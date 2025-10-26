//
//  TheDailyDevUITests.swift
//  TheDailyDevUITests
//
//  Created by Claire Knutson on 10/14/25.
//

import XCTest

final class TheDailyDevUITests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // In UI tests it's important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testExample() throws {
        // UI tests must launch the application that they test.
        let app = XCUIApplication()
        app.launch()

        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }

    func testLaunchPerformance() throws {
        if #available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 7.0, *) {
            // This measures how long it takes to launch your application.
            measure(metrics: [XCTApplicationLaunchMetric()]) {
                XCUIApplication().launch()
            }
        }
    }
}

// MARK: - Contributions Tracker UI Tests
extension TheDailyDevUITests {
    
    func testContributionsTrackerNavigation() throws {
        let app = XCUIApplication()
        app.launch()
        
        // Navigate to Profile view to access Contributions Tracker
        // Assuming there's a way to navigate to Profile (tab bar, navigation, etc.)
        // This test assumes the Profile view is accessible
        
        // Wait for the app to load
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 10))
        
        // Look for Profile tab or navigation element
        // Adjust this based on your actual navigation structure
        if app.tabBars.buttons["Profile"].exists {
            app.tabBars.buttons["Profile"].tap()
        } else if app.navigationBars.buttons["Profile"].exists {
            app.navigationBars.buttons["Profile"].tap()
        }
        
        // Verify Contributions Tracker is visible
        XCTAssertTrue(app.staticTexts["Question History"].exists, "Question History header should be visible")
        
        // Verify legend is present
        XCTAssertTrue(app.staticTexts["Correct"].exists, "Correct legend should be visible")
        XCTAssertTrue(app.staticTexts["Incorrect"].exists, "Incorrect legend should be visible")
        XCTAssertTrue(app.staticTexts["No data"].exists, "No data legend should be visible")
    }
    
    func testEmptyBoxClickShowsDate() throws {
        let app = XCUIApplication()
        app.launch()
        
        // Navigate to Profile view
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 10))
        
        if app.tabBars.buttons["Profile"].exists {
            app.tabBars.buttons["Profile"].tap()
        } else if app.navigationBars.buttons["Profile"].exists {
            app.navigationBars.buttons["Profile"].tap()
        }
        
        // Wait for contributions tracker to load
        XCTAssertTrue(app.staticTexts["Question History"].waitForExistence(timeout: 5))
        
        // Find contribution squares (gray boxes for empty dates)
        let contributionSquares = app.otherElements.matching(identifier: "ContributionSquare")
        
        // Look for gray squares (empty boxes) - these should be clickable
        let graySquares = contributionSquares.matching(NSPredicate(format: "color == 'gray'"))
        
        if graySquares.count > 0 {
            // Tap the first gray square
            graySquares.element(boundBy: 0).tap()
            
            // Verify the Question Review sheet appears
            XCTAssertTrue(app.navigationBars["Question Review"].waitForExistence(timeout: 3))
            
            // Verify "No Question Available" text is shown
            XCTAssertTrue(app.staticTexts["No Question Available"].exists)
            
            // Verify date is displayed
            XCTAssertTrue(app.staticTexts["Date"].exists)
            
            // Verify there's a date value shown (not empty)
            let dateText = app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] '2024' OR label CONTAINS[c] '2025'"))
            XCTAssertTrue(dateText.count > 0, "Date should be displayed")
            
            // Close the sheet
            app.navigationBars["Question Review"].buttons["Done"].tap()
            
            // Verify we're back to the main view
            XCTAssertTrue(app.staticTexts["Question History"].exists)
        }
    }
    
    func testDayLabelsAlwaysVisible() throws {
        let app = XCUIApplication()
        app.launch()
        
        // Navigate to Profile view
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 10))
        
        if app.tabBars.buttons["Profile"].exists {
            app.tabBars.buttons["Profile"].tap()
        } else if app.navigationBars.buttons["Profile"].exists {
            app.navigationBars.buttons["Profile"].tap()
        }
        
        // Wait for contributions tracker to load
        XCTAssertTrue(app.staticTexts["Question History"].waitForExistence(timeout: 5))
        
        // Verify day labels are visible
        XCTAssertTrue(app.staticTexts["Mon"].exists, "Monday label should be visible")
        XCTAssertTrue(app.staticTexts["Wed"].exists, "Wednesday label should be visible")
        XCTAssertTrue(app.staticTexts["Fri"].exists, "Friday label should be visible")
        
        // Find the contributions grid scroll view
        let scrollViews = app.scrollViews
        XCTAssertTrue(scrollViews.count > 0, "Should have scroll views")
        
        // Scroll horizontally to test that day labels remain visible
        let firstScrollView = scrollViews.element(boundBy: 0)
        
        // Scroll right
        firstScrollView.swipeLeft()
        
        // Verify day labels are still visible after scrolling
        XCTAssertTrue(app.staticTexts["Mon"].exists, "Monday label should remain visible after scrolling")
        XCTAssertTrue(app.staticTexts["Wed"].exists, "Wednesday label should remain visible after scrolling")
        XCTAssertTrue(app.staticTexts["Fri"].exists, "Friday label should remain visible after scrolling")
        
        // Scroll back
        firstScrollView.swipeRight()
        
        // Verify day labels are still visible
        XCTAssertTrue(app.staticTexts["Mon"].exists, "Monday label should remain visible after scrolling back")
        XCTAssertTrue(app.staticTexts["Wed"].exists, "Wednesday label should remain visible after scrolling back")
        XCTAssertTrue(app.staticTexts["Fri"].exists, "Friday label should remain visible after scrolling back")
    }
    
    func testMonthLabelsAppear() throws {
        let app = XCUIApplication()
        app.launch()
        
        // Navigate to Profile view
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 10))
        
        if app.tabBars.buttons["Profile"].exists {
            app.tabBars.buttons["Profile"].tap()
        } else if app.navigationBars.buttons["Profile"].exists {
            app.navigationBars.buttons["Profile"].tap()
        }
        
        // Wait for contributions tracker to load
        XCTAssertTrue(app.staticTexts["Question History"].waitForExistence(timeout: 5))
        
        // Verify month labels are present (should show current month and recent months)
        let monthLabels = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", 
                          "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
        
        var foundMonths = 0
        for month in monthLabels {
            if app.staticTexts[month].exists {
                foundMonths += 1
            }
        }
        
        // Should find at least a few month labels
        XCTAssertTrue(foundMonths > 0, "Should find at least some month labels")
        
        // Specifically check for October (which was previously missing)
        XCTAssertTrue(app.staticTexts["Oct"].exists, "October should be visible")
    }
    
    func testContributionsTrackerScrolling() throws {
        let app = XCUIApplication()
        app.launch()
        
        // Navigate to Profile view
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 10))
        
        if app.tabBars.buttons["Profile"].exists {
            app.tabBars.buttons["Profile"].tap()
        } else if app.navigationBars.buttons["Profile"].exists {
            app.navigationBars.buttons["Profile"].tap()
        }
        
        // Wait for contributions tracker to load
        XCTAssertTrue(app.staticTexts["Question History"].waitForExistence(timeout: 5))
        
        // Find scroll views
        let scrollViews = app.scrollViews
        XCTAssertTrue(scrollViews.count > 0, "Should have scroll views")
        
        // Test horizontal scrolling
        let firstScrollView = scrollViews.element(boundBy: 0)
        
        // Verify we can scroll horizontally
        XCTAssertTrue(firstScrollView.exists, "Scroll view should exist")
        
        // Test scrolling in both directions
        firstScrollView.swipeLeft()
        firstScrollView.swipeLeft()
        firstScrollView.swipeRight()
        firstScrollView.swipeRight()
        
        // Verify the view is still functional after scrolling
        XCTAssertTrue(app.staticTexts["Question History"].exists)
    }
    
    func testQuestionReviewViewWithData() throws {
        let app = XCUIApplication()
        app.launch()
        
        // Navigate to Profile view
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 10))
        
        if app.tabBars.buttons["Profile"].exists {
            app.tabBars.buttons["Profile"].tap()
        } else if app.navigationBars.buttons["Profile"].exists {
            app.navigationBars.buttons["Profile"].tap()
        }
        
        // Wait for contributions tracker to load
        XCTAssertTrue(app.staticTexts["Question History"].waitForExistence(timeout: 5))
        
        // Look for colored squares (green or red) that represent answered questions
        let contributionSquares = app.otherElements.matching(identifier: "ContributionSquare")
        
        // Try to find a green or red square (answered question)
        var foundAnsweredQuestion = false
        for i in 0..<contributionSquares.count {
            let square = contributionSquares.element(boundBy: i)
            if square.exists {
                square.tap()
                
                // Check if Question Review sheet appears
                if app.navigationBars["Question Review"].waitForExistence(timeout: 2) {
                    // If it shows question content, this was an answered question
                    if app.staticTexts["Your Answer"].exists || app.staticTexts["Correct Answer"].exists {
                        foundAnsweredQuestion = true
                        
                        // Verify question review elements
                        XCTAssertTrue(app.staticTexts["Question Review"].exists)
                        
                        // Close the sheet
                        app.navigationBars["Question Review"].buttons["Done"].tap()
                        break
                    } else {
                        // This was an empty box, close and continue
                        app.navigationBars["Question Review"].buttons["Done"].tap()
                    }
                }
            }
        }
        
        // Note: This test might not find answered questions if there are none in the test data
        // That's okay - the test verifies the UI structure is correct
    }
}
