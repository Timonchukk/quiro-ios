import ActivityKit
import Foundation
import Combine

/// Fix 4: Manages Live Activity lifecycle for Dynamic Island integration.
/// Starts when broadcast begins, updates during AI processing, stops when broadcast ends.
@MainActor
final class LiveActivityManager: ObservableObject {
    static let shared = LiveActivityManager()

    @Published var isActivityActive = false

    private var currentActivity: Activity<QuiroActivityAttributes>?
    private let broadcastReceiver = BroadcastReceiver.shared

    private init() {}

    // MARK: - Start Live Activity

    /// Call when broadcast starts (after user confirms via RPSystemBroadcastPickerView)
    func startLiveActivity() {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            print("LiveActivity: Activities not enabled")
            return
        }

        // End any existing activity first
        endExistingActivities()

        let attributes = QuiroActivityAttributes()
        let initialState = QuiroActivityAttributes.ContentState(
            status: .recording,
            framesProcessed: 0,
            statusText: "Запис екрану активний"
        )

        do {
            let activity = try Activity.request(
                attributes: attributes,
                content: .init(state: initialState, staleDate: nil),
                pushType: nil
            )
            currentActivity = activity
            isActivityActive = true
            print("LiveActivity: Started with id \(activity.id)")
        } catch {
            print("LiveActivity: Failed to start — \(error)")
        }
    }

    // MARK: - Update Live Activity

    /// Update the Dynamic Island state (e.g. when AI is processing)
    func updateStatus(_ status: QuiroActivityAttributes.ContentState.RecordingStatus, text: String, frames: Int = 0) {
        guard let activity = currentActivity else { return }

        let updatedState = QuiroActivityAttributes.ContentState(
            status: status,
            framesProcessed: frames,
            statusText: text
        )

        Task {
            await activity.update(
                ActivityContent(state: updatedState, staleDate: nil)
            )
        }
    }

    /// Convenience: mark as "AI processing"
    func markProcessing(framesProcessed: Int = 0) {
        updateStatus(.processing, text: "AI обробляє...", frames: framesProcessed)
    }

    /// Convenience: mark as "recording/idle"
    func markRecording(framesProcessed: Int = 0) {
        updateStatus(.recording, text: "Запис екрану активний", frames: framesProcessed)
    }

    /// Convenience: mark as "error"
    func markError(message: String = "Помилка") {
        updateStatus(.error, text: message)
    }

    // MARK: - Stop Live Activity

    /// End the current Live Activity and signal broadcast to stop
    func stopAll() {
        // Stop broadcast
        broadcastReceiver.requestStopBroadcast()
        ScreenCaptureService.shared.stopBroadcast()

        // End Live Activity
        endExistingActivities()
        isActivityActive = false
    }

    /// End the Live Activity without stopping broadcast
    func endLiveActivity() {
        endExistingActivities()
        isActivityActive = false
    }

    // MARK: - Internal

    private func endExistingActivities() {
        let finalState = QuiroActivityAttributes.ContentState(
            status: .idle,
            framesProcessed: 0,
            statusText: "Запис завершено"
        )

        // End current tracked activity
        if let activity = currentActivity {
            Task {
                await activity.end(
                    ActivityContent(state: finalState, staleDate: nil),
                    dismissalPolicy: .immediate
                )
            }
            currentActivity = nil
        }

        // Also end any orphaned activities
        Task {
            for activity in Activity<QuiroActivityAttributes>.activities {
                await activity.end(
                    ActivityContent(state: finalState, staleDate: nil),
                    dismissalPolicy: .immediate
                )
            }
        }
    }
}
