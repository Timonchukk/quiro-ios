import SwiftUI

// MARK: - Glass Components

/// Full glass card with shadow — for main content areas
struct GlassCard<Content: View>: View {
    @Environment(\.appTheme) var theme
    @Environment(\.accessibilityContrast) var contrast
    let cornerRadius: CGFloat
    let content: () -> Content
    
    init(cornerRadius: CGFloat = DesignTokens.radiusLarge, @ViewBuilder content: @escaping () -> Content) {
        self.cornerRadius = cornerRadius
        self.content = content
    }
    
    var body: some View {
        content()
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(contrast == .increased
                              ? theme.glassBackgroundSolid
                              : theme.glassBackground)
                    
                    if contrast != .increased {
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(theme.isDark ? 0.06 : 0.3),
                                        Color.white.opacity(theme.isDark ? 0.01 : 0.08)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }
                    
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .stroke(theme.glassBorder, lineWidth: 0.5)
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .shadow(color: Color.black.opacity(theme.isDark ? 0.2 : 0.08), radius: 12, y: 6)
    }
}

/// Glass section — lighter, no shadow, for inline sections
struct GlassSection<Content: View>: View {
    @Environment(\.appTheme) var theme
    @Environment(\.accessibilityContrast) var contrast
    let cornerRadius: CGFloat
    let content: () -> Content
    
    init(cornerRadius: CGFloat = DesignTokens.radiusMedium, @ViewBuilder content: @escaping () -> Content) {
        self.cornerRadius = cornerRadius
        self.content = content
    }
    
    var body: some View {
        content()
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(contrast == .increased
                          ? theme.glassBackgroundSolid
                          : theme.glassBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(theme.glassBorder, lineWidth: 0.5)
            )
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
    }
}

/// Accent gradient button with haptic feedback
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
        Button(action: {
            if enabled && !isLoading {
                HapticManager.impact(.medium)
                action()
            }
        }) {
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
            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.radiusMedium))
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
        Button(action: {
            HapticManager.selection()
            action()
        }) {
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
                RoundedRectangle(cornerRadius: DesignTokens.radiusMedium)
                    .fill(theme.glassBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: DesignTokens.radiusMedium)
                    .stroke(Color.accentPurple.opacity(0.35), lineWidth: 1)
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
    
    init(_ label: String, icon: String, tint: Color, bgAlpha: Double = 0.12, onClick: (() -> Void)? = nil) {
        self.label = label
        self.icon = icon
        self.tint = tint
        self.bgAlpha = bgAlpha
        self.onClick = onClick
    }
    
    var body: some View {
        let content = HStack(spacing: 5) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .bold))
            Text(label)
                .font(.system(size: 12, weight: .semibold))
        }
        .foregroundColor(tint)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            Capsule().fill(tint.opacity(bgAlpha))
        )
        
        if let onClick {
            Button(action: {
                HapticManager.selection()
                onClick()
            }) { content }
        } else {
            content
        }
    }
}


// MARK: - Icon Circle

struct IconCircle: View {
    let icon: String
    let tint: Color
    let size: CGFloat
    
    init(_ icon: String, tint: Color, size: CGFloat = 36) {
        self.icon = icon
        self.tint = tint
        self.size = size
    }
    
    var body: some View {
        Image(systemName: icon)
            .font(.system(size: size * 0.42, weight: .semibold))
            .foregroundColor(tint)
            .frame(width: size, height: size)
            .background(
                Circle()
                    .fill(tint.opacity(0.12))
            )
    }
}
