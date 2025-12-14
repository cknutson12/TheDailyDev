# RevenueCat Setup - Step by Step Guide

## ✅ Step 1: API Key Added
- [x] Added `REVENUECAT_API_KEY` to `Config-Secrets.plist`
- [x] Value: `test_vWiKnNMjHYYzrbfAPbKvqqsYhgE`

## ✅ Step 2: Verify RevenueCat SDK in Xcode
- [x] SDK verified and linked in Xcode

## ✅ Step 3: RevenueCat Dashboard - Products & Entitlement
- [x] Created two products: `monthly` and `yearly`
- [x] Created entitlement: `pro`

## Step 4: Create Offering in RevenueCat Dashboard

**Action Required**: Create an Offering with packages

The Offerings section may be located under different names in the updated dashboard. Try these locations:

### Option 1: Product Catalog
1. Go to RevenueCat Dashboard → **Product Catalog**
2. Look for **Offerings** tab within Product Catalog
3. Click **Create Offering** or edit the default offering

### Option 2: Direct Navigation
1. Look for **Offerings** in the main navigation menu
2. Or search for "Offering" in the dashboard search

### Once you find Offerings:
1. Click **Create Offering** (or edit the default offering)
2. Name it: **"default"** (or any name, but "default" is recommended)
3. Add packages:
   - **Monthly Package**:
     - Package Identifier: `$rc_monthly` (or any identifier)
     - Product: Select your `monthly` product
   - **Yearly Package**:
     - Package Identifier: `$rc_yearly` (or any identifier)
     - Product: Select your `yearly` product
4. **Mark as Current Offering** (important!)
5. Save the offering

## ✅ Step 4: Create Offering in RevenueCat Dashboard
- [x] Created Offering with two packages (monthly and yearly)
- [x] Marked as Current Offering

## Step 5: Database Migration

**Action Required**: Run SQL migration to add RevenueCat columns

We need to add columns to your database tables to store RevenueCat subscription data.

### Instructions:
1. Go to your **Supabase Dashboard** → **SQL Editor**
2. Create a new query
3. Copy and paste the contents of `add_revenuecat_columns.sql`
4. Run the query

The migration will add these columns:
- **user_subscriptions table**: 
  - `revenuecat_user_id`
  - `revenuecat_subscription_id`
  - `entitlement_status`
  - `original_transaction_id`
- **subscription_plans table**:
  - `revenuecat_product_id`
  - `revenuecat_package_id`

## ✅ Step 5: Database Migration
- [x] Ran SQL migration to add RevenueCat columns

## Step 6: Update Subscription Plans

**Action Required**: Link your existing subscription plans to RevenueCat product IDs

We need to update your existing subscription plans in the database to include the RevenueCat product IDs.

### Instructions:
1. Go to your **Supabase Dashboard** → **SQL Editor**
2. Create a new query
3. Copy and paste the contents of `update_subscription_plans_revenuecat.sql`
4. Run the query

This will:
- Set `revenuecat_product_id = 'monthly'` for your monthly plan
- Set `revenuecat_product_id = 'yearly'` for your yearly plan

The SQL includes a verification query at the end to show you the updated plans.

## ✅ Step 6: Update Subscription Plans
- [x] Updated subscription plans with RevenueCat product IDs

## Step 7: Configure RevenueCat Webhook

**Action Required**: Set up webhook in RevenueCat dashboard and Supabase

The webhook will automatically update your database when subscription events occur (purchases, renewals, cancellations, etc.).

### Part A: Get Your Webhook URL

Your webhook URL format is:
```
https://YOUR_PROJECT_ID.supabase.co/functions/v1/revenuecat-webhook
```

**To find your project ID:**
1. Go to Supabase Dashboard → Settings → API
2. Your Project URL is: `https://YOUR_PROJECT_ID.supabase.co`
3. Your webhook URL will be: `https://YOUR_PROJECT_ID.supabase.co/functions/v1/revenuecat-webhook`

**Your current Supabase URL from Config-Secrets.plist:**
Based on your config, your webhook URL should be:
```
https://thawdmtbwehbuzmrwicz.supabase.co/functions/v1/revenuecat-webhook
```

### Part B: Set Webhook Secret in Supabase

1. Go to **Supabase Dashboard** → **Edge Functions** → **revenuecat-webhook**
2. Click on **Settings** or **Secrets**
3. Add a new secret:
   - **Name**: `REVENUECAT_WEBHOOK_SECRET`
   - **Value**: Generate a secure random string (you'll use this in RevenueCat)
   - Example: `rc_whsec_abc123xyz789` (or any secure random string)
4. **Save the secret** - you'll need this value for RevenueCat

### Part C: Configure Webhook in RevenueCat Dashboard

1. Go to **RevenueCat Dashboard** → **Project Settings** → **Webhooks**
2. Click **Add Webhook** or **Create Webhook**
3. Enter:
   - **Webhook URL**: `https://thawdmtbwehbuzmrwicz.supabase.co/functions/v1/revenuecat-webhook`
   - **Authorization Header**: `Bearer YOUR_WEBHOOK_SECRET` (use the secret you created in Part B)
4. **Enable all event types** (or at least these important ones):
   - ✅ INITIAL_PURCHASE
   - ✅ RENEWAL
   - ✅ CANCELLATION
   - ✅ UNCANCELLATION
   - ✅ EXPIRATION
   - ✅ BILLING_ISSUE
5. **Save** the webhook

### Part D: Deploy Edge Function (if not already deployed)

Make sure your `revenuecat-webhook` Edge Function is deployed:

1. Go to **Supabase Dashboard** → **Edge Functions**
2. If `revenuecat-webhook` is not listed, you need to deploy it
3. Use Supabase CLI or deploy via dashboard

## ✅ Step 7: Configure RevenueCat Webhook
- [x] Webhook URL configured in RevenueCat dashboard
- [x] Webhook secret set in Supabase Edge Function
- [x] Edge function deployed

## Step 8: App Store Connect Setup (Required for Purchases)

**Action Required**: Set up subscription products in App Store Connect

⚠️ **Important**: RevenueCat uses Apple's in-app purchase system, so you **must** create subscription products in App Store Connect to test actual purchases.

### What You Need:
1. **Apple Developer Account** ($99/year) - Required for App Store publishing
2. **App registered in App Store Connect** (can be in development, doesn't need to be submitted)

### Quick Setup Guide:

See **`APP_STORE_CONNECT_SETUP.md`** for detailed instructions.

**Summary:**
1. Go to https://appstoreconnect.apple.com
2. Select your app → **Features** → **In-App Purchases**
3. Create **Subscription Group**: "The Daily Dev Pro"
4. Create **Monthly Product**:
   - Product ID: `monthly` (must match exactly!)
   - Duration: 1 Month
   - Set price
5. Create **Yearly Product**:
   - Product ID: `yearly` (must match exactly!)
   - Duration: 1 Year
   - Set price
6. Create **Sandbox Test Account**:
   - Users and Access → Sandbox Testers
   - Create test account for testing purchases

### Can You Test Without App Store Connect?

**Limited testing only:**
- ✅ SDK initialization
- ✅ UI flows (paywall display)
- ✅ Code logic
- ❌ **Actual purchases** (requires App Store Connect)

**Recommendation**: Set up App Store Connect now if you want to test the full purchase flow. Otherwise, you can test UI/code first and set it up later.

## Step 9: Testing RevenueCat Integration

**Action Required**: Test the complete RevenueCat integration flow

### Prerequisites for Testing

1. **App Store Connect Setup** (if testing real purchases):
   - ✅ Subscription products created with IDs: `monthly` and `yearly`
   - ✅ Sandbox test account created
   - ✅ Sign out of App Store on your test device/simulator

### Testing Checklist

#### Test 1: App Launch & SDK Initialization
- [ ] Open the app
- [ ] Check Xcode console for: `✅ RevenueCat SDK initialized with API key`
- [ ] Verify no errors related to RevenueCat

#### Test 2: User Authentication & RevenueCat User ID
- [ ] Sign in or sign up with a test account
- [ ] Check Xcode console for: `✅ RevenueCat user ID set: [user-id]`
- [ ] Verify user ID is set correctly

#### Test 3: Fetch Subscription Plans
- [ ] Navigate to subscription benefits view
- [ ] Verify plans are displayed (monthly and yearly)
- [ ] Check that prices and descriptions are correct
- [ ] Verify RevenueCat paywall appears (not Stripe checkout)

#### Test 4: Purchase Flow (Sandbox)
- [ ] Select a subscription plan
- [ ] Tap "Subscribe" button
- [ ] Verify native iOS purchase sheet appears
- [ ] Sign in with sandbox test account when prompted
- [ ] Complete the purchase
- [ ] Verify purchase success message appears
- [ ] Check Xcode console for purchase confirmation

#### Test 5: Subscription Status Check
- [ ] After purchase, check subscription status in app
- [ ] Verify status shows as "active" or "trialing"
- [ ] Check database: `user_subscriptions` table should have:
   - `status = 'active'` or `'trialing'`
   - `revenuecat_user_id` populated
   - `revenuecat_subscription_id` populated
   - `entitlement_status = 'active'`

#### Test 6: Webhook Verification
- [ ] Check Supabase Edge Function logs for webhook events
- [ ] Verify webhook received events from RevenueCat
- [ ] Check that database was updated via webhook
- [ ] Look for: `✅ Updated user_subscriptions for user [id], status: active`

#### Test 7: Restore Purchases
- [ ] Sign out and sign back in
- [ ] Test "Restore Purchases" functionality
- [ ] Verify subscription is restored correctly
- [ ] Check that access is granted

#### Test 8: Customer Center / Subscription Management
- [ ] Navigate to subscription settings
- [ ] Test "Manage Subscription" button
- [ ] Verify it opens Customer Center or App Store subscription management
- [ ] Test cancellation flow (if applicable)

#### Test 9: Entitlement Checking
- [ ] Verify that users with active subscriptions can access questions
- [ ] Verify that users without subscriptions see paywall
- [ ] Test entitlement check after purchase

#### Test 10: Error Handling
- [ ] Test purchase cancellation (tap "Cancel" on purchase sheet)
- [ ] Verify app handles cancellation gracefully
- [ ] Test with network errors (airplane mode)
- [ ] Verify error messages are user-friendly

### Debugging Tips

**If purchases don't work:**
1. Verify RevenueCat API key is correct
2. Check that products exist in RevenueCat dashboard
3. Verify offering is marked as "current"
4. Check that product IDs match: RevenueCat, App Store Connect, and database
5. Check Xcode console for RevenueCat errors

**If webhook doesn't receive events:**
1. Verify webhook URL is correct in RevenueCat dashboard
2. Check webhook secret matches in both places
3. Check Supabase Edge Function logs
4. Verify Edge Function is deployed and running

**If subscription status doesn't update:**
1. Check database `user_subscriptions` table
2. Verify `revenuecat_user_id` is set correctly
3. Check webhook logs for errors
4. Manually trigger webhook test from RevenueCat dashboard

### Next Steps After Testing

Once testing is complete:
- [ ] Document any issues found
- [ ] Fix any bugs discovered
- [ ] Prepare for production deployment
- [ ] Update App Store Connect with production products (if needed)

**Let me know how the testing goes and if you encounter any issues!**

---

## Summary: What We've Completed

✅ **Step 1**: API Key added to Config-Secrets.plist  
✅ **Step 2**: RevenueCat SDK verified in Xcode  
✅ **Step 3**: Products and entitlement created in RevenueCat  
✅ **Step 4**: Offering created with packages  
✅ **Step 5**: Database migration completed  
✅ **Step 6**: Subscription plans updated with RevenueCat product IDs  
✅ **Step 7**: Webhook configured  
⏳ **Step 8**: App Store Connect setup (in progress)  
⏳ **Step 9**: Testing (pending App Store Connect)

## Next Actions

1. **Local Testing** (see `LOCAL_TESTING_PLAN.md`) - Test everything possible without App Store Connect
2. **Set up App Store Connect** (when you get Apple Developer account) - See `APP_STORE_CONNECT_SETUP.md`
3. **Test actual purchases** once App Store Connect is ready
4. **Deploy to production** when ready

---

## Local Testing (No App Store Connect Required)

Since you don't have an Apple Developer account yet, you can still test:

✅ **What You CAN Test:**
- SDK initialization
- User authentication & RevenueCat user ID linking
- UI flows and navigation
- Paywall display (will show errors, but UI works)
- Database structure and queries
- Error handling
- Code architecture

❌ **What You CANNOT Test (Requires App Store Connect):**
- Actual purchases
- Real subscription status
- Webhook events
- Restore purchases

**See `LOCAL_TESTING_PLAN.md` for detailed testing checklist!**

