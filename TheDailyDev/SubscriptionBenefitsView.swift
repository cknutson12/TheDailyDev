//
//  SubscriptionBenefitsView.swift
//  TheDailyDev
//
//  Created by Claire Knutson on 10/25/25.
//

import SwiftUI

struct SubscriptionBenefitsView: View {
    let onSubscribe: (SubscriptionPlan) -> Void
    let onSkip: (() -> Void)?
    
    @State private var allPlans: [SubscriptionPlan] = []
    @State private var selectedPlan: SubscriptionPlan?
    @StateObject private var subscriptionService = SubscriptionService.shared
    
    init(onSubscribe: @escaping (SubscriptionPlan) -> Void, onSkip: (() -> Void)? = nil) {
        self.onSubscribe = onSubscribe
        self.onSkip = onSkip
    }
    
    var body: some View {
        ZStack {
            Color.theme.background.ignoresSafeArea()
            NavigationView {
                ScrollView {
                    VStack(spacing: 24) {
                        // Crown Icon
                        Image(systemName: "crown.fill")
                            .font(.system(size: 60))
                            .foregroundColor(Color.theme.accentGreen)
                        
                        // Title
                        Text("Start Your Free Trial")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        // Description
                        if let plan = selectedPlan {
                            Text("Get \(plan.trialDays) days free, then \(plan.formattedPrice). Cancel anytime.")
                                .font(.body)
                                .foregroundColor(Color.theme.textSecondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        } else {
                            Text("Get 7 days free, then choose your plan. Cancel anytime.")
                                .font(.body)
                                .foregroundColor(Color.theme.textSecondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                        
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
                            .padding(.horizontal)
                        }
                        
                        // Benefits List
                        VStack(alignment: .leading, spacing: 16) {
                            ForEach(SubscriptionBenefit.allBenefits) { benefit in
                                HStack(alignment: .top, spacing: 12) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(Theme.Colors.stateCorrect)
                                        .font(.title3)
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(benefit.title)
                                            .font(.headline)
                                            .foregroundColor(.white)
                                        
                                        if let description = benefit.description {
                                            Text(description)
                                                .font(.subheadline)
                                                .foregroundColor(Color.theme.textSecondary)
                                                .fixedSize(horizontal: false, vertical: true)
                                        }
                                    }
                                    
                                    Spacer()
                                }
                            }
                        }
                        .padding()
                        .cardContainer()
                        
                        // Subscribe Button
                        Button(action: {
                            if let plan = selectedPlan ?? allPlans.first {
                                onSubscribe(plan)
                            }
                        }) {
                            VStack(spacing: 4) {
                                Text("Start My Free Trial")
                                    .bold()
                                Text("No charge for 7 days")
                                    .font(.caption)
                                    .opacity(0.8)
                            }
                        }
                        .buttonStyle(PrimaryButtonStyle())
                        .disabled(selectedPlan == nil && !allPlans.isEmpty)
                        
                        // Skip Button (if provided)
                        if let onSkip = onSkip {
                            Button(action: onSkip) {
                                Text("Maybe Later")
                                    .font(.subheadline)
                                    .foregroundColor(Color.theme.textSecondary)
                            }
                        }
                    }
                    .padding()
                }
                .background(Color.theme.background)
                .navigationTitle("")
                .navigationBarTitleDisplayMode(.inline)
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
        }
        .preferredColorScheme(.dark)
    }
}

// MARK: - Plan Selection Card
struct PlanSelectionCard: View {
    let plan: SubscriptionPlan
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(plan.displayName ?? plan.name.capitalized)
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        if plan.billingPeriod == "year" {
                            Text("SAVE 33%")
                                .font(.caption2)
                                .fontWeight(.bold)
                                .foregroundColor(.black)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Theme.Colors.accentGreen)
                                .cornerRadius(4)
                        }
                    }
                    
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text(plan.formattedPriceAmount)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        Text("/\(plan.billingPeriod)")
                            .font(.subheadline)
                            .foregroundColor(Color.theme.textSecondary)
                    }
                    
                    if plan.billingPeriod == "year" {
                        Text("$\(String(format: "%.2f", plan.priceAmount / 12))/month")
                            .font(.caption)
                            .foregroundColor(Color.theme.textSecondary)
                    }
                }
                
                Spacer()
                
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundColor(isSelected ? Theme.Colors.accentGreen : Color.theme.textSecondary)
            }
            .padding()
            .background(isSelected ? Theme.Colors.accentGreen.opacity(0.1) : Theme.Colors.surface)
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Metrics.cornerRadius)
                    .stroke(isSelected ? Theme.Colors.accentGreen : Theme.Colors.border, lineWidth: isSelected ? 2 : 1)
            )
            .cornerRadius(Theme.Metrics.cornerRadius)
        }
    }
}

// MARK: - Preview
struct SubscriptionBenefitsView_Previews: PreviewProvider {
    static var previews: some View {
        SubscriptionBenefitsView(
            onSubscribe: { plan in print("Subscribe tapped: \(plan.name)") },
            onSkip: { print("Skip tapped") }
        )
    }
}
