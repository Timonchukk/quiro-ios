import AppIntents
import Foundation

/// Stub intent for widget extension compilation.
/// The REAL perform() runs in the MAIN APP process (StopBroadcastIntent.swift in QurioIOSApp).
/// This stub just needs to exist so Button(intent:) compiles in the widget.
@available(iOS 17.0, *)
struct StopBroadcastIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Зупинити запис"
    static var description = IntentDescription("Зупиняє запис екрану Quiro")

    func perform() async throws -> some IntentResult {
        // This never actually runs here — the main app's version executes instead.
        return .result()
    }
}
