# Complete Stripe + Supabase Integration Guide

## Step 1: Stripe Dashboard Setup

### 1.1 Get Your Stripe Test Keys
1. Go to: https://dashboard.stripe.com/test/apikeys
2. You'll see:
   - **Secret key**: `sk_test_51AbCd...` ⚠️ COPY THIS NOW
   - Keep this page open for later

### 1.2 Create a Subscription Product/Price
1. Go to: https://dashboard.stripe.com/test/products
2. Click "Add product"
3. Fill in:
   - **Name**: "Monthly Plan"
   - **Pricing**: 
     - Model: Recurring
     - Price: $9.99
     - Billing period: Monthly
4. Click "Save product"
5. **⚠️ CRITICAL**: Copy the "Price ID" (starts with `price_...` like `price_1234567890`)
   - This will be used in your iOS app

---

## Step 2: Supabase Dashboard Setup

### 2.1 Find Your Supabase Credentials
1. Go to: https://supabase.com/dashboard/project/thawdmtbwehbuzmrwicz/settings/api
2. You'll see:
   - **Project URL**: `https://thawdmtbwehbuzmrwicz.supabase.co` ✅ Already have this
   - **anon public**: `eyJhbGci...` ✅ Already have this in Config-Secrets.plist
   - **service_role secret**: `eyJhbGci...` ⚠️ YOU NEED THIS - Click "Reveal" to see it

### 2.2 Create the Database Table
1. Go to: https://supabase.com/dashboard/project/thawdmtbwehbuzmrwicz/editor
2. Click "SQL Editor"
3. Click "New query"
4. Paste this SQL:

```sql
-- Create user_subscriptions table
CREATE TABLE user_subscriptions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES auth.users(id) NOT NULL,
  stripe_customer_id TEXT,
  stripe_subscription_id TEXT,
  status TEXT NOT NULL DEFAULT 'inactive',
  current_period_end TIMESTAMP,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE user_subscriptions ENABLE ROW LEVEL SECURITY;

-- Create policies
CREATE POLICY "Users can view their own subscription"
  ON user_subscriptions FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own subscription"
  ON user_subscriptions FOR INSERT
  WITH CHECK (auth.uid() = user_id);
```

5. Click "Run" (bottom right)

### 2.3 Create Edge Function: create-checkout-session
1. Go to: https://supabase.com/dashboard/project/thawdmtbwehbuzmrwicz/functions
2. Click "Create a new function"
3. Name: `create-checkout-session`
4. Copy and paste this code (we'll update the price_id later):

```typescript
import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const { user_id, price_id } = await req.json()
    
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    )

    let { data: subscription } = await supabaseClient
      .from('user_subscriptions')
      .select('stripe_customer_id')
      .eq('user_id', user_id)
      .maybeSingle()

    let customerId = subscription?.stripe_customer_id

    if (!customerId) {
      const stripeResponse = await fetch('https://api.stripe.com/v1/customers', {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${Deno.env.get('STRIPE_SECRET_KEY')}`,
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: new URLSearchParams({
          metadata: JSON.stringify({ supabase_user_id: user_id })
        })
      })

      const customer = await stripeResponse.json()
      customerId = customer.id

      await supabaseClient
        .from('user_subscriptions')
        .insert({
          user_id,
          stripe_customer_id: customerId,
          status: 'inactive'
        })
    }

    const checkoutResponse = await fetch('https://api.stripe.com/v1/checkout/sessions', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${Deno.env.get('STRIPE_SECRET_KEY')}`,
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: new URLSearchParams({
        customer: customerId,
        mode: 'subscription',
        line_items: JSON.stringify([{
          price: price_id,
          quantity: 1
        }]),
        success_url: `thedailydev://subscription-success`,
        cancel_url: `thedailydev://subscription-cancel`,
        metadata: JSON.stringify({ user_id })
      })
    })

    const session = await checkoutResponse.json()

    return new Response(
      JSON.stringify({ url: session.url }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 200,
      },
    )
  } catch (error) {
    return new Response(
      JSON.stringify({ error: error.message }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 400,
      },
    )
  }
})
```

5. Click "Deploy function"

### 2.4 Create Edge Function: stripe-webhook
1. Click "Create a new function" again
2. Name: `stripe-webhook`
3. Paste this code:

```typescript
import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const payload = await req.text()
    const event = JSON.parse(payload)
    
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    )

    if (event.type === 'checkout.session.completed') {
      const session = event.data.object
      const userId = session.metadata?.user_id

      if (userId) {
        await supabaseClient
          .from('user_subscriptions')
          .update({
            stripe_subscription_id: session.subscription,
            status: 'active',
            current_period_end: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000).toISOString()
          })
          .eq('user_id', userId)
      }
    }

    if (event.type === 'customer.subscription.updated') {
      const subscription = event.data.object
      
      await supabaseClient
        .from('user_subscriptions')
        .update({
          status: subscription.status,
          current_period_end: new Date(subscription.current_period_end * 1000).toISOString()
        })
        .eq('stripe_subscription_id', subscription.id)
    }

    if (event.type === 'customer.subscription.deleted') {
      const subscription = event.data.object
      
      await supabaseClient
        .from('user_subscriptions')
        .update({
          status: 'canceled',
          current_period_end: new Date(subscription.current_period_end * 1000).toISOString()
        })
        .eq('stripe_subscription_id', subscription.id)
    }

    return new Response(JSON.stringify({ received: true }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  } catch (error) {
    return new Response(
      JSON.stringify({ error: error.message }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 400 },
    )
  }
})
```

4. Click "Deploy function"

### 2.4 Create Edge Function: create-billing-portal-session
1. Click "Create a new function" again
2. Name: `create-billing-portal-session`
3. Paste this code:

```typescript
import { serve } from "https://deno.land/std@0.168.0/http/server.ts"

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    console.log('📥 Billing portal request received')
    
    const { customer_id } = await req.json()
    console.log('📋 Customer ID:', customer_id)
    
    const stripeKey = Deno.env.get('STRIPE_SECRET_KEY')
    
    if (!stripeKey) {
      console.error('❌ STRIPE_SECRET_KEY not set!')
      return new Response(JSON.stringify({ error: 'STRIPE_SECRET_KEY not configured' }), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 500,
      })
    }
    
    // Create billing portal session
    console.log('🔄 Creating Stripe billing portal session...')
    const response = await fetch('https://api.stripe.com/v1/billing_portal/sessions', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${stripeKey}`,
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: new URLSearchParams({
        customer: customer_id,
        return_url: 'thedailydev://subscription-settings'
      })
    })

    console.log('📡 Stripe response status:', response.status)
    const session = await response.json()
    console.log('📋 Session response:', JSON.stringify(session))
    
    // If there's an error from Stripe, return it
    if (!response.ok || session.error) {
      console.error('❌ Stripe error:', session.error || session)
      return new Response(JSON.stringify({ 
        error: session.error?.message || session.error || JSON.stringify(session)
      }), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: response.status || 500,
      })
    }
    
    if (!session.url) {
      console.error('❌ No URL in session response')
      return new Response(JSON.stringify({ error: 'No URL in session' }), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 500,
      })
    }
    
    console.log('✅ Portal URL:', session.url)
    return new Response(JSON.stringify({ url: session.url }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 200,
    })
  } catch (error) {
    console.error('❌ Error:', error)
    return new Response(JSON.stringify({ error: error.message }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 500,
    })
  }
})
```

4. Click "Deploy function"

### 2.5 Add Environment Variables
1. In the Edge Functions page, click on `create-checkout-session` function
2. Click "Manage secrets" or go to: Settings → Edge Functions
3. Add these secrets:
   - **Key**: `STRIPE_SECRET_KEY`
     **Value**: Your Stripe secret key from Step 1.1 (starts with `sk_test_`)
   - **Key**: `SUPABASE_URL`
     **Value**: `https://thawdmtbwehbuzmrwicz.supabase.co`
   - **Key**: `SUPABASE_SERVICE_ROLE_KEY`
     **Value**: Your service_role key from Step 2.1 (starts with `eyJhbGci...`)

4. Repeat for the `stripe-webhook` function

### 2.6 Get Your Supabase API Keys Location
- **Project URL**: Settings → API → Project URL
- **anon key**: Settings → API → anon public (✅ you have this)
- **service_role key**: Settings → API → service_role secret (⚠️ Reveal to copy)

---

## Step 3: Update iOS App

### 3.1 Update SubscriptionService with Your Price ID
1. Open: `TheDailyDev/SubscriptionService.swift`
2. Find line: `"price_id": "price_1234567890"`
3. Replace `"price_1234567890"` with your actual Price ID from Step 1.2

---

## Step 4: Configure Stripe Webhook

### 4.1 Set Up Webhook Endpoint
1. Go to Stripe Dashboard:
   - Visit: https://dashboard.stripe.com/
   - Ensure you're in **Test mode** (toggle in top right)
   - Click **Developers** in left sidebar
   - Click **Webhooks**
2. Click "Add endpoint"
3. Enter URL: `https://thawdmtbwehbuzmrwicz.supabase.co/functions/v1/stripe-webhook`
4. Select events:
   - `checkout.session.completed`
   - `customer.subscription.updated`
   - `customer.subscription.deleted`
5. Click "Add endpoint"
6. **⚠️ CRITICAL**: Copy the "Signing secret" (starts with `whsec_...`)
7. Add this as another secret in Supabase Edge Functions:
   - **Key**: `STRIPE_WEBHOOK_SECRET`
   - **Value**: The signing secret from this step

---

## Quick Checklist

- [ ] Stripe Secret Key copied (`sk_test_...`)
- [ ] Stripe Price ID copied (`price_...`)
- [ ] Supabase service_role key copied
- [ ] Database table created and policies set
- [ ] Edge function `create-checkout-session` deployed
- [ ] Edge function `stripe-webhook` deployed
- [ ] Environment variables set in Supabase
- [ ] Stripe webhook endpoint configured
- [ ] Webhook signing secret added to Supabase
- [ ] iOS app updated with Price ID

---

## Testing

Use Stripe test cards:
- Success: `4242 4242 4242 4242`
- Any future expiry date
- Any CVC

The webhook will automatically update your database when a subscription is created!
