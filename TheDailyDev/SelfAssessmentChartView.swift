import SwiftUI

struct SelfAssessmentTrendPoint: Identifiable {
    let id = UUID()
    let assessmentId: UUID
    let date: Date
    let rating: Double
}

struct SkillSeries: Identifiable {
    let id = UUID()
    let key: String
    let label: String
    let color: Color
    let points: [SelfAssessmentTrendPoint]
}

struct SelfAssessmentChartView: View {
    let assessments: [SelfAssessmentRecord]
    let isLoading: Bool
    let isDue: Bool
    let onTakeAssessment: () -> Void
    
    private let skillOrder: [(key: String, label: String, color: Color)] = [
        ("infrastructure", "Infrastructure", Color(red: 0.95, green: 0.55, blue: 0.15)),
        ("data", "Data", Color(red: 0.30, green: 0.65, blue: 0.95)),
        ("api_design", "API Design", Color(red: 0.85, green: 0.30, blue: 0.75)),
        ("theory", "Theory", Color(red: 0.25, green: 0.85, blue: 0.55)),
        ("product", "Product", Color(red: 0.90, green: 0.25, blue: 0.35))
    ]
    
    private var skillSeries: [SkillSeries] {
        skillOrder.compactMap { entry in
            let points: [SelfAssessmentTrendPoint] = assessments.compactMap { record in
                guard let date = DateUtils.parseISODate(record.assessmentDate) else { return nil }
                guard let rating = record.ratings[entry.key] else { return nil }
                return SelfAssessmentTrendPoint(assessmentId: record.id, date: date, rating: Double(rating))
            }.sorted { $0.date < $1.date }
            
            guard !points.isEmpty else { return nil }
            return SkillSeries(
                key: entry.key,
                label: entry.label,
                color: entry.color,
                points: points
            )
        }
    }
    
    private var originDate: Date? {
        let dates = skillSeries.flatMap { $0.points.map { $0.date } }.sorted()
        return dates.first
    }
    
    private var orderedAssessments: [(id: UUID, date: Date)] {
        assessments.compactMap { record in
            guard let date = DateUtils.parseISODate(record.assessmentDate) else { return nil }
            return (id: record.id, date: date)
        }.sorted { $0.date < $1.date }
    }
    
    private var placeholderAssessment: (id: UUID, date: Date) {
        (UUID(), Date())
    }
    
    private var displaySeries: [SkillSeries] {
        if !skillSeries.isEmpty {
            return skillSeries
        }
        
        let placeholder = placeholderAssessment
        return skillOrder.map { entry in
            let point = SelfAssessmentTrendPoint(
                assessmentId: placeholder.id,
                date: placeholder.date,
                rating: 3.0
            )
            return SkillSeries(
                key: entry.key,
                label: entry.label,
                color: entry.color.opacity(0.5),
                points: [point]
            )
        }
    }
    
    private var displayAssessments: [(id: UUID, date: Date)] {
        if !orderedAssessments.isEmpty {
            return orderedAssessments
        }
        return [placeholderAssessment]
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Self-Ratings")
                .font(.title3)
                .bold()
                .foregroundColor(.white)
            
            if isLoading {
                ProgressView("Loading self-assessments...")
                    .frame(maxWidth: .infinity, minHeight: 120)
            } else {
                MultiLineChartView(
                    series: displaySeries,
                    originDate: originDate ?? placeholderAssessment.date,
                    orderedAssessments: displayAssessments
                )
                .frame(height: 200)
                
                if skillSeries.isEmpty {
                    Text("Complete your first self-assessment to see your real data here.")
                        .font(.subheadline)
                        .foregroundColor(Color.theme.textSecondary)
                        .multilineTextAlignment(.leading)
                }
            }
            
            if isDue {
                Button(action: onTakeAssessment) {
                    Text("Take Monthly Self-Assessment")
                        .bold()
                }
                .buttonStyle(PrimaryButtonStyle())
                .padding(.top, 4)
            }
            
            if !displaySeries.isEmpty {
                let leftColumn = Array(displaySeries.prefix(3))
                let rightColumn = Array(displaySeries.dropFirst(3))
                
                HStack(alignment: .top, spacing: 24) {
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(leftColumn) { line in
                            legendRow(line)
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(rightColumn) { line in
                            legendRow(line)
                        }
                    }
                    
                    Spacer(minLength: 0)
                }
                .padding(.top, 4)
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
    }
    
    private func legendRow(_ line: SkillSeries) -> some View {
        HStack(spacing: 6) {
            Circle()
                .fill(line.color)
                .frame(width: 6, height: 6)
            Text(line.label)
                .font(.caption2)
                .foregroundColor(Color.theme.textSecondary)
        }
    }
}

struct MultiLineChartView: View {
    let series: [SkillSeries]
    let originDate: Date?
    let orderedAssessments: [(id: UUID, date: Date)]
    
    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let height = geometry.size.height
            let maxRating = 5.0
            let minRating = 1.0
            let leftPadding: CGFloat = 34
            let rightPadding: CGFloat = 12
            let topPadding: CGFloat = 20
            let bottomPadding: CGFloat = 34
            let plotWidth = max(1, width - leftPadding - rightPadding)
            let plotHeight = max(1, height - topPadding - bottomPadding)
            
            let allPoints = series.flatMap { $0.points }
            let origin = originDate ?? allPoints.map(\.date).sorted().first ?? Date()
            let maxDays = max(0, allPoints.map { daysSinceOrigin($0.date, origin: origin) }.max() ?? 0)
            let count = max(1, orderedAssessments.count)
            let indexMap = Dictionary(uniqueKeysWithValues: orderedAssessments.enumerated().map { ($0.element.id, $0.offset) })
            let maxIndex = max(1, count - 1)
            
            ZStack {
                Path { path in
                    path.move(to: CGPoint(x: leftPadding, y: topPadding))
                    path.addLine(to: CGPoint(x: leftPadding, y: height - bottomPadding))
                    path.addLine(to: CGPoint(x: width - rightPadding, y: height - bottomPadding))
                }
                .stroke(Color.theme.textSecondary.opacity(0.6), lineWidth: 1)
                
                Text("Rating")
                    .font(.caption2)
                    .foregroundColor(Color.theme.textSecondary)
                    .position(x: leftPadding - 22, y: topPadding + 6)
                
                ForEach(series) { line in
                    let points = line.points
                    if points.count > 1 {
                        Path { path in
                            for (index, point) in points.enumerated() {
                                let x = leftPadding + (normalizedX(for: point, origin: origin, maxDays: maxDays, indexMap: indexMap, maxIndex: maxIndex) * plotWidth)
                                let yRatio = (point.rating - minRating) / (maxRating - minRating)
                                let y = (height - bottomPadding) - (CGFloat(yRatio) * plotHeight)
                                
                                if index == 0 {
                                    path.move(to: CGPoint(x: x, y: y))
                                } else {
                                    path.addLine(to: CGPoint(x: x, y: y))
                                }
                            }
                        }
                        .stroke(line.color, lineWidth: 2)
                    }
                    
                    ForEach(points) { point in
                        let x = leftPadding + (normalizedX(for: point, origin: origin, maxDays: maxDays, indexMap: indexMap, maxIndex: maxIndex) * plotWidth)
                        let yRatio = (point.rating - minRating) / (maxRating - minRating)
                        let y = (height - bottomPadding) - (CGFloat(yRatio) * plotHeight)
                        
                        Circle()
                            .fill(line.color)
                            .frame(width: 6, height: 6)
                            .position(x: x, y: y)
                    }
                }
                
                if let labels = axisLabels(
                    origin: origin,
                    orderedAssessments: orderedAssessments,
                    leftPadding: leftPadding,
                    plotWidth: plotWidth,
                    maxDays: maxDays,
                    indexMap: indexMap,
                    maxIndex: maxIndex
                ), !labels.isEmpty {
                    ForEach(labels, id: \.x) { label in
                        Text(label.text)
                            .font(.caption2)
                            .foregroundColor(Color.theme.textSecondary)
                            .position(x: label.x, y: height - bottomPadding + 18)
                    }
                }
            }
        }
    }
    
    private func daysSinceOrigin(_ date: Date, origin: Date) -> CGFloat {
        let days = Calendar.current.dateComponents([.day], from: origin, to: date).day ?? 0
        return CGFloat(max(0, days))
    }
    
    private func normalizedX(
        for point: SelfAssessmentTrendPoint,
        origin: Date,
        maxDays: CGFloat,
        indexMap: [UUID: Int],
        maxIndex: Int
    ) -> CGFloat {
        let timeX: CGFloat
        if maxDays > 0 {
            timeX = daysSinceOrigin(point.date, origin: origin) / maxDays
        } else {
            timeX = 0
        }
        let indexX = CGFloat(indexMap[point.assessmentId] ?? 0) / CGFloat(maxIndex)
        return max(timeX, indexX)
    }
    
    private func axisLabels(
        origin: Date,
        orderedAssessments: [(id: UUID, date: Date)],
        leftPadding: CGFloat,
        plotWidth: CGFloat,
        maxDays: CGFloat,
        indexMap: [UUID: Int],
        maxIndex: Int
    ) -> [(x: CGFloat, text: String)]? {
        guard !orderedAssessments.isEmpty else { return nil }
        
        let indices: [Int]
        if orderedAssessments.count >= 3 {
            indices = [0, orderedAssessments.count / 2, orderedAssessments.count - 1]
        } else {
            indices = Array(0..<orderedAssessments.count)
        }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd/yy"
        
        return indices.map { idx in
            let record = orderedAssessments[idx]
            let point = SelfAssessmentTrendPoint(assessmentId: record.id, date: record.date, rating: 0)
            let normalized = normalizedX(for: point, origin: origin, maxDays: maxDays, indexMap: indexMap, maxIndex: maxIndex)
            let x = leftPadding + (normalized * plotWidth)
            return (x: x, text: formatter.string(from: record.date))
        }
    }
}
