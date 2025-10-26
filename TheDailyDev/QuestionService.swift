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
    
    // MARK: - Fetch User Progress History
    func fetchUserProgressHistory() async -> [UserProgressWithQuestion] {
        do {
            // Get the current authenticated user
            let session = try await SupabaseManager.shared.client.auth.session
            let userId = session.user.id
            
            let response: [UserProgressWithQuestion] = try await SupabaseManager.shared.client
                .from("user_progress")
                .select("*, question:questions(*)")
                .eq("user_id", value: userId)
                .order("completed_at", ascending: false)
                .execute()
                .value
            
            return response
        } catch {
            print("❌ Failed to fetch user progress: \(error)")
            return []
        }
    }
    
    // MARK: - Submit Answer
    func submitAnswer(questionId: UUID, selectedAnswer: String, isCorrect: Bool, timeTaken: Int) async {
        do {
            // Get the current authenticated user
            let session = try await SupabaseManager.shared.client.auth.session
            let userId = session.user.id
            
            print("🔐 Authenticated user ID: \(userId)")
            
            let progress = UserProgress(
                id: UUID(),
                userId: userId, // Use actual user ID
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
                
            print("✅ Progress saved successfully")
        } catch {
            print(" Failed to save progress: \(error)")
        }
    }
    
    // MARK: - Get User Info
    func getCurrentUser() async -> User? {
        do {
            let session = try await SupabaseManager.shared.client.auth.session
            return session.user
        } catch {
            print("❌ Failed to get current user: \(error)")
            return nil
        }
    }
    
    // MARK: - Get User Display Name
    func getUserDisplayName() async -> String {
        do {
            // First try to get the user profile name
            let session = try await SupabaseManager.shared.client.auth.session
            let userId = session.user.id
            
            let response: [UserProfile] = try await SupabaseManager.shared.client
                .from("user_profiles")
                .select("*")
                .eq("id", value: userId.uuidString)
                .execute()
                .value
            
            if let profile = response.first, !profile.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                return profile.name.trimmingCharacters(in: .whitespacesAndNewlines)
            }
            
            // Fallback to user metadata name
            if let metadataName = session.user.userMetadata["name"] as? String,
               !metadataName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                return metadataName.trimmingCharacters(in: .whitespacesAndNewlines)
            }
            
            // Final fallback to email
            return session.user.email ?? "User"
            
        } catch {
            print("❌ Failed to get user display name: \(error)")
            return "User"
        }
    }
    
    // MARK: - Calculate Streak
    func calculateCurrentStreak() async -> Int {
        let progressHistory = await fetchUserProgressHistory()
        
        // Sort by completion date (most recent first)
        let sortedProgress = progressHistory.sorted { progress1, progress2 in
            let date1 = ISO8601DateFormatter().date(from: progress1.completedAt) ?? Date.distantPast
            let date2 = ISO8601DateFormatter().date(from: progress2.completedAt) ?? Date.distantPast
            return date1 > date2
        }
        
        var streak = 0
        let calendar = Calendar.current
        var currentDate = Date()
        
        for progress in sortedProgress {
            guard let isCorrect = progress.isCorrect, isCorrect else {
                break // Streak ends when we hit an incorrect answer
            }
            
            let progressDate = ISO8601DateFormatter().date(from: progress.completedAt) ?? Date.distantPast
            
            // Check if this progress is within the expected date range for the streak
            if calendar.isDate(progressDate, inSameDayAs: currentDate) ||
               calendar.isDate(progressDate, inSameDayAs: calendar.date(byAdding: .day, value: -1, to: currentDate) ?? currentDate) {
                streak += 1
                currentDate = calendar.date(byAdding: .day, value: -1, to: currentDate) ?? currentDate
            } else {
                break
            }
        }
        
        return streak
    }
    
    // MARK: - Calculate Category Performance
    func calculateCategoryPerformance() async -> [CategoryPerformance] {
        let progressHistory = await fetchUserProgressHistory()
        
        // Group progress by category
        var categoryStats: [String: (correct: Int, total: Int)] = [:]
        
        for progress in progressHistory {
            guard let question = progress.question,
                  let category = question.category,
                  let isCorrect = progress.isCorrect else {
                continue
            }
            
            if categoryStats[category] == nil {
                categoryStats[category] = (correct: 0, total: 0)
            }
            
            categoryStats[category]?.total += 1
            if isCorrect {
                categoryStats[category]?.correct += 1
            }
        }
        
        // Convert to CategoryPerformance array and sort by percentage
        let performances = categoryStats.map { (category, stats) in
            let percentage = stats.total > 0 ? Double(stats.correct) / Double(stats.total) * 100 : 0.0
            return CategoryPerformance(
                category: category,
                correctAnswers: stats.correct,
                totalAnswers: stats.total,
                percentage: percentage
            )
        }.sorted { $0.percentage > $1.percentage }
        
        return performances
    }
    
    // MARK: - Helper Methods
    private func getCurrentDateString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }
    
    private func getCurrentUserId() async -> UUID? {
        // Get the current authenticated user
        do {
            let session = try await SupabaseManager.shared.client.auth.session
            return session.user.id
        } catch {
            print("No authenticated user found: \(error)")
            return nil
        }
    }
}
