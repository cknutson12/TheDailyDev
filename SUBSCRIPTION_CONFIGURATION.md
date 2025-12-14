# Subscription Price and Duration Configuration

## 📋 Quick Answer

**Subscription prices and durations are configured in App Store Connect**, not in RevenueCat or your app code. They work the **same in both test mode and production**.

## 🔧 Where to Configure

### App Store Connect (The Source of Truth)

**All subscription configuration happens here:**
- **Price**: Set in App Store Connect for each product
- **Duration**: Set in App Store Connect (1 month, 1 year, etc.)
- **Trial Period**: Set in App Store Connect (7 days, 14 days, etc.)

**Location**: App Store Connect → Your App → Features → In-App Purchases → Your Subscription Products

### RevenueCat (Just Passes Through)

RevenueCat **does NOT** configure prices or durations. It:
- Reads product information from App Store Connect
- Passes it through to your app
- Manages entitlements and subscription status

**RevenueCat Dashboard**: You configure:
- Product IDs (must match App Store Connect)
- Entitlements
- Offerings/Packages
- **NOT** prices or durations (those come from App Store Connect)

### Your App Code (Just Displays)

Your app code:
- Fetches packages from RevenueCat
- Displays prices and durations that RevenueCat provides
- **Does NOT** configure prices or durations

## 🧪 Test Mode vs Production

### Test Mode (StoreKit Sandbox)

**Uses the SAME products from App Store Connect:**
- Products configured in App Store Connect
- Prices you set in App Store Connect
- Durations you set in App Store Connect
- Trial periods you set in App Store Connect

**How it works:**
1. You configure products in App Store Connect (even if app isn't submitted)
2. Products can be in "Ready to Submit" status
3. StoreKit sandbox uses these same products for testing
4. No separate test configuration needed

### Production

**Uses the SAME products from App Store Connect:**
- Same products, same prices, same durations
- Only difference: Real payments vs test payments
- Products must be approved/submitted

## 📝 Configuration Steps

### Step 1: Configure in App Store Connect

1. Go to App Store Connect → Your App → Features → In-App Purchases
2. Create subscription products:
   - **Monthly**: Duration = 1 Month, Price = $4.99 (or your price)
   - **Yearly**: Duration = 1 Year, Price = $49.99 (or your price)
3. Configure free trial (optional):
   - Set trial period (e.g., 7 days)
4. Save products

**Status**: Products can be "Ready to Submit" - you don't need to submit the app to test

### Step 2: Link in RevenueCat

1. Go to RevenueCat Dashboard → Products
2. Create products with matching Product IDs:
   - Product ID: `monthly` (must match App Store Connect)
   - Product ID: `yearly` (must match App Store Connect)
3. RevenueCat automatically syncs prices/durations from App Store Connect

### Step 3: Your App Displays

Your app automatically displays:
- Prices from App Store Connect (via RevenueCat)
- Durations from App Store Connect (via RevenueCat)
- Trial information from App Store Connect (via RevenueCat)

**No code changes needed** - prices come from RevenueCat packages

## ❓ Common Questions

### Q: Can I change prices in test mode?

**A**: Yes! Change prices in App Store Connect, and they'll be reflected in test mode immediately (after RevenueCat syncs, which happens automatically).

### Q: Do I need different products for test vs production?

**A**: No! The same products are used for both. StoreKit sandbox uses the same App Store Connect products.

### Q: Can I test with different prices than production?

**A**: You can create separate products with different prices, but they'll be the same in test and production. There's no "test price" vs "production price" - it's the same product.

### Q: How do I change subscription duration?

**A**: Edit the product in App Store Connect. Duration is set when you create the subscription product (1 month, 1 year, etc.).

### Q: Can I change prices after launch?

**A**: Yes, but with limitations:
- You can add new prices (price increases require user consent)
- You can't change existing subscription prices for current subscribers
- New subscribers get the new price

## 🎯 Current Setup

### What You Have Now

✅ **App Store Connect Products** (if configured):
- Monthly subscription: `monthly` product ID
- Yearly subscription: `yearly` product ID
- Prices and durations set in App Store Connect

✅ **RevenueCat Products**:
- Products linked to App Store Connect
- Product IDs match: `monthly`, `yearly`

✅ **App Code**:
- Fetches packages from RevenueCat
- Displays prices dynamically from RevenueCat
- No hardcoded prices

### What You Need to Do

**If you haven't set up App Store Connect yet:**
1. Create subscription products in App Store Connect
2. Set prices and durations
3. Configure free trials (optional)
4. Link products in RevenueCat (Product IDs must match)

**If App Store Connect is already set up:**
- ✅ You're all set! Prices and durations are already configured
- Test mode uses the same products
- Production will use the same products

## 🔍 How to Verify Configuration

### Check App Store Connect

1. Go to App Store Connect → Your App → Features → In-App Purchases
2. Verify:
   - Products exist: `monthly`, `yearly`
   - Prices are set correctly
   - Durations are set correctly (1 month, 1 year)
   - Trial periods are configured (if desired)

### Check RevenueCat Dashboard

1. Go to RevenueCat Dashboard → Products
2. Verify:
   - Products exist: `monthly`, `yearly`
   - Product IDs match App Store Connect exactly
   - Products show prices (synced from App Store Connect)

### Check Your App

1. Run app in test mode
2. Open paywall
3. Verify:
   - Prices match App Store Connect
   - Durations are correct
   - Trial information displays (if configured)

## 📊 Example Configuration

### App Store Connect

**Monthly Product:**
- Product ID: `monthly`
- Duration: 1 Month
- Price: $4.99
- Free Trial: 7 days

**Yearly Product:**
- Product ID: `yearly`
- Duration: 1 Year
- Price: $49.99
- Free Trial: 7 days

### RevenueCat

**Products:**
- Product ID: `monthly` (matches App Store Connect)
- Product ID: `yearly` (matches App Store Connect)

**Offerings:**
- Package: Monthly → `monthly` product
- Package: Yearly → `yearly` product

### Your App

**Displays:**
- Monthly: $4.99/month (from RevenueCat → App Store Connect)
- Yearly: $49.99/year (from RevenueCat → App Store Connect)
- Trial: "7-day free trial" (from RevenueCat → App Store Connect)

## 🚀 Summary

**Key Points:**
1. ✅ Prices and durations are configured in **App Store Connect**
2. ✅ Same configuration works for **both test and production**
3. ✅ RevenueCat just passes through what's in App Store Connect
4. ✅ Your app displays what RevenueCat provides
5. ✅ No separate test vs production configuration needed

**To Change Prices/Durations:**
1. Edit products in App Store Connect
2. RevenueCat automatically syncs
3. Your app automatically displays new values

**No code changes needed** - everything is configured in App Store Connect!

