import SwiftUI


struct ContentView: View {
    @State private var isLoggedIn = false
    @State private var showSignUp = false
    @StateObject private var authManager = AuthManager.shared

    var body: some View {
        NavigationStack {
            // Show loading screen while checking authentication
            if authManager.isCheckingAuth {
                ZStack {
                    Color.theme.background.ignoresSafeArea()
                    
                    VStack(spacing: 20) {
                        Text("The Daily Dev")
                            .font(.system(size: 42, weight: .heavy, design: .monospaced))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [
                                        Theme.Colors.accentGreen,
                                        Theme.Colors.accentGreen.opacity(0.75),
                                        Theme.Colors.subtleBlue.opacity(0.9)
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .overlay(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.35),
                                        Color.clear
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                                .mask(
                                    Text("The Daily Dev")
                                        .font(.system(size: 42, weight: .heavy, design: .monospaced))
                                )
                            )
                            .shadow(color: Theme.Colors.accentGreen.opacity(0.4), radius: 12, x: 0, y: 8)
                            .shadow(color: Color.black.opacity(0.85), radius: 20, x: 0, y: 18)
                        
                        ProgressView()
                            .tint(Theme.Colors.accentGreen)
                            .scaleEffect(1.2)
                    }
                }
            } else if authManager.isAuthenticated || isLoggedIn {
                HomeView(isLoggedIn: $isLoggedIn)
            } else {
                VStack(spacing: 20) {
                    Text("The Daily Dev")
                        .font(.system(size: 42, weight: .heavy, design: .monospaced))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [
                                    Theme.Colors.accentGreen,
                                    Theme.Colors.accentGreen.opacity(0.75),
                                    Theme.Colors.subtleBlue.opacity(0.9)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .overlay(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.35),
                                    Color.clear
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                            .mask(
                                Text("The Daily Dev")
                                    .font(.system(size: 42, weight: .heavy, design: .monospaced))
                            )
                        )
                        .shadow(color: Theme.Colors.accentGreen.opacity(0.4), radius: 12, x: 0, y: 8)
                        .shadow(color: Color.black.opacity(0.85), radius: 20, x: 0, y: 18)
                        .padding(.top, 30)
                        .padding(.bottom, 20)
                    
                    if showSignUp {
                        SignUpView(isLoggedIn: $isLoggedIn)
                    } else {
                        LoginView(isLoggedIn: $isLoggedIn)
                    }
                    
                    Button(action: {
                        showSignUp.toggle()
                    }) {
                        Text(showSignUp ? "Already have an account? Sign In" : "Don't have an account? Sign Up")
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(.blue)
                }
            }
        }
        .id(isLoggedIn || authManager.isAuthenticated ? "loggedIn" : "loggedOut")
        .task {
            // Check for existing session on app launch
            await authManager.checkSession()
            if authManager.isAuthenticated {
                // Ensure user_subscriptions record exists for OAuth users
                await SubscriptionService.shared.ensureUserSubscriptionRecord()
                isLoggedIn = true
            }
        }
        .onChange(of: authManager.isAuthenticated) { oldValue, newValue in
            // Update isLoggedIn when auth state changes
            isLoggedIn = newValue
        }
    }
}
