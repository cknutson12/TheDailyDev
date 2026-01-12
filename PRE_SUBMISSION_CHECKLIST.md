# Pre-Submission Checklist - What You Can Do Now

Since you're waiting for your Apple Developer account approval, here's what you can prepare **now** vs. what requires the account.

## ✅ What You Can Do NOW (No Apple Developer Account Needed)

### 1. Privacy & Legal Documents
- [x] **Privacy Policy Template** - Updated for RevenueCat ✅
- [x] **Terms of Service Template** - Ready ✅
- [ ] **Host Privacy Policy** - Upload to `https://thedailydevweb.vercel.app/privacy-policy`
- [ ] **Host Terms of Service** - Upload to `https://thedailydevweb.vercel.app/terms-of-service`
- [ ] **Review with lawyer** - Have both documents reviewed before publishing

### 2. Code Preparation
- [ ] **Create Privacy Manifest** (`PrivacyInfo.xcprivacy`)
  - Required for iOS 17+ apps
  - Declare required reason APIs
  - List third-party SDKs (RevenueCat, Supabase)
  
- [ ] **Production Configuration**
  - [ ] Switch RevenueCat log level from `.debug` to `.info` or `.warn`
  - [ ] Remove or conditionally compile debug `print()` statements
  - [ ] Set production RevenueCat API key (get from RevenueCat dashboard)
  - [ ] Verify no test API keys in production builds

- [ ] **Version & Build Numbers**
  - [ ] Set version number (e.g., 1.0.0)
  - [ ] Set build number (e.g., 1)
  - [ ] Update in Xcode project settings

### 3. App Store Assets (Can Prepare Now)
- [ ] **App Icon** - 1024x1024 PNG, no transparency
- [ ] **Screenshots** - Prepare for all required device sizes:
  - iPhone 6.7" (1290 x 2796)
  - iPhone 6.5" (1242 x 2688)  
  - iPhone 5.5" (1242 x 2208)
- [ ] **App Preview Video** (optional) - 15-30 seconds
- [ ] **App Description** - Write up to 4000 characters
- [ ] **Keywords** - Up to 100 characters
- [ ] **Support URL** - Your website support page
- [ ] **Marketing URL** (optional) - Your website

### 4. Testing & Quality Assurance
- [ ] **Comprehensive Testing**
  - [ ] Test all user flows (sign up, login, questions, subscriptions)
  - [ ] Test on multiple devices (iPhone SE, iPhone 15, iPhone 15 Pro Max)
  - [ ] Test on multiple iOS versions (17.5, 18.0, latest)
  - [ ] Test network error handling
  - [ ] Test edge cases (expired sessions, failed payments, etc.)

- [ ] **Performance Testing**
  - [ ] App launch time (< 3 seconds)
  - [ ] Question loading performance
  - [ ] Memory usage (check for leaks)
  - [ ] Battery usage

### 5. RevenueCat Production Setup
- [ ] **Get Production API Key**
  - [ ] Log into RevenueCat dashboard
  - [ ] Go to Project Settings → API Keys
  - [ ] Copy production API key (starts with `pk_` not `test_`)
  - [ ] Update `Config-Secrets.plist` with production key

- [ ] **Verify Products in App Store Connect** (once you have account)
  - [ ] Monthly subscription product created
  - [ ] Yearly subscription product created
  - [ ] Product IDs match code (`monthly`, `yearly`)

- [ ] **Verify RevenueCat Configuration**
  - [ ] Products linked in RevenueCat
  - [ ] Entitlement created ("The Daily Dev Pro")
  - [ ] Offering created with packages
  - [ ] Webhook configured and tested

### 6. Database & Backend
- [x] **RLS Policies** - Fixed ✅
- [x] **Webhook** - RevenueCat webhook configured ✅
- [ ] **Test webhook** - Verify it's receiving and processing events correctly
- [ ] **Backup strategy** - Ensure database backups are configured

## ⏳ What Requires Apple Developer Account

### 1. App Store Connect Setup
- [ ] Create app record in App Store Connect
- [ ] Configure app metadata
- [ ] Upload screenshots
- [ ] Set privacy policy URL
- [ ] Complete App Privacy questionnaire
- [ ] Set age rating
- [ ] Configure in-app purchases

### 2. App Store Connect - App Privacy Section
- [ ] Declare data collection types
- [ ] Declare data use purposes
- [ ] List third-party SDKs (RevenueCat, Supabase)
- [ ] Link privacy policy

### 3. App Store Connect - In-App Purchases
- [ ] Create subscription products
  - Monthly subscription
  - Yearly subscription
- [ ] Set pricing for all regions
- [ ] Configure subscription groups
- [ ] Set up free trial (if offering)
- [ ] Configure subscription terms

### 4. Code Signing & Certificates
- [ ] Generate distribution certificate
- [ ] Create App ID
- [ ] Create provisioning profile
- [ ] Configure code signing in Xcode

### 5. Build & Upload
- [ ] Archive app in Xcode
- [ ] Upload to App Store Connect (via Xcode or Transporter)
- [ ] Submit for review

## 🎯 Priority Order While Waiting

### Do These First (High Priority)
1. **Create Privacy Manifest** - Required for iOS 17+
2. **Host Privacy Policy & Terms** - Required for submission
3. **Production Configuration** - Switch to production API keys/logging
4. **Comprehensive Testing** - Find and fix bugs now
5. **Prepare App Store Assets** - Screenshots, description, etc.

### Do These Second (Medium Priority)
6. **Code Cleanup** - Remove debug code, optimize
7. **Performance Testing** - Ensure app is fast
8. **RevenueCat Production Setup** - Get production API key ready

### Do These When Account is Approved (Can't Do Without Account)
9. **App Store Connect Setup** - Create app record
10. **In-App Purchase Configuration** - Create products
11. **Code Signing** - Set up certificates
12. **Upload & Submit** - Final submission

## 📋 Quick Wins You Can Do Right Now

1. **Create Privacy Manifest** (15 minutes)
   - Create `PrivacyInfo.xcprivacy` file
   - Declare APIs and SDKs used

2. **Production Code Changes** (30 minutes)
   - Change RevenueCat log level
   - Add conditional compilation for debug prints

3. **Prepare Screenshots** (1-2 hours)
   - Take screenshots on simulator
   - Edit and prepare for all device sizes

4. **Write App Store Description** (1 hour)
   - Write compelling description
   - List key features
   - Add keywords

5. **Test Everything** (2-4 hours)
   - Go through all user flows
   - Test edge cases
   - Document any bugs found

## 🔍 Critical Items to Verify

### Before Submission (Once Account is Approved)
- [ ] Privacy Policy is live and accessible
- [ ] Terms of Service is live (if hosting)
- [ ] All placeholder URLs removed
- [ ] No test API keys in production
- [ ] No debug logging in production builds
- [ ] Privacy Manifest file exists
- [ ] All required screenshots prepared
- [ ] App description written
- [ ] Support email configured

## 💡 Tips While Waiting

1. **TestFlight Beta** - Once you have the account, use TestFlight for beta testing
2. **Documentation** - Write/update any user-facing documentation
3. **Marketing Prep** - Prepare launch materials, social media posts
4. **Bug Fixes** - Fix any bugs found during testing
5. **Performance** - Optimize any slow areas

---

**Note:** Apple Developer account approval typically takes 24-48 hours, but can sometimes take longer. Use this time to prepare everything else!

