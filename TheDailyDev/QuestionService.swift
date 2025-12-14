import Foundation
import Supabase

class QuestionService: ObservableObject {
    static let shared = QuestionService()
    
    @Published var todaysQuestion: Question?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // Cache management - different durations for different data types
    private var cachedProgressHistory: [UserProgressWithQuestion]?
    private var progressHistoryFetchTime: Date?
    private let progressHistoryCacheTimeout: TimeInterval = 86400 // 24 hours
    
    private var cachedHasAnsweredToday: Bool?
    private var hasAnsweredTodayFetchTime: Date?
    private var lastCheckedDate: String? // Track which day we checked
    
    private var cachedHasAnsweredAny: Bool?
    // No timeout - once true, always true
    
    private var cachedStreak: Int?
    private var streakFetchTime: Date?
    private var streakCachedDate: String? // Track which day streak was calculated
    // Cache until midnight or user answers (date-aware)
    
    private var cachedDisplayName: String?
    private var displayNameFetchTime: Date?
    private let displayNameCacheTimeout: TimeInterval = 86400 // 24 hours
    
    // Request deduplication - prevent concurrent requests
    private var currentHasAnsweredTodayTask: Task<Bool, Never>?
    
    private init() {}
    
    // MARK: - Cache Invalidation
    /// Call this after user answers a question to refresh stats
    func invalidateProgressCache() {
        progressHistoryFetchTime = nil
        cachedHasAnsweredToday = nil
        hasAnsweredTodayFetchTime = nil
        cachedStreak = nil
        streakFetchTime = nil
        streakCachedDate = nil
        print("🔄 Progress cache invalidated - stats will refresh")
    }
    
    /// Invalidate question cache - call when you want to force refresh today's question
    func invalidateQuestionCache() {
        todaysQuestion = nil
        errorMessage = nil
        print("🔄 Question cache invalidated - will fetch fresh question")
    }
    
    /// Clear ALL caches - call on sign out to ensure no user data persists
    func clearAllCaches() {
        // Clear progress history cache
        cachedProgressHistory = nil
        progressHistoryFetchTime = nil
        
        // Clear answered today cache
        cachedHasAnsweredToday = nil
        hasAnsweredTodayFetchTime = nil
        lastCheckedDate = nil
        
        // Clear has answered any cache
        cachedHasAnsweredAny = nil
        
        // Clear streak cache
        cachedStreak = nil
        streakFetchTime = nil
        streakCachedDate = nil
        
        // Clear display name cache
        cachedDisplayName = nil
        displayNameFetchTime = nil
        
        // Clear today's question
        todaysQuestion = nil
        errorMessage = nil
        isLoading = false
        
        // Cancel any in-progress requests
        currentHasAnsweredTodayTask?.cancel()
        currentHasAnsweredTodayTask = nil
        
        print("🧹 All QuestionService caches cleared")
    }
    
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
    
    // MARK: - Check if User Has Answered Any Question
    func hasAnsweredAnyQuestion() async -> Bool {
        // Once true, always true - cache indefinitely
        if let cached = cachedHasAnsweredAny, cached == true {
            print("✅ Using cached 'has answered any' (value: true)")
            return true
        }
        
        do {
            let session = try await SupabaseManager.shared.client.auth.session
            let userId = session.user.id
            
            // Use count query instead of fetching data
            let response = try await SupabaseManager.shared.client
                .from("user_progress")
                .select("*", head: false, count: .exact)
                .eq("user_id", value: userId)
                .limit(1)
                .execute()
            
            let count = response.count ?? 0
            let hasAnswered = count > 0
            
            // Cache the result (especially if true)
            cachedHasAnsweredAny = hasAnswered
            print("✅ Checked if user has answered any: \(hasAnswered)")
            
            return hasAnswered
        } catch {
            print("❌ Failed to check if user has answered: \(error)")
            return false
        }
    }
    
    // MARK: - Fetch All Daily Challenges
    /// Fetches all daily challenges (answered and unanswered) for question history
    func fetchAllDailyChallenges(forceRefresh: Bool = false) async -> [DailyChallenge] {
        do {
            // Fetch all daily challenges with their questions
            // Order by challenge_date descending to show most recent first
            let response: [DailyChallenge] = try await SupabaseManager.shared.client
                .from("daily_challenges")
                .select("*, question:questions(*)")
                .order("challenge_date", ascending: false)
                .execute()
                .value
            
            print("✅ Fetched \(response.count) daily challenges")
            return response
        } catch {
            print("❌ Failed to fetch daily challenges: \(error)")
            return []
        }
    }
    
    // MARK: - Fetch User Progress History
    func fetchUserProgressHistory(forceRefresh: Bool = false) async -> [UserProgressWithQuestion] {
        // Check cache first (24-hour cache for history)
        if !forceRefresh,
           let cached = cachedProgressHistory,
           let lastFetch = progressHistoryFetchTime,
           Date().timeIntervalSince(lastFetch) < progressHistoryCacheTimeout {
            let age = Int(Date().timeIntervalSince(lastFetch))
            print("✅ Using cached progress history (age: \(age)s, \(cached.count) records)")
            return cached
        }
        
        print("🔄 Fetching fresh progress history...")
        
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
            
            // Cache the result
            cachedProgressHistory = response
            progressHistoryFetchTime = Date()
            print("✅ Progress history cached (\(response.count) records)")
            
            return response
        } catch {
            let nsError = error as NSError
            if nsError.domain == NSURLErrorDomain && nsError.code == NSURLErrorCancelled {
                print("ℹ️ Progress fetch cancelled (likely superseded by a newer request).")
                return cachedProgressHistory ?? []
            }
            print("❌ Failed to fetch user progress: \(error)")
            return cachedProgressHistory ?? [] // Return cached data if available
        }
    }
    
    // MARK: - Submit Answer
    func submitAnswer(questionId: UUID, selectedAnswer: String, isCorrect: Bool, timeTaken: Int) async {
        do {
            // Get the current authenticated user
            let session = try await SupabaseManager.shared.client.auth.session
            let userId = session.user.id
            
            print("🔐 Authenticated user ID: \(userId)")
            
            // Save with actual completion time (when user actually answered)
            let progress = UserProgress(
                id: UUID(),
                userId: userId, // Use actual user ID
                questionId: questionId,
                answer: QuestionAnswer(correctOptionId: selectedAnswer, correctText: nil),
                isCorrect: isCorrect,
                timeTaken: timeTaken,
                completedAt: DateUtils.iso8601WithFractional.string(from: Date())
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
            
            // Save with actual completion time (when user actually answered)
            let progress = UserProgress(
                id: UUID(),
                userId: userId,
                questionId: questionId,
                answer: QuestionAnswer(correctOptionId: nil, correctText: matchesString),
                isCorrect: isCorrect,
                timeTaken: timeTaken,
                completedAt: DateUtils.iso8601WithFractional.string(from: Date())
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
            
            // Save with actual completion time (when user actually answered)
            let progress = UserProgress(
                id: UUID(),
                userId: userId,
                questionId: questionId,
                answer: QuestionAnswer(correctOptionId: nil, correctText: orderString),
                isCorrect: isCorrect,
                timeTaken: timeTaken,
                completedAt: DateUtils.iso8601WithFractional.string(from: Date())
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
        // Check display name cache (24-hour cache)
        if let cached = cachedDisplayName,
           let lastFetch = displayNameFetchTime,
           Date().timeIntervalSince(lastFetch) < displayNameCacheTimeout {
            let age = Int(Date().timeIntervalSince(lastFetch))
            print("✅ Using cached display name (age: \(age)s)")
            return cached
        }
        
        print("🔄 Fetching fresh display name...")
        
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
            
            var displayName = "User"
            
            // Use full name from subscription if available
            if let subscription = subscriptions.first, !subscription.fullName.isEmpty, subscription.fullName != "User" {
                displayName = subscription.fullName
            } else {
                // Final fallback to email
                displayName = session.user.email ?? "User"
            }
            
            // Cache the result
            cachedDisplayName = displayName
            displayNameFetchTime = Date()
            print("✅ Display name cached: \(displayName)")
            
            return displayName
            
        } catch {
            print("❌ Failed to get user display name: \(error)")
            return "User"
        }
    }
    
    // MARK: - Calculate Streak
    func calculateCurrentStreak() async -> Int {
        let todayDateString = getCurrentDateString()
        
        // Check streak cache (date-aware - valid until midnight)
        if let cached = cachedStreak,
           let cachedDate = streakCachedDate,
           cachedDate == todayDateString {
            print("✅ Using cached streak (value: \(cached), cached today)")
            return cached
        }
        
        if let oldDate = streakCachedDate, oldDate != todayDateString {
            print("🔄 Date changed (\(oldDate) → \(todayDateString)) - recalculating streak...")
        } else {
            print("🔄 Calculating fresh streak...")
        }
        
        // Fetch both progress history and daily challenges
        let progressHistory = await fetchUserProgressHistory()
        let allChallenges = await fetchAllDailyChallenges()
        
        // Create a map of challenge_date -> question_id for quick lookup
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        
        var challengeMap: [String: UUID] = [:]
        for challenge in allChallenges {
            challengeMap[challenge.challengeDate] = challenge.questionId
        }
        
        // Create a map of (date, question_id) -> progress for quick lookup
        // Only include correct answers
        var progressMap: [String: UserProgressWithQuestion] = [:]
        for progress in progressHistory {
            guard let isCorrect = progress.isCorrect, isCorrect else { continue }
            
            if let progressDate = progress.completedDayLocal {
                let dateKey = dateFormatter.string(from: progressDate)
                let mapKey = "\(dateKey)|\(progress.questionId.uuidString)"
                progressMap[mapKey] = progress
            }
        }
        
        // Calculate streak by checking consecutive days backwards from today
        var streak = 0
        let calendar = Calendar.current
        var currentDate = Date()
        let dateFormatterLocal = DateFormatter()
        dateFormatterLocal.dateFormat = "yyyy-MM-dd"
        
        // Check up to 365 days back (reasonable limit)
        for _ in 0..<365 {
            let dateString = dateFormatterLocal.string(from: currentDate)
            
            // Get the question ID scheduled for this date
            guard let scheduledQuestionId = challengeMap[dateString] else {
                // No question scheduled for this date - streak ends
                break
            }
            
            // Check if user answered the question scheduled for this date
            let mapKey = "\(dateString)|\(scheduledQuestionId.uuidString)"
            if progressMap[mapKey] != nil {
                // User answered the question of the day - continue streak
                streak += 1
            } else {
                // User didn't answer the question of the day - streak ends
                break
            }
            
            // Move to previous day
            guard let previousDay = calendar.date(byAdding: .day, value: -1, to: currentDate) else {
                break
            }
            currentDate = previousDay
        }
        
        // Cache the result (valid until midnight)
        cachedStreak = streak
        streakFetchTime = Date()
        streakCachedDate = todayDateString
        print("✅ Streak calculated and cached: \(streak) (valid until midnight)")
        
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
        let todayDateString = getCurrentDateString()
        
        // Check if we have a cached result for TODAY
        if let cached = cachedHasAnsweredToday,
           let lastChecked = lastCheckedDate,
           lastChecked == todayDateString {
            print("✅ Using cached 'has answered today' (value: \(cached))")
            return cached
        }
        
        // If there's already a request in progress, wait for it instead of starting a new one
        if let existingTask = currentHasAnsweredTodayTask {
            print("ℹ️ 'Has answered today' check already in progress, waiting for existing request...")
            return await existingTask.value
        }
        
        // Create a new task
        let checkTask = Task<Bool, Never> {
            print("🔄 Checking if answered today (\(todayDateString))...")
            
            do {
            // Get today's question ID
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
            
                let hasAnswered = !progressResponse.isEmpty
                
                // Cache the result for today
                cachedHasAnsweredToday = hasAnswered
                lastCheckedDate = todayDateString
                hasAnsweredTodayFetchTime = Date()
                print("✅ Answered today check cached: \(hasAnswered)")
                
                // Clear task reference when done
                await MainActor.run {
                    self.currentHasAnsweredTodayTask = nil
                }
                
                return hasAnswered
            } catch {
                let nsError = error as NSError
                // Don't log cancelled errors as failures - they're expected when requests are deduplicated
                if nsError.domain == NSURLErrorDomain && nsError.code == NSURLErrorCancelled {
                    print("ℹ️ 'Has answered today' check cancelled (likely superseded by a newer request)")
                    // Return cached value if available, otherwise false
                    await MainActor.run {
                        self.currentHasAnsweredTodayTask = nil
                    }
                    return cachedHasAnsweredToday ?? false
                } else {
                    print("❌ Failed to check if answered today: \(error)")
                }
                await MainActor.run {
                    self.currentHasAnsweredTodayTask = nil
                }
                return false
            }
        }
        
        // Store the task and await its result
        await MainActor.run {
            self.currentHasAnsweredTodayTask = checkTask
        }
        
        return await checkTask.value
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
