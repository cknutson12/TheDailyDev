//
//  CategoryPerformanceView.swift
//  TheDailyDev
//
//  Created by Claire Knutson on 10/25/25.
//

import SwiftUI

struct CategoryPerformanceView: View {
    let categoryPerformances: [CategoryPerformance]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Text("Category Performance")
                    .font(.title3)
                    .bold()
                
                Spacer()
                
                Text("\(categoryPerformances.count) categories")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            if categoryPerformances.isEmpty {
                // Empty state
                VStack(spacing: 12) {
                    Image(systemName: "chart.bar.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.gray)
                    
                    Text("No Category Data")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    Text("Complete more questions to see your category performance")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            } else {
                // Performance list
                VStack(spacing: 12) {
                    ForEach(Array(categoryPerformances.enumerated()), id: \.element.id) { index, performance in
                        CategoryPerformanceRow(
                            performance: performance,
                            rank: index + 1,
                            isTopThree: index < 3
                        )
                    }
                }
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
    }
}

struct CategoryPerformanceRow: View {
    let performance: CategoryPerformance
    let rank: Int
    let isTopThree: Bool
    
    private var rankColor: Color {
        switch rank {
        case 1: return .yellow
        case 2: return .gray
        case 3: return .orange
        default: return .blue
        }
    }
    
    private var rankIcon: String {
        switch rank {
        case 1: return "crown.fill"
        case 2: return "2.circle.fill"
        case 3: return "3.circle.fill"
        default: return "\(rank).circle.fill"
        }
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Rank indicator
            ZStack {
                Circle()
                    .fill(rankColor.opacity(0.2))
                    .frame(width: 40, height: 40)
                
                Image(systemName: rankIcon)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(rankColor)
            }
            
            // Category info
            VStack(alignment: .leading, spacing: 4) {
                Text(performance.category)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text("\(performance.correctAnswers)/\(performance.totalAnswers) correct")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Percentage and progress bar
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(Int(performance.percentage))%")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(percentageColor)
                
                // Progress bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 6)
                            .cornerRadius(3)
                        
                        Rectangle()
                            .fill(percentageColor)
                            .frame(width: geometry.size.width * (performance.percentage / 100), height: 6)
                            .cornerRadius(3)
                    }
                }
                .frame(width: 60, height: 6)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color(UIColor.systemBackground))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isTopThree ? rankColor.opacity(0.3) : Color.clear, lineWidth: 1)
        )
    }
    
    private var percentageColor: Color {
        switch performance.percentage {
        case 80...100: return .green
        case 60..<80: return .blue
        case 40..<60: return .orange
        default: return .red
        }
    }
}

struct CategoryPerformanceView_Previews: PreviewProvider {
    static var previews: some View {
        let sampleData = [
            CategoryPerformance(category: "System Design", correctAnswers: 8, totalAnswers: 10, percentage: 80.0),
            CategoryPerformance(category: "Algorithms", correctAnswers: 6, totalAnswers: 8, percentage: 75.0),
            CategoryPerformance(category: "Database Design", correctAnswers: 4, totalAnswers: 6, percentage: 66.7),
            CategoryPerformance(category: "Networking", correctAnswers: 3, totalAnswers: 5, percentage: 60.0),
            CategoryPerformance(category: "Security", correctAnswers: 2, totalAnswers: 4, percentage: 50.0)
        ]
        
        CategoryPerformanceView(categoryPerformances: sampleData)
            .padding()
    }
}
