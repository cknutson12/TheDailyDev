import SwiftUI

// MARK: - Layout Constants
/// Constants for the contribution tracking grid layout
/// Centralizes all sizing values for easy maintenance and consistency
private enum ContributionGridLayout {
    static let squareSize: CGFloat = 24           // Size of each contribution square
    static let squareSpacing: CGFloat = 2         // Space between squares
    static let cornerRadius: CGFloat = 3          // Rounded corners for squares
    static let dayLabelWidth: CGFloat = 40        // Width of day label column
    static let weeksToDisplay: Int = 52           // Number of weeks to show in the grid
    
    // Calculated values for consistency
    // Month label width must match the week column width (squareSize only, spacing is added by HStack)
    static var monthLabelWidth: CGFloat {
        squareSize
    }
}

// MARK: - Contributions Tracker View
/// Main view for displaying user's question history in a GitHub-style contribution grid
/// 
/// Features:
/// - GitHub-style contribution calendar showing answered/unanswered questions
/// - Rolling 52-week view for current year, full calendar year for past years
/// - Color-coded squares: green=correct, red=incorrect, gray=unanswered
/// - Tappable squares to review past questions or answer missed ones
/// - Year selector tabs for viewing historical data
/// - Handles year boundaries and leap years correctly
struct ContributionsTracker: View {
    let progressHistory: [UserProgressWithQuestion]
    let allDailyChallenges: [DailyChallenge]
    @State private var selectedDate: Date?
    @State private var showingQuestionReview = false
    @State private var showingQuestion = false
    @State private var selectedProgress: UserProgressWithQuestion?
    @State private var selectedQuestion: Question?
    @State private var selectedYear: Int
    
    private let calendar = Calendar.current
    private let dateFormatter = DateFormatter()
    
    init(progressHistory: [UserProgressWithQuestion], allDailyChallenges: [DailyChallenge] = []) {
        self.progressHistory = progressHistory
        self.allDailyChallenges = allDailyChallenges
        self.dateFormatter.dateFormat = "yyyy-MM-dd"
        self._selectedYear = State(initialValue: Calendar.current.component(.year, from: Date()))
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Text("Question History")
                    .font(.title3)
                    .bold()
                
                Spacer()
                
                let answeredCount = filteredProgressHistory.count
                let totalCount = filteredChallenges.count
                Text("\(answeredCount)/\(totalCount) answered")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // Year Tabs
            if availableYears.count > 1 {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(availableYears, id: \.self) { year in
                            Button(action: {
                                selectedYear = year
                            }) {
                                Text(String(year))
                                    .font(.caption)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(selectedYear == year ? Color.accentColor : Color.gray.opacity(0.2))
                                    .foregroundColor(selectedYear == year ? .white : .primary)
                                    .cornerRadius(12)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                }
                .padding(.horizontal, -16)
            }
            
            // Legend
            HStack(spacing: 12) {
                LegendItem(color: Theme.Colors.stateCorrect, text: "Correct")
                LegendItem(color: Theme.Colors.stateIncorrect, text: "Incorrect")
                LegendItem(color: .gray.opacity(0.3), text: "Unanswered")
            }
            .padding(.bottom, 4)
            
            // Contributions Grid
            ContributionsGrid(
                progressHistory: filteredProgressHistory,
                allDailyChallenges: filteredChallenges,
                selectedYear: selectedYear,
                onDateSelected: { date, progress, question in
                    selectedDate = date
                    selectedProgress = progress
                    selectedQuestion = question
                    if progress != nil {
                        // Answered question - show review
                        showingQuestionReview = true
                    } else if question != nil {
                        // Unanswered question - show question view to answer
                        showingQuestion = true
                    } else {
                        // No question for this date - show review with empty state
                        showingQuestionReview = true
                    }
                }
            )
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
        .sheet(isPresented: $showingQuestionReview) {
            if let date = selectedDate {
                QuestionReviewView(progress: selectedProgress, date: date)
            }
        }
        .sheet(isPresented: $showingQuestion) {
            if let question = selectedQuestion {
                NavigationView {
                    Group {
                        if question.content.orderingItems != nil {
                            OrderingQuestionView(
                                question: question,
                                onComplete: {
                                    Task {
                                        // Invalidate caches immediately after answering
                                        QuestionService.shared.invalidateProgressCache()
                                        SubscriptionService.shared.invalidateCache()
                                    }
                                    showingQuestion = false
                                }
                            )
                        } else if question.content.matchingItems != nil {
                            MatchingQuestionView(
                                question: question,
                                onComplete: {
                                    Task {
                                        // Invalidate caches immediately after answering
                                        QuestionService.shared.invalidateProgressCache()
                                        SubscriptionService.shared.invalidateCache()
                                    }
                                    showingQuestion = false
                                }
                            )
                        } else {
                            MultipleChoiceQuestionView(
                                question: question,
                                onComplete: {
                                    Task {
                                        // Invalidate caches immediately after answering
                                        QuestionService.shared.invalidateProgressCache()
                                        SubscriptionService.shared.invalidateCache()
                                    }
                                    showingQuestion = false
                                }
                            )
                        }
                    }
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Close") {
                                showingQuestion = false
                            }
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Computed Properties
    private var availableYears: [Int] {
        // Get years from both progress history and daily challenges
        var years = Set<Int>()
        
        // Add years from progress history
        for progress in progressHistory {
            if let date = progress.completedDayLocal {
                years.insert(calendar.component(.year, from: date))
            }
        }
        
        // Add years from daily challenges
        for challenge in allDailyChallenges {
            if let date = parseDate(challenge.challengeDate) {
                years.insert(calendar.component(.year, from: date))
            }
        }
        
        return Array(years).sorted(by: >)
    }
    
    private var filteredProgressHistory: [UserProgressWithQuestion] {
        progressHistory.filter { progress in
            guard let date = progress.completedDayLocal else { return false }
            return calendar.component(.year, from: date) == selectedYear
        }
    }
    
    private var filteredChallenges: [DailyChallenge] {
        allDailyChallenges.filter { challenge in
            guard let date = parseDate(challenge.challengeDate) else { return false }
            return calendar.component(.year, from: date) == selectedYear
        }
    }
    
    private func parseDate(_ dateString: String) -> Date? {
        dateFormatter.date(from: dateString)
    }
}

// MARK: - Legend Item
struct LegendItem: View {
    let color: Color
    let text: String
    
    var body: some View {
        HStack(spacing: 3) {
            Rectangle()
                .fill(color)
                .frame(width: ContributionGridLayout.squareSize, height: ContributionGridLayout.squareSize)
                .cornerRadius(ContributionGridLayout.cornerRadius)
            
            Text(text)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Contributions Grid
struct ContributionsGrid: View {
    let progressHistory: [UserProgressWithQuestion]
    let allDailyChallenges: [DailyChallenge]
    let selectedYear: Int
    let onDateSelected: (Date, UserProgressWithQuestion?, Question?) -> Void
    
    private let calendar = Calendar.current
    private let dateFormatter = DateFormatter()
    
    init(progressHistory: [UserProgressWithQuestion], allDailyChallenges: [DailyChallenge], selectedYear: Int, onDateSelected: @escaping (Date, UserProgressWithQuestion?, Question?) -> Void) {
        self.progressHistory = progressHistory
        self.allDailyChallenges = allDailyChallenges
        self.selectedYear = selectedYear
        self.onDateSelected = onDateSelected
        // Date format matches the database format for daily challenges (yyyy-MM-dd)
        self.dateFormatter.dateFormat = "yyyy-MM-dd"
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            // Grid with fixed day labels and synchronized scrolling
            HStack(alignment: .top, spacing: ContributionGridLayout.squareSpacing) {
                // Day labels - Fixed on left, always visible
                VStack(spacing: ContributionGridLayout.squareSpacing) {
                    // Empty space to align with month labels
                    Text("")
                        .font(.caption2)
                        .frame(height: ContributionGridLayout.squareSize)
                    
                    // Day labels aligned with contribution squares
                    ForEach(0..<7) { dayIndex in
                        if let labelIndex = dayRowIndices.firstIndex(of: dayIndex) {
                            Text(dayLabels[labelIndex])
                                .font(.caption2)
                                .foregroundColor(.secondary)
                                .frame(height: ContributionGridLayout.squareSize)
                                .frame(maxWidth: .infinity, alignment: .trailing) // Right-align text
                                .minimumScaleFactor(0.7) // Allow text to scale down to 70%
                        } else {
                            // Empty space for other days
                            Text("")
                                .font(.caption2)
                                .frame(height: ContributionGridLayout.squareSize)
                        }
                    }
                }
                .frame(width: ContributionGridLayout.dayLabelWidth)
                
                // Single ScrollView containing both month labels and contribution squares
                ScrollViewReader { proxy in
                    ScrollView(.horizontal, showsIndicators: false) {
                        VStack(alignment: .leading, spacing: 4) {
                        // Month labels positioned based on calendar weeks
                        // Important: spacing must match the contribution squares HStack spacing for alignment
                        HStack(spacing: ContributionGridLayout.squareSpacing) {
                            ForEach(Array(0..<weeksToShow), id: \.self) { week in
                                if let monthLabel = getMonthLabelForWeek(week) {
                                    Text(monthLabel)
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                        .frame(width: ContributionGridLayout.monthLabelWidth)
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.5) // Allow text to scale down to 50%
                                } else {
                                    // Empty space for weeks without month labels
                                    // Must use same width as monthLabelWidth for consistent alignment
                                    Text("")
                                        .frame(width: ContributionGridLayout.monthLabelWidth)
                                }
                            }
                        }
                        
                        // Contribution squares
                        VStack(alignment: .leading, spacing: ContributionGridLayout.squareSpacing) {
                            ForEach(0..<7) { day in
                                HStack(spacing: ContributionGridLayout.squareSpacing) {
                                    ForEach(Array(0..<weeksToShow), id: \.self) { week in
                                        if let date = getDateForGridPosition(week: week, day: day) {
                                            let progress = progressForDate(date)
                                            let question = questionForDate(date)
                                            
                                            ContributionSquare(
                                                date: date,
                                                progress: progress,
                                                hasQuestion: question != nil,
                                                onTap: {
                                                    onDateSelected(date, progress, question)
                                                }
                                            )
                                            } else {
                                                // Empty space for future dates or dates outside the year
                                                if let date = getDateForGridPosition(week: week, day: day) {
                                                    // Show clickable empty box for past dates with no data
                                                    Rectangle()
                                                        .fill(Color.gray.opacity(0.3))
                                                        .frame(width: ContributionGridLayout.squareSize, height: ContributionGridLayout.squareSize)
                                                        .cornerRadius(ContributionGridLayout.cornerRadius)
                                                        .accessibilityIdentifier("ContributionSquare")
                                                        .onTapGesture {
                                                            onDateSelected(date, nil, nil)
                                                        }
                                                } else {
                                                    // Truly empty space for future dates
                                                    Rectangle()
                                                        .fill(Color.clear)
                                                        .frame(width: ContributionGridLayout.squareSize, height: ContributionGridLayout.squareSize)
                                                }
                                            }
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .id("contributionsGrid")
                }
                .onAppear {
                    // Track progress viewed
                    let answeredCount = progressHistory.count
                    AnalyticsService.shared.track("progress_viewed", properties: [
                        "total_questions_answered": answeredCount,
                        "year": selectedYear
                    ])
                    
                    // Scroll to the right (most recent data) when view appears
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        proxy.scrollTo("contributionsGrid", anchor: .trailing)
                    }
                }
                }
            }
        }
    }
    
    // MARK: - Date Calculation Methods
    
    /// Get date for a specific grid position (week, day)
    /// - Parameters:
    ///   - week: Week index (0-51), where 0 is the leftmost week and 51 is the rightmost (current) week
    ///   - day: Day index (0-6), where 0=Sunday, 1=Monday, ..., 6=Saturday
    /// - Returns: The date for this grid position, or nil if it's a future date or outside the selected year
    ///
    /// This method handles two different modes:
    /// 1. Current year: Shows a rolling 52-week view ending with the current week
    /// 2. Previous years: Shows all weeks in that calendar year
    ///
    /// Edge cases handled:
    /// - Year boundaries (Dec 31 → Jan 1): Calendar.date(byAdding:) handles this automatically
    /// - Leap years: Calendar.date(byAdding:) correctly handles Feb 29 in leap years
    /// - Future dates: Returns nil for dates that haven't occurred yet
    private func getDateForGridPosition(week: Int, day: Int) -> Date? {
        if selectedYear == Calendar.current.component(.year, from: Date()) {
            // Rolling 52-week view ending today
            let today = Date()
            
            // Calculate the start of the current week (Sunday)
            // weekday: 1=Sunday, 2=Monday, ..., 7=Saturday
            let todayWeekday = calendar.component(.weekday, from: today)
            let daysFromSunday = todayWeekday - 1  // 0 for Sunday, 1 for Monday, ..., 6 for Saturday
            let currentWeekStart = calendar.date(byAdding: .day, value: -daysFromSunday, to: today) ?? today
            
            // Calculate the target week start (going back by week number)
            // week 51 is current week, week 0 is 51 weeks ago
            let weeksBack = ContributionGridLayout.weeksToDisplay - 1 - week
            let targetWeekStart = calendar.date(byAdding: .weekOfYear, value: -weeksBack, to: currentWeekStart) ?? currentWeekStart
            
            // Add the day offset within the week (0=Sunday through 6=Saturday)
            let targetDate = calendar.date(byAdding: .day, value: day, to: targetWeekStart) ?? targetWeekStart
            
            // Only return dates that have actually occurred (not future dates)
            return targetDate <= today ? targetDate : nil
        } else {
            // Year view - start from January 1st of selected year
            let yearStart = calendar.date(from: DateComponents(year: selectedYear, month: 1, day: 1)) ?? Date()
            let firstWeekday = calendar.component(.weekday, from: yearStart) // 1=Sunday, 2=Monday, ..., 7=Saturday
            
            // Calculate the start of the first week (Sunday before or on Jan 1st)
            // If Jan 1 is Sunday (weekday=1), daysFromSunday=0 (no adjustment needed)
            // If Jan 1 is Monday (weekday=2), daysFromSunday=1 (go back 1 day to Sunday)
            // If Jan 1 is Saturday (weekday=7), daysFromSunday=6 (go back 6 days to Sunday)
            let daysFromSunday = firstWeekday - 1
            let firstWeekStart = calendar.date(byAdding: .day, value: -daysFromSunday, to: yearStart) ?? yearStart
            
            // Calculate the target date by adding week and day offsets
            let dayOffset = week * 7 + day
            let targetDate = calendar.date(byAdding: .day, value: dayOffset, to: firstWeekStart) ?? yearStart
            
            // Only return dates within the selected year
            // This filters out dates from late December of previous year or early January of next year
            let targetYear = calendar.component(.year, from: targetDate)
            return targetYear == selectedYear ? targetDate : nil
        }
    }
    
    // Number of weeks to display
    private var weeksToShow: Int {
        return ContributionGridLayout.weeksToDisplay
    }
    
    /// Get month label for a specific week column
    /// - Parameter week: Week index (0-51)
    /// - Returns: Month abbreviation if this week contains the 1st of a month, nil otherwise
    ///
    /// This ensures month labels appear exactly once at the week containing the month's first day.
    /// Works correctly across year boundaries because getDateForGridPosition handles year transitions.
    private func getMonthLabelForWeek(_ week: Int) -> String? {
        let months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun",
                      "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
        
        // Get the first day of this week (Sunday)
        guard let firstDayOfWeek = getDateForGridPosition(week: week, day: 0) else {
            return nil
        }
        
        // Check if this week contains the first day of any month
        // We check all 7 days in the week to catch the 1st regardless of which day it falls on
        for dayOffset in 0..<7 {
            if let dateInWeek = calendar.date(byAdding: .day, value: dayOffset, to: firstDayOfWeek) {
                let dayInMonth = calendar.component(.day, from: dateInWeek)
                let month = calendar.component(.month, from: dateInWeek)
                
                if dayInMonth == 1 {
                    // This week contains the 1st of a month, show the month label
                    // month is 1-indexed, so subtract 1 for array access
                    return months[month - 1]
                }
            }
        }
        
        return nil
    }
    
    // Day labels for all days of the week
    // Displayed on the left side of the grid, aligned with each row
    private var dayLabels: [String] {
        return ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
    }
    
    // Get the row indices for all days (0-based, where 0=Sunday)
    // This matches the grid coordinate system used in getDateForGridPosition
    // Sunday=0, Monday=1, Tuesday=2, Wednesday=3, Thursday=4, Friday=5, Saturday=6
    private var dayRowIndices: [Int] {
        return [0, 1, 2, 3, 4, 5, 6]
    }
    
    /// Find progress for a specific date
    /// Matches progress to dates based on which question was scheduled for that date,
    /// not when the user actually answered it.
    ///
    /// For example, if Monday's question is answered on Tuesday, it still shows up on Monday's square.
    /// - Parameter date: The date to find progress for
    /// - Returns: UserProgressWithQuestion if the user answered the question scheduled for this date
    private func progressForDate(_ date: Date) -> UserProgressWithQuestion? {
        let dateString = dateFormatter.string(from: date)
        
        // Find which question was scheduled for this date
        guard let challenge = allDailyChallenges.first(where: { $0.challengeDate == dateString }),
              let scheduledQuestionId = challenge.question?.id else {
            return nil
        }
        
        // Find if user has progress for this question (regardless of when they answered it)
        return progressHistory.first { progress in
            progress.questionId == scheduledQuestionId
        }
    }
    
    /// Find question for a specific date
    /// - Parameter date: The date to find the question for
    /// - Returns: The question that was scheduled for this date, or nil if no question exists
    private func questionForDate(_ date: Date) -> Question? {
        let dateString = dateFormatter.string(from: date)
        return allDailyChallenges.first { challenge in
            challenge.challengeDate == dateString
        }?.question
    }
}

// MARK: - Contribution Square
struct ContributionSquare: View {
    let date: Date
    let progress: UserProgressWithQuestion?
    let hasQuestion: Bool
    let onTap: () -> Void
    
    private let calendar = Calendar.current
    
    var body: some View {
        Rectangle()
            .fill(squareColor)
            .frame(width: ContributionGridLayout.squareSize, height: ContributionGridLayout.squareSize)
            .cornerRadius(ContributionGridLayout.cornerRadius)
            .accessibilityIdentifier("ContributionSquare")
            .onTapGesture {
                onTap()
            }
    }
    
    private var squareColor: Color {
        // If answered, show correct/incorrect color
        if let progress = progress, let isCorrect = progress.isCorrect {
            return isCorrect ? Theme.Colors.stateCorrect : Theme.Colors.stateIncorrect
        }
        
        // If unanswered but has question, show gray (unanswered)
        if hasQuestion {
            return .gray.opacity(0.3)
        }
        
        // No question for this date
        return .gray.opacity(0.3)
    }
}

// MARK: - Question Review View
struct QuestionReviewView: View {
    let progress: UserProgressWithQuestion?
    let date: Date
    @Environment(\.dismiss) private var dismiss
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()
    
    private let questionDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        return formatter
    }()
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Date Banner at the top
                    HStack {
                        Image(systemName: "calendar")
                            .foregroundColor(Theme.Colors.accentGreen)
                        Text(questionDateFormatter.string(from: date))
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                    .padding()
                    .background(Theme.Colors.surface)
                    .cornerRadius(8)
                    
                    if let progress = progress, let question = progress.question {
                        // Question Header
                        VStack(alignment: .leading, spacing: 12) {
                            Text(question.title)
                                .font(.title2)
                                .bold()
                            
                            Text(question.content.question)
                                .font(.body)
                                .foregroundColor(.primary)
                            
                            // Question Image
                            if let imageUrl = question.content.imageUrl, !imageUrl.isEmpty {
                                QuestionImageView(
                                    imageUrl: imageUrl,
                                    imageAlt: question.content.imageAlt,
                                    maxHeight: 200
                                )
                            }
                        }
                        
                        // Answer Section
                        if let orderingItems = question.content.orderingItems, !orderingItems.isEmpty {
                            // Ordering Question Answer Display
                            let correctOrderIds = question.content.correctOrderIds ?? []
                            let idToText: [String: String] = orderingItems.reduce(into: [:]) { dict, item in
                                dict[item.id] = item.text
                            }
                            let userOrderIds: [String] = {
                                if let answer = progress.answer,
                                   let text = answer.correctText,
                                   let data = text.data(using: .utf8),
                                   let arr = try? JSONDecoder().decode([String].self, from: data) {
                                    return arr
                                }
                                return []
                            }()
                            let correctPositions = zip(userOrderIds, correctOrderIds).reduce(0) { acc, pair in
                                acc + (pair.0 == pair.1 ? 1 : 0)
                            }
                            
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Your Order")
                                    .font(.headline)
                                
                                Text("\(correctPositions)/\(correctOrderIds.count) in the correct position")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                
                                VStack(alignment: .leading, spacing: 6) {
                                    ForEach(Array(userOrderIds.enumerated()), id: \.offset) { idx, id in
                                        let isCorrect = idx < correctOrderIds.count && correctOrderIds[idx] == id
                                        HStack(spacing: 8) {
                                            Text("\(idx+1).")
                                                .foregroundColor(.secondary)
                                            Text(idToText[id] ?? id)
                                                .bold()
                                            Spacer()
                                            Image(systemName: isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                                                .foregroundColor(isCorrect ? .green : .red)
                                        }
                                        .font(.caption)
                                    }
                                }
                                .padding()
                                .background(Color.gray.opacity(0.08))
                                .cornerRadius(8)
                            }
                        } else if let matchingItems = question.content.matchingItems, !matchingItems.isEmpty {
                            // Matching Question Answer Display
                            let draggableItems = matchingItems.filter { $0.isDraggable }
                            let targetItems = matchingItems.filter { !$0.isDraggable }
                            
                            // Parse user's matches from answer
                            let userMatches: [String: String] = {
                                if let answer = progress.answer,
                                   let correctText = answer.correctText,
                                   let matchesData = correctText.data(using: .utf8),
                                   let parsedMatches = try? JSONDecoder().decode([String: String].self, from: matchesData) {
                                    return parsedMatches
                                }
                                return [:]
                            }()
                            
                            // Calculate correct pairs
                            let correctMatches = question.content.correctMatches ?? []
                            let correctCount = correctMatches.reduce(0) { count, pair in
                                count + ((userMatches[pair.targetId] == pair.sourceId) ? 1 : 0)
                            }
                            
                            // Your Matches
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Your Matches")
                                    .font(.headline)
                                
                                Text("\(correctCount)/\(correctMatches.count) matches correct")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .padding(.bottom, 4)
                                
                                ForEach(targetItems) { target in
                                    if let sourceId = userMatches[target.id],
                                       let source = draggableItems.first(where: { $0.id == sourceId }) {
                                        let isCorrect = correctMatches.first(where: { $0.targetId == target.id && $0.sourceId == sourceId }) != nil
                                        
                                        HStack(alignment: .top, spacing: 8) {
                                            Text("•")
                                            Text("\(source.text)")
                                                .bold()
                                            Text("→")
                                            Text("\(target.text)")
                                            
                                            Spacer()
                                            
                                            Image(systemName: isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                                                .foregroundColor(isCorrect ? .green : .red)
                                        }
                                        .font(.caption)
                                        .padding(.vertical, 4)
                                    }
                                }
                            }
                            .padding()
                            .background(Color.gray.opacity(0.08))
                            .cornerRadius(8)
                            
                            // Correct Matches (only show if not all correct)
                            if correctCount < correctMatches.count {
                                VStack(alignment: .leading, spacing: 12) {
                                    Text("Correct Matches")
                                        .font(.headline)
                                    
                                    ForEach(correctMatches, id: \.sourceId) { pair in
                                        if let source = draggableItems.first(where: { $0.id == pair.sourceId }),
                                           let target = targetItems.first(where: { $0.id == pair.targetId }) {
                                            HStack(alignment: .top, spacing: 8) {
                                                Text("•")
                                                Text("\(source.text)")
                                                    .bold()
                                                Text("→")
                                                Text("\(target.text)")
                                            }
                                            .font(.caption)
                                            .padding(.vertical, 4)
                                        }
                                    }
                                }
                                .padding()
                                .background(Theme.Colors.subtleBlue.opacity(0.05))
                                .cornerRadius(8)
                            }
                        } else {
                            // Multiple Choice Answer Display
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Your Answer")
                                    .font(.headline)
                                
                                if let answer = progress.answer,
                                   let selectedOptionId = answer.correctOptionId,
                                   let options = question.content.options {
                                    
                                    if let selectedOption = options.first(where: { $0.id == selectedOptionId }) {
                                        HStack {
                                            Text(selectedOption.id.uppercased())
                                                .font(.headline)
                                                .foregroundColor(.white)
                                                .frame(width: 30, height: 30)
                                                .background(progress.isCorrect == true ? .green : .red)
                                                .clipShape(Circle())
                                            
                                            Text(selectedOption.text)
                                                .font(.body)
                                            
                                            Spacer()
                                            
                                            Image(systemName: progress.isCorrect == true ? "checkmark.circle.fill" : "xmark.circle.fill")
                                                .foregroundColor(progress.isCorrect == true ? .green : .red)
                                        }
                                        .padding()
                                        .background((progress.isCorrect == true ? Color.green : Color.red).opacity(0.1))
                                        .cornerRadius(12)
                                    }
                                }
                            }
                            
                            // Correct Answer
                            let correctAnswer = question.correctAnswer
                            if let correctOptionId = correctAnswer.correctOptionId,
                               let options = question.content.options {
                                
                                VStack(alignment: .leading, spacing: 12) {
                                    Text("Correct Answer")
                                        .font(.headline)
                                    
                                    if let correctOption = options.first(where: { $0.id == correctOptionId }) {
                                        HStack {
                                            Text(correctOption.id.uppercased())
                                                .font(.headline)
                                                .foregroundColor(.white)
                                                .frame(width: 30, height: 30)
                                                .background(.green)
                                                .clipShape(Circle())
                                            
                                            Text(correctOption.text)
                                                .font(.body)
                                            
                                            Spacer()
                                            
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundColor(.green)
                                        }
                                        .padding()
                                        .background(.green.opacity(0.1))
                                        .cornerRadius(12)
                                    }
                                }
                            }
                        }
                        
                        // Explanation
                        if let explanation = question.explanation {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Explanation")
                                    .font(.headline)
                                
                                Text(explanation)
                                    .font(.body)
                                    .foregroundColor(.secondary)
                                    .padding()
                                    .background(Color.gray.opacity(0.1))
                                    .cornerRadius(8)
                            }
                        }
                        
                        // Resources Link
                        if let resourcesUrl = question.resourcesUrl, !resourcesUrl.isEmpty,
                           let url = URL(string: resourcesUrl) {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Check out more resources:")
                                    .font(.headline)
                                
                                Link(destination: url) {
                                    HStack {
                                        Text(resourcesUrl)
                                            .font(.body)
                                            .foregroundColor(Theme.Colors.accentGreen)
                                            .lineLimit(2)
                                        
                                        Spacer()
                                        
                                        Image(systemName: "arrow.up.right.square")
                                            .foregroundColor(Theme.Colors.accentGreen)
                                    }
                                    .padding()
                                    .background(Color.gray.opacity(0.1))
                                    .cornerRadius(8)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(Theme.Colors.accentGreen.opacity(0.3), lineWidth: 1)
                                    )
                                }
                            }
                        }
                        
                        // Stats
                        if let timeTaken = progress.timeTaken, timeTaken > 0 {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Stats")
                                    .font(.headline)
                                
                                HStack {
                                    Text("Time taken:")
                                        .foregroundColor(.secondary)
                                    Spacer()
                                    Text(formatTime(timeTaken))
                                        .bold()
                                }
                            }
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                        }
                        
                    } else {
                        // No question data - show empty state with date
                        VStack(spacing: 20) {
                            Image(systemName: "calendar.badge.exclamationmark")
                                .font(.system(size: 60))
                                .foregroundColor(.gray)
                            
                            Text("No Question Available")
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            Text("There was no question scheduled for this date.")
                                .font(.body)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                            
                            // Show the date prominently
                            VStack(spacing: 4) {
                                Text("Date")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .textCase(.uppercase)
                                
                                Text(questionDateFormatter.string(from: date))
                                    .font(.headline)
                                    .fontWeight(.semibold)
                            }
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(12)
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                    }
                }
                .padding()
            }
            .navigationTitle("Question Review")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                AnalyticsService.shared.trackScreen("question_review")
            }
        }
    }
    
    private func formatTime(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        return String(format: "%d:%02d", minutes, remainingSeconds)
    }
}

#Preview {
    ContributionsTracker(progressHistory: [], allDailyChallenges: [])
}
