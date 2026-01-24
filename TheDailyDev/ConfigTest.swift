import Foundation

struct ConfigTest {
    static func testConfiguration() {
        DebugLogger.log("🔍 Testing Supabase Configuration...")
        
        // Test if Config-Secrets.plist exists
        guard let path = Bundle.main.path(forResource: "Config-Secrets", ofType: "plist") else {
            DebugLogger.error("Config-Secrets.plist not found in bundle")
            return
        }
        DebugLogger.log("✅ Config-Secrets.plist found at: \(path)")
        
        // Test if plist can be read
        guard let plist = NSDictionary(contentsOfFile: path) else {
            DebugLogger.error("Failed to read Config-Secrets.plist")
            return
        }
        DebugLogger.log("✅ Config-Secrets.plist loaded successfully")
        
        // Test SUPABASE_URL
        guard let url = plist["SUPABASE_URL"] as? String else {
            DebugLogger.error("SUPABASE_URL not found in Config-Secrets.plist")
            return
        }
        DebugLogger.log("✅ SUPABASE_URL found: \(url)")
        
        // Test SUPABASE_KEY
        guard let key = plist["SUPABASE_KEY"] as? String else {
            DebugLogger.error("SUPABASE_KEY not found in Config-Secrets.plist")
            return
        }
        DebugLogger.log("✅ SUPABASE_KEY found")
        
        // Test URL format
        if url.hasPrefix("https://") && url.contains(".supabase.co") {
            DebugLogger.log("✅ URL format looks correct")
        } else {
            DebugLogger.error("URL format looks incorrect. Should be: https://[project-id].supabase.co")
        }
        
        DebugLogger.log("🔍 Configuration test completed!")
    }
}
