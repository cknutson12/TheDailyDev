import SwiftUI

struct EmailVerificationView: View {
    let email: String
    let onResend: () async -> Void
    let onRetry: () async -> Void
    
    @State private var isResending = false
    @State private var resendMessage = ""
    @State private var isRetrying = false
    
    var body: some View {
        ZStack {
            Color.theme.background.ignoresSafeArea()
            
            VStack(spacing: 24) {
                Spacer()
                
                // Icon
                Image(systemName: "envelope.fill")
                    .font(.system(size: 60))
                    .foregroundColor(Theme.Colors.accentGreen)
                
                // Title
                Text("Check your email")
                    .font(.title)
                    .bold()
                    .foregroundColor(Theme.Colors.textPrimary)
                
                // Message
                VStack(spacing: 8) {
                    Text("We've sent a verification link to")
                        .font(.body)
                        .foregroundColor(Theme.Colors.textSecondary)
                    
                    Text(email)
                        .font(.headline)
                        .foregroundColor(Theme.Colors.textPrimary)
                }
                .multilineTextAlignment(.center)
                .padding(.horizontal)
                
                // Info
                Text("Click the link in the email to verify your account")
                    .font(.caption)
                    .foregroundColor(Theme.Colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                Spacer()
                
                // Actions
                VStack(spacing: 12) {
                    // Resend button
                    Button(action: {
                        Task {
                            await resendEmail()
                        }
                    }) {
                        if isResending {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                                .tint(Theme.Colors.textPrimary)
                        } else {
                            Text("Resend verification email")
                                .font(.headline)
                        }
                    }
                    .buttonStyle(SecondaryButtonStyle())
                    .disabled(isResending)
                    
                    // Retry button
                    Button(action: {
                        Task {
                            await retryLogin()
                        }
                    }) {
                        if isRetrying {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                                .tint(.black)
                        } else {
                            Text("I've verified, try again")
                                .font(.headline)
                        }
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .disabled(isRetrying)
                    
                    // Resend message
                    if !resendMessage.isEmpty {
                        Text(resendMessage)
                            .font(.caption)
                            .foregroundColor(resendMessage.contains("✅") ? Theme.Colors.stateCorrect : Theme.Colors.stateIncorrect)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                }
                .padding(.horizontal)
                
                Spacer()
            }
        }
        .preferredColorScheme(.dark)
    }
    
    private func resendEmail() async {
        isResending = true
        resendMessage = ""
        
        do {
            try await SupabaseManager.shared.resendVerificationEmail(email: email)
            await MainActor.run {
                resendMessage = "✅ Verification email sent! Check your inbox."
                isResending = false
            }
        } catch {
            await MainActor.run {
                resendMessage = "Failed to resend email: \(error.localizedDescription)"
                isResending = false
            }
        }
    }
    
    private func retryLogin() async {
        isRetrying = true
        
        do {
            // Check if email is now verified by trying to get session
            let session = try await SupabaseManager.shared.client.auth.session
            if session.user.emailConfirmedAt != nil {
                // Email is verified, proceed with retry
                await onRetry()
            } else {
                // Still not verified
                await MainActor.run {
                    resendMessage = "Email not yet verified. Please check your inbox and click the verification link."
                }
            }
            await MainActor.run {
                isRetrying = false
            }
        } catch {
            await MainActor.run {
                resendMessage = "Failed to check verification status: \(error.localizedDescription)"
                isRetrying = false
            }
        }
    }
}

