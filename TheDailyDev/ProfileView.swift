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
    @State private var progressHistory: [UserProgressWithQuestion] = []
    @State private var isLoadingHistory = false
    @State private var userName: String = ""
    @State private var categoryPerformances: [CategoryPerformance] = []
    @State private var isLoadingCategories = false
    @State private var showingSubscriptionSettings = false
    @State private var showingSubscriptionBenefits = false

    var body: some View {
        ZStack {
            // Gradient background for depth
            LinearGradient(
                colors: [
                    Color.black,
                    Color(red: 0.08, green: 0.20, blue: 0.14)  // Lighter dark green tint at bottom
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: 16) {
                        // User Statistics Header
                        if !userName.isEmpty {
                            Text("\(userName)'s Statistics")
                                .font(.system(size: 34, weight: .heavy, design: .monospaced))
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
                                .minimumScaleFactor(0.5)
                                .lineLimit(1)
                                .padding(.horizontal, 20)
                                .padding(.top, 16)
                        }
                        
                        // Subscription Status
                        if let subscription = subscriptionService.currentSubscription, subscription.isActive {
                            // Show stats for subscribers
                            if isLoadingHistory {
                                VStack {
                                    ProgressView("Loading your progress...")
                                        .frame(maxWidth: .infinity, maxHeight: 200)
                                }
                                .cardContainer()
                                .padding(.horizontal)
                            } else {
                                ContributionsTracker(progressHistory: progressHistory)
                                    .padding(.horizontal)
                            }
                            
                            if isLoadingCategories {
                                VStack {
                                    ProgressView("Loading category performance...")
                                        .frame(maxWidth: .infinity, maxHeight: 100)
                                }
                                .cardContainer()
                                .padding(.horizontal)
                            } else {
                                CategoryPerformanceView(categoryPerformances: categoryPerformances)
                                    .padding(.horizontal)
                            }
                        } else {
                            // Show upgrade prompt for non-subscribers
                            VStack(spacing: 16) {
                                Image(systemName: "crown.fill")
                                    .font(.system(size: 50))
                                    .foregroundColor(Color.theme.accentGreen)
                                
                                Text("Upgrade to See Question Stats")
                                    .font(.title2)
                                    .bold()
                                    .foregroundColor(.white)
                                
                                Text("Unlock detailed analytics, question history, and performance tracking with a subscription")
                                    .font(.body)
                                    .foregroundColor(Color.theme.textSecondary)
                                    .multilineTextAlignment(.center)
                                
                                Button(action: {
                                    showingSubscriptionBenefits = true
                                }) {
                                    Text("See Benefits")
                                        .bold()
                                }
                                .buttonStyle(PrimaryButtonStyle())
                            }
                            .padding()
                            .background(Theme.Colors.surface)
                            .overlay(
                                RoundedRectangle(cornerRadius: Theme.Metrics.cornerRadius)
                                    .stroke(Theme.Colors.border, lineWidth: 1)
                            )
                            .cornerRadius(Theme.Metrics.cornerRadius)
                            .padding(.horizontal)
                        }
                    }
                    .padding(.bottom, 16)
                }
                .refreshable {
                    // Pull-to-refresh: Force refresh all data
                    await refreshProfileData()
                }
            }
        }
        .preferredColorScheme(.dark)
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    showingSubscriptionSettings = true
                }) {
                    Image(systemName: "gearshape.fill")
                        .font(.title3)
                        .foregroundColor(.white)
                }
                .accessibilityIdentifier("SettingsButton")
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
                SubscriptionSettingsView(subscription: .constant(subscription), isLoggedIn: $isLoggedIn)
            } else {
                SubscriptionSettingsView(subscription: .constant(nil), isLoggedIn: $isLoggedIn)
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
        _ = await subscriptionService.fetchSubscriptionStatus()
        
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
    
    // MARK: - Refresh Profile Data (Pull-to-Refresh)
    private func refreshProfileData() async {
        print("🔄 Profile manual refresh triggered")
        
        // Invalidate caches to force fresh data
        QuestionService.shared.invalidateProgressCache()
        await subscriptionService.fetchSubscriptionStatus(forceRefresh: true)
        
        // Reload all data
        await loadUserData()
        
        print("✅ Profile refresh complete")
    }
    
}

