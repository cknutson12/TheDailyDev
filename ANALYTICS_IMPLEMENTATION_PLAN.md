# Analytics Implementation Plan

## 📋 Overview

This plan outlines the step-by-step implementation of analytics and attribution tracking for The Daily Dev app, based on the [Analytics & Attribution Plan](./ANALYTICS_AND_ATTRIBUTION_PLAN.md).

## 🎯 Goals

1. Track user conversion rates (install → sign up → purchase)
2. Identify drop-off points in the conversion funnel
3. Track marketing attribution (Instagram ads, App Store, etc.)
4. Measure source performance (which channels convert best)
5. Understand user behavior and journey

## 🏗️ Architecture

### Analytics Stack

1. **PostHog** (Primary Analytics)
   - Event tracking
   - Funnel analysis
   - User session recordings
   - Free tier: 1M events/month

2. **Branch.io** (Attribution)
   - Install attribution
   - Deep linking
   - Campaign tracking
   - Free tier: 10K MAU

3. **App Store Connect** (Built-in)
   - Organic installs
   - App Store metrics
   - Already available

4. **RevenueCat** (Already Integrated)
   - Subscription metrics
   - Revenue tracking
   - Already configured ✅

## 📦 Implementation Phases

### Phase 1: Setup & Infrastructure (Week 1)

#### Step 1.1: Add SDKs to Project
- [ ] Add PostHog iOS SDK via Swift Package Manager
  - URL: `https://github.com/PostHog/posthog-ios`
  - Version: Latest stable (3.x)
  
- [ ] Add Branch.io iOS SDK via Swift Package Manager
  - URL: `https://github.com/BranchMetrics/ios-branch-deep-linking`
  - Version: Latest stable (2.x)

- [ ] Verify SDKs are linked to TheDailyDev target

#### Step 1.2: Create Analytics Service
- [ ] Create `AnalyticsService.swift`
  - Singleton pattern (like `SubscriptionService`)
  - Abstract analytics providers behind interface
  - Handle initialization and configuration
  - Provide unified API for tracking events

- [ ] Add configuration to `Config.swift`
  - `postHogAPIKey` (from Config-Secrets.plist)
  - `branchAPIKey` (from Config-Secrets.plist)

- [ ] Add API keys to `Config-Secrets.plist`
  - `POSTHOG_API_KEY`
  - `BRANCH_API_KEY`

#### Step 1.3: Initialize SDKs
- [ ] Initialize PostHog in `TheDailyDevApp.swift` `init()`
  - Configure with API key
  - Set up user identification
  - Handle app lifecycle events

- [ ] Initialize Branch.io in `TheDailyDevApp.swift` `init()`
  - Initialize session
  - Handle deep links
  - Track attribution

- [ ] Create initialization helper in `AnalyticsService`

#### Step 1.4: App Tracking Transparency (ATT)
- [ ] Add ATT permission to `Info.plist`
  - Key: `NSUserTrackingUsageDescription`
  - Message: "We use tracking to measure the effectiveness of our ads and improve your experience."

- [ ] Create `TrackingPermissionManager.swift`
  - Request ATT permission
  - Handle permission responses
  - Store permission status

- [ ] Request permission at appropriate time
  - After user signs up (recommended)
  - Or on first app launch

### Phase 2: Basic Event Tracking (Week 2)

#### Step 2.1: App Lifecycle Events
- [ ] Track `app_open` when app launches
- [ ] Track `app_background` when app goes to background
- [ ] Track `app_foreground` when app returns to foreground
- [ ] Track `app_terminate` when app closes

**Implementation Location:**
- `TheDailyDevApp.swift` - Scene lifecycle methods

#### Step 2.2: Authentication Events
- [ ] Track `sign_up_started` when user begins sign-up
- [ ] Track `sign_up_completed` when user successfully signs up
- [ ] Track `sign_up_failed` if sign-up fails
- [ ] Track `sign_in_started` when user begins sign-in
- [ ] Track `sign_in_completed` when user successfully signs in
- [ ] Track `sign_in_failed` if sign-in fails
- [ ] Track `sign_out` when user signs out
- [ ] Track `email_verified` when email is verified
- [ ] Track `password_reset_requested` when user requests password reset
- [ ] Track `password_reset_completed` when password is reset

**Implementation Locations:**
- `SignUpView.swift`
- `LoginView.swift`
- `AuthManager.swift`
- `EmailVerificationView.swift`
- `ForgotPasswordView.swift`
- `ResetPasswordView.swift`

#### Step 2.3: Onboarding Events
- [ ] Track `onboarding_viewed` when onboarding screen appears
- [ ] Track `onboarding_completed` when user taps "Get Started"
- [ ] Track `onboarding_skipped` if user skips (if applicable)

**Implementation Location:**
- `OnboardingView.swift`

#### Step 2.4: Screen View Events
- [ ] Track `screen_view` for all major screens
  - `home_view`
  - `profile_view`
  - `subscription_benefits_view`
  - `subscription_details_view`
  - `subscription_settings_view`
  - `contributions_tracker_view`
  - `question_view` (with question type)
  - `question_review_view`

**Implementation:**
- Add `.onAppear` modifiers to track screen views
- Or use a custom view modifier

### Phase 3: Question & Engagement Events (Week 2-3)

#### Step 3.1: Question Events
- [ ] Track `question_viewed` when question is displayed
  - Properties: `question_id`, `question_type`, `question_category`
  
- [ ] Track `question_answered` when user submits answer
  - Properties: `question_id`, `question_type`, `is_correct`, `time_taken`
  
- [ ] Track `question_correct` when answer is correct
  - Properties: `question_id`, `question_type`, `time_taken`
  
- [ ] Track `question_incorrect` when answer is wrong
  - Properties: `question_id`, `question_type`, `time_taken`, `selected_answer`

**Implementation Locations:**
- `MultipleChoiceQuestionView.swift`
- `OrderingQuestionView.swift`
- `MatchingQuestionView.swift`
- `QuestionReviewView.swift`

#### Step 3.2: Progress Events
- [ ] Track `first_question_answered` (special event for conversion funnel)
  - Properties: `time_to_first_question` (seconds since sign-up)
  
- [ ] Track `streak_achieved` when user reaches streak milestones
  - Properties: `streak_days` (7, 14, 30, etc.)
  
- [ ] Track `progress_viewed` when user views contribution grid
  - Properties: `total_questions_answered`, `current_streak`

**Implementation Locations:**
- `QuestionService.swift` (when submitting answers)
- `ContributionsTracker.swift` (when viewing progress)

### Phase 4: Subscription Events (Week 3)

#### Step 4.1: Paywall Events
- [ ] Track `paywall_viewed` when subscription screen appears
  - Properties: `source` (home_screen, first_question_complete, profile, etc.)
  - Properties: `user_has_answered_question` (boolean)
  - Properties: `user_has_active_subscription` (boolean)

- [ ] Track `paywall_dismissed` when user closes paywall
  - Properties: `source`, `time_viewed` (seconds)

**Implementation Locations:**
- `SubscriptionBenefitsView.swift`
- `RevenueCatPaywallView.swift`

#### Step 4.2: Purchase Events
- [ ] Track `subscription_purchase_started` when user taps purchase
  - Properties: `plan` (monthly/yearly), `package_type`
  
- [ ] Track `subscription_purchased` when purchase succeeds
  - Properties: `plan`, `price`, `is_trial`, `trial_days`
  
- [ ] Track `subscription_purchase_failed` if purchase fails
  - Properties: `plan`, `error_message`
  
- [ ] Track `subscription_purchase_cancelled` if user cancels
  - Properties: `plan`

**Implementation Locations:**
- `RevenueCatPaywallView.swift`
- `RevenueCatSubscriptionProvider.swift`

#### Step 4.3: Trial Events
- [ ] Track `trial_started` when trial begins
  - Properties: `plan`, `trial_end_date`
  
- [ ] Track `trial_converted` when trial converts to paid
  - Properties: `plan`, `trial_duration_days`
  
- [ ] Track `trial_expired` when trial ends without conversion
  - Properties: `plan`, `trial_duration_days`

**Implementation Locations:**
- `SubscriptionService.swift` (when subscription status changes)
- RevenueCat webhook (for trial expiration)

#### Step 4.4: Subscription Management Events
- [ ] Track `subscription_management_opened` when user opens management portal
- [ ] Track `subscription_cancelled` when user cancels subscription
- [ ] Track `subscription_restored` when user restores purchases

**Implementation Locations:**
- `SubscriptionSettingsView.swift`
- `SubscriptionDetailsView.swift`

### Phase 5: Attribution & User Properties (Week 3-4)

#### Step 5.1: Attribution Setup
- [ ] Configure Branch.io for attribution tracking
  - Set up deep links for Instagram/Facebook ads
  - Configure UTM parameter tracking
  - Test attribution flow

- [ ] Track install attribution
  - Store `install_source` (Instagram, App Store, referral, etc.)
  - Store `campaign` name
  - Store `ad_group` (if applicable)
  - Store `creative` (if applicable)

**Implementation:**
- `AnalyticsService.swift` - Get attribution from Branch
- Set as user property in PostHog

#### Step 5.2: User Properties
- [ ] Set user ID after sign-in
  - PostHog: `PostHog.shared.identify(userId)`
  - Branch: Set user ID (if needed)

- [ ] Track user properties
  - `subscription_status` (inactive, trialing, active, cancelled)
  - `subscription_plan` (monthly, yearly, none)
  - `streak_count` (current streak)
  - `total_questions_answered`
  - `install_source` (from Branch)
  - `campaign` (from Branch)
  - `sign_up_date`
  - `first_question_date`

**Implementation:**
- Update properties when they change
- `SubscriptionService.swift` - Update subscription properties
- `QuestionService.swift` - Update engagement properties
- `AuthManager.swift` - Set user ID and sign-up date

#### Step 5.3: User Journey Tracking
- [ ] Track time to key events
  - `time_to_sign_up` (install → sign up)
  - `time_to_first_question` (sign up → first question)
  - `time_to_paywall_view` (first question → paywall)
  - `time_to_purchase` (paywall → purchase)

**Implementation:**
- Store timestamps at each stage
- Calculate differences when tracking events

### Phase 6: Funnel Analysis Setup (Week 4)

#### Step 6.1: Define Conversion Funnel
Create funnel stages in PostHog:
1. `app_open` (or `app_install` from Branch)
2. `sign_up_completed`
3. `first_question_answered`
4. `paywall_viewed`
5. `subscription_purchased`

#### Step 6.2: Funnel Tracking
- [ ] Ensure all funnel events are tracked
- [ ] Add properties to link events (user_id, session_id)
- [ ] Test funnel data collection
- [ ] Verify funnel in PostHog dashboard

#### Step 6.3: Drop-off Analysis
- [ ] Identify biggest drop-off points
- [ ] Track drop-off reasons (if possible)
- [ ] Set up alerts for significant changes

### Phase 7: Testing & Validation (Week 4)

#### Step 7.1: Event Testing
- [ ] Test all events fire correctly
- [ ] Verify event properties are correct
- [ ] Check events appear in PostHog dashboard
- [ ] Verify attribution data from Branch

#### Step 7.2: Funnel Testing
- [ ] Complete full user journey
- [ ] Verify all funnel stages are tracked
- [ ] Check funnel conversion rates
- [ ] Test with different sources (App Store, Instagram ad)

#### Step 7.3: Privacy Testing
- [ ] Test ATT permission flow
- [ ] Verify analytics work with permission denied
- [ ] Test data deletion (if user requests)

## 📁 File Structure

```
TheDailyDev/
├── AnalyticsService.swift          # Central analytics service
├── TrackingPermissionManager.swift  # ATT permission handling
├── Config.swift                     # Add API keys
└── Config-Secrets.plist            # Store API keys
```

## 🔧 Code Structure

### AnalyticsService.swift Structure

```swift
class AnalyticsService {
    static let shared = AnalyticsService()
    
    // Initialization
    func initialize()
    func setUserID(_ userId: String)
    
    // Event Tracking
    func track(_ event: String, properties: [String: Any]?)
    
    // User Properties
    func setUserProperty(_ key: String, value: Any)
    func setUserProperties(_ properties: [String: Any])
    
    // Screen Tracking
    func trackScreen(_ screenName: String, properties: [String: Any]?)
    
    // Attribution
    func getAttribution() -> AttributionData?
}
```

## 📊 Key Events to Track

### Critical Events (Must Have)
1. `app_open`
2. `sign_up_completed`
3. `sign_in_completed`
4. `first_question_answered`
5. `paywall_viewed`
6. `subscription_purchased`
7. `trial_started`
8. `trial_converted`

### Important Events (Should Have)
1. `question_answered`
2. `question_correct`
3. `streak_achieved`
4. `subscription_cancelled`
5. `screen_view`

### Nice to Have Events
1. `onboarding_completed`
2. `password_reset_requested`
3. `subscription_restored`
4. `feedback_submitted`

## 🎯 Key Metrics to Calculate

### Conversion Metrics
- Overall conversion rate: `subscription_purchased / app_open`
- Sign-up rate: `sign_up_completed / app_open`
- First question rate: `first_question_answered / sign_up_completed`
- Paywall view rate: `paywall_viewed / first_question_answered`
- Purchase rate: `subscription_purchased / paywall_viewed`

### Source Performance
- Conversion rate by source (Instagram, App Store, etc.)
- Cost per acquisition (CPA) by source
- Return on ad spend (ROAS) by source

### Engagement Metrics
- Time to first question
- Questions answered per user
- Streak retention
- Daily active users (DAU)

## 🔒 Privacy Considerations

### App Tracking Transparency (ATT)
- Request permission after sign-up (not on first launch)
- Explain why tracking is needed
- Handle denied permissions gracefully
- Analytics still work without ATT (just less accurate attribution)

### Data Retention
- PostHog: 90 days default (configurable)
- Branch: Per their privacy policy
- User data: Until account deletion

### GDPR/CCPA Compliance
- PostHog: GDPR compliant, data deletion API
- Branch: GDPR compliant, data deletion API
- Implement user data deletion if requested

## 🚀 Implementation Order

### Week 1: Foundation
1. Add SDKs to project
2. Create AnalyticsService
3. Initialize SDKs
4. Add ATT permission

### Week 2: Core Events
1. App lifecycle events
2. Authentication events
3. Screen view events
4. Question events

### Week 3: Subscription & Attribution
1. Subscription events
2. Attribution setup
3. User properties
4. User journey tracking

### Week 4: Analysis & Testing
1. Funnel setup
2. Testing
3. Dashboard creation
4. Documentation

## 📝 Next Steps

1. **Review this plan** - Make sure it aligns with your goals
2. **Get API keys** - Sign up for PostHog and Branch.io accounts
3. **Start Phase 1** - Add SDKs and create AnalyticsService
4. **Iterate** - Start with critical events, expand as needed

## ❓ Questions to Answer

Before starting implementation, consider:
- Do you already have PostHog/Branch accounts?
- What's your priority: conversion tracking or attribution?
- Do you want to start with basic events or full implementation?
- Any specific events or metrics you need beyond the plan?

---

**Ready to start?** Begin with Phase 1, Step 1.1: Adding SDKs to the project.

