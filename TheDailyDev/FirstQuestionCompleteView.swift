import SwiftUI
import RevenueCat

struct FirstQuestionCompleteView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var subscriptionService = SubscriptionService.shared
    
    var body: some View {
        ZStack {
            // Gradient background
            LinearGradient(
                colors: [
                    Color.black,
                    Color(red: 0.08, green: 0.20, blue: 0.14)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    // Success icon - smaller size to fit on screen
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(Theme.Colors.accentGreen)
                        .padding(.top, 20)
                    
                    // Title
                    Text("Great Job!")
                        .font(.system(size: 32, weight: .heavy, design: .monospaced))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.4, green: 0.9, blue: 0.7),
                                    Theme.Colors.accentGreen
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .shadow(color: Theme.Colors.accentGreen.opacity(0.5), radius: 10, x: 0, y: 0)
                        .shadow(color: .black.opacity(0.8), radius: 2, x: 0, y: 3)
                    
                    // Subtitle
                    Text("Ready for daily practice?")
                        .font(.title3)
                        .foregroundColor(Theme.Colors.textPrimary)
                        .padding(.bottom, 8)
                    
                    // Show RevenueCat paywall for plan selection
                    RevenueCatPaywallView()
                        .onAppear {
                            // Track paywall viewed from first question complete
                            // This view only shows after first question, so hasAnsweredQuestion is always true
                            let hasActiveSubscription = subscriptionService.currentSubscription?.isActive ?? false
                            
                            AnalyticsService.shared.track("paywall_viewed", properties: [
                                "source": "first_question_complete",
                                "user_has_answered_question": true,
                                "user_has_active_subscription": hasActiveSubscription
                            ])
                        }
                    
                    // Dismiss button
                    Button(action: {
                        dismiss()
                    }) {
                        Text("No Thanks - I'll use free Friday questions")
                            .font(.subheadline)
                            .foregroundColor(Theme.Colors.textSecondary)
                    }
                    .padding(.bottom, 20)
                }
                .padding(.horizontal)
            }
        }
        .preferredColorScheme(.dark)
    }
}

#Preview {
    FirstQuestionCompleteView()
}

