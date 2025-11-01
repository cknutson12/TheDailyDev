import SwiftUI
import Supabase

struct LoginView: View {
    @Binding var isLoggedIn: Bool
    @State private var email = ""
    @State private var password = ""
    @State private var message = ""
    @State private var isLoading = false
    
    var body: some View {
        ZStack {
            Color.theme.background.ignoresSafeArea()
            VStack(spacing: 20) {
                Spacer()
                
                VStack(spacing: 16) {
                    Text("Welcome back")
                        .font(.title)
                        .bold()
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    VStack(spacing: 12) {
                        TextField("Email", text: $email)
                            .textFieldStyle(DarkTextFieldStyle())
                            .textInputAutocapitalization(.never)
                            .accessibilityIdentifier("EmailField")
                        
                        SecureField("Password", text: $password)
                            .textFieldStyle(DarkTextFieldStyle())
                            .accessibilityIdentifier("PasswordField")
                    }
                }
                .cardContainer()
                
                if !message.isEmpty {
                    Text(message)
                        .foregroundColor(Theme.Colors.stateIncorrect)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                }
                
                Button(action: { Task { await signIn() } }) {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                            .tint(.black)
                    } else {
                        Text("Sign In")
                            .bold()
                    }
                }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(isLoading)
                .accessibilityIdentifier("SignInButton")
                
                // Social Sign In
                VStack(spacing: 12) {
                    HStack {
                        Rectangle()
                            .fill(Color.theme.border)
                            .frame(height: 1)
                        
                        Text("OR")
                            .font(.caption)
                            .foregroundColor(Color.theme.textSecondary)
                            .padding(.horizontal, 8)
                        
                        Rectangle()
                            .fill(Color.theme.border)
                            .frame(height: 1)
                    }
                    .padding(.vertical, 8)
                    
                    VStack(spacing: 12) {
                        Button(action: { Task { await signInWithGoogle() } }) {
                            HStack {
                                Image(systemName: "globe")
                                    .font(.title3)
                                Text("Continue with Google")
                                    .font(.headline)
                            }
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.white)
                            .cornerRadius(Theme.Metrics.cornerRadius)
                        }
                        .accessibilityIdentifier("GoogleSignInButton")
                        
                        Button(action: { Task { await signInWithGitHub() } }) {
                            HStack {
                                Image(systemName: "chevron.left.forwardslash.chevron.right")
                                    .font(.title3)
                                Text("Continue with GitHub")
                                    .font(.headline)
                            }
                            .foregroundColor(Theme.Colors.textPrimary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Theme.Colors.surface)
                            .cornerRadius(Theme.Metrics.cornerRadius)
                            .overlay(
                                RoundedRectangle(cornerRadius: Theme.Metrics.cornerRadius)
                                    .stroke(Theme.Colors.border, lineWidth: 1)
                            )
                        }
                        .accessibilityIdentifier("GitHubSignInButton")
                    }
                }
                
                Spacer()
            }
            .padding()
        }
        .preferredColorScheme(.dark)
    }
    
    
    // MARK: - Supabase Sign In
    func signIn() async {
        isLoading = true
        message = ""
        defer { isLoading = false }

        do {
            let session = try await SupabaseManager.shared.client.auth.signIn(
                email: email,
                password: password
            )

            // Successfully logged in - update auth manager
            await AuthManager.shared.checkSession()
            isLoggedIn = true
        } catch {
            isLoggedIn = false
            message = "Sign-in failed: \(error.localizedDescription)"
        }
    }
    
    // MARK: - OAuth Sign In
    func signInWithGoogle() async {
        isLoading = true
        message = ""
        defer { isLoading = false }
        
        do {
            let session = try await SupabaseManager.shared.client.auth.signInWithOAuth(
                provider: .google,
                redirectTo: URL(string: "com.supabase.thedailydev://oauth-callback")
            )
            // If we got a session, the user is already signed in
            await AuthManager.shared.checkSession()
            // Ensure user_subscriptions record exists
            await SubscriptionService.shared.ensureUserSubscriptionRecord()
            await MainActor.run {
                isLoggedIn = true
            }
        } catch {
            message = "Failed to sign in with Google: \(error.localizedDescription)"
            print("❌ OAuth error: \(error)")
        }
    }
    
    func signInWithGitHub() async {
        isLoading = true
        message = ""
        defer { isLoading = false }
        
        do {
            let session = try await SupabaseManager.shared.client.auth.signInWithOAuth(
                provider: .github,
                redirectTo: URL(string: "com.supabase.thedailydev://oauth-callback")
            )
            // If we got a session, the user is already signed in
            await AuthManager.shared.checkSession()
            // Ensure user_subscriptions record exists
            await SubscriptionService.shared.ensureUserSubscriptionRecord()
            await MainActor.run {
                isLoggedIn = true
            }
        } catch {
            message = "Failed to sign in with GitHub: \(error.localizedDescription)"
            print("❌ OAuth error: \(error)")
        }
    }
}
