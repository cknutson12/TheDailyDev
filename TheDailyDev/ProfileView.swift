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
    @State private var allDailyChallenges: [DailyChallenge] = []
    @State private var isLoadingHistory = false
    @State private var userName: String = ""
    @State private var categoryPerformances: [CategoryPerformance] = []
    @State private var isLoadingCategories = false
    @State private var showingSubscriptionBenefits = false
    @State private var isLoadingSubscription = true
    @StateObject private var tourManager = OnboardingTourManager.shared
    @State private var viewFrames: [String: CGRect] = [:]
    @State private var tourTargetFrame: CGRect? = nil

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
                        if isLoadingSubscription {
                            VStack {
                                ProgressView("Loading your subscription...")
                                    .frame(maxWidth: .infinity, maxHeight: 120)
                            }
                            .cardContainer()
                            .padding(.horizontal)
                        } else if let subscription = subscriptionService.currentSubscription, subscription.isActive {
                            // Show stats for subscribers
                            if isLoadingHistory {
                                VStack {
                                    ProgressView("Loading your progress...")
                                        .frame(maxWidth: .infinity, maxHeight: 200)
                                }
                                .cardContainer()
                                .padding(.horizontal)
                            } else {
                                ContributionsTracker(
                                    progressHistory: progressHistory,
                                    allDailyChallenges: allDailyChallenges
                                )
                                .tourHighlight(isHighlighted: tourManager.shouldHighlight(identifier: "QuestionHistoryGrid"))
                                .accessibilityIdentifier("QuestionHistoryGrid")
                                .trackFrame(identifier: "QuestionHistoryGrid")
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
                                    .tourHighlight(isHighlighted: tourManager.shouldHighlight(identifier: "CategoryPerformanceView"))
                                    .accessibilityIdentifier("CategoryPerformanceView")
                                    .trackFrame(identifier: "CategoryPerformanceView")
                                    .padding(.horizontal)
                            }
                        } else {
                            // Show analytics views (blank for non-subscribers) or upgrade prompt
                            if tourManager.isTourActive {
                                // During tour, show the views even if empty so users can see them
                                ContributionsTracker(
                                    progressHistory: [],
                                    allDailyChallenges: []
                                )
                                .tourHighlight(isHighlighted: tourManager.shouldHighlight(identifier: "QuestionHistoryGrid"))
                                .accessibilityIdentifier("QuestionHistoryGrid")
                                .trackFrame(identifier: "QuestionHistoryGrid")
                                .padding(.horizontal)
                                
                                CategoryPerformanceView(categoryPerformances: [])
                                    .tourHighlight(isHighlighted: tourManager.shouldHighlight(identifier: "CategoryPerformanceView"))
                                    .accessibilityIdentifier("CategoryPerformanceView")
                                    .trackFrame(identifier: "CategoryPerformanceView")
                                    .padding(.horizontal)
                            } else {
                                // Show upgrade prompt for non-subscribers (when not in tour)
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
        .overlay {
            // Tour overlay (tooltip only, no black background)
            if tourManager.isTourActive {
                TourOverlayView(
                    tourManager: tourManager,
                    onDismiss: {
                        // Tour will handle its own dismissal
                    }
                )
            }
        }
        .onAppear {
            AnalyticsService.shared.trackScreen("profile")
            
            // Log tour state for debugging
            DebugLogger.log("📊 ProfileView appeared")
            DebugLogger.log("   Tour active: \(tourManager.isTourActive)")
            DebugLogger.log("   Current step index: \(tourManager.currentStepIndex)")
            
            // If tour is active, log the current step
            if tourManager.isTourActive, let step = tourManager.currentStep {
                DebugLogger.log("   Current step: \(step.id) - \(step.title)")
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("SubscriptionSuccess"))) { _ in
            // Dismiss subscription benefits view when subscription succeeds
            showingSubscriptionBenefits = false
        }
        .sheet(isPresented: $showingSubscriptionBenefits) {
            SubscriptionBenefitsView()
        }
        .onAppear {
            Task {
                // Force refresh subscription status when profile appears
                _ = await subscriptionService.fetchSubscriptionStatus(forceRefresh: true)
                await loadUserData()
            }
        }
    }
    
    
    // MARK: - Load User Data
    private func loadUserData() async {
        // Load subscription status - force refresh to get latest
        await MainActor.run {
            self.isLoadingSubscription = true
        }
        _ = await subscriptionService.fetchSubscriptionStatus(forceRefresh: true)
        await MainActor.run {
            self.isLoadingSubscription = false
        }
        
        // Load user display name (prioritizes profile name over email)
        let displayName = await QuestionService.shared.getUserDisplayName()
        await MainActor.run {
            self.userName = displayName
        }
        
        // Load progress history and category performance
        // Show empty/blank views for non-subscribers during tour so they can see the UI
        // For subscribers, load actual data
        if subscriptionService.currentSubscription?.isActive == true {
            await loadProgressHistory()
            await loadCategoryPerformance()
        } else if tourManager.isTourActive {
            // During tour, show empty data so users can see the UI structure
            await MainActor.run {
                self.progressHistory = []
                self.allDailyChallenges = []
                self.categoryPerformances = []
                self.isLoadingHistory = false
                self.isLoadingCategories = false
            }
        }
    }
    
    // MARK: - Load Progress History
    private func loadProgressHistory() async {
        isLoadingHistory = true
        
        // Fetch both progress history and all daily challenges in parallel
        async let history = QuestionService.shared.fetchUserProgressHistory()
        async let challenges = QuestionService.shared.fetchAllDailyChallenges()
        
        let (progressHistoryResult, challengesResult) = await (history, challenges)
        
        await MainActor.run {
            self.progressHistory = progressHistoryResult
            self.allDailyChallenges = challengesResult
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
        // Force refresh both progress history and daily challenges
        let history = await QuestionService.shared.fetchUserProgressHistory(forceRefresh: true)
        let challenges = await QuestionService.shared.fetchAllDailyChallenges(forceRefresh: true)
        
        await MainActor.run {
            self.progressHistory = history
            self.allDailyChallenges = challenges
        }
        
        // Invalidate caches to force fresh data
        QuestionService.shared.invalidateProgressCache()
        await MainActor.run {
            self.isLoadingSubscription = true
        }
        _ = await subscriptionService.fetchSubscriptionStatus(forceRefresh: true)
        await MainActor.run {
            self.isLoadingSubscription = false
        }
        
        // Reload all data
        await loadUserData()
        
        print("✅ Profile refresh complete")
    }
    
}

