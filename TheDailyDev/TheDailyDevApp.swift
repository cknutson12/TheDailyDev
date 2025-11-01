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
                    Task {
                        await handleDeepLink(url: url)
                    }
                }
        }
    }
    
    // MARK: - Handle Deep Links
    private func handleDeepLink(url: URL) async {
        print("🔗 Received deep link: \(url)")
        print("   - scheme: \(url.scheme ?? "nil")")
        print("   - host: \(url.host ?? "nil")")
        print("   - path: \(url.path)")
        
        // Handle Supabase OAuth redirects
        if url.scheme == "com.supabase.thedailydev" && url.host == "oauth-callback" {
            print("🔐 OAuth callback received: \(url.absoluteString)")
            await AuthManager.shared.handleOAuthCallback(url: url)
            return
        }
        
        // Handle Stripe return
        guard url.scheme == "thedailydev" else {
            print("❌ Invalid scheme: \(url.scheme ?? "nil")")
            return
        }
        
        let host = url.host ?? ""
        print("📋 Host: \(host)")
        
        switch host {
        case "subscription-success":
            print("✅ Subscription successful - fetching status...")
            let subscription = await subscriptionService.fetchSubscriptionStatus()
            print("📊 Fetched subscription: \(subscription?.status ?? "none")")
            if subscription != nil {
                print("✅ Active subscription found!")
            } else {
                print("⚠️ No subscription found - webhook may not have processed yet")
            }
        case "subscription-cancel":
            print("❌ Subscription canceled")
        default:
            print("⚠️ Unknown host: \(host)")
            break
        }
    }
}
