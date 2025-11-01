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
                    .foregroundColor(.white)
                
                Text(question.content.question)
                    .font(.body)
                    .foregroundColor(Color.theme.textSecondary)
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
                        .background(Theme.Colors.surface)
                        .foregroundColor(.white)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Theme.Colors.border, lineWidth: 1)
                        )
                        .cornerRadius(8)
                }
                
                Text("Level \(question.difficultyLevel)")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Theme.Colors.surface)
                    .foregroundColor(.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Theme.Colors.border, lineWidth: 1)
                    )
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
                    Text("Submit Answer").bold()
                }
                .buttonStyle(PrimaryButtonStyle())
            }
            
            // Result
            if showResult {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundColor(isCorrect ? Theme.Colors.stateCorrect : Theme.Colors.stateIncorrect)
                            .font(.title2)
                        
                        Text(isCorrect ? "Correct!" : "Incorrect")
                            .font(.headline)
                            .foregroundColor(isCorrect ? Theme.Colors.stateCorrect : Theme.Colors.stateIncorrect)
                    }
                    
                    if let explanation = question.explanation {
                        AdaptiveText(explanation, maxFontSize: 16, minFontSize: 12)
                            .foregroundColor(Color.theme.textSecondary)
                            .padding()
                            .background(Theme.Colors.surface)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Theme.Colors.border, lineWidth: 1)
                            )
                            .cornerRadius(8)
                    }
                }
                .padding()
                .background(Theme.Colors.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Theme.Colors.border, lineWidth: 1)
                )
                .cornerRadius(12)
            }
            
            Spacer()
        }
        .padding()
        .background(Color.theme.background)
        .preferredColorScheme(.dark)
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
                    .foregroundColor(.white)
                    .multilineTextAlignment(.leading)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
                
                Spacer()
                
                if isCorrect {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(Theme.Colors.stateCorrect)
                } else if isIncorrect {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(Theme.Colors.stateIncorrect)
                }
            }
            .padding()
            .background(Theme.Colors.surface)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(borderColor, lineWidth: 2)
            )
            .cornerRadius(12)
        }
        .disabled(isCorrect || isIncorrect)
    }
    
    private var backgroundColor: Color {
        if isCorrect { return Theme.Colors.stateCorrect }
        if isIncorrect { return Theme.Colors.stateIncorrect }
        if isSelected { return Theme.Colors.accentGreen }
        return Theme.Colors.surface
    }
    
    private var textColor: Color {
        if isCorrect || isIncorrect || isSelected { return .black }
        return .white
    }
    
    private var borderColor: Color {
        if isSelected { return Theme.Colors.accentGreen }
        if isCorrect { return Theme.Colors.stateCorrect }
        if isIncorrect { return Theme.Colors.stateIncorrect }
        return Theme.Colors.border
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
