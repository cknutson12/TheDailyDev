# Onboarding Implementation Plan

## 🎯 Goal

Add a personal onboarding message from Arjay McCandless that appears after sign-up, before the subscription screen. This will:
- Welcome new users with a personal message
- Explain why the app was created
- Guide users on how to use it
- Provide a button to proceed to subscription screen

## 📋 Current Flow

**Before:**
1. User signs up (email/password or OAuth)
2. Email verification (if email/password and not verified)
3. **→ SubscriptionBenefitsView** (shows immediately)
4. HomeView

**After:**
1. User signs up (email/password or OAuth)
2. Email verification (if email/password and not verified)
3. **→ OnboardingView** (NEW - personal message)
4. SubscriptionBenefitsView
5. HomeView

## 🎨 Design Requirements

### Message Content

**From:** Arjay McCandless

**Message:**
> "Now more than ever, system design is an important part of the interview process. It's important for developers of all skill levels to hone their knowledge, stay up with the times, and continuously improve. Just take a minute each morning to challenge your knowledge or learn something new."

### Visual Design

- Match app's dark theme (black background, green accents)
- Use card container style (like other views)
- Personal, welcoming tone
- Clean, readable typography
- Button to proceed to subscription

## 🏗️ Implementation Steps

### Step 1: Create OnboardingView

**File:** `TheDailyDev/OnboardingView.swift`

**Features:**
- Personal message from Arjay McCandless
- Styled to match app theme
- "Get Started" or "Continue" button
- Optional: Skip button (if needed)

**Layout:**
- Card container with message
- Author signature at bottom
- Primary button to proceed
- Optional secondary button to skip

### Step 2: Update SignUpView

**Changes:**
- Add `@State private var showingOnboarding = false`
- After successful sign-up (and email verification if needed), show onboarding instead of subscription
- Onboarding completion → show subscription screen

**Flow:**
```swift
// After sign-up success:
showingOnboarding = true  // NEW
// After onboarding:
showingOnboarding = false
showingSubscriptionBenefits = true
```

### Step 3: Update OAuth Flow

**Changes:**
- OAuth sign-in (Google/GitHub) should also show onboarding
- Add onboarding state to OAuth handlers
- Show onboarding before setting `isLoggedIn = true`

### Step 4: Handle First-Time vs Returning Users

**Consideration:**
- Should onboarding only show once per user?
- Store `has_seen_onboarding` flag in database?
- Or show every time (simpler for now)?

**Recommendation:** Show every time for now (can add flag later if needed)

## 📝 Code Structure

### OnboardingView.swift

```swift
struct OnboardingView: View {
    let onContinue: () -> Void
    
    var body: some View {
        // Card with message
        // Author signature
        // Continue button
    }
}
```

### SignUpView Updates

```swift
@State private var showingOnboarding = false

// After sign-up:
showingOnboarding = true

// In body:
.sheet(isPresented: $showingOnboarding) {
    OnboardingView(onContinue: {
        showingOnboarding = false
        showingSubscriptionBenefits = true
    })
}
```

## 🎯 User Experience Flow

1. **User signs up** → Email verification (if needed)
2. **Onboarding appears** → Personal message from Arjay
3. **User clicks "Get Started"** → Subscription screen appears
4. **User subscribes or skips** → HomeView

## ✅ Implementation Checklist

- [ ] Create `OnboardingView.swift`
- [ ] Style message card to match app theme
- [ ] Add author signature (Arjay McCandless)
- [ ] Add "Get Started" button
- [ ] Update `SignUpView` to show onboarding after sign-up
- [ ] Update email verification flow to show onboarding
- [ ] Update OAuth flows (Google/GitHub) to show onboarding
- [ ] Test email/password sign-up flow
- [ ] Test OAuth sign-up flow
- [ ] Verify styling matches app design
- [ ] Test button navigation

## 🎨 Design Mockup

```
┌─────────────────────────────────┐
│                                   │
│   [Card Container]                │
│                                   │
│   Welcome to The Daily Dev        │
│                                   │
│   Now more than ever, system       │
│   design is an important part      │
│   of the interview process...     │
│                                   │
│   [Message text]                  │
│                                   │
│   — Arjay McCandless              │
│                                   │
│   [Get Started Button]            │
│                                   │
└─────────────────────────────────┘
```

## 🔄 Edge Cases

1. **User closes onboarding?**
   - Should they be able to skip?
   - Or force them to see it?

2. **User already saw onboarding?**
   - Should we track this?
   - For now: show every time

3. **OAuth users?**
   - They skip email verification
   - Should go: OAuth → Onboarding → Subscription

## 📱 Testing Plan

1. **Email/Password Sign-Up:**
   - Sign up → Email verification → Onboarding → Subscription

2. **OAuth Sign-Up:**
   - Google/GitHub → Onboarding → Subscription

3. **Button Actions:**
   - "Get Started" → Shows subscription screen
   - Verify navigation works correctly

4. **Styling:**
   - Matches app theme
   - Readable on dark background
   - Proper spacing and typography

---

## 🚀 Ready to Implement

This plan provides a clear path to add the onboarding step. The implementation is straightforward:
1. Create the view
2. Update sign-up flow
3. Test both email and OAuth flows

Let's proceed with implementation!

