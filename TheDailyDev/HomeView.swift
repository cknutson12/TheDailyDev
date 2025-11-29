//
//  HomeView.swift
//  TheDailyDev
//
//  Created by Claire Knutson on 10/15/25.
//

import SwiftUI

struct HomeView: View {
    @Binding var isLoggedIn: Bool
    @StateObject private var questionService = QuestionService.shared
    @StateObject private var subscriptionService = SubscriptionService.shared
    @State private var showingQuestion = false
    @State private var hasAnsweredToday = false
    @State private var userName: String = ""
    @State private var currentStreak: Int = 0
    @State private var showingSubscriptionBenefits = false
    @State private var isLoadingInitialData = true
    @State private var canAccessQuestions = false
    @State private var hasAnsweredBefore = false
    @State private var showingFirstQuestionComplete = false
    @State private var currentPlan: SubscriptionPlan?
    
    // Splash messages (Minecraft-style)
    private let splashMessages = [
        "Who's on call right now?",
        "Mmmm caching",
        "Now with more queues!",
        "One does not simply scale vertically.",
        "Eventual consistency achieved!",
        "Did you invalidate the cache?",
        "Just one more index…",
        "It's always DNS",
        "REST in peace",
        "Never use GraphQL",
        "Have you tried turning it off and on again?",
        "Distributed systems are hard!",
        "CAP theorem says no",
        "Microservices everywhere!",
        "Monolith Monday",
        "Sharding is caring",
        "ACID or BASE?",
        "The cloud is just someone else's computer",
        "Kubernetes ate my homework",
        "Docker all the things!",
        "Serverless? More like server-less-problems!",
        "Redis to the rescue!",
        "PostgreSQL > MySQL (fight me)",
        "NoSQL? More like NoThankYouSQL!",
        "Premature optimization is the root of all evil",
        "Works on my machine ¯\\_(ツ)_/¯",
        "In production? Better hope it scales!",
        "99.9% uptime... most of the time",
        "Load balancer goes brrr",
        "Cache invalidation: one of the two hard problems"
    ]
    
    // Get daily splash message (consistent per day)
    private var dailySplashMessage: String {
        let calendar = Calendar.current
        let dayOfYear = calendar.ordinality(of: .day, in: .year, for: Date()) ?? 0
        let index = dayOfYear % splashMessages.count
        return splashMessages[index]
    }

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
            
            if isLoadingInitialData {
                // Loading state
                VStack(spacing: 20) {
                    ProgressView()
                        .scaleEffect(1.5)
                    Text("Loading your data...")
                        .foregroundColor(Color.theme.textSecondary)
                }
            } else {
                // Main content
                mainContent
            }
        }
        .preferredColorScheme(.dark)
        .task {
            await loadInitialData()
            // Fetch current plan for pricing display
            currentPlan = await subscriptionService.fetchCurrentPlan()
        }
    }
    
    var mainContent: some View {
        ScrollView {
            VStack(spacing: 30) {
                Spacer()
                    .frame(height: 20)
            
            // Welcome Section
            VStack(spacing: 16) {
                Image("AppLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 120, height: 120)
                
                VStack(spacing: 8) {
                    if !userName.isEmpty {
                        Text("Welcome, \(userName)!")
                            .font(.system(size: 28, weight: .heavy, design: .monospaced))
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
                    } else {
                        Text("Welcome to The Daily Dev!")
                            .font(.system(size: 28, weight: .heavy, design: .monospaced))
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
                    }
                    
                    if currentStreak > 0 {
                        HStack {
                            Image(systemName: "flame.fill")
                                .foregroundColor(Color.theme.stateCorrect)
                            Text("\(currentStreak) day streak!")
                                .font(.headline)
                                .foregroundColor(Color.theme.stateCorrect)
                        }
                    }
                }
                
                Text(dailySplashMessage)
                    .font(.body)
                    .italic()
                    .foregroundColor(Color.theme.accentGreen.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            Spacer()
            
            // Main Action Button
            VStack(spacing: 20) {
                if hasAnsweredToday {
                    VStack(spacing: 16) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 40))
                            .foregroundColor(Color.theme.stateCorrect)
                        
                        Text("Question Completed!")
                            .font(.title2)
                            .bold()
                            .foregroundColor(.white)
                        
                        // Show different message based on subscription status
                        if subscriptionService.currentSubscription?.isActive == true {
                            Text("Check back tomorrow for a new challenge")
                                .font(.body)
                                .foregroundColor(Color.theme.textSecondary)
                                .multilineTextAlignment(.center)
                        } else {
                            // Non-subscriber: Show subscribe CTA
                            VStack(spacing: 12) {
                                Text("Want to practice daily?")
                                    .font(.body)
                                    .foregroundColor(Color.theme.textSecondary)
                                    .multilineTextAlignment(.center)
                                
                                Button(action: {
                                    showingSubscriptionBenefits = true
                                }) {
                                    Text("Start 7-Day Free Trial")
                                        .font(.headline)
                                        .foregroundColor(.black)
                                        .padding(.vertical, 12)
                                        .frame(maxWidth: .infinity)
                                }
                                .buttonStyle(PrimaryButtonStyle())
                                
                                Text("Or come back Friday for your next free question")
                                    .font(.caption)
                                    .foregroundColor(Color.theme.textSecondary)
                                    .multilineTextAlignment(.center)
                            }
                        }
                    }
                    .padding()
                    .background(Theme.Colors.surface)
                    .overlay(
                        RoundedRectangle(cornerRadius: Theme.Metrics.cornerRadius)
                            .stroke(Theme.Colors.border, lineWidth: 1)
                    )
                    .cornerRadius(Theme.Metrics.cornerRadius)
                } else if canAccessQuestions {
                    // User has access - show play button
                    Button(action: {
                        showingQuestion = true
                    }) {
                        HStack {
                            Image(systemName: "play.circle.fill")
                                .font(.title2)
                            // Only show "First Free Question" if they have no subscription/trial AND haven't answered before
                            Text(getQuestionButtonText())
                                .font(.headline)
                        }
                        .foregroundColor(.black)
                        .padding(.vertical, 14)
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .padding(.horizontal)
                    
                    // Show Friday or first question message if applicable
                    if !hasAnsweredBefore && subscriptionService.currentSubscription?.isActive != true {
                        Text("Your first question is free - no subscription needed!")
                            .font(.caption)
                            .foregroundColor(Theme.Colors.textSecondary)
                            .multilineTextAlignment(.center)
                    } else if subscriptionService.currentSubscription?.isActive != true {
                        // Must be Friday (non-subscriber with previous answers)
                        Text("🎉 Free Friday Question!")
                            .font(.caption)
                            .foregroundColor(Theme.Colors.accentGreen)
                    }
                    // Don't show trial status on home screen - keep it clean
                } else {
                    // User needs subscription - show locked state
                    VStack(spacing: 16) {
                        Image(systemName: "crown.fill")
                            .font(.system(size: 50))
                            .foregroundColor(Color.theme.accentGreen)
                        
                        Text("Start Your Free Trial")
                            .font(.title2)
                            .bold()
                            .foregroundColor(.white)
                        
                        if let plan = currentPlan {
                            Text("Get \(plan.trialDays) days free, then \(plan.formattedPrice)")
                                .font(.body)
                                .foregroundColor(Color.theme.textSecondary)
                                .multilineTextAlignment(.center)
                        } else {
                            Text("Get 7 days free, then $4.99/month")
                                .font(.body)
                                .foregroundColor(Color.theme.textSecondary)
                                .multilineTextAlignment(.center)
                        }
                        
                        Text("Or wait until Friday for your next free question")
                            .font(.caption)
                            .foregroundColor(Color.theme.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.top, 4)
                        
                        Button(action: {
                            showingSubscriptionBenefits = true
                        }) {
                            HStack {
                                Image(systemName: "crown.fill")
                                    .font(.title3)
                                Text("Start Free Trial")
                                    .font(.headline)
                            }
                            .foregroundColor(.black)
                            .padding(.vertical, 14)
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(PrimaryButtonStyle())
                        .padding(.horizontal)
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
            
            Spacer()
                    .frame(height: 20)
            }
        }
        .refreshable {
            // Pull-to-refresh: Force refresh subscription and answered status
            await refreshData()
        }
        .navigationTitle("")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                NavigationLink(destination: ProfileView(isLoggedIn: $isLoggedIn)) {
                    Image(systemName: "person.circle.fill")
                        .font(.title2)
                }
                .accessibilityIdentifier("ProfileButton")
            }
        }
        .sheet(isPresented: $showingQuestion) {
            QuestionView(
                isPresented: $showingQuestion,
                hasAnsweredToday: $hasAnsweredToday
            )
        }
        .onChange(of: showingQuestion) { oldValue, newValue in
            // When question sheet is dismissed, refresh answered status
            if oldValue && !newValue {
                Task {
                    // Check if they actually answered (not just dismissed)
                    let answered = await QuestionService.shared.hasAnsweredToday()
                    let hasAnswered = await questionService.hasAnsweredAnyQuestion()
                    let wasFirstQuestion = !hasAnsweredBefore && hasAnswered
                    
                    await MainActor.run {
                        hasAnsweredToday = answered
                        hasAnsweredBefore = hasAnswered
                        
                        // If they just completed their first question AND don't have active subscription, show trial popup
                        if wasFirstQuestion && subscriptionService.currentSubscription?.isActive != true {
                            // Small delay to ensure smooth transition
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                showingFirstQuestionComplete = true
                            }
                        }
                    }
                    
                    // If they answered, invalidate caches
                    if answered {
                        subscriptionService.invalidateCache() // For trial status
                        questionService.invalidateProgressCache() // For stats refresh
                    }
                    
                    // Refresh access status (this will use fresh data if cache was invalidated)
                    let canAccess = await subscriptionService.canAccessQuestions()
                    await MainActor.run {
                        canAccessQuestions = canAccess
                    }
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("SubscriptionSuccess"))) { _ in
            // Dismiss subscription benefits view when subscription succeeds
            showingSubscriptionBenefits = false
        }
        .sheet(isPresented: $showingSubscriptionBenefits) {
            SubscriptionBenefitsView(
                onSubscribe: { plan, skipTrial in
                    Task {
                        await handleSubscription(plan: plan, skipTrial: skipTrial)
                    }
                }
            )
        }
        .sheet(isPresented: $showingFirstQuestionComplete) {
            FirstQuestionCompleteView()
        }
    }
    
    // MARK: - Refresh Data (Pull-to-Refresh)
    private func refreshData() async {
        print("🔄 Manual refresh triggered")
        
        // Invalidate question cache to force fresh fetch
        questionService.invalidateQuestionCache()
        
        // Force refresh subscription status
        _ = await subscriptionService.fetchSubscriptionStatus(forceRefresh: true)
        
        // Re-check access
        let canAccess = await subscriptionService.canAccessQuestions()
        await MainActor.run {
            self.canAccessQuestions = canAccess
        }
        
        // Re-check answered status
        let answered = await QuestionService.shared.hasAnsweredToday()
        await MainActor.run {
            self.hasAnsweredToday = answered
        }
        
        print("✅ Manual refresh complete")
    }
    
    private func loadInitialData() async {
        // Load subscription status (uses cache if available)
        _ = await subscriptionService.fetchSubscriptionStatus()
        
        // Check if user has answered any question before
        let answered = await questionService.hasAnsweredAnyQuestion()
        await MainActor.run {
            self.hasAnsweredBefore = answered
        }
        
        // Check if user can access questions
        let canAccess = await subscriptionService.canAccessQuestions()
        await MainActor.run {
            self.canAccessQuestions = canAccess
        }
        
        // Load user display name (prioritizes profile name over email)
        let displayName = await QuestionService.shared.getUserDisplayName()
        await MainActor.run {
            self.userName = displayName
        }
        
        // Load current streak
        let streak = await QuestionService.shared.calculateCurrentStreak()
        await MainActor.run {
            self.currentStreak = streak
        }
        
        // Check if answered today
        await checkIfAnsweredToday()
        
        // Mark as loaded
        await MainActor.run {
            self.isLoadingInitialData = false
        }
    }
    
    // MARK: - Handle Subscription
    private func handleSubscription(plan: SubscriptionPlan, skipTrial: Bool = false) async {
        do {
            // Use the new trial flow for all subscription signups
            let checkoutURL = try await subscriptionService.getCheckoutURL(plan: plan, skipTrial: skipTrial)
            await MainActor.run {
                UIApplication.shared.open(checkoutURL)
            }
        } catch {
            print("Failed to initiate trial setup: \(error)")
        }
    }
    
    private func checkIfAnsweredToday() async {
        let answered = await QuestionService.shared.hasAnsweredToday()
        await MainActor.run {
            hasAnsweredToday = answered
        }
    }
    
    // MARK: - Get Question Button Text
    private func getQuestionButtonText() -> String {
        // If user has active subscription or trial, always show standard text
        if subscriptionService.currentSubscription?.isActive == true {
            return "Answer Today's Question"
        }
        
        // Otherwise, show "first free question" only if they've never answered
        return hasAnsweredBefore ? "Answer Today's Question" : "Answer Your First Free Question"
    }
}

// MARK: - Question View
struct QuestionView: View {
    @Binding var isPresented: Bool
    @Binding var hasAnsweredToday: Bool
    @StateObject private var questionService = QuestionService.shared
    @State private var showingCompletion = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack {
                    if questionService.isLoading {
                        ProgressView("Loading today's question...")
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else if let errorMessage = questionService.errorMessage {
                        VStack(spacing: 16) {
                            Image(systemName: "exclamationmark.triangle")
                                .font(.largeTitle)
                                .foregroundColor(.orange)
                            
                            Text("Oops!")
                                .font(.title2)
                                .bold()
                            
                            Text(errorMessage)
                                .multilineTextAlignment(.center)
                                .foregroundColor(.secondary)
                            
                            Button("Try Again") {
                                Task {
                                    await questionService.fetchTodaysQuestion()
                                }
                            }
                            .buttonStyle(.borderedProminent)
                        }
                        .padding()
                    } else if let question = questionService.todaysQuestion {
                            // Route to appropriate question view based on type
                            if question.content.orderingItems != nil {
                                OrderingQuestionView(
                                    question: question,
                                    onComplete: {
                                        Task {
                                            // Invalidate caches immediately after answering
                                            QuestionService.shared.invalidateProgressCache()
                                            SubscriptionService.shared.invalidateCache()
                                            
                                            // Now fetch fresh data
                                            let answered = await QuestionService.shared.hasAnsweredToday()
                                            await MainActor.run {
                                                hasAnsweredToday = answered
                                                showingCompletion = true
                                            }
                                        }
                                    }
                                )
                            } else if question.content.matchingItems != nil {
                                MatchingQuestionView(
                                    question: question,
                                    onComplete: {
                                        Task {
                                            // Invalidate caches immediately after answering
                                            QuestionService.shared.invalidateProgressCache()
                                            SubscriptionService.shared.invalidateCache()
                                            
                                            // Now fetch fresh data
                                            let answered = await QuestionService.shared.hasAnsweredToday()
                                            await MainActor.run {
                                                hasAnsweredToday = answered
                                                showingCompletion = true
                                            }
                                        }
                                    }
                                )
                            } else {
                                MultipleChoiceQuestionView(
                                    question: question,
                                    onComplete: {
                                        Task {
                                            // Invalidate caches immediately after answering
                                            QuestionService.shared.invalidateProgressCache()
                                            SubscriptionService.shared.invalidateCache()
                                            
                                            // Now fetch fresh data
                                            let answered = await QuestionService.shared.hasAnsweredToday()
                                            await MainActor.run {
                                                hasAnsweredToday = answered
                                                showingCompletion = true
                                            }
                                        }
                                    }
                                )
                            }
                } else {
                    VStack(spacing: 16) {
                        Image(systemName: "questionmark.circle")
                            .font(.largeTitle)
                            .foregroundColor(.blue)
                        
                        Text("No Question Today")
                            .font(.title2)
                            .bold()
                        
                        Text("Check back tomorrow for a new system design challenge!")
                            .multilineTextAlignment(.center)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                }
                }
            }
            .refreshable {
                // Pull-to-refresh: Invalidate cache and fetch fresh question
                questionService.invalidateQuestionCache()
                await questionService.fetchTodaysQuestion()
            }
            .navigationTitle("Today's Question")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        isPresented = false
                    }
                }
            }
        }
        .alert("Question Completed!", isPresented: $showingCompletion) {
            Button("OK") {
                isPresented = false
            }
        } message: {
            Text("You have answered today's question. Check back tomorrow!")
        }
        .task {
            await questionService.fetchTodaysQuestion()
        }
        .onAppear {
            // Refresh answered status when view appears
            Task {
                let answered = await QuestionService.shared.hasAnsweredToday()
                await MainActor.run {
                    hasAnsweredToday = answered
                }
            }
        }
    }
}
