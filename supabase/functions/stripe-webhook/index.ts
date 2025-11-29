import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import Stripe from 'https://esm.sh/stripe@14.21.0'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.45.0'

const stripe = new Stripe(Deno.env.get('STRIPE_SECRET_KEY') as string, {
  apiVersion: '2024-11-20.acacia',
  httpClient: Stripe.createFetchHttpClient(),
})

const webhookSecret = Deno.env.get('STRIPE_WEBHOOK_SECRET')!

// Helper function to find user by email using database RPC function
// We use a database function because auth.users is not directly queryable via PostgREST
async function findUserByEmail(supabase: any, email: string): Promise<string | null> {
  try {
    // Use RPC to call the database function that queries auth.users
    const { data, error } = await supabase.rpc('get_user_id_by_email', {
      user_email: email.toLowerCase()
    })
    
    if (error) {
      console.log(`⚠️ RPC call failed: ${error.message}`)
      return null
    }
    
    // The function returns a UUID directly, or null if not found
    return data || null
  } catch (error: any) {
    console.log(`⚠️ Exception finding user by email: ${error.message}`)
    return null
  }
}

serve(async (req) => {
  const signature = req.headers.get('stripe-signature')

  if (!signature) {
    return new Response(JSON.stringify({ error: 'No signature' }), {
      status: 400,
    })
  }

  try {
    const body = await req.text()
    const event = await stripe.webhooks.constructEventAsync(body, signature, webhookSecret)

    console.log(`Webhook received: ${event.type}`)

    const supabaseUrl = Deno.env.get('SUPABASE_URL')!
    const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
    const supabase = createClient(supabaseUrl, supabaseServiceKey)

    // Handle checkout.session.completed - subscription created via checkout
    if (event.type === 'checkout.session.completed') {
      const session = event.data.object as Stripe.Checkout.Session
      
      // Only process subscription mode checkouts
      if (session.mode === 'subscription' && session.subscription) {
        const subscriptionId = session.subscription as string
        const customerId = session.customer as string
        
        // Multi-layered approach to find user_id (in order of reliability):
        // 1. client_reference_id (PRIMARY - most reliable, passed as query param to checkout)
        // 2. metadata.user_id (for backward compatibility with dynamically created sessions)
        // 3. customer_id lookup (if customer was already linked in a previous event)
        // 4. email matching (LAST RESORT - only if all else fails, as emails can match wrong users)
        
        let userId = session.client_reference_id as string | null
        
        if (userId) {
          console.log(`✅ Found user_id from client_reference_id: ${userId}`)
        } else {
          // Fallback 1: Check metadata (for backward compatibility)
          userId = session.metadata?.user_id
          if (userId) {
            console.log(`✅ Found user_id from metadata: ${userId}`)
          }
        }

        // If still no user_id, try lookup by customer_id (might have been linked in customer.created)
        if (!userId) {
          console.log('🔍 No user_id from client_reference_id or metadata, checking if customer already linked...')
          const { data: userSub } = await supabase
            .from('user_subscriptions')
            .select('user_id')
            .eq('stripe_customer_id', customerId)
            .single()

          if (userSub) {
            userId = userSub.user_id
            console.log(`✅ Found user by existing customer_id link: ${userId}`)
          }
        }

        // LAST RESORT: Try to match by customer email
        // WARNING: Only use this if client_reference_id and customer_id lookup both failed
        // Email matching can link to wrong user if same email exists in multiple accounts
        if (!userId) {
          console.log('⚠️ No user_id from client_reference_id, metadata, or existing customer link')
          console.log('⚠️ Attempting email matching as last resort (may link to wrong user if email matches multiple accounts)...')
          try {
            const customer = await stripe.customers.retrieve(customerId)
            if (customer && typeof customer === 'object' && customer.email) {
              console.log(`🔍 Looking up user by email: ${customer.email}`)
              const foundUserId = await findUserByEmail(supabase, customer.email)
              if (foundUserId) {
                userId = foundUserId
                console.log(`⚠️ Found user by email (LAST RESORT): ${userId}`)
                console.log(`⚠️ WARNING: Email matching used - verify this is the correct user!`)
              } else {
                console.log(`❌ No user found with email: ${customer.email}`)
              }
            }
          } catch (error: any) {
            console.error('⚠️ Could not retrieve customer or find user:', error.message || error)
          }
        }

        if (!userId) {
          console.error('❌ Could not determine user_id for checkout session')
          console.error('   All methods failed: client_reference_id, metadata, customer_id lookup, and email matching')
          return new Response(JSON.stringify({ 
            received: true,
            error: 'Could not determine user_id for checkout session'
          }), {
            status: 200,
          })
        }

        console.log(`✅ Checkout completed for user ${userId}, subscription: ${subscriptionId}`)

        // Retrieve the subscription to get full details
        const subscription = await stripe.subscriptions.retrieve(subscriptionId)

        // Upsert user_subscriptions record
        const upsertData: any = {
          user_id: userId,
          stripe_customer_id: customerId,
          stripe_subscription_id: subscription.id,
          status: subscription.status,
          current_period_end: subscription.current_period_end
            ? new Date(subscription.current_period_end * 1000).toISOString()
            : null,
          updated_at: new Date().toISOString()
        }

        // Add trial_end if subscription is in trial
        if (subscription.status === 'trialing' && subscription.trial_end) {
          upsertData.trial_end = new Date(subscription.trial_end * 1000).toISOString()
        } else if (subscription.status === 'active') {
          // Clear trial_end if subscription is now active after trial
          upsertData.trial_end = null
        }

        const { error: upsertError } = await supabase
          .from('user_subscriptions')
          .upsert(upsertData, {
            onConflict: 'user_id'
          })

        if (upsertError) {
          console.error('❌ Failed to upsert user_subscriptions:', upsertError)
          return new Response(JSON.stringify({ error: upsertError.message }), {
            status: 500,
          })
        }

        console.log(`✅ Updated user_subscriptions for user ${userId}, status: ${subscription.status}`)
      }
    }

    // Handle customer.created - link new Stripe customer to user
    // This happens when Stripe creates a customer during checkout
    // Note: We don't create a subscription record here - we wait for checkout.session.completed
    // This is just for early linking if possible (helps with subscription.created fallback)
    if (event.type === 'customer.created') {
      const customer = event.data.object as Stripe.Customer
      const customerId = customer.id
      const customerEmail = customer.email

      console.log(`🔍 New customer created: ${customerId}, email: ${customerEmail || 'none'}`)
      
      // Try to find user by email (optional - helps with fallback matching)
      // The primary method (client_reference_id) will be in checkout.session.completed
      if (customerEmail) {
        try {
          const userId = await findUserByEmail(supabase, customerEmail)
          
          if (userId) {
            console.log(`✅ Found user for customer ${customerId}: ${userId} (will link when subscription is created)`)
            // Don't create record yet - wait for subscription to be created
            // This just helps us know the customer can be linked
          } else {
            console.log(`⚠️ No user found with email: ${customerEmail} - will use client_reference_id when subscription is created`)
          }
        } catch (error: any) {
          console.error('⚠️ Error checking customer email:', error.message || error)
        }
      } else {
        console.log(`⚠️ Customer ${customerId} has no email - will rely on client_reference_id from checkout`)
      }
    }

    // Handle subscription events
    if (
      event.type === 'customer.subscription.created' ||
      event.type === 'customer.subscription.updated' ||
      event.type === 'customer.subscription.deleted' ||
      event.type === 'customer.subscription.trial_will_end'
    ) {
      const subscription = event.data.object as Stripe.Subscription
      const customerId = subscription.customer as string

      // Find user by stripe_customer_id
      // IMPORTANT: If a record already exists, use it - don't try to re-link by email
      // This prevents linking to the wrong user when emails match but client_reference_id was correct
      let { data: userSub } = await supabase
        .from('user_subscriptions')
        .select('user_id')
        .eq('stripe_customer_id', customerId)
        .single()

      // If not found, wait a moment and retry (checkout.session.completed might still be processing)
      if (!userSub) {
        console.log(`⚠️ No user_subscriptions record found for customer ${customerId}, waiting for checkout.session.completed...`)
        await new Promise(resolve => setTimeout(resolve, 1000)) // Wait 1 second
        
        // Retry lookup
        const retryResult = await supabase
          .from('user_subscriptions')
          .select('user_id')
          .eq('stripe_customer_id', customerId)
          .single()
        
        if (retryResult.data) {
          userSub = retryResult.data
          console.log(`✅ Found user_subscriptions record on retry: ${userSub.user_id}`)
        } else {
          console.error(`❌ No user_subscriptions record found for customer ${customerId} after retry`)
          console.error(`   This customer should have been linked during checkout.session.completed`)
          console.error(`   The subscription will be orphaned - check if checkout.session.completed was processed`)
          // Don't try to link by email here - if checkout.session.completed didn't create the record,
          // it means client_reference_id wasn't available, and email matching could link to wrong user
          return new Response(JSON.stringify({ 
            received: true,
            warning: `No user_subscriptions record found for customer ${customerId}. Check checkout.session.completed event.`
          }), {
            status: 200,
          })
        }
      }

      // Prepare update data
      const updateData: any = {
        stripe_subscription_id: subscription.id,
        status: subscription.status,
        current_period_end: subscription.current_period_end 
          ? new Date(subscription.current_period_end * 1000).toISOString()
          : null,
        updated_at: new Date().toISOString()
      }

      // Add trial_end if subscription is in trial
      if (subscription.status === 'trialing' && subscription.trial_end) {
        updateData.trial_end = new Date(subscription.trial_end * 1000).toISOString()
      } else if (subscription.status === 'active' && !subscription.trial_end) {
        // Clear trial_end when subscription becomes active after trial
        updateData.trial_end = null
      }

      // Handle subscription deletion
      if (event.type === 'customer.subscription.deleted') {
        updateData.status = 'inactive'
        updateData.stripe_subscription_id = null
        updateData.trial_end = null
      }

      // Upsert user_subscriptions (ensures only one record per user)
      const upsertData = {
        user_id: userSub.user_id,
        stripe_customer_id: customerId,
        stripe_subscription_id: updateData.stripe_subscription_id,
        status: updateData.status,
        current_period_end: updateData.current_period_end,
        trial_end: updateData.trial_end,
        updated_at: updateData.updated_at
      }
      
      const { error } = await supabase
        .from('user_subscriptions')
        .upsert(upsertData, {
          onConflict: 'user_id' // Use user_id as the conflict resolution key
        })

      if (error) {
        console.error('Error updating subscription:', error)
        return new Response(JSON.stringify({ error: error.message }), {
          status: 500,
        })
      }

      console.log(`Updated subscription for user ${userSub.user_id}: ${subscription.status}`)
      
      // If subscription was incomplete and is now active, log it
      if (subscription.status === 'active' && event.type === 'customer.subscription.updated') {
        console.log(`✅ Subscription activated for user ${userSub.user_id}`)
      }
    }

    // Handle successful payments - this updates incomplete subscriptions to active/trialing
    if (event.type === 'invoice.payment_succeeded') {
      const invoice = event.data.object as Stripe.Invoice
      const subscriptionId = invoice.subscription as string

      if (subscriptionId) {
        // Fetch the subscription to ensure status is current
        const subscription = await stripe.subscriptions.retrieve(subscriptionId)
        const customerId = subscription.customer as string

        const { data: userSub } = await supabase
          .from('user_subscriptions')
          .select('user_id')
          .eq('stripe_customer_id', customerId)
          .single()

        if (userSub) {
          const upsertData: any = {
            user_id: userSub.user_id,
            stripe_customer_id: customerId,
            stripe_subscription_id: subscription.id,
            status: subscription.status, // Should be 'active' or 'trialing' after payment succeeds
            current_period_end: subscription.current_period_end 
              ? new Date(subscription.current_period_end * 1000).toISOString()
              : null,
            updated_at: new Date().toISOString()
          }

          // Add trial_end if subscription is in trial
          if (subscription.status === 'trialing' && subscription.trial_end) {
            upsertData.trial_end = new Date(subscription.trial_end * 1000).toISOString()
          } else if (subscription.status === 'active') {
            // Clear trial_end if subscription is now active after trial
            upsertData.trial_end = null
          }

          await supabase
            .from('user_subscriptions')
            .upsert(upsertData, {
              onConflict: 'user_id' // Use user_id as the conflict resolution key
            })

          console.log(`✅ Payment succeeded for user ${userSub.user_id}, subscription status: ${subscription.status}`)
        }
      }
    }

    // Handle failed payments
    if (event.type === 'invoice.payment_failed') {
      const invoice = event.data.object as Stripe.Invoice
      const subscriptionId = invoice.subscription as string

      if (subscriptionId) {
        const subscription = await stripe.subscriptions.retrieve(subscriptionId)
        const customerId = subscription.customer as string

        const { data: userSub } = await supabase
          .from('user_subscriptions')
          .select('user_id')
          .eq('stripe_customer_id', customerId)
          .single()

        if (userSub) {
          const upsertData: any = {
            user_id: userSub.user_id,
            stripe_customer_id: customerId,
            stripe_subscription_id: subscription.id,
            status: subscription.status, // Could be 'past_due', 'unpaid', or 'incomplete_expired'
            updated_at: new Date().toISOString()
          }
          
          await supabase
            .from('user_subscriptions')
            .upsert(upsertData, {
              onConflict: 'user_id' // Use user_id as the conflict resolution key
            })

          console.log(`❌ Payment failed for user ${userSub.user_id}, subscription status: ${subscription.status}`)
        } else {
          console.log(`⚠️ No user found for customer ${customerId} in invoice.payment_failed`)
        }
      }
    }

    return new Response(JSON.stringify({ received: true }), {
      status: 200,
    })
  } catch (error) {
    console.error('Webhook error:', error)
    return new Response(
      JSON.stringify({ error: error.message }),
      {
        status: 400,
      }
    )
  }
})

