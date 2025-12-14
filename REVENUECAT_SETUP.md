# RevenueCat Setup Guide

This document outlines the setup process for RevenueCat integration on the `feature/revenuecat-integration` branch.

## Prerequisites

1. **RevenueCat Account**: Create account at https://www.revenuecat.com
2. **App Store Connect**: Link your app to App Store Connect
3. **Products Created**: Create subscription products in App Store Connect

## Step 1: RevenueCat Dashboard Setup

### 1.1 Create Project
1. Log into RevenueCat dashboard
2. Create a new project or select existing
3. Add your iOS app

### 1.2 Link App Store Connect
1. Go to Project Settings → App Store Connect
2. Link your App Store Connect account
3. Select your app

### 1.3 Create Products
Create products in RevenueCat dashboard (or use API):

**Monthly Product:**
- Product ID: `monthly` (must match App Store Connect)
- Type: Subscription
- Store: App Store

**Yearly Product:**
- Product ID: `yearly` (must match App Store Connect)
- Type: Subscription
- Store: App Store

### 1.4 Create Entitlement
1. Go to Entitlements
2. Create entitlement: `pro`
3. Attach products: `monthly` and `yearly`

### 1.5 Create Offering
1. Go to Offerings
2. Create offering (default is fine)
3. Add packages:
   - Monthly package → `monthly` product
   - Yearly package → `yearly` product

### 1.6 Get API Keys
1. Go to Project Settings → API Keys
2. Copy your **Public API Key** (starts with `pk_` or `test_`)
3. Add to `Config-Secrets.plist` as `REVENUECAT_API_KEY`

## Step 2: App Store Connect Setup

### 2.1 Create Subscription Products
1. Go to App Store Connect → Your App → Subscriptions
2. Create subscription group: "The Daily Dev Pro"
3. Create products:
   - **Monthly**: Product ID `monthly`, price your choice
   - **Yearly**: Product ID `yearly`, price your choice
4. Configure trial period if desired

### 2.2 Important
- Product IDs must match what's in RevenueCat (`monthly`, `yearly`)
- Product IDs must match what's in `Config.swift` constants

## Step 3: Database Setup

Run the migration SQL to add RevenueCat columns:

```sql
-- Run add_revenuecat_columns.sql
```

This adds:
- `revenuecat_user_id`
- `revenuecat_subscription_id`
- `entitlement_status`
- `original_transaction_id`
- `revenuecat_product_id` (in subscription_plans)
- `revenuecat_package_id` (in subscription_plans)

## Step 4: Update Subscription Plans Table

Add RevenueCat product IDs to your subscription plans:

```sql
UPDATE subscription_plans
SET revenuecat_product_id = 'monthly'
WHERE name = 'monthly';

UPDATE subscription_plans
SET revenuecat_product_id = 'yearly'
WHERE name = 'yearly';
```

## Step 5: Configure Webhook

1. Go to RevenueCat Dashboard → Project Settings → Webhooks
2. Add webhook URL: `https://your-project.supabase.co/functions/v1/revenuecat-webhook`
3. Set webhook secret in Supabase Edge Function secrets:
   - `REVENUECAT_WEBHOOK_SECRET`

## Step 6: Xcode Project Setup

### 6.1 Add RevenueCat SDK
1. Open Xcode project
2. File → Add Package Dependencies
3. Add: `https://github.com/RevenueCat/purchases-ios-spm.git`
4. Select version (latest stable)
5. Add to TheDailyDev target

### 6.2 Add API Key to Config
Add to `Config-Secrets.plist`:
```xml
<key>REVENUECAT_API_KEY</key>
<string>test_vWiKnNMjHYYzrbfAPbKvqqsYhgE</string>
```

## Step 7: Testing

### 7.1 Sandbox Testing
1. Create sandbox test account in App Store Connect
2. Sign out of App Store on device/simulator
3. Run app and attempt purchase
4. Sign in with sandbox account when prompted

### 7.2 Verify
- [ ] Purchase flow works
- [ ] Subscription status updates in database
- [ ] Webhook receives events
- [ ] Restore purchases works
- [ ] Customer Center accessible

## Product IDs Reference

- **Monthly**: `monthly`
- **Yearly**: `yearly`
- **Entitlement**: `pro`

These must match:
1. App Store Connect product IDs
2. RevenueCat product IDs
3. `Config.swift` constants
4. Database `revenuecat_product_id` values

## Troubleshooting

### "No package found with product ID"
- Verify product ID matches App Store Connect
- Check RevenueCat offering has the package
- Ensure products are approved in App Store Connect

### "No current offering found"
- Create an offering in RevenueCat dashboard
- Mark it as the current offering

### Webhook not receiving events
- Verify webhook URL is correct
- Check webhook secret matches
- Review RevenueCat webhook logs

### User ID not linking
- Ensure `Purchases.shared.logIn(userId)` is called after sign in
- Check webhook can find user by `app_user_id` or aliases

