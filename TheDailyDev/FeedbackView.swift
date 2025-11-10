//
//  FeedbackView.swift
//  TheDailyDev
//
//  Created by Claire Knutson on 11/9/24.
//

import SwiftUI

struct FeedbackView: View {
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedCategory: FeedbackCategory = .featureRequest
    @State private var feedbackMessage = ""
    @State private var showingFeedbackSuccess = false
    @State private var feedbackError: String?
    @State private var isSubmittingFeedback = false
    
    var body: some View {
        ZStack {
            Color.theme.background.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    Spacer()
                        .frame(height: 20)
                    
                    // Header Icon
                    Image(systemName: "envelope.fill")
                        .font(.system(size: 60))
                        .foregroundColor(Theme.Colors.accentGreen)
                    
                    // Title & Description
                    VStack(spacing: 8) {
                        Text("Send Feedback")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Text("Help us improve The Daily Dev")
                            .font(.body)
                            .foregroundColor(Theme.Colors.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    
                    // Feedback Form
                    VStack(spacing: 20) {
                        // Category picker
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Category")
                                .font(.subheadline)
                                .foregroundColor(Theme.Colors.textSecondary)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(FeedbackCategory.allCases, id: \.self) { category in
                                        Button(action: {
                                            selectedCategory = category
                                        }) {
                                            HStack(spacing: 6) {
                                                Image(systemName: category.icon)
                                                    .font(.caption)
                                                Text(category.rawValue)
                                                    .font(.subheadline)
                                            }
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 10)
                                            .background(selectedCategory == category ? Theme.Colors.accentGreen : Theme.Colors.surface)
                                            .foregroundColor(selectedCategory == category ? .black : Theme.Colors.textPrimary)
                                            .cornerRadius(20)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 20)
                                                    .stroke(selectedCategory == category ? Theme.Colors.accentGreen : Theme.Colors.border, lineWidth: 1)
                                            )
                                        }
                                    }
                                }
                            }
                        }
                        
                        // Text editor for feedback
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Message")
                                .font(.subheadline)
                                .foregroundColor(Theme.Colors.textSecondary)
                            
                            ZStack(alignment: .topLeading) {
                                if feedbackMessage.isEmpty {
                                    Text("Share your thoughts, report bugs, or suggest features...")
                                        .foregroundColor(Theme.Colors.textSecondary)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 12)
                                }
                                
                                TextEditor(text: $feedbackMessage)
                                    .frame(minHeight: 150)
                                    .foregroundColor(Theme.Colors.textPrimary)
                                    .scrollContentBackground(.hidden)
                                    .background(Color.clear)
                                    .padding(4)
                            }
                            .background(Theme.Colors.background)
                            .overlay(
                                RoundedRectangle(cornerRadius: Theme.Metrics.cornerRadius)
                                    .stroke(Theme.Colors.border, lineWidth: 1)
                            )
                            .cornerRadius(Theme.Metrics.cornerRadius)
                        }
                        
                        // Character count
                        HStack {
                            Spacer()
                            Text("\(feedbackMessage.count)/2000")
                                .font(.caption)
                                .foregroundColor(feedbackMessage.count > 2000 ? Theme.Colors.stateIncorrect : Theme.Colors.textSecondary)
                        }
                        
                        // Success message
                        if showingFeedbackSuccess {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(Theme.Colors.stateCorrect)
                                Text("Thank you! Your feedback has been submitted.")
                                    .font(.subheadline)
                                    .foregroundColor(Theme.Colors.stateCorrect)
                            }
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Theme.Colors.stateCorrect.opacity(0.1))
                            .cornerRadius(Theme.Metrics.cornerRadius)
                        }
                        
                        // Error message
                        if let error = feedbackError {
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(Theme.Colors.stateIncorrect)
                                Text(error)
                                    .font(.subheadline)
                                    .foregroundColor(Theme.Colors.stateIncorrect)
                            }
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Theme.Colors.stateIncorrect.opacity(0.1))
                            .cornerRadius(Theme.Metrics.cornerRadius)
                        }
                        
                        // Submit button
                        Button(action: {
                            Task {
                                await submitFeedback()
                            }
                        }) {
                            if isSubmittingFeedback {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .black))
                            } else {
                                HStack {
                                    Image(systemName: "paperplane.fill")
                                    Text("Submit Feedback")
                                }
                                .font(.headline)
                            }
                        }
                        .buttonStyle(PrimaryButtonStyle())
                        .disabled(feedbackMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || feedbackMessage.count > 2000 || isSubmittingFeedback)
                    }
                    .padding()
                    .cardContainer()
                    
                    Spacer()
                }
                .padding()
            }
        }
        .preferredColorScheme(.dark)
        .navigationTitle("Feedback")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // MARK: - Submit Feedback
    private func submitFeedback() async {
        isSubmittingFeedback = true
        feedbackError = nil
        showingFeedbackSuccess = false
        
        do {
            try await FeedbackService.shared.submitFeedback(category: selectedCategory, message: feedbackMessage)
            
            await MainActor.run {
                showingFeedbackSuccess = true
                feedbackMessage = "" // Clear the text field
                isSubmittingFeedback = false
            }
            
            // Hide success message after 3 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                showingFeedbackSuccess = false
            }
        } catch FeedbackService.FeedbackError.emptyMessage {
            await MainActor.run {
                feedbackError = "Please enter a message"
                isSubmittingFeedback = false
            }
        } catch FeedbackService.FeedbackError.messageTooLong {
            await MainActor.run {
                feedbackError = "Message is too long (max 2000 characters)"
                isSubmittingFeedback = false
            }
        } catch {
            await MainActor.run {
                feedbackError = "Failed to submit feedback. Please try again."
                isSubmittingFeedback = false
            }
        }
    }
}

struct FeedbackView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            FeedbackView()
        }
    }
}

