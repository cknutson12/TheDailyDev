import SwiftUI

// MARK: - Contributions Tracker View
struct ContributionsTracker: View {
    let progressHistory: [UserProgressWithQuestion]
    @State private var selectedDate: Date?
    @State private var showingQuestionReview = false
    @State private var selectedProgress: UserProgressWithQuestion?
    @State private var selectedYear: Int
    
    private let calendar = Calendar.current
    private let dateFormatter = DateFormatter()
    
    init(progressHistory: [UserProgressWithQuestion]) {
        self.progressHistory = progressHistory
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
                
                Text("\(filteredProgressHistory.count) answered")
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
                                Text("\(year)")
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
                LegendItem(color: .gray.opacity(0.3), text: "No data")
            }
            .padding(.bottom, 4)
            
            // Contributions Grid
            ContributionsGrid(
                progressHistory: filteredProgressHistory,
                selectedYear: selectedYear,
                onDateSelected: { date, progress in
                    selectedDate = date
                    selectedProgress = progress
                    showingQuestionReview = true
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
    }
    
    // MARK: - Computed Properties
    private var availableYears: [Int] {
        let years = Set<Int>(progressHistory.compactMap { progress in
            guard let date = progress.completedDayLocal else { return nil }
            return calendar.component(.year, from: date)
        })
        return Array(years).sorted(by: >)
    }
    
    private var filteredProgressHistory: [UserProgressWithQuestion] {
        progressHistory.filter { progress in
            guard let date = progress.completedDayLocal else { return false }
            return calendar.component(.year, from: date) == selectedYear
        }
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
                .frame(width: 16, height: 16)
                .cornerRadius(3)
            
            Text(text)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Contributions Grid
struct ContributionsGrid: View {
    let progressHistory: [UserProgressWithQuestion]
    let selectedYear: Int
    let onDateSelected: (Date, UserProgressWithQuestion?) -> Void
    
    private let calendar = Calendar.current
    private let dateFormatter = DateFormatter()
    
    init(progressHistory: [UserProgressWithQuestion], selectedYear: Int, onDateSelected: @escaping (Date, UserProgressWithQuestion?) -> Void) {
        self.progressHistory = progressHistory
        self.selectedYear = selectedYear
        self.onDateSelected = onDateSelected
        self.dateFormatter.dateFormat = "yyyy-MM-dd"
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            // Grid with fixed day labels and synchronized scrolling
            HStack(alignment: .top, spacing: 1) {
                // Day labels - Fixed on left, always visible
                VStack(spacing: 1) {
                    // Empty space to align with month labels
                    Text("")
                        .font(.caption2)
                        .frame(height: 16)
                    
                    // Day labels aligned with contribution squares
                    ForEach(0..<7) { dayIndex in
                        if let labelIndex = dayRowIndices.firstIndex(of: dayIndex) {
                            Text(dayLabels[labelIndex])
                                .font(.caption2)
                                .foregroundColor(.secondary)
                                .frame(height: 16) // Match new square height
                                .frame(maxWidth: .infinity, alignment: .trailing) // Right-align text
                                .minimumScaleFactor(0.7) // Allow text to scale down to 70%
                        } else {
                            // Empty space for other days
                            Text("")
                                .font(.caption2)
                                .frame(height: 16) // Match new square height
                        }
                    }
                }
                .frame(width: 40) // Wider for better text visibility
                
                // Single ScrollView containing both month labels and contribution squares
                ScrollViewReader { proxy in
                    ScrollView(.horizontal, showsIndicators: false) {
                        VStack(alignment: .leading, spacing: 4) {
                        // Month labels positioned based on calendar weeks
                        HStack(spacing: 0) {
                            ForEach(Array(0..<weeksToShow), id: \.self) { week in
                                if let monthLabel = getMonthLabelForWeek(week) {
                                    Text(monthLabel)
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                        .frame(width: 24) // Wider frame for month names
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.5) // Allow text to scale down to 50%
                                } else {
                                    // Empty space for weeks without month labels
                                    Text("")
                                        .frame(width: 16) // Match new square width
                                }
                            }
                        }
                        
                        // Contribution squares
                        VStack(alignment: .leading, spacing: 1) {
                            ForEach(0..<7) { day in
                                HStack(spacing: 1) {
                                    ForEach(Array(0..<weeksToShow), id: \.self) { week in
                                        if let date = getDateForGridPosition(week: week, day: day) {
                                            let progress = progressForDate(date)
                                            
                                            ContributionSquare(
                                                date: date,
                                                progress: progress,
                                                onTap: {
                                                    onDateSelected(date, progress)
                                                }
                                            )
                                            } else {
                                                // Empty space for future dates or dates outside the year
                                                if let date = getDateForGridPosition(week: week, day: day) {
                                                    // Show clickable empty box for past dates with no data
                                                    Rectangle()
                                                        .fill(Color.gray.opacity(0.3))
                                                        .frame(width: 16, height: 16)
                                                        .cornerRadius(3)
                                                        .accessibilityIdentifier("ContributionSquare")
                                                        .onTapGesture {
                                                            onDateSelected(date, nil)
                                                        }
                                                } else {
                                                    // Truly empty space for future dates
                                                    Rectangle()
                                                        .fill(Color.clear)
                                                        .frame(width: 16, height: 16)
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
                    // Scroll to the right (most recent data) when view appears
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        proxy.scrollTo("contributionsGrid", anchor: .trailing)
                    }
                }
                }
            }
        }
    }
    
    // Get date for a specific grid position (week, day)
    private func getDateForGridPosition(week: Int, day: Int) -> Date? {
        if selectedYear == Calendar.current.component(.year, from: Date()) {
            // Rolling 52-week view ending today
            let today = Date()
            
            // Calculate the start of the current week (Sunday)
            let todayWeekday = calendar.component(.weekday, from: today) // 1=Sunday, 2=Monday, etc.
            let daysFromSunday = (todayWeekday == 1) ? 0 : (todayWeekday - 1) // Convert to 0=Sunday, 1=Monday, etc.
            let currentWeekStart = calendar.date(byAdding: .day, value: -daysFromSunday, to: today) ?? today
            
            // Calculate the target week start (going back by week number)
            let weeksBack = 51 - week // week 51 is current week, week 0 is 51 weeks ago
            let targetWeekStart = calendar.date(byAdding: .weekOfYear, value: -weeksBack, to: currentWeekStart) ?? currentWeekStart
            
            // Add the day offset within the week
            let targetDate = calendar.date(byAdding: .day, value: day, to: targetWeekStart) ?? targetWeekStart
            
            // Only return dates that have actually occurred (not future dates)
            return targetDate <= today ? targetDate : nil
        } else {
            // Year view - start from January 1st of selected year
            let yearStart = calendar.date(from: DateComponents(year: selectedYear, month: 1, day: 1)) ?? Date()
            let firstWeekday = calendar.component(.weekday, from: yearStart) // 1=Sunday, 2=Monday, etc.
            
            // Calculate the start of the first week (Sunday before or on Jan 1st)
            let daysToFirstSunday = (firstWeekday == 1) ? 0 : (8 - firstWeekday) % 7
            let firstWeekStart = calendar.date(byAdding: .day, value: -daysToFirstSunday, to: yearStart) ?? yearStart
            
            let dayOffset = week * 7 + day
            let targetDate = calendar.date(byAdding: .day, value: dayOffset, to: firstWeekStart) ?? yearStart
            
            // Only return dates within the selected year
            let targetYear = calendar.component(.year, from: targetDate)
            return targetYear == selectedYear ? targetDate : nil
        }
    }
    
    // Number of weeks to display
    private var weeksToShow: Int {
        return 52 // Always show 52 weeks
    }
    
    // Get month label for a specific week based on calendar logic
    private func getMonthLabelForWeek(_ week: Int) -> String? {
        let months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun",
                      "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
        
        // Get the first day of this week (Sunday)
        guard let firstDayOfWeek = getDateForGridPosition(week: week, day: 0) else {
            return nil
        }
        
        // Check if this week contains the first day of any month
        for dayOffset in 0..<7 {
            if let dateInWeek = calendar.date(byAdding: .day, value: dayOffset, to: firstDayOfWeek) {
                let dayInMonth = calendar.component(.day, from: dateInWeek)
                let month = calendar.component(.month, from: dateInWeek)
                
                if dayInMonth == 1 {
                    // This week contains the 1st of a month, show the month label
                    return months[month - 1]
                }
            }
        }
        
        return nil
    }
    
    // Day labels for Mon, Wed, Fri only
    private var dayLabels: [String] {
        return ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
    }
    
    // Get the row indices for all days (0-based, where 0=Sunday)
    private var dayRowIndices: [Int] {
        return [0, 1, 2, 3, 4, 5, 6] // All days: Sun=0, Mon=1, Tue=2, Wed=3, Thu=4, Fri=5, Sat=6
    }
    
    // Find progress for a specific date
    private func progressForDate(_ date: Date) -> UserProgressWithQuestion? {
        progressHistory.first { progress in
            guard let progressDate = progress.completedDayLocal else { return false }
            return calendar.isDate(progressDate, inSameDayAs: date)
        }
    }
}

// MARK: - Contribution Square
struct ContributionSquare: View {
    let date: Date
    let progress: UserProgressWithQuestion?
    let onTap: () -> Void
    
    private let calendar = Calendar.current
    
    var body: some View {
        Rectangle()
            .fill(squareColor)
            .frame(width: 16, height: 16)
            .cornerRadius(3)
            .accessibilityIdentifier("ContributionSquare")
            .onTapGesture {
                onTap()
            }
    }
    
    private var squareColor: Color {
        guard let progress = progress else {
            return .gray.opacity(0.3)
        }
        
        if let isCorrect = progress.isCorrect {
            return isCorrect ? Theme.Colors.stateCorrect : Theme.Colors.stateIncorrect
        }
        
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
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
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
                        
                        // Stats
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Stats")
                                .font(.headline)
                            
                            HStack {
                                Text("Time taken:")
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text(formatTime(progress.timeTaken ?? 0))
                                    .bold()
                            }
                            
                            HStack {
                                Text("Completed:")
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text(formatDate(from: progress))
                                    .bold()
                            }
                        }
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                        
                    } else {
                        // No question data - just show the date
                        VStack(spacing: 20) {
                            Image(systemName: "calendar")
                                .font(.system(size: 60))
                                .foregroundColor(.gray)
                            
                            Text("No Question Available")
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            Text("There was no question available for this date.")
                                .font(.body)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Date")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                Text(dateFormatter.string(from: date))
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                            }
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(12)
                        }
                        .padding()
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
        }
    }
    
    private func formatTime(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        return String(format: "%d:%02d", minutes, remainingSeconds)
    }
    
    private func formatDate(from progress: UserProgressWithQuestion) -> String {
        if let date = progress.completedDate {
            return dateFormatter.string(from: date)
        }
        return progress.completedAt
    }
}

#Preview {
    ContributionsTracker(progressHistory: [])
}
