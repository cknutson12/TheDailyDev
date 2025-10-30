//
//  ProfileView.swift
//  TheDailyDev
//
//  Created by Claire Knutson on 10/15/25.
//

import SwiftUI
import Supabase

struct ProfileView: View {
    @Binding var isLoggedIn: Bool
    @Environment(\.dismiss) private var dismiss
    @StateObject private var subscriptionService = SubscriptionService.shared
    @State private var isSigningOut = false
    @State private var signOutError: String?
    @State private var progressHistory: [UserProgressWithQuestion] = []
    @State private var isLoadingHistory = false
    @State private var userName: String = ""
    @State private var categoryPerformances: [CategoryPerformance] = []
    @State private var isLoadingCategories = false
    @State private var showingSubscriptionSettings = false
    @State private var showingSubscriptionBenefits = false

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 24) {
                    // User Stats Header
                    if !userName.isEmpty {
                        Text("\(userName) Stats")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .minimumScaleFactor(0.5)
                            .lineLimit(1)
                            .padding(.horizontal, 20)
                            .padding(.top, 20)
                    }
                    
                    // Subscription Status
                    if let subscription = subscriptionService.currentSubscription {
                        if subscription.isActive {
                            // Show stats for subscribers
                            if isLoadingHistory {
                                VStack {
                                    ProgressView("Loading your progress...")
                                        .frame(maxWidth: .infinity, maxHeight: 200)
                                }
                            } else {
                                ContributionsTracker(progressHistory: progressHistory)
                                    .padding(.horizontal)
                            }
                            
                            if isLoadingCategories {
                                VStack {
                                    ProgressView("Loading category performance...")
                                        .frame(maxWidth: .infinity, maxHeight: 100)
                                }
                            } else {
                                CategoryPerformanceView(categoryPerformances: categoryPerformances)
                                    .padding(.horizontal)
                            }
                        } else {
                            // Show upgrade prompt for non-subscribers
                            VStack(spacing: 16) {
                                Image(systemName: "crown.fill")
                                    .font(.system(size: 50))
                                    .foregroundColor(.yellow)
                                
                                Text("Upgrade to See Question Stats")
                                    .font(.title2)
                                    .bold()
                                
                                Text("Unlock detailed analytics, question history, and performance tracking with a subscription")
                                    .font(.body)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                                
                                Button(action: {
                                    showingSubscriptionBenefits = true
                                }) {
                                    HStack {
                                        Image(systemName: "crown.fill")
                                        Text("Subscribe Now")
                                    }
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .padding()
                                    .frame(maxWidth: .infinity)
                                    .background(Color.yellow)
                                    .cornerRadius(12)
                                }
                            }
                            .padding()
                            .background(Color.yellow.opacity(0.1))
                            .cornerRadius(16)
                            .padding(.horizontal)
                        }
                    } else {
                        // No subscription - show benefits
                        SubscriptionBenefitsView(
                            onSubscribe: {
                                Task {
                                    await handleSubscription()
                                }
                            }
                        )
                        .padding(.horizontal)
                    }
                }
                .padding(.bottom, 20)
            }
            
            // Sign Out Button at Bottom
            VStack(spacing: 12) {
                if let error = signOutError {
                    Text(error)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }

                Button(role: .destructive) {
                    Task { await signOut() }
                } label: {
                    if isSigningOut {
                        HStack {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                            Text("Signing Out...")
                        }
                        .font(.headline)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.red)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    } else {
                        Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                            .font(.headline)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.red)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                }
                .disabled(isSigningOut)
                .padding(.horizontal)
                .padding(.bottom, 20)
            }
            .background(Color(UIColor.systemBackground))
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    showingSubscriptionSettings = true
                }) {
                    Image(systemName: "gearshape.fill")
                        .font(.title3)
                }
            }
        }
        .sheet(isPresented: $showingSubscriptionBenefits) {
            SubscriptionBenefitsView(
                onSubscribe: {
                    Task {
                        await handleSubscription()
                    }
                }
            )
        }
        .sheet(isPresented: $showingSubscriptionSettings) {
            if let subscription = subscriptionService.currentSubscription {
                SubscriptionSettingsView(subscription: .constant(subscription))
            } else {
                SubscriptionSettingsView(subscription: .constant(nil))
            }
        }
        .onAppear {
            Task {
                await loadUserData()
            }
        }
    }
    
    // MARK: - Handle Subscription
    private func handleSubscription() async {
        do {
            let checkoutURL = try await subscriptionService.createCheckoutSession()
            await MainActor.run {
                UIApplication.shared.open(checkoutURL)
            }
        } catch {
            print("Failed to create checkout session: \(error)")
        }
    }
    
    // MARK: - Load User Data
    private func loadUserData() async {
        // Load subscription status
        await subscriptionService.fetchSubscriptionStatus()
        
        // Load user display name (prioritizes profile name over email)
        let displayName = await QuestionService.shared.getUserDisplayName()
        await MainActor.run {
            self.userName = displayName
        }
        
        // Load progress history and category performance (only for subscribers)
        if subscriptionService.currentSubscription?.isActive == true {
            await loadProgressHistory()
            await loadCategoryPerformance()
        }
    }
    
    // MARK: - Load Progress History
    private func loadProgressHistory() async {
        isLoadingHistory = true
        
        let history = await QuestionService.shared.fetchUserProgressHistory()
        
        await MainActor.run {
            self.progressHistory = history
            self.isLoadingHistory = false
        }
    }
    
    // MARK: - Load Category Performance
    private func loadCategoryPerformance() async {
        isLoadingCategories = true
        
        let performances = await QuestionService.shared.calculateCategoryPerformance()
        
        await MainActor.run {
            self.categoryPerformances = performances
            self.isLoadingCategories = false
        }
    }
    
    // MARK: - Sign Out Function
    private func signOut() async {
        print("🔄 Starting sign out process...")
        isSigningOut = true
        signOutError = nil
        
        do {
            // Sign out from Supabase
            print("🔐 Calling Supabase sign out...")
            try await SupabaseManager.shared.client.auth.signOut()
            print("✅ Supabase sign out successful")
            
            // Update local state to return to login screen
            await MainActor.run {
                print("🔄 Updating UI state...")
                isLoggedIn = false
                isSigningOut = false
                print("📱 Dismissing ProfileView...")
                // Dismiss the ProfileView to return to HomeView, which will then show LoginView
                dismiss()
                print("✅ Sign out process completed")
            }
        } catch {
            print("❌ Sign out failed: \(error.localizedDescription)")
            await MainActor.run {
                signOutError = "Sign out failed: \(error.localizedDescription)"
                isSigningOut = false
            }
        }
    }
}

