# App Store Connect Setup for RevenueCat

## What is App Store Connect?

**App Store Connect** is Apple's platform where you:
- Manage your iOS apps
- Upload app builds for review
- Configure in-app purchases and subscriptions
- Monitor app analytics and sales
- Manage app metadata and screenshots

## Why Do You Need It for RevenueCat?

RevenueCat uses **Apple's native in-app purchase system** (StoreKit) to process subscriptions. This means:
- RevenueCat acts as a middle layer that manages your subscriptions
- But the actual purchases go through Apple's App Store
- You **must** create subscription products in App Store Connect
- The product IDs must match between App Store Connect, RevenueCat, and your database

## Can You Test Without App Store Connect?

**Partial testing only:**
- ✅ You can test SDK initialization
- ✅ You can test UI flows (paywall display)
- ✅ You can test entitlement checking logic
- ❌ You **cannot** test actual purchases without App Store Connect products

## Step-by-Step: App Store Connect Setup

### Prerequisites

1. **Apple Developer Account** ($99/year)
   - If you don't have one: https://developer.apple.com/programs/
   - You need this to publish apps anyway

2. **App Created in App Store Connect**
   - Your app should be registered in App Store Connect
   - You can create it even if you haven't submitted for review yet

### Step 1: Access App Store Connect

1. Go to https://appstoreconnect.apple.com
2. Sign in with your Apple Developer account
3. Select your app (or create a new one)

### Step 2: Create Subscription Group

1. In your app, go to **Features** → **In-App Purchases**
2. Click **+** to create a new subscription
3. Select **Auto-Renewable Subscription**
4. Create a **Subscription Group**:
   - Name: "The Daily Dev Pro" (or your preferred name)
   - This groups your monthly and yearly plans together

### Step 3: Create Monthly Subscription Product

1. Within the subscription group, click **Create Subscription**
2. **Product ID**: `monthly` (must match exactly!)
3. **Reference Name**: "Monthly Subscription" (for your reference)
4. **Subscription Duration**: 1 Month
5. **Price**: Set your monthly price (e.g., $4.99)
6. **Free Trial**: Configure if desired (e.g., 7 days)
7. **Localizations**: Add display name and description
8. **Review Information**: Add screenshots if required
9. **Save**

### Step 4: Create Yearly Subscription Product

1. Click **Create Subscription** again
2. **Product ID**: `yearly` (must match exactly!)
3. **Reference Name**: "Yearly Subscription"
4. **Subscription Duration**: 1 Year
5. **Price**: Set your yearly price (e.g., $49.99)
6. **Free Trial**: Configure if desired
7. **Localizations**: Add display name and description
8. **Save**

### Step 5: Link to RevenueCat

1. In RevenueCat Dashboard → **Products**
2. For each product (`monthly` and `yearly`):
   - Make sure the **Product ID** matches App Store Connect exactly
   - RevenueCat will automatically sync with App Store Connect once linked

### Step 6: Important Notes

**Product IDs Must Match:**
- App Store Connect: `monthly`, `yearly`
- RevenueCat: `monthly`, `yearly`
- Your database: `revenuecat_product_id = 'monthly'`, `'yearly'`
- Your code: `Config.revenueCatMonthlyProductID = "monthly"`

**Status Requirements:**
- Products can be in "Ready to Submit" status for testing
- You don't need to submit the app for review to test subscriptions
- Sandbox testing works with "Ready to Submit" products

### Step 7: Create Sandbox Test Account

1. In App Store Connect, go to **Users and Access** → **Sandbox Testers**
2. Click **+** to create a test account
3. Enter:
   - Email (can be fake, like `test@example.com`)
   - Password
   - Country/Region
4. **Save**

**Important:** Use this account when testing purchases in your app!

## Testing Without App Store Connect (Limited)

If you want to test the integration **before** setting up App Store Connect:

### What You CAN Test:
1. ✅ Build and run the app
2. ✅ Verify RevenueCat SDK initializes
3. ✅ Check that paywall UI displays
4. ✅ Test navigation and UI flows
5. ✅ Verify error handling

### What You CANNOT Test:
1. ❌ Actual purchases
2. ❌ Subscription status updates
3. ❌ Webhook events
4. ❌ Entitlement checking with real subscriptions

### Testing Strategy:

**Option 1: Set up App Store Connect now**
- Full testing capability
- Can test complete purchase flow
- Takes ~30-60 minutes to set up

**Option 2: Test UI/Code first, then set up App Store Connect**
- Test SDK initialization and UI
- Set up App Store Connect when ready for purchase testing
- Good if you want to verify code works first

## Next Steps

Once App Store Connect is set up:
1. Products are created with IDs: `monthly` and `yearly`
2. Sandbox test account is created
3. You can test full purchase flow
4. RevenueCat will sync products automatically

## Resources

- [Apple: In-App Purchase Configuration](https://developer.apple.com/app-store-connect/in-app-purchases/)
- [Apple: Testing In-App Purchases](https://developer.apple.com/documentation/storekit/in-app_purchase/testing_in-app_purchases_with_sandbox)
- [RevenueCat: App Store Connect Setup](https://www.revenuecat.com/docs/app-store-connect)

