import Foundation
import Supabase

struct SelfAssessmentRecord: Codable, Identifiable {
    let id: UUID
    let userId: UUID
    let assessmentDate: String
    let ratings: [String: Int]
    let source: String?
    let createdAt: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case assessmentDate = "assessment_date"
        case ratings
        case source
        case createdAt = "created_at"
    }
}

struct SelfAssessmentInsertRecord: Encodable {
    let id: UUID
    let userId: UUID
    let assessmentDate: String
    let ratings: [String: Int]
    let source: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case assessmentDate = "assessment_date"
        case ratings
        case source
    }
}

struct AssessmentAnswerInsertRecord: Encodable {
    let id: UUID
    let assessmentId: UUID
    let userId: UUID
    let questionId: UUID
    let questionType: String
    let answer: AssessmentAnswerPayload
    let isCorrect: Bool
    let timeTaken: Int
    let completedAt: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case assessmentId = "assessment_id"
        case userId = "user_id"
        case questionId = "question_id"
        case questionType = "question_type"
        case answer
        case isCorrect = "is_correct"
        case timeTaken = "time_taken"
        case completedAt = "completed_at"
    }
}

struct SelfAssessmentService {
    static var assessmentIntervalHours: Int = 24 * 30

    func fetchAssessments() async -> [SelfAssessmentRecord] {
        do {
            let session = try await SupabaseManager.shared.client.auth.session
            let userId = session.user.id.uuidString
            
            let records: [SelfAssessmentRecord] = try await SupabaseManager.shared.client
                .from("user_self_assessments")
                .select()
                .eq("user_id", value: userId)
                .order("assessment_date", ascending: true)
                .execute()
                .value
            
            return records
        } catch {
            DebugLogger.error("Failed to fetch self assessments: \(error)")
            return []
        }
    }
    
    func hasInitialAssessment() async -> Bool {
        let records = await fetchAssessments()
        return records.contains { record in
            record.source == nil || record.source == AssessmentSource.initial.rawValue
        }
    }
    
    func latestAssessmentDate() async -> Date? {
        let records = await fetchAssessments()
        let dates = records.compactMap { DateUtils.parseISODate($0.assessmentDate) }
        return dates.sorted().last
    }
    
    func hasAssessmentForCurrentMonth(records: [SelfAssessmentRecord]) -> Bool {
        let calendar = Calendar.current
        let now = Date()
        let currentYear = calendar.component(.year, from: now)
        let currentMonth = calendar.component(.month, from: now)
        
        return records.contains { record in
            guard let date = DateUtils.parseISODate(record.assessmentDate) else { return false }
            return calendar.component(.year, from: date) == currentYear &&
                   calendar.component(.month, from: date) == currentMonth
        }
    }
    
    func submitAssessment(ratings: [SkillRating], source: AssessmentSource) async throws {
        let session = try await SupabaseManager.shared.client.auth.session
        let userId = session.user.id
        let assessmentId = UUID()
        let ratingMap = Dictionary(uniqueKeysWithValues: ratings.map { ($0.skillKey, $0.rating) })
        
        let record = SelfAssessmentInsertRecord(
            id: assessmentId,
            userId: userId,
            assessmentDate: DateUtils.iso8601WithFractional.string(from: Date()),
            ratings: ratingMap,
            source: source.rawValue
        )
        
        _ = try await SupabaseManager.shared.client
            .from("user_self_assessments")
            .insert(record)
            .execute()
        
        AnalyticsService.shared.track("self_assessment_submitted", properties: [
            "source": source.rawValue
        ])
    }
    
    func isAssessmentDue(records: [SelfAssessmentRecord]) -> Bool {
        guard !records.isEmpty else { return false }
        let dates = records.compactMap { DateUtils.parseISODate($0.assessmentDate) }.sorted()
        guard let lastDate = dates.last else { return false }
        
        let intervalHours = max(1, SelfAssessmentService.assessmentIntervalHours)
        let hoursSinceLast = Calendar.current.dateComponents([.hour], from: lastDate, to: Date()).hour ?? 0
        return hoursSinceLast >= intervalHours
    }
}
