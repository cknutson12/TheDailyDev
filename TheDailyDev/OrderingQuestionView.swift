import SwiftUI

struct OrderingQuestionView: View {
    let question: Question
    let onComplete: (() -> Void)?
    
    @State private var items: [OrderingItem] = []
    @State private var showResult = false
    @State private var isCorrect = false
    @State private var timeStarted = Date()
    
    init(question: Question, onComplete: (() -> Void)? = nil) {
        self.question = question
        self.onComplete = onComplete
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
                
                Text(question.content.question)
                    .font(.body)
                    .foregroundColor(.primary)
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
                            .foregroundColor(.secondary)
                        Text(item.text)
                            .font(.body)
                        Spacer()
                    }
                }
                .onMove(perform: move)
            }
            .environment(\.editMode, .constant(.active))
            .frame(maxHeight: 350)
            
            // Submit button
            if !showResult {
                Button(action: submitAnswer) {
                    Text("Submit Order")
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
                        Text(isCorrect ? "Correct!" : "Partially Correct")
                            .font(.headline)
                            .foregroundColor(isCorrect ? .green : .red)
                    }
                    
                    Text("\(correctPositionsCount)/\(correctOrderIds.count) in the correct position")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    if let explanation = question.explanation {
                        Text(explanation)
                            .font(.body)
                            .foregroundColor(.secondary)
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
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
        questionType: "ordering",
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
        scheduledDate: nil,
        createdAt: ""
    )
    return OrderingQuestionView(question: q)
}
