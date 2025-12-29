# Privacy Policy & Terms of Service Update Summary

## Current Status

✅ **Templates exist** but need updates for RevenueCat
✅ **Privacy Policy Template** - Updated to replace Stripe with RevenueCat/Apple
✅ **Terms of Service Template** - Already correct (mentions Apple refunds)
✅ **Privacy Manifest** - Updated to replace Stripe with RevenueCat/Apple

## Updates Made

### 1. Privacy Policy Template (`PRIVACY_POLICY_TEMPLATE.md`)
- ✅ Replaced Stripe references with RevenueCat and Apple App Store
- ✅ Updated payment processing section to reflect Apple in-app purchases
- ✅ Added RevenueCat as third-party service with privacy policy link
- ✅ Added Apple App Store as payment processor

### 2. Privacy Manifest (`PRIVACY_MANIFEST.md`)
- ✅ Replaced Stripe SDK reference with RevenueCat SDK
- ✅ Added Apple StoreKit reference
- ✅ Updated privacy policy links

### 3. Terms of Service Template (`TERMS_OF_SERVICE_TEMPLATE.md`)
- ✅ Already correct - mentions Apple refunds (no Stripe references)

## Apple's Current Requirements (2025)

### Privacy Policy Requirements:
1. ✅ **Must be publicly accessible** via URL
2. ✅ **Must disclose data collection** - what data you collect
3. ✅ **Must disclose data use** - how you use the data
4. ✅ **Must disclose third-party services** - who you share data with
5. ✅ **Must include contact information** - how to reach you
6. ✅ **Must be linked in App Store Connect** - Privacy Policy URL field
7. ✅ **Must be linked in app** - NSPrivacyPolicyURL in Info.plist

### App Privacy Section (App Store Connect):
- Must complete "App Privacy" questionnaire
- Must declare data collection types
- Must declare data use purposes
- Must declare third-party SDKs (RevenueCat, Supabase, etc.)

## Next Steps

### 1. Host the Privacy Policy
- [ ] Update `PRIVACY_POLICY_TEMPLATE.md` with your actual website URL
- [ ] Replace `[YOUR_WEBSITE_URL]` placeholders
- [ ] Replace `[YOUR_EMAIL_ADDRESS]` with your support email
- [ ] Host on your website at a permanent URL (e.g., `https://thedailydev.com/privacy-policy`)

### 2. Update Config.swift
- [ ] Update `privacyPolicyURL` with your actual hosted URL
- [ ] Update `termsOfServiceURL` if you have one hosted

### 3. Update Info.plist
- [ ] Update `NSPrivacyPolicyURL` with your actual hosted URL

### 4. Complete App Store Connect
- [ ] Fill out "App Privacy" section
- [ ] Declare RevenueCat SDK
- [ ] Declare Supabase SDK
- [ ] Declare data collection types (email, user ID, subscription data)
- [ ] Add Privacy Policy URL

### 5. Review with Legal
- [ ] Have a lawyer review both documents before publishing
- [ ] Ensure compliance with GDPR, CCPA, and other regulations

## RevenueCat-Specific Notes

Since you're using RevenueCat with Apple's StoreKit (not Stripe):
- ✅ Payment processing is handled by **Apple** (App Store)
- ✅ Subscription management is handled by **RevenueCat**
- ✅ No credit card data is collected by your app
- ✅ All payments go through Apple's secure payment system
- ✅ RevenueCat acts as a data processor for subscription data

## Files Updated

1. `PRIVACY_POLICY_TEMPLATE.md` - Stripe → RevenueCat/Apple
2. `PRIVACY_MANIFEST.md` - Stripe SDK → RevenueCat SDK + StoreKit
3. `TERMS_OF_SERVICE_TEMPLATE.md` - Already correct (no changes needed)

## Important Notes

⚠️ **These are TEMPLATES** - You need to:
1. Customize them with your actual information
2. Host them on your website
3. Update the URLs in Config.swift and Info.plist
4. Have them reviewed by a lawyer

⚠️ **Apple requires a live, accessible Privacy Policy URL** before app submission.

