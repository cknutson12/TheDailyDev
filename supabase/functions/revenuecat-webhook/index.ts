import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.45.0'

const webhookSecret = Deno.env.get('REVENUECAT_WEBHOOK_SECRET')!

// Helper function to find user by RevenueCat user ID
async function findUserByRevenueCatID(supabase: any, revenueCatUserId: string): Promise<string | null> {
  try {
    const { data, error } = await supabase
      .from('user_subscriptions')
      .select('user_id')
      .eq('revenuecat_user_id', revenueCatUserId)
      .single()
    
    if (error || !data) {
      console.log(`⚠️ No user found with RevenueCat ID: ${revenueCatUserId}`)
      return null
    }
    
    return data.user_id
  } catch (error: any) {
    console.log(`⚠️ Exception finding user by RevenueCat ID: ${error.message}`)
    return null
  }
}

serve(async (req) => {
  // Check if webhook secret is configured
  if (!webhookSecret || webhookSecret === '') {
    console.error('❌ REVENUECAT_WEBHOOK_SECRET is not set in Edge Function secrets')
    return new Response(JSON.stringify({ 
      error: 'Webhook secret not configured',
      message: 'Please set REVENUECAT_WEBHOOK_SECRET in Supabase Edge Function secrets'
    }), {
      status: 500,
    })
  }

  // Verify webhook signature (RevenueCat sends Authorization header)
  // Try multiple header name variations (case-insensitive)
  const authHeader = req.headers.get('Authorization') || 
                     req.headers.get('authorization') ||
                     req.headers.get('AUTHORIZATION')
  
  // Log all headers for debugging (don't log secrets)
  console.log('🔐 Webhook authorization check:')
  console.log(`   - All headers: ${JSON.stringify(Object.fromEntries(req.headers.entries()))}`)
  console.log(`   - Authorization header present: ${authHeader ? 'yes' : 'no'}`)
  if (authHeader) {
    console.log(`   - Header value starts with Bearer: ${authHeader.startsWith('Bearer ') || authHeader.startsWith('bearer ')}`)
    console.log(`   - Header length: ${authHeader.length}`)
  }
  console.log(`   - Webhook secret configured: ${webhookSecret ? 'yes (length: ' + webhookSecret.length + ')' : 'no'}`)
  
  if (!authHeader) {
    console.error('❌ No Authorization header found in request')
    console.error('   Available headers:', Array.from(req.headers.keys()).join(', '))
    return new Response(JSON.stringify({ 
      code: 401,
      message: "Auth header is not 'Bearer {token}'",
      error: 'Missing Authorization header. Please configure Authorization header in RevenueCat webhook settings.'
    }), {
      status: 401,
    })
  }
  
  // Normalize the header (handle case variations)
  const normalizedHeader = authHeader.trim()
  const bearerPrefix = normalizedHeader.substring(0, 7).toLowerCase()
  
  if (bearerPrefix !== 'bearer ') {
    console.error('❌ Authorization header does not start with "Bearer "')
    console.error(`   - Received: "${normalizedHeader.substring(0, 20)}..."`)
    return new Response(JSON.stringify({ 
      code: 401,
      message: "Auth header is not 'Bearer {token}'",
      error: 'Invalid Authorization header format. Expected: "Bearer [secret]"'
    }), {
      status: 401,
    })
  }
  
  const providedSecret = normalizedHeader.substring(7).trim() // Remove "Bearer " prefix and trim whitespace
  
  if (providedSecret !== webhookSecret) {
    console.error('❌ Webhook secret mismatch')
    console.error(`   - Provided secret length: ${providedSecret.length}`)
    console.error(`   - Expected secret length: ${webhookSecret.length}`)
    console.error(`   - First 10 chars match: ${providedSecret.substring(0, 10) === webhookSecret.substring(0, 10)}`)
    return new Response(JSON.stringify({ 
      code: 401,
      message: "Auth header is not 'Bearer {token}'",
      error: 'Webhook secret does not match. Please verify the secret in both RevenueCat dashboard and Supabase Edge Function secrets.'
    }), {
      status: 401,
    })
  }
  
  console.log('✅ Webhook authorization successful')

  try {
    const body = await req.json()
    const event = body.event

    console.log(`Webhook received: ${event.type}`)

    const supabaseUrl = Deno.env.get('SUPABASE_URL')!
    const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
    const supabase = createClient(supabaseUrl, supabaseServiceKey)

    // Extract user information from event
    const appUserId = event.app_user_id
    const aliases = event.aliases || {}
    
    // Try to find user by RevenueCat user ID or aliases
    let userId: string | null = null
    
    // First, try to find by revenuecat_user_id in database
    userId = await findUserByRevenueCatID(supabase, appUserId)
    
    // If not found, check if app_user_id is a Supabase user ID (UUID format)
    if (!userId) {
      // RevenueCat app_user_id might be the Supabase user_id directly
      // Check if it's a valid UUID
      const uuidRegex = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i
      if (uuidRegex.test(appUserId)) {
        // Verify this user exists in auth.users
        const { data: userData } = await supabase.auth.admin.getUserById(appUserId)
        if (userData?.user) {
          userId = appUserId
          console.log(`✅ Found user by UUID match: ${userId}`)
        }
      }
    }
    
    // If still not found, try aliases
    if (!userId && aliases) {
      for (const [aliasType, aliasValue] of Object.entries(aliases)) {
        if (aliasType === 'supabase_user_id' || aliasType === 'user_id') {
          userId = aliasValue as string
          console.log(`✅ Found user from alias ${aliasType}: ${userId}`)
          break
        }
      }
    }

    if (!userId) {
      console.error('❌ Could not determine user_id for RevenueCat event')
      console.error(`   app_user_id: ${appUserId}`)
      console.error(`   aliases: ${JSON.stringify(aliases)}`)
      return new Response(JSON.stringify({ 
        received: true,
        error: 'Could not determine user_id for RevenueCat event'
      }), {
        status: 200, // Return 200 to acknowledge receipt
      })
    }

    console.log(`✅ Processing event for user ${userId}`)
    console.log(`   - RevenueCat app_user_id: ${appUserId}`)
    console.log(`   - Supabase user_id: ${userId}`)
    console.log(`   - User IDs match: ${appUserId === userId}`)

    // Handle different event types
    const eventType = event.type
    const productId = event.product_id
    const entitlementId = event.entitlement_ids?.[0] || 'pro' // Default entitlement ID
    
    // Prepare update data
    // Always set revenuecat_user_id to appUserId (which should be the Supabase user_id after logIn)
    const updateData: any = {
      revenuecat_user_id: appUserId,
      updated_at: new Date().toISOString()
    }
    
    console.log(`   - Setting revenuecat_user_id to: ${appUserId}`)

    // Handle subscription status based on event type
    switch (eventType) {
      case 'INITIAL_PURCHASE':
        // Initial purchase - check if it's a trial
        if (event.trial_ends_at) {
          // User is starting a trial
          updateData.status = 'trialing'
          updateData.trial_end = new Date(event.trial_ends_at).toISOString()
          console.log(`   - Trial started, ends at: ${updateData.trial_end}`)
        } else {
          // No trial - direct purchase
          updateData.status = 'active'
        }
        updateData.entitlement_status = 'active'
        if (event.expires_at) {
          updateData.current_period_end = new Date(event.expires_at).toISOString()
        }
        
        // Extract transaction IDs from event
        if (event.transaction_id) {
          updateData.revenuecat_subscription_id = event.transaction_id
          console.log(`   - Setting revenuecat_subscription_id: ${event.transaction_id}`)
        } else {
          console.log(`   ⚠️ No transaction_id in event`)
        }
        
        if (event.original_transaction_id) {
          updateData.original_transaction_id = event.original_transaction_id
          console.log(`   - Setting original_transaction_id: ${event.original_transaction_id}`)
        } else {
          console.log(`   ⚠️ No original_transaction_id in event`)
        }
        
        // Log all event fields for debugging
        console.log(`   - Event fields: ${JSON.stringify(Object.keys(event))}`)
        if (event.product_id) {
          console.log(`   - Product ID: ${event.product_id}`)
        }
        if (event.entitlement_ids) {
          console.log(`   - Entitlement IDs: ${JSON.stringify(event.entitlement_ids)}`)
        }
        break
        
      case 'RENEWAL':
        // Renewal means trial is over and subscription is now active
        // This event is sent when trial converts to paid subscription OR regular renewal
        updateData.status = 'active'
        updateData.entitlement_status = 'active'
        if (event.expires_at) {
          updateData.current_period_end = new Date(event.expires_at).toISOString()
        }
        // Note: trial_end is not cleared - kept for historical reference
        // Status change from 'trialing' to 'active' indicates trial is over
        console.log(`   - Subscription renewed (trial completed, now active)`)
        
        // Extract transaction IDs from event
        if (event.transaction_id) {
          updateData.revenuecat_subscription_id = event.transaction_id
          console.log(`   - Setting revenuecat_subscription_id: ${event.transaction_id}`)
        } else {
          console.log(`   ⚠️ No transaction_id in event`)
        }
        
        if (event.original_transaction_id) {
          updateData.original_transaction_id = event.original_transaction_id
          console.log(`   - Setting original_transaction_id: ${event.original_transaction_id}`)
        } else {
          console.log(`   ⚠️ No original_transaction_id in event`)
        }
        
        // Log all event fields for debugging
        console.log(`   - Event fields: ${JSON.stringify(Object.keys(event))}`)
        if (event.product_id) {
          console.log(`   - Product ID: ${event.product_id}`)
        }
        if (event.entitlement_ids) {
          console.log(`   - Entitlement IDs: ${JSON.stringify(event.entitlement_ids)}`)
        }
        break
        
      case 'CANCELLATION':
        updateData.status = 'inactive'
        updateData.entitlement_status = 'expired'
        // Keep subscription_id for reference
        break
        
      case 'UNCANCELLATION':
        updateData.status = 'active'
        updateData.entitlement_status = 'active'
        if (event.expires_at) {
          updateData.current_period_end = new Date(event.expires_at).toISOString()
        }
        break
        
      case 'NON_RENEWING_PURCHASE':
        // One-time purchase, not a subscription
        updateData.status = 'active'
        updateData.entitlement_status = 'active'
        if (event.expires_at) {
          updateData.current_period_end = new Date(event.expires_at).toISOString()
        }
        break
        
      case 'BILLING_ISSUE':
        updateData.status = 'past_due'
        updateData.entitlement_status = 'billing_issue'
        break
        
      case 'SUBSCRIPTION_PAUSED':
        updateData.status = 'paused'
        updateData.entitlement_status = 'paused'
        break
        
      case 'SUBSCRIPTION_UNPAUSED':
        updateData.status = 'active'
        updateData.entitlement_status = 'active'
        if (event.expires_at) {
          updateData.current_period_end = new Date(event.expires_at).toISOString()
        }
        break
        
      case 'PRODUCT_CHANGE':
        // User upgraded/downgraded plan
        updateData.status = 'active'
        updateData.entitlement_status = 'active'
        if (event.expires_at) {
          updateData.current_period_end = new Date(event.expires_at).toISOString()
        }
        if (event.transaction_id) {
          updateData.revenuecat_subscription_id = event.transaction_id
        }
        break
        
      case 'SUBSCRIPTION_EXTENDED':
        // Subscription period extended (promotional)
        updateData.status = 'active'
        updateData.entitlement_status = 'active'
        if (event.expires_at) {
          updateData.current_period_end = new Date(event.expires_at).toISOString()
        }
        break
        
      case 'EXPIRATION':
        // Subscription expired - could be trial expired without payment or regular expiration
        updateData.status = 'inactive'
        updateData.entitlement_status = 'expired'
        updateData.current_period_end = new Date().toISOString()
        console.log(`   - Subscription expired (trial ended without payment or subscription cancelled)`)
        break
        
      default:
        // Unknown event type - log but don't update status
        console.log(`⚠️ Unknown event type: ${eventType}`)
        // Safely log event data (avoid circular reference errors)
        try {
          console.log(`   Event keys: ${JSON.stringify(Object.keys(event))}`)
          // Log specific fields that are safe to stringify
          if (event.product_id) console.log(`   - product_id: ${event.product_id}`)
          if (event.entitlement_ids) console.log(`   - entitlement_ids: ${JSON.stringify(event.entitlement_ids)}`)
          if (event.transaction_id) console.log(`   - transaction_id: ${event.transaction_id}`)
          if (event.original_transaction_id) console.log(`   - original_transaction_id: ${event.original_transaction_id}`)
        } catch (logError) {
          console.log(`   ⚠️ Could not log event data: ${logError}`)
        }
        // Don't update status for unknown events
        break
    }

    // Upsert user_subscriptions record
    const upsertData = {
      user_id: userId,
      revenuecat_user_id: appUserId,
      revenuecat_subscription_id: updateData.revenuecat_subscription_id,
      entitlement_status: updateData.entitlement_status,
      original_transaction_id: updateData.original_transaction_id,
      status: updateData.status,
      current_period_end: updateData.current_period_end,
      trial_end: updateData.trial_end,
      updated_at: updateData.updated_at
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

    console.log(`✅ Updated user_subscriptions for user ${userId}, status: ${updateData.status}`)
    
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

