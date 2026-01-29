//
//  TourOverlayView.swift
//  TheDailyDev
//
//  Overlay view for onboarding tour with spotlight and tooltip
//

import SwiftUI

struct TourOverlayView: View {
    @ObservedObject var tourManager: OnboardingTourManager
    let onDismiss: (() -> Void)?
    
    init(tourManager: OnboardingTourManager = .shared, onDismiss: (() -> Void)? = nil) {
        self.tourManager = tourManager
        self.onDismiss = onDismiss
    }
    
    var body: some View {
        Group {
            // Only render if tour is active - this prevents blocking after completion
            if !tourManager.isTourActive {
                Color.clear
                    .allowsHitTesting(false)
            } else if let step = tourManager.currentStep {
                // Debug logging
                let _ = DebugLogger.log("🎨 TourOverlayView body - isTourActive: \(tourManager.isTourActive), currentStepIndex: \(tourManager.currentStepIndex)")
                let _ = DebugLogger.log("   Showing step: \(step.id) - \(step.title)")
                
                // Only show tooltip - no black overlay, highlighting is done directly on elements
                let isTopTooltip = step.targetViewIdentifier == "SelfAssessmentChart"
                
                ZStack {
                    // Transparent background that allows touches to pass through except on tooltip
                    Color.clear
                        .contentShape(Rectangle())
                        .allowsHitTesting(false) // Allow touches to pass through to views below
                    
                    VStack {
                        if !isTopTooltip {
                            Spacer()
                        }
                        
                        TooltipView(
                            step: step,
                            currentStepIndex: tourManager.currentStepIndex,
                            totalSteps: TourStep.allSteps.count,
                            onNext: {
                                tourManager.nextStep()
                            },
                            onSkip: {
                                tourManager.skipTour()
                                onDismiss?()
                            }
                        )
                        .padding(.horizontal, 20)
                        .padding(.bottom, isTopTooltip ? 12 : 40)
                        .padding(.top, isTopTooltip ? 40 : 0)
                        .allowsHitTesting(true) // Allow touches on tooltip buttons
                        
                        if isTopTooltip {
                            Spacer()
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .transition(.opacity)
            } else {
                // No step - show nothing and don't block
                Color.clear
                    .allowsHitTesting(false)
            }
        }
    }
}


// MARK: - Tooltip View
struct TooltipView: View {
    let step: TourStep
    let currentStepIndex: Int
    let totalSteps: Int
    let onNext: () -> Void
    let onSkip: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Title
            Text(step.title)
                .font(.title2)
                .bold()
                .foregroundColor(.white)
            
            // Message
            Text(step.message)
                .font(.body)
                .foregroundColor(Theme.Colors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
            
            // Progress indicator
            HStack {
                Text("Step \(currentStepIndex + 1) of \(totalSteps)")
                    .font(.caption)
                    .foregroundColor(Theme.Colors.textSecondary)
                
                Spacer()
                
                // Progress dots
                HStack(spacing: 6) {
                    ForEach(0..<totalSteps, id: \.self) { index in
                        Circle()
                            .fill(index <= currentStepIndex ? Theme.Colors.accentGreen : Color.gray.opacity(0.3))
                            .frame(width: 6, height: 6)
                    }
                }
            }
            
            // Action buttons
            HStack(spacing: 12) {
                // Skip button
                Button(action: onSkip) {
                    Text("Skip Tour")
                        .font(.subheadline)
                        .foregroundColor(Theme.Colors.textSecondary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                }
                
                Spacer()
                
                // Next/Got it button
                Button(action: onNext) {
                    Text(currentStepIndex == totalSteps - 1 ? "Got it!" : "Next")
                        .font(.headline)
                        .foregroundColor(.black)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(Theme.Colors.accentGreen)
                        .cornerRadius(Theme.Metrics.cornerRadius)
                }
            }
        }
        .padding(20)
        .background(Theme.Colors.surface)
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Metrics.cornerRadius)
                .stroke(Theme.Colors.accentGreen, lineWidth: 2)
        )
        .cornerRadius(Theme.Metrics.cornerRadius)
        .shadow(color: .black.opacity(0.5), radius: 20, x: 0, y: 10)
    }
}

// MARK: - Preview
struct TourOverlayView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.blue.ignoresSafeArea()
            
            VStack {
                Text("Sample Content")
                    .padding()
                    .background(Color.green)
                    .cornerRadius(8)
            }
            
            TourOverlayView()
        }
    }
}

