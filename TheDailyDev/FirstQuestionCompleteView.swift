import SwiftUI

struct FirstQuestionCompleteView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var subscriptionService = SubscriptionService.shared
    @State private var isLoading = false
    @State private var errorMessage = ""
    @State private var allPlans: [SubscriptionPlan] = []
    @State private var selectedPlan: SubscriptionPlan?
    
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
                
                // Plan Selection
                if !allPlans.isEmpty {
                    VStack(spacing: 12) {
                        ForEach(allPlans) { plan in
                            PlanSelectionCard(
                                plan: plan,
                                isSelected: selectedPlan?.id == plan.id,
                                onSelect: {
                                    selectedPlan = plan
                                }
                            )
                        }
                    }
                    .padding(.horizontal, 32)
                } else {
                    // Fallback trial info box
                    VStack(spacing: 12) {
                        HStack(spacing: 12) {
                            Image(systemName: "gift.fill")
                                .font(.system(size: 32))
                                .foregroundColor(Theme.Colors.accentGreen)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("7 Days Free, Then $4.99/Month")
                                    .font(.headline)
                                    .foregroundColor(Theme.Colors.textPrimary)
                                
                                Text("Auto-renews after trial • Cancel anytime")
                                    .font(.caption)
                                    .foregroundColor(Theme.Colors.textSecondary)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(16)
                    .background(Theme.Colors.surface)
                    .cornerRadius(Theme.Metrics.cornerRadius)
                    .overlay(
                        RoundedRectangle(cornerRadius: Theme.Metrics.cornerRadius)
                            .stroke(Theme.Colors.accentGreen.opacity(0.3), lineWidth: 1)
                    )
                    .padding(.horizontal, 32)
                }
                
                // Benefits list
                VStack(alignment: .leading, spacing: 12) {
                    BenefitRow(icon: "calendar", text: "Daily system design questions")
                    BenefitRow(icon: "chart.line.uptrend.xyaxis", text: "Track your progress")
                    BenefitRow(icon: "flame.fill", text: "Build your streak")
                }
                .padding(.horizontal, 32)
                .padding(.top, 8)
                
                Spacer()
                
                // Error message
                if !errorMessage.isEmpty {
                    Text(errorMessage)
                        .foregroundColor(Theme.Colors.stateIncorrect)
                        .font(.caption)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                
                // Buttons
                VStack(spacing: 12) {
                    Button(action: {
                        Task { await startTrial() }
                    }) {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                                .tint(.black)
                        } else {
                            VStack(spacing: 4) {
                                Text("Start My Free Trial")
                                    .bold()
                                    .font(.headline)
                                Text("No charge for 7 days")
                                    .font(.caption2)
                                    .opacity(0.8)
                            }
                        }
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .disabled(isLoading)
                    
                    if let plan = selectedPlan ?? allPlans.first {
                        Text("You'll be charged \(plan.formattedPrice) after the trial ends")
                            .font(.caption)
                            .foregroundColor(Theme.Colors.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                    } else {
                        Text("You'll be charged $4.99/month after the trial ends")
                            .font(.caption)
                            .foregroundColor(Theme.Colors.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                    }
                    
                    Button(action: {
                        dismiss()
                    }) {
                        Text("No Thanks - I'll use free Friday questions")
                            .font(.subheadline)
                            .foregroundColor(Theme.Colors.textSecondary)
                    }
                    .padding(.bottom, 16)
                }
                .padding(.horizontal, 32)
            }
        }
        .preferredColorScheme(.dark)
        .task {
            // Fetch all plans for selection
            let plans = await subscriptionService.fetchAllPlans()
            await MainActor.run {
                self.allPlans = plans
                // Default to monthly plan
                self.selectedPlan = plans.first { $0.name == "monthly" }
            }
        }
    }
    
    private func startTrial() async {
        isLoading = true
        errorMessage = ""
        
        guard let plan = selectedPlan ?? allPlans.first else {
            await MainActor.run {
                errorMessage = "Please select a plan"
                isLoading = false
            }
            return
        }
        
        do {
            let checkoutURL = try await subscriptionService.initiateTrialSetup(plan: plan)
            await MainActor.run {
                isLoading = false
                UIApplication.shared.open(checkoutURL)
                // Don't dismiss - let user return via deep link
            }
        } catch {
            await MainActor.run {
                errorMessage = "Failed to start trial: \(error.localizedDescription)"
                isLoading = false
            }
        }
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

