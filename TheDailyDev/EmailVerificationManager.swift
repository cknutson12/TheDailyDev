import Foundation
import SwiftUI

/// Manages email verification state and onboarding flow after verification
class EmailVerificationManager: ObservableObject {
    static let shared = EmailVerificationManager()
    
    @Published var showingOnboarding = false
    @Published var shouldShowOnboardingAfterVerification = false
    
    // Store names from sign-up to use after email verification
    var pendingFirstName: String?
    var pendingLastName: String?
    
    private init() {}
    
    func markShouldShowOnboarding() {
        shouldShowOnboardingAfterVerification = true
    }
    
    func showOnboarding() {
        showingOnboarding = true
        shouldShowOnboardingAfterVerification = false
    }
    
    func dismiss() {
        showingOnboarding = false
        shouldShowOnboardingAfterVerification = false
    }
    
    func setPendingNames(firstName: String?, lastName: String?) {
        self.pendingFirstName = firstName
        self.pendingLastName = lastName
    }
    
    func clearPendingNames() {
        self.pendingFirstName = nil
        self.pendingLastName = nil
    }
}

