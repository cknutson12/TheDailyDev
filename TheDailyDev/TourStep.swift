//
//  TourStep.swift
//  TheDailyDev
//
//  Tour step data model for onboarding tour
//

import SwiftUI

/// Represents a single step in the onboarding tour
struct TourStep: Identifiable {
    let id: String
    let title: String
    let message: String
    let targetViewIdentifier: String
    let arrowDirection: ArrowDirection
    let requiresNavigation: Bool // Whether this step requires navigating to a different view
    
    enum ArrowDirection {
        case top
        case bottom
        case left
        case right
        case topLeft
        case topRight
        case bottomLeft
        case bottomRight
    }
}

/// Predefined tour steps
extension TourStep {
    static let allSteps: [TourStep] = [
        // Step 1: Daily Questions Button
        TourStep(
            id: "daily_questions",
            title: "Daily Question",
            message: "Each day, a new question appears here on your home screen. This is where you'll come back daily to take on the next challenge.",
            targetViewIdentifier: "DailyQuestionButton",
            arrowDirection: .top,
            requiresNavigation: false
        ),
        
        // Step 2: Settings Button
        TourStep(
            id: "settings_access",
            title: "Settings",
            message: "Manage your subscription, review our privacy policy, and customize your app preferences from here.",
            targetViewIdentifier: "SettingsButton",
            arrowDirection: .bottomLeft,
            requiresNavigation: false
        ),
        
        // Step 3: Analytics/History Button
        TourStep(
            id: "analytics_access",
            title: "Analytics & History",
            message: "Access your question history and review how you've done over time.",
            targetViewIdentifier: "AnalyticsButton",
            arrowDirection: .bottomRight,
            requiresNavigation: false
        ),
        
        // Step 4: Question History Grid
        TourStep(
            id: "question_history",
            title: "Question History",
            message: "Browse all past questions here. Tap any square to review questions you've already answered or complete ones you missed. Once a question is answered, it can't be answered again.",
            targetViewIdentifier: "QuestionHistoryGrid",
            arrowDirection: .top,
            requiresNavigation: true
        ),
        
        // Step 5: Progress Over Time
        TourStep(
            id: "progress_over_time",
            title: "Progress Over Time",
            message: "Track how your self-ratings trend across skills. We'll check in monthly to see how you're feeling so your growth shows up here.",
            targetViewIdentifier: "SelfAssessmentChart",
            arrowDirection: .top,
            requiresNavigation: true
        )
    ]
}

