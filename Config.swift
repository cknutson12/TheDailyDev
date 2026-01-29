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
            #if DEBUG
            // Fallback to test key if not in plist (for development)
            return "test_vWiKnNMjHYYzrbfAPbKvqqsYhgE"
            #else
            fatalError("REVENUECAT_API_KEY not found in Config-Secrets.plist for release build")
            #endif
        }
        return key
    }
    
    // MARK: - PostHog Configuration
    static var postHogAPIKey: String {
        guard let path = Bundle.main.path(forResource: "Config-Secrets", ofType: "plist"),
              let plist = NSDictionary(contentsOfFile: path),
              let key = plist["POSTHOG_API_KEY"] as? String else {
            #if DEBUG
            DebugLogger.log("⚠️ POSTHOG_API_KEY not found in Config-Secrets.plist")
            return ""
            #else
            fatalError("POSTHOG_API_KEY not found in Config-Secrets.plist")
            #endif
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
    static var privacyPolicyURL: String {
        return "https://thedailydevweb.vercel.app/privacy-policy"
    }
    
    static var termsOfServiceURL: String {
        return "https://thedailydevweb.vercel.app/terms-of-service"
    }
}
