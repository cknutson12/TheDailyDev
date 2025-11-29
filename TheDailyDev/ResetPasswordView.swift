import SwiftUI
import Supabase

struct ResetPasswordView: View {
    @Environment(\.dismiss) private var dismiss
    
    let resetCode: String
    
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var isLoading = false
    @State private var message = ""
    @State private var isSuccess = false
    @State private var isValidatingToken = true
    @State private var tokenValid = false
    
    var body: some View {
        ZStack {
            Color.theme.background.ignoresSafeArea()
            
            NavigationView {
                VStack(spacing: 24) {
                    Spacer()
                    
                    if isValidatingToken {
                        // Validating token
                        VStack(spacing: 16) {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                                .scaleEffect(1.5)
                            
                            Text("Validating reset link...")
                                .font(.headline)
                                .foregroundColor(Theme.Colors.textPrimary)
                        }
                        .padding()
                        .onAppear {
                            Task {
                                await validateToken()
                            }
                        }
                    } else if !tokenValid {
                        // Token validation failed
                        VStack(spacing: 16) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 50))
                                .foregroundColor(Theme.Colors.stateIncorrect)
                            
                            Text("Invalid Reset Link")
                                .font(.title)
                                .bold()
                                .foregroundColor(Theme.Colors.textPrimary)
                            
                            Text(message.isEmpty ? "This password reset link is invalid or has expired. Please request a new one." : message)
                                .font(.body)
                                .foregroundColor(Theme.Colors.textSecondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                            
                            Button(action: {
                                dismiss()
                            }) {
                                Text("Close")
                                    .font(.headline)
                            }
                            .buttonStyle(PrimaryButtonStyle())
                            .padding(.horizontal)
                            .padding(.top)
                        }
                        .padding()
                    } else if isSuccess {
                        // Success state
                        VStack(spacing: 16) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 60))
                                .foregroundColor(Theme.Colors.stateCorrect)
                            
                            Text("Password Updated")
                                .font(.title)
                                .bold()
                                .foregroundColor(Theme.Colors.textPrimary)
                            
                            Text("Your password has been successfully updated. Please sign in with your new password.")
                                .font(.body)
                                .foregroundColor(Theme.Colors.textSecondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                            
                            Button(action: {
                                dismiss()
                            }) {
                                Text("Sign In")
                                    .font(.headline)
                            }
                            .buttonStyle(PrimaryButtonStyle())
                            .padding(.horizontal)
                            .padding(.top)
                        }
                        .padding()
                    } else {
                        // Password input
                        VStack(spacing: 16) {
                            // Icon
                            Image(systemName: "lock.fill")
                                .font(.system(size: 50))
                                .foregroundColor(Theme.Colors.accentGreen)
                            
                            Text("Set New Password")
                                .font(.title)
                                .bold()
                                .foregroundColor(Theme.Colors.textPrimary)
                            
                            VStack(spacing: 12) {
                                SecureField("New Password", text: $newPassword)
                                    .textFieldStyle(DarkTextFieldStyle())
                                    .disabled(isLoading)
                                
                                SecureField("Confirm Password", text: $confirmPassword)
                                    .textFieldStyle(DarkTextFieldStyle())
                                    .disabled(isLoading)
                                
                                if !message.isEmpty {
                                    Text(message)
                                        .font(.caption)
                                        .foregroundColor(Theme.Colors.stateIncorrect)
                                        .multilineTextAlignment(.center)
                                }
                                
                                Button(action: {
                                    Task {
                                        await updatePassword()
                                    }
                                }) {
                                    if isLoading {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle())
                                            .tint(.black)
                                    } else {
                                        Text("Update Password")
                                            .font(.headline)
                                    }
                                }
                                .buttonStyle(PrimaryButtonStyle())
                                .disabled(isLoading || newPassword.isEmpty || confirmPassword.isEmpty)
                            }
                            .cardContainer()
                            .padding(.horizontal)
                        }
                    }
                    
                    Spacer()
                }
                .navigationTitle("Reset Password")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Cancel") {
                            dismiss()
                        }
                        .foregroundColor(Theme.Colors.textPrimary)
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
    }
    
    private func validateToken() async {
        // Code was already validated in TheDailyDevApp when establishing session
        // Check if we have a valid session instead of re-exchanging the code
        // (codes can only be exchanged once)
        do {
            // Check if there's an active session (established by the code exchange)
            _ = try await SupabaseManager.shared.client.auth.session
            print("✅ Valid session found - code was already validated")
            
            await MainActor.run {
                tokenValid = true
                isValidatingToken = false
            }
        } catch {
            // No session found - try to exchange the code one more time as fallback
            print("⚠️ No active session found, attempting code exchange...")
            do {
                _ = try await SupabaseManager.shared.client.auth.exchangeCodeForSession(authCode: resetCode)
                print("✅ Code exchange successful")
                await MainActor.run {
                    tokenValid = true
                    isValidatingToken = false
                }
            } catch {
                print("❌ Code validation failed: \(error)")
                await MainActor.run {
                    tokenValid = false
                    isValidatingToken = false
                    message = "This password reset link is invalid or has expired. Please request a new one."
                }
            }
        }
    }
    
    private func updatePassword() async {
        // Validate passwords match
        guard newPassword == confirmPassword else {
            await MainActor.run {
                message = "Passwords do not match"
            }
            return
        }
        
        // Validate password length
        guard newPassword.count >= 6 else {
            await MainActor.run {
                message = "Password must be at least 6 characters"
            }
            return
        }
        
        isLoading = true
        message = ""
        
        do {
            // Check if we have a valid session (from the code exchange)
            // If not, try to exchange the code one more time
            var hasSession = false
            do {
                _ = try await SupabaseManager.shared.client.auth.session
                hasSession = true
                print("✅ Using existing session for password update")
            } catch {
                print("⚠️ No session found, attempting code exchange...")
                _ = try await SupabaseManager.shared.client.auth.exchangeCodeForSession(authCode: resetCode)
                hasSession = true
                print("✅ Code exchange successful")
            }
            
            guard hasSession else {
                throw NSError(domain: "PasswordReset", code: 401, userInfo: [NSLocalizedDescriptionKey: "No valid session"])
            }
            
            // Update password using the validated session
            try await SupabaseManager.shared.client.auth.update(user: UserAttributes(password: newPassword))
            
            // Sign out after password update (code is now invalidated)
            try await SupabaseManager.shared.client.auth.signOut()
            
            await MainActor.run {
                isSuccess = true
                isLoading = false
            }
        } catch {
            await MainActor.run {
                let errorString = error.localizedDescription.lowercased()
                if errorString.contains("expired") || errorString.contains("invalid") {
                    message = "This reset link has expired or is invalid. Please request a new one."
                } else {
                    message = "Failed to update password: \(error.localizedDescription)"
                }
                isLoading = false
            }
        }
    }
}

