//
//  ViewFramePreferenceKey.swift
//  TheDailyDev
//
//  PreferenceKey for passing view frame information up the view hierarchy
//

import SwiftUI

/// PreferenceKey to pass view frame information up the view hierarchy
struct ViewFramePreferenceKey: PreferenceKey {
    static var defaultValue: [String: CGRect] = [:]
    
    static func reduce(value: inout [String: CGRect], nextValue: () -> [String: CGRect]) {
        value.merge(nextValue(), uniquingKeysWith: { $1 })
    }
}

/// View modifier to attach frame information to a view
struct ViewFrameModifier: ViewModifier {
    let identifier: String
    
    func body(content: Content) -> some View {
        content
            .background(
                GeometryReader { geometry in
                    Color.clear
                        .preference(
                            key: ViewFramePreferenceKey.self,
                            value: [identifier: geometry.frame(in: .global)]
                        )
                }
            )
    }
}

extension View {
    /// Attach frame tracking to a view with an identifier
    func trackFrame(identifier: String) -> some View {
        modifier(ViewFrameModifier(identifier: identifier))
    }
}

