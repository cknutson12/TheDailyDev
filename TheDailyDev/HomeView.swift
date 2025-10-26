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
    @State private var showingQuestion = false
    @State private var hasAnsweredToday = false
    @State private var userName: String = ""
    @State private var currentStreak: Int = 0

    var body: some View {
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
                } else {
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
        .task {
            await loadUserData()
        }
    }
    
    private func loadUserData() async {
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
    }
    
    private func checkIfAnsweredToday() async {
        // Check if user has already answered today's question
        // For now, we'll set this to false - you can implement actual checking later
        hasAnsweredToday = false
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
                    MultipleChoiceQuestionView(
                        question: question,
                        onComplete: {
                            hasAnsweredToday = true
                            showingCompletion = true
                        }
                    )
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
    }
}
