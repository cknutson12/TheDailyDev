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
    @State private var showingOnboarding = false
    @State private var showingSubscriptionBenefits = false
    @State private var showingEmailVerification = false
    @State private var signupEmail = ""
    @StateObject private var subscriptionService = SubscriptionService.shared
    
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
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("SubscriptionSuccess"))) { _ in
                // Dismiss subscription benefits view when subscription succeeds
                showingSubscriptionBenefits = false
            }
            .onDisappear {
                // Always dismiss screens when leaving signup view
                // This prevents them from showing when user returns to app
                showingOnboarding = false
                showingSubscriptionBenefits = false
            }
            .sheet(isPresented: $showingOnboarding) {
                OnboardingView(onContinue: {
                    showingOnboarding = false
                    showingSubscriptionBenefits = true
                })
            }
            .sheet(isPresented: $showingSubscriptionBenefits) {
                SubscriptionBenefitsView(
                    onSkip: {
                        showingSubscriptionBenefits = false
                        isLoggedIn = true
                    }
                )
            }
            .sheet(isPresented: $showingEmailVerification) {
                EmailVerificationView(
                    email: signupEmail,
                    onResend: {
                        // Resend is handled in EmailVerificationView
                    },
                    onRetry: {
                        // Check if email is now verified
                        await checkEmailVerification()
                    }
                )
            }
        }
        .preferredColorScheme(.dark)
    }
    
    // MARK: - Supabase Sign Up with Profile Data
    func signUp() async {
        isLoading = true
        message = ""
        defer { isLoading = false }
        
        do {
            // Redirect URL is configured in Supabase Dashboard
            // Authentication > URL Configuration > Redirect URLs
            // For production: https://thedailydevweb.vercel.app/auth/verify
            let redirectURL: URL? = nil // Use dashboard setting
            
            let session = try await SupabaseManager.shared.client.auth.signUp(
                email: email,
                password: password,
                redirectTo: redirectURL
            )
            
            // If sign-up was successful, create user profile
            let user = session.user
            
            // Check if email is verified
            if user.emailConfirmedAt == nil {
                // Email not verified - don't create subscription record yet (no session)
                // Store the names in EmailVerificationManager so they're available after verification
                // Store names for use after email verification
                await MainActor.run {
                    EmailVerificationManager.shared.setPendingNames(
                        firstName: firstName.isEmpty ? nil : firstName,
                        lastName: lastName.isEmpty ? nil : lastName
                    )
                    signupEmail = email
                    showingEmailVerification = true
                }
            } else {
                // Create user subscription record synchronously (not in background)
                // This ensures display name is available immediately
                // Use ensureUserSubscriptionRecord with names to handle RLS properly
                await SubscriptionService.shared.ensureUserSubscriptionRecord(
                    firstName: firstName.isEmpty ? nil : firstName,
                    lastName: lastName.isEmpty ? nil : lastName
                )
                // Clear display name cache so it refreshes with new data
                QuestionService.shared.invalidateDisplayNameCache()
                
                // Update auth manager
                await AuthManager.shared.checkSession()
                
                // Show onboarding screen first, then subscription
                await MainActor.run {
                    showingOnboarding = true
                }
            }
        } catch {
            isLoggedIn = false
            message = "Sign-up failed: \(error.localizedDescription)"
        }
    }
    
    // MARK: - Check Email Verification
    func checkEmailVerification() async {
        do {
            let session = try await SupabaseManager.shared.client.auth.session
            if session.user.emailConfirmedAt != nil {
                // Email is verified, proceed with signup flow
                let user = session.user
                
                // Create user subscription record synchronously
                // This ensures display name is available immediately
                // Use ensureUserSubscriptionRecord with names to handle RLS properly
                await SubscriptionService.shared.ensureUserSubscriptionRecord(
                    firstName: firstName.isEmpty ? nil : firstName,
                    lastName: lastName.isEmpty ? nil : lastName
                )
                // Clear display name cache so it refreshes with new data
                QuestionService.shared.invalidateDisplayNameCache()
                
                // Update auth manager
                await AuthManager.shared.checkSession()
                
                // Show onboarding screen first, then subscription
                await MainActor.run {
                    showingEmailVerification = false
                    showingOnboarding = true
                }
            } else {
                // Still not verified
                await MainActor.run {
                    // Keep showing verification view
                }
            }
        } catch {
            // No session yet, user still needs to verify
            await MainActor.run {
                // Keep showing verification view
            }
        }
    }
    
    // MARK: - Create User Subscription Record
    func createUserSubscription(userId: UUID) async throws {
        // Insert into user_subscriptions with name info
        var insertData: [String: String] = [
            "user_id": userId.uuidString,
            "status": "inactive"
        ]
        
        // Only add name fields if they're not empty
        if !firstName.isEmpty {
            insertData["first_name"] = firstName
        }
        if !lastName.isEmpty {
            insertData["last_name"] = lastName
        }
        
        _ = try await SupabaseManager.shared.client
            .from("user_subscriptions")
            .insert(insertData)
            .execute()
    }
    
    // MARK: - OAuth Sign In
    func signInWithGoogle() async {
        do {
            _ = try await SupabaseManager.shared.client.auth.signInWithOAuth(
                provider: .google,
                redirectTo: URL(string: "com.supabase.thedailydev://oauth-callback")
            )
            // If we got a session, the user is already signed in
            await AuthManager.shared.checkSession()
            // Set RevenueCat user ID
            await AuthManager.shared.setRevenueCatUserID()
            // Ensure user_subscriptions record exists
            await SubscriptionService.shared.ensureUserSubscriptionRecord()
            
            // Check if this is a new user (first time signing in)
            // For OAuth, we'll show onboarding for all sign-ins (can be optimized later)
            await MainActor.run {
                showingOnboarding = true
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
            _ = try await SupabaseManager.shared.client.auth.signInWithOAuth(
                provider: .github,
                redirectTo: URL(string: "com.supabase.thedailydev://oauth-callback")
            )
            // If we got a session, the user is already signed in
            await AuthManager.shared.checkSession()
            // Set RevenueCat user ID
            await AuthManager.shared.setRevenueCatUserID()
            // Ensure user_subscriptions record exists
            await SubscriptionService.shared.ensureUserSubscriptionRecord()
            
            // Check if this is a new user (first time signing in)
            // For OAuth, we'll show onboarding for all sign-ins (can be optimized later)
            await MainActor.run {
                showingOnboarding = true
            }
        } catch {
            await MainActor.run {
                message = "Failed to sign in with GitHub: \(error.localizedDescription)"
            }
            print("❌ OAuth error: \(error)")
        }
    }
}
