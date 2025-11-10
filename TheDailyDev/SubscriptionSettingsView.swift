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
                        Spacer()
                            .frame(height: 20)
                        
                        // MARK: - Feedback Section
                        Text("Feedback")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal)
                        
                        NavigationLink(destination: FeedbackView()) {
                            HStack {
                                Image(systemName: "envelope.fill")
                                    .font(.title3)
                                    .foregroundColor(Theme.Colors.accentGreen)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Send Feedback")
                                        .font(.headline)
                                        .foregroundColor(.white)
                                    Text("Share your thoughts or report issues")
                                        .font(.caption)
                                        .foregroundColor(Color.theme.textSecondary)
                                }
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .foregroundColor(Color.theme.textSecondary)
                            }
                            .padding()
                            .cardContainer()
                        }
                        
                        Spacer()
                            .frame(height: 20)
                        
                        // MARK: - Subscription Section
                        Text("Subscription")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal)
                        
                        if let subscription = subscription {
                            // View Subscription Details - only show for active subscriptions or trials
                            if subscription.isActive {
                                NavigationLink(destination: SubscriptionDetailsView(subscription: subscription)) {
                                    HStack {
                                        Image(systemName: "doc.text.fill")
                                            .font(.title3)
                                            .foregroundColor(Theme.Colors.accentGreen)
                                        
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text("View Subscription Details")
                                                .font(.headline)
                                                .foregroundColor(.white)
                                            Text("See pricing, billing date, and manage your subscription")
                                                .font(.caption)
                                                .foregroundColor(Color.theme.textSecondary)
                                        }
                                        
                                        Spacer()
                                        
                                        Image(systemName: "chevron.right")
                                            .foregroundColor(Color.theme.textSecondary)
                                    }
                                    .padding()
                                    .cardContainer()
                                }
                            } else {
                                // For non-subscribers, show subscribe option
                                VStack(spacing: 8) {
                                    Text("No Active Subscription")
                                        .font(.subheadline)
                                        .foregroundColor(Color.theme.textSecondary)
                                    
                                    Text("Subscribe to unlock full access")
                                        .font(.caption)
                                        .foregroundColor(Color.theme.textSecondary)
                                }
                                .padding()
                                .frame(maxWidth: .infinity)
                                .cardContainer()
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
                .navigationTitle("Settings")
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
