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
            
            VStack(spacing: 32) {
                Spacer()
                
                // Success icon
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(Theme.Colors.accentGreen)
                
                // Title
                Text("Great Job!")
                    .font(.system(size: 36, weight: .heavy, design: .monospaced))
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
                    .font(.title2)
                    .foregroundColor(Theme.Colors.textPrimary)
                
                // Show RevenueCat paywall for plan selection
                RevenueCatPaywallView()
                    .frame(height: 400) // Limit height to fit in view
                
                // Benefits list
                VStack(alignment: .leading, spacing: 12) {
                    BenefitRow(icon: "calendar", text: "Daily system design questions")
                    BenefitRow(icon: "chart.line.uptrend.xyaxis", text: "Track your progress")
                    BenefitRow(icon: "flame.fill", text: "Build your streak")
                }
                .padding(.horizontal, 32)
                .padding(.top, 8)
                
                Spacer()
                
                Button(action: {
                    dismiss()
                }) {
                    Text("No Thanks - I'll use free Friday questions")
                        .font(.subheadline)
                        .foregroundColor(Theme.Colors.textSecondary)
                }
                .padding(.bottom, 16)
            }
        }
        .preferredColorScheme(.dark)
    }
}

struct BenefitRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(Theme.Colors.accentGreen)
                .frame(width: 24)
            
            Text(text)
                .font(.body)
                .foregroundColor(Theme.Colors.textPrimary)
            
            Spacer()
        }
    }
}

#Preview {
    FirstQuestionCompleteView()
}

