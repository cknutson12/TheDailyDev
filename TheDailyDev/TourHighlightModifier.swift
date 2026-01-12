//
//  TourHighlightModifier.swift
//  TheDailyDev
//
//  Direct element highlighting for onboarding tour
//

import SwiftUI

/// View modifier that adds a blinking glow effect to highlight elements during the tour
struct TourHighlightModifier: ViewModifier {
    let isHighlighted: Bool
    let glowColor: Color
    let cornerRadius: CGFloat
    let verticalPadding: CGFloat
    
    @State private var glowOpacity: Double = 0.6
    @State private var isAnimating = false
    
    init(
        isHighlighted: Bool,
        glowColor: Color = Theme.Colors.accentGreen,
        cornerRadius: CGFloat = Theme.Metrics.cornerRadius,
        verticalPadding: CGFloat = 0
    ) {
        self.isHighlighted = isHighlighted
        self.glowColor = glowColor
        self.cornerRadius = cornerRadius
        self.verticalPadding = verticalPadding
    }
    
    func body(content: Content) -> some View {
        content
            .overlay(
                Group {
                    if isHighlighted {
                        ZStack {
                            // Border stroke - glows and blinks (opacity animates)
                            // Matches the full button size (no padding to inset it)
                            RoundedRectangle(cornerRadius: cornerRadius)
                                .stroke(glowColor.opacity(glowOpacity), lineWidth: 2)
                                .padding(.vertical, verticalPadding) // Only add extra vertical padding if needed
                                .shadow(color: glowColor.opacity(glowOpacity * 0.6), radius: 8, x: 0, y: 0) // Glow effect on border
                        }
                    }
                }
                .allowsHitTesting(false) // Don't block touches
            )
            .onAppear {
                if isHighlighted {
                    startBlinking()
                }
            }
            .onChange(of: isHighlighted) { oldValue, newValue in
                if newValue {
                    startBlinking()
                } else {
                    isAnimating = false
                    withAnimation {
                        glowOpacity = 0.0
                    }
                }
            }
    }
    
    private func startBlinking() {
        guard !isAnimating else { return }
        isAnimating = true
        glowOpacity = 0.6
        
        // Start the animation loop
        animateBlink()
    }
    
    private func animateBlink() {
        guard isAnimating else { return }
        
        withAnimation(.easeInOut(duration: 1.2)) {
            glowOpacity = glowOpacity == 0.6 ? 1.0 : 0.6
        }
        
        // Schedule next animation after current one completes
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            guard self.isAnimating else { return }
            self.animateBlink()
        }
    }
}

extension View {
    /// Add tour highlighting to a view
    func tourHighlight(isHighlighted: Bool, glowColor: Color = Theme.Colors.accentGreen, verticalPadding: CGFloat = 0) -> some View {
        modifier(TourHighlightModifier(isHighlighted: isHighlighted, glowColor: glowColor, verticalPadding: verticalPadding))
    }
}

