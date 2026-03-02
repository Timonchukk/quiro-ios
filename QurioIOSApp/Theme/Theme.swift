import SwiftUI

// MARK: - Color Palette (mirrors Theme.kt)

extension Color {
    static let accentPurple = Color(red: 0x7C/255, green: 0x4D/255, blue: 0xFF/255) // #7C4DFF
    static let violet = Color(red: 0xBB/255, green: 0x86/255, blue: 0xFC/255)       // #BB86FC
    static let accentRed = Color(red: 0xF4/255, green: 0x43/255, blue: 0x36/255)    // #F44336
    static let summaryGreen = Color(red: 0x10/255, green: 0xB9/255, blue: 0x81/255) // #10B981
    static let yellowDot = Color(red: 0xE5/255, green: 0xA1/255, blue: 0x00/255)    // #E5A100
    static let streakOrange = Color(red: 0xFF/255, green: 0x6D/255, blue: 0x00/255) // #FF6D00
    
    // Dark theme surface colors
    static let darkSurface = Color(red: 0x1A/255, green: 0x1A/255, blue: 0x2E/255)
    static let darkCard = Color(red: 0x24/255, green: 0x24/255, blue: 0x3E/255)
    static let darkOverlay = Color(red: 0x2A/255, green: 0x2A/255, blue: 0x44/255)
    
    // Light theme
    static let lightSurface = Color(red: 0xF5/255, green: 0xF5/255, blue: 0xFA/255)
    static let lightCard = Color.white
}

// MARK: - App Theme

struct AppTheme {
    let isDark: Bool
    
    var background: Color { isDark ? .darkSurface : .lightSurface }
    var cardBackground: Color { isDark ? .darkCard : .lightCard }
    var textPrimary: Color { isDark ? .white : .black }
    var textSecondary: Color { isDark ? Color.white.opacity(0.7) : Color.black.opacity(0.6) }
    var textTertiary: Color { isDark ? Color.white.opacity(0.4) : Color.black.opacity(0.35) }
    var divider: Color { isDark ? Color.white.opacity(0.1) : Color.black.opacity(0.08) }
    
    var accentGradient: LinearGradient {
        LinearGradient(
            colors: [.accentPurple, .violet],
            startPoint: .leading,
            endPoint: .trailing
        )
    }
    
    var proGradient: LinearGradient {
        LinearGradient(
            colors: [Color(red: 1, green: 0.84, blue: 0), Color(red: 1, green: 0.6, blue: 0)],
            startPoint: .leading,
            endPoint: .trailing
        )
    }
}

// MARK: - Theme Environment Key

struct ThemeKey: EnvironmentKey {
    static let defaultValue = AppTheme(isDark: true)
}

extension EnvironmentValues {
    var appTheme: AppTheme {
        get { self[ThemeKey.self] }
        set { self[ThemeKey.self] = newValue }
    }
}

// MARK: - Common Modifiers

struct CardModifier: ViewModifier {
    @Environment(\.appTheme) var theme
    let cornerRadius: CGFloat
    
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(theme.cardBackground.opacity(0.8))
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(theme.divider, lineWidth: 0.5)
            )
    }
}

extension View {
    func cardStyle(cornerRadius: CGFloat = 16) -> some View {
        modifier(CardModifier(cornerRadius: cornerRadius))
    }
}
