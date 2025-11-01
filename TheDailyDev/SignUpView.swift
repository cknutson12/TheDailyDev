import SwiftUI
import Supabase

struct SignUpView: View {
    @Binding var isLoggedIn: Bool
    @State private var email = ""
    @State private var password = ""
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var message = ""
    @State private var isLoading = false
    @State private var showingSubscriptionBenefits = false
    @StateObject private var subscriptionService = SubscriptionService.shared
    
    var body: some View {
        ZStack {
            Color.theme.background.ignoresSafeArea()
            VStack(spacing: 20) {
                VStack(spacing: 16) {
                    Text("Create Account")
                        .font(.title)
                        .bold()
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    VStack(spacing: 12) {
                        TextField("First Name", text: $firstName)
                            .textFieldStyle(DarkTextFieldStyle())
                            .textInputAutocapitalization(.words)
                        
                        TextField("Last Name", text: $lastName)
                            .textFieldStyle(DarkTextFieldStyle())
                            .textInputAutocapitalization(.words)
                        
                        TextField("Email", text: $email)
                            .textFieldStyle(DarkTextFieldStyle())
                            .textInputAutocapitalization(.never)
                            .keyboardType(.emailAddress)
                        
                        SecureField("Password", text: $password)
                            .textFieldStyle(DarkTextFieldStyle())
                    }
                }
                .cardContainer()
                
                if !message.isEmpty {
                    Text(message)
                        .foregroundColor(Theme.Colors.stateIncorrect)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                }
                
                Button(action: { Task { await signUp() } }) {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                            .tint(.black)
                    } else {
                        Text("Create Account")
                            .bold()
                    }
                }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(isLoading)
                
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
            .sheet(isPresented: $showingSubscriptionBenefits) {
                SubscriptionBenefitsView(
                    onSubscribe: {
                        Task {
                            await handleSubscription()
                        }
                    },
                    onSkip: {
                        showingSubscriptionBenefits = false
                        isLoggedIn = true
                    }
                )
            }
        }
        .preferredColorScheme(.dark)
    }
    
    // MARK: - Handle Subscription
    private func handleSubscription() async {
        do {
            print("🔄 Creating Stripe checkout session...")
            let checkoutURL = try await subscriptionService.createCheckoutSession()
            print("✅ Checkout session created: \(checkoutURL)")
            
            await MainActor.run {
                print("🌐 Opening Safari with checkout URL...")
                if UIApplication.shared.canOpenURL(checkoutURL) {
                    UIApplication.shared.open(checkoutURL) { success in
                        if success {
                            print("✅ Safari opened successfully")
                        } else {
                            print("❌ Failed to open Safari")
                        }
                    }
                } else {
                    print("❌ Cannot open URL: \(checkoutURL)")
                    message = "Cannot open browser. Please check your settings."
                }
            }
        } catch {
            print("❌ Failed to create checkout session: \(error)")
            await MainActor.run {
                message = "Failed to start subscription: \(error.localizedDescription)"
                showingSubscriptionBenefits = false
                isLoggedIn = true
            }
        }
    }
    
    // MARK: - Supabase Sign Up with Profile Data
    func signUp() async {
        isLoading = true
        message = ""
        defer { isLoading = false }
        
        do {
            let session = try await SupabaseManager.shared.client.auth.signUp(
                email: email,
                password: password
            )
            
            // If sign-up was successful, create user profile
            let user = session.user
            
            // Create user subscription record in the background
            Task {
                do {
                    try await createUserSubscription(userId: user.id)
                } catch {
                    print("Failed to create user subscription: \(error)")
                }
            }
            
            // Update auth manager
            await AuthManager.shared.checkSession()
            
            // Show subscription benefits screen
            await MainActor.run {
                showingSubscriptionBenefits = true
            }
        } catch {
            isLoggedIn = false
            message = "Sign-up failed: \(error.localizedDescription)"
        }
    }
    
    // MARK: - Create User Subscription Record
    func createUserSubscription(userId: UUID) async throws {
        // Insert into user_subscriptions with name info
        _ = try await SupabaseManager.shared.client
            .from("user_subscriptions")
            .insert([
                "user_id": userId.uuidString,
                "first_name": firstName.isEmpty ? nil : firstName,
                "last_name": lastName.isEmpty ? nil : lastName,
                "status": "inactive"
            ])
            .execute()
    }
    
    // MARK: - OAuth Sign In
    func signInWithGoogle() async {
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
            await MainActor.run {
                message = "Failed to sign in with Google: \(error.localizedDescription)"
            }
            print("❌ OAuth error: \(error)")
        }
    }
    
    func signInWithGitHub() async {
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
            await MainActor.run {
                message = "Failed to sign in with GitHub: \(error.localizedDescription)"
            }
            print("❌ OAuth error: \(error)")
        }
    }
}
