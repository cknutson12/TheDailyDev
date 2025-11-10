import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import Stripe from 'https://esm.sh/stripe@14.21.0'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.45.0'

const stripe = new Stripe(Deno.env.get('STRIPE_SECRET_KEY') as string, {
  apiVersion: '2024-11-20.acacia',
  httpClient: Stripe.createFetchHttpClient(),
})

const webhookSecret = Deno.env.get('STRIPE_WEBHOOK_SECRET')!

serve(async (req) => {
  const signature = req.headers.get('stripe-signature')

  if (!signature) {
    return new Response(JSON.stringify({ error: 'No signature' }), {
      status: 400,
    })
  }

  try {
    const body = await req.text()
    const event = stripe.webhooks.constructEvent(body, signature, webhookSecret)

    console.log(`Webhook received: ${event.type}`)

    const supabaseUrl = Deno.env.get('SUPABASE_URL')!
    const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
    const supabase = createClient(supabaseUrl, supabaseServiceKey)

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
      const { data: userSub } = await supabase
        .from('user_subscriptions')
        .select('user_id')
        .eq('stripe_customer_id', customerId)
        .single()

      if (!userSub) {
        console.error(`No user found for customer ${customerId}`)
        return new Response(JSON.stringify({ error: 'User not found' }), {
          status: 404,
        })
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

      // Update user_subscriptions
      const { error } = await supabase
        .from('user_subscriptions')
        .update(updateData)
        .eq('user_id', userSub.user_id)

      if (error) {
        console.error('Error updating subscription:', error)
        return new Response(JSON.stringify({ error: error.message }), {
          status: 500,
        })
      }

      console.log(`Updated subscription for user ${userSub.user_id}: ${subscription.status}`)
    }

    // Handle successful payments
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
          const updateData: any = {
            status: subscription.status,
            current_period_end: subscription.current_period_end 
              ? new Date(subscription.current_period_end * 1000).toISOString()
              : null,
            updated_at: new Date().toISOString()
          }

          // Clear trial_end if subscription is now active after trial
          if (subscription.status === 'active' && !subscription.trial_end) {
            updateData.trial_end = null
          }

          await supabase
            .from('user_subscriptions')
            .update(updateData)
            .eq('user_id', userSub.user_id)

          console.log(`Payment succeeded for user ${userSub.user_id}`)
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
          await supabase
            .from('user_subscriptions')
            .update({
              status: subscription.status, // Could be 'past_due' or 'unpaid'
              updated_at: new Date().toISOString()
            })
            .eq('user_id', userSub.user_id)

          console.log(`Payment failed for user ${userSub.user_id}`)
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

