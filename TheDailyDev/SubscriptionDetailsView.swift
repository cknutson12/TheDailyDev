//
//  SubscriptionDetailsView.swift
//  TheDailyDev
//
//  Created by Claire Knutson on 11/8/25.
//

import SwiftUI

struct SubscriptionDetailsView: View {
    let subscription: UserSubscription
    @StateObject private var subscriptionService = SubscriptionService.shared
    @State private var errorMessage: String?
    @State private var currentPlan: SubscriptionPlan?
    @Environment(\.dismiss) private var dismiss
    
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
                    // Header Icon
                    Image(systemName: subscription.isActive ? "checkmark.seal.fill" : "info.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(subscription.isActive ? Theme.Colors.accentGreen : Theme.Colors.textSecondary)
                        .padding(.top, 20)
                    
                    // Status Title
                    if subscription.isInTrial {
                        Text("Free Trial")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.white)
                    } else if subscription.isActive {
                        Text("Active Subscription")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.white)
                    } else {
                        Text("No Active Subscription")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.white)
                    }
                    
                    // Subscription Details Card
                    VStack(alignment: .leading, spacing: 16) {
                        // Price
                        DetailRow(
                            icon: "dollarsign.circle.fill",
                            label: "Price",
                            value: currentPlan?.formattedPrice ?? "$4.99/month"
                        )
                        
                        Divider()
                            .background(Theme.Colors.border)
                        
                        // Status
                        DetailRow(
                            icon: "circle.fill",
                            label: "Status",
                            value: subscription.isInTrial ? "Trial" : (subscription.isActive ? "Active" : "Inactive"),
                            valueColor: subscription.isActive ? Theme.Colors.accentGreen : Theme.Colors.textSecondary
                        )
                        
                        if subscription.isInTrial, let trialEnd = subscription.trialEnd {
                            Divider()
                                .background(Theme.Colors.border)
                            
                            DetailRow(
                                icon: "clock.fill",
                                label: "Trial Ends",
                                value: formatDate(trialEnd)
                            )
                        }
                        
                        if subscription.isActive, let billingDate = subscription.formattedBillingDate() {
                            Divider()
                                .background(Theme.Colors.border)
                            
                            DetailRow(
                                icon: "calendar.circle.fill",
                                label: "Next Billing Date",
                                value: billingDate
                            )
                        }
                    }
                    .padding(20)
                    .cardContainer()
                    
                    // Info Box
                    if subscription.isInTrial {
                        let priceText = currentPlan?.formattedPrice ?? "$4.99/month"
                        InfoBox(
                            icon: "info.circle.fill",
                            text: "Your card will be charged \(priceText) automatically when your trial ends. You can cancel anytime before then at no charge."
                        )
                    } else if subscription.isActive {
                        InfoBox(
                            icon: "info.circle.fill",
                            text: "Your subscription will automatically renew on the next billing date. You can cancel or update your payment method anytime."
                        )
                    }
                    
                    // Error Message
                    if let errorMessage = errorMessage {
                        Text(errorMessage)
                            .foregroundColor(Theme.Colors.stateIncorrect)
                            .font(.caption)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    
                    // Manage Subscription Button
                    if subscription.isActive {
                        Button(action: {
                            openStripeBillingPortal()
                        }) {
                            HStack {
                                Image(systemName: "gearshape.fill")
                                Text("Edit Subscription Details")
                                    .font(.headline)
                            }
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                        }
                        .buttonStyle(PrimaryButtonStyle())
                        
                        Text("Update payment method, view invoices, or cancel")
                            .font(.caption)
                            .foregroundColor(Theme.Colors.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                }
                .padding()
            }
        }
        .navigationTitle("Subscription Details")
        .navigationBarTitleDisplayMode(.inline)
        .preferredColorScheme(.dark)
        .task {
            // Fetch current plan for pricing display
            currentPlan = await subscriptionService.fetchCurrentPlan()
        }
    }
    
    private func formatDate(_ dateString: String) -> String {
        guard let date = ISO8601DateFormatter().date(from: dateString) else {
            return dateString
        }
        
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
    
    private func openStripeBillingPortal() {
        Task {
            do {
                let portalURL = try await subscriptionService.getBillingPortalURL()
                await MainActor.run {
                    UIApplication.shared.open(portalURL)
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to open billing portal: \(error.localizedDescription)"
                }
            }
        }
    }
}

// MARK: - Detail Row
struct DetailRow: View {
    let icon: String
    let label: String
    let value: String
    var valueColor: Color = Theme.Colors.textPrimary
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(Theme.Colors.accentGreen)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(label)
                    .font(.caption)
                    .foregroundColor(Theme.Colors.textSecondary)
                
                Text(value)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(valueColor)
            }
            
            Spacer()
        }
    }
}

// MARK: - Info Box
struct InfoBox: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(Theme.Colors.accentGreen)
            
            Text(text)
                .font(.caption)
                .foregroundColor(Theme.Colors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
            
            Spacer()
        }
        .padding(16)
        .background(Theme.Colors.surface)
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Metrics.cornerRadius)
                .stroke(Theme.Colors.accentGreen.opacity(0.3), lineWidth: 1)
        )
        .cornerRadius(Theme.Metrics.cornerRadius)
    }
}

#Preview {
    NavigationView {
        SubscriptionDetailsView(subscription: UserSubscription(
            id: "1",
            userId: "123",
            firstName: "Test",
            lastName: "User",
            stripeCustomerId: "cus_123",
            stripeSubscriptionId: "sub_123",
            status: "trialing",
            currentPeriodEnd: "2025-11-15T00:00:00Z",
            trialEnd: "2025-11-15T00:00:00Z",
            createdAt: "2025-11-08T00:00:00Z",
            updatedAt: "2025-11-08T00:00:00Z"
        ))
    }
}

