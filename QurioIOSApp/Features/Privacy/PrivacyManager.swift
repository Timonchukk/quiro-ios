import Foundation
import Combine

/// Fix 3: Privacy & consent manager.
/// Tracks whether the user has accepted the screen capture consent disclosure.
/// Consent is stored per-session (not persisted) to ensure explicit acknowledgement each time.
@MainActor
final class PrivacyManager: ObservableObject {
    static let shared = PrivacyManager()

    /// Whether the user has given consent for screen capture in this session
    @Published var hasConsentedThisSession = false

    /// Whether the consent sheet should be shown
    @Published var showingConsentSheet = false

    /// Callback when consent is granted
    var onConsentGranted: (() -> Void)?

    private init() {}

    // MARK: - Request Consent

    /// Call before opening the broadcast picker.
    /// If consent has not been given this session, shows the consent view.
    /// If already consented, immediately calls the completion.
    func requestConsent(onGranted: @escaping () -> Void) {
        if hasConsentedThisSession {
            onGranted()
            return
        }

        onConsentGranted = onGranted
        showingConsentSheet = true
    }

    /// Called by CaptureConsentView when user explicitly accepts
    func grantConsent() {
        hasConsentedThisSession = true
        showingConsentSheet = false
        onConsentGranted?()
        onConsentGranted = nil
    }

    /// Called by CaptureConsentView when user declines
    func denyConsent() {
        hasConsentedThisSession = false
        showingConsentSheet = false
        onConsentGranted = nil
    }

    /// Reset consent (e.g. when broadcast stops)
    func resetConsent() {
        hasConsentedThisSession = false
    }
}
