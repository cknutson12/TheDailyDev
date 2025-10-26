import Foundation

// MARK: - Question Model
struct Question: Codable, Identifiable {
    let id: UUID
    let title: String
    let questionType: String
    let content: QuestionContent
    let correctAnswer: QuestionAnswer
    let explanation: String?
    let difficultyLevel: Int
    let category: String?
    let scheduledDate: String?
    let createdAt: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case questionType = "question_type"
        case content
        case correctAnswer = "correct_answer"
        case explanation
        case difficultyLevel = "difficulty_level"
        case category
        case scheduledDate = "scheduled_date"
        case createdAt = "created_at"
    }
}

// MARK: - Question Content (JSONB)
struct QuestionContent: Codable {
    let question: String
    let options: [QuestionOption]?
    let diagramRef: String?
    let imageUrl: String?
    let imageAlt: String?
    
    enum CodingKeys: String, CodingKey {
        case question
        case options
        case diagramRef = "diagram_ref"
        case imageUrl = "image_url"
        case imageAlt = "image_alt"
    }
}

// MARK: - Question Option
struct QuestionOption: Codable, Identifiable {
    let id: String
    let text: String
}

// MARK: - Question Answer
struct QuestionAnswer: Codable {
    let correctOptionId: String?
    let correctText: String?
    
    enum CodingKeys: String, CodingKey {
        case correctOptionId = "correct_option_id"
        case correctText = "correct_text"
    }
}

// MARK: - User Progress
struct UserProgress: Codable {
    let id: UUID
    let userId: UUID
    let questionId: UUID
    let answer: QuestionAnswer?
    let isCorrect: Bool?
    let timeTaken: Int?
    let completedAt: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case questionId = "question_id"
        case answer
        case isCorrect = "is_correct"
        case timeTaken = "time_taken"
        case completedAt = "completed_at"
    }
}

// MARK: - User Progress with Question
struct UserProgressWithQuestion: Codable {
    let id: UUID
    let userId: UUID
    let questionId: UUID
    let answer: QuestionAnswer?
    let isCorrect: Bool?
    let timeTaken: Int?
    let completedAt: String
    let question: Question?
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case questionId = "question_id"
        case answer
        case isCorrect = "is_correct"
        case timeTaken = "time_taken"
        case completedAt = "completed_at"
        case question
    }
}

// MARK: - Daily Challenge
struct DailyChallenge: Codable {
    let id: UUID
    let questionId: UUID
    let challengeDate: String
    let question: Question?
    
    enum CodingKeys: String, CodingKey {
        case id
        case questionId = "question_id"
        case challengeDate = "challenge_date"
        case question
    }
}

// MARK: - Category Performance
struct CategoryPerformance: Identifiable {
    let id = UUID()
    let category: String
    let correctAnswers: Int
    let totalAnswers: Int
    let percentage: Double
}
