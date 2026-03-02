import SwiftUI

// MARK: - Glass Components (mirrors GlassComponents.kt)

/// Full glass card with shadow — for main content areas
struct GlassCard<Content: View>: View {
    @Environment(\.appTheme) var theme
    let cornerRadius: CGFloat
    let content: () -> Content
    
    init(cornerRadius: CGFloat = 20, @ViewBuilder content: @escaping () -> Content) {
        self.cornerRadius = cornerRadius
        self.content = content
    }
    
    var body: some View {
        content()
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(.ultraThinMaterial)
                    
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(theme.isDark ? 0.08 : 0.4),
                                    Color.white.opacity(theme.isDark ? 0.02 : 0.15)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(theme.isDark ? 0.2 : 0.5),
                                    Color.white.opacity(theme.isDark ? 0.05 : 0.15)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .shadow(color: Color.black.opacity(0.12), radius: 12, y: 6)
    }
}

/// Glass section — lighter, no shadow, for inline sections
struct GlassSection<Content: View>: View {
    @Environment(\.appTheme) var theme
    let cornerRadius: CGFloat
    let content: () -> Content
    
    init(cornerRadius: CGFloat = 16, @ViewBuilder content: @escaping () -> Content) {
        self.cornerRadius = cornerRadius
        self.content = content
    }
    
    var body: some View {
        content()
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(.thinMaterial)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(Color.white.opacity(theme.isDark ? 0.1 : 0.3), lineWidth: 0.5)
            )
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
    }
}

/// Accent gradient button
struct AccentButton: View {
    let title: String
    let icon: String?
    let isLoading: Bool
    let enabled: Bool
    let action: () -> Void
    
    init(
        _ title: String,
        icon: String? = nil,
        isLoading: Bool = false,
        enabled: Bool = true,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.isLoading = isLoading
        self.enabled = enabled
        self.action = action
    }
    
    var body: some View {
        Button(action: { if enabled && !isLoading { action() } }) {
            HStack(spacing: 8) {
                if isLoading {
                    ProgressView()
                        .tint(.white)
                        .scaleEffect(0.8)
                } else {
                    if let icon {
                        Image(systemName: icon)
                            .font(.system(size: 16, weight: .semibold))
                    }
                    Text(title)
                        .font(.system(size: 16, weight: .semibold))
                }
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 15)
            .background(
                LinearGradient(
                    colors: enabled ? [.accentPurple, .violet] : [.gray, .gray.opacity(0.7)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .shadow(color: (enabled ? Color.accentPurple : .gray).opacity(0.3), radius: 8, y: 4)
        }
        .disabled(!enabled || isLoading)
    }
}

/// Outlined secondary button
struct OutlinedButton: View {
    @Environment(\.appTheme) var theme
    let title: String
    let icon: String?
    let action: () -> Void
    
    init(_ title: String, icon: String? = nil, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let icon {
                    Image(systemName: icon)
                        .font(.system(size: 15))
                }
                Text(title)
                    .font(.system(size: 15, weight: .medium))
            }
            .foregroundColor(.accentPurple)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 13)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.ultraThinMaterial)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.accentPurple.opacity(0.4), lineWidth: 1)
            )
        }
    }
}

/// Chip badge — compact pill with icon + label
struct ChipBadge: View {
    let icon: String
    let label: String
    let tint: Color
    let bgAlpha: Double
    var onClick: (() -> Void)? = nil
    
    init(_ label: String, icon: String, tint: Color, bgAlpha: Double = 0.1, onClick: (() -> Void)? = nil) {
        self.label = label
        self.icon = icon
        self.tint = tint
        self.bgAlpha = bgAlpha
        self.onClick = onClick
    }
    
    var body: some View {
        let content = HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .semibold))
            Text(label)
                .font(.system(size: 12, weight: .semibold))
        }
        .foregroundColor(tint)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(
            Capsule().fill(tint.opacity(bgAlpha))
        )
        
        if let onClick {
            Button(action: onClick) { content }
        } else {
            content
        }
    }
}
