# RevenueCat Trials, Testing, and A/B Experiments Guide

## 🔍 Test Mode vs Production: Card Entry

### Why You Don't See Card Entry in Test Mode

**In Test Mode (StoreKit Test Environment):**
- You **don't** enter a credit card
- Apple's StoreKit test environment handles payments automatically
- When you tap "Subscribe", you see a test purchase dialog
- No actual payment is processed
- This is **normal and expected** behavior

**In Production:**
- Users will see the **native iOS purchase sheet** (Apple's standard subscription UI)
- Users **don't enter a card in your app** - they use their **Apple ID payment method**
- The payment method is already configured in their iPhone Settings → Apple ID → Payment & Shipping
- Apple handles all payment processing securely
- Users authenticate with Face ID, Touch ID, or passcode

**Key Point**: RevenueCat uses **native iOS in-app purchases** via StoreKit. The payment flow is handled entirely by Apple, not by RevenueCat or your app. This is why you don't see card entry - it's all managed through the user's Apple ID.

### Test Mode Purchase Flow

1. User taps "Subscribe" in your app
2. RevenueCat SDK calls `Purchases.shared.purchase(package:)`
3. StoreKit shows test purchase dialog: "Test Purchase - This purchase won't appear in production"
4. User taps "Test Purchase" or "Valid Purchase"
5. Purchase completes (no card needed)
6. RevenueCat processes the test purchase
7. Webhook updates your database

### Production Purchase Flow

1. User taps "Subscribe" in your app
2. RevenueCat SDK calls `Purchases.shared.purchase(package:)`
3. **Native iOS purchase sheet appears** (Apple's standard UI)
4. User sees:
   - Product name and price
   - Trial period (if configured)
   - Subscription terms
   - "Subscribe" button
5. User authenticates with Face ID/Touch ID/passcode
6. Apple processes payment using user's Apple ID payment method
7. Purchase completes
8. RevenueCat processes the purchase
9. Webhook updates your database

## 🎁 Free Trials

### Current Setup Support

**✅ Your code already supports trials:**

1. **Webhook handles trials:**
   - Detects `trial_ends_at` in webhook events
   - Sets `status = 'trialing'` when trial is active
   - Stores `trial_end` date in database

2. **App code handles trials:**
   - `UserSubscription.isInTrial` computed property checks trial status
   - `UserSubscription.isActive` includes `"trialing"` as active status
   - Status messages show "Free trial until [date]"

3. **Database schema supports trials:**
   - `trial_end` column stores trial expiration date
   - `status` can be `"trialing"` during trial period

### How to Configure Trials

**In App Store Connect:**
1. Go to your subscription product (monthly or yearly)
2. Click "Edit"
3. Under "Subscription Pricing", set:
   - **Free Trial**: Choose duration (e.g., 7 days, 14 days, 1 month)
   - **Introductory Pricing**: Optional promotional pricing after trial
4. Save changes
5. Submit for review (if needed)

**In RevenueCat:**
- Trials are automatically detected from App Store Connect
- No additional configuration needed in RevenueCat dashboard
- RevenueCat will pass trial information through to your app

### Trial Flow

1. User subscribes → Trial starts
2. Webhook receives `INITIAL_PURCHASE` with `trial_ends_at`
3. Database updated: `status = 'trialing'`, `trial_end = [date]`
4. User has full access during trial
5. At trial end:
   - If payment succeeds → `status = 'active'` (RENEWAL event)
   - If payment fails → `status = 'inactive'` (EXPIRATION event)

### Testing Trials

**In Test Mode:**
- StoreKit test environment respects trial periods
- You can test the full trial → renewal flow
- Trial periods are accelerated in test mode (configurable)

**In Production:**
- Real trial periods apply
- Users get full trial duration
- Automatic conversion to paid at trial end

## 🧪 A/B Price Testing (Experiments)

### Current Setup Support

**✅ Your code supports A/B testing:**

- Uses RevenueCat `Offerings` which support experiments
- Fetches packages dynamically from RevenueCat
- No hardcoded prices - all come from RevenueCat
- Paywall displays whatever RevenueCat returns

### How RevenueCat Experiments Work

RevenueCat's **Experiments** feature allows you to:
- Test different prices for the same product
- Test different paywall designs
- Test different package configurations
- Split traffic automatically (50/50, 70/30, etc.)
- Track conversion rates per variant

### Setting Up A/B Price Testing

**Step 1: Create Products in App Store Connect**

Create multiple products with different prices:
- `monthly_99` - $9.99/month
- `monthly_499` - $4.99/month
- `monthly_799` - $7.99/month

**Step 2: Create Packages in RevenueCat**

1. Go to RevenueCat Dashboard → Product Catalog → Offerings
2. Select your offering
3. Create multiple packages for the same entitlement:
   - Package A: `monthly_99` product
   - Package B: `monthly_499` product
   - Package C: `monthly_799` product

**Step 3: Create Experiment**

1. Go to RevenueCat Dashboard → Experiments
2. Click "Create Experiment"
3. Configure:
   - **Name**: "Monthly Price Test"
   - **Type**: Paywall Experiment
   - **Offering**: Select your offering
   - **Variants**: 
     - Variant A: Package `monthly_99` (50% traffic)
     - Variant B: Package `monthly_499` (50% traffic)
   - **Metrics**: Conversion rate, revenue per user
4. Save experiment

**Step 4: Your App Automatically Uses Experiments**

- RevenueCat SDK automatically serves different variants to different users
- Your app code doesn't need changes - it just displays what RevenueCat returns
- RevenueCat tracks which variant each user sees
- Analytics show conversion rates per variant

### Code Requirements for A/B Testing

**✅ Your current code already supports this:**

```swift
// RevenueCatPaywallView.swift
let loadedPackages = try await provider.getAvailablePackages()
// This automatically gets the variant assigned to this user
```

The `getAvailablePackages()` method returns the packages for the user's assigned variant. No code changes needed!

### Testing A/B Experiments

**In Test Mode:**
- You can manually assign yourself to different variants
- Use RevenueCat dashboard to assign test users to variants
- Test different price points

**In Production:**
- RevenueCat automatically splits traffic
- Users are randomly assigned to variants
- You can see results in RevenueCat analytics

### Advanced: Paywall A/B Testing

RevenueCat also supports **Paywall A/B testing** where you can test:
- Different paywall designs
- Different copy/text
- Different package ordering
- Different CTAs

This requires using RevenueCat's Paywalls feature (separate from the native SDK). Your current implementation uses the native SDK, which is simpler but doesn't support paywall-level A/B testing.

**To enable Paywall A/B testing:**
1. Use RevenueCat Paywalls (web-based paywalls)
2. Configure experiments in RevenueCat dashboard
3. Update your app to use RevenueCat Paywalls instead of native SDK

**Current Recommendation**: Stick with native SDK for now. It's simpler and works great. You can always add Paywall A/B testing later if needed.

## 📊 Current Implementation Status

### ✅ Fully Supported

- **Trials**: ✅ Fully supported
  - Webhook handles trial events
  - App displays trial status
  - Database stores trial dates
  - Access control respects trial period

- **A/B Price Testing**: ✅ Supported via RevenueCat Experiments
  - Code fetches packages dynamically
  - No hardcoded prices
  - RevenueCat handles variant assignment
  - Analytics available in RevenueCat dashboard

### ⚠️ Requires Configuration

- **Trials**: Need to configure in App Store Connect
- **A/B Testing**: Need to set up experiments in RevenueCat dashboard

### ❌ Not Currently Supported

- **Paywall Design A/B Testing**: Would require RevenueCat Paywalls (web-based)
- **Custom Trial Logic**: Trials are handled by App Store Connect, not custom code

## 🚀 Next Steps

### To Enable Trials:

1. **In App Store Connect:**
   - Edit your subscription products
   - Add free trial period (e.g., 7 days)
   - Save and submit for review

2. **Test:**
   - Use StoreKit test environment
   - Subscribe and verify trial status
   - Check database for `trialing` status
   - Verify trial end date is set

### To Enable A/B Price Testing:

1. **Create multiple products** in App Store Connect with different prices
2. **Create packages** in RevenueCat for each product
3. **Create experiment** in RevenueCat dashboard
4. **Configure traffic split** (e.g., 50/50)
5. **Monitor results** in RevenueCat analytics

### Testing Checklist

- [ ] Configure trial in App Store Connect
- [ ] Test trial subscription in StoreKit test environment
- [ ] Verify webhook receives trial event
- [ ] Verify database shows `trialing` status
- [ ] Verify app displays trial information
- [ ] Create A/B experiment in RevenueCat
- [ ] Test different variants
- [ ] Verify analytics tracking

## 📝 Summary

**Card Entry:**
- ✅ Test mode: No card needed (StoreKit test environment)
- ✅ Production: Uses Apple ID payment method (no card entry in app)
- ✅ This is normal and expected behavior

**Trials:**
- ✅ Code fully supports trials
- ⚠️ Need to configure in App Store Connect
- ✅ Webhook and app handle trial status correctly

**A/B Price Testing:**
- ✅ Code fully supports A/B testing
- ⚠️ Need to set up experiments in RevenueCat dashboard
- ✅ No code changes needed - works automatically

