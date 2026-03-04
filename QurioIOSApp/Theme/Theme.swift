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
    static let darkSurface = Color(red: 0x0E/255, green: 0x0E/255, blue: 0x1A/255)
    static let darkCard = Color(red: 0x1A/255, green: 0x1A/255, blue: 0x2E/255)
    static let darkOverlay = Color(red: 0x22/255, green: 0x22/255, blue: 0x3A/255)
    
    // Light theme
    static let lightSurface = Color(red: 0xF2/255, green: 0xF0/255, blue: 0xF7/255)
    static let lightCard = Color.white
}

// MARK: - Design Tokens

enum DesignTokens {
    // Corner radii
    static let radiusSmall: CGFloat = 10
    static let radiusMedium: CGFloat = 14
    static let radiusLarge: CGFloat = 20
    static let radiusXL: CGFloat = 26
    
    // Padding
    static let paddingSmall: CGFloat = 8
    static let paddingMedium: CGFloat = 14
    static let paddingLarge: CGFloat = 20
    static let paddingXL: CGFloat = 24
    
    // Spacing
    static let spacingTight: CGFloat = 6
    static let spacingMedium: CGFloat = 12
    static let spacingLarge: CGFloat = 20
    static let spacingXL: CGFloat = 28
}

// MARK: - App Theme

struct AppTheme {
    let isDark: Bool
    
    var background: Color { isDark ? .darkSurface : .lightSurface }
    var cardBackground: Color { isDark ? .darkCard : .lightCard }
    var textPrimary: Color { isDark ? .white : Color(red: 0.1, green: 0.1, blue: 0.12) }
    var textSecondary: Color { isDark ? Color.white.opacity(0.65) : Color.black.opacity(0.55) }
    var textTertiary: Color { isDark ? Color.white.opacity(0.35) : Color.black.opacity(0.3) }
    var divider: Color { isDark ? Color.white.opacity(0.08) : Color.black.opacity(0.06) }
    
    // Glass fills — opaque enough for text contrast, but with glass feel
    var glassBackground: Color {
        isDark
            ? Color(red: 0.12, green: 0.12, blue: 0.2).opacity(0.85)
            : Color.white.opacity(0.72)
    }
    
    // High-contrast mode glass (for Increase Contrast accessibility)
    var glassBackgroundSolid: Color {
        isDark ? .darkCard : .lightCard
    }
    
    var glassBorder: Color {
        isDark ? Color.white.opacity(0.12) : Color.black.opacity(0.06)
    }
    
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
    @Environment(\.accessibilityContrast) var contrast: AccessibilityContrast
    let cornerRadius: CGFloat
    
    func body(content: Content) -> some View {
        let backgroundFill = (contrast == .increased) ? theme.glassBackgroundSolid : theme.glassBackground
        
        return content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(backgroundFill)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(theme.glassBorder, lineWidth: 0.5)
            )
            .shadow(color: Color.black.opacity(0.1), radius: 8, y: 4)
    }
}

extension View {
    func cardStyle(cornerRadius: CGFloat = DesignTokens.radiusLarge) -> some View {
        modifier(CardModifier(cornerRadius: cornerRadius))
    }
}

// MARK: - Haptic Feedback

enum HapticManager {
    static func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {
        UIImpactFeedbackGenerator(style: style).impactOccurred()
    }
    
    static func notification(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        UINotificationFeedbackGenerator().notificationOccurred(type)
    }
    
    static func selection() {
        UISelectionFeedbackGenerator().selectionChanged()
    }
}
