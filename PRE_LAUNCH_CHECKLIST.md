# Pre-Launch Checklist

A comprehensive checklist of tasks to complete before launching The Daily Dev to the App Store.

## 🧪 Testing Checklist

### Core User Flows
- [ ] **Sign Up Flow**
  - [ ] Email/password sign up
  - [ ] Google OAuth sign up
  - [ ] GitHub OAuth sign up
  - [ ] Email verification flow
  - [ ] Error handling for invalid emails/passwords
  - [ ] Error handling for existing accounts

- [ ] **Login Flow**
  - [ ] Email/password login
  - [ ] Google OAuth login
  - [ ] GitHub OAuth login
  - [ ] "Forgot Password" flow
  - [ ] Password reset email delivery
  - [ ] Password reset deep link handling
  - [ ] Error handling for wrong credentials

- [ ] **Question Flow**
  - [ ] View today's question
  - [ ] Answer multiple choice question
  - [ ] Answer matching question
  - [ ] Answer ordering question
  - [ ] View correct answer and explanation
  - [ ] First free question popup
  - [ ] Subscription required message after first question
  - [ ] Friday free access

- [ ] **Subscription Flow**
  - [ ] View subscription benefits
  - [ ] Start free trial (monthly plan)
  - [ ] Start free trial (annual plan)
  - [ ] Complete Stripe checkout
  - [ ] Trial-to-paid conversion
  - [ ] View subscription details
  - [ ] Access billing portal
  - [ ] Cancel subscription
  - [ ] Subscription status updates after purchase

- [ ] **Progress Tracking**
  - [ ] View contribution tracker
  - [ ] View statistics page
  - [ ] Streak calculation
  - [ ] Category performance display
  - [ ] Progress updates after answering

- [ ] **Settings & Profile**
  - [ ] View profile information
  - [ ] Submit feedback
  - [ ] Sign out
  - [ ] View subscription details

### Edge Cases & Error Handling
- [ ] **Network Errors**
  - [ ] No internet connection
  - [ ] Slow/unstable connection
  - [ ] Request timeout
  - [ ] Server errors (500, 503, etc.)
  - [ ] Graceful error messages

- [ ] **Session Management**
  - [ ] Expired session handling
  - [ ] Token refresh
  - [ ] Auto-logout on session expiry
  - [ ] Deep link handling when logged out

- [ ] **Subscription Edge Cases**
  - [ ] Trial expired
  - [ ] Payment failed
  - [ ] Subscription cancelled
  - [ ] Webhook delays
  - [ ] Multiple devices with same account

- [ ] **Data Edge Cases**
  - [ ] No questions available
  - [ ] User with no progress
  - [ ] User with no subscription
  - [ ] Empty states

### Device & OS Testing
- [ ] **iOS Versions**
  - [ ] iOS 17.5 (minimum)
  - [ ] iOS 18.0
  - [ ] Latest iOS version

- [ ] **Device Types**
  - [ ] iPhone SE (small screen)
  - [ ] iPhone 15/16 (standard)
  - [ ] iPhone 15/16 Pro Max (large screen)
  - [ ] iPad (if supported)

- [ ] **Orientations**
  - [ ] Portrait mode
  - [ ] Landscape mode (if supported)

### Performance Testing
- [ ] App launch time (< 3 seconds)
- [ ] Question loading time
- [ ] Image loading performance
- [ ] Smooth scrolling in lists
- [ ] Memory usage (check for leaks)
- [ ] Battery usage

## 🧹 Code Cleanup

### Debug Code Removal
- [ ] Remove or conditionally compile debug `print()` statements
- [ ] Remove test/example code
- [ ] Remove commented-out code
- [ ] Remove unused files (e.g., `ConfigTest.swift` if not needed)

### Code Quality
- [ ] Add missing error handling
- [ ] Add code comments for complex logic
- [ ] Ensure consistent code style
- [ ] Remove unused imports
- [ ] Fix any compiler warnings
- [ ] Remove unused variables/functions

### Logging Strategy
- [ ] Implement proper logging framework (or conditional logging)
- [ ] Use different log levels (debug, info, error)
- [ ] Remove sensitive data from logs
- [ ] Consider using OSLog for production

### File Organization
- [ ] Ensure all files are properly organized
- [ ] Remove any duplicate code
- [ ] Verify all files are added to Xcode project

## 📱 Apple Requirements

### App Store Connect Setup
- [ ] Create App Store Connect listing
- [ ] App name and subtitle
- [ ] App description (up to 4000 characters)
- [ ] Keywords (up to 100 characters)
- [ ] Support URL
- [ ] Marketing URL (optional)
- [ ] Privacy Policy URL (REQUIRED)
- [ ] App category (Education/Productivity)
- [ ] Age rating (4+ recommended)
- [ ] App icon (1024x1024, no transparency)
- [ ] Screenshots (required for all device sizes)
- [ ] App preview video (optional but recommended)

### Privacy & Legal
- [ ] **Privacy Policy** (REQUIRED)
  - [ ] Data collection disclosure
  - [ ] Third-party services (Supabase, Stripe, Google, GitHub)
  - [ ] Data usage explanation
  - [ ] User rights (GDPR compliance if applicable)
  - [ ] Contact information
  - [ ] Host on your website

- [ ] **Terms of Service** (Recommended)
  - [ ] User responsibilities
  - [ ] Subscription terms
  - [ ] Refund policy
  - [ ] Content usage rights
  - [ ] Limitation of liability
  - [ ] Host Terms of Service on website
  - [ ] Add Terms of Service link to website (footer, about page, etc.)

- [ ] **Privacy Manifest** (iOS 17+ requirement)
  - [ ] Create `PrivacyInfo.xcprivacy` file
  - [ ] Declare required reason APIs used
  - [ ] List third-party SDKs

### App Store Guidelines Compliance
- [ ] **Guideline 2.1 - App Completeness**
  - [ ] All features functional
  - [ ] No placeholder content
  - [ ] No broken links

- [ ] **Guideline 3.1.1 - In-App Purchase**
  - [ ] Subscription terms clearly displayed
  - [ ] Auto-renewal clearly explained
  - [ ] Cancel anytime messaging
  - [ ] Restore purchases option (if applicable)

- [ ] **Guideline 5.1.1 - Privacy**
  - [ ] Privacy policy accessible
  - [ ] Data collection disclosed
  - [ ] User consent obtained

- [ ] **Guideline 2.3 - Accurate Metadata**
  - [ ] Accurate screenshots
  - [ ] Accurate description
  - [ ] No misleading information

### Technical Requirements
- [ ] **Info.plist**
  - [ ] Privacy descriptions for all required permissions
  - [ ] URL schemes properly configured
  - [ ] Bundle identifier matches App Store Connect

- [ ] **Entitlements**
  - [ ] Push notifications (if using)
  - [ ] Associated domains (if using)
  - [ ] App groups (if using)

- [ ] **Signing & Capabilities**
  - [ ] Proper code signing
  - [ ] All capabilities configured
  - [ ] Background modes (if needed)

## 🔒 Security & Privacy

### Data Security
- [ ] No hardcoded secrets in code
- [ ] API keys stored securely (Config.plist, not in git)
- [ ] HTTPS for all network requests
- [ ] Sensitive data encrypted at rest (if stored locally)

### Privacy Compliance
- [ ] Privacy policy URL in Info.plist
- [ ] User data deletion capability
- [ ] GDPR compliance (if applicable)
- [ ] CCPA compliance (if applicable)

## 📊 Analytics & Monitoring (Optional but Recommended)

### Crash Reporting
- [ ] Set up crash reporting (e.g., Firebase Crashlytics, Sentry)
- [ ] Test crash reporting
- [ ] Configure crash alerts

### Analytics
- [ ] Set up analytics (e.g., Firebase Analytics, Mixpanel)
- [ ] Track key events:
  - [ ] User sign ups
  - [ ] Question answers
  - [ ] Subscription purchases
  - [ ] Feature usage

### Performance Monitoring
- [ ] Set up performance monitoring
- [ ] Monitor API response times
- [ ] Monitor app performance metrics

## 🎨 App Store Assets

### Screenshots (Required)
- [ ] iPhone 6.7" (iPhone 15 Pro Max, etc.) - 1290 x 2796
- [ ] iPhone 6.5" (iPhone 11 Pro Max, etc.) - 1242 x 2688
- [ ] iPhone 5.5" (iPhone 8 Plus, etc.) - 1242 x 2208
- [ ] iPad Pro 12.9" (if iPad supported) - 2048 x 2732

### App Icon
- [ ] 1024 x 1024 PNG
- [ ] No transparency
- [ ] No rounded corners (Apple adds them)
- [ ] Matches app design

### App Preview Video (Optional)
- [ ] 15-30 seconds
- [ ] Shows key features
- [ ] High quality
- [ ] No text overlays (Apple adds them)

## 🚀 Deployment Preparation

### Version Management
- [ ] Set version number (e.g., 1.0.0)
- [ ] Set build number (e.g., 1)
- [ ] Update version in Info.plist
- [ ] Update version in Xcode project settings

### Build Configuration
- [ ] Create Release build configuration
- [ ] Disable debug logging in Release
- [ ] Optimize for Release builds
- [ ] Test Release build thoroughly

### App Store Connect
- [ ] Create app record
- [ ] Upload build via Xcode or Transporter
- [ ] Complete all required metadata
- [ ] Submit for review

### Pre-Release Testing
- [ ] TestFlight beta testing
  - [ ] Invite internal testers
  - [ ] Test all features in TestFlight build
  - [ ] Gather feedback
  - [ ] Fix critical issues

## 📝 Documentation

### User-Facing
- [ ] App Store description
- [ ] What's New description (for updates)
- [ ] In-app help/tutorial (optional)

### Developer Documentation
- [ ] README.md updated
- [ ] Code comments for complex logic
- [ ] API documentation (if applicable)
- [ ] Deployment guide

## ✅ Final Checks

### Before Submission
- [ ] All tests passing
- [ ] No critical bugs
- [ ] All required assets uploaded
- [ ] Privacy policy live and accessible
- [ ] Terms of service live (if applicable)
- [ ] Support email configured
- [ ] App reviewed by someone else
- [ ] Tested on multiple devices
- [ ] Tested with different network conditions

### Post-Submission
- [ ] Monitor App Store Connect for review status
- [ ] Respond to reviewer questions promptly
- [ ] Prepare for potential rejection and fixes
- [ ] Plan marketing/launch strategy

## 🎯 Priority Order

### Critical (Must Do Before Launch)
1. **Privacy Policy** ⚠️ IN PROGRESS
   - ✅ Template created and customized
   - ⏳ Host privacy policy on website
   - ⏳ Update Config.swift with actual URL
   - ⏳ Update Info.plist with actual URL
   - ⏳ Test Privacy Policy link in Settings
   - See `PRIVACY_POLICY_IMPLEMENTATION.md` for detailed steps
2. Complete all core user flows testing
3. Set up App Store Connect listing
4. Create app screenshots
5. Remove debug code
6. Test on physical devices
7. Fix all critical bugs

### Important (Should Do Before Launch)
1. Add error handling improvements
2. Create Terms of Service
3. Set up crash reporting
4. TestFlight beta testing
5. Performance optimization
6. Code cleanup

### Nice to Have (Can Do After Launch)
1. Analytics setup
2. App preview video
3. In-app tutorials
4. Advanced monitoring

## 📞 Support & Contact

Before launch, ensure you have:
- [ ] Support email address
- [ ] Support website/contact form
- [ ] Response plan for user issues
- [ ] Plan for handling App Store reviews

---

**Last Updated:** November 2025
**Next Review:** Before each major release

