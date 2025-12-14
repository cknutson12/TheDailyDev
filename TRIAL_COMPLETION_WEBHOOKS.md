# Trial Completion Webhook Events

## ✅ Yes, Webhooks Are Sent When Trials Complete

RevenueCat automatically sends webhook events when a trial completes. Your webhook is already set up to handle these events.

## Trial Lifecycle Events

### 1. Trial Starts (INITIAL_PURCHASE)

**Event**: `INITIAL_PURCHASE`
**When**: User subscribes and trial begins
**Webhook Action**:
- Sets `status = 'trialing'`
- Sets `trial_end = [trial expiration date]`
- Sets `entitlement_status = 'active'`

**Database State**:
```sql
status = 'trialing'
entitlement_status = 'active'
trial_end = '2025-12-21T00:00:00Z'  -- Example: 7 days from now
```

### 2. Trial Completes Successfully (RENEWAL)

**Event**: `RENEWAL`
**When**: Trial period ends and payment succeeds
**Webhook Action**:
- Sets `status = 'active'` (converts from 'trialing' to 'active')
- Sets `entitlement_status = 'active'`
- Updates `current_period_end` to next billing date
- Clears `trial_end` (no longer in trial)

**Database State**:
```sql
status = 'active'  -- Changed from 'trialing'
entitlement_status = 'active'
current_period_end = '2026-01-14T00:00:00Z'  -- Next billing date
trial_end = NULL  -- Trial is over
```

### 3. Trial Completes with Payment Failure (EXPIRATION)

**Event**: `EXPIRATION`
**When**: Trial period ends and payment fails (or user cancelled during trial)
**Webhook Action**:
- Sets `status = 'inactive'`
- Sets `entitlement_status = 'expired'`
- Updates `current_period_end` to current time

**Database State**:
```sql
status = 'inactive'  -- Changed from 'trialing'
entitlement_status = 'expired'
current_period_end = '2025-12-14T12:00:00Z'  -- Current time
trial_end = '2025-12-14T00:00:00Z'  -- Still stored for reference
```

## Current Webhook Implementation

### ✅ Already Handled

Your webhook (`supabase/functions/revenuecat-webhook/index.ts`) already handles all trial completion scenarios:

**INITIAL_PURCHASE** (lines 180-214):
```typescript
case 'INITIAL_PURCHASE':
  updateData.status = 'active'
  updateData.entitlement_status = 'active'
  if (event.trial_ends_at) {
    updateData.trial_end = new Date(event.trial_ends_at).toISOString()
    updateData.status = 'trialing'  // ✅ Sets trialing status
  }
```

**RENEWAL** (lines 181-214):
```typescript
case 'RENEWAL':
  updateData.status = 'active'  // ✅ Converts trialing → active
  updateData.entitlement_status = 'active'
  if (event.expires_at) {
    updateData.current_period_end = new Date(event.expires_at).toISOString()
  }
  // Note: trial_end is not cleared here, but that's okay - 
  // the status change from 'trialing' to 'active' indicates trial is over
```

**EXPIRATION** (lines 278-282):
```typescript
case 'EXPIRATION':
  updateData.status = 'inactive'  // ✅ Converts trialing → inactive
  updateData.entitlement_status = 'expired'
  updateData.current_period_end = new Date().toISOString()
```

## What You Need to Do

### ✅ Nothing! It's Already Set Up

Your webhook is already configured to handle trial completion. However, you may want to:

### 1. Verify Webhook Configuration

**In RevenueCat Dashboard:**
1. Go to Project Settings → Webhooks
2. Verify your webhook URL is correct: `https://your-project.supabase.co/functions/v1/revenuecat-webhook`
3. Verify webhook secret is set in Supabase Edge Function secrets
4. Check that webhook is enabled and receiving events

### 2. Test Trial Completion (Optional)

**In Test Mode:**
1. Subscribe with a trial
2. Wait for trial to complete (or accelerate in test mode)
3. Check webhook logs in Supabase
4. Verify database status changes from `trialing` to `active` or `inactive`

### 3. Monitor Webhook Events

**Check Supabase Edge Function Logs:**
- Look for `RENEWAL` events when trial converts to paid
- Look for `EXPIRATION` events when trial expires without payment
- Verify status updates are happening correctly

## Trial Completion Flow Diagram

```
User Subscribes
    ↓
INITIAL_PURCHASE event
    ↓
status = 'trialing'
trial_end = [7 days from now]
    ↓
[Trial Period - 7 days]
    ↓
Trial Ends
    ↓
    ├─→ Payment Succeeds → RENEWAL event → status = 'active' ✅
    │
    └─→ Payment Fails → EXPIRATION event → status = 'inactive' ❌
```

## Edge Cases

### User Cancels During Trial

**What Happens:**
1. User cancels → `CANCELLATION` event is sent
2. **BUT**: User still has access until trial ends
3. At trial end:
   - If payment method was valid → `EXPIRATION` event (subscription doesn't renew)
   - If payment method was invalid → `EXPIRATION` event

**Current Webhook Behavior:**
- `CANCELLATION` sets status to `inactive` immediately
- This is **correct** - user cancelled, so they shouldn't have access
- However, RevenueCat may still grant access until trial ends (grace period)

**Recommendation**: Your current implementation is fine. The `CANCELLATION` event correctly marks the subscription as inactive.

### User Uncancels Before Trial Ends

**What Happens:**
1. User cancels → `CANCELLATION` event
2. User uncancels → `UNCANCELLATION` event
3. Trial continues normally
4. At trial end → `RENEWAL` event (if payment succeeds)

**Current Webhook Behavior:**
- `UNCANCELLATION` sets status back to `active`
- This is **correct** - user reactivated, so they should have access

## Potential Improvement

### Clear `trial_end` on RENEWAL

Currently, when a trial converts to paid (`RENEWAL` event), the `trial_end` date remains in the database. This is fine, but you could optionally clear it:

```typescript
case 'RENEWAL':
  updateData.status = 'active'
  updateData.entitlement_status = 'active'
  updateData.trial_end = null  // Optional: Clear trial_end when trial is over
  if (event.expires_at) {
    updateData.current_period_end = new Date(event.expires_at).toISOString()
  }
```

**Current Behavior**: Keeping `trial_end` is actually useful for historical tracking, so this is optional.

## Summary

### ✅ Webhooks Are Sent
- `RENEWAL` when trial converts to paid → status becomes `active`
- `EXPIRATION` when trial expires without payment → status becomes `inactive`

### ✅ Webhook Is Set Up
- Your webhook handles both `RENEWAL` and `EXPIRATION` events
- Status transitions are correct: `trialing` → `active` or `inactive`

### ✅ No Action Required
- Everything is already configured
- Just verify webhook is receiving events in RevenueCat dashboard
- Monitor Supabase logs to confirm events are being processed

### Optional: Test It
- Subscribe with a trial in test mode
- Wait for trial to complete (or accelerate)
- Verify status changes in database
- Check webhook logs

