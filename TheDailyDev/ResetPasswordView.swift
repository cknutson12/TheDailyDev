import SwiftUI
import Supabase

struct ResetPasswordView: View {
    @Environment(\.dismiss) private var dismiss
    
    let resetToken: String?
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var isLoading = false
    @State private var message = ""
    @State private var isSuccess = false
    
    var body: some View {
        ZStack {
            Color.theme.background.ignoresSafeArea()
            
            NavigationView {
                VStack(spacing: 24) {
                    Spacer()
                    
                    if isSuccess {
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
            // The deep link handler should have already established a session
            // Just update the password using the current session
            try await SupabaseManager.shared.client.auth.update(user: UserAttributes(password: newPassword))
            
            // Sign out after password update
            try await SupabaseManager.shared.client.auth.signOut()
            
            await MainActor.run {
                isSuccess = true
                isLoading = false
            }
        } catch {
            await MainActor.run {
                message = "Failed to update password: \(error.localizedDescription)"
                isLoading = false
            }
        }
    }
}

