import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import Stripe from 'https://esm.sh/stripe@14.21.0'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.45.0'

const stripe = new Stripe(Deno.env.get('STRIPE_SECRET_KEY') as string, {
  apiVersion: '2024-11-20.acacia',
  httpClient: Stripe.createFetchHttpClient(),
})

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response(null, { headers: corsHeaders })
  }

  try {
    console.log('🚀 complete-trial-setup function called')
    
    const authHeader = req.headers.get('Authorization')
    if (!authHeader) {
      console.error('❌ No authorization header')
      return new Response(JSON.stringify({ error: 'Missing authorization header' }), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 401,
      })
    }

    console.log('✅ Authorization header present')

    const supabaseUrl = Deno.env.get('SUPABASE_URL')!
    const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
    
    // Create Supabase client (service role for all operations)
    const supabase = createClient(supabaseUrl, supabaseServiceKey, {
      global: {
        headers: {
          Authorization: authHeader
        }
      },
      auth: {
        autoRefreshToken: false,
        persistSession: false
      }
    })

    // Get user from the JWT (Supabase already validated it)
    const { data: { user }, error: userError } = await supabase.auth.getUser()

    if (userError || !user) {
      console.error('❌ Auth error:', userError)
      return new Response(JSON.stringify({ error: 'Unauthorized', details: userError?.message }), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 401,
      })
    }

    console.log('✅ User authenticated:', user.id)

    const { user_id, session_id, price_id } = await req.json()
    console.log('📥 Request body:', { user_id, session_id, price_id })
    
    // Retrieve the checkout session to get metadata (including price_id if stored there)
    let finalPriceId = price_id
    if (session_id) {
      try {
        const checkoutSession = await stripe.checkout.sessions.retrieve(session_id)
        // Use price_id from metadata if not provided in request body
        if (!finalPriceId && checkoutSession.metadata?.price_id) {
          finalPriceId = checkoutSession.metadata.price_id
          console.log('📋 Using price_id from session metadata:', finalPriceId)
        }
      } catch (error) {
        console.error('⚠️ Could not retrieve checkout session:', error)
      }
    }
    
    if (!finalPriceId) {
      console.error('❌ No price_id provided')
      return new Response(JSON.stringify({ error: 'price_id is required' }), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 400,
      })
    }

    // Verify the user_id matches the authenticated user (case-insensitive)
    if (user_id.toLowerCase() !== user.id.toLowerCase()) {
      console.error('❌ User ID mismatch:', { provided: user_id, actual: user.id })
      return new Response(JSON.stringify({ error: 'User ID mismatch' }), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 401,
      })
    }
    
    console.log('✅ User ID verified')

    // Fetch trial days from subscription plan
    let trialDays = 7 // Default fallback
    try {
      const { data: plan } = await supabase
        .from('subscription_plans')
        .select('trial_days')
        .eq('stripe_price_id', finalPriceId)
        .single()
      
      if (plan?.trial_days) {
        trialDays = plan.trial_days
        console.log(`📅 Using trial days from plan: ${trialDays}`)
      }
    } catch (error) {
      console.warn('⚠️ Could not fetch trial days from plan, using default 7 days:', error)
    }

    // Retrieve the Setup Session to get the payment method
    let session
    try {
      session = await stripe.checkout.sessions.retrieve(session_id)
    } catch (error) {
      console.error('❌ Failed to retrieve checkout session:', error)
      return new Response(JSON.stringify({ 
        error: 'Failed to retrieve checkout session',
        details: error.message 
      }), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 400,
      })
    }

    if (!session.setup_intent || !session.customer) {
      console.error('❌ Invalid session:', { 
        has_setup_intent: !!session.setup_intent, 
        has_customer: !!session.customer,
        session_mode: session.mode 
      })
      return new Response(JSON.stringify({ 
        error: 'Invalid session: missing setup_intent or customer',
        details: `Session mode: ${session.mode}, Setup intent: ${!!session.setup_intent}, Customer: ${!!session.customer}`
      }), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 400,
      })
    }

    // Get the payment method from the SetupIntent
    let setupIntent
    try {
      setupIntent = await stripe.setupIntents.retrieve(session.setup_intent as string)
    } catch (error) {
      console.error('❌ Failed to retrieve setup intent:', error)
      return new Response(JSON.stringify({ 
        error: 'Failed to retrieve setup intent',
        details: error.message 
      }), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 400,
      })
    }
    
    const paymentMethodId = setupIntent.payment_method as string

    if (!paymentMethodId) {
      console.error('❌ No payment method in setup intent:', setupIntent)
      return new Response(JSON.stringify({ 
        error: 'No payment method attached to setup intent',
        details: 'The setup intent does not have a payment method'
      }), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 400,
      })
    }
    
    console.log('✅ Payment method found:', paymentMethodId)

    // Attach the payment method to the customer (if not already attached)
    await stripe.paymentMethods.attach(paymentMethodId, {
      customer: session.customer as string,
    }).catch(err => {
      // If already attached, ignore error
      if (!err.message.includes('already been attached')) {
        throw err
      }
    })

    // Set as default payment method
    await stripe.customers.update(session.customer as string, {
      invoice_settings: {
        default_payment_method: paymentMethodId,
      },
    })

    // Calculate trial end date (using trial days from plan)
    const trialEndTimestamp = Math.floor(Date.now() / 1000) + (trialDays * 24 * 60 * 60)
    const trialEndDate = new Date(trialEndTimestamp * 1000).toISOString()
    console.log(`📅 Trial end date: ${trialEndDate} (${trialDays} days from now)`)

    // Create subscription with trial period
    const subscription = await stripe.subscriptions.create({
      customer: session.customer as string,
      items: [{
        price: finalPriceId,
      }],
      trial_end: trialEndTimestamp,
      payment_behavior: 'default_incomplete',
      payment_settings: {
        save_default_payment_method: 'on_subscription',
      },
      expand: ['latest_invoice.payment_intent'],
    })

    console.log('💾 Updating user_subscriptions...')
    
    // Update user_subscriptions in database
    await supabase
      .from('user_subscriptions')
      .update({
        stripe_subscription_id: subscription.id,
        status: 'trialing',
        trial_end: trialEndDate,
        current_period_end: new Date(subscription.current_period_end * 1000).toISOString(),
        updated_at: new Date().toISOString()
      })
      .eq('user_id', user_id)
    
    console.log('✅ Trial subscription created successfully!')

    return new Response(
      JSON.stringify({ 
        success: true,
        subscription_id: subscription.id,
        trial_end: trialEndDate
      }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 200,
      }
    )
  } catch (error) {
    console.error('❌ Error completing trial setup:', error)
    console.error('❌ Error details:', error.message)
    return new Response(
      JSON.stringify({ error: error.message }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 500,
      }
    )
  }
})

