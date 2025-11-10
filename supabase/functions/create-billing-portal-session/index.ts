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
    console.log('🚀 create-billing-portal-session function called')
    
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

    // Get user from the JWT
    const { data: { user }, error: userError } = await supabase.auth.getUser()

    if (userError || !user) {
      console.error('❌ Auth error:', userError)
      return new Response(JSON.stringify({ error: 'Unauthorized' }), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 401,
      })
    }

    console.log('✅ User authenticated:', user.id)

    const { customer_id } = await req.json()
    console.log('📥 Requested customer ID:', customer_id)

    // Verify the customer belongs to this user
    const { data: subscription, error: dbError } = await supabase
      .from('user_subscriptions')
      .select('stripe_customer_id')
      .eq('user_id', user.id)
      .single()

    console.log('🔍 Database lookup result:', { subscription, dbError })

    if (dbError) {
      console.error('❌ Database error:', dbError)
      return new Response(JSON.stringify({ error: 'Database error', details: dbError.message }), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 500,
      })
    }

    if (!subscription) {
      console.error('❌ No subscription record found for user:', user.id)
      return new Response(JSON.stringify({ error: 'No subscription record found' }), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 404,
      })
    }

    console.log('💳 User\'s customer ID from DB:', subscription.stripe_customer_id)
    console.log('🔄 Comparing:', {
      requested: customer_id,
      db_value: subscription.stripe_customer_id,
      match: subscription.stripe_customer_id === customer_id
    })

    if (subscription.stripe_customer_id !== customer_id) {
      console.error('❌ Customer mismatch - BEFORE comparison:', {
        requested_type: typeof customer_id,
        requested_value: customer_id,
        db_type: typeof subscription.stripe_customer_id,
        db_value: subscription.stripe_customer_id
      })
      return new Response(JSON.stringify({ error: 'Customer ID mismatch' }), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 403,
      })
    }

    console.log('✅ Customer verified')
    console.log('🎫 Creating billing portal session...')

    // Create Stripe Billing Portal session
    const session = await stripe.billingPortal.sessions.create({
      customer: customer_id,
      return_url: 'thedailydev://subscription-updated',
    })

    console.log('✅ Billing portal session created')
    console.log('🔗 Portal URL:', session.url)

    return new Response(
      JSON.stringify({ url: session.url }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 200,
      }
    )
  } catch (error) {
    console.error('❌ Error creating billing portal session:', error)
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

