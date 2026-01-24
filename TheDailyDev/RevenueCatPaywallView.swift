//
//  RevenueCatPaywallView.swift
//  TheDailyDev
//
//  RevenueCat Paywall view using RevenueCat Paywalls
//  Modern, native iOS subscription purchase experience
//

import SwiftUI
import RevenueCat

struct RevenueCatPaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var subscriptionService = SubscriptionService.shared
    @State private var packages: [Package] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var selectedPackage: Package?
    @State private var isPurchasing = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.theme.background.ignoresSafeArea()
                
                if isLoading {
                    ProgressView("Loading plans...")
                        .foregroundColor(.white)
                } else if let error = errorMessage {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.largeTitle)
                            .foregroundColor(.orange)
                        Text("Error")
                            .font(.title2)
                            .bold()
                        Text(error)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        Button("Retry") {
                            Task {
                                await loadPackages()
                            }
                        }
                        .buttonStyle(PrimaryButtonStyle())
                    }
                    .padding()
                } else {
                    ScrollView {
                        VStack(spacing: 24) {
                            // Header
                            VStack(spacing: 12) {
                                Image(systemName: "crown.fill")
                                    .font(.system(size: 60))
                                    .foregroundColor(Theme.Colors.accentGreen)
                                
                                Text("The Daily Dev Pro")
                                    .font(.title)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                
                                Text("Unlock unlimited daily questions")
                                    .font(.body)
                                    .foregroundColor(Color.theme.textSecondary)
                            }
                            .padding(.top, 20)
                            
                            // Benefits
                            VStack(alignment: .leading, spacing: 16) {
                                ForEach(SubscriptionBenefit.allBenefits) { benefit in
                                    HStack(alignment: .top, spacing: 12) {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(Theme.Colors.stateCorrect)
                                            .font(.title3)
                                        
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(benefit.title)
                                                .font(.headline)
                                                .foregroundColor(.white)
                                            
                                            if let description = benefit.description {
                                                Text(description)
                                                    .font(.subheadline)
                                                    .foregroundColor(Color.theme.textSecondary)
                                                    .fixedSize(horizontal: false, vertical: true)
                                            }
                                        }
                                        
                                        Spacer()
                                    }
                                }
                            }
                            .padding()
                            .cardContainer()
                            
                            // Package Selection
                            if !packages.isEmpty {
                                VStack(spacing: 12) {
                                    ForEach(packages, id: \.identifier) { package in
                                        PackageCard(
                                            package: package,
                                            isSelected: selectedPackage?.identifier == package.identifier,
                                            onSelect: {
                                                selectedPackage = package
                                            }
                                        )
                                    }
                                }
                                .padding(.horizontal)
                            }
                            
                            // Purchase Button
                            if let selectedPackage = selectedPackage {
                                Button(action: {
                                    Task {
                                        await purchasePackage(selectedPackage)
                                    }
                                }) {
                                    if isPurchasing {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle())
                                            .tint(.black)
                                    } else {
                                        Text("Subscribe")
                                            .font(.headline)
                                    }
                                }
                                .buttonStyle(PrimaryButtonStyle())
                                .disabled(isPurchasing)
                                .padding(.horizontal)
                            }
                            
                            // Free Friday note
                            VStack(spacing: 12) {
                                Text("No subscription? Come back Friday for your next free question")
                                    .font(.subheadline)
                                    .foregroundColor(Color.theme.textSecondary)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal)
                                
                                // Restore Purchases
                                Button(action: {
                                    Task {
                                        await restorePurchases()
                                    }
                                }) {
                                    Text("Restore Purchases")
                                        .font(.subheadline)
                                        .foregroundColor(Color.theme.textSecondary)
                                }
                            }
                            .padding(.bottom, 20)
                        }
                    }
                }
            }
            .navigationTitle("Subscribe")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
        .task {
            await loadPackages()
        }
        .onAppear {
            // Track paywall viewed
            Task {
                let hasAnsweredQuestion = await QuestionService.shared.hasAnsweredAnyQuestion()
                let hasActiveSubscription = SubscriptionService.shared.currentSubscription?.isActive ?? false
                
                AnalyticsService.shared.track("paywall_viewed", properties: [
                    "source": "revenuecat_paywall",
                    "user_has_answered_question": hasAnsweredQuestion,
                    "user_has_active_subscription": hasActiveSubscription
                ])
            }
        }
    }
    
    // MARK: - Load Packages
    
    private func loadPackages() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let provider = RevenueCatSubscriptionProvider()
            let loadedPackages = try await provider.getAvailablePackages()
            
            await MainActor.run {
                self.packages = loadedPackages
                // Select first package by default
                self.selectedPackage = loadedPackages.first
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
        }
    }
    
    // MARK: - Purchase Package
    
    private func purchasePackage(_ package: Package) async {
        isPurchasing = true
        
        // Track purchase started
        let plan = package.storeProduct.productIdentifier
        AnalyticsService.shared.track("subscription_purchase_started", properties: [
            "plan": plan,
            "package_type": package.packageType.rawValue
        ])
        
        do {
            let (_, customerInfo, userCancelled) = try await Purchases.shared.purchase(package: package)
            
            // Check if user cancelled
            if userCancelled {
                // Track purchase cancelled
                AnalyticsService.shared.track("subscription_purchase_cancelled", properties: [
                    "plan": plan
                ])
                
                await MainActor.run {
                    isPurchasing = false
                }
                return
            }
            
            // Debug: Print all entitlements to see what we have
            DebugLogger.log("🔍 Checking entitlements after purchase:")
            DebugLogger.log("   - Looking for entitlement ID: '\(Config.revenueCatEntitlementID)'")
            DebugLogger.log("   - Available entitlements: \(customerInfo.entitlements.all.keys.joined(separator: ", "))")
            
            for (key, entitlement) in customerInfo.entitlements.all {
                DebugLogger.log("   - Entitlement '\(key)': isActive=\(entitlement.isActive), willRenew=\(entitlement.willRenew)")
            }
            
            // Verify entitlement is active
            var activeEntitlement = customerInfo.entitlements[Config.revenueCatEntitlementID]
            
            // Fallback: If specific entitlement not found, check for any active entitlement
            if activeEntitlement == nil || activeEntitlement?.isActive != true {
                DebugLogger.log("⚠️ Specific entitlement '\(Config.revenueCatEntitlementID)' not found or inactive")
                DebugLogger.log("   - Checking for any active entitlements...")
                
                // Find any active entitlement
                for (key, entitlement) in customerInfo.entitlements.all {
                    if entitlement.isActive == true {
                        DebugLogger.log("   - Found active entitlement: '\(key)'")
                        activeEntitlement = entitlement
                        break
                    }
                }
            }
            
            if let entitlement = activeEntitlement, entitlement.isActive == true {
                DebugLogger.log("✅ Purchase successful - entitlement active")
                DebugLogger.log("   - Entitlement ID: \(entitlement.identifier)")
                DebugLogger.log("   - Will renew: \(entitlement.willRenew)")
                
                // Track purchase successful
                let price = package.storeProduct.localizedPriceString
                // Check if this is a trial by checking if willRenew is true and expiration date exists
                // In RevenueCat, trials typically have willRenew = true and an expiration date
                let isTrial = entitlement.willRenew && entitlement.expirationDate != nil
                // Calculate trial days if available (approximate based on expiration)
                let trialDays: Int
                if isTrial, let expiration = entitlement.expirationDate {
                    let days = Int(expiration.timeIntervalSinceNow / 86400)
                    trialDays = max(0, days)
                } else {
                    trialDays = 0
                }
                
                AnalyticsService.shared.track("subscription_purchased", properties: [
                    "plan": plan,
                    "price": price,
                    "is_trial": isTrial,
                    "trial_days": trialDays
                ])
                
                // Refresh subscription status
                _ = await subscriptionService.fetchSubscriptionStatus(forceRefresh: true)
                
                // Post success notification
                await MainActor.run {
                    NotificationCenter.default.post(name: NSNotification.Name("SubscriptionSuccess"), object: nil)
                    dismiss()
                }
            } else {
                // More detailed error logging
                DebugLogger.log("⚠️ Purchase completed but entitlement check failed:")
                DebugLogger.log("   - Entitlement exists: \(activeEntitlement != nil)")
                if let activeEntitlement = activeEntitlement {
                    DebugLogger.log("   - Entitlement isActive: \(activeEntitlement.isActive)")
                    DebugLogger.log("   - Entitlement willRenew: \(activeEntitlement.willRenew)")
                    DebugLogger.log("   - Product identifier: \(activeEntitlement.productIdentifier)")
                } else {
                    DebugLogger.log("   - Entitlement isActive: false")
                    DebugLogger.log("   - Entitlement willRenew: false")
                    DebugLogger.log("   - Product identifier: none")
                }
                
                // In test mode, sometimes entitlements take a moment to activate
                // Try refreshing customer info after a short delay
                DebugLogger.log("🔄 Waiting 1 second and refreshing customer info...")
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                
                let refreshedInfo = try? await Purchases.shared.customerInfo()
                if let refreshedInfo = refreshedInfo {
                    // Check specific entitlement first
                    var refreshedEntitlement = refreshedInfo.entitlements[Config.revenueCatEntitlementID]
                    
                    // Fallback: Check any active entitlement
                    if refreshedEntitlement == nil || refreshedEntitlement?.isActive != true {
                        for (key, entitlement) in refreshedInfo.entitlements.all {
                            if entitlement.isActive == true {
                                DebugLogger.log("   - Found active entitlement after refresh: '\(key)'")
                                refreshedEntitlement = entitlement
                                break
                            }
                        }
                    }
                    
                    if let entitlement = refreshedEntitlement, entitlement.isActive == true {
                        DebugLogger.log("✅ Entitlement active after refresh!")
                        _ = await subscriptionService.fetchSubscriptionStatus(forceRefresh: true)
                        await MainActor.run {
                            NotificationCenter.default.post(name: NSNotification.Name("SubscriptionSuccess"), object: nil)
                            dismiss()
                        }
                    } else {
                        DebugLogger.error("Entitlement still not active after refresh")
                        DebugLogger.log("   - Available entitlements: \(refreshedInfo.entitlements.all.keys.joined(separator: ", "))")
                        throw SubscriptionError.invalidResponse
                    }
                } else {
                    DebugLogger.error("Failed to refresh customer info")
                    throw SubscriptionError.invalidResponse
                }
            }
        } catch {
            // Track purchase failed
            AnalyticsService.shared.track("subscription_purchase_failed", properties: [
                "plan": plan,
                "error": error.localizedDescription
            ])
            
            await MainActor.run {
                errorMessage = error.localizedDescription
                isPurchasing = false
            }
        }
    }
    
    // MARK: - Restore Purchases
    
    private func restorePurchases() async {
        do {
            let customerInfo = try await Purchases.shared.restorePurchases()
            
            if customerInfo.entitlements[Config.revenueCatEntitlementID]?.isActive == true {
                DebugLogger.log("✅ Purchases restored - entitlement active")
                
                // Refresh subscription status
                _ = await subscriptionService.fetchSubscriptionStatus(forceRefresh: true)
                
                await MainActor.run {
                    NotificationCenter.default.post(name: NSNotification.Name("SubscriptionSuccess"), object: nil)
                    dismiss()
                }
            } else {
                await MainActor.run {
                    errorMessage = "No active subscription found to restore"
                }
            }
        } catch {
            await MainActor.run {
                errorMessage = "Failed to restore purchases: \(error.localizedDescription)"
            }
        }
    }
}

// MARK: - Package Card

struct PackageCard: View {
    let package: Package
    let isSelected: Bool
    let onSelect: () -> Void
    
    // Extract billing period from package identifier or product
    private var billingPeriod: String {
        let identifier = package.identifier.lowercased()
        let productId = package.storeProduct.productIdentifier.lowercased()
        
        if identifier.contains("yearly") || identifier.contains("annual") || 
           productId.contains("yearly") || productId.contains("annual") {
            return "year"
        }
        return "month"
    }
    
    // Calculate monthly equivalent for yearly plans
    private var monthlyEquivalent: String? {
        guard billingPeriod == "year" else { return nil }
        // Extract numeric value from price string and divide by 12
        // This is a simplified calculation - for production, consider using StoreKit 2's price APIs
        let priceString = package.storeProduct.localizedPriceString
        // Try to extract number from price string (e.g., "$49.99" -> 49.99)
        let numericString = priceString.replacingOccurrences(of: "[^0-9.]", with: "", options: .regularExpression)
        if let price = Double(numericString) {
            let monthly = price / 12.0
            let formatter = NumberFormatter()
            formatter.numberStyle = .currency
            // Use same currency symbol as original price
            if let currencySymbol = priceString.components(separatedBy: CharacterSet.decimalDigits).first?.trimmingCharacters(in: .whitespaces) {
                formatter.currencySymbol = currencySymbol.isEmpty ? "$" : currencySymbol
            }
            return formatter.string(from: NSNumber(value: monthly))
        }
        return nil
    }
    
    // Determine if this is a yearly plan (for savings badge)
    private var isYearly: Bool {
        billingPeriod == "year"
    }
    
    var body: some View {
        Button(action: onSelect) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(package.storeProduct.localizedTitle)
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        if isYearly {
                            Text("SAVE")
                                .font(.caption2)
                                .fontWeight(.bold)
                                .foregroundColor(.black)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Theme.Colors.accentGreen)
                                .cornerRadius(4)
                        }
                    }
                    
                    if !package.storeProduct.localizedDescription.isEmpty {
                        Text(package.storeProduct.localizedDescription)
                            .font(.subheadline)
                            .foregroundColor(Color.theme.textSecondary)
                            .lineLimit(2)
                    }
                    
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text(package.storeProduct.localizedPriceString)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(Theme.Colors.accentGreen)
                        
                        Text("/\(billingPeriod)")
                            .font(.subheadline)
                            .foregroundColor(Color.theme.textSecondary)
                    }
                    
                    if let monthly = monthlyEquivalent {
                        Text("\(monthly)/month")
                            .font(.caption)
                            .foregroundColor(Color.theme.textSecondary)
                    }
                }
                
                Spacer()
                
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundColor(isSelected ? Theme.Colors.accentGreen : Color.theme.textSecondary)
            }
            .padding()
            .background(isSelected ? Theme.Colors.accentGreen.opacity(0.1) : Theme.Colors.surface)
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Metrics.cornerRadius)
                    .stroke(isSelected ? Theme.Colors.accentGreen : Theme.Colors.border, lineWidth: isSelected ? 2 : 1)
            )
            .cornerRadius(Theme.Metrics.cornerRadius)
        }
    }
}

