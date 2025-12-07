import Foundation
import Supabase

class SupabaseManager {
    static let shared = SupabaseManager()
    
    let client: SupabaseClient

    private init() {
        self.client = SupabaseClient(
            supabaseURL: URL(string: Config.supabaseURL)!,
            supabaseKey: Config.supabaseKey
        )
    }
    
    // MARK: - Email Verification
    
    func resendVerificationEmail(email: String) async throws {
        // Resend verification email
        // Note: The redirect URL should be configured in Supabase dashboard
        // under Authentication > URL Configuration > Redirect URLs
        // Add: https://thedailydevweb.vercel.app/auth/verify
        // The website will then redirect to the app with a code via deep link
        try await client.auth.resend(
            email: email,
            type: .signup
        )
    }
    
    // MARK: - Password Reset
    
    func requestPasswordReset(email: String) async throws {
        // Reset password for email - this sends a recovery email
        // Use redirectTo to have Supabase redirect to your website after verification
        // The token will be in the redirect URL query parameters
        try await client.auth.resetPasswordForEmail(
            email,
            redirectTo: URL(string: "https://thedailydevweb.vercel.app/auth/reset")
        )
    }
}

