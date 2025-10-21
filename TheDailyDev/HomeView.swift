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

    var body: some View {
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
                MultipleChoiceQuestionView(question: question)
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
        .navigationTitle("Today's Challenge")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                NavigationLink(destination: ProfileView(isLoggedIn: $isLoggedIn)) {
                    Image(systemName: "person.circle.fill")
                        .font(.title2)
                }
            }
        }
        .task {
            await questionService.fetchTodaysQuestion()
        }
    }
}
