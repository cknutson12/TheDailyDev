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

    // Verify the user_id matches the authenticated user (case-insensitive)
    if (user_id.toLowerCase() !== user.id.toLowerCase()) {
      console.error('❌ User ID mismatch:', { provided: user_id, actual: user.id })
      return new Response(JSON.stringify({ error: 'User ID mismatch' }), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 401,
      })
    }
    
    console.log('✅ User ID verified')

    // Retrieve the Setup Session to get the payment method
    const session = await stripe.checkout.sessions.retrieve(session_id)

    if (!session.setup_intent || !session.customer) {
      throw new Error('Invalid session: missing setup_intent or customer')
    }

    // Get the payment method from the SetupIntent
    const setupIntent = await stripe.setupIntents.retrieve(session.setup_intent as string)
    const paymentMethodId = setupIntent.payment_method as string

    if (!paymentMethodId) {
      throw new Error('No payment method attached to setup intent')
    }

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

    // Calculate trial end date (7 days from now)
    const trialEndTimestamp = Math.floor(Date.now() / 1000) + (7 * 24 * 60 * 60)
    const trialEndDate = new Date(trialEndTimestamp * 1000).toISOString()

    // Create subscription with trial period
    const subscription = await stripe.subscriptions.create({
      customer: session.customer as string,
      items: [{
        price: price_id,
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

