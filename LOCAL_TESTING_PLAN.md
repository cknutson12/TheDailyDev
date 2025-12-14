# Local Testing Plan (Without App Store Connect)

This plan covers everything you can test **without** an Apple Developer account or App Store Connect setup.

## ✅ What You CAN Test Locally

### Test Category 1: SDK Initialization & Configuration

#### Test 1.1: RevenueCat SDK Initialization
- [ ] **Action**: Build and run the app
- [ ] **Expected**: Check Xcode console for:
  ```
  ✅ RevenueCat SDK initialized with API key
  ```
- [ ] **Verify**: No errors related to RevenueCat initialization
- [ ] **Location**: `TheDailyDevApp.swift` - `init()` method

#### Test 1.2: API Key Configuration
- [ ] **Action**: Verify API key is loaded correctly
- [ ] **Expected**: API key from `Config-Secrets.plist` is used
- [ ] **Verify**: Check that `Config.revenueCatAPIKey` returns the test key
- [ ] **Location**: `Config.swift`

#### Test 1.3: SDK Configuration on App Launch
- [ ] **Action**: Launch app and check console logs
- [ ] **Expected**: RevenueCat SDK configured without errors
- [ ] **Verify**: No fatal errors or crashes related to RevenueCat

---

### Test Category 2: User Authentication & RevenueCat User ID

#### Test 2.1: User ID Set on Login
- [ ] **Action**: Sign in with email/password
- [ ] **Expected**: Console shows:
  ```
  ✅ RevenueCat user ID set: [user-uuid]
  ```
- [ ] **Verify**: User ID matches Supabase user ID
- [ ] **Location**: `LoginView.swift` → `signIn()` method

#### Test 2.2: User ID Set on Sign Up
- [ ] **Action**: Create new account
- [ ] **Expected**: Console shows RevenueCat user ID set
- [ ] **Verify**: User ID is set correctly
- [ ] **Location**: `SignUpView.swift` → `signUp()` method

#### Test 2.3: User ID Set on OAuth Login
- [ ] **Action**: Sign in with Google or GitHub
- [ ] **Expected**: RevenueCat user ID set after OAuth callback
- [ ] **Verify**: User ID matches authenticated user
- [ ] **Location**: `LoginView.swift` → OAuth methods

#### Test 2.4: User ID Cleared on Sign Out
- [ ] **Action**: Sign out of the app
- [ ] **Expected**: RevenueCat user ID cleared (check console)
- [ ] **Verify**: No errors on sign out
- [ ] **Location**: `AuthManager.swift` → `signOut()` method

#### Test 2.5: User ID Set on App Launch (Existing Session)
- [ ] **Action**: Close and reopen app with existing session
- [ ] **Expected**: RevenueCat user ID set automatically
- [ ] **Verify**: Check console on app launch
- [ ] **Location**: `ContentView.swift` → `.task` modifier

---

### Test Category 3: Subscription Plans Fetching

#### Test 3.1: Fetch Plans from Database
- [ ] **Action**: Navigate to subscription benefits view
- [ ] **Expected**: Plans load from database (monthly and yearly)
- [ ] **Verify**: Plans display with correct:
  - Names
  - Prices
  - Billing periods
  - Descriptions
- [ ] **Location**: `SubscriptionService.swift` → `fetchAllPlans()`

#### Test 3.2: RevenueCat Product IDs in Plans
- [ ] **Action**: Check database `subscription_plans` table
- [ ] **Expected**: Both plans have `revenuecat_product_id` set:
  - Monthly: `revenuecat_product_id = 'monthly'`
  - Yearly: `revenuecat_product_id = 'yearly'`
- [ ] **Verify**: Query database to confirm values

#### Test 3.3: Plans Display in UI
- [ ] **Action**: Open subscription benefits view
- [ ] **Expected**: Both plans visible with:
  - Correct pricing
  - Trial information (if configured)
  - Subscribe buttons
- [ ] **Verify**: UI matches database values
- [ ] **Location**: `SubscriptionBenefitsView.swift`

---

### Test Category 4: Paywall UI & Navigation

#### Test 4.1: RevenueCat Paywall Display
- [ ] **Action**: Tap "Subscribe" button
- [ ] **Expected**: `RevenueCatPaywallView` appears as sheet
- [ ] **Verify**: Paywall view displays correctly
- [ ] **Location**: `SubscriptionBenefitsView.swift` → `showingRevenueCatPaywall`

#### Test 4.2: Paywall Shows Offerings
- [ ] **Action**: Open paywall view
- [ ] **Expected**: Paywall attempts to load offerings from RevenueCat
- [ ] **Verify**: Check console for:
  - Loading state
  - Offerings fetch attempt
  - Error messages (expected: no offerings without App Store Connect)
- [ ] **Location**: `RevenueCatPaywallView.swift`

#### Test 4.3: Paywall Error Handling
- [ ] **Action**: Open paywall (will fail without App Store Connect)
- [ ] **Expected**: Error message displayed gracefully
- [ ] **Verify**: User-friendly error message, not crash
- [ ] **Location**: `RevenueCatPaywallView.swift` → error handling

#### Test 4.4: Paywall Dismissal
- [ ] **Action**: Tap "Cancel" or swipe down on paywall
- [ ] **Expected**: Paywall dismisses smoothly
- [ ] **Verify**: No crashes or UI glitches
- [ ] **Location**: `RevenueCatPaywallView.swift` → `dismiss` action

---

### Test Category 5: Subscription Status Checking

#### Test 5.1: Fetch Subscription Status
- [ ] **Action**: Check subscription status in app
- [ ] **Expected**: Status fetched from database
- [ ] **Verify**: Console shows status fetch attempt
- [ ] **Location**: `SubscriptionService.swift` → `fetchSubscriptionStatus()`

#### Test 5.2: No Active Subscription State
- [ ] **Action**: Check status for user without subscription
- [ ] **Expected**: Status shows as "inactive" or null
- [ ] **Verify**: UI reflects no active subscription
- [ ] **Location**: `SubscriptionService.swift`

#### Test 5.3: Entitlement Checking Logic
- [ ] **Action**: Try to access questions without subscription
- [ ] **Expected**: Paywall shown or access denied
- [ ] **Verify**: `canAccessQuestions()` returns `false`
- [ ] **Location**: `SubscriptionService.swift` → `canAccessQuestions()`

#### Test 5.4: Mock Active Subscription (Database Test)
- [ ] **Action**: Manually update database:
  ```sql
  UPDATE user_subscriptions
  SET status = 'active',
      revenuecat_user_id = '[your-user-id]',
      entitlement_status = 'active'
  WHERE user_id = '[your-user-id]';
  ```
- [ ] **Expected**: App recognizes active subscription
- [ ] **Verify**: `canAccessQuestions()` returns `true`
- [ ] **Location**: Test entitlement checking with mock data

---

### Test Category 6: Database Integration

#### Test 6.1: RevenueCat Columns Exist
- [ ] **Action**: Query `user_subscriptions` table
- [ ] **Expected**: Columns exist:
  - `revenuecat_user_id`
  - `revenuecat_subscription_id`
  - `entitlement_status`
  - `original_transaction_id`
- [ ] **Verify**: Run SQL query to check columns

#### Test 6.2: Subscription Plans Columns
- [ ] **Action**: Query `subscription_plans` table
- [ ] **Expected**: Columns exist:
  - `revenuecat_product_id`
  - `revenuecat_package_id`
- [ ] **Verify**: Run SQL query to check columns

#### Test 6.3: Database Sync Method
- [ ] **Action**: Check `syncRevenueCatStatus()` method
- [ ] **Expected**: Method exists and handles errors gracefully
- [ ] **Verify**: Code review - method structure is correct
- [ ] **Location**: `SubscriptionService.swift` → `syncRevenueCatStatus()`

---

### Test Category 7: Webhook Endpoint Structure

#### Test 7.1: Webhook Function Exists
- [ ] **Action**: Check Edge Function file
- [ ] **Expected**: `supabase/functions/revenuecat-webhook/index.ts` exists
- [ ] **Verify**: File is present and readable

#### Test 7.2: Webhook Function Structure
- [ ] **Action**: Review webhook code
- [ ] **Expected**: Function handles:
  - Authorization header check
  - Event parsing
  - User ID resolution
  - Database updates
- [ ] **Verify**: Code structure is correct
- [ ] **Location**: `supabase/functions/revenuecat-webhook/index.ts`

#### Test 7.3: Webhook Event Types
- [ ] **Action**: Review switch statement
- [ ] **Expected**: Handles all event types:
  - INITIAL_PURCHASE
  - RENEWAL
  - CANCELLATION
  - UNCANCELLATION
  - EXPIRATION
  - BILLING_ISSUE
- [ ] **Verify**: All cases are handled
- [ ] **Location**: Webhook function event handling

---

### Test Category 8: Error Handling

#### Test 8.1: Network Errors
- [ ] **Action**: Enable airplane mode, try to fetch offerings
- [ ] **Expected**: Graceful error handling
- [ ] **Verify**: User-friendly error message, no crash
- [ ] **Location**: `RevenueCatPaywallView.swift`

#### Test 8.2: Invalid API Key
- [ ] **Action**: Temporarily change API key to invalid value
- [ ] **Expected**: Error logged, app doesn't crash
- [ ] **Verify**: Error handling works
- [ ] **Location**: `TheDailyDevApp.swift`

#### Test 8.3: Missing Configuration
- [ ] **Action**: Check what happens if config values are missing
- [ ] **Expected**: Appropriate fallbacks or errors
- [ ] **Verify**: No crashes
- [ ] **Location**: `Config.swift`

---

### Test Category 9: UI/UX Flow

#### Test 9.1: Navigation to Subscription View
- [ ] **Action**: Navigate from home to subscription benefits
- [ ] **Expected**: Smooth navigation
- [ ] **Verify**: No UI glitches

#### Test 9.2: Subscription Settings View
- [ ] **Action**: Open subscription settings
- [ ] **Expected**: View displays correctly
- [ ] **Verify**: Shows current subscription status
- [ ] **Location**: `SubscriptionSettingsView.swift`

#### Test 9.3: Customer Center Button
- [ ] **Action**: Check if "Manage Subscription" button exists
- [ ] **Expected**: Button visible (will show error without App Store Connect)
- [ ] **Verify**: Button doesn't crash app
- [ ] **Location**: `SubscriptionSettingsView.swift`

---

### Test Category 10: Code Quality & Architecture

#### Test 10.1: Provider Pattern Implementation
- [ ] **Action**: Review `SubscriptionProvider` protocol
- [ ] **Expected**: Protocol defines all required methods
- [ ] **Verify**: `RevenueCatSubscriptionProvider` conforms correctly
- [ ] **Location**: `SubscriptionProvider.swift`, `RevenueCatSubscriptionProvider.swift`

#### Test 10.2: No Hardcoded Values
- [ ] **Action**: Review code for hardcoded product IDs
- [ ] **Expected**: All IDs come from `Config.swift`
- [ ] **Verify**: No magic strings in code
- [ ] **Location**: All RevenueCat-related files

#### Test 10.3: Error Types
- [ ] **Action**: Check error handling
- [ ] **Expected**: Proper error types used
- [ ] **Verify**: Errors are user-friendly
- [ ] **Location**: Error handling throughout

---

## ❌ What You CANNOT Test Without App Store Connect

These tests require App Store Connect setup:

1. **Actual Purchase Flow**
   - Cannot test native iOS purchase sheet
   - Cannot test StoreKit purchase completion
   - Cannot test subscription activation

2. **Real Subscription Status**
   - Cannot test with real active subscriptions
   - Cannot test renewal events
   - Cannot test cancellation flow

3. **Webhook Events**
   - Cannot receive real webhook events from RevenueCat
   - Cannot test webhook processing with real data
   - Cannot verify webhook → database updates

4. **Entitlement Verification**
   - Cannot test real entitlement checking
   - Cannot verify access control with real subscriptions

5. **Restore Purchases**
   - Cannot test restore functionality
   - Cannot test cross-device subscription sync

---

## Testing Checklist Summary

### Quick Test Run (15 minutes)
- [ ] Build app successfully
- [ ] SDK initializes without errors
- [ ] User ID sets on login
- [ ] Paywall UI displays
- [ ] No crashes or errors

### Comprehensive Test Run (1-2 hours)
- [ ] Complete all Test Category 1-10 items
- [ ] Test all UI flows
- [ ] Verify database structure
- [ ] Check error handling
- [ ] Review code quality

---

## Mock Data Testing

You can test with mock database data:

### Create Mock Active Subscription
```sql
-- Replace [your-user-id] with actual user ID
UPDATE user_subscriptions
SET 
    status = 'active',
    revenuecat_user_id = '[your-user-id]',
    entitlement_status = 'active',
    current_period_end = (NOW() + INTERVAL '1 month')::text
WHERE user_id = '[your-user-id]';
```

### Test Entitlement Checking
After creating mock subscription:
- [ ] Verify `canAccessQuestions()` returns `true`
- [ ] Verify questions are accessible
- [ ] Verify subscription status shows as active

### Reset to Inactive
```sql
UPDATE user_subscriptions
SET 
    status = 'inactive',
    entitlement_status = 'expired'
WHERE user_id = '[your-user-id]';
```

---

## Expected Console Output

### Successful Initialization
```
✅ RevenueCat SDK initialized with API key
✅ RevenueCat user ID set: [uuid]
```

### Expected Errors (Without App Store Connect)
```
⚠️ No current offering found in RevenueCat
⚠️ No package found with product ID: monthly
```

These errors are **expected** and **normal** without App Store Connect setup.

---

## Next Steps After Local Testing

Once you get an Apple Developer account:

1. Set up App Store Connect (see `APP_STORE_CONNECT_SETUP.md`)
2. Create subscription products
3. Test actual purchase flow
4. Test webhook events
5. Test restore purchases
6. Test subscription lifecycle (renewal, cancellation)

---

## Testing Notes

- **Focus Areas**: SDK initialization, UI flows, error handling, database structure
- **Expected Issues**: Offerings won't load (normal without App Store Connect)
- **Success Criteria**: No crashes, proper error handling, UI works correctly
- **Time Estimate**: 1-2 hours for comprehensive testing

