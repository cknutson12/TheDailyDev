//
//  OnboardingTourManager.swift
//  TheDailyDev
//
//  Manages onboarding tour state and completion tracking
//

import Foundation
import SwiftUI

/// Manages the onboarding tour state and completion
class OnboardingTourManager: ObservableObject {
    static let shared = OnboardingTourManager()
    
    @Published var isTourActive: Bool = false
    @Published var currentStepIndex: Int = 0
    @Published var shouldNavigateToProfile: Bool = false
    
    /// Get the identifier of the currently highlighted element
    var currentHighlightIdentifier: String? {
        guard let step = currentStep else { return nil }
        return step.targetViewIdentifier
    }
    
    /// Check if a specific identifier should be highlighted
    func shouldHighlight(identifier: String) -> Bool {
        return currentHighlightIdentifier == identifier
    }
    
    private let hasCompletedTourKey = "hasCompletedOnboardingTour"
    
    private init() {
        // Check if tour should be active on initialization
        if !hasCompletedTour() {
            // Don't auto-start, wait for explicit trigger
            isTourActive = false
        }
    }
    
    // MARK: - Tour Control
    
    /// Start the onboarding tour
    /// This should ONLY be called during onboarding (after sign-up/email verification)
    /// The tour should NOT start automatically when returning to HomeView
    func startTour() {
        // Check if already active
        if isTourActive {
            DebugLogger.log("⚠️ Tour already active, not starting again")
            return
        }
        
        // Check if already completed - DO NOT reset, just return
        if hasCompletedTour() {
            DebugLogger.log("⚠️ Tour already completed - not starting again")
            DebugLogger.log("   Tour should only run once during onboarding")
            return
        }
        
        // Start the tour for new accounts (only during onboarding)
        currentStepIndex = 0
        isTourActive = true
        shouldNavigateToProfile = false
        
        // Track tour started
        AnalyticsService.shared.track("onboarding_tour_started")
        
        DebugLogger.log("✅ Onboarding tour started - Step \(currentStepIndex + 1) of \(TourStep.allSteps.count)")
        DebugLogger.log("   Tour active: \(isTourActive)")
        DebugLogger.log("   Current step: \(TourStep.allSteps[currentStepIndex].id)")
        
        // Force UI update on main thread
        DispatchQueue.main.async {
            self.objectWillChange.send()
        }
    }
    
    /// Move to the next step
    func nextStep() {
        guard isTourActive else { return }
        
        let currentStep = TourStep.allSteps[currentStepIndex]
        
        // Track step completion
        AnalyticsService.shared.track("onboarding_tour_step_completed", properties: [
            "step_number": currentStepIndex + 1,
            "step_name": currentStep.id
        ])
        
        // Move to next step
        if currentStepIndex < TourStep.allSteps.count - 1 {
            let newStepIndex = currentStepIndex + 1
            let newStep = TourStep.allSteps[newStepIndex]
            
            // Check if the new step requires navigation
            if newStep.requiresNavigation {
                // Set flag to trigger navigation
                shouldNavigateToProfile = true
                DebugLogger.log("📍 Next step requires navigation to ProfileView: \(newStep.id)")
                
                // Post notification to trigger navigation
                NotificationCenter.default.post(name: NSNotification.Name("TourNavigateToProfile"), object: nil)
                
                // Update step index after a small delay to allow navigation to complete
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    self.currentStepIndex = newStepIndex
                    // Track new step viewed
                    AnalyticsService.shared.track("onboarding_tour_step_viewed", properties: [
                        "step_number": newStepIndex + 1,
                        "step_name": newStep.id
                    ])
                    self.objectWillChange.send()
                }
            } else {
                // No navigation needed - update immediately
                currentStepIndex = newStepIndex
                shouldNavigateToProfile = false
                
                // Track new step viewed
                AnalyticsService.shared.track("onboarding_tour_step_viewed", properties: [
                    "step_number": newStepIndex + 1,
                    "step_name": newStep.id
                ])
                
                // Force UI update on main thread
                DispatchQueue.main.async {
                    self.objectWillChange.send()
                }
            }
        } else {
            // Tour completed
            completeTour()
        }
    }
    
    /// Skip the tour
    func skipTour() {
        guard isTourActive else { return }
        
        let currentStep = TourStep.allSteps[currentStepIndex]
        
        // Track skip event
        AnalyticsService.shared.track("onboarding_tour_skipped", properties: [
            "step_number": currentStepIndex + 1,
            "step_name": currentStep.id
        ])
        
        completeTour()
    }
    
    /// Complete the tour
    func completeTour() {
        DebugLogger.log("✅ Completing onboarding tour...")
        
        isTourActive = false
        currentStepIndex = 0
        shouldNavigateToProfile = false
        
        // Mark as completed
        UserDefaults.standard.set(true, forKey: hasCompletedTourKey)
        
        // Track completion
        AnalyticsService.shared.track("onboarding_tour_completed", properties: [
            "total_steps": TourStep.allSteps.count
        ])
        
        DebugLogger.log("✅ Onboarding tour completed - isTourActive set to false")
        
        // Force UI update on main thread to ensure overlay is removed
        DispatchQueue.main.async {
            self.objectWillChange.send()
        }
    }
    
    // MARK: - State Queries
    
    /// Get the current tour step
    var currentStep: TourStep? {
        guard isTourActive, currentStepIndex < TourStep.allSteps.count else {
            return nil
        }
        return TourStep.allSteps[currentStepIndex]
    }
    
    /// Check if tour has been completed
    func hasCompletedTour() -> Bool {
        let completed = UserDefaults.standard.bool(forKey: hasCompletedTourKey)
        DebugLogger.log("🔍 Tour completion check: \(completed) (key: \(hasCompletedTourKey))")
        return completed
    }
    
    /// Reset tour completion (for testing)
    func resetTour() {
        UserDefaults.standard.removeObject(forKey: hasCompletedTourKey)
        isTourActive = false
        currentStepIndex = 0
        shouldNavigateToProfile = false
        DebugLogger.log("🔄 Tour reset for testing")
    }
    
    /// Check if tour should be shown (not completed and not currently active)
    func shouldShowTour() -> Bool {
        return !hasCompletedTour() && !isTourActive
    }
}

