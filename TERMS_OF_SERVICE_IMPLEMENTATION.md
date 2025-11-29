# Terms of Service Implementation Guide

This guide walks you through implementing Terms of Service for The Daily Dev app.

## 📋 Overview

**Terms of Service is RECOMMENDED but NOT REQUIRED** for App Store submission (unlike Privacy Policy which is required). However, it's highly recommended for:
- Legal protection
- Clear subscription terms
- User expectations
- Professional appearance

## ✅ What's Already Set Up

1. ✅ Terms of Service template created (`TERMS_OF_SERVICE_TEMPLATE.md`)
2. ✅ Terms of Service link already in Settings view (will appear when URL is set)
3. ✅ Config.swift has `termsOfServiceURL` property
4. ✅ Settings view checks if URL exists before showing the link

## 📋 Implementation Steps

### Step 1: Customize the Terms of Service Template

1. **Open `TERMS_OF_SERVICE_TEMPLATE.md`**
2. **Replace placeholders:**
   - `[YOUR_STATE/COUNTRY]` → Your jurisdiction (e.g., "California, United States")
   - `[YOUR_WEBSITE_URL]` → Your website URL
3. **Review and customize:**
   - Subscription terms (trial period, pricing, cancellation)
   - Refund policy
   - Dispute resolution location
   - Any other terms specific to your business

### Step 2: Host Terms of Service on Your Website

1. **Create the HTML page:**
   - Convert markdown to HTML (or use a markdown renderer)
   - Create a clean, readable page on your website

2. **Choose a permanent URL:**
   - Recommended: `https://yourdomain.com/terms-of-service`
   - Make sure the URL is publicly accessible
   - The URL should be stable and not change

3. **Add link to your website:**
   - Add Terms of Service link to website footer
   - Or add to an "About" or "Legal" page
   - Make it easily accessible from your main website navigation

### Step 3: Update Code with Terms of Service URL

**File:** `Config.swift`

**Location:** Lines 36-40

**Current code:**
```swift
static var termsOfServiceURL: String {
    // Replace with your actual terms of service URL, or return empty string if not available
    // Example: "https://yourdomain.com/terms-of-service"
    return "" // PLACEHOLDER - UPDATE THIS or leave empty if not available
}
```

**Update to:**
```swift
static var termsOfServiceURL: String {
    return "https://yourdomain.com/terms-of-service" // Replace with your actual URL
}
```

**Example:**
```swift
static var termsOfServiceURL: String {
    return "https://thedailydev.com/terms-of-service"
}
```

**Note:** If you don't want to include Terms of Service yet, you can leave it as an empty string `""` and the link won't appear in Settings.

### Step 4: Test the Implementation

1. **Build and run the app**
2. **Navigate to Settings:**
   - Profile → Settings (gear icon)
   - Scroll to "Legal" section
3. **Verify Terms of Service link appears** (if URL is set)
4. **Tap "Terms of Service"**
   - Should open Safari with your terms page
   - Verify the URL is correct
   - Verify the page loads correctly

## 📍 Code Locations

### Where Terms of Service is Referenced:

1. **Config.swift** (Line ~36)
   - `termsOfServiceURL` property
   - Used by Settings view to show/hide the link

2. **SubscriptionSettingsView.swift** (Line ~108-136)
   - "Terms of Service" button in Legal section
   - Only shows if `Config.termsOfServiceURL` is not empty
   - Opens URL using `Config.termsOfServiceURL`

## 🔍 Verification Checklist

- [ ] Terms of Service is live on your website
- [ ] URL is publicly accessible (no login required)
- [ ] URL is stable and won't change
- [ ] Terms of Service link added to website (footer, about page, etc.)
- [ ] Config.swift has correct URL (or empty string if not using)
- [ ] Terms of Service link appears in Settings (if URL is set)
- [ ] Terms of Service link works correctly
- [ ] All placeholders in terms are filled in
- [ ] Terms include all important sections:
  - [ ] Subscription terms and auto-renewal
  - [ ] Cancellation policy
  - [ ] Refund policy
  - [ ] User responsibilities
  - [ ] Intellectual property
  - [ ] Limitation of liability
  - [ ] Contact information

## ⚠️ Important Notes

### Is Terms of Service Required?

- **App Store:** Not strictly required, but recommended
- **Legal Protection:** Highly recommended
- **Subscription Apps:** Strongly recommended (Apple may ask for it)

### When to Include It

- **Before Launch:** Recommended, especially for subscription apps
- **After Launch:** You can add it later, but better to have it from the start
- **If Not Ready:** Leave `termsOfServiceURL` as empty string - the link won't show

### Key Sections to Focus On

1. **Subscription Terms** - Most important for your app
   - Trial period
   - Auto-renewal
   - Cancellation
   - Refunds

2. **User Responsibilities** - Protect yourself
   - Account security
   - Acceptable use
   - Prohibited activities

3. **Limitation of Liability** - Legal protection
   - Service availability
   - Content accuracy
   - Damage limitations

## 🆘 Troubleshooting

### Link doesn't appear in Settings
- Check that `Config.termsOfServiceURL` is not an empty string
- Verify the URL format is correct (starts with `https://`)

### Link doesn't open
- Verify the URL is publicly accessible
- Test the URL in a browser first
- Check for typos in the URL

## 📝 Quick Reference

**Files to Update:**
1. `Config.swift` - Line ~36 (update `termsOfServiceURL`)

**Where Users See It:**
- Settings → Legal → Terms of Service (in-app, only if URL is set)

**Template File:**
- `TERMS_OF_SERVICE_TEMPLATE.md` - Customize this, then host on your website

---

**Last Updated:** November 15, 2025

