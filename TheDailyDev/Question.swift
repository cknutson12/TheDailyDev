import Foundation

// MARK: - Question Model
struct Question: Codable, Identifiable {
    let id: UUID
    let title: String
    let content: QuestionContent
    let correctAnswer: QuestionAnswer
    let explanation: String?
    let difficultyLevel: Int
    let category: String?
    let createdAt: String
    
    // Deprecated fields (kept for backward compatibility, not used by app)
    let questionType: String?
    let scheduledDate: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case content
        case correctAnswer = "correct_answer"
        case explanation
        case difficultyLevel = "difficulty_level"
        case category
        case createdAt = "created_at"
        case questionType = "question_type"
        case scheduledDate = "scheduled_date"
    }
}

// MARK: - Question Content (JSONB)
struct QuestionContent: Codable {
    let question: String
    let options: [QuestionOption]?
    let diagramRef: String?
    let imageUrl: String?
    let imageAlt: String?
    let matchingItems: [MatchingItem]?
    let correctMatches: [MatchPair]?
    let orderingItems: [OrderingItem]?
    let correctOrderIds: [String]?
    
    enum CodingKeys: String, CodingKey {
        case question
        case options
        case diagramRef = "diagram_ref"
        case imageUrl = "image_url"
        case imageAlt = "image_alt"
        case matchingItems = "matching_items"
        case correctMatches = "correct_matches"
        case orderingItems = "ordering_items"
        case correctOrderIds = "correct_order_ids"
    }
}

// MARK: - Question Option
struct QuestionOption: Codable, Identifiable {
    let id: String
    let text: String
}

// MARK: - Matching Item
struct MatchingItem: Codable, Identifiable {
    let id: String
    let text: String
    let isDraggable: Bool
    
    enum CodingKeys: String, CodingKey {
        case id
        case text
        case isDraggable = "is_draggable"
    }
}

// MARK: - Match Pair
struct MatchPair: Codable {
    let sourceId: String
    let targetId: String
    
    enum CodingKeys: String, CodingKey {
        case sourceId = "source_id"
        case targetId = "target_id"
    }
}

// MARK: - Ordering Item
struct OrderingItem: Codable, Identifiable {
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

// MARK: - Date Helpers for Progress Models
enum DateUtils {
    static let iso8601WithFractional: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()
    
    static let iso8601Basic: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()
    
    static func parseISODate(_ string: String) -> Date? {
        if let date = iso8601WithFractional.date(from: string) {
            return date
        }
        return iso8601Basic.date(from: string)
    }
}

extension UserProgress {
    var completedDate: Date? {
        DateUtils.parseISODate(completedAt)
    }
    
    var completedDayLocal: Date? {
        guard let date = completedDate else { return nil }
        return Calendar.current.startOfDay(for: date)
    }
}

extension UserProgressWithQuestion {
    var completedDate: Date? {
        DateUtils.parseISODate(completedAt)
    }
    
    var completedDayLocal: Date? {
        guard let date = completedDate else { return nil }
        return Calendar.current.startOfDay(for: date)
    }
}
