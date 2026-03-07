import AppIntents
import ActivityKit
import Foundation

/// App Intent that stops the broadcast when user taps "Stop" in Dynamic Island.
/// Executes in the MAIN APP process — has full access to LiveActivityManager.
@available(iOS 17.0, *)
struct StopBroadcastIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Зупинити запис"
    static var description = IntentDescription("Зупиняє запис екрану Quiro")

    func perform() async throws -> some IntentResult {
        await MainActor.run {
            LiveActivityManager.shared.stopAll()
        }
        return .result()
    }
}
