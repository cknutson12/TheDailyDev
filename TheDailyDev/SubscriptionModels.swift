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
    let stripeCustomerId: String?
    let stripeSubscriptionId: String?
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
        case stripeCustomerId = "stripe_customer_id"
        case stripeSubscriptionId = "stripe_subscription_id"
        case status
        case currentPeriodEnd = "current_period_end"
        case trialEnd = "trial_end"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    var isActive: Bool {
        status == "active" || status == "trialing"
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
        if isInTrial {
            if let trialEndString = trialEnd,
               let trialEndDate = ISO8601DateFormatter().date(from: trialEndString) {
                let formatter = DateFormatter()
                formatter.dateStyle = .medium
                return "Free trial until \(formatter.string(from: trialEndDate))"
            }
            return "Free trial active"
        }
        
        if status == "active" {
            return "Active subscription"
        }
        
        return "Subscription required"
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
