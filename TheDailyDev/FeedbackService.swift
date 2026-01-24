//
//  FeedbackService.swift
//  TheDailyDev
//
//  Created by AI Assistant
//

import Foundation
import Supabase

enum FeedbackCategory: String, CaseIterable, Codable {
    case bugReport = "Bug Report"
    case featureRequest = "Feature Request"
    case improvement = "Improvement"
    case question = "Question"
    case other = "Other"
    
    var icon: String {
        switch self {
        case .bugReport: return "ladybug.fill"
        case .featureRequest: return "lightbulb.fill"
        case .improvement: return "arrow.up.circle.fill"
        case .question: return "questionmark.circle.fill"
        case .other: return "ellipsis.circle.fill"
        }
    }
}

struct Feedback: Codable {
    let id: UUID
    let userId: UUID
    let category: String
    let message: String
    let userEmail: String?
    let createdAt: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case category
        case message
        case userEmail = "user_email"
        case createdAt = "created_at"
    }
}

struct FeedbackInsert: Codable {
    let userId: String
    let category: String
    let message: String
    let userEmail: String
    
    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case category
        case message
        case userEmail = "user_email"
    }
}

class FeedbackService {
    static let shared = FeedbackService()
    
    private init() {}
    
    enum FeedbackError: Error {
        case emptyMessage
        case messageTooLong
        case submissionFailed
        case authenticationFailed
    }
    
    // MARK: - Submit Feedback
    func submitFeedback(category: FeedbackCategory, message: String) async throws {
        // Validate message
        guard !message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw FeedbackError.emptyMessage
        }
        
        guard message.count <= 2000 else {
            throw FeedbackError.messageTooLong
        }
        
        do {
            // Get current user
            let session = try await SupabaseManager.shared.client.auth.session
            let userId = session.user.id
            let userEmail = session.user.email
            
            // Create feedback record
            let feedbackData = FeedbackInsert(
                userId: userId.uuidString,
                category: category.rawValue,
                message: message.trimmingCharacters(in: .whitespacesAndNewlines),
                userEmail: userEmail ?? ""
            )
            
            // Insert using Supabase client (automatically protects against SQL injection)
            try await SupabaseManager.shared.client
                .from("feedback")
                .insert(feedbackData)
                .execute()
            
            DebugLogger.log("✅ Feedback submitted successfully")
            
        } catch let error as FeedbackError {
            throw error
        } catch {
            DebugLogger.error("Failed to submit feedback: \(error)")
            throw FeedbackError.submissionFailed
        }
    }
    
}

