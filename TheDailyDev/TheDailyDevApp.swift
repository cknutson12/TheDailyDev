//
//  TheDailyDevApp.swift
//  TheDailyDev
//
//  Created by Claire Knutson on 10/14/25.
//

import SwiftUI
import RevenueCat

@main
struct TheDailyDevApp: App {
    @StateObject private var subscriptionService = SubscriptionService.shared
    @StateObject private var passwordResetManager = PasswordResetManager.shared
    @StateObject private var emailVerificationManager = EmailVerificationManager.shared
    
    init() {
        // Initialize RevenueCat SDK
        Purchases.logLevel = .debug // Use .info or .warn in production
        Purchases.configure(withAPIKey: Config.revenueCatAPIKey)
        
        // Set user ID after authentication (will be called from AuthManager)
        // For now, anonymous ID will be used until user signs in
        print("✅ RevenueCat SDK initialized with API key")
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onOpenURL { url in
                    Task {
                        await handleDeepLink(url: url)
                    }
                }
                .sheet(isPresented: $passwordResetManager.showingResetView) {
                    if let resetCode = passwordResetManager.resetCode {
                        ResetPasswordView(resetCode: resetCode)
                    }
                }
                .alert("Password Reset Error", isPresented: $passwordResetManager.showingError) {
                    Button("OK") {
                        passwordResetManager.dismiss()
                    }
                } message: {
                    Text(passwordResetManager.errorMessage ?? "An error occurred with the password reset link.")
                }
                .sheet(isPresented: $emailVerificationManager.showingOnboarding) {
                    OnboardingView(onContinue: {
                        emailVerificationManager.dismiss()
                        // After onboarding, show subscription screen
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            // Post notification to show subscription screen
                            NotificationCenter.default.post(name: NSNotification.Name("ShowSubscriptionAfterOnboarding"), object: nil)
                        }
                    })
                }
        }
    }
    
    // MARK: - Handle Deep Links
    private func handleDeepLink(url: URL) async {
        print("🔗 Received deep link: \(url)")
        print("   - scheme: \(url.scheme ?? "nil")")
        print("   - host: \(url.host ?? "nil")")
        print("   - path: \(url.path)")
        
        // Handle Supabase OAuth redirects
        if url.scheme == "com.supabase.thedailydev" && url.host == "oauth-callback" {
            print("🔐 OAuth callback received: \(url.absoluteString)")
            await AuthManager.shared.handleOAuthCallback(url: url)
            return
        }
        
        // Handle email confirmation
        if url.scheme == "thedailydev" && url.host == "email-confirm" {
            print("📧 Email confirmation received: \(url.absoluteString)")
            
            // Extract code from query parameters
            // Supabase redirects with a 'code' parameter after verification
            guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
                  let queryItems = components.queryItems else {
                print("❌ No query parameters found in email confirmation URL")
                return
            }
            
            // Check for 'code' parameter first, then fallback to 'token' (if it's a UUID, not PKCE)
            var authCode: String?
            
            // First try 'code' parameter
            if let code = queryItems.first(where: { $0.name == "code" })?.value {
                authCode = code
                print("📋 Extracted code: \(code.prefix(20))...")
            } else if let token = queryItems.first(where: { $0.name == "token" })?.value {
                // If token is a UUID (not a PKCE token), treat it as a code
                // PKCE tokens start with "pkce_", UUIDs are 36 chars with dashes
                print("📋 Found token parameter: \(token.prefix(20))... (length: \(token.count))")
                if !token.hasPrefix("pkce_") && token.count == 36 && token.contains("-") {
                    authCode = token
                    print("✅ Token is a UUID - treating as code")
                } else {
                    print("⚠️ Token doesn't match UUID format - ignoring")
                }
            } else {
                print("⚠️ No 'code' or 'token' parameter found in query items")
                for item in queryItems {
                    print("   - \(item.name): \(item.value ?? "nil")")
                }
            }
            
            guard let code = authCode else {
                print("❌ No valid code found in email confirmation URL")
                return
            }
            
            // Exchange the code for a session (PKCE flow)
            // This verifies the email - user is already signed in, just verifying email
            do {
                _ = try await SupabaseManager.shared.client.auth.exchangeCodeForSession(authCode: code)
                print("✅ Email verification code validated - email verified")
                
                // Give the UI a moment to update if the app was in the background
                try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
                
                // Refresh auth state to update UI (user is already signed in, just email is now verified)
                await AuthManager.shared.checkSession()
                
                // Set RevenueCat user ID after verification
                await AuthManager.shared.setRevenueCatUserID()
                
                // Create subscription record with stored names (now we have a session)
                let firstName = emailVerificationManager.pendingFirstName
                let lastName = emailVerificationManager.pendingLastName
                
                await SubscriptionService.shared.ensureUserSubscriptionRecord(
                    firstName: firstName,
                    lastName: lastName
                )
                QuestionService.shared.invalidateDisplayNameCache()
                
                // Clear pending names
                emailVerificationManager.clearPendingNames()
                
                // Check if this is a new user who should see onboarding
                // If user just verified email after sign-up, show onboarding
                await MainActor.run {
                    emailVerificationManager.showOnboarding()
                }
                
                print("✅ Auth state refreshed after email verification")
            } catch {
                print("❌ Email verification code validation failed: \(error)")
                // Still try to refresh auth state in case verification worked
                await AuthManager.shared.checkSession()
            }
            return
        }
        
        // Handle password reset
        if url.scheme == "thedailydev" && url.host == "password-reset" {
            print("🔑 Password reset received: \(url.absoluteString)")
            
            // Extract code from query parameters
            // Supabase redirects with a 'code' parameter, but HTML might pass it as 'token'
            guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
                  let queryItems = components.queryItems else {
                print("❌ No query parameters found in password reset URL")
                await MainActor.run {
                    passwordResetManager.setError(NSError(
                        domain: "PasswordReset",
                        code: 400,
                        userInfo: [NSLocalizedDescriptionKey: "Invalid reset link. Missing parameters."]
                    ))
                }
                return
            }
            
            // Check for 'code' parameter first, then fallback to 'token' (if it's a UUID, not PKCE)
            var authCode: String?
            
            // First try 'code' parameter
            if let code = queryItems.first(where: { $0.name == "code" })?.value {
                authCode = code
                print("📋 Extracted code: \(code.prefix(20))...")
            } else if let token = queryItems.first(where: { $0.name == "token" })?.value {
                // If token is a UUID (not a PKCE token), treat it as a code
                // PKCE tokens start with "pkce_", UUIDs are 36 chars with dashes
                print("📋 Found token parameter: \(token.prefix(20))... (length: \(token.count))")
                if !token.hasPrefix("pkce_") && token.count == 36 && token.contains("-") {
                    authCode = token
                    print("✅ Token is a UUID - treating as code")
                } else {
                    print("⚠️ Token doesn't match UUID format - ignoring")
                }
            } else {
                print("⚠️ No 'code' or 'token' parameter found in query items")
                for item in queryItems {
                    print("   - \(item.name): \(item.value ?? "nil")")
                }
            }
            
            guard let code = authCode else {
                print("❌ No valid code found in password reset URL")
                await MainActor.run {
                    passwordResetManager.setError(NSError(
                        domain: "PasswordReset",
                        code: 400,
                        userInfo: [NSLocalizedDescriptionKey: "Invalid reset link. Missing code."]
                    ))
                }
                return
            }
            
            // Exchange the code for a session (PKCE flow)
            // This validates the code and establishes a session for password reset
            do {
                _ = try await SupabaseManager.shared.client.auth.exchangeCodeForSession(authCode: code)
                print("✅ Password reset code validated - session established")
                
                // Post notification to dismiss any forgot password views
                await MainActor.run {
                    NotificationCenter.default.post(name: NSNotification.Name("PasswordResetLinkReceived"), object: nil)
                }
                
                // Session is now established - store code for the reset view
                // This will immediately show the password reset view
                // Use MainActor to ensure UI updates happen on the main thread
                await MainActor.run {
                    // Set the reset code which will trigger showingResetView = true
                    passwordResetManager.setResetCode(code)
                    print("📱 Password reset view should now be visible")
                }
                
                // Give the UI a moment to update if the app was in the background
                try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
            } catch {
                print("❌ Password reset code validation failed: \(error)")
                await MainActor.run {
                    passwordResetManager.setError(error)
                }
            }
            return
        }
        
        // Note: subscriptions are created directly via RevenueCat
        // The webhook handles creating the user_subscription record when checkout.session.completed fires
        
        // Handle subscription return
        guard url.scheme == "thedailydev" else {
            print("❌ Invalid scheme: \(url.scheme ?? "nil")")
            return
        }
        
        let host = url.host ?? ""
        print("📋 Host: \(host)")
        
        switch host {
        case "subscription-success":
            print("✅ Subscription successful - refreshing subscription status...")
            
            // Invalidate caches to force fresh data
            subscriptionService.invalidateCache()
            QuestionService.shared.invalidateProgressCache()
            QuestionService.shared.invalidateQuestionCache()
            
            // Wait a moment for webhook to process checkout.session.completed
            try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
            
            // Force refresh - user just purchased!
            let subscription = await subscriptionService.fetchSubscriptionStatus(forceRefresh: true)
            print("📊 Fetched subscription: \(subscription?.status ?? "none")")
            
            if subscription != nil {
                print("✅ Active subscription found!")
                // Cache already invalidated, so next call will fetch fresh
            } else {
                print("⚠️ No subscription found - webhook may still be processing")
                // Retry after another 3 seconds
                try? await Task.sleep(nanoseconds: 3_000_000_000)
                let retrySubscription = await subscriptionService.fetchSubscriptionStatus(forceRefresh: true)
                if retrySubscription != nil {
                    print("✅ Subscription found on retry!")
                    // Refresh question access status
                    _ = await QuestionService.shared.hasAnsweredToday()
                }
            }
            
            // Post notification to dismiss subscription views
            await MainActor.run {
                NotificationCenter.default.post(name: NSNotification.Name("SubscriptionSuccess"), object: nil)
            }
        case "subscription-updated":
            print("💳 Subscription updated via billing portal - refreshing...")
            // Force refresh - user just modified subscription!
            let subscription = await subscriptionService.fetchSubscriptionStatus(forceRefresh: true)
            print("📊 Updated subscription: \(subscription?.status ?? "none")")
        case "subscription-cancel":
            print("❌ Subscription canceled")
        default:
            print("⚠️ Unknown host: \(host)")
            break
        }
    }
}
