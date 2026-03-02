import ActivityKit
import SwiftUI

/// Fix 4: Live Activity data model for Dynamic Island.
/// Defines the attributes and state displayed in the Dynamic Island and Lock Screen.
struct QuiroActivityAttributes: ActivityAttributes {
    /// Static data that doesn't change during the activity
    struct ContentState: Codable, Hashable {
        /// Current recording status
        var status: RecordingStatus
        /// Number of frames processed
        var framesProcessed: Int
        /// Latest AI processing state description
        var statusText: String

        enum RecordingStatus: String, Codable, Hashable {
            case recording
            case processing
            case idle
            case error
        }
    }

    /// App name shown in compact presentation
    var appName: String = "Quiro"
}

// MARK: - Live Activity Widget Definition

/// The actual Live Activity widget that renders in the Dynamic Island and Lock Screen.
/// This must be included in a Widget Extension target.
struct QuiroLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: QuiroActivityAttributes.self) { context in
            // Lock Screen / Banner presentation
            lockScreenView(context: context)
        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded presentation
                DynamicIslandExpandedRegion(.leading) {
                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 20))
                        .foregroundColor(.purple)
                }
                DynamicIslandExpandedRegion(.center) {
                    VStack(spacing: 2) {
                        Text(context.state.statusText)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                        Text("Кадрів: \(context.state.framesProcessed)")
                            .font(.system(size: 11))
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
                DynamicIslandExpandedRegion(.trailing) {
                    // Recording indicator
                    Circle()
                        .fill(statusColor(context.state.status))
                        .frame(width: 12, height: 12)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    // Stop button — terminates broadcast
                    Button(intent: StopBroadcastIntent()) {
                        HStack(spacing: 6) {
                            Image(systemName: "stop.fill")
                                .font(.system(size: 12))
                            Text("Зупинити запис")
                                .font(.system(size: 13, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(Color.red.opacity(0.8))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                }
            } compactLeading: {
                Image(systemName: "brain.head.profile")
                    .font(.system(size: 14))
                    .foregroundColor(.purple)
            } compactTrailing: {
                Circle()
                    .fill(statusColor(context.state.status))
                    .frame(width: 8, height: 8)
            } minimal: {
                Image(systemName: "brain.head.profile")
                    .font(.system(size: 12))
                    .foregroundColor(.purple)
            }
        }
    }

    // MARK: - Lock Screen View

    @ViewBuilder
    private func lockScreenView(context: ActivityViewContext<QuiroActivityAttributes>) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "brain.head.profile")
                .font(.system(size: 24))
                .foregroundColor(.purple)

            VStack(alignment: .leading, spacing: 2) {
                Text("Quiro")
                    .font(.system(size: 15, weight: .bold))
                Text(context.state.statusText)
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            }

            Spacer()

            Circle()
                .fill(statusColor(context.state.status))
                .frame(width: 12, height: 12)
        }
        .padding(16)
        .activityBackgroundTint(.black.opacity(0.75))
    }

    // MARK: - Helpers

    private func statusColor(_ status: QuiroActivityAttributes.ContentState.RecordingStatus) -> Color {
        switch status {
        case .recording: return .red
        case .processing: return .orange
        case .idle: return .green
        case .error: return .yellow
        }
    }
}

// MARK: - Stop Broadcast App Intent (iOS 17+)

import AppIntents

/// App Intent triggered by the "Stop" button in Dynamic Island
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
