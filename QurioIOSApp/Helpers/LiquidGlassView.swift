import SwiftUI

// MARK: - Liquid Glass Card

/// Frosted glass card component with blur and gradient overlay.
/// Mirrors GlassComponents.kt glass morphism effects.
struct LiquidGlassCard<Content: View>: View {
    let cornerRadius: CGFloat
    let opacity: Double
    let content: () -> Content
    
    init(
        cornerRadius: CGFloat = 20,
        opacity: Double = 0.85,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.cornerRadius = cornerRadius
        self.opacity = opacity
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
                                    Color.white.opacity(0.15),
                                    Color.white.opacity(0.05)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.3),
                                    Color.white.opacity(0.1)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .shadow(color: Color.black.opacity(0.15), radius: 10, y: 5)
    }
}

// MARK: - Glass Surface

/// Lighter glass surface without shadow — for inline sections.
struct GlassSurface<Content: View>: View {
    let cornerRadius: CGFloat
    let content: () -> Content
    
    init(
        cornerRadius: CGFloat = 16,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.cornerRadius = cornerRadius
        self.content = content
    }
    
    var body: some View {
        content()
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(.thinMaterial)
                    
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .stroke(Color.white.opacity(0.15), lineWidth: 0.5)
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
    }
}

// MARK: - Glass Button

/// Button with frosted glass background and accent gradient.
struct GlassButton: View {
    let title: String
    let icon: String?
    let gradient: LinearGradient
    let action: () -> Void
    
    init(
        title: String,
        icon: String? = nil,
        gradient: LinearGradient = LinearGradient(
            colors: [Color.accentPurple, Color.accentPurple.opacity(0.7)],
            startPoint: .leading,
            endPoint: .trailing
        ),
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.gradient = gradient
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let icon {
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .semibold))
                }
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(gradient)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .shadow(color: Color.accentPurple.opacity(0.3), radius: 8, y: 4)
        }
    }
}

// MARK: - Glass Text Field

/// Text field with frosted glass appearance.
struct GlassTextField: View {
    let placeholder: String
    @Binding var text: String
    var isSecure: Bool = false
    var keyboardType: UIKeyboardType = .default
    
    var body: some View {
        Group {
            if isSecure {
                SecureField(placeholder, text: $text)
            } else {
                TextField(placeholder, text: $text)
                    .keyboardType(keyboardType)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.15), lineWidth: 0.5)
        )
        .autocapitalization(.none)
        .disableAutocorrection(true)
    }
}

// MARK: - Shimmer Effect

struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = 0
    
    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geo in
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0),
                            Color.white.opacity(0.15),
                            Color.white.opacity(0)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: geo.size.width * 0.6)
                    .offset(x: -geo.size.width * 0.3 + geo.size.width * 1.6 * phase)
                }
                .mask(content)
            )
            .onAppear {
                withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                    phase = 1
                }
            }
    }
}

extension View {
    func shimmer() -> some View {
        modifier(ShimmerModifier())
    }
}
