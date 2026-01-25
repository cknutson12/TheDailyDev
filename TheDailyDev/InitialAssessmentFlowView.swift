import SwiftUI
import Supabase

// MARK: - Initial Assessment Configuration

struct InitialAssessmentSkill: Identifiable, Codable {
    let id = UUID()
    let key: String
    let title: String
    let description: String
}

enum AssessmentSource: String, Codable {
    case initial
    case monthly
}

enum InitialAssessmentConfig {
    static let skills: [InitialAssessmentSkill] = [
        InitialAssessmentSkill(
            key: "infrastructure",
            title: "Infrastructure",
            description: "Distributed Systems, Failure handling, Networking"
        ),
        InitialAssessmentSkill(
            key: "data",
            title: "Data",
            description: "Modeling, Query Patterns, Database Design"
        ),
        InitialAssessmentSkill(
            key: "api_design",
            title: "API Design",
            description: "Contracts, Versioning, Developer Experience"
        ),
        InitialAssessmentSkill(
            key: "theory",
            title: "Theory",
            description: "CAP, PACELC, Trade-offs"
        ),
        InitialAssessmentSkill(
            key: "product",
            title: "Product",
            description: "Scale, Feature Prioritization, Architecture"
        )
    ]

    static let placeholderQuestions: [Question] = [
        Question(
            id: UUID(uuidString: "11111111-1111-1111-1111-111111111111") ?? UUID(),
            title: "PACELC Trade-offs",
            content: QuestionContent(
                question: "You're designing a multi-region deployment strategy for a financial application that requires strong consistency and must handle network partitions gracefully. Which statement correctly describes the trade-offs you must make?",
                options: [
                    QuestionOption(id: "a", text: "In the absence of partitions, you only need to optimize for latency since consistency is guaranteed"),
                    QuestionOption(id: "b", text: "During partitions choose between availability and consistency; else choose between latency and consistency"),
                    QuestionOption(id: "c", text: "PACELC only applies during network partitions and doesn't address normal operation trade-offs"),
                    QuestionOption(id: "d", text: "You must always sacrifice availability to maintain consistency regardless of partition state")
                ],
                diagramRef: nil,
                imageUrl: nil,
                imageAlt: nil,
                matchingItems: nil,
                correctMatches: nil,
                orderingItems: nil,
                correctOrderIds: nil
            ),
            correctAnswer: QuestionAnswer(correctOptionId: "b", correctText: nil),
            explanation: "PACELC extends CAP: during partitions you trade off Availability vs Consistency; else you trade off Latency vs Consistency.",
            difficultyLevel: 3,
            category: "Theory",
            createdAt: DateUtils.iso8601WithFractional.string(from: Date()),
            resourcesUrl: nil,
            questionType: nil,
            scheduledDate: nil
        ),
        Question(
            id: UUID(uuidString: "22222222-2222-2222-2222-222222222222") ?? UUID(),
            title: "Caching Layers",
            content: QuestionContent(
                question: "Order these caching layers from the point where a request enters your infrastructure to where it terminates at your application server.",
                options: nil,
                diagramRef: nil,
                imageUrl: nil,
                imageAlt: nil,
                matchingItems: nil,
                correctMatches: nil,
                orderingItems: [
                    OrderingItem(id: "B", text: "Browser cache (client-side)"),
                    OrderingItem(id: "D", text: "CDN edge cache (geographically distributed)"),
                    OrderingItem(id: "E", text: "API Gateway cache layer"),
                    OrderingItem(id: "A", text: "Application-level in-memory cache (local to each service instance)")
                ],
                correctOrderIds: ["B", "D", "E", "A"]
            ),
            correctAnswer: QuestionAnswer(correctOptionId: "a", correctText: nil),
            explanation: "Requests flow from the browser cache → CDN edge → API gateway → application cache.",
            difficultyLevel: 2,
            category: "Infrastructure",
            createdAt: DateUtils.iso8601WithFractional.string(from: Date()),
            resourcesUrl: nil,
            questionType: nil,
            scheduledDate: nil
        ),
        Question(
            id: UUID(uuidString: "33333333-3333-3333-3333-333333333333") ?? UUID(),
            title: "Replication Strategies",
            content: QuestionContent(
                question: "Order these database replication strategies from strongest durability guarantees to weakest.",
                options: nil,
                diagramRef: nil,
                imageUrl: nil,
                imageAlt: nil,
                matchingItems: nil,
                correctMatches: nil,
                orderingItems: [
                    OrderingItem(id: "A", text: "Synchronous multi-region replication with quorum writes"),
                    OrderingItem(id: "C", text: "Synchronous single-region replication to one standby"),
                    OrderingItem(id: "B", text: "Asynchronous replication with WAL to disk before acknowledgment"),
                    OrderingItem(id: "D", text: "Asynchronous multi-region replication with eventual consistency"),
                    OrderingItem(id: "E", text: "In-memory writes with periodic snapshots to disk")
                ],
                correctOrderIds: ["A", "C", "B", "D", "E"]
            ),
            correctAnswer: QuestionAnswer(correctOptionId: "a", correctText: nil),
            explanation: "Quorum synchronous replication is strongest; in-memory snapshots are weakest.",
            difficultyLevel: 3,
            category: "Data",
            createdAt: DateUtils.iso8601WithFractional.string(from: Date()),
            resourcesUrl: nil,
            questionType: nil,
            scheduledDate: nil
        ),
        Question(
            id: UUID(uuidString: "44444444-4444-4444-4444-444444444444") ?? UUID(),
            title: "API Styles",
            content: QuestionContent(
                question: "Match each API architectural style to the use case where it provides the greatest advantage.",
                options: nil,
                diagramRef: nil,
                imageUrl: nil,
                imageAlt: nil,
                matchingItems: [
                    MatchingItem(id: "rest", text: "REST with resource-oriented design", isDraggable: true),
                    MatchingItem(id: "graphql", text: "GraphQL with schema stitching", isDraggable: true),
                    MatchingItem(id: "grpc", text: "gRPC with protocol buffers", isDraggable: true),
                    MatchingItem(id: "websocket", text: "WebSocket with message framing", isDraggable: true),
                    MatchingItem(id: "sse", text: "Server-Sent Events (SSE)", isDraggable: true),
                    MatchingItem(id: "crud", text: "Simple CRUD operations on well-defined business entities with standard HTTP tooling", isDraggable: false),
                    MatchingItem(id: "aggregate", text: "Aggregating data from multiple backend services into a unified API", isDraggable: false),
                    MatchingItem(id: "microservices", text: "High-performance microservice communication with type-safe contracts", isDraggable: false),
                    MatchingItem(id: "realtime", text: "Real-time bidirectional communication for chat or collaborative editing", isDraggable: false),
                    MatchingItem(id: "stream", text: "Server-to-client streaming for live updates like notifications or stock tickers", isDraggable: false)
                ],
                correctMatches: [
                    MatchPair(sourceId: "rest", targetId: "crud"),
                    MatchPair(sourceId: "graphql", targetId: "aggregate"),
                    MatchPair(sourceId: "grpc", targetId: "microservices"),
                    MatchPair(sourceId: "websocket", targetId: "realtime"),
                    MatchPair(sourceId: "sse", targetId: "stream")
                ],
                orderingItems: nil,
                correctOrderIds: nil
            ),
            correctAnswer: QuestionAnswer(correctOptionId: "a", correctText: nil),
            explanation: "Each API style shines in a specific scenario: REST for CRUD, GraphQL for aggregation, gRPC for internal services, WebSocket for real-time, SSE for streaming.",
            difficultyLevel: 3,
            category: "API Design",
            createdAt: DateUtils.iso8601WithFractional.string(from: Date()),
            resourcesUrl: nil,
            questionType: nil,
            scheduledDate: nil
        ),
        Question(
            id: UUID(uuidString: "55555555-5555-5555-5555-555555555555") ?? UUID(),
            title: "Core Product Challenges",
            content: QuestionContent(
                question: "Match each product design question to the core technical challenge.",
                options: nil,
                diagramRef: nil,
                imageUrl: nil,
                imageAlt: nil,
                matchingItems: [
                    MatchingItem(id: "whatsapp", text: "Design WhatsApp", isDraggable: true),
                    MatchingItem(id: "tinyurl", text: "Design TinyURL", isDraggable: true),
                    MatchingItem(id: "reddit", text: "Design Reddit", isDraggable: true),
                    MatchingItem(id: "zoom", text: "Design Zoom", isDraggable: true),
                    MatchingItem(id: "yelp", text: "Design Yelp", isDraggable: true),
                    MatchingItem(id: "messaging", text: "Real-time message delivery at scale with ordering guarantees", isDraggable: false),
                    MatchingItem(id: "shortlinks", text: "Hash collision handling and distributed ID generation for short URLs", isDraggable: false),
                    MatchingItem(id: "ranking", text: "Ranking algorithm for hot posts combining votes and time", isDraggable: false),
                    MatchingItem(id: "streaming", text: "Video/audio streaming architecture and handling network variability", isDraggable: false),
                    MatchingItem(id: "geo", text: "Geospatial search, indexing, and radius queries", isDraggable: false)
                ],
                correctMatches: [
                    MatchPair(sourceId: "whatsapp", targetId: "messaging"),
                    MatchPair(sourceId: "tinyurl", targetId: "shortlinks"),
                    MatchPair(sourceId: "reddit", targetId: "ranking"),
                    MatchPair(sourceId: "zoom", targetId: "streaming"),
                    MatchPair(sourceId: "yelp", targetId: "geo")
                ],
                orderingItems: nil,
                correctOrderIds: nil
            ),
            correctAnswer: QuestionAnswer(correctOptionId: "a", correctText: nil),
            explanation: "Each product has a defining technical challenge that drives its architecture.",
            difficultyLevel: 3,
            category: "Product",
            createdAt: DateUtils.iso8601WithFractional.string(from: Date()),
            resourcesUrl: nil,
            questionType: nil,
            scheduledDate: nil
        )
    ]
}

// MARK: - Assessment Storage Models

struct AssessmentAnswerPayload: Codable {
    let selectedOptionId: String?
    let matches: [String: String]?
    let orderIds: [String]?
}

struct AssessmentAnswer: Codable, Identifiable {
    let id: UUID
    let questionId: UUID
    let questionType: String
    let payload: AssessmentAnswerPayload
    let isCorrect: Bool
    let timeTaken: Int
    let completedAt: String
}

struct SkillRating: Codable, Identifiable {
    let id: UUID
    let skillKey: String
    let rating: Int
}

struct PendingAssessment: Codable {
    var id: UUID
    var questionIds: [UUID]
    var answers: [AssessmentAnswer]
    var ratings: [SkillRating]
    var completedAt: String?
    var syncedAt: String?
    var source: AssessmentSource
    var userId: String?
}

// MARK: - Local Store (Pre-Auth)

@MainActor
final class InitialAssessmentStore: ObservableObject {
    static let shared = InitialAssessmentStore()
    
    @Published private(set) var assessment: PendingAssessment?
    
    private let storageKey = "pending_initial_assessment_v1"
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    
    private init() {
        assessment = loadAssessment()
    }
    
    var hasCompletedInitialAssessment: Bool {
        assessment?.completedAt != nil
    }
    
    var needsSync: Bool {
        guard let assessment = assessment else { return false }
        return assessment.completedAt != nil && assessment.syncedAt == nil
    }
    
    func beginAssessment(questionIds: [UUID]) {
        guard assessment?.completedAt == nil else { return }
        if assessment == nil {
            assessment = PendingAssessment(
                id: UUID(),
                questionIds: questionIds,
                answers: [],
                ratings: [],
                completedAt: nil,
                syncedAt: nil,
                source: .initial,
                userId: nil
            )
            persist()
        }
    }
    
    func recordAnswer(_ answer: AssessmentAnswer) {
        guard var assessment = assessment else { return }
        if let index = assessment.answers.firstIndex(where: { $0.questionId == answer.questionId }) {
            assessment.answers[index] = answer
        } else {
            assessment.answers.append(answer)
        }
        self.assessment = assessment
        persist()
    }
    
    func recordRatings(_ ratings: [SkillRating]) {
        guard var assessment = assessment else { return }
        assessment.ratings = ratings
        assessment.completedAt = DateUtils.iso8601WithFractional.string(from: Date())
        self.assessment = assessment
        persist()
    }
    
    func markSynced(userId: String) {
        guard var assessment = assessment else { return }
        assessment.syncedAt = DateUtils.iso8601WithFractional.string(from: Date())
        assessment.userId = userId
        self.assessment = assessment
        persist()
    }
    
    func syncIfNeeded() async {
        guard needsSync, let assessment = assessment else { return }
        
        do {
            let session = try await SupabaseManager.shared.client.auth.session
            let userId = session.user.id
            
            let assessmentRecord = SelfAssessmentInsertRecord(
                id: assessment.id,
                userId: userId,
                assessmentDate: assessment.completedAt ?? DateUtils.iso8601WithFractional.string(from: Date()),
                ratings: Dictionary(uniqueKeysWithValues: assessment.ratings.map { ($0.skillKey, $0.rating) }),
                source: assessment.source.rawValue
            )
            
            let answerRecords = assessment.answers.map { answer in
                AssessmentAnswerInsertRecord(
                    id: answer.id,
                    assessmentId: assessment.id,
                    userId: userId,
                    questionId: answer.questionId,
                    questionType: answer.questionType,
                    answer: answer.payload,
                    isCorrect: answer.isCorrect,
                    timeTaken: answer.timeTaken,
                    completedAt: answer.completedAt
                )
            }
            
            _ = try await SupabaseManager.shared.client
                .from("user_self_assessments")
                .insert(assessmentRecord)
                .execute()
            
            if !answerRecords.isEmpty {
                _ = try await SupabaseManager.shared.client
                    .from("user_assessment_answers")
                    .insert(answerRecords)
                    .execute()
            }
            
            markSynced(userId: userId.uuidString)
            AnalyticsService.shared.track("initial_assessment_synced")
        } catch {
            DebugLogger.error("Failed to sync initial assessment: \(error)")
        }
    }
    
    private func loadAssessment() -> PendingAssessment? {
        guard let data = try? Data(contentsOf: storageURL()) else { return nil }
        return try? decoder.decode(PendingAssessment.self, from: data)
    }
    
    private func persist() {
        guard let assessment = assessment else { return }
        if let data = try? encoder.encode(assessment) {
            try? data.write(to: storageURL(), options: [.atomic])
        }
    }
    
    private func storageURL() -> URL {
        let fileName = "\(storageKey).json"
        let directory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return directory.appendingPathComponent(fileName)
    }
}

// MARK: - Initial Assessment Flow

enum InitialAssessmentFinishAction {
    case showSignUp
    case dismiss
}

struct InitialAssessmentFlowView: View {
    let isAuthenticated: Bool
    let onFinish: (_ action: InitialAssessmentFinishAction) -> Void
    
    @StateObject private var store = InitialAssessmentStore.shared
    @State private var questions: [Question] = []
    @State private var currentIndex = 0
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var showingIntro = true
    @State private var showingRatings = false
    @State private var showingAccountPrompt = false
    
    var body: some View {
        ZStack {
            Color.theme.background.ignoresSafeArea()
            
            if isLoading {
                ProgressView("Loading your starter questions...")
                    .foregroundColor(.white)
            } else if let errorMessage = errorMessage {
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.largeTitle)
                        .foregroundColor(.orange)
                    Text("Couldn't load questions")
                        .font(.title2)
                        .bold()
                        .foregroundColor(.white)
                    Text(errorMessage)
                        .multilineTextAlignment(.center)
                        .foregroundColor(Color.theme.textSecondary)
                    Button("Try Again") {
                        Task {
                            await loadQuestions()
                        }
                    }
                    .buttonStyle(PrimaryButtonStyle())
                }
                .padding()
            } else if showingIntro {
                AssessmentIntroView(
                    onStart: {
                        showingIntro = false
                    }
                )
            } else if showingAccountPrompt {
                AssessmentAccountPromptView(
                    ratings: store.assessment?.ratings ?? [],
                    onCreateAccount: { onFinish(.showSignUp) }
                )
            } else if showingRatings {
                SelfAssessmentRatingView(
                    title: "Rate Your Skills",
                    subtitle: "Help us personalize your learning plan",
                    skills: InitialAssessmentConfig.skills,
                    primaryButtonTitle: "Continue",
                    onSubmit: { ratings in
                        store.recordRatings(ratings)
                        AnalyticsService.shared.track("initial_assessment_completed")
                        if isAuthenticated {
                            await store.syncIfNeeded()
                            onFinish(.dismiss)
                        } else {
                            showingRatings = false
                            showingAccountPrompt = true
                        }
                    }
                )
            } else if !questions.isEmpty {
                AssessmentQuestionStepView(
                    question: questions[currentIndex],
                    index: currentIndex,
                    total: questions.count,
                    onAnswered: recordAnswer,
                    onAdvance: advanceAfterQuestion
                )
            }
        }
        .task {
            await loadQuestions()
        }
        .onAppear {
            AnalyticsService.shared.track("initial_assessment_started")
        }
    }
    
    private func loadQuestions() async {
        isLoading = true
        errorMessage = nil
        let loaded = InitialAssessmentConfig.placeholderQuestions
        await MainActor.run {
            if loaded.isEmpty {
                errorMessage = "No starter questions are available right now."
            } else {
                questions = loaded
                currentIndex = 0
                store.beginAssessment(questionIds: loaded.map { $0.id })
                showingIntro = !store.hasCompletedInitialAssessment
                showingAccountPrompt = store.hasCompletedInitialAssessment && !isAuthenticated
            }
            isLoading = false
        }
    }
    
    private func advanceAfterQuestion() {
        if currentIndex + 1 >= questions.count {
            showingRatings = true
        } else {
            currentIndex += 1
        }
    }
    
    private func recordAnswer(payload: AssessmentAnswerPayload, question: Question, isCorrect: Bool, timeTaken: Int) {
        let answer = AssessmentAnswer(
            id: UUID(),
            questionId: question.id,
            questionType: questionType(for: question),
            payload: payload,
            isCorrect: isCorrect,
            timeTaken: timeTaken,
            completedAt: DateUtils.iso8601WithFractional.string(from: Date())
        )
        store.recordAnswer(answer)
        AnalyticsService.shared.track("initial_assessment_question_answered", properties: [
            "question_id": question.id.uuidString,
            "question_type": answer.questionType,
            "is_correct": isCorrect
        ])
    }
    
    private func questionType(for question: Question) -> String {
        if question.content.orderingItems != nil {
            return "ordering"
        }
        if question.content.matchingItems != nil {
            return "matching"
        }
        return "multiple_choice"
    }
}

// MARK: - Assessment Step

struct AssessmentQuestionStepView: View {
    let question: Question
    let index: Int
    let total: Int
    let onAnswered: (_ payload: AssessmentAnswerPayload, _ question: Question, _ isCorrect: Bool, _ timeTaken: Int) -> Void
    let onAdvance: () -> Void
    
    @State private var canAdvance = false
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Question \(index + 1) of \(total)")
                    .font(.subheadline)
                    .foregroundColor(Color.theme.textSecondary)
                Spacer()
            }
            .padding(.horizontal)
            
            Group {
                if question.content.orderingItems != nil {
                    OrderingQuestionView(
                        question: question,
                        onComplete: { canAdvance = true },
                        submitHandler: { question, orderIds, isCorrect, timeTaken in
                            let payload = AssessmentAnswerPayload(
                                selectedOptionId: nil,
                                matches: nil,
                                orderIds: orderIds
                            )
                            onAnswered(payload, question, isCorrect, timeTaken)
                            canAdvance = true
                        }
                    )
                    .id(question.id)
                } else if question.content.matchingItems != nil {
                    MatchingQuestionView(
                        question: question,
                        onComplete: { canAdvance = true },
                        submitHandler: { question, matches, isCorrect, timeTaken in
                            let payload = AssessmentAnswerPayload(
                                selectedOptionId: nil,
                                matches: matches,
                                orderIds: nil
                            )
                            onAnswered(payload, question, isCorrect, timeTaken)
                            canAdvance = true
                        }
                    )
                    .id(question.id)
                } else {
                    ScrollView {
                        MultipleChoiceQuestionView(
                            question: question,
                            onComplete: { canAdvance = true },
                            submitHandler: { question, selectedId, isCorrect, timeTaken in
                                let payload = AssessmentAnswerPayload(
                                    selectedOptionId: selectedId,
                                    matches: nil,
                                    orderIds: nil
                                )
                                onAnswered(payload, question, isCorrect, timeTaken)
                                canAdvance = true
                            }
                        )
                        .id(question.id)
                    }
                }
            }
            
            if canAdvance {
                Button(action: {
                    canAdvance = false
                    onAdvance()
                }) {
                    Text(index + 1 == total ? "Continue" : "Next")
                        .bold()
                }
                .buttonStyle(PrimaryButtonStyle())
                .padding(.horizontal)
                .padding(.bottom, 8)
            }
        }
        .background(Color.theme.background)
        .preferredColorScheme(.dark)
        .onChange(of: question.id) { _, _ in
            canAdvance = false
        }
    }
}

// MARK: - Intro

struct AssessmentIntroView: View {
    let onStart: () -> Void
    
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color.black,
                    Color(red: 0.08, green: 0.20, blue: 0.14)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 16) {
                Spacer(minLength: 24)
                Text("Welcome to The Daily Dev!")
                    .font(.system(size: 30, weight: .heavy))
                    .bold()
                    .foregroundColor(Theme.Colors.accentGreen)
                    .multilineTextAlignment(.center)
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("""
                    I built this app with my fiancée to solve the most difficult problem I faced when learning system design: showing up consistently.

                    Take just 5 minutes every morning to answer a single system design question, stay sharp for interviews, and explore edge cases you’ve never considered.
                    
                    Let’s get started by answering a few questions.
                    """)
                        .font(.body)
                        .foregroundColor(Color.theme.textSecondary)
                        .multilineTextAlignment(.leading)
                    
                    Text("— Arjay")
                        .font(.system(size: 18, weight: .regular, design: .serif))
                        .italic()
                        .foregroundColor(Color.theme.textSecondary)
                }
                .padding()
                .cardContainer()
                .padding(.horizontal)
                
                Button(action: onStart) {
                    Text("Get Started")
                        .bold()
                }
                .buttonStyle(PrimaryButtonStyle())
                .padding(.horizontal)
                
                Spacer(minLength: 24)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            .padding(.bottom)
        }
    }
}

// MARK: - Self Assessment Rating

struct SelfAssessmentRatingView: View {
    let title: String
    let subtitle: String
    let skills: [InitialAssessmentSkill]
    let primaryButtonTitle: String
    let onSubmit: ([SkillRating]) async -> Void
    
    @State private var ratings: [String: Int] = [:]
    @State private var isSubmitting = false
    
    var body: some View {
        ZStack {
            Color.theme.background.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 20) {
                    VStack(spacing: 8) {
                        Text(title)
                            .font(.title)
                            .bold()
                            .foregroundColor(Theme.Colors.accentGreen)
                        Text(subtitle)
                            .font(.subheadline)
                            .foregroundColor(Color.theme.textSecondary)
                            .multilineTextAlignment(.center)
                        Text("1 = Just starting, 5 = Expert")
                            .font(.caption)
                            .foregroundColor(Color.theme.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal)
                    
                    ForEach(skills) { skill in
                        VStack(alignment: .center, spacing: 12) {
                            Text(skill.title)
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            Text(skill.description)
                                .font(.caption)
                                .foregroundColor(Color.theme.textSecondary)
                                .multilineTextAlignment(.center)
                            
                            RatingSelector(
                                selectedRating: ratings[skill.key],
                                onSelect: { rating in
                                    ratings[skill.key] = rating
                                }
                            )
                        }
                        .padding()
                        .frame(maxWidth: .infinity, minHeight: 120, alignment: .center)
                        .cardContainer()
                        .padding(.horizontal)
                    }
                    
                    Button(action: submit) {
                        if isSubmitting {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                                .tint(.black)
                        } else {
                            Text(primaryButtonTitle)
                                .bold()
                        }
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .disabled(!allRated || isSubmitting)
                    .padding(.horizontal)
                    
                    Text("We'll check in monthly so you can track your growth over time.")
                        .font(.caption)
                        .foregroundColor(Color.theme.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                        .padding(.bottom, 20)
                }
                .padding(.top, 20)
            }
        }
        .preferredColorScheme(.dark)
    }
    
    private var allRated: Bool {
        skills.allSatisfy { ratings[$0.key] != nil }
    }
    
    private func submit() {
        let ratingItems = ratings.map { key, value in
            SkillRating(id: UUID(), skillKey: key, rating: value)
        }
        isSubmitting = true
        Task {
            await onSubmit(ratingItems)
            await MainActor.run {
                isSubmitting = false
            }
        }
    }
}

struct RatingSelector: View {
    let selectedRating: Int?
    let onSelect: (Int) -> Void
    
    var body: some View {
        VStack(spacing: 6) {
            HStack(spacing: 8) {
                ForEach(1...5, id: \.self) { rating in
                    let isSelected = selectedRating == rating
                    Button(action: { onSelect(rating) }) {
                        Text("\(rating)")
                            .font(.subheadline)
                            .foregroundColor(isSelected ? .black : Theme.Colors.accentGreen)
                            .frame(width: 28, height: 28)
                            .background(isSelected ? Theme.Colors.accentGreen : Theme.Colors.surface.opacity(0.9))
                            .cornerRadius(7)
                            .overlay(
                                RoundedRectangle(cornerRadius: 7)
                                    .stroke(Theme.Colors.accentGreen.opacity(isSelected ? 0.4 : 0.8), lineWidth: 1)
                            )
                    }
                }
            }
            
        }
    }
}

// MARK: - Account Prompt

struct AssessmentAccountPromptView: View {
    let ratings: [SkillRating]
    let onCreateAccount: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Great start!")
                .font(.title)
                .bold()
                .foregroundColor(.white)
            
            Text("Create an account to save your results and continue your learning journey.")
                .font(.body)
                .foregroundColor(Color.theme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            AssessmentProgressPreview(ratings: ratings)
                .padding(.vertical, 8)
            
            Text("If you want to level up, sign up now.")
                .font(.caption)
                .foregroundColor(Color.theme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button(action: onCreateAccount) {
                Text("Create Account")
                    .bold()
            }
            .buttonStyle(PrimaryButtonStyle())
            .padding(.horizontal)
        }
        .padding()
    }
}

// MARK: - Placeholder Motion Graphic

struct AssessmentProgressPreview: View {
    let ratings: [SkillRating]
    @State private var animationPhase: CGFloat = 0
    
    var body: some View {
        VStack(spacing: 8) {
            GeometryReader { geo in
                let width = geo.size.width
                let height = geo.size.height
                let leftPadding: CGFloat = 32
                let rightPadding: CGFloat = 12
                let topPadding: CGFloat = 18
                let bottomPadding: CGFloat = 20
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Theme.Colors.border, lineWidth: 1)
                        .background(Theme.Colors.surface.cornerRadius(8))
                    
                    Path { path in
                        path.move(to: CGPoint(x: leftPadding, y: topPadding))
                        path.addLine(to: CGPoint(x: leftPadding, y: height - bottomPadding))
                        path.addLine(to: CGPoint(x: width - rightPadding, y: height - bottomPadding))
                    }
                    .stroke(Color.theme.textSecondary.opacity(0.6), lineWidth: 1)
                    
                    VStack {
                        HStack {
                            Text("Confidence")
                                .font(.caption2)
                                .foregroundColor(Color.theme.textSecondary)
                            Spacer()
                        }
                        Spacer()
                    }
                    .padding(6)
                    
                    ForEach(0..<5, id: \.self) { index in
                        let rating = ratingForIndex(index)
                        let normalized = (rating - 1) / 4
                        let axisY = height - bottomPadding
                        let usableHeight = max(1, axisY - topPadding)
                        let offset = jitter(for: index, rating: rating)
                        let startNormalized = min(1, max(0, normalized + (offset * 0.16)))
                        let endNormalized = min(1, max(0, normalized + 0.25 + (offset * 0.2)))
                        let startY = axisY - (startNormalized * usableHeight)
                        let endY = axisY - (endNormalized * usableHeight)
                        Path { path in
                            path.move(to: CGPoint(x: leftPadding, y: startY))
                            let midX = width * 0.5
                            let endX = width - rightPadding
                            path.addQuadCurve(
                                to: CGPoint(x: midX, y: (startY + endY) / 2),
                                control: CGPoint(x: width * 0.25, y: startY - (14 + (offset * 34)))
                            )
                            path.addQuadCurve(
                                to: CGPoint(x: endX, y: endY),
                                control: CGPoint(x: width * 0.75, y: endY + (14 + (offset * 34)))
                            )
                        }
                        .trim(from: 0, to: min(1, animationPhase))
                        .stroke(colorForLine(index: index), lineWidth: 2)
                        
                        if animationPhase > 0.05 {
                            Circle()
                                .fill(colorForLine(index: index))
                                .frame(width: 6, height: 6)
                                .position(x: leftPadding, y: startY)
                        }
                    }
                    
                    let axisY = height - bottomPadding
                    let tick3Months = leftPadding + (width - leftPadding - rightPadding) * 0.5
                    let tick6Months = width - rightPadding
                    
                    Path { path in
                        path.move(to: CGPoint(x: tick3Months, y: axisY))
                        path.addLine(to: CGPoint(x: tick3Months, y: axisY - 6))
                        path.move(to: CGPoint(x: tick6Months, y: axisY))
                        path.addLine(to: CGPoint(x: tick6Months, y: axisY - 6))
                    }
                    .stroke(Color.theme.textSecondary.opacity(0.6), lineWidth: 1)
                    
                    Text("Today")
                        .font(.caption2)
                        .foregroundColor(Color.theme.textSecondary)
                        .position(x: leftPadding + 14, y: axisY + 10)
                    
                    Text("3 mo")
                        .font(.caption2)
                        .foregroundColor(Color.theme.textSecondary)
                        .position(x: tick3Months, y: axisY + 10)
                    
                    Text("6 mo")
                        .font(.caption2)
                        .foregroundColor(Color.theme.textSecondary)
                        .position(x: tick6Months, y: axisY + 10)
                }
            }
            .frame(height: 250)
            .onAppear {
                withAnimation(.easeInOut(duration: 2.4)) {
                    animationPhase = 1
                }
            }

            VStack(alignment: .leading, spacing: 6) {
                legendItem(label: "Infrastructure", color: colorForLine(index: 0))
                legendItem(label: "Data", color: colorForLine(index: 1))
                legendItem(label: "API Design", color: colorForLine(index: 2))
                legendItem(label: "Theory", color: colorForLine(index: 3))
                legendItem(label: "Product", color: colorForLine(index: 4))
            }
            .font(.caption2)
            .foregroundColor(Color.theme.textSecondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 8)
        }
        .padding(.horizontal)
    }

    private func colorForLine(index: Int) -> Color {
        switch index {
        case 0: return Color(red: 0.95, green: 0.55, blue: 0.15)
        case 1: return Color(red: 0.30, green: 0.65, blue: 0.95)
        case 2: return Color(red: 0.85, green: 0.30, blue: 0.75)
        case 3: return Color(red: 0.25, green: 0.85, blue: 0.55)
        default: return Color(red: 0.90, green: 0.25, blue: 0.35)
        }
    }

    private func legendItem(label: String, color: Color) -> some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 6, height: 6)
            Text(label)
        }
    }
    
    private func ratingForIndex(_ index: Int) -> CGFloat {
        let keyOrder = [
            "infrastructure",
            "data",
            "api_design",
            "theory",
            "product"
        ]
        let key = keyOrder[index]
        let rating = ratings.first(where: { $0.skillKey == key })?.rating ?? 3
        return CGFloat(min(max(rating, 1), 5))
    }

    private func jitter(for index: Int, rating: CGFloat) -> CGFloat {
        let seed = CGFloat((index + 1) * 97) + (rating * 53)
        let value = (sin(seed) * 0.6) + (cos(seed * 1.9) * 0.6)
        return max(-0.28, min(0.28, value))
    }
}
