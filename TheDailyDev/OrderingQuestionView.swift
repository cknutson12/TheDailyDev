import SwiftUI

struct OrderingQuestionView: View {
    let question: Question
    let onComplete: (() -> Void)?
    
    @State private var items: [OrderingItem] = []
    @State private var showResult = false
    @State private var isCorrect = false
    @State private var timeStarted = Date()
    
    init(question: Question, challengeDate: Date? = nil, onComplete: (() -> Void)? = nil) {
        self.question = question
        self.onComplete = onComplete
        // challengeDate parameter kept for compatibility but not used
        _items = State(initialValue: question.content.orderingItems ?? [])
    }
    
    private var correctOrderIds: [String] {
        question.content.correctOrderIds ?? []
    }
    
    private var userOrderIds: [String] {
        items.map { $0.id }
    }
    
    private var correctPositionsCount: Int {
        guard !correctOrderIds.isEmpty else { return 0 }
        return zip(userOrderIds, correctOrderIds).reduce(0) { acc, pair in
            acc + (pair.0 == pair.1 ? 1 : 0)
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header
            VStack(alignment: .leading, spacing: 12) {
                Text(question.title)
                    .font(.title2)
                    .bold()
                    .foregroundColor(.white)
                
                Text(question.content.question)
                    .font(.body)
                    .foregroundColor(Color.theme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                
                if let imageUrl = question.content.imageUrl, !imageUrl.isEmpty {
                    QuestionImageView(
                        imageUrl: imageUrl,
                        imageAlt: question.content.imageAlt,
                        maxHeight: 250
                    )
                }
            }
            
            // Reorderable list
            List {
                ForEach(items, id: \.id) { item in
                    HStack {
                        Image(systemName: "line.3.horizontal")
                            .foregroundColor(Color.theme.textSecondary)
                        Text(item.text)
                            .font(.body)
                            .foregroundColor(.white)
                        Spacer()
                    }
                    .listRowBackground(Theme.Colors.surface)
                }
                .onMove(perform: move)
            }
            .environment(\.editMode, .constant(.active))
            .scrollContentBackground(.hidden)
            .background(Theme.Colors.surface)
            .cornerRadius(12)
            
            // Submit button
            if !showResult {
                Button(action: submitAnswer) {
                    Text("Submit Order").bold()
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
                        Text(isCorrect ? "Correct!" : "Partially Correct")
                            .font(.headline)
                            .foregroundColor(isCorrect ? Theme.Colors.stateCorrect : Theme.Colors.stateIncorrect)
                    }
                    
                    Text("\(correctPositionsCount)/\(correctOrderIds.count) in the correct position")
                        .font(.subheadline)
                        .foregroundColor(Color.theme.textSecondary)
                    
                    if let explanation = question.explanation {
                        Text(explanation)
                            .font(.body)
                            .foregroundColor(Color.theme.textSecondary)
                            .padding()
                            .background(Theme.Colors.surface)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Theme.Colors.border, lineWidth: 1)
                            )
                            .cornerRadius(8)
                    }
                    
                    // Resources Link
                    if let resourcesUrl = question.resourcesUrl, !resourcesUrl.isEmpty,
                       let url = URL(string: resourcesUrl) {
                        Link(destination: url) {
                            HStack {
                                Text("Check out more resources")
                                    .font(.body)
                                    .foregroundColor(Theme.Colors.accentGreen)
                                
                                Spacer()
                                
                                Image(systemName: "arrow.up.right.square")
                                    .foregroundColor(Theme.Colors.accentGreen)
                            }
                            .padding()
                            .background(Theme.Colors.surface)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Theme.Colors.accentGreen.opacity(0.3), lineWidth: 1)
                            )
                            .cornerRadius(8)
                        }
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
    
    private func move(from source: IndexSet, to destination: Int) {
        items.move(fromOffsets: source, toOffset: destination)
    }
    
    private func submitAnswer() {
        showResult = true
        isCorrect = userOrderIds == correctOrderIds
        
        let timeTaken = Int(Date().timeIntervalSince(timeStarted))
        Task {
            await QuestionService.shared.submitOrderingAnswer(
                questionId: question.id,
                orderIds: userOrderIds,
                isCorrect: isCorrect,
                timeTaken: timeTaken
            )
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 6.0) {
                onComplete?()
            }
        }
    }
}

#Preview {
    let q = Question(
        id: UUID(),
        title: "HTTP Request Lifecycle",
        content: QuestionContent(
            question: "Arrange the steps of an HTTP request from client to server response.",
            options: nil,
            diagramRef: nil,
            imageUrl: nil,
            imageAlt: nil,
            matchingItems: nil,
            correctMatches: nil,
            orderingItems: [
                OrderingItem(id: "1", text: "Client sends HTTP request"),
                OrderingItem(id: "2", text: "Load balancer routes request"),
                OrderingItem(id: "3", text: "App server handles request"),
                OrderingItem(id: "4", text: "App queries database"),
                OrderingItem(id: "5", text: "Server sends HTTP response")
            ],
            correctOrderIds: ["1","2","3","4","5"]
        ),
        correctAnswer: QuestionAnswer(correctOptionId: nil, correctText: nil),
        explanation: "Typical flow: client → load balancer → app → database → response.",
        difficultyLevel: 2,
        category: "Networking",
        createdAt: "",
        resourcesUrl: nil,
        questionType: nil,
        scheduledDate: nil
    )
    return OrderingQuestionView(question: q)
}
