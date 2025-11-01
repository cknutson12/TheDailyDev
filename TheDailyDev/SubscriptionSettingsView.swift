//
//  SubscriptionSettingsView.swift
//  TheDailyDev
//
//  Created by Claire Knutson on 10/25/25.
//

import SwiftUI
import Supabase

struct SubscriptionSettingsView: View {
    @Binding var subscription: UserSubscription?
    @Binding var isLoggedIn: Bool
    @StateObject private var subscriptionService = SubscriptionService.shared
    @Environment(\.dismiss) private var dismiss
    
    @State private var errorMessage: String?
    @State private var isSigningOut = false
    @State private var signOutError: String?
    @State private var showingSignOutConfirmation = false
    
    init(subscription: Binding<UserSubscription?>, isLoggedIn: Binding<Bool>) {
        self._subscription = subscription
        self._isLoggedIn = isLoggedIn
    }
    
    var body: some View {
        ZStack {
            Color.theme.background.ignoresSafeArea()
            NavigationView {
                ScrollView {
                    VStack(spacing: 24) {
                        if let subscription = subscription {
                            // Subscription Status Card
                            VStack(spacing: 16) {
                                Image(systemName: subscription.isActive ? "crown.fill" : "crown")
                                    .font(.system(size: 50))
                                    .foregroundColor(subscription.isActive ? Color.theme.accentGreen : Color.theme.textSecondary)
                                
                                Text(subscription.isActive ? "Active Subscription" : "No Active Subscription")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                
                                if subscription.isActive {
                                    if let billingDate = subscription.formattedBillingDate() {
                                        Text("Next billing date: \(billingDate)")
                                            .font(.subheadline)
                                            .foregroundColor(Color.theme.textSecondary)
                                    }
                                    
                                    Text("$7.99/month")
                                        .font(.headline)
                                        .foregroundColor(Theme.Colors.stateCorrect)
                                } else {
                                    Text("Subscribe to unlock full access")
                                        .font(.subheadline)
                                        .foregroundColor(Color.theme.textSecondary)
                                }
                            }
                            .padding()
                            .frame(maxWidth: .infinity)
                            .cardContainer()
                            
                            // Manage Subscription - only show for active subscriptions
                            if subscription.isActive {
                                VStack(spacing: 16) {
                                    Button(action: {
                                        openStripeBillingPortal()
                                    }) {
                                        HStack {
                                            Image(systemName: "creditcard.fill")
                                            Text("Update Payment Method")
                                        }
                                        .bold()
                                    }
                                    .buttonStyle(PrimaryButtonStyle())
                                    
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
                                        .background(Theme.Colors.stateIncorrect)
                                        .cornerRadius(12)
                                    }
                                }
                            }
                        }
                        
                        // Error Message
                        if let errorMessage = errorMessage {
                            Text(errorMessage)
                                .foregroundColor(Theme.Colors.stateIncorrect)
                                .font(.caption)
                                .multilineTextAlignment(.center)
                        }
                        
                        // Sign Out Button
                        VStack(spacing: 12) {
                            if let error = signOutError {
                                Text(error)
                                    .foregroundColor(Theme.Colors.stateIncorrect)
                                    .font(.caption)
                                    .multilineTextAlignment(.center)
                            }
                            
                            Button(role: .destructive) {
                                showingSignOutConfirmation = true
                            } label: {
                                Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                                    .font(.headline)
                                    .padding()
                                    .frame(maxWidth: .infinity)
                                    .background(Theme.Colors.stateIncorrect)
                                    .foregroundColor(.white)
                                    .cornerRadius(10)
                            }
                            .disabled(isSigningOut)
                            .accessibilityIdentifier("SignOutButton")
                        }
                    }
                    .padding()
                }
                .background(Color.theme.background)
                .navigationTitle("Subscription")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Close") {
                            dismiss()
                        }
                        .foregroundColor(.white)
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
        .alert("Sign Out", isPresented: $showingSignOutConfirmation) {
            Button("Cancel", role: .cancel) { }
                .accessibilityIdentifier("CancelSignOutButton")
            Button("Yes, Sign Out", role: .destructive) {
                Task {
                    await signOut()
                }
            }
            .accessibilityIdentifier("ConfirmSignOutButton")
        } message: {
            Text("Are you sure you want to sign out?")
        }
    }
    
    // MARK: - Sign Out
    private func signOut() async {
        isSigningOut = true
        signOutError = nil
        do {
            try await AuthManager.shared.signOut()
            await MainActor.run {
                isLoggedIn = false
                dismiss()
            }
        } catch {
            await MainActor.run {
                signOutError = "Failed to sign out: \(error.localizedDescription)"
            }
        }
        isSigningOut = false
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
        SubscriptionSettingsView(subscription: .constant(nil), isLoggedIn: .constant(true))
    }
}
