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
    console.log('🚀 initiate-trial function called')
    
    // Get authorization header
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

    const { user_id, email, price_id } = await req.json()
    console.log('📥 Request body:', { user_id, email, price_id })

    // Verify the user_id matches the authenticated user (case-insensitive)
    if (user_id.toLowerCase() !== user.id.toLowerCase()) {
      console.error('❌ User ID mismatch:', { provided: user_id, actual: user.id })
      return new Response(JSON.stringify({ error: 'User ID mismatch' }), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 401,
      })
    }
    
    console.log('✅ User ID verified')

    console.log('🔍 Looking up Stripe customer...')
    
    // Get or create Stripe customer
    const { data: subscription } = await supabase
      .from('user_subscriptions')
      .select('stripe_customer_id')
      .eq('user_id', user_id)
      .single()

    let customerId = subscription?.stripe_customer_id
    console.log('💳 Existing customer ID:', customerId)

    if (!customerId) {
      console.log('➕ Creating new Stripe customer...')
      const customer = await stripe.customers.create({
        email: email,
        metadata: {
          supabase_user_id: user_id
        }
      })
      customerId = customer.id
      console.log('✅ Created customer:', customerId)

      // Update user_subscriptions with customer_id
      await supabase
        .from('user_subscriptions')
        .upsert({
          user_id: user_id,
          stripe_customer_id: customerId,
          status: 'inactive',
          updated_at: new Date().toISOString()
        })
      console.log('✅ Updated user_subscriptions')
    }

    console.log('🛒 Creating Stripe Checkout session...')
    
    // Create Checkout Session in SETUP mode (collect payment method without charging)
    // Store price_id in metadata so we can use it in complete-trial-setup
    const session = await stripe.checkout.sessions.create({
      customer: customerId,
      mode: 'setup',
      payment_method_types: ['card'],
      success_url: `thedailydev://trial-started?session_id={CHECKOUT_SESSION_ID}`,
      cancel_url: 'thedailydev://subscription-cancel',
      metadata: {
        price_id: price_id || '', // Store price_id for later use
        user_id: user_id
      }
    })

    console.log('✅ Created checkout session:', session.id)
    console.log('🔗 Checkout URL:', session.url)

    return new Response(
      JSON.stringify({ url: session.url }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 200,
      }
    )
  } catch (error) {
    console.error('❌ Error creating trial setup session:', error)
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

