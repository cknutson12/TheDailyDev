# Duplicate Email Sign-Up Bug Fix Plan

## Problem

When a user tries to sign up with an email that already exists:
1. The sign-up appears to succeed (no error shown)
2. The email verification screen is shown
3. When trying to resend verification email, it doesn't send (or fails silently)
4. User is stuck in a confusing state

## Root Cause

The `signUp()` function in `SignUpView.swift` doesn't properly handle the case where:
- Email already exists in Supabase
- Supabase might return a session even for existing emails (depending on settings)
- OR Supabase throws an error that we're not catching specifically

## Current Code Flow

```swift
func signUp() async {
    do {
        let session = try await SupabaseManager.shared.client.auth.signUp(...)
        // If successful, check if email is verified
        if user.emailConfirmedAt == nil {
            showingEmailVerification = true  // ❌ Shows even if email exists
        }
    } catch {
        message = "Sign-up failed: \(error.localizedDescription)"  // ❌ Generic error
    }
}
```

## Supabase Behavior

Supabase's `signUp()` method behavior depends on settings:
1. **If "Confirm email" is enabled**: 
   - New user: Creates user, sends verification email, returns session with `emailConfirmedAt = nil`
   - Existing user: Might return error OR might return session (depending on settings)

2. **If "Confirm email" is disabled**:
   - New user: Creates user, returns session with `emailConfirmedAt != nil`
   - Existing user: Returns error or existing session

## Error Types to Handle

Supabase Swift SDK typically throws `AuthError` with:
- `AuthError.userAlreadyRegistered` - User already exists
- `AuthError.emailAlreadyConfirmed` - Email already exists and is verified
- Generic errors with messages like "User already registered"

## Solution Options

### Option A: Check Error Message (Recommended)
**Approach**: Parse error message for duplicate email indicators
**Pros**: Works regardless of Supabase settings
**Cons**: Relies on error message strings (might change)

```swift
catch {
    let errorMessage = error.localizedDescription.lowercased()
    if errorMessage.contains("already registered") || 
       errorMessage.contains("user already exists") ||
       errorMessage.contains("email already") {
        // Show specific error with sign-in option
        message = "An account with this email already exists. Please sign in instead."
        // Optionally: Show "Sign In" button
    } else {
        message = "Sign-up failed: \(error.localizedDescription)"
    }
}
```

### Option B: Check Session User State
**Approach**: After signUp(), check if user already exists by checking email confirmation status
**Pros**: More reliable
**Cons**: Requires additional API call

```swift
let session = try await signUp(...)
// If emailConfirmedAt is not nil, user might already exist
// Check by trying to sign in with same credentials
```

### Option C: Try Sign-In First (Best UX)
**Approach**: Before showing error, try to sign in with the same credentials
**Pros**: Best user experience - automatically signs them in
**Cons**: Requires password (which we have)

```swift
catch {
    // If sign-up fails, try signing in instead
    do {
        let session = try await signIn(email: email, password: password)
        // Successfully signed in - proceed with onboarding
    } catch {
        // Show error message
    }
}
```

### Option D: Check Before Sign-Up
**Approach**: Check if email exists before attempting sign-up
**Pros**: Prevents the issue entirely
**Cons**: Requires additional API call, might not be possible with Supabase

## Recommended Solution: Option A + Option C Hybrid

1. **Catch duplicate email errors** and show a clear message
2. **Offer to sign in** if the email already exists
3. **Handle the case** where Supabase returns a session for existing users

## Implementation Plan

### Step 1: Improve Error Handling
- Add specific error detection for duplicate emails
- Show user-friendly error message
- Add "Sign In Instead" button/link

### Step 2: Handle Edge Case
- Check if `signUp()` returns a session for existing user
- If email is already confirmed, treat as sign-in
- If email is not confirmed, show verification screen (current behavior)

### Step 3: Improve Email Verification
- Add error handling in `resendVerificationEmail()` for existing users
- Show appropriate message if email already exists

### Step 4: Add Sign-In Option
- When duplicate email detected, offer to navigate to sign-in
- Pre-fill email in sign-in form if possible

## Code Changes Needed

1. **SignUpView.swift**:
   - Improve `signUp()` error handling
   - Detect duplicate email errors
   - Show appropriate message
   - Add "Sign In Instead" option

2. **EmailVerificationView.swift**:
   - Improve error handling in `resendEmail()`
   - Handle case where email already exists

3. **SupabaseManager.swift** (if needed):
   - Add helper method to check if email exists (if possible)

## User Experience Flow

### Current (Broken):
1. User enters existing email → Sign up
2. Email verification screen appears
3. User clicks "Resend" → Nothing happens (or error)
4. User is confused

### Fixed:
1. User enters existing email → Sign up
2. **Error message appears**: "An account with this email already exists"
3. **Option to sign in**: "Sign In Instead" button
4. User clicks "Sign In Instead" → Navigate to login with email pre-filled

## Testing Checklist

- [ ] Sign up with new email → Should work normally
- [ ] Sign up with existing email → Should show error message
- [ ] Click "Sign In Instead" → Should navigate to login
- [ ] Email pre-filled in login → Should work
- [ ] Resend verification for existing email → Should show appropriate error
- [ ] Sign up with existing but unverified email → Should show verification screen

