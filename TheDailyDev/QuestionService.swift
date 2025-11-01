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
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
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
    
    // MARK: - Submit Matching Answer
    func submitMatchingAnswer(questionId: UUID, matches: [String: String], isCorrect: Bool, timeTaken: Int) async {
        do {
            // Get the current authenticated user
            let session = try await SupabaseManager.shared.client.auth.session
            let userId = session.user.id
            
            print("🔐 Authenticated user ID: \(userId)")
            print("📝 Submitting matching answer with \(matches.count) matches")
            
            // Convert matches dictionary to JSON string for storage
            let matchesData = try JSONEncoder().encode(matches)
            let matchesString = String(data: matchesData, encoding: .utf8) ?? "{}"
            
            let progress = UserProgress(
                id: UUID(),
                userId: userId,
                questionId: questionId,
                answer: QuestionAnswer(correctOptionId: nil, correctText: matchesString),
                isCorrect: isCorrect,
                timeTaken: timeTaken,
                completedAt: ISO8601DateFormatter().string(from: Date())
            )
            
            try await SupabaseManager.shared.client
                .from("user_progress")
                .insert(progress)
                .execute()
                
            print("✅ Matching answer saved successfully")
        } catch {
            print("❌ Failed to save matching answer: \(error)")
        }
    }
    
    // MARK: - Submit Ordering Answer
    func submitOrderingAnswer(questionId: UUID, orderIds: [String], isCorrect: Bool, timeTaken: Int) async {
        do {
            let session = try await SupabaseManager.shared.client.auth.session
            let userId = session.user.id
            
            print("🔐 Authenticated user ID: \(userId)")
            print("📝 Submitting ordering answer with \(orderIds.count) items")
            
            let orderData = try JSONEncoder().encode(orderIds)
            let orderString = String(data: orderData, encoding: .utf8) ?? "[]"
            
            let progress = UserProgress(
                id: UUID(),
                userId: userId,
                questionId: questionId,
                answer: QuestionAnswer(correctOptionId: nil, correctText: orderString),
                isCorrect: isCorrect,
                timeTaken: timeTaken,
                completedAt: ISO8601DateFormatter().string(from: Date())
            )
            
            try await SupabaseManager.shared.client
                .from("user_progress")
                .insert(progress)
                .execute()
            
            print("✅ Ordering answer saved successfully")
        } catch {
            print("❌ Failed to save ordering answer: \(error)")
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
            let session = try await SupabaseManager.shared.client.auth.session
            let userId = session.user.id.uuidString
            
            // Get subscription with name info
            let subscriptions: [UserSubscription] = try await SupabaseManager.shared.client
                .from("user_subscriptions")
                .select()
                .eq("user_id", value: userId)
                .order("created_at", ascending: false)
                .limit(1)
                .execute()
                .value
            
            // Use full name from subscription if available
            if let subscription = subscriptions.first, !subscription.fullName.isEmpty, subscription.fullName != "User" {
                return subscription.fullName
            }
            
            // Fallback to user metadata name - skipping for now as AnyJSON casting is complex
            // TODO: Implement proper AnyJSON to String extraction
            
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
    
    // MARK: - Check if User Answered Today
    func hasAnsweredToday() async -> Bool {
        do {
            // Get today's question ID
            let todayDateString = getCurrentDateString()
            let challengeResponse: [DailyChallenge] = try await SupabaseManager.shared.client
                .from("daily_challenges")
                .select("id, question_id, challenge_date")
                .eq("challenge_date", value: todayDateString)
                .execute()
                .value
            
            guard let challenge = challengeResponse.first else {
                return false
            }
            
            // Check if user has progress for today's question
            let session = try await SupabaseManager.shared.client.auth.session
            let userId = session.user.id
            
            let progressResponse: [UserProgress] = try await SupabaseManager.shared.client
                .from("user_progress")
                .select("id, user_id, question_id, answer, is_correct, time_taken, completed_at")
                .eq("user_id", value: userId)
                .eq("question_id", value: challenge.questionId)
                .limit(1)
                .execute()
                .value
            
            return !progressResponse.isEmpty
        } catch {
            print("❌ Failed to check if answered today: \(error)")
            return false
        }
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
