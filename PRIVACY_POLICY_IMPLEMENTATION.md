# Privacy Policy Implementation Guide

This guide walks you through implementing the Privacy Policy for The Daily Dev app.

## ✅ Completed Steps

1. ✅ Privacy Policy template created (`PRIVACY_POLICY_TEMPLATE.md`)
2. ✅ Privacy Policy link added to Settings view
3. ✅ Config.swift updated with privacy policy URL property
4. ✅ Info.plist updated with NSPrivacyPolicyURL key
5. ✅ Template customized with your email (thedailydev@arjaythedev.com)

## 📋 Remaining Steps

### Step 1: Host Privacy Policy on Your Website

1. **Create the HTML page:**
   - Copy the content from `PRIVACY_POLICY_TEMPLATE.md`
   - Convert markdown to HTML (or use a markdown renderer)
   - Create a clean, readable page on your website

2. **Choose a permanent URL:**
   - Recommended: `https://yourdomain.com/privacy-policy`
   - Make sure the URL is publicly accessible (no login required)
   - The URL should be stable and not change

3. **Update the template:**
   - Replace `[YOUR_WEBSITE_URL]` with your actual website URL
   - Ensure all placeholders are filled in

### Step 2: Update Code with Privacy Policy URL

#### A. Update Config.swift

**File:** `TheDailyDev/Config.swift`

**Location:** Lines 30-33

**Current code:**
```swift
static var privacyPolicyURL: String {
    // Replace with your actual privacy policy URL
    // Example: "https://yourdomain.com/privacy-policy"
    return "https://yourdomain.com/privacy-policy" // PLACEHOLDER - UPDATE THIS
}
```

**Update to:**
```swift
static var privacyPolicyURL: String {
    return "https://yourdomain.com/privacy-policy" // Replace with your actual URL
}
```

**Example:**
```swift
static var privacyPolicyURL: String {
    return "https://thedailydev.com/privacy-policy"
}
```

#### B. Update Info.plist

**File:** `TheDailyDev/Info.plist`

**Location:** Lines 28-29

**Current code:**
```xml
<key>NSPrivacyPolicyURL</key>
<string>https://yourdomain.com/privacy-policy</string>
```

**Update to:**
```xml
<key>NSPrivacyPolicyURL</key>
<string>https://yourdomain.com/privacy-policy</string>
```

**Example:**
```xml
<key>NSPrivacyPolicyURL</key>
<string>https://thedailydev.com/privacy-policy</string>
```

**Note:** Make sure both URLs match exactly!

### Step 3: Test the Implementation

1. **Build and run the app**
2. **Navigate to Settings:**
   - Profile → Settings (gear icon)
   - Scroll to "Legal" section
3. **Tap "Privacy Policy"**
   - Should open Safari with your privacy policy page
   - Verify the URL is correct
   - Verify the page loads correctly

### Step 4: Add to App Store Connect

When you create your App Store listing:

1. Go to App Store Connect
2. Select your app
3. Go to "App Information"
4. Find "Privacy Policy URL" field
5. Enter the same URL you used in the code
6. Save

## 📍 Code Locations Summary

### Where Privacy Policy is Referenced:

1. **Config.swift** (Line ~30)
   - `privacyPolicyURL` property
   - Used by Settings view to open the link

2. **Info.plist** (Line ~28-29)
   - `NSPrivacyPolicyURL` key
   - Used by iOS system and App Store

3. **SubscriptionSettingsView.swift** (Line ~79-105)
   - "Privacy Policy" button in Legal section
   - Opens URL using `Config.privacyPolicyURL`

## 🔍 Verification Checklist

Before submitting to App Store:

- [ ] Privacy Policy is live on your website
- [ ] URL is publicly accessible (no login required)
- [ ] URL is stable and won't change
- [ ] Config.swift has correct URL
- [ ] Info.plist has correct URL (matches Config.swift)
- [ ] Privacy Policy link works in Settings view
- [ ] Privacy Policy URL added to App Store Connect
- [ ] All placeholders in privacy policy are filled in
- [ ] Privacy policy includes all required information:
  - [ ] Data collection practices
  - [ ] Third-party services disclosure
  - [ ] User rights
  - [ ] Contact information
  - [ ] Last updated date

## 🆘 Troubleshooting

### Link doesn't open in Settings
- Check that `Config.privacyPolicyURL` returns a valid URL string
- Verify the URL format is correct (starts with `https://`)
- Check Xcode console for errors

### URL not working
- Verify the URL is publicly accessible
- Test the URL in a browser first
- Check for typos in the URL

### App Store rejection for missing privacy policy
- Ensure URL is added in App Store Connect
- Verify URL is accessible without login
- Make sure URL matches what's in Info.plist

## 📝 Notes

- **Website URL:** You still need to replace `[YOUR_WEBSITE_URL]` in the privacy policy template
- **Terms of Service:** Optional, but recommended. If you create one, update `Config.termsOfServiceURL` and it will automatically appear in Settings
- **Legal Review:** Consider having a lawyer review your privacy policy before publishing

## 🎯 Quick Reference

**Files to Update:**
1. `Config.swift` - Line ~30
2. `Info.plist` - Line ~28-29
3. `PRIVACY_POLICY_TEMPLATE.md` - Replace `[YOUR_WEBSITE_URL]`

**Where Users See It:**
- Settings → Legal → Privacy Policy (in-app)
- App Store listing (metadata)
- System can reference it (Info.plist)

---

**Last Updated:** November 15, 2025

