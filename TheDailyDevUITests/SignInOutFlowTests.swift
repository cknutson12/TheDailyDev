//
//  SignInOutFlowTests.swift
//  TheDailyDevUITests
//
//  Created by Claire Knutson on 10/28/25.
//

import XCTest

final class SignInOutFlowTests: XCTestCase {
    
    private let testEmail = "test@example.com"
    private let testPassword = "testpassword123"

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    override func tearDownWithError() throws {
        // Clean up if needed
    }
    
    func testSignInSignOutSignInFlow() throws {
        let app = XCUIApplication()
        app.launch()
        
        // Wait for app to load
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 10))
        
        // MARK: - First Sign In
        print("📱 First Sign In")
        
        // Enter credentials
        let emailField = app.textFields["EmailField"]
        let passwordField = app.secureTextFields["PasswordField"]
        
        XCTAssertTrue(emailField.waitForExistence(timeout: 5), "Email field should exist")
        XCTAssertTrue(passwordField.waitForExistence(timeout: 5), "Password field should exist")
        
        emailField.tap()
        emailField.typeText(testEmail)
        
        passwordField.tap()
        passwordField.typeText(testPassword)
        
        // Sign in
        let signInButton = app.buttons["SignInButton"]
        XCTAssertTrue(signInButton.exists, "Sign in button should exist")
        signInButton.tap()
        
        // Wait for navigation to HomeView
        let profileButton = app.buttons["ProfileButton"]
        XCTAssertTrue(profileButton.waitForExistence(timeout: 10), "Profile button should appear after sign in")
        
        print("✅ First sign in successful")
        
        // MARK: - Sign Out
        print("📱 Signing Out")
        
        // Tap profile button to go to ProfileView
        profileButton.tap()
        
        // Wait for ProfileView to load
        let settingsButton = app.buttons["SettingsButton"]
        XCTAssertTrue(settingsButton.waitForExistence(timeout: 5), "Settings button should exist in ProfileView")
        
        // Tap settings button to open SubscriptionSettingsView
        settingsButton.tap()
        
        // Wait for Settings view to load
        let signOutButton = app.buttons["SignOutButton"]
        XCTAssertTrue(signOutButton.waitForExistence(timeout: 5), "Sign out button should exist")
        
        // Tap sign out button (should show confirmation)
        signOutButton.tap()
        
        // Wait for confirmation alert
        let confirmButton = app.alerts["Sign Out"].buttons["ConfirmSignOutButton"]
        XCTAssertTrue(confirmButton.waitForExistence(timeout: 3), "Confirm sign out button should appear")
        
        // Confirm sign out
        confirmButton.tap()
        
        // Wait to be redirected to login screen
        let loginEmailField = app.textFields["EmailField"]
        XCTAssertTrue(loginEmailField.waitForExistence(timeout: 5), "Should be back on login screen")
        
        print("✅ Sign out successful")
        
        // MARK: - Second Sign In
        print("📱 Second Sign In")
        
        // Enter credentials again
        loginEmailField.tap()
        loginEmailField.typeText(testEmail)
        
        let loginPasswordField = app.secureTextFields["PasswordField"]
        loginPasswordField.tap()
        loginPasswordField.typeText(testPassword)
        
        // Sign in again
        let signInButton2 = app.buttons["SignInButton"]
        XCTAssertTrue(signInButton2.exists, "Sign in button should exist")
        signInButton2.tap()
        
        // Wait for navigation to HomeView
        let profileButton2 = app.buttons["ProfileButton"]
        XCTAssertTrue(profileButton2.waitForExistence(timeout: 10), "Profile button should appear after second sign in")
        
        print("✅ Second sign in successful")
    }
    
    func testSignOutConfirmationCancelled() throws {
        let app = XCUIApplication()
        app.launch()
        
        // Wait for app to load
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 10))
        
        // Sign in first
        let emailField = app.textFields["EmailField"]
        let passwordField = app.secureTextFields["PasswordField"]
        
        XCTAssertTrue(emailField.waitForExistence(timeout: 5))
        emailField.tap()
        emailField.typeText(testEmail)
        
        passwordField.tap()
        passwordField.typeText(testPassword)
        
        app.buttons["SignInButton"].tap()
        
        // Wait for home screen
        let profileButton = app.buttons["ProfileButton"]
        XCTAssertTrue(profileButton.waitForExistence(timeout: 10))
        
        // Try to sign out
        profileButton.tap()
        
        let settingsButton = app.buttons["SettingsButton"]
        XCTAssertTrue(settingsButton.waitForExistence(timeout: 5))
        settingsButton.tap()
        
        let signOutButton = app.buttons["SignOutButton"]
        XCTAssertTrue(signOutButton.waitForExistence(timeout: 5))
        signOutButton.tap()
        
        // Cancel sign out
        let cancelButton = app.alerts["Sign Out"].buttons["CancelSignOutButton"]
        XCTAssertTrue(cancelButton.waitForExistence(timeout: 3))
        cancelButton.tap()
        
        // Should still be in settings
        XCTAssertTrue(app.staticTexts["Subscription"].exists, "Should still be in settings after cancelling sign out")
    }
}

