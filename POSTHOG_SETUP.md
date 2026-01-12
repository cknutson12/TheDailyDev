# PostHog Setup Instructions

## Overview
This guide will walk you through creating a PostHog account and obtaining your API key for analytics tracking in The Daily Dev app.

## Step 1: Create a PostHog Account

1. **Visit PostHog**
   - Go to [https://posthog.com](https://posthog.com)
   - Click **"Get Started"** or **"Sign Up"**

2. **Choose Your Plan**
   - PostHog offers a **free tier** with 1 million events per month
   - For testing and initial launch, the free tier is sufficient
   - You can upgrade later if needed

3. **Sign Up**
   - You can sign up with:
     - Email and password
     - Google account
     - GitHub account
   - Choose whichever is most convenient

4. **Verify Your Email**
   - Check your email for a verification link
   - Click the link to verify your account

## Step 2: Create a Project

1. **After Signing In**
   - PostHog will prompt you to create your first project
   - If not, click **"New Project"** in the dashboard

2. **Project Details**
   - **Project Name**: Enter "The Daily Dev" (or any name you prefer)
   - **Project Type**: Select **"Mobile App"** or **"Web App"** (both work for iOS)
   - Click **"Create Project"**

## Step 3: Get Your API Key

1. **Navigate to Project Settings**
   - In your PostHog dashboard, click on your project name (top left)
   - Go to **"Project Settings"** or click the gear icon

2. **Find Your API Key**
   - Look for **"Project API Key"** section
   - You'll see a key that looks like: `phc_xxxxxxxxxxxxxxxxxxxxxxxxxxxx`
   - This is your **PostHog API Key**

3. **Copy the API Key**
   - Click the copy button next to the API key
   - **Important**: Keep this key secure and don't commit it to version control

## Step 4: Add API Key to Your App

1. **Open Config-Secrets.plist**
   - In Xcode, navigate to `TheDailyDev/Config-Secrets.plist`
   - If the file doesn't exist, create it:
     - Right-click on `TheDailyDev` folder
     - Select **"New File"**
     - Choose **"Property List"**
     - Name it `Config-Secrets.plist`

2. **Add the API Key**
   - Open `Config-Secrets.plist` in Xcode
   - Add a new row with:
     - **Key**: `POSTHOG_API_KEY`
     - **Type**: String
     - **Value**: Paste your PostHog API key (e.g., `phc_xxxxxxxxxxxxxxxxxxxxxxxxxxxx`)

3. **Verify the File Structure**
   - Your `Config-Secrets.plist` should look like:
   ```xml
   <?xml version="1.0" encoding="UTF-8"?>
   <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
   <plist version="1.0">
   <dict>
       <key>SUPABASE_URL</key>
       <string>your-supabase-url</string>
       <key>SUPABASE_KEY</key>
       <string>your-supabase-key</string>
       <key>REVENUECAT_API_KEY</key>
       <string>your-revenuecat-key</string>
       <key>POSTHOG_API_KEY</key>
       <string>phc_xxxxxxxxxxxxxxxxxxxxxxxxxxxx</string>
   </dict>
   </plist>
   ```

4. **Ensure File is in .gitignore**
   - Make sure `Config-Secrets.plist` is in your `.gitignore` file
   - This prevents accidentally committing your API keys

## Step 5: Test the Integration

1. **Build and Run the App**
   - In Xcode, build and run the app on a simulator or device
   - The app will automatically initialize PostHog when it launches

2. **Verify Events are Being Tracked**
   - In PostHog dashboard, go to **"Events"** or **"Live Events"**
   - You should see events appearing in real-time as you use the app:
     - `app_open` - When app launches
     - `app_foreground` - When app comes to foreground
     - `sign_up_started` - When user begins sign-up
     - `sign_up_completed` - When user completes sign-up
     - `question_viewed` - When user views a question
     - `question_answered` - When user answers a question
     - And many more...

3. **Check for Errors**
   - If events aren't appearing, check:
     - Xcode console for any PostHog initialization errors
     - PostHog dashboard for any API key errors
     - Ensure the API key is correctly added to `Config-Secrets.plist`

## Step 6: Explore PostHog Features

Once events are flowing, you can:

1. **View Funnels**
   - Go to **"Insights"** → **"New Insight"** → **"Funnel"**
   - Create a conversion funnel:
     - Step 1: `app_open`
     - Step 2: `sign_up_completed`
     - Step 3: `first_question_answered`
     - Step 4: `paywall_viewed`
     - Step 5: `subscription_purchased`

2. **View User Sessions**
   - Go to **"Persons"** to see individual users
   - Click on a user to see their event history

3. **Create Dashboards**
   - Go to **"Dashboards"** → **"New Dashboard"**
   - Add charts for key metrics:
     - Daily active users
     - Conversion rates
     - Question completion rates
     - Subscription conversion

## Troubleshooting

### Events Not Appearing

1. **Check API Key**
   - Verify the API key in `Config-Secrets.plist` matches your PostHog project
   - Ensure there are no extra spaces or characters

2. **Check Console Logs**
   - Look for PostHog initialization messages in Xcode console
   - Should see: `✅ PostHog initialized with API key`
   - If you see errors, check the error message

3. **Check Network**
   - Ensure device/simulator has internet connection
   - PostHog requires network access to send events

4. **Check PostHog Project**
   - Verify you're looking at the correct project in PostHog dashboard
   - Check project settings to ensure it's active

### API Key Not Found Error

- If you see: `⚠️ POSTHOG_API_KEY not found in Config-Secrets.plist`
- Verify:
  1. The file is named exactly `Config-Secrets.plist` (case-sensitive)
  2. The key is named exactly `POSTHOG_API_KEY` (case-sensitive)
  3. The file is in the `TheDailyDev` folder
  4. The file is added to the Xcode project target

## Next Steps

Once PostHog is set up and working:

1. **Monitor Key Metrics**
   - Set up alerts for important events
   - Track conversion rates over time

2. **Create Custom Insights**
   - Build dashboards for your specific needs
   - Track user behavior patterns

3. **Set Up Cohorts**
   - Create user segments (e.g., "Users who completed first question")
   - Analyze behavior differences between cohorts

4. **Review Regularly**
   - Check analytics weekly to understand user behavior
   - Use insights to improve the app experience

## Resources

- **PostHog Documentation**: [https://posthog.com/docs](https://posthog.com/docs)
- **iOS SDK Documentation**: [https://posthog.com/docs/integrate/client/ios](https://posthog.com/docs/integrate/client/ios)
- **PostHog Community**: [https://posthog.com/questions](https://posthog.com/questions)

## Security Notes

- **Never commit API keys to version control**
- Keep `Config-Secrets.plist` in `.gitignore`
- Use different API keys for development and production
- Rotate keys if they're ever exposed

