import AppIntents
import Foundation

/// Stub intent for widget extension compilation.
/// The REAL perform() runs in the MAIN APP process (CaptureIntent.swift in QurioIOSApp).
/// This stub just needs to exist so Button(intent:) compiles in the widget.
@available(iOS 17.0, *)
struct CaptureAndAskAIIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Запитати AI"
    static var description = IntentDescription("Зробити скрін і запитати AI")

    func perform() async throws -> some IntentResult {
        // This never actually runs here — the main app's version executes instead.
        return .result()
    }
}
