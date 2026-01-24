//
//  SubscriptionService.swift
//  TheDailyDev
//
//  Created by Claire Knutson on 10/25/25.
//

import Foundation
import Supabase
import RevenueCat

class SubscriptionService: ObservableObject {
    static let shared = SubscriptionService()
    
    @Published var currentSubscription: UserSubscription?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // Cache management
    private var lastFetchTime: Date?
    private let cacheTimeout: TimeInterval = 300 // 5 minutes
    
    // Request deduplication - prevent concurrent syncs
    private var currentSyncTask: Task<Void, Never>?
    private var currentFetchTask: Task<UserSubscription?, Never>?
    
    // RevenueCat provider instance
    private let revenueCatProvider = RevenueCatSubscriptionProvider()
    
    private init() {}
    
    // MARK: - Cache Invalidation
    /// Force next fetch to bypass cache - call after critical actions like purchase/answer
    func invalidateCache() {
        lastFetchTime = nil
        DebugLogger.log("🔄 Cache invalidated - next fetch will be fresh")
    }
    
    /// Clear ALL caches and reset state - call on sign out to ensure no user data persists
    func clearAllCaches() {
        // Clear fetch time cache
        lastFetchTime = nil
        
        // Clear current subscription
        currentSubscription = nil
        
        // Clear error message
        errorMessage = nil
        
        // Reset loading state
        isLoading = false
        
        // Cancel any in-progress requests
        currentSyncTask?.cancel()
        currentSyncTask = nil
        currentFetchTask?.cancel()
        currentFetchTask = nil
        
        DebugLogger.log("🧹 All SubscriptionService caches cleared")
    }
    
    // MARK: - Get RevenueCat Packages
    /// Get all available packages from RevenueCat
    func getAvailablePackages() async throws -> [Package] {
        return try await revenueCatProvider.getAvailablePackages()
    }
    
    /// Get monthly package (default)
    func getMonthlyPackage() async throws -> Package? {
        return try await revenueCatProvider.getMonthlyPackage()
    }
    
    /// Get yearly package
    func getYearlyPackage() async throws -> Package? {
        return try await revenueCatProvider.getYearlyPackage()
    }
    
    // MARK: - Extract Name from User Metadata
    private func extractNameFromMetadata(userMetadata: [String: Any]) -> (String?, String?) {
        var firstName: String?
        var lastName: String?
        
        // Try multiple possible name fields from OAuth providers and auth.users
        let nameFields = ["full_name", "name", "display_name", "displayName", "fullName"]
        var fullName: String?
        
        for field in nameFields {
            if let nameValue = userMetadata[field] {
                // Try direct String cast first
                if let name = nameValue as? String, !name.isEmpty {
                    fullName = name
                    break
                }
                
                // If not String, try converting AnyJSON using string description
                // AnyJSON's description should give us the underlying value
                let stringValue = String(describing: nameValue)
                if !stringValue.isEmpty && stringValue != "nil" && !stringValue.hasPrefix("AnyJSON") {
                    fullName = stringValue
                    break
                }
            }
        }
        
        if let fullName = fullName {
            let parts = fullName.split(separator: " ", maxSplits: 1, omittingEmptySubsequences: true)
            firstName = parts.isEmpty ? nil : String(parts[0])
            lastName = parts.count > 1 ? String(parts[1]) : nil
        }
        
        return (firstName, lastName)
    }
    
    // MARK: - Ensure User Subscription Record Exists
    /// Ensures a user_subscriptions record exists for the user, but NEVER modifies subscription status
    /// WARNING: DO NOT modify status or RevenueCat-related fields here!
    /// Those fields are ONLY managed by the RevenueCat webhook and syncRevenueCatStatus() to maintain sync
    /// - Parameters:
    ///   - firstName: Optional first name to set if creating new record
    ///   - lastName: Optional last name to set if creating new record
    func ensureUserSubscriptionRecord(firstName: String? = nil, lastName: String? = nil) async {
        do {
            let session = try await SupabaseManager.shared.client.auth.session
            let userId = session.user.id.uuidString
            
            // Extract name from parameters (passed in) or user metadata (from auth.users table)
            var finalFirstName: String? = firstName
            var finalLastName: String? = lastName
            
            // If not provided as parameters, try to get from userMetadata
            if finalFirstName == nil && finalLastName == nil {
                let userMetadataDict = session.user.userMetadata.reduce(into: [String: Any]()) { result, pair in
                    result[pair.key] = pair.value
                }
                if !userMetadataDict.isEmpty {
                    let extracted = extractNameFromMetadata(userMetadata: userMetadataDict)
                    finalFirstName = extracted.0
                    finalLastName = extracted.1
                }
            }
            
            // Check if record already exists
            let existing: [UserSubscription] = try await SupabaseManager.shared.client
                .from("user_subscriptions")
                .select()
                .eq("user_id", value: userId)
                .limit(1)
                .execute()
                .value
            
            if existing.isEmpty {
                // Record doesn't exist - create it with minimal data
                // IMPORTANT: Only set status to "inactive" when creating NEW records
                // The RevenueCat webhook or syncRevenueCatStatus() will update it when subscription is created
                var insertData: [String: String] = [
                    "user_id": userId,
                    "status": "inactive"  // Only set for NEW records
                ]
                
                // Only set name if we have it
                if let firstName = finalFirstName, !firstName.isEmpty {
                    insertData["first_name"] = firstName
                }
                if let lastName = finalLastName, !lastName.isEmpty {
                    insertData["last_name"] = lastName
                }
                
                _ = try await SupabaseManager.shared.client
                    .from("user_subscriptions")
                    .insert(insertData)
                    .execute()
                
                DebugLogger.log("✅ Created new user_subscriptions record")
            } else {
                // Record exists - ONLY update name fields if they're missing
                // DO NOT touch subscription status or RevenueCat-related fields!
                if let existingRecord = existing.first {
                    let needsUpdate = (existingRecord.firstName == nil || existingRecord.firstName?.isEmpty == true) && finalFirstName != nil ||
                                      (existingRecord.lastName == nil || existingRecord.lastName?.isEmpty == true) && finalLastName != nil
                    
                    if needsUpdate {
                        var updateData: [String: String?] = [:]
                        if (existingRecord.firstName == nil || existingRecord.firstName?.isEmpty == true) && finalFirstName != nil {
                            updateData["first_name"] = finalFirstName
                        }
                        if (existingRecord.lastName == nil || existingRecord.lastName?.isEmpty == true) && finalLastName != nil {
                            updateData["last_name"] = finalLastName
                        }
                        
                        if !updateData.isEmpty {
                            _ = try await SupabaseManager.shared.client
                                .from("user_subscriptions")
                                .update(updateData)
                                .eq("user_id", value: userId)
                                .execute()
                            
                            DebugLogger.log("✅ Updated name for user_subscriptions record")
                        }
                    }
                }
                // If record exists, do nothing else - RevenueCat webhook and syncRevenueCatStatus() manage subscription fields
            }
        } catch let error as PostgrestError {
            // Handle foreign key constraint errors (user deleted from auth.users but session still exists)
            if error.code == "23503" {
                DebugLogger.log("⚠️ Foreign key constraint error in ensureUserSubscriptionRecord - user may have been deleted")
                DebugLogger.log("   This is expected if the account was deleted. Skipping record creation.")
                // Don't throw - this is expected when account is deleted
            } else {
                DebugLogger.error("❌ Failed to ensure user_subscriptions record: \(error)")
            }
        } catch {
            DebugLogger.error("❌ Failed to ensure user_subscriptions record: \(error)")
            // Don't throw - this is a background operation
        }
    }
    
    // MARK: - Fetch User Subscription
    func fetchSubscriptionStatus(forceRefresh: Bool = false) async -> UserSubscription? {
        // Check cache first (unless force refresh)
        if !forceRefresh,
           let lastFetch = lastFetchTime,
           let cached = currentSubscription,
           Date().timeIntervalSince(lastFetch) < cacheTimeout {
            DebugLogger.log("✅ Using cached subscription (age: \(Int(Date().timeIntervalSince(lastFetch)))s)")
            return cached
        }
        
        // If there's already a fetch in progress, wait for it instead of starting a new one
        if let existingTask = currentFetchTask {
            DebugLogger.log("ℹ️ Subscription fetch already in progress, waiting for existing request...")
            return await existingTask.value
        }
        
        // Create a new fetch task
        let fetchTask = Task<UserSubscription?, Never> {
            DebugLogger.log("🔄 Fetching fresh subscription status...")
            
            // Sync status from RevenueCat first (with deduplication)
            await syncRevenueCatStatus()
            
            do {
                let session = try await SupabaseManager.shared.client.auth.session
                let userId = session.user.id.uuidString
                
                let subscriptions: [UserSubscription] = try await SupabaseManager.shared.client
                    .from("user_subscriptions")
                    .select()
                    .eq("user_id", value: userId)
                    .order("created_at", ascending: false)
                    .limit(1)
                    .execute()
                    .value
                
                let previousSubscription = await MainActor.run { self.currentSubscription }
                let newSubscription = subscriptions.first
                
                await MainActor.run {
                    self.currentSubscription = newSubscription
                    self.lastFetchTime = Date()
                    self.currentFetchTask = nil // Clear task reference when done
                }
                
                // Track subscription status changes
                if let newSub = newSubscription {
                    // Batch user properties together to reduce event noise
                    var userProperties: [String: Any] = ["subscription_status": newSub.status]
                    if let plan = newSub.status == "active" || newSub.status == "trialing" ? (newSub.currentPeriodEnd != nil ? "monthly" : "yearly") : nil {
                        userProperties["subscription_plan"] = plan
                    }
                    AnalyticsService.shared.setUserProperties(userProperties)
                    
                    // Track trial events
                    if let previous = previousSubscription {
                        // Check if trial started
                        if previous.status != "trialing" && newSub.status == "trialing" {
                            AnalyticsService.shared.track("trial_started", properties: [
                                "trial_end_date": newSub.trialEnd ?? ""
                            ])
                        }
                        
                        // Check if trial converted
                        if previous.status == "trialing" && newSub.status == "active" {
                            AnalyticsService.shared.track("trial_converted", properties: [
                                "plan": "monthly" // Could be enhanced to detect actual plan
                            ])
                        }
                    } else if newSub.status == "trialing" {
                        // New subscription with trial
                        AnalyticsService.shared.track("trial_started", properties: [
                            "trial_end_date": newSub.trialEnd ?? ""
                        ])
                    }
                }
                
                DebugLogger.log("✅ Subscription status updated: \(subscriptions.first?.status ?? "none")")
                
                return subscriptions.first
            } catch {
                let nsError = error as NSError
                if nsError.domain == NSURLErrorDomain && nsError.code == NSURLErrorCancelled {
                    DebugLogger.log("ℹ️ Subscription fetch cancelled (likely superseded by a newer request).")
                    await MainActor.run {
                        self.currentFetchTask = nil // Clear task reference
                    }
                    return await MainActor.run {
                        self.currentSubscription
                    }
                }
                await MainActor.run {
                    self.errorMessage = "Failed to fetch subscription: \(error.localizedDescription)"
                    self.currentFetchTask = nil // Clear task reference
                }
                DebugLogger.error("Failed to fetch subscription status: \(error)")
                return nil
            }
        }
        
        // Store the task and await its result
        await MainActor.run {
            self.currentFetchTask = fetchTask
        }
        
        return await fetchTask.value
    }
    
    // MARK: - Sync RevenueCat Status
    /// Syncs subscription status from RevenueCat to database
    /// This ensures database is up-to-date with RevenueCat's latest status
    /// Uses request deduplication to prevent concurrent syncs
    private func syncRevenueCatStatus() async {
        // If there's already a sync in progress, wait for it instead of starting a new one
        if let existingTask = currentSyncTask {
            DebugLogger.log("ℹ️ RevenueCat sync already in progress, waiting for existing sync...")
            await existingTask.value
            return
        }
        
        // Create a new sync task
        let syncTask = Task<Void, Never> {
            do {
            // Get customer info directly from RevenueCat to access transaction IDs
            let customerInfo = try await revenueCatProvider.getCustomerInfo()
            
            // Get user ID
            let session = try await SupabaseManager.shared.client.auth.session
            let userId = session.user.id.uuidString
            
            // Get RevenueCat user ID
            // After logIn(), the app user ID is the Supabase user ID
            // We use the userId directly since that's what we set with logIn()
            let revenueCatUserId = userId
            
            // Find active entitlement
            var entitlement = customerInfo.entitlements[Config.revenueCatEntitlementID]
            
            // Fallback: Check for any active entitlement
            if entitlement == nil || entitlement?.isActive != true {
                for (_, ent) in customerInfo.entitlements.all {
                    if ent.isActive == true {
                        entitlement = ent
                        break
                    }
                }
            }
            
            // Get status from RevenueCat (for status string)
            guard let status = await revenueCatProvider.getSubscriptionStatus() else {
                return
            }
            
            // Create date formatter for ISO8601
            let dateFormatter = ISO8601DateFormatter()
            dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            
            // Build upsert data (all values must be String or String?)
            var upsertData: [String: String?] = [
                "user_id": userId,
                "revenuecat_user_id": revenueCatUserId,
                "status": status.status,
                "entitlement_status": status.isActive ? "active" : "inactive",
                "updated_at": dateFormatter.string(from: Date())
            ]
            
            // Add optional date fields
            if let periodEnd = status.periodEndDate {
                upsertData["current_period_end"] = dateFormatter.string(from: periodEnd)
            }
            
            if let trialEnd = status.trialEndDate {
                upsertData["trial_end"] = dateFormatter.string(from: trialEnd)
            }
            
            // Note: Transaction IDs are not directly available from EntitlementInfo in iOS SDK
            // Transaction IDs should be set by the RevenueCat webhook, which is the authoritative source
            // We don't set them here to avoid incorrect values (like using entitlement.identifier)
            // The webhook will populate revenuecat_subscription_id and original_transaction_id correctly
            DebugLogger.log("ℹ️ Transaction IDs are managed by RevenueCat webhook, not app-side sync")
            
            // Upsert to database
            _ = try await SupabaseManager.shared.client
                .from("user_subscriptions")
                .upsert(upsertData, onConflict: "user_id")
                .execute()
            
                DebugLogger.log("✅ Synced RevenueCat status to database")
            } catch let error as PostgrestError {
                // Handle foreign key constraint errors (user deleted from auth.users but session still exists)
                if error.code == "23503" {
                    DebugLogger.log("⚠️ Foreign key constraint error in syncRevenueCatStatus - user may have been deleted")
                    DebugLogger.log("   This is expected if the account was deleted. Skipping sync.")
                    // Don't throw - this is expected when account is deleted
                } else {
                    DebugLogger.error("⚠️ Failed to sync RevenueCat status: \(error)")
                }
            } catch {
                let nsError = error as NSError
                // Don't log cancelled errors as failures - they're expected when requests are deduplicated
                if nsError.domain == NSURLErrorDomain && nsError.code == NSURLErrorCancelled {
                    DebugLogger.log("ℹ️ RevenueCat sync cancelled (likely superseded by a newer request)")
                } else {
                    DebugLogger.error("Failed to sync RevenueCat status: \(error)")
                }
                // Don't throw - this is a background sync
            }
            
            // Clear task reference when done
            await MainActor.run {
                self.currentSyncTask = nil
            }
        }
        
        // Store the task and await its result
        await MainActor.run {
            self.currentSyncTask = syncTask
        }
        
        await syncTask.value
    }
    
    // MARK: - Purchase Package
    /// Initiates RevenueCat native purchase flow for a package
    func purchase(package: Package, skipTrial: Bool = false) async throws -> URL {
        // Use RevenueCat provider to handle purchase
        let result = try await revenueCatProvider.purchase(package: package, skipTrial: skipTrial)
        
        switch result {
        case .success:
            // Purchase happens natively - return success deep link
            return URL(string: "thedailydev://subscription-success")!
        case .cancelled:
            throw SubscriptionError.networkError // User cancelled
        case .failed(let error):
            throw error
        }
    }
    
    // MARK: - Get Checkout URL / Purchase (Legacy - for compatibility)
    /// Legacy method for compatibility - purchases monthly package by default
    @available(*, deprecated, message: "Use purchase(package:) instead")
    func getCheckoutURL(plan: Any? = nil, skipTrial: Bool = false) async throws -> URL {
        // Default to monthly package
        guard let monthlyPackage = try await getMonthlyPackage() else {
            throw SubscriptionError.invalidConfiguration
        }
        return try await purchase(package: monthlyPackage, skipTrial: skipTrial)
    }
    
    // MARK: - Check if User Can Access Questions
    func canAccessQuestions() async -> Bool {
        // 1. Check subscription/trial status
        if currentSubscription?.isActive == true {
            return true
        }
        
        // 2. Check if they've never answered (first free question)
        let hasAnswered = await QuestionService.shared.hasAnsweredAnyQuestion()
        if !hasAnswered {
            return true
        }
        
        // 3. Check if it's Friday
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: Date())
        if weekday == 6 { // Friday
            return true
        }
        
        // 4. Otherwise, need subscription
        return false
    }
    
    // MARK: - Get Function URL
    private func getFunctionURL(functionName: String) -> URL? {
        return Config.getFunctionURL(functionName: functionName)
    }
    
    // MARK: - Cancel Subscription
    func cancelSubscription() async throws {
        // Track subscription cancelled
        AnalyticsService.shared.track("subscription_cancelled")
        
        try await revenueCatProvider.cancelSubscription()
        
        // Refresh subscription status
        _ = await fetchSubscriptionStatus(forceRefresh: true)
    }
    
    // MARK: - Get Billing Portal URL / Management URL
    /// Returns URL for subscription management (RevenueCat Customer Center or App Store)
    func getBillingPortalURL() async throws -> URL {
        return try await revenueCatProvider.getManagementURL()
    }
    
    // MARK: - Restore Purchases
    func restorePurchases() async throws {
        try await revenueCatProvider.restorePurchases()
        
        // Refresh subscription status
        _ = await fetchSubscriptionStatus(forceRefresh: true)
    }
}

// MARK: - Subscription Errors
enum SubscriptionError: Error, LocalizedError {
    case invalidConfiguration
    case networkError
    case invalidResponse
    case noActiveSubscription
    
    var errorDescription: String? {
        switch self {
        case .invalidConfiguration:
            return "Subscription service not properly configured"
        case .networkError:
            return "Network error. Please try again."
        case .invalidResponse:
            return "Invalid response from server"
        case .noActiveSubscription:
            return "No active subscription found"
        }
    }
}
