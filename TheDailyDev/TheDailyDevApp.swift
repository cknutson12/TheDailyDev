//
//  TheDailyDevApp.swift
//  TheDailyDev
//
//  Created by Claire Knutson on 10/14/25.
//

import SwiftUI

@main
struct TheDailyDevApp: App {
    @StateObject private var subscriptionService = SubscriptionService.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onOpenURL { url in
                    handleStripeReturn(url: url)
                }
        }
    }
    
    // MARK: - Handle Stripe Return
    private func handleStripeReturn(url: URL) {
        print("🔗 Received deep link: \(url)")
        guard url.scheme == "thedailydev" else {
            print("❌ Invalid scheme: \(url.scheme ?? "nil")")
            return
        }
        
        let host = url.host ?? ""
        print("📋 Host: \(host)")
        
        switch host {
        case "subscription-success":
            print("✅ Subscription successful - fetching status...")
            Task {
                let subscription = await subscriptionService.fetchSubscriptionStatus()
                print("📊 Fetched subscription: \(subscription?.status ?? "none")")
                if subscription != nil {
                    print("✅ Active subscription found!")
                } else {
                    print("⚠️ No subscription found - webhook may not have processed yet")
                }
            }
        case "subscription-cancel":
            print("❌ Subscription canceled")
        default:
            print("⚠️ Unknown host: \(host)")
            break
        }
    }
}
