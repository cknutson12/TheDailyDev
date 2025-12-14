# RevenueCat ID Mapping & Edge Cases Guide

## Overview

This document explains how RevenueCat IDs interact with Supabase IDs, the data flow, and how to handle edge cases.

## ID Types & Their Purpose

### 1. Supabase User ID (`user_id`)
- **What**: UUID from Supabase Auth (e.g., `19A36551-03F9-4A64-A772-2AA0CCB4A9A1`)
- **Where**: `auth.users.id` in Supabase
- **Purpose**: Primary identifier for users in your app
- **Uniqueness**: Globally unique per user
- **Persistence**: Never changes, even if user deletes/recreates account

### 2. RevenueCat App User ID (`revenuecat_user_id`)
- **What**: User identifier in RevenueCat (can be UUID or anonymous ID)
- **Where**: RevenueCat dashboard, `user_subscriptions.revenuecat_user_id` in database
- **Purpose**: Links RevenueCat purchases to your user
- **Uniqueness**: One per RevenueCat customer
- **Persistence**: Can change if user logs in/out or if you call `logIn()` with different ID

### 3. RevenueCat Subscription ID (`revenuecat_subscription_id`)
- **What**: Transaction/subscription identifier from RevenueCat
- **Where**: `user_subscriptions.revenuecat_subscription_id` in database
- **Purpose**: Tracks specific subscription transactions
- **Uniqueness**: One per purchase transaction
- **Persistence**: Changes on renewal, cancellation, or new purchase

### 4. Original Transaction ID (`original_transaction_id`)
- **What**: First transaction ID for a subscription (for restore purchases)
- **Where**: `user_subscriptions.original_transaction_id` in database
- **Purpose**: Allows restoring purchases across devices
- **Uniqueness**: One per subscription lifecycle
- **Persistence**: Never changes for a subscription

## ID Mapping Flow

### Initial Setup (User Signs Up)

```
1. User signs up → Supabase creates user
   └─> user_id: "19A36551-03F9-4A64-A772-2AA0CCB4A9A1"

2. App calls Purchases.shared.logIn(user_id)
   └─> RevenueCat creates/links customer
   └─> RevenueCat App User ID = Supabase user_id
   └─> Stored in: user_subscriptions.revenuecat_user_id

3. Database record created:
   user_subscriptions {
     user_id: "19A36551-03F9-4A64-A772-2AA0CCB4A9A1"
     revenuecat_user_id: "19A36551-03F9-4A64-A772-2AA0CCB4A9A1"  // Same as user_id
     status: "inactive"
   }
```

### Purchase Flow

```
1. User purchases subscription
   └─> RevenueCat processes purchase
   └─> Creates transaction: "test_1765647825891_1C78EE86-7292-4373-B468-F04B74D32455"

2. RevenueCat webhook fires:
   {
     app_user_id: "19A36551-03F9-4A64-A772-2AA0CCB4A9A1"  // Supabase user_id
     transaction_id: "test_1765647825891_1C78EE86-7292-4373-B468-F04B74D32455"
     original_transaction_id: "test_1765647825891_1C78EE86-7292-4373-B468-F04B74D32455"
   }

3. Webhook updates database:
   user_subscriptions {
     user_id: "19A36551-03F9-4A64-A772-2AA0CCB4A9A1"
     revenuecat_user_id: "19A36551-03F9-4A64-A772-2AA0CCB4A9A1"
     revenuecat_subscription_id: "test_1765647825891_1C78EE86-7292-4373-B468-F04B74D32455"
     original_transaction_id: "test_1765647825891_1C78EE86-7292-4373-B468-F04B74D32455"
     status: "active"
   }
```

### Renewal Flow

```
1. Subscription renews
   └─> RevenueCat processes renewal
   └─> New transaction: "test_1765651234567_2D89FF97-8393-5484-C579-G15C85E43566"

2. Webhook fires:
   {
     app_user_id: "19A36551-03F9-4A64-A772-2AA0CCB4A9A1"
     transaction_id: "test_1765651234567_2D89FF97-8393-5484-C579-G15C85E43566"  // NEW
     original_transaction_id: "test_1765647825891_1C78EE86-7292-4373-B468-F04B74D32455"  // SAME
   }

3. Database updated:
   user_subscriptions {
     revenuecat_subscription_id: "test_1765651234567_2D89FF97-8393-5484-C579-G15C85E43566"  // Updated
     original_transaction_id: "test_1765647825891_1C78EE86-7292-4373-B468-F04B74D32455"  // Unchanged
   }
```

## Edge Cases & Solutions

### Edge Case 1: Anonymous Purchases Before Login

**Scenario**: User makes purchase before signing in (anonymous RevenueCat customer)

**Problem**: 
- RevenueCat creates anonymous customer: `$RCAnonymousID:abc123xyz`
- User later signs in with Supabase user ID
- Need to link anonymous purchases to real user

**Solution**:
```swift
// In AuthManager.setRevenueCatUserID()
func setRevenueCatUserID() async {
    let userId = session.user.id.uuidString
    try await Purchases.shared.logIn(userId)
    // RevenueCat automatically transfers anonymous purchases to logged-in user
}
```

**Database Handling**:
- Webhook receives `app_user_id` = Supabase user_id after login
- Webhook updates `revenuecat_user_id` to match
- Anonymous purchases are now linked

### Edge Case 2: User Signs Out and Back In

**Scenario**: User signs out, then signs back in

**Problem**: 
- RevenueCat might create new anonymous customer
- Need to restore previous purchases

**Solution**:
```swift
// Always call logIn() after authentication
func setRevenueCatUserID() async {
    let userId = session.user.id.uuidString
    try await Purchases.shared.logIn(userId)
    // RevenueCat links to existing customer if user_id matches
}
```

**Database Handling**:
- Webhook checks if `revenuecat_user_id` exists for this `user_id`
- If exists, updates existing record
- If not, creates new record

### Edge Case 3: Multiple Devices

**Scenario**: User purchases on iPhone, then uses iPad

**Problem**: 
- Need to restore purchases on new device
- `original_transaction_id` is key for restore

**Solution**:
```swift
// In RevenueCatPaywallView
func restorePurchases() async {
    let customerInfo = try await Purchases.shared.restorePurchases()
    // RevenueCat uses original_transaction_id to restore
}
```

**Database Handling**:
- Webhook receives `original_transaction_id` from RevenueCat
- Matches against database to find existing subscription
- Updates `revenuecat_user_id` if user logged in on new device

### Edge Case 4: User ID Mismatch

**Scenario**: RevenueCat has different `app_user_id` than Supabase `user_id`

**Problem**: 
- Webhook can't find user in database
- Subscription status not updated

**Solution** (in webhook):
```typescript
// 1. Try to find by revenuecat_user_id
userId = await findUserByRevenueCatID(supabase, appUserId)

// 2. If not found, check if app_user_id is a Supabase UUID
if (!userId && isUUID(appUserId)) {
    userId = appUserId  // Use directly if it's a UUID
}

// 3. If still not found, check aliases
if (!userId && aliases) {
    userId = aliases['supabase_user_id']
}
```

### Edge Case 5: Webhook Arrives Before User Record Exists

**Scenario**: Purchase happens, webhook fires, but `user_subscriptions` record doesn't exist yet

**Problem**: 
- Webhook can't find user to update
- Returns error but subscription is active in RevenueCat

**Solution** (in webhook):
```typescript
// Webhook creates record if it doesn't exist
const upsertData = {
    user_id: userId,
    revenuecat_user_id: appUserId,
    status: 'active',
    // ... other fields
}

await supabase
    .from('user_subscriptions')
    .upsert(upsertData, { onConflict: 'user_id' })
```

### Edge Case 6: Subscription Cancelled but Still Active

**Scenario**: User cancels subscription, but it's still active until period ends

**Problem**: 
- Status should be "active" until expiration
- Not "inactive" immediately

**Solution** (in webhook):
```typescript
case 'CANCELLATION':
    // Don't set to inactive immediately
    // Keep status as "active" until expiration
    updateData.entitlement_status = 'cancelled'
    // Status remains "active" until expires_at
    break

case 'EXPIRATION':
    // Only set to inactive when actually expired
    updateData.status = 'inactive'
    break
```

### Edge Case 7: Test vs Production Purchases

**Scenario**: Test purchases in sandbox, production purchases in App Store

**Problem**: 
- Test transaction IDs look different
- Need to handle both

**Solution**:
- Test IDs: `test_1765647825891_...`
- Production IDs: `1000000123456789` (numeric)
- Webhook handles both formats
- Database stores both types

### Edge Case 8: User Deletes and Recreates Account

**Scenario**: User deletes account, then signs up again with same email

**Problem**: 
- New Supabase user_id (different UUID)
- Old RevenueCat purchases still linked to old user_id

**Solution**:
```swift
// When user signs up again
func setRevenueCatUserID() async {
    let userId = session.user.id.uuidString
    try await Purchases.shared.logIn(userId)
    // RevenueCat creates new customer with new user_id
    // Old purchases are NOT transferred (by design for security)
}
```

**Note**: This is intentional - prevents account hijacking. User would need to restore purchases manually.

## Database Schema

```sql
user_subscriptions {
    id: UUID (primary key)
    user_id: UUID (foreign key to auth.users, unique)
    
    -- RevenueCat fields
    revenuecat_user_id: TEXT  -- RevenueCat App User ID (usually = user_id)
    revenuecat_subscription_id: TEXT  -- Current transaction ID (changes on renewal)
    original_transaction_id: TEXT  -- First transaction (for restore)
    entitlement_status: TEXT  -- 'active', 'expired', 'cancelled', etc.
    
    -- Status fields
    status: TEXT  -- 'active', 'inactive', 'trialing', 'past_due'
    current_period_end: TIMESTAMP
    trial_end: TIMESTAMP
    
    -- Stripe fields (for main branch)
    stripe_customer_id: TEXT
    stripe_subscription_id: TEXT
}
```

## ID Lookup Strategies

### Strategy 1: Primary Lookup (Most Common)
```typescript
// Webhook receives app_user_id = Supabase user_id
// Direct lookup
SELECT * FROM user_subscriptions WHERE user_id = app_user_id
```

### Strategy 2: RevenueCat User ID Lookup
```typescript
// If app_user_id doesn't match user_id
SELECT * FROM user_subscriptions WHERE revenuecat_user_id = app_user_id
```

### Strategy 3: UUID Validation
```typescript
// If app_user_id is a UUID, check if it's a valid Supabase user
if (isUUID(appUserId)) {
    const user = await supabase.auth.admin.getUserById(appUserId)
    if (user) {
        userId = appUserId
    }
}
```

### Strategy 4: Alias Lookup
```typescript
// RevenueCat can store aliases
if (aliases['supabase_user_id']) {
    userId = aliases['supabase_user_id']
}
```

## Best Practices

### 1. Always Set User ID After Authentication
```swift
// In AuthManager, LoginView, SignUpView
await AuthManager.shared.setRevenueCatUserID()
```

### 2. Use Supabase User ID as RevenueCat App User ID
```swift
// This ensures 1:1 mapping
let userId = session.user.id.uuidString
try await Purchases.shared.logIn(userId)
```

### 3. Handle Webhook Failures Gracefully
```typescript
// Webhook should return 200 even if user not found
// Log error but don't fail webhook (RevenueCat will retry)
if (!userId) {
    console.error('User not found')
    return new Response(JSON.stringify({ received: true }), { status: 200 })
}
```

### 4. Store Original Transaction ID
```typescript
// Always store original_transaction_id for restore purchases
updateData.original_transaction_id = event.original_transaction_id
```

### 5. Sync Status Regularly
```swift
// In app, periodically sync with RevenueCat
await subscriptionService.fetchSubscriptionStatus(forceRefresh: true)
```

## Testing Scenarios

### Test 1: New User Purchase
1. User signs up
2. User ID set in RevenueCat
3. User purchases
4. Webhook updates database
5. ✅ Verify: `revenuecat_user_id` = `user_id`

### Test 2: Anonymous Purchase Then Login
1. User purchases without account (anonymous)
2. User signs up
3. User ID set in RevenueCat
4. ✅ Verify: Anonymous purchases transferred

### Test 3: Restore Purchases
1. User purchases on Device A
2. User signs in on Device B
3. User restores purchases
4. ✅ Verify: Subscription restored using `original_transaction_id`

### Test 4: Renewal
1. User has active subscription
2. Subscription renews
3. Webhook receives renewal event
4. ✅ Verify: `revenuecat_subscription_id` updated, `original_transaction_id` unchanged

### Test 5: Cancellation
1. User cancels subscription
2. Webhook receives cancellation event
3. ✅ Verify: Status remains "active" until expiration

## Troubleshooting

### Issue: Webhook can't find user
**Check**:
1. Is `app_user_id` in webhook = Supabase `user_id`?
2. Does `user_subscriptions` record exist?
3. Check webhook logs for user lookup attempts

### Issue: Purchases not restoring
**Check**:
1. Is `original_transaction_id` stored in database?
2. Is user logged in with same `user_id`?
3. Check RevenueCat dashboard for customer info

### Issue: Multiple customers in RevenueCat
**Check**:
1. Is `logIn()` called consistently after auth?
2. Are there anonymous purchases before login?
3. Check RevenueCat dashboard for customer aliases

### Issue: Subscription status out of sync
**Check**:
1. Are webhooks processing successfully (200 status)?
2. Is `syncRevenueCatStatus()` being called?
3. Check database vs RevenueCat dashboard

## Code References

### Setting User ID
- `AuthManager.setRevenueCatUserID()` - Sets RevenueCat App User ID
- Called in: `LoginView`, `SignUpView`, `ContentView`

### Webhook Processing
- `supabase/functions/revenuecat-webhook/index.ts` - Handles webhook events
- Maps `app_user_id` to Supabase `user_id`

### Status Sync
- `SubscriptionService.syncRevenueCatStatus()` - Syncs status from RevenueCat to database
- Called after purchases and periodically

### Restore Purchases
- `RevenueCatPaywallView.restorePurchases()` - Restores purchases using `original_transaction_id`

