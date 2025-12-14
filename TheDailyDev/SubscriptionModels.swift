//
//  SubscriptionModels.swift
//  TheDailyDev
//
//  Created by Claire Knutson on 10/25/25.
//

import Foundation

// MARK: - User Subscription
struct UserSubscription: Codable, Identifiable {
    let id: String
    let userId: String
    let firstName: String?
    let lastName: String?
    // RevenueCat fields
    let revenueCatUserId: String?
    let revenueCatSubscriptionId: String?
    let entitlementStatus: String?
    let originalTransactionId: String?
    // Shared fields
    let status: String
    let currentPeriodEnd: String?
    let trialEnd: String?
    let createdAt: String
    let updatedAt: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case firstName = "first_name"
        case lastName = "last_name"
        case revenueCatUserId = "revenuecat_user_id"
        case revenueCatSubscriptionId = "revenuecat_subscription_id"
        case entitlementStatus = "entitlement_status"
        case originalTransactionId = "original_transaction_id"
        case status
        case currentPeriodEnd = "current_period_end"
        case trialEnd = "trial_end"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    /// Determines if the user has active subscription access
    /// Checks both status and entitlement_status to handle all RevenueCat states
    var isActive: Bool {
        // Check subscription status - these indicate user should have access
        let hasActiveStatus = ["active", "trialing", "past_due", "paused"].contains(status)
        
        // Check entitlement status - these indicate user has access
        // If entitlement_status is nil, assume active for backward compatibility
        let hasActiveEntitlement: Bool
        if let entitlementStatus = entitlementStatus {
            hasActiveEntitlement = ["active", "billing_issue", "paused"].contains(entitlementStatus)
        } else {
            // Backward compatibility: if entitlement_status is nil, check status only
            hasActiveEntitlement = hasActiveStatus
        }
        
        // User has access if both status and entitlement are active
        return hasActiveStatus && hasActiveEntitlement
    }
    
    var isInTrial: Bool {
        guard status == "trialing", let trialEndString = trialEnd else {
            return false
        }
        
        guard let trialEndDate = ISO8601DateFormatter().date(from: trialEndString) else {
            return false
        }
        
        return trialEndDate > Date()
    }
    
    // Get full name
    var fullName: String {
        let parts = [firstName, lastName].compactMap { $0 }.filter { !$0.isEmpty }
        return parts.isEmpty ? "User" : parts.joined(separator: " ")
    }
    
    // Get access status message
    var accessStatusMessage: String {
        // Handle trial status
        if isInTrial {
            if let trialEndString = trialEnd,
               let trialEndDate = ISO8601DateFormatter().date(from: trialEndString) {
                let formatter = DateFormatter()
                formatter.dateStyle = .medium
                return "Free trial until \(formatter.string(from: trialEndDate))"
            }
            return "Free trial active"
        }
        
        // Handle different subscription statuses
        switch status {
        case "active":
            return "Active subscription"
            
        case "trialing":
            return "Free trial active"
            
        case "past_due":
            return "Payment issue - please update payment method"
            
        case "paused":
            return "Subscription paused"
            
        case "inactive":
            // Check entitlement_status for more context
            if entitlementStatus == "expired" {
                return "Subscription expired"
            } else if entitlementStatus == "billing_issue" {
                return "Payment issue - please update payment method"
            } else {
                return "Subscription required"
            }
            
        default:
            // Unknown status - default message
            return "Subscription required"
        }
    }
    
    // Format billing date
    func formattedBillingDate() -> String? {
        guard let dateString = currentPeriodEnd,
              let date = ISO8601DateFormatter().date(from: dateString) else {
            return nil
        }
        
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

// MARK: - Subscription Benefits
struct SubscriptionBenefit: Identifiable {
    let id = UUID()
    let title: String
    let description: String?
}

extension SubscriptionBenefit {
    static let allBenefits: [SubscriptionBenefit] = [
        SubscriptionBenefit(
            title: "Unlimited daily questions",
            description: "Access to a new system design question every day"
        ),
        SubscriptionBenefit(
            title: "Progress tracking",
            description: "Track your answers and see your improvement over time"
        ),
        SubscriptionBenefit(
            title: "Performance analytics",
            description: "Detailed analytics showing your strengths by category"
        ),
        SubscriptionBenefit(
            title: "Historical insights",
            description: "Review all your past questions and learn from mistakes"
        )
    ]
}
