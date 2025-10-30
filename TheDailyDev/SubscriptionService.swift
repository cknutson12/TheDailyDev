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
    
    private init() {}
    
    // MARK: - Fetch User Subscription
    func fetchSubscriptionStatus() async -> UserSubscription? {
        do {
            print("🔍 Fetching subscription status...")
            let session = try await SupabaseManager.shared.client.auth.session
            let userId = session.user.id.uuidString
            print("✅ User ID: \(userId)")
            
            let subscriptions: [UserSubscription] = try await SupabaseManager.shared.client
                .from("user_subscriptions")
                .select()
                .eq("user_id", value: userId)
                .order("created_at", ascending: false)
                .limit(1)
                .execute()
                .value
            
            print("📊 Found \(subscriptions.count) subscription(s)")
            
            if let subscription = subscriptions.first {
                print("✅ Subscription status: \(subscription.status)")
                print("📅 Current period end: \(subscription.currentPeriodEnd ?? "none")")
            }
            
            await MainActor.run {
                self.currentSubscription = subscriptions.first
            }
            
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
        print("🔧 Getting function URL...")
        guard let functionURL = getFunctionURL(functionName: "create-checkout-session") else {
            print("❌ Failed to get function URL")
            throw SubscriptionError.invalidConfiguration
        }
        
        print("✅ Function URL: \(functionURL)")
        
        print("🔐 Getting user session...")
        let session = try await SupabaseManager.shared.client.auth.session
        let userId = session.user.id.uuidString
        print("✅ User ID: \(userId)")
        
        var request = URLRequest(url: functionURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(session.accessToken)", 
                        forHTTPHeaderField: "Authorization")
        
        let body = [
            "user_id": userId,
            "price_id": "price_1SMViRLKbK8V5YM1xkjiJfnz"
        ]
        
        print("📤 Request body: \(body)")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        print("🚀 Sending request to Edge Function...")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            print("❌ Invalid response type")
            throw SubscriptionError.networkError
        }
        
        print("📡 Edge Function response status: \(httpResponse.statusCode)")
        
        // Log response data for debugging
        if let responseString = String(data: data, encoding: .utf8) {
            print("📄 Response data: \(responseString)")
        }
        
        guard httpResponse.statusCode == 200 else {
            print("❌ Non-200 status code: \(httpResponse.statusCode)")
            throw SubscriptionError.networkError
        }
        
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            print("❌ Failed to parse JSON")
            throw SubscriptionError.invalidResponse
        }
        
        print("✅ Parsed JSON: \(json)")
        
        guard let checkoutURLString = json["url"] as? String else {
            print("❌ 'url' key not found in response")
            print("Available keys: \(json.keys)")
            throw SubscriptionError.invalidResponse
        }
        
        guard let checkoutURL = URL(string: checkoutURLString) else {
            print("❌ Invalid URL string: \(checkoutURLString)")
            throw SubscriptionError.invalidResponse
        }
        
        return checkoutURL
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
        print("🔧 Getting billing portal URL...")
        
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
        
        print("✅ Have subscription: \(subscription.status)")
        print("✅ Customer ID: \(stripeCustomerId)")
        
        guard let functionURL = getFunctionURL(functionName: "create-billing-portal-session") else {
            print("❌ Failed to get function URL")
            throw SubscriptionError.invalidConfiguration
        }
        
        print("✅ Function URL: \(functionURL)")
        print("📋 Customer ID: \(stripeCustomerId)")
        
        let session = try await SupabaseManager.shared.client.auth.session
        
        var request = URLRequest(url: functionURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(session.accessToken)", 
                        forHTTPHeaderField: "Authorization")
        
        let body = ["customer_id": stripeCustomerId]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        print("🚀 Sending request to Edge Function...")
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            print("❌ Invalid response type")
            throw SubscriptionError.networkError
        }
        
        print("📡 Edge Function response status: \(httpResponse.statusCode)")
        
        // Log response data for debugging
        if let responseString = String(data: data, encoding: .utf8) {
            print("📄 Response data: \(responseString)")
        }
        
        guard httpResponse.statusCode == 200 else {
            print("❌ Non-200 status code: \(httpResponse.statusCode)")
            throw SubscriptionError.networkError
        }
        
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            print("❌ Failed to parse JSON")
            throw SubscriptionError.invalidResponse
        }
        
        print("✅ Parsed JSON: \(json)")
        
        guard let urlString = json["url"] as? String else {
            print("❌ 'url' key not found in response")
            print("Available keys: \(json.keys)")
            throw SubscriptionError.invalidResponse
        }
        
        print("✅ Portal URL: \(urlString)")
        
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
