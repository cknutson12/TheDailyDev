//
//  AnalyticsService.swift
//  TheDailyDev
//
//  Created for PostHog analytics tracking
//

import Foundation
import PostHog

/// Central analytics service for tracking user events and properties
class AnalyticsService {
    static let shared = AnalyticsService()
    
    private var isInitialized = false
    private var currentUserId: String?
    private var signUpDate: Date?
    
    private init() {}
    
    // MARK: - Initialization
    
    /// Initialize PostHog with API key
    func initialize() {
        guard !isInitialized else {
            DebugLogger.log("⚠️ AnalyticsService already initialized")
            return
        }
        
        let apiKey = Config.postHogAPIKey
        
        guard !apiKey.isEmpty else {
            DebugLogger.error("PostHog API key is empty - analytics will not work")
            return
        }
        
        let config = PostHogConfig(apiKey: apiKey)
        // Enable session recordings (optional, can be disabled if not needed)
        config.sessionReplay = false
        
        // Disable automatic screen tracking - we use custom trackScreen() instead
        // This prevents generic "UIHostingController" screen names from appearing
        config.captureScreenViews = false
        
        #if DEBUG
        // Enable debug logging in DEBUG builds to help verify events are being sent
        config.debug = true
        DebugLogger.log("🔍 PostHog debug mode enabled")
        #endif
        
        PostHogSDK.shared.setup(config)
        isInitialized = true
        
        DebugLogger.log("✅ PostHog initialized with API key: \(String(apiKey.prefix(10)))...")
        
        #if DEBUG
        // In DEBUG mode, flush events immediately for testing
        PostHogSDK.shared.flush()
        DebugLogger.log("🔄 PostHog events flushed (debug mode)")
        #endif
    }
    
    // MARK: - User Identification
    
    /// Set user ID after sign-in
    func setUserID(_ userId: String) {
        currentUserId = userId
        PostHogSDK.shared.identify(userId)
        DebugLogger.log("✅ Analytics user ID set")
    }
    
    /// Clear user ID on sign-out
    func clearUserID() {
        currentUserId = nil
        signUpDate = nil
        PostHogSDK.shared.reset()
        DebugLogger.log("✅ Analytics user ID cleared")
    }
    
    // MARK: - Event Tracking
    
    /// Track an event with optional properties
    func track(_ event: String, properties: [String: Any]? = nil) {
        guard isInitialized else {
            DebugLogger.log("⚠️ Analytics not initialized - event not tracked: \(event)")
            return
        }
        
        // Merge with default properties
        var finalProperties = properties ?? [:]
        
        // Add timestamp if not already present
        if finalProperties["timestamp"] == nil {
            finalProperties["timestamp"] = ISO8601DateFormatter().string(from: Date())
        }
        
        PostHogSDK.shared.capture(event, properties: finalProperties)
        DebugLogger.log("📊 Tracked event: \(event)")
    }
    
    // MARK: - User Properties
    
    /// Set a single user property
    /// Note: Properties are batched and sent together to reduce event noise
    func setUserProperty(_ key: String, value: Any) {
        guard isInitialized else { return }
        
        // Batch user properties - collect them and send together
        // This reduces the number of "Set person properties" events
        let distinctId = currentUserId ?? PostHogSDK.shared.getDistinctId()
        
        // Get existing user properties and merge
        // Note: PostHog will merge properties automatically, but we batch to reduce events
        PostHogSDK.shared.identify(distinctId, userProperties: [key: value])
        DebugLogger.log("📊 Set user property: \(key)")
    }
    
    /// Set multiple user properties at once
    func setUserProperties(_ properties: [String: Any]) {
        guard isInitialized else { return }
        
        let distinctId = currentUserId ?? PostHogSDK.shared.getDistinctId()
        PostHogSDK.shared.identify(distinctId, userProperties: properties)
        DebugLogger.log("📊 Set user properties: \(properties.keys.joined(separator: ", "))")
    }
    
    // MARK: - Screen Tracking
    
    /// Track screen view
    func trackScreen(_ screenName: String, properties: [String: Any]? = nil) {
        var screenProperties = properties ?? [:]
        screenProperties["screen_name"] = screenName
        
        track("screen_view", properties: screenProperties)
    }
    
    // MARK: - Helper Methods
    
    /// Store sign-up date for time-to-event calculations
    func setSignUpDate(_ date: Date) {
        signUpDate = date
        setUserProperty("sign_up_date", value: ISO8601DateFormatter().string(from: date))
    }
    
    /// Calculate time to first question (seconds since sign-up)
    func getTimeToFirstQuestion() -> Int? {
        guard let signUpDate = signUpDate else { return nil }
        return Int(Date().timeIntervalSince(signUpDate))
    }
}

