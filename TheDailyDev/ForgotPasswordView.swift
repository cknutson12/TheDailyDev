import SwiftUI

struct ForgotPasswordView: View {
    @Environment(\.dismiss) private var dismiss
    
    @State private var email = ""
    @State private var isLoading = false
    @State private var message = ""
    @State private var isSuccess = false
    
    var body: some View {
        ZStack {
            Color.theme.background.ignoresSafeArea()
            
            NavigationView {
                VStack(spacing: 24) {
                    Spacer()
                    
                    // Icon
                    Image(systemName: "lock.rotation")
                        .font(.system(size: 60))
                        .foregroundColor(Theme.Colors.accentGreen)
                    
                    // Title
                    Text("Reset Password")
                        .font(.title)
                        .bold()
                        .foregroundColor(Theme.Colors.textPrimary)
                    
                    // Message
                    Text("Enter your email address and we'll send you a link to reset your password")
                        .font(.body)
                        .foregroundColor(Theme.Colors.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    if isSuccess {
                        // Success state
                        VStack(spacing: 16) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 50))
                                .foregroundColor(Theme.Colors.stateCorrect)
                            
                            Text("Check your email")
                                .font(.title2)
                                .bold()
                                .foregroundColor(Theme.Colors.textPrimary)
                            
                            Text("We've sent password reset instructions to \(email)")
                                .font(.body)
                                .foregroundColor(Theme.Colors.textSecondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                            
                            Text("Click the link in the email to reset your password")
                                .font(.caption)
                                .foregroundColor(Theme.Colors.textSecondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                        .padding()
                        .cardContainer()
                        .padding(.horizontal)
                    } else {
                        // Email input
                        VStack(spacing: 16) {
                            TextField("Email", text: $email)
                                .textFieldStyle(DarkTextFieldStyle())
                                .textInputAutocapitalization(.never)
                                .keyboardType(.emailAddress)
                                .autocorrectionDisabled()
                                .disabled(isLoading)
                            
                            if !message.isEmpty {
                                Text(message)
                                    .font(.caption)
                                    .foregroundColor(Theme.Colors.stateIncorrect)
                                    .multilineTextAlignment(.center)
                            }
                            
                            Button(action: {
                                Task {
                                    await sendResetLink()
                                }
                            }) {
                                if isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle())
                                        .tint(.black)
                                } else {
                                    Text("Send Reset Link")
                                        .font(.headline)
                                }
                            }
                            .buttonStyle(PrimaryButtonStyle())
                            .disabled(isLoading || email.isEmpty)
                        }
                        .cardContainer()
                        .padding(.horizontal)
                    }
                    
                    Spacer()
                }
                .navigationTitle("Forgot Password")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Close") {
                            dismiss()
                        }
                        .foregroundColor(Theme.Colors.textPrimary)
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
    }
    
    private func sendResetLink() async {
        // Track password reset requested
        AnalyticsService.shared.track("password_reset_requested")
        
        isLoading = true
        message = ""
        
        do {
            try await SupabaseManager.shared.requestPasswordReset(email: email)
            await MainActor.run {
                isSuccess = true
                isLoading = false
            }
        } catch {
            print("❌ Password reset error: \(error)")
            // Check if it's a specific Supabase error
            if let errorDescription = (error as NSError).userInfo[NSLocalizedDescriptionKey] as? String {
                print("❌ Error description: \(errorDescription)")
            }
            await MainActor.run {
                var errorMessage = "Failed to send reset link: \(error.localizedDescription)"
                // Provide more helpful error messages
                if error.localizedDescription.contains("recover email") || error.localizedDescription.contains("SMTP") {
                    errorMessage = "Unable to send reset email. Please check your email address or try again later. If the problem persists, contact support."
                }
                message = errorMessage
                isLoading = false
            }
        }
    }
}

