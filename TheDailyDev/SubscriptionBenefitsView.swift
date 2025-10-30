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
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Crown Icon
                    Image(systemName: "crown.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.yellow)
                    
                    // Title
                    Text("Unlock Full Access")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    // Description
                    Text("Subscribe to get unlimited access to daily system design questions and track your progress")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    // Benefits List
                    VStack(alignment: .leading, spacing: 16) {
                        ForEach(SubscriptionBenefit.allBenefits) { benefit in
                            HStack(alignment: .top, spacing: 12) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                    .font(.title3)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(benefit.title)
                                        .font(.headline)
                                    
                                    if let description = benefit.description {
                                        Text(description)
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                            .fixedSize(horizontal: false, vertical: true)
                                    }
                                }
                                
                                Spacer()
                            }
                        }
                    }
                    .padding()
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(16)
                    
                    // Price
                    VStack(spacing: 8) {
                        HStack(alignment: .firstTextBaseline, spacing: 4) {
                            Text("$7.99")
                                .font(.system(size: 36, weight: .bold))
                            Text("/month")
                                .font(.body)
                                .foregroundColor(.secondary)
                        }
                        Text("Cancel anytime")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    // Subscribe Button
                    Button(action: onSubscribe) {
                        Text("Subscribe Now")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(12)
                    }
                    
                    // Skip Button (if provided)
                    if let onSkip = onSkip {
                        Button(action: onSkip) {
                            Text("Maybe Later")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
        }
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
