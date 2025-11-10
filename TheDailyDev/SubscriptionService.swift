//
//  SubscriptionService.swift
//  TheDailyDev
//
//  Created by Claire Knutson on 10/25/25.
//

import Foundation
import Supabase

class SubscriptionService: ObservableObject {
    static let shared = SubscriptionService()
    
    @Published var currentSubscription: UserSubscription?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // Cache management
    private var lastFetchTime: Date?
    private let cacheTimeout: TimeInterval = 300 // 5 minutes
    
    private init() {}
    
    // MARK: - Cache Invalidation
    /// Force next fetch to bypass cache - call after critical actions like purchase/answer
    func invalidateCache() {
        lastFetchTime = nil
        print("🔄 Cache invalidated - next fetch will be fresh")
    }
    
    // MARK: - Extract Name from User Metadata
    private func extractNameFromMetadata(userMetadata: [String: Any]) -> (String?, String?) {
        var firstName: String?
        var lastName: String?
        
        // Try multiple possible name fields from OAuth providers and auth.users
        let nameFields = ["full_name", "name", "display_name", "displayName", "fullName"]
        var fullName: String?
        
        for field in nameFields {
            if let nameValue = userMetadata[field] {
                // Try direct String cast first
                if let name = nameValue as? String, !name.isEmpty {
                    fullName = name
                    break
                }
                
                // If not String, try converting AnyJSON using string description
                // AnyJSON's description should give us the underlying value
                let stringValue = String(describing: nameValue)
                if !stringValue.isEmpty && stringValue != "nil" && !stringValue.hasPrefix("AnyJSON") {
                    fullName = stringValue
                    break
                }
            }
        }
        
        if let fullName = fullName {
            let parts = fullName.split(separator: " ", maxSplits: 1, omittingEmptySubsequences: true)
            firstName = parts.isEmpty ? nil : String(parts[0])
            lastName = parts.count > 1 ? String(parts[1]) : nil
        }
        
        return (firstName, lastName)
    }
    
    // MARK: - Ensure User Subscription Record Exists
    func ensureUserSubscriptionRecord() async {
        do {
            let session = try await SupabaseManager.shared.client.auth.session
            let userId = session.user.id.uuidString
            
            // Extract name from user metadata (from auth.users table)
            var firstName: String?
            var lastName: String?
            
            // Try to get display_name from userMetadata
            if let userMetadata = session.user.userMetadata as? [String: Any] {
                let extracted = extractNameFromMetadata(userMetadata: userMetadata)
                firstName = extracted.0
                lastName = extracted.1
            }
            
            // Check if record already exists
            let existing: [UserSubscription] = try await SupabaseManager.shared.client
                .from("user_subscriptions")
                .select()
                .eq("user_id", value: userId)
                .limit(1)
                .execute()
                .value
            
            if existing.isEmpty {
                // Create the record with extracted name
                _ = try await SupabaseManager.shared.client
                    .from("user_subscriptions")
                    .insert([
                        "user_id": userId,
                        "first_name": firstName,
                        "last_name": lastName,
                        "status": "inactive"
                    ])
                    .execute()
                
            } else {
                // Record exists - update it if name is missing but now available
                if let existingRecord = existing.first {
                    let needsUpdate = (existingRecord.firstName == nil || existingRecord.firstName?.isEmpty == true) && firstName != nil ||
                                      (existingRecord.lastName == nil || existingRecord.lastName?.isEmpty == true) && lastName != nil
                    
                    if needsUpdate {
                        var updateData: [String: String?] = [:]
                        if (existingRecord.firstName == nil || existingRecord.firstName?.isEmpty == true) && firstName != nil {
                            updateData["first_name"] = firstName
                        }
                        if (existingRecord.lastName == nil || existingRecord.lastName?.isEmpty == true) && lastName != nil {
                            updateData["last_name"] = lastName
                        }
                        
                        if !updateData.isEmpty {
                            _ = try await SupabaseManager.shared.client
                                .from("user_subscriptions")
                                .update(updateData)
                                .eq("user_id", value: userId)
                                .execute()
                            
                        }
                    }
                }
            }
        } catch {
            print("❌ Failed to ensure user_subscriptions record: \(error)")
            // Don't throw - this is a background operation
        }
    }
    
    // MARK: - Fetch User Subscription
    func fetchSubscriptionStatus(forceRefresh: Bool = false) async -> UserSubscription? {
        // Check cache first (unless force refresh)
        if !forceRefresh,
           let lastFetch = lastFetchTime,
           let cached = currentSubscription,
           Date().timeIntervalSince(lastFetch) < cacheTimeout {
            print("✅ Using cached subscription (age: \(Int(Date().timeIntervalSince(lastFetch)))s)")
            return cached
        }
        
        print("🔄 Fetching fresh subscription status...")
        
        do {
            let session = try await SupabaseManager.shared.client.auth.session
            let userId = session.user.id.uuidString
            
            let subscriptions: [UserSubscription] = try await SupabaseManager.shared.client
                .from("user_subscriptions")
                .select()
                .eq("user_id", value: userId)
                .order("created_at", ascending: false)
                .limit(1)
                .execute()
                .value
            
            await MainActor.run {
                self.currentSubscription = subscriptions.first
                self.lastFetchTime = Date()
            }
            
            print("✅ Subscription status updated: \(subscriptions.first?.status ?? "none")")
            
            return subscriptions.first
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to fetch subscription: \(error.localizedDescription)"
            }
            print("❌ Failed to fetch subscription status: \(error)")
            return nil
        }
    }
    
    // MARK: - Create Checkout Session
    func createCheckoutSession() async throws -> URL {
        guard let functionURL = getFunctionURL(functionName: "create-checkout-session") else {
            print("❌ Failed to get function URL")
            throw SubscriptionError.invalidConfiguration
        }
        
        let session = try await SupabaseManager.shared.client.auth.session
        let userId = session.user.id.uuidString
        
        var request = URLRequest(url: functionURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(session.accessToken)", 
                        forHTTPHeaderField: "Authorization")
        
        let body = [
            "user_id": userId,
            "price_id": "price_1SREPsK9eNlBD1eEdAJAAhlc"
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            print("❌ Invalid response type")
            throw SubscriptionError.networkError
        }
        
        guard httpResponse.statusCode == 200 else {
            print("❌ Non-200 status code: \(httpResponse.statusCode)")
            throw SubscriptionError.networkError
        }
        
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            print("❌ Failed to parse JSON")
            throw SubscriptionError.invalidResponse
        }
        
        guard let checkoutURLString = json["url"] as? String else {
            print("❌ 'url' key not found in response")
            throw SubscriptionError.invalidResponse
        }
        
        guard let checkoutURL = URL(string: checkoutURLString) else {
            print("❌ Invalid URL string: \(checkoutURLString)")
            throw SubscriptionError.invalidResponse
        }
        
        return checkoutURL
    }
    
    // MARK: - Initiate Trial Setup (Step 1: Collect Payment Method)
    func initiateTrialSetup() async throws -> URL {
        guard let functionURL = getFunctionURL(functionName: "initiate-trial") else {
            print("❌ Failed to get function URL")
            throw SubscriptionError.invalidConfiguration
        }
        
        let session = try await SupabaseManager.shared.client.auth.session
        let userId = session.user.id.uuidString
        let email = session.user.email ?? ""
        
        var request = URLRequest(url: functionURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(session.accessToken)",
                        forHTTPHeaderField: "Authorization")
        
        let body = [
            "user_id": userId,
            "email": email
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            print("❌ Invalid response type")
            throw SubscriptionError.networkError
        }
        
        guard httpResponse.statusCode == 200 else {
            print("❌ Non-200 status code: \(httpResponse.statusCode)")
            throw SubscriptionError.networkError
        }
        
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            print("❌ Failed to parse JSON")
            throw SubscriptionError.invalidResponse
        }
        
        guard let checkoutURLString = json["url"] as? String else {
            print("❌ 'url' key not found in response")
            throw SubscriptionError.invalidResponse
        }
        
        guard let checkoutURL = URL(string: checkoutURLString) else {
            print("❌ Invalid URL string: \(checkoutURLString)")
            throw SubscriptionError.invalidResponse
        }
        
        return checkoutURL
    }
    
    // MARK: - Complete Trial Setup (Step 2: Create Subscription with Trial)
    func completeTrialSetup(sessionId: String) async throws {
        guard let functionURL = getFunctionURL(functionName: "complete-trial-setup") else {
            print("❌ Failed to get function URL")
            throw SubscriptionError.invalidConfiguration
        }
        
        let session = try await SupabaseManager.shared.client.auth.session
        let userId = session.user.id.uuidString
        
        var request = URLRequest(url: functionURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(session.accessToken)",
                        forHTTPHeaderField: "Authorization")
        
        let body = [
            "user_id": userId,
            "session_id": sessionId,
            "price_id": "price_1SREPsK9eNlBD1eEdAJAAhlc"
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw SubscriptionError.networkError
        }
        
        // Refresh subscription status
        await fetchSubscriptionStatus()
    }
    
    // MARK: - Check if User Can Access Questions
    func canAccessQuestions() async -> Bool {
        // 1. Check subscription/trial status
        if currentSubscription?.isActive == true {
            return true
        }
        
        // 2. Check if they've never answered (first free question)
        let hasAnswered = await QuestionService.shared.hasAnsweredAnyQuestion()
        if !hasAnswered {
            return true
        }
        
        // 3. Check if it's Friday
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: Date())
        if weekday == 6 { // Friday
            return true
        }
        
        // 4. Otherwise, need subscription
        return false
    }
    
    // MARK: - Get Function URL
    private func getFunctionURL(functionName: String) -> URL? {
        return Config.getFunctionURL(functionName: functionName)
    }
    
    // MARK: - Cancel Subscription
    func cancelSubscription() async throws {
        guard let subscription = currentSubscription,
              let stripeSubscriptionId = subscription.stripeSubscriptionId,
              let functionURL = getFunctionURL(functionName: "cancel-subscription") else {
            throw SubscriptionError.noActiveSubscription
        }
        
        let session = try await SupabaseManager.shared.client.auth.session
        
        var request = URLRequest(url: functionURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(session.accessToken)", 
                        forHTTPHeaderField: "Authorization")
        
        let body = ["subscription_id": stripeSubscriptionId]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw SubscriptionError.networkError
        }
        
        // Refresh subscription status
        await fetchSubscriptionStatus()
    }
    
    // MARK: - Get Billing Portal URL
    func getBillingPortalURL() async throws -> URL {
        // Make sure we have a subscription
        await fetchSubscriptionStatus()
        
        guard let subscription = currentSubscription else {
            print("❌ No subscription found")
            throw SubscriptionError.noActiveSubscription
        }
        
        guard let stripeCustomerId = subscription.stripeCustomerId else {
            print("❌ No Stripe customer ID")
            throw SubscriptionError.noActiveSubscription
        }
        
        guard let functionURL = getFunctionURL(functionName: "create-billing-portal-session") else {
            print("❌ Failed to get function URL")
            throw SubscriptionError.invalidConfiguration
        }
        
        let session = try await SupabaseManager.shared.client.auth.session
        
        var request = URLRequest(url: functionURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(session.accessToken)", 
                        forHTTPHeaderField: "Authorization")
        
        let body = ["customer_id": stripeCustomerId]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            print("❌ Invalid response type")
            throw SubscriptionError.networkError
        }
        
        guard httpResponse.statusCode == 200 else {
            print("❌ Non-200 status code: \(httpResponse.statusCode)")
            throw SubscriptionError.networkError
        }
        
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            print("❌ Failed to parse JSON")
            throw SubscriptionError.invalidResponse
        }
        
        guard let urlString = json["url"] as? String else {
            print("❌ 'url' key not found in response")
            throw SubscriptionError.invalidResponse
        }
        
        guard let url = URL(string: urlString) else {
            print("❌ Invalid URL string: \(urlString)")
            throw SubscriptionError.invalidResponse
        }
        
        return url
    }
}

// MARK: - Subscription Errors
enum SubscriptionError: Error, LocalizedError {
    case invalidConfiguration
    case networkError
    case invalidResponse
    case noActiveSubscription
    
    var errorDescription: String? {
        switch self {
        case .invalidConfiguration:
            return "Subscription service not properly configured"
        case .networkError:
            return "Network error. Please try again."
        case .invalidResponse:
            return "Invalid response from server"
        case .noActiveSubscription:
            return "No active subscription found"
        }
    }
}
