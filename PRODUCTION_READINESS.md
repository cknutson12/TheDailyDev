# Production Readiness Checklist

## ✅ Completed

### Code & Configuration
- [x] **Privacy Manifest** - `PrivacyInfo.xcprivacy` created and added to project
- [x] **Production Logging** - DebugLogger utility created, RevenueCat log level conditional
- [x] **Privacy Policy URL** - Configured in `Info.plist` and `Config.swift`
- [x] **Terms of Service URL** - Configured in `Config.swift` and `SubscriptionSettingsView`
- [x] **RLS Policies** - Fixed and tested
- [x] **RevenueCat Webhook** - Configured and tested

## ⚠️ Needs Action Before Production

### 1. API Keys & Configuration (CRITICAL)

#### RevenueCat Production API Key
- [ ] **Get production API key from RevenueCat dashboard**
  - Go to: RevenueCat Dashboard → Project Settings → API Keys
  - Copy production key (starts with `pk_`, NOT `test_`)
  - Update `Config-Secrets.plist` with production key:
    ```xml
    <key>REVENUECAT_API_KEY</key>
    <string>pk_YOUR_PRODUCTION_KEY_HERE</string>
    ```

- [ ] **Remove test key fallback in `Config.swift`**
  - Currently has fallback: `return "test_vWiKnNMjHYYzrbfAPbKvqqsYhgE"`
  - Should `fatalError` instead if key is missing in production
  - **Location**: `Config.swift` line 34

#### Verify Config-Secrets.plist
- [ ] Ensure `Config-Secrets.plist` contains:
  - `SUPABASE_URL` (production Supabase URL)
  - `SUPABASE_KEY` (production Supabase anon key)
  - `REVENUECAT_API_KEY` (production key starting with `pk_`)

### 2. Version & Build Numbers

- [ ] **Set Marketing Version** (currently: 1.0)
  - In Xcode: Target → General → Version
  - Format: `MAJOR.MINOR.PATCH` (e.g., `1.0.0`)

- [ ] **Set Build Number** (currently: 1)
  - In Xcode: Target → General → Build
  - Increment for each App Store submission
  - Format: Integer (e.g., `1`, `2`, `3`)

### 3. Legal Documents (REQUIRED for App Store)

- [ ] **Host Privacy Policy**
  - URL: `https://thedailydevweb.vercel.app/privacy-policy`
  - Must be live and accessible before submission
  - Template available in `PRIVACY_POLICY_TEMPLATE.md`

- [ ] **Host Terms of Service**
  - URL: `https://thedailydevweb.vercel.app/terms-of-service`
  - Must be live and accessible before submission

- [ ] **Legal Review**
  - Have both documents reviewed by a lawyer
  - Ensure compliance with Apple's requirements
  - Ensure compliance with GDPR/CCPA if applicable

### 4. App Store Connect Setup (Requires Apple Developer Account)

#### App Record
- [ ] Create app record in App Store Connect
- [ ] Set app name, subtitle, category
- [ ] Upload app icon (1024x1024 PNG, no transparency)

#### App Privacy Section
- [ ] Complete App Privacy questionnaire
- [ ] Declare data collection types:
  - Email Address (for account creation)
  - User ID (for account management)
- [ ] Declare data use purposes:
  - App Functionality
- [ ] List third-party SDKs:
  - RevenueCat (subscription management)
  - Supabase (backend services)
- [ ] Link privacy policy URL

#### In-App Purchases
- [ ] Create subscription products in App Store Connect:
  - Monthly subscription (`monthly`)
  - Yearly subscription (`yearly`)
- [ ] Set pricing for all regions
- [ ] Configure subscription groups
- [ ] Set up free trial (7 days)
- [ ] Configure subscription terms and descriptions

#### App Store Assets
- [ ] **Screenshots** (required for all device sizes):
  - iPhone 6.7" (1290 x 2796) - iPhone 15 Pro Max
  - iPhone 6.5" (1242 x 2688) - iPhone 11 Pro Max
  - iPhone 5.5" (1242 x 2208) - iPhone 8 Plus
- [ ] **App Preview Video** (optional, 15-30 seconds)
- [ ] **App Description** (up to 4000 characters)
- [ ] **Keywords** (up to 100 characters)
- [ ] **Support URL** (your website support page)
- [ ] **Marketing URL** (optional, your website)

### 5. Testing (CRITICAL)

#### Functional Testing
- [ ] **User Flows**:
  - [ ] Sign up (email/password)
  - [ ] Sign up (OAuth - Google/Apple)
  - [ ] Email verification
  - [ ] Login
  - [ ] Password reset
  - [ ] Onboarding flow
  - [ ] Subscription purchase (monthly)
  - [ ] Subscription purchase (yearly)
  - [ ] Subscription management
  - [ ] Question answering
  - [ ] Progress tracking
  - [ ] Contribution grid interaction

#### Edge Cases
- [ ] Network errors (offline mode)
- [ ] Expired sessions
- [ ] Failed payments
- [ ] Subscription cancellation
- [ ] Trial expiration
- [ ] Year boundary (Dec 31 → Jan 1)
- [ ] Leap year handling

#### Device Testing
- [ ] iPhone SE (small screen)
- [ ] iPhone 15 (standard)
- [ ] iPhone 15 Pro Max (large screen)
- [ ] Test on iOS 17.5
- [ ] Test on iOS 18.0+
- [ ] Test on latest iOS version

#### Performance Testing
- [ ] App launch time (< 3 seconds)
- [ ] Question loading performance
- [ ] Memory usage (check for leaks)
- [ ] Battery usage
- [ ] Network request optimization

### 6. RevenueCat Production Verification

- [ ] **Verify Products in RevenueCat Dashboard**:
  - Monthly product linked
  - Yearly product linked
  - Product IDs match code (`monthly`, `yearly`)

- [ ] **Verify Entitlement**:
  - Entitlement ID: "The Daily Dev Pro"
  - Matches `Config.revenueCatEntitlementID`

- [ ] **Verify Offering**:
  - Default offering created
  - Packages configured (Monthly, Yearly)
  - Products linked to App Store Connect

- [ ] **Test Webhook**:
  - Verify webhook URL is correct
  - Test with production API key
  - Verify events are being received
  - Check database updates

### 7. Code Signing & Certificates (Requires Apple Developer Account)

- [ ] Generate distribution certificate
- [ ] Create App ID (`dailydev.TheDailyDev`)
- [ ] Create provisioning profile
- [ ] Configure code signing in Xcode
- [ ] Verify bundle identifier matches App Store Connect

### 8. Final Pre-Submission Checks

- [ ] **No test keys in production build**
  - Verify `Config-Secrets.plist` has production keys
  - Remove test key fallback from `Config.swift`

- [ ] **No debug logging in production**
  - RevenueCat log level set to `.warn` in Release builds ✅
  - DebugLogger suppresses debug prints in Release ✅

- [ ] **Privacy Manifest exists**
  - `PrivacyInfo.xcprivacy` file present ✅
  - Added to Xcode project ✅

- [ ] **All URLs are production**
  - Privacy policy URL: `https://thedailydevweb.vercel.app/privacy-policy` ✅
  - Terms of service URL: `https://thedailydevweb.vercel.app/terms-of-service` ✅
  - No localhost references ✅

- [ ] **Version numbers set**
  - Marketing version: `1.0` (update if needed)
  - Build number: `1` (increment for each submission)

## 🚨 Critical Issues to Fix

### 1. Test API Key Fallback
**File**: `Config.swift` line 34
**Issue**: Falls back to test key if production key is missing
**Fix**: Change to `fatalError` in production:
```swift
static var revenueCatAPIKey: String {
    guard let path = Bundle.main.path(forResource: "Config-Secrets", ofType: "plist"),
          let plist = NSDictionary(contentsOfFile: path),
          let key = plist["REVENUECAT_API_KEY"] as? String else {
        #if DEBUG
        return "test_vWiKnNMjHYYzrbfAPbKvqqsYhgE" // Only in debug
        #else
        fatalError("REVENUECAT_API_KEY not found in Config-Secrets.plist")
        #endif
    }
    return key
}
```

## 📋 Quick Reference

### Production API Keys Location
- **RevenueCat**: Dashboard → Project Settings → API Keys → Production Key (starts with `pk_`)
- **Supabase**: Dashboard → Settings → API → Project API keys → `anon` `public` key

### App Store Connect URLs
- **App Store Connect**: https://appstoreconnect.apple.com
- **RevenueCat Dashboard**: https://app.revenuecat.com
- **Supabase Dashboard**: https://supabase.com/dashboard

### Required Before First Submission
1. ✅ Privacy Manifest
2. ✅ Production logging configured
3. ⚠️ Production API keys in `Config-Secrets.plist`
4. ⚠️ Remove test key fallback
5. ⚠️ Privacy Policy hosted and live
6. ⚠️ Terms of Service hosted and live
7. ⚠️ Comprehensive testing completed
8. ⚠️ App Store Connect app record created
9. ⚠️ In-app purchases configured
10. ⚠️ Screenshots prepared

---

**Last Updated**: After Privacy Manifest and Production Logging implementation

