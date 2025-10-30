import SwiftUI

struct MultipleChoiceQuestionView: View {
    let question: Question
    let onComplete: (() -> Void)?
    @State private var selectedOptionId: String?
    @State private var showResult = false
    @State private var isCorrect = false
    @State private var timeStarted = Date()
    
    init(question: Question, onComplete: (() -> Void)? = nil) {
        self.question = question
        self.onComplete = onComplete
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Question Header
            VStack(alignment: .leading, spacing: 12) {
                Text(question.title)
                    .font(.title2)
                    .bold()
                
                Text(question.content.question)
                    .font(.body)
                    .foregroundColor(.primary)
                    .lineLimit(nil) // Allow unlimited lines
                    .fixedSize(horizontal: false, vertical: true) // Allow vertical expansion
                
                // Question Image
                if let imageUrl = question.content.imageUrl, !imageUrl.isEmpty {
                    QuestionImageView(
                        imageUrl: imageUrl,
                        imageAlt: question.content.imageAlt,
                        maxHeight: 250
                    )
                }
            }
            
            // Difficulty and Category
            HStack {
                if let category = question.category {
                    Text(category)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.blue.opacity(0.2))
                        .foregroundColor(.blue)
                        .cornerRadius(8)
                }
                
                Text("Level \(question.difficultyLevel)")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.orange.opacity(0.2))
                    .foregroundColor(.orange)
                    .cornerRadius(8)
            }
            
            // Options
            VStack(spacing: 12) {
                ForEach(question.content.options ?? []) { option in
                    OptionButton(
                        option: option,
                        isSelected: selectedOptionId == option.id,
                        isCorrect: showResult && option.id == question.correctAnswer.correctOptionId,
                        isIncorrect: showResult && selectedOptionId == option.id && option.id != question.correctAnswer.correctOptionId,
                        onTap: {
                            if !showResult {
                                selectedOptionId = option.id
                            }
                        }
                    )
                }
            }
            
            // Submit Button
            if selectedOptionId != nil && !showResult {
                Button(action: submitAnswer) {
                    Text("Submit Answer")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(12)
                }
            }
            
            // Result
            if showResult {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundColor(isCorrect ? .green : .red)
                            .font(.title2)
                        
                        Text(isCorrect ? "Correct!" : "Incorrect")
                            .font(.headline)
                            .foregroundColor(isCorrect ? .green : .red)
                    }
                    
                    if let explanation = question.explanation {
                        //  Simple adaptive text
                        AdaptiveText(explanation, maxFontSize: 16, minFontSize: 12)
                            .foregroundColor(.secondary)
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                        
                        // Another option to try based on feedback: Expandable text (uncomment to use)
                        // ExpandableText(explanation, maxLines: 3)
                        //     .foregroundColor(.secondary)
                        //     .padding()
                        //     .background(Color.gray.opacity(0.1))
                        //     .cornerRadius(8)
                        
                        // Scrollable text for very long content (uncomment to use)
                        // ScrollableText(explanation, maxHeight: 150)
                        //     .foregroundColor(.secondary)
                        //     .padding()
                        //     .background(Color.gray.opacity(0.1))
                        //     .cornerRadius(8)
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.05))
                .cornerRadius(12)
            }
            
            Spacer()
        }
        .padding()
    }
    
    private func submitAnswer() {
        guard let selectedId = selectedOptionId else { return }
        
        let correctId = question.correctAnswer.correctOptionId
        isCorrect = selectedId == correctId
        showResult = true
        
        // Save progress to database
        let timeTaken = Int(Date().timeIntervalSince(timeStarted))
        Task {
            await QuestionService.shared.submitAnswer(
                questionId: question.id,
                selectedAnswer: selectedId,
                isCorrect: isCorrect,
                timeTaken: timeTaken
            )
            
            // Call completion callback after delay to allow reading result
            DispatchQueue.main.asyncAfter(deadline: .now() + 6.0) {
                onComplete?()
            }
        }
    }
}

// MARK: - Option Button
struct OptionButton: View {
    let option: QuestionOption
    let isSelected: Bool
    let isCorrect: Bool
    let isIncorrect: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                Text(option.id.uppercased())
                    .font(.headline)
                    .foregroundColor(textColor)
                    .frame(width: 30, height: 30)
                    .background(backgroundColor)
                    .clipShape(Circle())
                
                Text(option.text)
                    .font(.body)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.leading)
                    .lineLimit(nil) // Allow unlimited lines
                    .fixedSize(horizontal: false, vertical: true) // Allow vertical expansion
                
                Spacer()
                
                if isCorrect {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                } else if isIncorrect {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.red)
                }
            }
            .padding()
            .background(buttonBackgroundColor)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(borderColor, lineWidth: 2)
            )
        }
        .disabled(isCorrect || isIncorrect)
    }
    
    private var backgroundColor: Color {
        if isCorrect { return .green }
        if isIncorrect { return .red }
        if isSelected { return .blue }
        return .gray.opacity(0.3)
    }
    
    private var textColor: Color {
        if isCorrect || isIncorrect || isSelected { return .white }
        return .primary
    }
    
    private var buttonBackgroundColor: Color {
        if isCorrect { return .green.opacity(0.1) }
        if isIncorrect { return .red.opacity(0.1) }
        if isSelected { return .blue.opacity(0.1) }
        return .gray.opacity(0.05)
    }
    
    private var borderColor: Color {
        if isCorrect { return .green }
        if isIncorrect { return .red }
        if isSelected { return .blue }
        return .gray.opacity(0.3)
    }
}

#Preview {
    let sampleQuestion = Question(
        id: UUID(),
        title: "Load Balancing Strategy",
        questionType: "multiple_choice",
        content: QuestionContent(
            question: "Which load balancing algorithm distributes requests evenly across all servers without considering server capacity?",
            options: [
                QuestionOption(id: "a", text: "Round Robin"),
                QuestionOption(id: "b", text: "Weighted Round Robin"),
                QuestionOption(id: "c", text: "Least Connections"),
                QuestionOption(id: "d", text: "IP Hash")
            ],
            diagramRef: nil,
            imageUrl: nil,
            imageAlt: nil,
            matchingItems: nil,
            correctMatches: nil,
            orderingItems: nil,
            correctOrderIds: nil
        ),
        correctAnswer: QuestionAnswer(correctOptionId: "a", correctText: nil),
        explanation: "Round Robin distributes requests in a circular fashion, treating all servers equally regardless of their capacity or current load.",
        difficultyLevel: 2,
        category: "Load Balancing",
        scheduledDate: nil,
        createdAt: ""
    )
    
    return MultipleChoiceQuestionView(question: sampleQuestion)
}
