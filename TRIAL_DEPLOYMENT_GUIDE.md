a# Free Trial Subscription Flow - Deployment Guide

## Overview

This guide walks you through deploying the new subscription flow that includes:
- **First free question** for all new users
- **Free Friday access** for all users
- **7-day credit card-gated trial** with automatic billing

## What We've Implemented

### iOS App Changes ✅
1. ✅ Updated `SubscriptionModels.swift` with `trialEnd` and `isInTrial` logic
2. ✅ Added `hasAnsweredAnyQuestion()` to `QuestionService.swift`
3. ✅ Updated `SubscriptionService.swift` with trial methods and access control
4. ✅ Created `FirstQuestionCompleteView.swift` for post-question popup
5. ✅ Updated `HomeView.swift` with new access logic and UI states
6. ✅ Added deep link handling for `thedailydev://trial-started` in `TheDailyDevApp.swift`

### Backend Changes ✅
1. ✅ Database: Added `trial_end` column to `user_subscriptions`
2. ✅ Created 3 new Edge Functions (need deployment)

## Step 1: Database Migration

Run this SQL in your Supabase SQL Editor:

```sql
-- Add trial_end column to user_subscriptions
ALTER TABLE user_subscriptions
ADD COLUMN IF NOT EXISTS trial_end TIMESTAMP WITH TIME ZONE;
```

**Status: ✅ Already completed by you**

## Step 2: Deploy Edge Functions

### Prerequisites
- Supabase CLI installed
- Logged in to Supabase CLI (`supabase login`)
- Project linked (`supabase link --project-ref YOUR_PROJECT_REF`)

### Deploy Functions

From your project root:

```bash
# Deploy initiate-trial function
supabase functions deploy initiate-trial

# Deploy complete-trial-setup function
supabase functions deploy complete-trial-setup

# Deploy stripe-webhook function
supabase functions deploy stripe-webhook
```

## Step 3: Configure Stripe Webhook

### 3.1 Get Your Webhook Endpoint URL

Your webhook URL will be:
```
https://YOUR_PROJECT_REF.supabase.co/functions/v1/stripe-webhook
```

### 3.2 Create Webhook in Stripe Dashboard

1. Go to https://dashboard.stripe.com/webhooks
2. Click "Add endpoint"
3. Enter your webhook URL (from above)
4. Select the following events to listen for:
   - `customer.subscription.created`
   - `customer.subscription.updated`
   - `customer.subscription.deleted`
   - `customer.subscription.trial_will_end`
   - `invoice.payment_succeeded`
   - `invoice.payment_failed`
5. Click "Add endpoint"

### 3.3 Get Webhook Signing Secret

1. After creating the webhook, click on it
2. Click "Reveal" under "Signing secret"
3. Copy the secret (starts with `whsec_...`)

### 3.4 Add Webhook Secret to Supabase

In your Supabase dashboard:

1. Go to **Project Settings** → **Edge Functions** → **Secrets**
2. Add a new secret:
   - Name: `STRIPE_WEBHOOK_SECRET`
   - Value: Your webhook signing secret from Stripe

## Step 4: Configure Function Secrets

Make sure these secrets are set in Supabase:

```bash
# Set secrets (or use Supabase dashboard)
supabase secrets set STRIPE_SECRET_KEY=sk_...
supabase secrets set STRIPE_WEBHOOK_SECRET=whsec_...
supabase secrets set SUPABASE_SERVICE_ROLE_KEY=your_service_role_key
supabase secrets set SUPABASE_URL=https://your-project.supabase.co
```

## Step 5: Update Config.swift (If Needed)

Make sure your `Config.swift` includes the new function names:

```swift
static func getFunctionURL(functionName: String) -> URL? {
    let baseURL = supabaseURL.replacingOccurrences(of: "/rest/v1", with: "")
    return URL(string: "\(baseURL)/functions/v1/\(functionName)")
}
```

Valid function names:
- `initiate-trial`
- `complete-trial-setup`
- `create-checkout-session`
- `cancel-subscription`
- `get-billing-portal-url`

## Step 6: Testing the Flow

### Test 1: First Free Question
1. Create a new test account (or use existing non-subscriber)
2. Sign in to the app
3. You should see "Answer Your First Free Question" button
4. Answer the question
5. After submission, `FirstQuestionCompleteView` popup should appear
6. Click "Maybe Later" to dismiss

### Test 2: Free Friday Access
1. Sign in as a non-subscriber on a Friday
2. You should see "🎉 Free Friday Question!" message
3. You can answer the question without subscription
4. On other days, you should see "Start Your Free Trial" button

### Test 3: Trial Signup Flow
1. After answering first question, click "Start 7-Day Free Trial" in popup
2. OR click "Start Free Trial" button on Home screen
3. Safari should open with Stripe Checkout in setup mode
4. Enter test card: `4242 4242 4242 4242`, any future date, any CVC
5. Complete the payment method setup
6. You should be redirected back to the app
7. Check that your subscription status shows "Free trial until [date]"

### Test 4: Trial Conversion (Requires Waiting or Stripe CLI)

**Option A: Use Stripe CLI to simulate trial end**
```bash
stripe trigger customer.subscription.updated --add subscription:status=active
```

**Option B: Change trial period in code for testing**
In `complete-trial-setup/index.ts`, temporarily change:
```typescript
// Original: 7 days
const trialEndTimestamp = Math.floor(Date.now() / 1000) + (7 * 24 * 60 * 60)

// For testing: 1 minute
const trialEndTimestamp = Math.floor(Date.now() / 1000) + 60
```

### Test 5: Cancellation
1. While in trial, go to Settings → Subscription
2. Click "Manage Subscription"
3. Cancel the subscription
4. Verify status updates to "Subscription required"
5. Friday access should still work

## Step 7: Stripe Test Cards

Use these test cards for different scenarios:

- **Success**: `4242 4242 4242 4242`
- **Payment fails after trial**: `4000 0000 0000 9995`
- **3D Secure required**: `4000 0025 0000 3155`

## Access Control Logic Summary

Users can access questions if ANY of these are true:

1. ✅ **Active subscription** (`status == "active"`)
2. ✅ **Active trial** (`status == "trialing"` AND `trial_end > now()`)
3. ✅ **First free question** (no questions answered before)
4. ✅ **Friday** (weekday == 6, regardless of subscription)

## User Journey Examples

### New User
1. Signs up → Can answer 1 free question
2. After answering → Sees trial popup
3. Starts trial → Gets 7 days free
4. After 7 days → Auto-charged $8/month

### Returning Non-Subscriber
1. Signs in on Monday → Sees "Start Free Trial" button
2. Signs in on Friday → Can answer question for free
3. Never subscribes → Can only answer on Fridays

### Trial User
1. In trial → Can answer daily questions
2. Shows "Free trial until [date]" message
3. After trial ends → Auto-converted to paid
4. Can cancel anytime before trial ends

## Troubleshooting

### Issue: Webhook not receiving events
- Check webhook URL is correct
- Verify webhook secret is set in Supabase
- Check Stripe webhook logs for errors
- Make sure function is deployed

### Issue: Trial not starting after payment setup
- Check browser console/Xcode logs for deep link errors
- Verify `thedailydev://` URL scheme is configured
- Check `complete-trial-setup` function logs in Supabase

### Issue: Access denied after trial starts
- Check `user_subscriptions` table for correct `status` and `trial_end`
- Verify `canAccessQuestions()` logic in SubscriptionService
- Check that subscription status was fetched on app launch

### Issue: FirstQuestionCompleteView not showing
- Verify `hasAnsweredAnyQuestion()` returns false before first question
- Check `showingFirstQuestionComplete` state in HomeView
- Ensure QuestionView properly updates `hasAnsweredToday`

## Monitoring

### Key Metrics to Track
1. **Conversion Rate**: First question → Trial signup
2. **Trial Completion Rate**: Trials that convert to paid
3. **Friday Engagement**: Free Friday question answers
4. **Churn Rate**: Cancellations during/after trial

### Supabase Queries

```sql
-- Count users in trial
SELECT COUNT(*) 
FROM user_subscriptions 
WHERE status = 'trialing';

-- Count users with first free question available
SELECT COUNT(DISTINCT us.user_id)
FROM user_subscriptions us
LEFT JOIN user_progress up ON us.user_id = up.user_id
WHERE up.user_id IS NULL;

-- Trial conversion rate
SELECT 
  COUNT(CASE WHEN status = 'trialing' THEN 1 END) as trials,
  COUNT(CASE WHEN status = 'active' AND trial_end IS NULL THEN 1 END) as active
FROM user_subscriptions;
```

## Next Steps

1. ✅ Database migration (done by you)
2. 🔲 Deploy Edge Functions (supabase functions deploy)
3. 🔲 Configure Stripe webhook
4. 🔲 Test the complete flow
5. 🔲 Monitor metrics and adjust trial period/pricing as needed

## Need Help?

If you encounter issues:
1. Check Supabase Edge Function logs
2. Check Stripe webhook event logs
3. Check Xcode console for iOS errors
4. Verify all environment variables are set correctly

---

**Ready to deploy?** Start with Step 2 and work through each section carefully!

