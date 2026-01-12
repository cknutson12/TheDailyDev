# How to Verify PostHog is Working

## Quick Verification Steps

### 1. Check Console Logs in Xcode

When you run the app, you should see these logs in the Xcode console:

```
✅ PostHog initialized with API key: phc_z3xomL...
🔍 PostHog debug mode enabled
🔄 PostHog events flushed (debug mode)
📊 Tracked event: app_open
```

If you see these logs, PostHog is initialized correctly.

### 2. Check PostHog Dashboard

1. **Log in to PostHog**: Go to [https://posthog.com](https://posthog.com) and log in
2. **Navigate to Events**: Click on "Events" in the left sidebar
3. **Look for Your Events**: You should see events like:
   - `app_open` - When the app launches
   - `screen_view` - When screens are viewed
   - `sign_up_completed` - When users sign up
   - `question_answered` - When questions are answered
   - And many more...

**Note**: Events may take a few seconds to appear. In production, events are batched and sent every 30 seconds or when the app goes to background. In DEBUG mode, events are flushed immediately.

### 3. Real-Time Event Testing

To test if events are being sent:

1. **Run the app** in Xcode
2. **Perform actions** in the app:
   - Open the app (should trigger `app_open`)
   - Sign in (should trigger `user_signed_in`)
   - View a question (should trigger `question_viewed`)
   - Answer a question (should trigger `question_answered`)
3. **Check PostHog Dashboard**: Go to "Events" and look for these events
4. **Use the search bar**: Type the event name (e.g., "app_open") to filter

### 4. Check PostHog Live Events (Real-Time)

PostHog has a "Live Events" feature that shows events in real-time:

1. Go to your PostHog dashboard
2. Look for "Live Events" or "Activity" in the sidebar
3. You should see events appearing as they happen in your app

### 5. Verify API Key

If events aren't appearing:

1. **Check the API key** in `Config-Secrets.plist`:
   - Key should be: `POSTHOG_API_KEY`
   - Value should start with: `phc_`
   - Make sure there are no extra spaces

2. **Check console logs** for errors:
   - If you see: `⚠️ PostHog API key is empty` - the key is missing
   - If you see: `⚠️ POSTHOG_API_KEY not found` - the key name is wrong

### 6. Check Network Connection

PostHog requires an internet connection to send events. Make sure:
- Your simulator/device has internet access
- No firewall is blocking requests to PostHog servers
- The app has network permissions

### 7. Check PostHog Project Settings

1. **Verify you're in the correct project** in PostHog dashboard
2. **Check the API key** matches what's in your `Config-Secrets.plist`:
   - Go to Project Settings → Project API Key
   - Compare with your `POSTHOG_API_KEY` in `Config-Secrets.plist`
3. **Check project status**: Make sure the project is active

### 8. Debug Mode

Debug mode is automatically enabled in DEBUG builds. This means:
- Events are flushed immediately (sent right away, not batched)
- More detailed logging is available
- You can see network requests in Xcode console

If you want to see network requests:
1. In Xcode, open the Debug Navigator (⌘7)
2. Look for network activity when events are tracked
3. You should see HTTP requests to PostHog's servers

### 9. Test with a Simple Event

To manually test PostHog:

1. **Add a test button** in your app (temporarily)
2. **Track an event** when the button is tapped:
   ```swift
   AnalyticsService.shared.track("test_event", properties: ["test": "value"])
   ```
3. **Tap the button** in the app
4. **Check PostHog dashboard** for the `test_event`

### 10. Common Issues and Solutions

#### Events Not Appearing

**Possible causes:**
- API key is incorrect or missing
- Network connection issues
- PostHog project is paused or inactive
- Events are being filtered out in PostHog dashboard

**Solutions:**
1. Verify API key is correct
2. Check console logs for errors
3. Check network connectivity
4. Verify PostHog project is active

#### "PostHog API key is empty" Error

**Cause:** The API key is not found in `Config-Secrets.plist`

**Solution:**
1. Open `Config-Secrets.plist`
2. Add `POSTHOG_API_KEY` key (exact name, case-sensitive)
3. Set value to your PostHog API key (starts with `phc_`)
4. Rebuild the app

#### Events Appearing with Delay

**Cause:** This is normal! PostHog batches events for efficiency.

**Solution:**
- In DEBUG builds, events are flushed immediately
- In production, events are sent every 30 seconds or when the app goes to background
- If you need immediate events, they're already flushed in DEBUG mode

## Expected Events in The Daily Dev

Here are the events that should be tracked in the app:

### App Lifecycle
- `app_open` - App launches
- `app_foreground` - App comes to foreground
- `app_background` - App goes to background

### Authentication
- `sign_up_started` - User begins sign-up
- `sign_up_completed` - User completes sign-up
- `user_signed_in` - User signs in
- `user_signed_out` - User signs out
- `sign_in_failed` - Sign-in fails

### Onboarding
- `onboarding_viewed` - Onboarding screen appears
- `onboarding_completed` - User completes onboarding
- `onboarding_tour_started` - Tour begins
- `onboarding_tour_completed` - Tour completes

### Questions
- `question_viewed` - Question is viewed
- `question_answered` - Question is answered
- `question_correct` - Answer is correct
- `question_incorrect` - Answer is incorrect
- `first_question_answered` - First question answered

### Subscriptions
- `paywall_viewed` - Paywall appears
- `subscription_purchase_started` - Purchase begins
- `subscription_purchased` - Purchase completes
- `subscription_purchase_failed` - Purchase fails
- `subscription_restored` - Purchase restored

### Screens
- `screen_viewed` - Screen is viewed (with `screen_name` property)

## Next Steps

Once you've verified PostHog is working:

1. **Set up Dashboards**: Create dashboards for key metrics (see `POSTHOG_DASHBOARD_SETUP.md` for detailed instructions)
2. **Create Funnels**: Track user conversion funnels
3. **Set up Alerts**: Get notified of important events
4. **Analyze User Behavior**: Review events to understand user patterns

**Important**: PostHog dashboards don't automatically populate! You need to create insights and add them to dashboards. See `POSTHOG_DASHBOARD_SETUP.md` for step-by-step instructions.

For more help, check:
- [PostHog Documentation](https://posthog.com/docs)
- [PostHog iOS SDK](https://posthog.com/docs/integrate/client/ios)

