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

    var body: some View {
        Group {
            if isLoadingInitialData {
                // Loading state
                VStack(spacing: 20) {
                    ProgressView()
                        .scaleEffect(1.5)
                    Text("Loading your data...")
                        .foregroundColor(.secondary)
                }
            } else {
                // Main content
                mainContent
            }
        }
        .task {
            await loadInitialData()
        }
    }
    
    var mainContent: some View {
        VStack(spacing: 30) {
            Spacer()
            
            // Welcome Section
            VStack(spacing: 16) {
                Image(systemName: "brain.head.profile")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)
                
                VStack(spacing: 8) {
                    if !userName.isEmpty {
                        Text("Welcome, \(userName)!")
                            .font(.title)
                            .bold()
                    } else {
                        Text("Welcome to The Daily Dev!")
                            .font(.title)
                            .bold()
                    }
                    
                    if currentStreak > 0 {
                        HStack {
                            Image(systemName: "flame.fill")
                                .foregroundColor(.orange)
                            Text("\(currentStreak) day streak!")
                                .font(.headline)
                                .foregroundColor(.orange)
                        }
                    }
                }
                
                Text("Challenge your system design knowledge with daily questions")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            Spacer()
            
            // Main Action Button
            VStack(spacing: 20) {
                if hasAnsweredToday {
                    VStack(spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.green)
                        
                        Text("Question Completed!")
                            .font(.title2)
                            .bold()
                        
                        Text("Check back tomorrow for a new challenge")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(16)
                } else if let subscription = subscriptionService.currentSubscription, subscription.canAccessQuestions {
                    // User has access - show play button
                    Button(action: {
                        showingQuestion = true
                    }) {
                        HStack {
                            Image(systemName: "play.circle.fill")
                                .font(.title2)
                            Text("Answer Today's System Design Question")
                                .font(.headline)
                        }
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .cornerRadius(12)
                    }
                    .padding(.horizontal)
                } else {
                    // User needs subscription - show locked state
                    VStack(spacing: 16) {
                        Image(systemName: "crown.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.yellow)
                        
                        Text("Subscription Required")
                            .font(.title2)
                            .bold()
                        
                        Text(subscriptionService.currentSubscription?.accessStatusMessage ?? "Activate Subscription to View Today's Questions")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        
                        Button(action: {
                            showingSubscriptionBenefits = true
                        }) {
                            HStack {
                                Image(systemName: "crown.fill")
                                    .font(.title3)
                                Text("Subscribe Now")
                                    .font(.headline)
                            }
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.yellow)
                            .cornerRadius(12)
                        }
                        .padding(.horizontal)
                    }
                    .padding()
                    .background(Color.yellow.opacity(0.1))
                    .cornerRadius(16)
                    .padding(.horizontal)
                }
            }
            
            Spacer()
        }
        .navigationTitle("The Daily Dev")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                NavigationLink(destination: ProfileView(isLoggedIn: $isLoggedIn)) {
                    Image(systemName: "person.circle.fill")
                        .font(.title2)
                }
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
                    let answered = await QuestionService.shared.hasAnsweredToday()
                    await MainActor.run {
                        hasAnsweredToday = answered
                    }
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
    }
    
    private func loadInitialData() async {
        // Load subscription status
        await subscriptionService.fetchSubscriptionStatus()
        
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
    
    private func checkIfAnsweredToday() async {
        let answered = await QuestionService.shared.hasAnsweredToday()
        await MainActor.run {
            hasAnsweredToday = answered
        }
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
