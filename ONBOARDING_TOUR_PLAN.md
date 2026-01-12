# Onboarding Tour Implementation Plan

## Overview
Create an interactive onboarding tour that guides new users through the app's key features, highlighting where to find daily questions, previous questions, and analytics.

## Goals
- Help users understand the app structure quickly
- Highlight key features: daily questions, question history, analytics
- Make it skippable and non-intrusive
- Remember completion status to avoid showing it repeatedly

## Tour Flow

### Step 1: Home Screen - Daily Questions
**Location**: HomeView
**Highlight**: Main "Start Question" / "Play" button
**Message**: 
- Title: "Daily Questions"
- Body: "New questions are released every day right here on the home screen. Tap the button to start today's challenge!"
- Action: "Next"

### Step 2: Home Screen - Analytics/History Access
**Location**: HomeView (navigation bar)
**Highlight**: Analytics/History button (graph icon) in navigation bar
**Message**:
- Title: "Your Analytics & History"
- Body: "Tap the analytics icon in the top right to view your statistics, question history, and performance analytics."
- Action: "Next"

### Step 3: Analytics Screen - Question History
**Location**: ProfileView (after navigating from analytics icon)
**Highlight**: ContributionsTracker (Question History grid)
**Message**:
- Title: "Question History"
- Body: "View all your past questions here. Tap any square to review questions you've answered or answer ones you missed. Green = correct, red = incorrect, gray = unanswered."
- Action: "Next"

### Step 4: Analytics Screen - Performance Analytics
**Location**: ProfileView
**Highlight**: CategoryPerformanceView (category performance section)
**Message**:
- Title: "Your Performance Analytics"
- Body: "See how you're performing across different system design categories. Track your progress and identify areas to improve!"
- Action: "Got it!"

## Implementation Approach

### Option 1: Custom Overlay System (Recommended)
Create a custom SwiftUI overlay system that:
- Uses a semi-transparent dark overlay to dim the background
- Highlights specific UI elements with a spotlight effect
- Shows tooltip-style messages with arrows pointing to elements
- Supports navigation between steps
- Stores completion status in UserDefaults

**Pros**:
- Full control over design and behavior
- No external dependencies
- Lightweight and performant
- Matches app's design system

**Cons**:
- Requires custom implementation
- Need to handle view hierarchy and positioning

### Option 2: Third-Party Library
Use a library like `Introspect` or `OnboardingKit` for SwiftUI.

**Pros**:
- Pre-built solution
- Less code to maintain

**Cons**:
- External dependency
- May not match app design perfectly
- Less customization

## Technical Implementation

### 1. Create OnboardingTourManager
**File**: `TheDailyDev/OnboardingTourManager.swift`
- Singleton to manage tour state
- Track current step
- Store completion status
- Handle navigation between steps

### 2. Create TourOverlayView
**File**: `TheDailyDev/TourOverlayView.swift`
- Semi-transparent dark background
- Spotlight effect for highlighted elements
- Tooltip with message and arrow
- Next/Skip buttons

### 3. Create TourStep Model
**File**: `TheDailyDev/TourStep.swift`
- Define tour steps with:
  - Step ID
  - Title and message
  - Target view identifier
  - Highlight frame/position
  - Arrow direction

### 4. Add View Identifiers
Add `.accessibilityIdentifier()` or `.id()` to key UI elements:
- HomeView: Main question button
- HomeView: Analytics/History navigation button (graph icon)
- HomeView: Settings button (gear icon)
- ProfileView: ContributionsTracker section
- ProfileView: CategoryPerformanceView section

### 5. Integration Points

#### HomeView
- Check if tour should start after onboarding completes
- Show tour overlay when active
- Highlight question button (Step 1)
- Highlight analytics/history button (Step 2)
- Add settings button in navigation bar (gear icon)
- Move settings access from ProfileView to HomeView

#### ProfileView
- Show tour overlay when navigated from tour
- Highlight ContributionsTracker (Step 3)
- Highlight CategoryPerformanceView (Step 4)
- Remove settings button (moved to HomeView)

#### OnboardingView
- After "Get Started" is tapped, trigger tour instead of going directly to subscription
- Or show tour after subscription screen (if skipped)

## User Experience Flow

1. User signs up → Email verification (if needed)
2. OnboardingView shows personal message
3. User taps "Get Started"
4. **Tour starts automatically** (or after subscription if they subscribe)
5. Step 1: Highlights daily question button on HomeView
6. User taps "Next" → Step 2: Highlights profile button
7. User taps "Next" → Navigates to ProfileView, Step 3: Highlights question history
8. User taps "Next" → Step 4: Highlights analytics
9. User taps "Got it!" → Tour completes, stored in UserDefaults

## Tour Features

### Skip Functionality
- "Skip Tour" button on every step
- Immediately completes tour and stores status

### Progress Indicator
- Show "Step 1 of 4" at bottom of tooltip
- Visual progress dots

### Smart Navigation
- Automatically navigate to ProfileView when needed
- Return to HomeView after tour completes

### Completion Tracking
- Store in UserDefaults: `hasCompletedOnboardingTour = true`
- Check on app launch - only show if not completed
- Option to reset for testing (debug menu or settings)

## Design Specifications

### Overlay
- Background: Black with 0.7 opacity
- Spotlight: Circular cutout with blur effect
- Border: Green glow around spotlight (Theme.Colors.accentGreen)

### Tooltip
- Background: Dark card matching app theme
- Border: Green accent color
- Arrow: Points to highlighted element
- Typography: Match app's font system
- Buttons: Primary button style for "Next", secondary for "Skip"

### Highlight Effect
- Pulse animation on highlighted element
- Subtle scale animation (1.0 → 1.05 → 1.0)
- Green border glow

## Analytics Integration (PostHog)

Track tour events in PostHog:
- `onboarding_tour_started` - When tour begins
- `onboarding_tour_step_viewed` - For each step (properties: `step_number`, `step_name`)
- `onboarding_tour_step_completed` - When user taps "Next" on a step (properties: `step_number`, `step_name`)
- `onboarding_tour_skipped` - When user skips tour (properties: `step_number` where skipped)
- `onboarding_tour_completed` - When user finishes all steps

All events should include:
- `user_id` - Current user ID
- `timestamp` - Event timestamp
- `session_id` - Session identifier

## Edge Cases

1. **User navigates away during tour**
   - Pause tour state
   - Resume when returning to relevant screen
   - Or cancel tour if user navigates to unrelated screen

2. **User already completed tour**
   - Check UserDefaults on app launch
   - Skip tour automatically

3. **Tour on different screen sizes**
   - Ensure tooltip positioning works on all devices
   - Test on iPhone SE, iPhone 15, iPhone 15 Pro Max

4. **User subscribes during tour**
   - Continue tour normally
   - Analytics section will be visible for subscribers

## Testing Checklist

- [ ] Tour starts after onboarding
- [ ] All 4 steps display correctly
- [ ] Navigation between steps works
- [ ] Skip functionality works
- [ ] Completion status is saved
- [ ] Tour doesn't show again after completion
- [ ] Works on different screen sizes
- [ ] Analytics events are tracked
- [ ] Tour works for both subscribers and non-subscribers
- [ ] Tour can be reset for testing

## Files to Create/Modify

### New Files
1. `TheDailyDev/OnboardingTourManager.swift` - Tour state management
2. `TheDailyDev/TourOverlayView.swift` - Overlay UI component
3. `TheDailyDev/TourStep.swift` - Tour step data model

### Modified Files
1. `TheDailyDev/OnboardingView.swift` - Trigger tour after "Get Started"
2. `TheDailyDev/HomeView.swift` - Add tour overlay, view identifiers, add settings button, change profile icon to graph icon
3. `TheDailyDev/ProfileView.swift` - Add tour overlay, view identifiers, remove settings button
4. `TheDailyDev/ContentView.swift` - Check tour completion status on launch

## UI Changes

### Icon Updates
- **Profile Icon**: Change from `person` to `chart.bar.fill` or `chart.line.uptrend.xyaxis` (graph/analytics icon)
- **Settings Icon**: Add `gearshape.fill` to HomeView navigation bar

### Navigation Changes
- **Settings Access**: Move from ProfileView to HomeView navigation bar
- **ProfileView Purpose**: Rename/reposition as "Analytics & History" view
- **Icon Semantics**: Analytics icon should clearly indicate it's for viewing stats/history

## Implementation Order

1. **UI Refactoring**:
   - Change profile icon to graph/analytics icon in HomeView
   - Add settings button to HomeView navigation bar
   - Remove settings button from ProfileView
   - Update navigation semantics

2. **Tour Infrastructure**:
   - Create TourStep model
   - Create OnboardingTourManager
   - Create TourOverlayView component

3. **Tour Integration**:
   - Add view identifiers to key elements
   - Integrate tour into HomeView
   - Integrate tour into ProfileView
   - Connect tour to OnboardingView flow

4. **Tracking & Completion**:
   - Add PostHog analytics events
   - Add completion tracking
   - Test on multiple devices

## Future Enhancements (Post-MVP)

- Interactive elements: Let users tap highlighted areas to proceed
- Animation improvements: Smooth transitions between steps
- Contextual help: Show tour again from settings
- Tutorial mode: More detailed explanations for power users
- Video walkthrough option: For users who prefer video

