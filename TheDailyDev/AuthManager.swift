//
//  AuthManager.swift
//  TheDailyDev
//
//  Created by Claire Knutson on 10/28/25.
//

import Foundation
import Supabase
import SwiftUI
import RevenueCat

class AuthManager: ObservableObject {
    static let shared = AuthManager()
    
    @Published var isAuthenticated = false
    @Published var isCheckingAuth = true // Track if we're still checking auth status
    
    private init() {}
    
    // MARK: - Session Management
    func checkSession() async {
        await MainActor.run {
            isCheckingAuth = true
        }
        
        do {
            let _ = try await SupabaseManager.shared.client.auth.session
            await MainActor.run {
                isAuthenticated = true
                isCheckingAuth = false
            }
        } catch {
            await MainActor.run {
                isAuthenticated = false
                isCheckingAuth = false
            }
        }
    }
    
    // MARK: - Sign Out
    
    /// Force sign out (useful for testing when account is deleted)
    /// This clears the session without requiring the sign out button
    func forceSignOut() async {
        DebugLogger.log("🚪 Force signing out user (session clear)...")
        
        do {
            try await signOut()
        } catch {
            // If signOut fails (e.g., account deleted), just clear local state
            DebugLogger.log("⚠️ Sign out failed, clearing local state only: \(error)")
            await MainActor.run {
                isAuthenticated = false
                isCheckingAuth = false
            }
            // Clear RevenueCat
            _ = try? await Purchases.shared.logOut()
            // Clear caches
            SubscriptionService.shared.clearAllCaches()
            QuestionService.shared.clearAllCaches()
            OnboardingTourManager.shared.resetTour()
        }
    }
    
    func signOut() async throws {
        // Track sign-out
        AnalyticsService.shared.track("sign_out")
        
        DebugLogger.log("🚪 Signing out user - clearing all caches...")
        
        // Clear all caches BEFORE signing out to prevent cancelled request errors
        await MainActor.run {
            // Clear all QuestionService caches
            QuestionService.shared.clearAllCaches()
            
            // Clear all SubscriptionService caches
            SubscriptionService.shared.clearAllCaches()
            
            // Reset tour completion so new accounts get a fresh tour
            OnboardingTourManager.shared.resetTour()
            DebugLogger.log("✅ Tour completion reset for new account")
        }
        
        // Clear analytics user ID
        AnalyticsService.shared.clearUserID() // Reset PostHog user identity
        
        // Log out from RevenueCat to clear its local cache
        // This ensures no RevenueCat data persists for the next user
        do {
            _ = try await Purchases.shared.logOut()
            DebugLogger.log("✅ RevenueCat logged out - local cache cleared")
        } catch {
            DebugLogger.error("⚠️ Failed to log out from RevenueCat: \(error)")
            // Don't throw - continue with sign out even if RevenueCat logout fails
        }
        
        // Sign out from Supabase
        try await SupabaseManager.shared.client.auth.signOut()
        
        // Final state cleanup
        await MainActor.run {
            isAuthenticated = false
            isCheckingAuth = false // Ensure we're not in checking state after sign out
        }
        
        DebugLogger.log("✅ Sign out complete - all caches cleared")
    }
    
    // MARK: - Handle OAuth Callback
    func handleOAuthCallback(url: URL) async {
        do {
            // Extract the session from the callback URL to verify authentication
            let session = try await SupabaseManager.shared.client.auth.session(from: url)
            let userId = session.user.id.uuidString
            
            let shouldShowOnboarding = OnboardingTourManager.shared.shouldShowTour()
            DebugLogger.log("🧭 OAuth onboarding check - shouldShowTour: \(shouldShowOnboarding)")
            
            // Set RevenueCat user ID and update database
            // This will call logIn() and update the database
            await setRevenueCatUserID()
            
            await MainActor.run {
                isAuthenticated = true
                isCheckingAuth = false
                
                if shouldShowOnboarding {
                    DebugLogger.log("🆕 OAuth sign-in - showing onboarding")
                    EmailVerificationManager.shared.showOnboarding()
                }
            }
        } catch {
            DebugLogger.error("Failed to establish OAuth session: \(error)")
            await MainActor.run {
                isAuthenticated = false
                isCheckingAuth = false
            }
        }
    }
    
    // MARK: - Set RevenueCat User ID
    /// Call this after user signs in to link RevenueCat purchases to user account
    func setRevenueCatUserID() async {
        do {
            let session = try await SupabaseManager.shared.client.auth.session
            let userId = session.user.id.uuidString
            
            // Link the RevenueCat customer to this user ID
            let (_, created) = try await Purchases.shared.logIn(userId)
            DebugLogger.log("✅ RevenueCat user ID set")
            if created {
                DebugLogger.log("   - New RevenueCat customer created")
            } else {
                DebugLogger.log("   - Existing RevenueCat customer linked")
            }
            
            // Immediately update the database with the RevenueCat user ID
            // After logIn(userId), the RevenueCat app user ID is now the userId
            // We use userId directly since that's what we set with logIn()
            let revenueCatUserId = userId
            
            // Ensure user_subscriptions record exists first
            await SubscriptionService.shared.ensureUserSubscriptionRecord()
            
            // Update user_subscriptions with RevenueCat user ID
            let dateFormatter = ISO8601DateFormatter()
            dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            
            let updateData: [String: String?] = [
                "revenuecat_user_id": revenueCatUserId,
                "updated_at": dateFormatter.string(from: Date())
            ]
            
            _ = try await SupabaseManager.shared.client
                .from("user_subscriptions")
                .update(updateData)
                .eq("user_id", value: userId)
                .execute()
            
            DebugLogger.log("✅ Updated database with RevenueCat user ID")
            
            // Also sync the full subscription status
            _ = await SubscriptionService.shared.fetchSubscriptionStatus(forceRefresh: true)
        } catch {
            DebugLogger.error("Failed to set RevenueCat user ID: \(error)")
        }
    }

}

