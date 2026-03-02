import SwiftUI

/// Fix 7: Simulator compatibility guard.
/// Detects simulator environment and disables broadcast features.
enum SimulatorGuard {

    /// Returns true if running on iOS Simulator
    static var isSimulator: Bool {
        #if targetEnvironment(simulator)
        return true
        #else
        return false
        #endif
    }

    /// Returns true if broadcast capture is available on this device
    static var isBroadcastAvailable: Bool {
        !isSimulator
    }

    /// Human-readable reason when broadcast is unavailable
    static var unavailableMessage: String {
        "Запис екрану потребує реальний iPhone. Ця функція недоступна на симуляторі."
    }
}

// MARK: - SwiftUI View Modifier

/// Wraps broadcast-dependent UI — shows inline message on simulator
struct BroadcastAvailabilityModifier: ViewModifier {
    func body(content: Content) -> some View {
        if SimulatorGuard.isBroadcastAvailable {
            content
        } else {
            VStack(spacing: 12) {
                Image(systemName: "iphone.slash")
                    .font(.system(size: 32))
                    .foregroundColor(.secondary)

                Text(SimulatorGuard.unavailableMessage)
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
        }
    }
}

extension View {
    /// Replaces content with a simulator warning when broadcast is unavailable
    func requiresRealDevice() -> some View {
        modifier(BroadcastAvailabilityModifier())
    }
}
