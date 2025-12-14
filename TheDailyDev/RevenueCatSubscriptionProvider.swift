//
//  RevenueCatSubscriptionProvider.swift
//  TheDailyDev
//
//  RevenueCat subscription management
//  Handles native iOS in-app purchases via RevenueCat SDK
//

import Foundation
import RevenueCat
import UIKit

/// Result of a purchase operation
enum PurchaseResult {
    case success
    case cancelled
    case failed(Error)
}

/// Subscription status information
struct SubscriptionStatus {
    let isActive: Bool
    let isInTrial: Bool
    let trialEndDate: Date?
    let periodEndDate: Date?
    let status: String
    let providerId: String? // RevenueCat subscription ID
}

/// RevenueCat subscription provider
/// Handles native iOS subscription purchases via StoreKit
class RevenueCatSubscriptionProvider {
    
    // MARK: - Initialization
    
    init() {
        // RevenueCat SDK is initialized in TheDailyDevApp.swift
        // This provider assumes SDK is already configured
    }
    
    // MARK: - Purchase
    
    /// Purchase a RevenueCat package directly
    func purchase(package: Package, skipTrial: Bool) async throws -> PurchaseResult {
        do {
            
            // Purchase the package
            // Note: skipTrial is not directly supported by RevenueCat SDK
            // Trial is configured in App Store Connect and RevenueCat dashboard
            let (_, customerInfo, userCancelled) = try await Purchases.shared.purchase(package: package)
            
            // Check if user cancelled
            if userCancelled {
                print("ℹ️ User cancelled purchase")
                return .cancelled
            }
            
            // Debug: Print all entitlements
            print("🔍 Checking entitlements after purchase:")
            print("   - Looking for entitlement ID: '\(Config.revenueCatEntitlementID)'")
            print("   - Available entitlements: \(customerInfo.entitlements.all.keys.joined(separator: ", "))")
            
            // Verify entitlement is active
            var activeEntitlement = customerInfo.entitlements[Config.revenueCatEntitlementID]
            
            // Fallback: If specific entitlement not found, check for any active entitlement
            if activeEntitlement == nil || activeEntitlement?.isActive != true {
                print("⚠️ Specific entitlement '\(Config.revenueCatEntitlementID)' not found or inactive")
                print("   - Checking for any active entitlements...")
                
                // Find any active entitlement
                for (key, entitlement) in customerInfo.entitlements.all {
                    if entitlement.isActive == true {
                        print("   - Found active entitlement: '\(key)'")
                        activeEntitlement = entitlement
                        break
                    }
                }
            }
            
            if let entitlement = activeEntitlement, entitlement.isActive == true {
                print("✅ Purchase successful - entitlement active")
                print("   - Entitlement ID: \(entitlement.identifier)")
                print("   - Status: \(entitlement.willRenew == true ? "active" : "expired")")
                if let expirationDate = entitlement.expirationDate {
                    print("   - Expires: \(expirationDate)")
                }
                return .success
            } else {
                print("⚠️ Purchase completed but entitlement not active")
                print("   - Entitlement exists: \(activeEntitlement != nil)")
                print("   - Entitlement isActive: \(activeEntitlement?.isActive ?? false)")
                if let activeEntitlement = activeEntitlement {
                    print("   - Entitlement willRenew: \(activeEntitlement.willRenew)")
                }
                
                // In test mode, try refreshing after a delay
                print("🔄 Waiting 1 second and refreshing customer info...")
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                
                let refreshedInfo = try? await Purchases.shared.customerInfo()
                if let refreshedInfo = refreshedInfo {
                    // Check specific entitlement first
                    var refreshedEntitlement = refreshedInfo.entitlements[Config.revenueCatEntitlementID]
                    
                    // Fallback: Check any active entitlement
                    if refreshedEntitlement == nil || refreshedEntitlement?.isActive != true {
                        for (key, entitlement) in refreshedInfo.entitlements.all {
                            if entitlement.isActive == true {
                                print("   - Found active entitlement after refresh: '\(key)'")
                                refreshedEntitlement = entitlement
                                break
                            }
                        }
                    }
                    
                    if let entitlement = refreshedEntitlement, entitlement.isActive == true {
                        print("✅ Entitlement active after refresh!")
                        return .success
                    }
                }
                
                return .failed(SubscriptionError.invalidResponse)
            }
        } catch {
            print("❌ Purchase failed: \(error)")
            return .failed(error)
        }
    }
    
    // MARK: - Restore Purchases
    
    func restorePurchases() async throws {
        do {
            let customerInfo = try await Purchases.shared.restorePurchases()
            
            // Check if user has active entitlement after restore
            var hasActive = customerInfo.entitlements[Config.revenueCatEntitlementID]?.isActive == true
            
            // Fallback: Check for any active entitlement
            if !hasActive {
                for (key, entitlement) in customerInfo.entitlements.all {
                    if entitlement.isActive == true {
                        print("⚠️ Using fallback entitlement check after restore - found active entitlement: \(key)")
                        hasActive = true
                        break
                    }
                }
            }
            
            if hasActive {
                print("✅ Purchases restored - entitlement active")
            } else {
                print("⚠️ Purchases restored but no active entitlement")
            }
        } catch {
            print("❌ Restore purchases failed: \(error)")
            throw error
        }
    }
    
    // MARK: - Get Management URL
    
    func getManagementURL() async throws -> URL {
        do {
            let customerInfo = try await Purchases.shared.customerInfo()
            
            // RevenueCat provides a management URL for Customer Center
            // This is configured in RevenueCat dashboard under Customer Center
            if let managementURL = customerInfo.managementURL {
                print("✅ Using RevenueCat Customer Center URL")
                return managementURL
            }
            
            // Fallback: Open App Store subscription management
            // This works for all iOS subscriptions
            if let url = URL(string: "https://apps.apple.com/account/subscriptions") {
                print("⚠️ No Customer Center URL, using App Store management")
                return url
            }
            
            throw SubscriptionError.invalidConfiguration
        } catch {
            print("❌ Failed to get management URL: \(error)")
            throw error
        }
    }
    
    // MARK: - Cancel Subscription
    
    func cancelSubscription() async throws {
        // Note: RevenueCat doesn't directly cancel subscriptions
        // Users must cancel through App Store or Customer Center
        // This method redirects to management URL
        let managementURL = try await getManagementURL()
        await MainActor.run {
            UIApplication.shared.open(managementURL)
        }
    }
    
    // MARK: - Check Active Subscription
    
    func hasActiveSubscription() async -> Bool {
        do {
            let customerInfo = try await Purchases.shared.customerInfo()
            
            // Check specific entitlement first
            if let entitlement = customerInfo.entitlements[Config.revenueCatEntitlementID],
               entitlement.isActive == true {
                return true
            }
            
            // Fallback: Check for any active entitlement
            for (_, entitlement) in customerInfo.entitlements.all {
                if entitlement.isActive == true {
                    print("⚠️ Using fallback entitlement check - found active entitlement: \(entitlement.identifier)")
                    return true
                }
            }
            
            return false
        } catch {
            print("❌ Failed to check subscription status: \(error)")
            return false
        }
    }
    
    // MARK: - Get Subscription Status
    
    func getSubscriptionStatus() async -> SubscriptionStatus? {
        do {
            let customerInfo = try await Purchases.shared.customerInfo()
            
            // Check specific entitlement first
            var entitlement = customerInfo.entitlements[Config.revenueCatEntitlementID]
            
            // Fallback: Check for any active entitlement
            if entitlement == nil || entitlement?.isActive != true {
                for (_, ent) in customerInfo.entitlements.all {
                    if ent.isActive == true {
                        print("⚠️ Using fallback entitlement for status - found active entitlement: \(ent.identifier)")
                        entitlement = ent
                        break
                    }
                }
            }
            
            guard let entitlement = entitlement else {
                return SubscriptionStatus(
                    isActive: false,
                    isInTrial: false,
                    trialEndDate: nil,
                    periodEndDate: nil,
                    status: "inactive",
                    providerId: nil
                )
            }
            
            let isActive = entitlement.isActive
            let isInTrial = entitlement.willRenew && entitlement.periodType == .trial
            let periodEndDate = entitlement.expirationDate
            let trialEndDate = isInTrial ? periodEndDate : nil
            
            // Map RevenueCat status to our status string
            let status: String
            if isActive {
                status = isInTrial ? "trialing" : "active"
            } else {
                status = "inactive"
            }
            
            // Note: Transaction IDs are not directly available from EntitlementInfo in iOS SDK
            // Transaction IDs should be set by the RevenueCat webhook, which is the source of truth
            // We don't set providerId here to avoid using entitlement.identifier (which is the entitlement ID, not a transaction ID)
            let providerId: String? = nil
            
            return SubscriptionStatus(
                isActive: isActive,
                isInTrial: isInTrial,
                trialEndDate: trialEndDate,
                periodEndDate: periodEndDate,
                status: status,
                providerId: providerId
            )
        } catch {
            print("❌ Failed to get subscription status: \(error)")
            return nil
        }
    }
    
    // MARK: - Helper Methods
    
    /// Get RevenueCat package by product identifier
    func getPackage(for productId: String) async throws -> Package? {
        // Get current offerings
        let offerings = try await Purchases.shared.offerings()
        
        guard let currentOffering = offerings.current else {
            print("❌ No current offering found in RevenueCat")
            throw SubscriptionError.invalidConfiguration
        }
        
        print("🔍 Looking for package with product ID: \(productId)")
        print("   Available packages: \(currentOffering.availablePackages.map { $0.storeProduct.productIdentifier })")
        
        // Find package with matching product ID
        let package = currentOffering.availablePackages.first { package in
            package.storeProduct.productIdentifier == productId
        }
        
        if let package = package {
            print("✅ Found package: \(package.identifier) for product: \(productId)")
            return package
        } else {
            print("❌ No package found with product ID: \(productId)")
            print("   Make sure the product ID matches what's configured in RevenueCat and App Store Connect")
            print("   Available product IDs: \(currentOffering.availablePackages.map { $0.storeProduct.productIdentifier })")
            return nil
        }
    }
    
    /// Get monthly package (default)
    func getMonthlyPackage() async throws -> Package? {
        return try await getPackage(for: Config.revenueCatMonthlyProductID)
    }
    
    /// Get yearly package
    func getYearlyPackage() async throws -> Package? {
        return try await getPackage(for: Config.revenueCatYearlyProductID)
    }
    
    /// Get all available packages for display
    func getAvailablePackages() async throws -> [Package] {
        let offerings = try await Purchases.shared.offerings()
        guard let currentOffering = offerings.current else {
            return []
        }
        return currentOffering.availablePackages
    }
    
    /// Get customer info
    func getCustomerInfo() async throws -> CustomerInfo {
        return try await Purchases.shared.customerInfo()
    }
}

// MARK: - RevenueCat Paywall Support

extension RevenueCatSubscriptionProvider {
    /// Get paywall data for RevenueCat Paywalls
    func getPaywallData() async throws -> PaywallData {
        let offerings = try await Purchases.shared.offerings()
        
        guard let currentOffering = offerings.current else {
            throw SubscriptionError.invalidConfiguration
        }
        
        return PaywallData(
            offering: currentOffering,
            packages: currentOffering.availablePackages
        )
    }
}

/// Paywall data structure for RevenueCat Paywalls
struct PaywallData {
    let offering: Offering
    let packages: [Package]
}

