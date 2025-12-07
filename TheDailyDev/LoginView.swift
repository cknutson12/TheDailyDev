import SwiftUI
import Supabase

struct LoginView: View {
    @Binding var isLoggedIn: Bool
    @State private var email = ""
    @State private var password = ""
    @State private var message = ""
    @State private var isLoading = false
    @State private var showingEmailVerification = false
    @State private var showingForgotPassword = false
    
    var body: some View {
        ZStack {
            // Gradient background for depth
            LinearGradient(
                colors: [
                    Color.black,
                    Color(red: 0.08, green: 0.20, blue: 0.14)  // Lighter dark green tint at bottom
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 20) {
                Spacer()
                VStack(spacing: 12) {
                    TextField("Email", text: $email)
                        .textFieldStyle(DarkTextFieldStyle())
                        .textInputAutocapitalization(.never)
                        .accessibilityIdentifier("EmailField")
                    
                    SecureField("Password", text: $password)
                        .textFieldStyle(DarkTextFieldStyle())
                        .accessibilityIdentifier("PasswordField")
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
                
                // Forgot Password Button
                Button(action: {
                    showingForgotPassword = true
                }) {
                    Text("Forgot Password?")
                        .font(.subheadline)
                        .foregroundColor(Theme.Colors.textSecondary)
                }
                .padding(.top, 8)
                
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
                            HStack(spacing: 12) {
                                Image("google-logo")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 20, height: 20)
                                Text("Continue with Google")
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
                        .accessibilityIdentifier("GoogleSignInButton")
                        
                        Button(action: { Task { await signInWithGitHub() } }) {
                            HStack(spacing: 12) {
                                Image("github-logo")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 20, height: 20)
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
            .sheet(isPresented: $showingEmailVerification) {
                EmailVerificationView(
                    email: email,
                    onResend: {
                        // Resend is handled in EmailVerificationView
                    },
                    onRetry: {
                        // Try to sign in again after verification
                        await signIn()
                    }
                )
            }
            .sheet(isPresented: $showingForgotPassword) {
                ForgotPasswordView()
            }
            .onDisappear {
                // Always dismiss forgot password view when leaving login view
                // This prevents it from showing when user returns to app after password reset
                showingForgotPassword = false
            }
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("PasswordResetLinkReceived"))) { _ in
                // Dismiss forgot password view when password reset link is received
                showingForgotPassword = false
            }
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

            // Check if email is verified
            if session.user.emailConfirmedAt == nil {
                await MainActor.run {
                    message = "Please verify your email before signing in. Check your inbox for the verification link."
                    showingEmailVerification = true
                }
            } else {
                // Successfully logged in - update auth manager
                await AuthManager.shared.checkSession()
                isLoggedIn = true
            }
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
