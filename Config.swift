import Foundation

struct Config {
    // MARK: - Supabase Configuration
    static var supabaseURL: String {
        guard let path = Bundle.main.path(forResource: "Config-Secrets", ofType: "plist"),
              let plist = NSDictionary(contentsOfFile: path),
              let url = plist["SUPABASE_URL"] as? String else {
            fatalError("SUPABASE_URL not found in Config-Secrets.plist")
        }
        return url
    }
    
    static var supabaseKey: String {
        guard let path = Bundle.main.path(forResource: "Config-Secrets", ofType: "plist"),
              let plist = NSDictionary(contentsOfFile: path),
              let key = plist["SUPABASE_KEY"] as? String else {
            fatalError("SUPABASE_KEY not found in Config-Secrets.plist")
        }
        return key
    }
    
    // MARK: - Helper to get function URL
    static func getFunctionURL(functionName: String) -> URL? {
        return URL(string: "\(supabaseURL)/functions/v1/\(functionName)")
    }
    
    // MARK: - RevenueCat Configuration
    static var revenueCatAPIKey: String {
        guard let path = Bundle.main.path(forResource: "Config-Secrets", ofType: "plist"),
              let plist = NSDictionary(contentsOfFile: path),
              let key = plist["REVENUECAT_API_KEY"] as? String else {
            // Fallback to test key if not in plist (for development)
            return "test_vWiKnNMjHYYzrbfAPbKvqqsYhgE"
        }
        return key
    }
    
    // RevenueCat Entitlement Identifier
    // NOTE: This must match the entitlement identifier in RevenueCat dashboard
    // If you see "The Daily Dev Pro" in logs, update this to match
    static let revenueCatEntitlementID = "The Daily Dev Pro"
    
    // RevenueCat Product Identifiers (must match App Store Connect)
    static let revenueCatMonthlyProductID = "monthly"
    static let revenueCatYearlyProductID = "yearly"
    
    // MARK: - Legal URLs
    // TODO: Replace with your actual URLs once you have them hosted
    static var privacyPolicyURL: String {
        // Replace with your actual privacy policy URL
        // Example: "https://yourdomain.com/privacy-policy"
        return "https://yourdomain.com/privacy-policy" // PLACEHOLDER - UPDATE THIS
    }
    
    static var termsOfServiceURL: String {
        // Replace with your actual terms of service URL, or return empty string if not available
        // Example: "https://yourdomain.com/terms-of-service"
        return "" // PLACEHOLDER - UPDATE THIS or leave empty if not available
    }
}
