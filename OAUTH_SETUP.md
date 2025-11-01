# OAuth Setup Guide for Google and GitHub

This guide will help you set up Google and GitHub OAuth authentication for The Daily Dev.

## Prerequisites

- A Supabase account and project
- Google Cloud Console access
- GitHub account

## Step 1: Configure Google OAuth

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project or select an existing one
3. Navigate to **APIs & Services** > **Credentials**
4. Click **Create Credentials** > **OAuth client ID**
5. Configure the OAuth consent screen if prompted
6. Select **Web application** as application type
7. Add authorized redirect URI: `https://thawdmtbwehbuzmrwicz.supabase.co/auth/v1/callback`
8. Click **Create** and save the **Client ID** and **Client Secret**

## Step 2: Configure GitHub OAuth

1. Go to [GitHub Developer Settings](https://github.com/settings/developers)
2. Click **New OAuth App**
3. Fill in the details:
   - **Application name**: The Daily Dev (or your app name)
   - **Homepage URL**: `https://thedailydev.app` (or your app URL)
   - **Authorization callback URL**: `https://thawdmtbwehbuzmrwicz.supabase.co/auth/v1/callback`
4. Click **Register application**
5. Save the **Client ID**
6. Click **Generate a new client secret** and save it

## Step 3: Configure Supabase

1. Go to your [Supabase Dashboard](https://supabase.com/dashboard)
2. Select your project
3. Navigate to **Authentication** > **URL Configuration**
4. Add your redirect URL: `com.supabase.thedailydev://oauth-callback`
   - This allows OAuth to redirect back to your iOS app
5. Navigate to **Authentication** > **Providers**
6. Enable **Google**:
   - Toggle the switch to enable
   - Enter your Google **Client ID**
   - Enter your Google **Client Secret**
   - Click **Save**
7. Enable **GitHub**:
   - Toggle the switch to enable
   - Enter your GitHub **Client ID**
   - Enter your GitHub **Client Secret**
   - Click **Save**

## Step 4: Test OAuth Sign-In

1. Build and run the app in the simulator
2. On the login screen, tap "Continue with Google" or "Continue with GitHub"
3. Complete the authentication flow
4. You should be redirected back to the app and logged in

## Troubleshooting

### "redirect_uri_mismatch" Error
- Verify that the redirect URL in the OAuth provider matches exactly with Supabase
- For Google: Check "Authorized redirect URIs" in Google Cloud Console
- For GitHub: Check "Authorization callback URL" in GitHub OAuth Apps settings

### OAuth Not Working on Simulator
- OAuth requires opening the browser, which should work on the simulator
- If issues persist, test on a physical device

### Session Not Persisting After OAuth
- Ensure `AuthManager.swift` is properly integrated
- Check that `TheDailyDevApp.swift` handles the OAuth callback correctly
- Verify the redirect URL scheme in `Info.plist` matches your configuration

