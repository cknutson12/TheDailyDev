//
//  SubscriptionBenefitsView.swift
//  TheDailyDev
//
//  Created by Claire Knutson on 10/25/25.
//

import SwiftUI

struct SubscriptionBenefitsView: View {
    let onSubscribe: () -> Void
    let onSkip: (() -> Void)?
    
    init(onSubscribe: @escaping () -> Void, onSkip: (() -> Void)? = nil) {
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
                        Text("Get 7 days free, then $7.99/month. Cancel anytime.")
                            .font(.body)
                            .foregroundColor(Color.theme.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        
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
                        
                        // Price
                        VStack(spacing: 8) {
                            HStack(alignment: .firstTextBaseline, spacing: 4) {
                                Text("$7.99")
                                    .font(.system(size: 36, weight: .bold))
                                    .foregroundColor(.white)
                                Text("/month")
                                    .font(.body)
                                    .foregroundColor(Color.theme.textSecondary)
                            }
                            Text("7-day free trial • Auto-renews after trial")
                                .font(.caption)
                                .foregroundColor(Color.theme.textSecondary)
                        }
                        
                        // Subscribe Button
                        Button(action: onSubscribe) {
                            VStack(spacing: 4) {
                                Text("Start My Free Trial")
                                    .bold()
                                Text("No charge for 7 days")
                                    .font(.caption)
                                    .opacity(0.8)
                            }
                        }
                        .buttonStyle(PrimaryButtonStyle())
                        
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
            }
        }
        .preferredColorScheme(.dark)
    }
}

// MARK: - Preview
struct SubscriptionBenefitsView_Previews: PreviewProvider {
    static var previews: some View {
        SubscriptionBenefitsView(
            onSubscribe: { print("Subscribe tapped") },
            onSkip: { print("Skip tapped") }
        )
    }
}
