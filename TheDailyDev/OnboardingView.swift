//
//  OnboardingView.swift
//  TheDailyDev
//
//  Created for onboarding flow
//

import SwiftUI

struct OnboardingView: View {
    let onContinue: () -> Void
    
    var body: some View {
        ZStack {
            // Match app's gradient background
            LinearGradient(
                colors: [
                    Color.black,
                    Color(red: 0.08, green: 0.20, blue: 0.14)  // Lighter dark green tint at bottom
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    Spacer()
                        .frame(height: 40)
                    
                    // Welcome Title
                    VStack(spacing: 8) {
                        Text("Welcome to")
                            .font(.title2)
                            .foregroundColor(Theme.Colors.textSecondary)
                        
                        Text("The Daily Dev")
                            .font(.system(size: 36, weight: .bold, design: .monospaced))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [
                                        Theme.Colors.accentGreen,
                                        Theme.Colors.accentGreen.opacity(0.75),
                                        Theme.Colors.subtleBlue.opacity(0.9)
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .shadow(color: Theme.Colors.accentGreen.opacity(0.3), radius: 8, x: 0, y: 4)
                    }
                    .padding(.bottom, 8)
                    
                    // Personal Message Card
                    VStack(alignment: .leading, spacing: 20) {
                        Text("Now more than ever, system design is an important part of the interview process. It's important for developers of all skill levels to hone their knowledge, stay up with the times, and continuously improve. Just take a minute each morning to challenge your knowledge or learn something new.")
                            .font(.body)
                            .foregroundColor(Theme.Colors.textPrimary)
                            .lineSpacing(6)
                        
                        // Author Signature
                        HStack {
                            Spacer()
                            VStack(alignment: .trailing, spacing: 4) {
                                Text("— Arjay McCandless")
                                    .font(.headline)
                                    .foregroundColor(Theme.Colors.accentGreen)
                            }
                        }
                        .padding(.top, 8)
                    }
                    .padding(Theme.Metrics.spacing24)
                    .background(Theme.Colors.surface)
                    .overlay(
                        RoundedRectangle(cornerRadius: Theme.Metrics.cornerRadius)
                            .stroke(Theme.Colors.border, lineWidth: 1)
                    )
                    .cornerRadius(Theme.Metrics.cornerRadius)
                    .padding(.horizontal, Theme.Metrics.spacing16)
                    
                    // Get Started Button
                    Button(action: {
                        AnalyticsService.shared.track("onboarding_completed")
                        onContinue()
                    }) {
                        Text("Get Started")
                            .font(.headline)
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Theme.Colors.accentGreen)
                            .cornerRadius(Theme.Metrics.cornerRadius)
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, Theme.Metrics.spacing16)
                    .padding(.top, 8)
                    
                    Spacer()
                        .frame(height: 40)
                }
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            AnalyticsService.shared.track("onboarding_viewed")
        }
    }
}

// MARK: - Preview
struct OnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingView(onContinue: {
            DebugLogger.log("Get Started tapped")
        })
    }
}

