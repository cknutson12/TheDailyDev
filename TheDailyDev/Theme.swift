import SwiftUI

// MARK: - Theme Tokens
enum Theme {
    enum Colors {
        static let background = Color.black // #000000
        static let surface = Color(red: 0.078, green: 0.078, blue: 0.078) // ~#141414 - slightly lighter for better visibility
        static let border = Color(red: 0.122, green: 0.122, blue: 0.122) // ~#1F1F1F
        static let textPrimary = Color.white
        static let textSecondary = Color(red: 0.607, green: 0.639, blue: 0.686) // ~#9BA3AF
        static let accentGreen = Color(red: 0.215, green: 0.749, blue: 0.518) // #37BF84
        static let stateCorrect = Color(red: 0.215, green: 0.749, blue: 0.518) // #37BF84
        static let stateIncorrect = Color(red: 0.980, green: 0.376, blue: 0.376) // #fa6060
        static let subtleBlue = Color(red: 0.051, green: 0.067, blue: 0.090) // #0D1117
    }
    
    enum Metrics {
        static let cornerRadius: CGFloat = 12
        static let spacing8: CGFloat = 8
        static let spacing12: CGFloat = 12
        static let spacing16: CGFloat = 16
        static let spacing24: CGFloat = 24
    }
}

// MARK: - Convenience Accessors
extension Color {
    static let theme = Theme.Colors.self
}

// MARK: - Card Container Modifier
struct CardContainer: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(Theme.Metrics.spacing16)
            .background(Theme.Colors.surface)
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Metrics.cornerRadius)
                    .stroke(Theme.Colors.border, lineWidth: 1)
            )
            .cornerRadius(Theme.Metrics.cornerRadius)
    }
}

extension View {
    func cardContainer() -> some View { modifier(CardContainer()) }
}

// MARK: - Button Styles
struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundColor(.black)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(Theme.Colors.accentGreen.opacity(configuration.isPressed ? 0.85 : 1))
            .cornerRadius(Theme.Metrics.cornerRadius)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundColor(Theme.Colors.textPrimary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(Theme.Colors.surface.opacity(configuration.isPressed ? 0.9 : 1))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Metrics.cornerRadius)
                    .stroke(Theme.Colors.border, lineWidth: 1)
            )
            .cornerRadius(Theme.Metrics.cornerRadius)
    }
}

// MARK: - Dark TextField Style
struct DarkTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<_Label>) -> some View {
        configuration
            .padding(12)
            .background(Theme.Colors.surface)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Theme.Colors.border, lineWidth: 1)
            )
            .foregroundColor(Theme.Colors.textPrimary)
            .cornerRadius(10)
    }
}


