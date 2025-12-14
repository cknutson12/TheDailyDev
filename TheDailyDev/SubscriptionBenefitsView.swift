//
//  SubscriptionBenefitsView.swift
//  TheDailyDev
//
//  Created by Claire Knutson on 10/25/25.
//

import SwiftUI

struct SubscriptionBenefitsView: View {
    let onSkip: (() -> Void)?
    
    init(onSkip: (() -> Void)? = nil) {
        self.onSkip = onSkip
    }
    
    var body: some View {
        ZStack {
            Color.theme.background.ignoresSafeArea()
            
            // Show RevenueCat native paywall (all data from RevenueCat)
            RevenueCatPaywallView()
                .onDisappear {
                    // Handle dismiss if needed
                }
        }
        .preferredColorScheme(.dark)
    }
    
}

// MARK: - Preview
struct SubscriptionBenefitsView_Previews: PreviewProvider {
    static var previews: some View {
        SubscriptionBenefitsView(
            onSkip: { print("Skip tapped") }
        )
    }
}
