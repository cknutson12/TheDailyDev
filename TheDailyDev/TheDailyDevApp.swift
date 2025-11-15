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
            
            // Validate the token by attempting to establish a session
            // This is where Supabase validates the token server-side
            do {
                // Attempt to establish session from the reset URL
                // This validates the token: checks if it exists, hasn't expired, and hasn't been used
                let session = try await SupabaseManager.shared.client.auth.session(from: url)
                print("✅ Password reset token validated - session established")
                
                // Token is valid - show reset view
                await MainActor.run {
                    passwordResetManager.setResetURL(url)
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
        
        // Handle trial setup completion
        if url.scheme == "thedailydev" && url.host == "trial-started" {
            print("🎉 Trial setup started - completing subscription creation...")
            
            // Extract session_id from query parameters
            if let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
               let queryItems = components.queryItems,
               let sessionIdItem = queryItems.first(where: { $0.name == "session_id" }),
               let sessionId = sessionIdItem.value {
                
                print("📋 Session ID: \(sessionId)")
                
                do {
                    // Complete the trial setup (create subscription with trial)
                    try await subscriptionService.completeTrialSetup(sessionId: sessionId)
                    print("✅ Trial subscription created successfully!")
                    
                    // Force refresh subscription status (bypass cache)
                    _ = await subscriptionService.fetchSubscriptionStatus(forceRefresh: true)
                } catch {
                    print("❌ Failed to complete trial setup: \(error)")
                }
            } else {
                print("❌ No session_id found in trial-started URL")
            }
            return
        }
        
        // Handle Stripe return
        guard url.scheme == "thedailydev" else {
            print("❌ Invalid scheme: \(url.scheme ?? "nil")")
            return
        }
        
        let host = url.host ?? ""
        print("📋 Host: \(host)")
        
        switch host {
        case "subscription-success":
            print("✅ Subscription successful - fetching status...")
            // Force refresh - user just purchased!
            let subscription = await subscriptionService.fetchSubscriptionStatus(forceRefresh: true)
            print("📊 Fetched subscription: \(subscription?.status ?? "none")")
            if subscription != nil {
                print("✅ Active subscription found!")
            } else {
                print("⚠️ No subscription found - webhook may not have processed yet")
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
