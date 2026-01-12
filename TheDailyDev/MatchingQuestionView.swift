import SwiftUI

struct MatchingQuestionView: View {
    let question: Question
    let onComplete: (() -> Void)?
    
    @State private var matches: [String: String] = [:] // targetId: sourceId
    @State private var showResult = false
    @State private var isCorrect = false
    @State private var timeStarted = Date()
    
    init(question: Question, challengeDate: Date? = nil, onComplete: (() -> Void)? = nil) {
        self.question = question
        self.onComplete = onComplete
        // challengeDate parameter kept for compatibility but not used
    }
    
    var draggableItems: [MatchingItem] {
        question.content.matchingItems?.filter { $0.isDraggable } ?? []
    }
    
    var targetItems: [MatchingItem] {
        question.content.matchingItems?.filter { !$0.isDraggable } ?? []
    }
    
    var unmatchedDraggables: [MatchingItem] {
        draggableItems.filter { item in
            !matches.values.contains(item.id)
        }
    }
    
    var allItemsPlaced: Bool {
        matches.count == draggableItems.count
    }
    
    var totalPairs: Int {
        question.content.correctMatches?.count ?? 0
    }

    var correctPairsCount: Int {
        let correctMatches = question.content.correctMatches ?? []
        return correctMatches.reduce(0) { count, pair in
            count + ((matches[pair.targetId] == pair.sourceId) ? 1 : 0)
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Question Header
                VStack(alignment: .leading, spacing: 12) {
                    Text(question.title)
                        .font(.title2)
                        .bold()
                        .foregroundColor(.white)
                    
                    Text(question.content.question)
                        .font(.body)
                        .foregroundColor(Color.theme.textSecondary)
                        .lineLimit(nil)
                        .fixedSize(horizontal: false, vertical: true)
                    
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
                
                // Instructions
                if !showResult {
                    Text("Drag items to match them with their descriptions")
                        .font(.subheadline)
                        .foregroundColor(Color.theme.textSecondary)
                        .italic()
                }
                
                // Draggable Items Section
                if !unmatchedDraggables.isEmpty && !showResult {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Drag These:")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 16) {
                                ForEach(unmatchedDraggables) { item in
                                    DraggableItemCard(item: item, isMatched: false)
                                        .draggable(item.id)
                                }
                            }
                            .padding(.vertical, 4) // Add vertical padding for easier grabbing
                        }
                    }
                    .cardContainer()
                }
                
                // Drop Zones Section
                VStack(alignment: .leading, spacing: 16) {
                    Text("Match To:")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    ForEach(targetItems) { target in
                        DropZoneView(
                            target: target,
                            matchedItem: getMatchedItem(for: target.id),
                            onDrop: { sourceId in
                                handleDrop(sourceId: sourceId, targetId: target.id)
                                return true
                            },
                            onRemove: {
                                removeMatch(for: target.id)
                            }
                        )
                        .disabled(showResult)
                    }
                }
                
                // Submit Button
                if !showResult {
                    Button(action: submitAnswer) {
                        if allItemsPlaced {
                            Text("Submit Answer").bold()
                        } else {
                            Text("Place all items to submit (\(matches.count)/\(draggableItems.count) placed)")
                        }
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .disabled(!allItemsPlaced)
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
                        
                        // Show X/Y matches correct
                        Text("\(correctPairsCount)/\(totalPairs) matches correct")
                            .font(.subheadline)
                            .foregroundColor(Color.theme.textSecondary)
                            .padding(.bottom, 4)
                        
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
        }
        .background(Color.theme.background)
        .preferredColorScheme(.dark)
        .onAppear {
            AnalyticsService.shared.track("question_viewed", properties: [
                "question_id": question.id.uuidString,
                "question_type": "matching",
                "question_category": question.category ?? "unknown"
            ])
        }
    }
    
    // MARK: - Helper Functions
    
    private func getMatchedItem(for targetId: String) -> MatchingItem? {
        guard let sourceId = matches[targetId] else { return nil }
        return draggableItems.first { $0.id == sourceId }
    }
    
    private func handleDrop(sourceId: String, targetId: String) {
        // Remove this source from any previous target
        for (key, value) in matches where value == sourceId {
            matches.removeValue(forKey: key)
        }
        
        // Add new match
        matches[targetId] = sourceId
    }
    
    private func removeMatch(for targetId: String) {
        matches.removeValue(forKey: targetId)
    }
    
    private func submitAnswer() {
        guard allItemsPlaced else { return }
        
        // Check if matches are correct
        let correctMatches = question.content.correctMatches ?? []
        var allCorrect = true
        
        for correctPair in correctMatches {
            if matches[correctPair.targetId] != correctPair.sourceId {
                allCorrect = false
                break
            }
        }
        
        isCorrect = allCorrect && matches.count == correctMatches.count
        showResult = true
        
        // Save progress to database
        let timeTaken = Int(Date().timeIntervalSince(timeStarted))
        Task {
            await QuestionService.shared.submitMatchingAnswer(
                questionId: question.id,
                matches: matches,
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

#Preview {
    let sampleQuestion = Question(
        id: UUID(),
        title: "Caching Strategies",
        content: QuestionContent(
            question: "Match each caching strategy to its best use case",
            options: nil,
            diagramRef: nil,
            imageUrl: nil,
            imageAlt: nil,
            matchingItems: [
                MatchingItem(id: "cache1", text: "Write-through cache", isDraggable: true),
                MatchingItem(id: "cache2", text: "Write-behind cache", isDraggable: true),
                MatchingItem(id: "cache3", text: "Read-through cache", isDraggable: true),
                MatchingItem(id: "use1", text: "High write frequency, eventual consistency OK", isDraggable: false),
                MatchingItem(id: "use2", text: "High read frequency, critical data consistency", isDraggable: false),
                MatchingItem(id: "use3", text: "Lazy loading pattern for cache misses", isDraggable: false)
            ],
            correctMatches: [
                MatchPair(sourceId: "cache1", targetId: "use2"),
                MatchPair(sourceId: "cache2", targetId: "use1"),
                MatchPair(sourceId: "cache3", targetId: "use3")
            ],
            orderingItems: nil,
            correctOrderIds: nil
        ),
        correctAnswer: QuestionAnswer(correctOptionId: nil, correctText: nil),
        explanation: "Write-through cache ensures data consistency by writing to both cache and database simultaneously. Write-behind cache improves write performance by asynchronously writing to the database. Read-through cache implements lazy loading, fetching data on cache misses.",
        difficultyLevel: 3,
        category: "Caching",
        createdAt: "",
        resourcesUrl: nil,
        questionType: nil,
        scheduledDate: nil
    )
    
    return MatchingQuestionView(question: sampleQuestion)
}

