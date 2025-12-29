# Analytics & Attribution Tracking Plan

## 🎯 Goals

1. **Track Conversion Rates**: See how many users convert to paid subscriptions
2. **Identify Drop-off Points**: Understand where users stop in the conversion funnel
3. **Attribution Tracking**: Know where users found the app (Instagram ads, App Store, etc.)
4. **Source Performance**: Compare conversion rates by marketing channel
5. **User Journey Analysis**: Track user behavior from install to conversion

## 📊 Solution Overview

### Recommended Stack (Cost-Effective)

**Primary Analytics**: **PostHog** (Open Source, Free tier available)
- Event tracking
- Funnel analysis
- User session recordings
- Feature flags
- A/B testing
- **Cost**: Free up to 1M events/month

**Attribution**: **Branch.io** (Free tier available)
- Deep linking
- Attribution tracking
- Cross-platform support
- **Cost**: Free up to 10K MAU

**App Store Analytics**: **App Store Connect** (Free, built-in)
- Organic installs
- App Store impressions
- Conversion rates from App Store

**RevenueCat Analytics**: **Already Integrated** (Free)
- Subscription conversion rates
- Revenue metrics
- Churn analysis

**Optional - Advanced**: **Firebase Analytics** (Free)
- Google's free analytics
- Integration with other Firebase services
- Real-time analytics

---

## 🏗️ Architecture

### 1. **PostHog** (Primary Analytics Platform)

**Why PostHog?**
- ✅ Free tier (1M events/month)
- ✅ Self-hostable (if needed later)
- ✅ Funnel analysis built-in
- ✅ Session recordings
- ✅ Privacy-friendly
- ✅ Easy iOS integration

**What to Track:**
- App installs
- User sign-ups
- First question answered
- Subscription paywall viewed
- Subscription purchased
- Trial started
- Trial converted
- Subscription cancelled

**Implementation:**
```swift
// Track key events
PostHog.shared.capture("subscription_paywall_viewed")
PostHog.shared.capture("subscription_purchased", properties: [
    "plan": "monthly",
    "source": "home_screen"
])
```

### 2. **Branch.io** (Attribution & Deep Linking)

**Why Branch?**
- ✅ Free tier (10K MAU)
- ✅ Attribution tracking
- ✅ Deep linking
- ✅ SKAdNetwork integration
- ✅ Works with Instagram/Facebook ads

**What It Tracks:**
- Install source (Instagram ad, App Store, referral, etc.)
- Campaign performance
- User journey from ad click to install

**Setup:**
- Create Branch account
- Configure Instagram/Facebook ad links
- Add Branch SDK to app
- Track attribution data

### 3. **App Store Connect Analytics** (Free, Built-in)

**What It Provides:**
- Organic installs
- App Store impressions
- Conversion rates from App Store
- User demographics
- Retention metrics

**Setup:**
- Already available if app is in App Store Connect
- No code changes needed
- View in App Store Connect dashboard

### 4. **RevenueCat Analytics** (Already Integrated)

**What It Provides:**
- Subscription conversion rates
- Revenue metrics
- Churn analysis
- Trial conversion rates
- Customer lifetime value

**Setup:**
- Already configured ✅
- View in RevenueCat dashboard

### 5. **Custom Supabase Events** (Optional)

**What to Track:**
- User progress events
- Question completion rates
- Feature usage
- Error tracking

**Implementation:**
- Create `analytics_events` table in Supabase
- Log events from app
- Query for custom insights

---

## 📈 Conversion Funnel Tracking

### Funnel Stages

1. **App Install** → Tracked by Branch/App Store Connect
2. **App Open** → Tracked by PostHog
3. **Sign Up** → Tracked by PostHog + Supabase
4. **First Question Answered** → Tracked by PostHog + Supabase
5. **Paywall Viewed** → Tracked by PostHog
6. **Subscription Purchased** → Tracked by PostHog + RevenueCat

### Key Metrics to Track

**Conversion Rates:**
- Install → Sign Up: `sign_ups / installs`
- Sign Up → First Question: `first_question / sign_ups`
- First Question → Paywall View: `paywall_views / first_question`
- Paywall View → Purchase: `purchases / paywall_views`
- Overall: `purchases / installs`

**Drop-off Analysis:**
- Where do users stop?
- What's the biggest drop-off point?
- Time to conversion

**Source Performance:**
- Instagram ads: `conversions / installs from Instagram`
- App Store: `conversions / installs from App Store`
- Other sources: Compare all sources

---

## 🔗 Attribution Setup

### Instagram/Facebook Ads

**Setup Process:**
1. Create Branch account
2. Configure Instagram ad links to use Branch deep links
3. Add UTM parameters to track campaigns
4. Branch SDK automatically tracks attribution

**Example Deep Link:**
```
https://your-app.app.link/install?campaign=instagram_summer&source=instagram&medium=ad
```

**What You'll See:**
- Which Instagram ad led to install
- Which Instagram ad led to conversion
- Cost per install (CPI)
- Cost per acquisition (CPA)
- Return on ad spend (ROAS)

### App Store Connect

**Organic Installs:**
- Tracked automatically
- View in App Store Connect → Analytics
- See impressions, installs, conversion rates

**Campaign Links:**
- Use App Store Campaign Links
- Track specific campaigns
- Compare campaign performance

---

## 🛠️ Implementation Plan

### Phase 1: Basic Analytics (Week 1)

**Step 1: Set Up PostHog**
- [ ] Create PostHog account
- [ ] Get API key
- [ ] Add PostHog SDK to Xcode project
- [ ] Initialize PostHog in `TheDailyDevApp.swift`
- [ ] Track basic events (app_open, sign_up, etc.)

**Step 2: Set Up Branch.io**
- [ ] Create Branch account
- [ ] Configure app in Branch dashboard
- [ ] Add Branch SDK to Xcode project
- [ ] Initialize Branch in `TheDailyDevApp.swift`
- [ ] Test deep linking

**Step 3: App Tracking Transparency (ATT)**
- [ ] Add ATT permission to `Info.plist`
- [ ] Request tracking permission
- [ ] Handle permission responses

### Phase 2: Event Tracking (Week 2)

**Step 4: Track Key Events**
- [ ] App lifecycle events (open, background, foreground)
- [ ] Authentication events (sign_up, sign_in, sign_out)
- [ ] Question events (question_viewed, question_answered, question_correct)
- [ ] Subscription events (paywall_viewed, subscription_purchased, trial_started)
- [ ] Navigation events (screen_viewed)

**Step 5: User Properties**
- [ ] Set user ID after sign-in
- [ ] Track user properties (subscription_status, streak_count, etc.)
- [ ] Update properties when they change

### Phase 3: Funnel Analysis (Week 3)

**Step 6: Create Conversion Funnels**
- [ ] Define funnel stages in PostHog
- [ ] Set up funnel tracking
- [ ] Test funnel data collection
- [ ] Create dashboard views

**Step 7: Attribution Integration**
- [ ] Configure Instagram ad links with Branch
- [ ] Set up UTM parameter tracking
- [ ] Test attribution flow
- [ ] Verify data in Branch dashboard

### Phase 4: Advanced Analytics (Week 4)

**Step 8: Custom Insights**
- [ ] Create custom queries in PostHog
- [ ] Set up alerts for key metrics
- [ ] Create weekly reports
- [ ] Integrate with RevenueCat data

**Step 9: A/B Testing Setup**
- [ ] Set up feature flags in PostHog
- [ ] Create A/B test for paywall
- [ ] Track conversion rates by variant

---

## 📱 Code Implementation

### 1. PostHog Setup

**Add to Package.swift or Xcode:**
```swift
// Swift Package Manager
dependencies: [
    .package(url: "https://github.com/PostHog/posthog-ios", from: "3.0.0")
]
```

**Initialize in TheDailyDevApp.swift:**
```swift
import PostHog

init() {
    // ... existing RevenueCat setup ...
    
    // Initialize PostHog
    let config = PostHogConfig(apiKey: Config.postHogAPIKey)
    PostHog.shared.setup(config)
    
    print("✅ PostHog initialized")
}
```

**Track Events:**
```swift
// In SubscriptionBenefitsView
PostHog.shared.capture("subscription_paywall_viewed", properties: [
    "source": "home_screen",
    "user_has_answered_question": hasAnsweredQuestion
])

// In RevenueCatPaywallView after purchase
PostHog.shared.capture("subscription_purchased", properties: [
    "plan": package.storeProduct.productIdentifier,
    "price": package.storeProduct.price.stringValue,
    "trial": isTrial ? "yes" : "no"
])
```

### 2. Branch.io Setup

**Add to Package.swift or Xcode:**
```swift
// Swift Package Manager
dependencies: [
    .package(url: "https://github.com/BranchMetrics/ios-branch-deep-linking", from: "2.0.0")
]
```

**Initialize in TheDailyDevApp.swift:**
```swift
import Branch

init() {
    // ... existing setup ...
    
    // Initialize Branch
    Branch.getInstance().initSession(launchOptions: nil)
    
    print("✅ Branch initialized")
}
```

**Track Attribution:**
```swift
// Branch automatically tracks installs and attribution
// Access attribution data:
Branch.getInstance().getFirstReferringParams { (params, error) in
    if let params = params {
        let source = params["~channel"] as? String
        let campaign = params["~campaign"] as? String
        // Store in PostHog as user property
        PostHog.shared.identify(userId, properties: [
            "install_source": source ?? "unknown",
            "campaign": campaign ?? "unknown"
        ])
    }
}
```

### 3. App Tracking Transparency

**Add to Info.plist:**
```xml
<key>NSUserTrackingUsageDescription</key>
<string>We use tracking to measure the effectiveness of our ads and improve your experience.</string>
```

**Request Permission:**
```swift
import AppTrackingTransparency
import AdSupport

func requestTrackingPermission() {
    if #available(iOS 14, *) {
        ATTrackingManager.requestTrackingAuthorization { status in
            switch status {
            case .authorized:
                print("✅ Tracking authorized")
                // Initialize analytics with full tracking
            case .denied, .restricted, .notDetermined:
                print("⚠️ Tracking not authorized")
                // Initialize analytics with limited tracking
            @unknown default:
                break
            }
        }
    }
}
```

---

## 📊 Dashboard & Reporting

### PostHog Dashboard

**Key Dashboards to Create:**
1. **Conversion Funnel**
   - Install → Sign Up → First Question → Paywall → Purchase
   - Drop-off rates at each stage

2. **Source Performance**
   - Conversions by source (Instagram, App Store, etc.)
   - Cost per acquisition by source

3. **User Behavior**
   - Time to first question
   - Time to paywall view
   - Time to purchase

4. **Subscription Metrics**
   - Trial conversion rate
   - Subscription retention
   - Churn analysis

### Branch Dashboard

**Key Metrics:**
- Installs by source
- Attribution data
- Deep link performance
- Campaign ROI

### RevenueCat Dashboard

**Key Metrics:**
- Subscription conversion rate
- Revenue metrics
- Trial conversion
- Customer lifetime value

### App Store Connect

**Key Metrics:**
- Organic installs
- App Store impressions
- Conversion rates
- User demographics

---

## 💰 Cost Analysis

### Free Tier Options

**PostHog:**
- Free: 1M events/month
- Paid: $0.000225 per event after 1M
- **Estimated cost**: $0-50/month (depending on usage)

**Branch.io:**
- Free: 10K MAU
- Paid: $99/month for 50K MAU
- **Estimated cost**: $0-99/month

**App Store Connect:**
- Free (built-in)
- **Cost**: $0

**RevenueCat:**
- Already integrated
- **Cost**: $0 (free tier)

**Total Estimated Cost: $0-149/month**

### Paid Options (If Needed)

**Mixpanel:**
- Free: 20M events/month
- Paid: $25/month for 100M events
- **Better for**: Advanced segmentation, cohort analysis

**Amplitude:**
- Free: 10M events/month
- Paid: $995/month for 1B events
- **Better for**: Product analytics, user journey analysis

**AppsFlyer:**
- Free: 10K installs/month
- Paid: Custom pricing
- **Better for**: Enterprise attribution, advanced fraud prevention

---

## 🔒 Privacy & Compliance

### App Tracking Transparency (ATT)

**Required for:**
- IDFA (Identifier for Advertisers) access
- Cross-app tracking
- Attribution tracking

**Implementation:**
- Request permission after user signs up
- Explain why tracking is needed
- Handle denied permissions gracefully

### GDPR/CCPA Compliance

**PostHog:**
- ✅ GDPR compliant
- ✅ Data retention controls
- ✅ User data deletion

**Branch:**
- ✅ GDPR compliant
- ✅ Privacy controls
- ✅ Data deletion API

### Data Retention

**Recommendations:**
- Keep event data for 90 days (PostHog default)
- Keep user data until account deletion
- Anonymize data after retention period

---

## 🎯 Key Metrics to Track

### Conversion Metrics

1. **Overall Conversion Rate**
   - `purchases / installs * 100`
   - Target: 2-5% (industry average)

2. **Funnel Conversion Rates**
   - Install → Sign Up: Target 30-40%
   - Sign Up → First Question: Target 60-70%
   - First Question → Paywall: Target 40-50%
   - Paywall → Purchase: Target 10-20%

3. **Source Performance**
   - Instagram ads: Track CPA, ROAS
   - App Store: Track organic conversion rate
   - Compare all sources

### Engagement Metrics

1. **Time to First Question**
   - Average time from sign-up to first question
   - Target: < 5 minutes

2. **Question Completion Rate**
   - `questions_completed / questions_viewed * 100`
   - Target: > 80%

3. **Streak Retention**
   - Users with 7+ day streaks
   - Target: > 20% of active users

### Revenue Metrics

1. **Trial Conversion Rate**
   - `trial_conversions / trials_started * 100`
   - Target: 30-50%

2. **Monthly Recurring Revenue (MRR)**
   - Tracked in RevenueCat
   - Monitor growth

3. **Customer Lifetime Value (LTV)**
   - Tracked in RevenueCat
   - Compare to acquisition cost

---

## 🚀 Next Steps

### Immediate Actions

1. **Choose Analytics Platform**
   - ✅ Recommended: PostHog (free tier, easy setup)
   - Alternative: Firebase Analytics (if using other Firebase services)

2. **Set Up Attribution**
   - ✅ Recommended: Branch.io (free tier, Instagram integration)
   - Alternative: AppsFlyer (if need enterprise features)

3. **Implement ATT**
   - Add permission request
   - Handle denied permissions

4. **Start Tracking**
   - Begin with basic events
   - Expand to funnel tracking
   - Add source attribution

### Long-term Goals

1. **Optimize Conversion Funnel**
   - Identify drop-off points
   - A/B test improvements
   - Iterate based on data

2. **Optimize Marketing Spend**
   - Compare source performance
   - Focus budget on best sources
   - Test new channels

3. **Improve User Experience**
   - Use session recordings
   - Identify UX issues
   - Fix conversion blockers

---

## 📚 Resources

### Documentation

- [PostHog iOS SDK](https://posthog.com/docs/integrate/client/ios)
- [Branch.io iOS SDK](https://help.branch.io/developers-hub/docs/ios-sdk-overview)
- [App Tracking Transparency](https://developer.apple.com/documentation/apptrackingtransparency)
- [SKAdNetwork](https://developer.apple.com/documentation/storekit/skadnetwork)

### Tutorials

- [PostHog Funnel Analysis](https://posthog.com/docs/user-guides/funnels)
- [Branch Attribution Setup](https://help.branch.io/developers-hub/docs/attribution-overview)
- [iOS Analytics Best Practices](https://developer.apple.com/app-store/app-analytics/)

---

## ✅ Implementation Checklist

### Phase 1: Setup (Week 1)
- [ ] Create PostHog account
- [ ] Create Branch.io account
- [ ] Add PostHog SDK to project
- [ ] Add Branch SDK to project
- [ ] Initialize both SDKs in app
- [ ] Add ATT permission to Info.plist
- [ ] Request ATT permission

### Phase 2: Basic Tracking (Week 2)
- [ ] Track app lifecycle events
- [ ] Track authentication events
- [ ] Track question events
- [ ] Track subscription events
- [ ] Set user properties
- [ ] Test event tracking

### Phase 3: Attribution (Week 3)
- [ ] Configure Branch deep links
- [ ] Set up Instagram ad links
- [ ] Test attribution flow
- [ ] Verify attribution data
- [ ] Create PostHog dashboards

### Phase 4: Analysis (Week 4)
- [ ] Create conversion funnels
- [ ] Set up alerts
- [ ] Create weekly reports
- [ ] Analyze drop-off points
- [ ] Optimize based on data

---

## 🎉 Expected Outcomes

After implementation, you'll be able to:

1. **See Conversion Rates**
   - Overall: X% of installs convert to paid
   - By source: Instagram ads convert at Y%, App Store at Z%

2. **Identify Drop-off Points**
   - "40% of users drop off at paywall"
   - "Users who answer 3+ questions convert 2x better"

3. **Optimize Marketing**
   - "Instagram ads have 3% conversion vs 1% for App Store"
   - "Focus budget on Instagram ads"

4. **Improve Product**
   - "Users who see paywall after 3 questions convert better"
   - "Trial users convert 40% vs 10% for direct purchase"

---

## 💡 Pro Tips

1. **Start Simple**: Begin with basic event tracking, expand later
2. **Focus on Funnels**: Conversion funnels are most valuable
3. **Test Attribution**: Verify attribution data is accurate
4. **Privacy First**: Always request ATT permission properly
5. **Iterate**: Use data to make improvements, then measure again

---

## 🤔 Questions to Answer

After implementation, you'll be able to answer:

- What % of users convert to paid subscriptions?
- Where do users drop off in the conversion funnel?
- Which marketing channel has the best conversion rate?
- What's the cost per acquisition (CPA) for Instagram ads?
- What's the return on ad spend (ROAS) for each channel?
- How long does it take users to convert?
- What user actions predict conversion?
- Which features drive the most conversions?

---

**Ready to implement?** Start with Phase 1 and work through the checklist. The free tiers of PostHog and Branch should be sufficient to get started, and you can upgrade later if needed.



