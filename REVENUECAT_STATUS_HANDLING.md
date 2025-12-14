# RevenueCat Status Handling Guide

## Overview
This document outlines how we handle different subscription status values from RevenueCat webhooks and the RevenueCat SDK.

## Status Values

### Subscription Status (`status` column)
The `status` column in `user_subscriptions` represents the overall subscription state:

- **`active`**: Subscription is active and billing normally
- **`trialing`**: User is in free trial period
- **`past_due`**: Subscription has billing issues but is still active (grace period)
- **`paused`**: Subscription is paused (iOS subscription pause feature)
- **`inactive`**: Subscription is cancelled or expired

### Entitlement Status (`entitlement_status` column)
The `entitlement_status` column tracks the RevenueCat entitlement state:

- **`active`**: Entitlement is active and user has access
- **`expired`**: Entitlement has expired, user no longer has access
- **`billing_issue`**: Payment failed, but user may still have access during grace period
- **`paused`**: Entitlement is paused (iOS subscription pause)

## RevenueCat Webhook Event Types

### Event Type → Status Mapping

| RevenueCat Event | `status` | `entitlement_status` | Notes |
|-----------------|----------|---------------------|-------|
| `INITIAL_PURCHASE` | `active` or `trialing` | `active` | If `trial_ends_at` exists, status is `trialing` |
| `RENEWAL` | `active` | `active` | Subscription renewed successfully |
| `CANCELLATION` | `inactive` | `expired` | User cancelled, but subscription may still be active until period end |
| `UNCANCELLATION` | `active` | `active` | User uncancelled before expiration |
| `NON_RENEWING_PURCHASE` | `active` | `active` | One-time purchase (not subscription) |
| `BILLING_ISSUE` | `past_due` | `billing_issue` | Payment failed, but subscription may still be active |
| `SUBSCRIPTION_PAUSED` | `paused` | `paused` | iOS subscription pause feature |
| `SUBSCRIPTION_UNPAUSED` | `active` | `active` | Subscription unpaused |
| `EXPIRATION` | `inactive` | `expired` | Subscription expired |
| `PRODUCT_CHANGE` | `active` | `active` | User upgraded/downgraded plan |
| `SUBSCRIPTION_EXTENDED` | `active` | `active` | Subscription period extended (promotional) |

## Access Control Logic

### When Should Users Have Access?

Users should have access to premium features when:
1. `status` is `active` OR `trialing` OR `past_due` OR `paused`
2. AND `entitlement_status` is `active` OR `billing_issue` OR `paused`

**Important Notes:**
- `past_due`: User may still have access during grace period (depends on RevenueCat configuration)
- `paused`: User has access but subscription is paused (iOS feature)
- `billing_issue`: User may have access during grace period

### When Should Users NOT Have Access?

Users should NOT have access when:
1. `status` is `inactive`
2. OR `entitlement_status` is `expired`

## Database Schema

The `user_subscriptions` table should allow these status values. No CHECK constraints should restrict these values - we use TEXT columns to allow flexibility.

## Swift Code Handling

### `UserSubscription.isActive` Property

Currently only checks `status == "active" || status == "trialing"`. This needs to be updated to also include:
- `status == "past_due"` (if we want to allow access during grace period)
- `status == "paused"` (if we want to allow access when paused)

**Recommendation**: Check both `status` AND `entitlement_status`:
- `status` in `["active", "trialing", "past_due", "paused"]`
- AND `entitlement_status` in `["active", "billing_issue", "paused"]`

### Status Display Messages

Update `accessStatusMessage` to handle all statuses:
- `active`: "Active subscription"
- `trialing`: "Free trial until [date]"
- `past_due`: "Payment issue - please update payment method"
- `paused`: "Subscription paused"
- `inactive`: "Subscription required"

## Webhook Implementation

The webhook should:
1. Handle ALL event types listed above
2. Map events to appropriate status values
3. Always update `revenuecat_user_id` to ensure it's current
4. Update `current_period_end` and `trial_end` when available
5. Log all status changes for debugging

## Edge Cases

### 1. Grace Period (`past_due` + `billing_issue`)
- User's payment failed
- RevenueCat may still grant access during grace period
- We should check `entitlement_status` to determine access

### 2. Subscription Pause (`paused`)
- iOS allows users to pause subscriptions
- User may still have access during pause
- Check both `status` and `entitlement_status`

### 3. Cancelled but Active (`CANCELLATION` event)
- User cancelled, but subscription is still active until period end
- Status should be `inactive`, but entitlement may still be `active` until expiration
- Check `current_period_end` to determine actual access

### 4. Missing Event Types
- If we receive an unknown event type, log it and don't update status
- Default to safe state (no access) if uncertain

## Testing Checklist

- [ ] Test `INITIAL_PURCHASE` with trial → should be `trialing`
- [ ] Test `INITIAL_PURCHASE` without trial → should be `active`
- [ ] Test `RENEWAL` → should be `active`
- [ ] Test `CANCELLATION` → should be `inactive` + `expired`
- [ ] Test `UNCANCELLATION` → should be `active` + `active`
- [ ] Test `BILLING_ISSUE` → should be `past_due` + `billing_issue`
- [ ] Test `SUBSCRIPTION_PAUSED` → should be `paused` + `paused`
- [ ] Test `SUBSCRIPTION_UNPAUSED` → should be `active` + `active`
- [ ] Test `EXPIRATION` → should be `inactive` + `expired`
- [ ] Test `PRODUCT_CHANGE` → should be `active` + `active`
- [ ] Verify access control logic for each status combination
- [ ] Verify UI displays correct status messages

