import Foundation
import Supabase

class QuestionService: ObservableObject {
    static let shared = QuestionService()
    
    @Published var todaysQuestion: Question?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private init() {}
    
    // MARK: - Fetch Today's Question
    func fetchTodaysQuestion() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let response: [DailyChallenge] = try await SupabaseManager.shared.client
                .from("daily_challenges")
                .select("*, question:questions(*)")
                .eq("challenge_date", value: getCurrentDateString())
                .execute()
                .value
            
            if let challenge = response.first, let question = challenge.question {
                await MainActor.run {
                    self.todaysQuestion = question
                    self.isLoading = false
                }
            } else {
                await MainActor.run {
                    self.errorMessage = "No question available for today"
                    self.isLoading = false
                }
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to fetch question: \(error.localizedDescription)"
                self.isLoading = false
            }
        }
    }
    
    // MARK: - Submit Answer
    func submitAnswer(questionId: UUID, selectedAnswer: String, isCorrect: Bool, timeTaken: Int) async {
        do {
            let progress = UserProgress(
                id: UUID(),
                userId: getCurrentUserId(),
                questionId: questionId,
                answer: QuestionAnswer(correctOptionId: selectedAnswer, correctText: nil),
                isCorrect: isCorrect,
                timeTaken: timeTaken,
                completedAt: ISO8601DateFormatter().string(from: Date())
            )
            
            try await SupabaseManager.shared.client
                .from("user_progress")
                .insert(progress)
                .execute()
        } catch {
            print("Failed to save progress: \(error)")
        }
    }
    
    // MARK: - Helper Methods
    private func getCurrentDateString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }
    
    private func getCurrentUserId() -> UUID {
        // TODO: Get from auth session
        return UUID() // Placeholder
    }
}
