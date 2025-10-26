import Foundation

struct ConfigTest {
    static func testConfiguration() {
        print("🔍 Testing Supabase Configuration...")
        
        // Test if Config-Secrets.plist exists
        guard let path = Bundle.main.path(forResource: "Config-Secrets", ofType: "plist") else {
            print("❌ Config-Secrets.plist not found in bundle")
            return
        }
        print("✅ Config-Secrets.plist found at: \(path)")
        
        // Test if plist can be read
        guard let plist = NSDictionary(contentsOfFile: path) else {
            print("❌ Failed to read Config-Secrets.plist")
            return
        }
        print("✅ Config-Secrets.plist loaded successfully")
        
        // Test SUPABASE_URL
        guard let url = plist["SUPABASE_URL"] as? String else {
            print("❌ SUPABASE_URL not found in Config-Secrets.plist")
            return
        }
        print("✅ SUPABASE_URL found: \(url)")
        
        // Test SUPABASE_KEY
        guard let key = plist["SUPABASE_KEY"] as? String else {
            print("❌ SUPABASE_KEY not found in Config-Secrets.plist")
            return
        }
        print("✅ SUPABASE_KEY found: \(String(key.prefix(20)))...")
        
        // Test URL format
        if url.hasPrefix("https://") && url.contains(".supabase.co") {
            print("✅ URL format looks correct")
        } else {
            print("❌ URL format looks incorrect. Should be: https://[project-id].supabase.co")
        }
        
        print("🔍 Configuration test completed!")
    }
}
