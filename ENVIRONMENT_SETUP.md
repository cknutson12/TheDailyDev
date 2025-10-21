# Environment Variables Setup

This project uses environment variables to store sensitive information like API keys. Follow these steps to set up your environment:

## Setup Instructions

1. **Copy the example configuration file:**
   ```bash
   cp Config-Example.plist Config-Secrets.plist
   ```

2. **Edit `Config-Secrets.plist` with your actual values:**
   - Replace `YOUR_SUPABASE_URL_HERE` with your actual Supabase URL
   - Replace `YOUR_SUPABASE_KEY_HERE` with your actual Supabase key

3. **Add the secrets file to your Xcode project:**
   - In Xcode, right-click on your project
   - Select "Add Files to [ProjectName]"
   - Choose `Config-Secrets.plist`
   - Make sure it's added to your target
   - **Important**: Make sure "Add to target" is checked for your app target

## Important Security Notes

- ✅ `Config-Example.plist` is safe to commit to git
- ❌ `Config-Secrets.plist` is in `.gitignore` and should NEVER be committed
- ✅ The `Config.swift` file is safe to commit (it only reads from Info.plist)

## Files Overview

- `Config.swift` - Safe configuration reader
- `Config-Example.plist` - Template file (safe to commit)
- `Config-Secrets.plist` - Your actual secrets (DO NOT COMMIT)
- `.gitignore` - Excludes secret files from git

## Troubleshooting

If you get "SUPABASE_URL not found in Config-Secrets.plist" errors:
1. Make sure `Config-Secrets.plist` is added to your Xcode target
2. Check that the file is included in your app bundle (not just the project)
3. Verify the plist file format is correct
4. Make sure you're not using the example file - use the actual secrets file
