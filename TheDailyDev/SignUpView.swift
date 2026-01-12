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
            .onDisappear {
                // Always dismiss screens when leaving signup view
                // This prevents them from showing when user returns to app
                showingOnboarding = false
            }
            .sheet(isPresented: $showingOnboarding) {
                OnboardingView(onContinue: {
                    DebugLogger.log("📝 OnboardingView 'Get Started' tapped")
                    showingOnboarding = false
                    
                    // Start the tour as part of default onboarding flow
                    // This will only start if the tour hasn't been completed
                    DebugLogger.log("🚀 Starting onboarding tour...")
                    OnboardingTourManager.shared.startTour()
                    
                    // Navigate to home screen
                    // Tour will be visible when HomeView appears
                    isLoggedIn = true
                    DebugLogger.log("✅ Set isLoggedIn = true, navigating to HomeView")
                })
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
        // Track sign-up started
        AnalyticsService.shared.track("sign_up_started")
        
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
            
            // Track sign-up completed
            AnalyticsService.shared.track("sign_up_completed", properties: [
                "email_verified": user.emailConfirmedAt != nil,
                "sign_up_method": "email"
            ])
            
            // Set user ID and sign-up date for analytics
            let userId = user.id.uuidString
            AnalyticsService.shared.setUserID(userId)
            AnalyticsService.shared.setSignUpDate(Date())
            AnalyticsService.shared.setUserProperty("sign_up_method", value: "email")
            
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
            // Track sign-up failure
            AnalyticsService.shared.track("sign_up_failed", properties: [
                "error": error.localizedDescription
            ])
            
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
        // Track OAuth sign-up started
        AnalyticsService.shared.track("sign_up_started", properties: [
            "sign_up_method": "google_oauth"
        ])
        
        do {
            _ = try await SupabaseManager.shared.client.auth.signInWithOAuth(
                provider: .google,
                redirectTo: URL(string: "com.supabase.thedailydev://oauth-callback")
            )
            // If we got a session, the user is already signed in
            await AuthManager.shared.checkSession()
            
            // Get user ID for analytics
            let session = try await SupabaseManager.shared.client.auth.session
            let userId = session.user.id.uuidString
            AnalyticsService.shared.setUserID(userId)
            AnalyticsService.shared.setSignUpDate(Date())
            AnalyticsService.shared.setUserProperty("sign_up_method", value: "google_oauth")
            
            // Track sign-up completed
            AnalyticsService.shared.track("sign_up_completed", properties: [
                "email_verified": session.user.emailConfirmedAt != nil,
                "sign_up_method": "google_oauth"
            ])
            
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
            // Track sign-up failure
            AnalyticsService.shared.track("sign_up_failed", properties: [
                "error": error.localizedDescription,
                "sign_up_method": "google_oauth"
            ])
            
            await MainActor.run {
                message = "Failed to sign in with Google: \(error.localizedDescription)"
            }
            print("❌ OAuth error: \(error)")
        }
    }
    
    func signInWithGitHub() async {
        // Track OAuth sign-up started
        AnalyticsService.shared.track("sign_up_started", properties: [
            "sign_up_method": "github_oauth"
        ])
        
        do {
            _ = try await SupabaseManager.shared.client.auth.signInWithOAuth(
                provider: .github,
                redirectTo: URL(string: "com.supabase.thedailydev://oauth-callback")
            )
            // If we got a session, the user is already signed in
            await AuthManager.shared.checkSession()
            
            // Get user ID for analytics
            let session = try await SupabaseManager.shared.client.auth.session
            let userId = session.user.id.uuidString
            AnalyticsService.shared.setUserID(userId)
            AnalyticsService.shared.setSignUpDate(Date())
            AnalyticsService.shared.setUserProperty("sign_up_method", value: "github_oauth")
            
            // Track sign-up completed
            AnalyticsService.shared.track("sign_up_completed", properties: [
                "email_verified": session.user.emailConfirmedAt != nil,
                "sign_up_method": "github_oauth"
            ])
            
            // Set RevenueCat user ID
            await AuthManager.shared.setRevenueCatUserID()
            // Ensure user_subscriptions record exists
            await SubscriptionService.shared.ensureUserSubscriptionRecord()
            
            // Show onboarding for all OAuth sign-ups (tour will start after onboarding)
            await MainActor.run {
                showingOnboarding = true
            }
        } catch {
            // Track sign-up failure
            AnalyticsService.shared.track("sign_up_failed", properties: [
                "error": error.localizedDescription,
                "sign_up_method": "github_oauth"
            ])
            
            await MainActor.run {
                message = "Failed to sign in with GitHub: \(error.localizedDescription)"
            }
            DebugLogger.error("❌ OAuth error: \(error)")
        }
    }
}
