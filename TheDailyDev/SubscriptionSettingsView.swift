//
//  SubscriptionSettingsView.swift
//  TheDailyDev
//
//  Created by Claire Knutson on 10/25/25.
//

import SwiftUI

struct SubscriptionSettingsView: View {
    @Binding var subscription: UserSubscription?
    @StateObject private var subscriptionService = SubscriptionService.shared
    @Environment(\.dismiss) private var dismiss
    
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    if let subscription = subscription {
                        // Subscription Status Card
                        VStack(spacing: 16) {
                            Image(systemName: "crown.fill")
                                .font(.system(size: 50))
                                .foregroundColor(.yellow)
                            
                            Text("Active Subscription")
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            if let billingDate = subscription.formattedBillingDate() {
                                Text("Next billing date: \(billingDate)")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            
                            Text("$7.99/month")
                                .font(.headline)
                                .foregroundColor(.green)
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color(UIColor.secondarySystemBackground))
                        .cornerRadius(16)
                        
                        // Manage Subscription
                        VStack(spacing: 16) {
                            Button(action: {
                                // TODO: Open Stripe billing portal
                                openStripeBillingPortal()
                            }) {
                                HStack {
                                    Image(systemName: "creditcard.fill")
                                    Text("Update Payment Method")
                                }
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .cornerRadius(12)
                            }
                            
                            Button(role: .destructive, action: {
                                openStripeBillingPortal()
                            }) {
                                HStack {
                                    Image(systemName: "xmark.circle.fill")
                                    Text("Cancel Subscription")
                                }
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.red)
                                .cornerRadius(12)
                            }
                        }
                    }
                    
                    // Error Message
                    if let errorMessage = errorMessage {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                            .multilineTextAlignment(.center)
                    }
                }
                .padding()
            }
            .navigationTitle("Subscription")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    // MARK: - Open Billing Portal
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

// MARK: - Preview
struct SubscriptionSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SubscriptionSettingsView(subscription: .constant(nil))
    }
}
