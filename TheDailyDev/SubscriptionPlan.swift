import Foundation

// MARK: - Subscription Plan Model
struct SubscriptionPlan: Codable, Identifiable {
    let id: UUID
    let name: String
    let stripePriceId: String
    let priceAmount: Double
    let currency: String
    let billingPeriod: String
    let isActive: Bool
    let trialDays: Int
    let displayName: String?
    let description: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case stripePriceId = "stripe_price_id"
        case priceAmount = "price_amount"
        case currency
        case billingPeriod = "billing_period"
        case isActive = "is_active"
        case trialDays = "trial_days"
        case displayName = "display_name"
        case description
    }
    
    // MARK: - Computed Properties
    
    /// Formatted price string (e.g., "$4.99/month")
    var formattedPrice: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency.uppercased()
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        
        let priceString = formatter.string(from: NSNumber(value: priceAmount)) ?? "$\(priceAmount)"
        
        if billingPeriod == "month" {
            return "\(priceString)/month"
        } else if billingPeriod == "year" {
            return "\(priceString)/year"
        }
        return priceString
    }
    
    /// Price without billing period (e.g., "$4.99")
    var formattedPriceAmount: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency.uppercased()
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        
        return formatter.string(from: NSNumber(value: priceAmount)) ?? "$\(priceAmount)"
    }
    
    /// Trial description (e.g., "7 Days Free, Then $4.99/Month")
    var trialDescription: String {
        if trialDays > 0 {
            return "\(trialDays) Days Free, Then \(formattedPrice)"
        }
        return formattedPrice
    }
}

