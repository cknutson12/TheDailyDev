//
//  TheDailyDevApp.swift
//  TheDailyDev
//
//  Created by Claire Knutson on 10/14/25.
//

import SwiftUI

@main
struct TheDailyDevApp: App {
    @StateObject private var subscriptionService = SubscriptionService.shared
    @StateObject private var passwordResetManager = PasswordResetManager.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onOpenURL { url in
                    Task {
                        await handleDeepLink(url: url)
                    }
                }
                .sheet(isPresented: $passwordResetManager.showingResetView) {
                    if let resetURL = passwordResetManager.resetURL {
                        ResetPasswordView(resetURL: resetURL)
                    }
                }
                .alert("Password Reset Error", isPresented: $passwordResetManager.showingError) {
                    Button("OK") {
                        passwordResetManager.dismiss()
                    }
                } message: {
                    Text(passwordResetManager.errorMessage ?? "An error occurred with the password reset link.")
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
            // Supabase automatically verifies when user clicks link
            // Just refresh auth state
            await AuthManager.shared.checkSession()
            // Show success notification or state change
            return
        }
        
        // Handle password reset
        if url.scheme == "thedailydev" && url.host == "password-reset" {
            print("🔑 Password reset received: \(url.absoluteString)")
            
            // Extract token and type from query parameters
            guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
                  let queryItems = components.queryItems,
                  let token = queryItems.first(where: { $0.name == "token" })?.value else {
                print("❌ No token found in password reset URL")
                await MainActor.run {
                    passwordResetManager.setError(NSError(
                        domain: "PasswordReset",
                        code: 400,
                        userInfo: [NSLocalizedDescriptionKey: "Invalid reset link. Missing token."]
                    ))
                }
                return
            }
            
            let type = queryItems.first(where: { $0.name == "type" })?.value ?? "recovery"
            print("📋 Extracted token: \(token.prefix(20))...")
            print("📋 Type: \(type)")
            
            // Construct Supabase verification URL from the token
            // Supabase's session(from:) expects a URL like:
            // https://project.supabase.co/auth/v1/verify?token=...&type=recovery
            let supabaseURL = Config.supabaseURL
            guard let verificationURL = URL(string: "\(supabaseURL)/auth/v1/verify?token=\(token.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? token)&type=\(type)") else {
                print("❌ Failed to construct Supabase verification URL")
                await MainActor.run {
                    passwordResetManager.setError(NSError(
                        domain: "PasswordReset",
                        code: 500,
                        userInfo: [NSLocalizedDescriptionKey: "Failed to process reset link."]
                    ))
                }
                return
            }
            
            // Validate the token by attempting to establish a session
            // This is where Supabase validates the token server-side
            do {
                // Attempt to establish session from the Supabase verification URL
                // This validates the token: checks if it exists, hasn't expired, and hasn't been used
                _ = try await SupabaseManager.shared.client.auth.session(from: verificationURL)
                print("✅ Password reset token validated - session established")
                
                // Token is valid - store the original deep link URL for the reset view
                // The reset view will use this URL to re-establish the session when updating password
                await MainActor.run {
                    passwordResetManager.setResetURL(verificationURL)
                }
            } catch {
                // Token validation failed - show error
                print("❌ Password reset token validation failed: \(error)")
                await MainActor.run {
                    passwordResetManager.setError(error)
                }
            }
            return
        }
        
        // Note: trial-started handler removed - subscriptions are created directly via Stripe checkout
        // The webhook handles creating the user_subscription record when checkout.session.completed fires
        
        // Handle Stripe return
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
