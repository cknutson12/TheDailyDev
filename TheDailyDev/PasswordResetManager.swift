import Foundation
import SwiftUI

/// Manages password reset state and validation
class PasswordResetManager: ObservableObject {
    static let shared = PasswordResetManager()
    
    @Published var showingResetView = false
    @Published var resetCode: String?
    @Published var errorMessage: String?
    @Published var showingError = false
    
    private init() {}
    
    func setResetCode(_ code: String) {
        resetCode = code
        errorMessage = nil
        showingError = false
        showingResetView = true
    }
    
    func setError(_ error: Error) {
        errorMessage = getErrorMessage(for: error)
        showingError = true
        showingResetView = false
        resetCode = nil
    }
    
    func dismiss() {
        showingResetView = false
        resetCode = nil
        errorMessage = nil
        showingError = false
    }
    
    private func getErrorMessage(for error: Error) -> String {
        let errorString = error.localizedDescription.lowercased()
        
        if errorString.contains("expired") || errorString.contains("expire") {
            return "This password reset link has expired. Please request a new one."
        } else if errorString.contains("invalid") || errorString.contains("token") {
            return "This password reset link is invalid or has already been used. Please request a new one."
        } else if errorString.contains("network") || errorString.contains("connection") {
            return "Unable to verify the reset link. Please check your internet connection and try again."
        } else {
            return "Unable to process the password reset link. Please request a new one."
        }
    }
}

