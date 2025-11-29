//
//  AuthManager.swift
//  TheDailyDev
//
//  Created by Claire Knutson on 10/28/25.
//

import Foundation
import Supabase
import SwiftUI

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
    func signOut() async throws {
        try await SupabaseManager.shared.client.auth.signOut()
        
        // Clear shared services state
        await MainActor.run {
            SubscriptionService.shared.currentSubscription = nil
            QuestionService.shared.todaysQuestion = nil
            QuestionService.shared.errorMessage = nil
            isAuthenticated = false
            isCheckingAuth = false // Ensure we're not in checking state after sign out
        }
    }
    
    // MARK: - Handle OAuth Callback
    func handleOAuthCallback(url: URL) async {
        do {
            // Extract the session from the callback URL
            try await SupabaseManager.shared.client.auth.session(from: url)
            
            // Ensure user_subscriptions record exists
            await SubscriptionService.shared.ensureUserSubscriptionRecord()
            
            await MainActor.run {
                isAuthenticated = true
                isCheckingAuth = false
            }
        } catch {
            print("❌ Failed to establish OAuth session: \(error)")
            await MainActor.run {
                isAuthenticated = false
                isCheckingAuth = false
            }
        }
    }
}

