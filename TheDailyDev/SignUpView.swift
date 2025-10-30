import SwiftUI

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
        VStack(spacing: 20) {
            Text("Create Account")
                .font(.largeTitle)
                .bold()
            
            TextField("First Name", text: $firstName)
                .textFieldStyle(.roundedBorder)
                .autocapitalization(.words)
            
            TextField("Last Name", text: $lastName)
                .textFieldStyle(.roundedBorder)
                .autocapitalization(.words)
            
            TextField("Email", text: $email)
                .textFieldStyle(.roundedBorder)
                .autocapitalization(.none)
                .keyboardType(.emailAddress)
            
            SecureField("Password", text: $password)
                .textFieldStyle(.roundedBorder)
            
            if !message.isEmpty {
                Text(message)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
            }
            
            Button(action: {
                Task { await signUp() }
            }) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                } else {
                    Text("Create Account")
                        .bold()
                        .frame(maxWidth: .infinity)
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(isLoading)
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
}
