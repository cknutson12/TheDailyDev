# The Daily Dev

A premium iOS application designed to help developers enhance their system design knowledge through daily questions and interactive challenges.

![Swift 5.9](https://img.shields.io/badge/Swift-5.9-orange.svg)
![iOS 17.5+](https://img.shields.io/badge/iOS-17.5%2B-blue.svg)
![Xcode 15.0+](https://img.shields.io/badge/Xcode-15.0%2B-blue.svg)

## 📱 Overview

The Daily Dev delivers curated system design questions daily, featuring multiple question types including multiple choice, drag-and-drop matching, and ordering/sequencing challenges. Users can track their progress with GitHub-style contribution graphs, view detailed statistics, and maintain learning streaks.

## ✨ Features

- **Daily System Design Questions**: Curated challenges covering various system design topics
- **Multiple Question Types**:
  - Multiple Choice Questions
  - Drag-and-Drop Matching
  - Ordering/Sequencing
- **Progress Tracking**: GitHub-style contribution graphs showing your answer history
- **Category Performance**: Detailed analytics by topic category
- **Streak System**: Maintain daily learning streaks with visual indicators
- **Subscription Management**: RevenueCat-powered subscription system with native iOS in-app purchases
- **OAuth Authentication**: Sign in with Google, GitHub, or email/password
- **Email Verification & Password Reset**: Full authentication flow with custom SMTP (Resend)
- **Dark Theme**: Modern dark UI with green accents (#37BF84)

## 🏗️ Architecture

### Tech Stack

- **Frontend**: SwiftUI (iOS 17.5+)
- **Backend**: Supabase (PostgreSQL, Auth, Storage, Edge Functions)
- **Authentication**: Supabase Auth with OAuth (Google, GitHub) and Email/Password
- **Payments**: RevenueCat (native iOS in-app purchases via StoreKit)
- **Email Service**: Resend (custom SMTP)

### Design Pattern

The application follows the MVVM (Model-View-ViewModel) architecture with a service-oriented approach:

- **Views**: SwiftUI views for UI presentation
- **Services**: Singleton services for business logic and API communication
- **Models**: Data structures conforming to `Codable` for Supabase integration
- **Managers**: Centralized managers for auth, database, and subscriptions

## 📂 Project Structure

### Views

#### Authentication & Onboarding
- **`ContentView.swift`**: Root view handling authentication state and routing
- **`LoginView.swift`**: Email/password and OAuth sign-in
- **`SignUpView.swift`**: User registration with name capture
- **`EmailVerificationView.swift`**: Email verification prompt and retry flow
- **`ForgotPasswordView.swift`**: Password reset email request
- **`ResetPasswordView.swift`**: New password entry after reset link

#### Main Application
- **`HomeView.swift`**: Main dashboard with daily question prompt and streak display
- **`ProfileView.swift`**: User statistics, contribution graph, and settings access
- **`QuestionView.swift`** (in `HomeView.swift`): Modal view for answering questions

#### Question Types
- **`MultipleChoiceQuestionView.swift`**: Standard multiple choice format
- **`MatchingQuestionView.swift`**: Drag-and-drop matching interface
- **`OrderingQuestionView.swift`**: Reorderable list for sequencing questions
- **`QuestionImageView.swift`**: Shared component for displaying question images
- **`QuestionReviewView.swift`** (in `ContributionsTracker.swift`): Review past answers

#### Subscription & Monetization
- **`SubscriptionBenefitsView.swift`**: Feature showcase and upgrade prompt
- **`SubscriptionSettingsView.swift`**: Subscription management (cancel, billing portal)

#### Analytics & Visualization
- **`ContributionsTracker.swift`**: GitHub-style contribution graph (52 weeks)
- **`CategoryPerformanceView.swift`**: Performance breakdown by category

#### Supporting UI Components
- **`DraggableItemCard.swift`**: Reusable draggable card for matching questions
- **`DropZoneView.swift`**: Drop target for drag-and-drop interactions
- **`AdaptiveText.swift`**: Text component with dynamic sizing

### Services & Managers

- **`SupabaseManager.swift`**: Singleton managing Supabase client initialization and auth helpers
- **`AuthManager.swift`**: Centralized authentication state management and OAuth handling
- **`QuestionService.swift`**: Question fetching, answer submission, and progress tracking
- **`SubscriptionService.swift`**: RevenueCat subscription management, status checking, and billing portal
- **`RevenueCatSubscriptionProvider.swift`**: RevenueCat SDK integration and purchase handling
- **`RevenueCatPaywallView.swift`**: Native RevenueCat paywall UI
- **`ImageHelper.swift`**: Image caching and display utilities

### Models

- **`Question.swift`**: Question data structure with support for multiple types
- **`SubscriptionModels.swift`**: User subscription, checkout, and billing models

### Configuration & Theme

- **`TheDailyDevApp.swift`**: App entry point with deep link handling
- **`Theme.swift`**: Centralized theme tokens (colors, fonts, metrics)
- **`Config-Secrets.plist`**: Supabase credentials (gitignored)

## 🔧 Backend Integration

### Supabase Setup

#### Database Schema

**`questions` table**:
```sql
- id (uuid, primary key)
- question_text (text)
- category (text)
- difficulty (text: easy, medium, hard)
- question_type (text: multiple_choice, matching, ordering)
- options (jsonb) -- Array of strings for multiple choice
- correct_answer (text) -- Index or comma-separated indices
- explanation (text)
- image_url (text, nullable)
- matching_items (jsonb, nullable) -- Array of {term, definition}
- ordering_items (jsonb, nullable) -- Array of {text, correctIndex}
- created_at (timestamp)
```

**`user_progress` table**:
```sql
- id (uuid, primary key)
- user_id (uuid, foreign key to auth.users)
- question_id (uuid, foreign key to questions)
- is_correct (boolean)
- selected_answer (text)
- completed_at (timestamp)
- created_at (timestamp)
```

**`user_subscriptions` table**:
```sql
- id (uuid, primary key)
- user_id (uuid, foreign key to auth.users)
- revenuecat_user_id (text, nullable)
- revenuecat_subscription_id (text, nullable)
- entitlement_status (text: active, expired, billing_issue, paused)
- original_transaction_id (text, nullable)
- status (text: active, trialing, inactive, past_due, paused)
- current_period_end (timestamp, nullable)
- trial_end (timestamp, nullable)
- first_name (text, nullable)
- last_name (text, nullable)
- created_at (timestamp)
- updated_at (timestamp)
```

#### Row Level Security (RLS)

All tables have RLS enabled with policies:
- Users can only read/write their own progress
- Questions are readable by authenticated users
- Subscriptions are only accessible by the subscription owner

#### Storage

**`question-images` bucket**:
- Public read access
- Stores question images
- Images referenced via `image_url` in questions table

### Supabase Edge Functions

**`revenuecat-webhook`**:
- Handles RevenueCat webhook events
- Updates `user_subscriptions` table
- Processes: `INITIAL_PURCHASE`, `RENEWAL`, `CANCELLATION`, `BILLING_ISSUE`, `SUBSCRIPTION_PAUSED`, `EXPIRATION`, etc.
- Requires `REVENUECAT_WEBHOOK_SECRET` environment variable

### Authentication

**Providers**:
- Email/Password (with email verification)
- Google OAuth
- GitHub OAuth

**Deep Links**:
- OAuth callback: `com.supabase.thedailydev://oauth-callback`
- Email confirmation: `thedailydev://email-confirm`
- Password reset: `thedailydev://password-reset`

**SMTP Configuration**:
- Custom SMTP via Resend
- Email verification required for new accounts
- Password reset emails via deep links

### RevenueCat Integration

**Products** (configured in App Store Connect):
- Monthly subscription
- Yearly subscription

**Entitlements**:
- `The Daily Dev Pro` - Main subscription entitlement

**Webhooks**:
- Endpoint: Your Supabase Edge Function URL (`revenuecat-webhook`)
- Authorization: Bearer token via `REVENUECAT_WEBHOOK_SECRET`
- Events: All subscription lifecycle events

**Setup**:
- See `REVENUECAT_SETUP.md` for detailed setup instructions
- See `SETUP_STEPS.md` for step-by-step guide

## 🚀 Setup Instructions

### Prerequisites

- macOS 13.0+
- Xcode 15.0+
- iOS 17.5+ device or simulator
- Supabase account
- RevenueCat account
- Apple Developer account (for App Store Connect)
- Resend account (for custom SMTP)

### 1. Clone the Repository

```bash
git clone <repository-url>
cd TheDailyDev
```

### 2. Configure Supabase

1. Create a new Supabase project
2. Run the database migrations (see SQL files in project root)
3. Set up Row Level Security policies
4. Create the `question-images` storage bucket
5. Configure authentication providers:
   - Enable Email/Password
   - Enable Google OAuth (add client ID/secret)
   - Enable GitHub OAuth (add client ID/secret)
6. Configure custom SMTP with Resend:
   - Go to Authentication → Email Templates
   - Add SMTP credentials from Resend
7. Add redirect URLs in Authentication → URL Configuration:
   - `com.supabase.thedailydev://oauth-callback`
   - `thedailydev://email-confirm`
   - `thedailydev://password-reset`

### 3. Configure RevenueCat

1. Create a RevenueCat account
2. Create products in App Store Connect (monthly and yearly)
3. Create entitlement: `The Daily Dev Pro`
4. Create offerings and packages in RevenueCat dashboard
5. Deploy Supabase Edge Function: `supabase/functions/revenuecat-webhook/`
6. Set up webhook in RevenueCat dashboard pointing to your Edge Function
7. Configure webhook secret in Supabase Edge Function secrets
8. See `REVENUECAT_SETUP.md` and `SETUP_STEPS.md` for detailed instructions

### 4. Configure Xcode Project

1. Open `TheDailyDev.xcodeproj` in Xcode
2. Create `Config-Secrets.plist` in the project root:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>SUPABASE_URL</key>
    <string>https://your-project.supabase.co</string>
    <key>SUPABASE_ANON_KEY</key>
    <string>your-anon-key</string>
    <key>REVENUECAT_API_KEY</key>
    <string>your-revenuecat-api-key</string>
</dict>
</plist>
```

3. Add URL schemes in Xcode:
   - Target → Info → URL Types
   - Add `thedailydev`
   - Add `com.supabase.thedailydev`

4. Update bundle identifier if needed

5. Add OAuth logos:
   - Add `google-logo` to Assets.xcassets
   - Add `github-logo` to Assets.xcassets

### 5. Install Dependencies

The project uses Swift Package Manager. Dependencies will be resolved automatically:
- Supabase-Swift
- RevenueCat iOS SDK (`https://github.com/RevenueCat/purchases-ios-spm.git`)
- HTTPTypes

### 6. Build & Run

1. Select a simulator or device
2. Press `Cmd + R` to build and run
3. Sign up with test credentials or OAuth

## 🧪 Testing

### Manual Testing Checklist

- [ ] Sign up with email/password
- [ ] Verify email
- [ ] Sign in with Google OAuth
- [ ] Sign in with GitHub OAuth
- [ ] Answer a multiple choice question
- [ ] Answer a matching question
- [ ] Answer an ordering question
- [ ] View contribution graph
- [ ] Check streak counter
- [ ] Subscribe via RevenueCat paywall
- [ ] View subscription details
- [ ] Manage subscription via App Store
- [ ] Forgot password flow
- [ ] Reset password flow

### Test Accounts

Use RevenueCat test mode with StoreKit test environment. See `LOCAL_TESTING_PLAN.md` for testing instructions.

## 📝 Contributing

**NOTICE**: This project is under a restrictive license. Contributions are only accepted under the following terms:

### Contribution Process

1. **Fork the repository** (if permitted by license)
2. **Create a feature branch**: `git checkout -b feature/amazing-feature`
3. **Make your changes** following the code style guidelines below
4. **Test thoroughly** using the manual testing checklist
5. **Commit your changes**: `git commit -m 'Add amazing feature'`
6. **Push to the branch**: `git push origin feature/amazing-feature`
7. **Open a Pull Request** with a detailed description

### Code Style Guidelines

**Swift**:
- Follow Swift API Design Guidelines
- Use SwiftUI best practices
- Prefer `async/await` over completion handlers
- Use `@MainActor` for UI updates
- Document public APIs with DocC comments
- Use `// MARK:` to organize code sections

**Naming Conventions**:
- Views: `PascalCase` ending in `View` (e.g., `HomeView`)
- Services: `PascalCase` ending in `Service` or `Manager` (e.g., `QuestionService`)
- State variables: `camelCase` with clear intent (e.g., `isLoading`, `showingQuestion`)

**File Organization**:
- One view per file
- Group related functionality with `// MARK:`
- Keep files under 500 lines when possible

**Theme**:
- Use `Theme.Colors` for all colors
- Use `Theme.Metrics` for spacing and sizing
- Apply `.preferredColorScheme(.dark)` to root views

**Error Handling**:
- Always handle errors in async functions
- Show user-friendly error messages
- Log errors for debugging with `print("❌ Error: \(error)")`

### Contribution Agreement

By contributing to this project, you agree that:

1. **Copyright Assignment**: All contributions become the sole property of the project owner
2. **License Agreement**: Contributions are subject to the project's restrictive license
3. **No Warranty**: Contributions are provided "as-is" without warranty
4. **Code of Conduct**: Professional and respectful communication is required

### What to Contribute

**Welcomed Contributions**:
- Bug fixes
- Performance improvements
- UI/UX enhancements
- Documentation improvements
- Test coverage
- Accessibility improvements

**Not Accepting**:
- Major architectural changes without prior discussion
- Features that require significant maintenance
- Breaking changes to the API

### Getting Help

- Open an issue for bugs or feature requests
- Use discussions for questions and ideas
- Provide detailed reproduction steps for bugs

## 🔒 Security

### Reporting Security Issues

**DO NOT** open public issues for security vulnerabilities.

Please report security issues privately to the project maintainer.

### Security Best Practices

- Never commit `Config-Secrets.plist`
- Use environment variables for sensitive data
- Rotate API keys regularly
- Enable MFA on all service accounts
- Keep dependencies updated

## 📄 License

**Copyright © 2025 Claire Knutson. All Rights Reserved.**

This software and associated documentation files (the "Software") are proprietary and confidential. Unauthorized copying, modification, distribution, or use of this Software, via any medium, is strictly prohibited.

### Permitted Use

This Software may be:
- Viewed for educational purposes
- Forked for personal learning (not for production use)
- Modified with explicit written permission from the copyright holder

### Restrictions

You MAY NOT:
- Use this Software for commercial purposes
- Distribute or publish this Software or derivatives
- Remove copyright or attribution notices
- Sublicense or sell copies of this Software
- Use the Software's name, logo, or trademarks without permission

### Contributions

Any contributions made to this project become the exclusive property of the copyright holder. By submitting a pull request, you assign all rights, title, and interest in your contribution to the copyright holder.

### Disclaimer

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE COPYRIGHT HOLDER BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

### Contact

For licensing inquiries or permission requests, please contact: [Your Contact Information]

---

## 🙏 Acknowledgments

- **Supabase**: Backend-as-a-Service platform
- **RevenueCat**: Subscription management and analytics
- **Resend**: Email delivery service
- **Swift Community**: For excellent tooling and libraries

## 📞 Support

For issues, questions, or feature requests, please open an issue on the repository.

---

**Built with ❤️ for developers who love system design**

