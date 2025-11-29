# Privacy Manifest Setup Guide

iOS 17+ requires apps to include a Privacy Manifest file (`PrivacyInfo.xcprivacy`) that declares the use of certain APIs and third-party SDKs.

## Required Reason APIs

Your app may use these APIs that require declaration:

### 1. User Defaults (NSUserDefaults)
- **Used for:** Storing user preferences, cached data
- **Required Reason:** CA92.1 - Access user defaults to read app-specific preferences

### 2. File Timestamp APIs
- **Used for:** Checking file modification times, cache expiration
- **Required Reason:** C617.1 - Access file timestamp for app functionality

### 3. System Boot Time
- **Used for:** Calculating time intervals, cache expiration
- **Required Reason:** 35F9.1 - Access system boot time for app functionality

## Third-Party SDKs

### Supabase Swift SDK
- **Privacy Policy:** https://supabase.com/privacy
- **Data Collection:** User authentication data, app usage data
- **Purpose:** Backend services, authentication, database

### Stripe SDK (via Edge Functions)
- **Privacy Policy:** https://stripe.com/privacy
- **Data Collection:** Payment information (processed server-side)
- **Purpose:** Payment processing

## Creating the Privacy Manifest

1. In Xcode, right-click on your app target
2. Select "New File..."
3. Choose "Property List"
4. Name it `PrivacyInfo.xcprivacy`
5. Add the required keys (see example below)

## Example PrivacyInfo.xcprivacy

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>NSPrivacyTracking</key>
    <false/>
    <key>NSPrivacyTrackingDomains</key>
    <array/>
    <key>NSPrivacyCollectedDataTypes</key>
    <array>
        <dict>
            <key>NSPrivacyCollectedDataType</key>
            <string>NSPrivacyCollectedDataTypeEmailAddress</string>
            <key>NSPrivacyCollectedDataTypeLinked</key>
            <false/>
            <key>NSPrivacyCollectedDataTypeTracking</key>
            <false/>
            <key>NSPrivacyCollectedDataTypePurposes</key>
            <array>
                <string>NSPrivacyCollectedDataTypePurposeAppFunctionality</string>
            </array>
        </dict>
        <dict>
            <key>NSPrivacyCollectedDataType</key>
            <string>NSPrivacyCollectedDataTypeUserID</string>
            <key>NSPrivacyCollectedDataTypeLinked</key>
            <false/>
            <key>NSPrivacyCollectedDataTypeTracking</key>
            <false/>
            <key>NSPrivacyCollectedDataTypePurposes</key>
            <array>
                <string>NSPrivacyCollectedDataTypePurposeAppFunctionality</string>
            </array>
        </dict>
    </array>
    <key>NSPrivacyAccessedAPITypes</key>
    <array>
        <dict>
            <key>NSPrivacyAccessedAPIType</key>
            <string>NSPrivacyAccessedAPICategoryUserDefaults</string>
            <key>NSPrivacyAccessedAPITypeReasons</key>
            <array>
                <string>CA92.1</string>
            </array>
        </dict>
        <dict>
            <key>NSPrivacyAccessedAPIType</key>
            <string>NSPrivacyAccessedAPICategoryFileTimestamp</string>
            <key>NSPrivacyAccessedAPITypeReasons</key>
            <array>
                <string>C617.1</string>
            </array>
        </dict>
        <dict>
            <key>NSPrivacyAccessedAPIType</key>
            <string>NSPrivacyAccessedAPICategorySystemBootTime</string>
            <key>NSPrivacyAccessedAPITypeReasons</key>
            <array>
                <string>35F9.1</string>
            </array>
        </dict>
    </array>
</dict>
</plist>
```

## Resources

- [Apple's Privacy Manifest Documentation](https://developer.apple.com/documentation/bundleresources/privacy_manifest_files)
- [Required Reason API Reference](https://developer.apple.com/documentation/bundleresources/privacy_manifest_files/describing_use_of_required_reason_api)

