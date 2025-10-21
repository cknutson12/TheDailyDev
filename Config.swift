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
}
