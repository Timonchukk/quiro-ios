import WidgetKit
import SwiftUI
import ActivityKit
import AppIntents

// Import shared ActivityAttributes from main app
// QuiroActivityAttributes is defined in QurioIOSApp/LiveActivity/LiveActivityManager.swift

@main
struct QurioLiveActivityBundle: WidgetBundle {
    var body: some Widget {
        QurioLiveActivityWidget()
    }
}

struct QurioLiveActivityWidget: Widget {
    // Blue accent colors matching Theme.swift
    private static let accentBlue = Color(red: 0.20, green: 0.49, blue: 0.96)
    private static let accentSky  = Color(red: 0.33, green: 0.67, blue: 0.98)

    var body: some WidgetConfiguration {
        ActivityConfiguration(for: QuiroActivityAttributes.self) { context in
            // Lock Screen / Banner view
            lockScreenView(context: context)
        } dynamicIsland: { context in
            DynamicIsland {
                // ═══════════════════════════════════════
                // EXPANDED VIEW (long press on Dynamic Island)
                // ═══════════════════════════════════════

                DynamicIslandExpandedRegion(.leading) {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(statusColor(context.state.status))
                            .frame(width: 10, height: 10)
                        Text("Qurio")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                    }
                }

                DynamicIslandExpandedRegion(.trailing) {
                    Image(systemName: statusIcon(context.state.status))
                        .font(.system(size: 18))
                        .foregroundColor(statusColor(context.state.status))
                }

                DynamicIslandExpandedRegion(.center) {
                    Text(context.state.statusText)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.white.opacity(0.9))
                        .lineLimit(1)
                }

                DynamicIslandExpandedRegion(.bottom) {
                    expandedBottomContent(context: context)
                }
            } compactLeading: {
                // Compact leading (left side of pill)
                HStack(spacing: 4) {
                    Circle()
                        .fill(statusColor(context.state.status))
                        .frame(width: 8, height: 8)
                    Text("Q")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(Self.accentBlue)
                }
            } compactTrailing: {
                // Compact trailing (right side of pill)
                Image(systemName: statusIcon(context.state.status))
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(statusColor(context.state.status))
            } minimal: {
                // Minimal view (when multiple Live Activities)
                ZStack {
                    Circle()
                        .fill(statusColor(context.state.status).opacity(0.3))
                        .frame(width: 16, height: 16)
                    Circle()
                        .fill(statusColor(context.state.status))
                        .frame(width: 8, height: 8)
                }
            }
        }
    }

    // MARK: - Expanded Bottom Content (Interactive!)

    @ViewBuilder
    private func expandedBottomContent(context: ActivityViewContext<QuiroActivityAttributes>) -> some View {
        switch context.state.status {
        case .processing:
            // AI is thinking — show spinner
            HStack(spacing: 8) {
                ProgressView()
                    .tint(Self.accentBlue)
                    .scaleEffect(0.8)
                Text("AI думає...")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
            }
            .padding(.top, 4)

        case .answered:
            // AI responded — show answer + "Ask again" button
            VStack(spacing: 10) {
                // Answer text
                HStack(alignment: .top, spacing: 6) {
                    Text("💡")
                        .font(.system(size: 13))
                    Text(context.state.answerText)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white)
                        .lineLimit(4)
                        .multilineTextAlignment(.leading)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 4)

                // "Ask again" + Stop buttons
                if #available(iOS 17.0, *) {
                    HStack(spacing: 8) {
                        Button(intent: CaptureAndAskAIIntent()) {
                            HStack(spacing: 6) {
                                Image(systemName: "camera.fill")
                                    .font(.system(size: 12, weight: .bold))
                                Text("Запитати ще")
                                    .font(.system(size: 13, weight: .semibold))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(
                                LinearGradient(
                                    colors: [Self.accentBlue, Self.accentSky],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                        .buttonStyle(.plain)

                        Button(intent: StopBroadcastIntent()) {
                            Image(systemName: "stop.fill")
                                .font(.system(size: 12))
                                .foregroundColor(.white)
                                .padding(8)
                                .background(Color.red.opacity(0.8))
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(.top, 2)

        case .error:
            // Error state
            VStack(spacing: 8) {
                Text(context.state.statusText)
                    .font(.system(size: 12))
                    .foregroundColor(.red.opacity(0.8))
                    .lineLimit(2)

                if #available(iOS 17.0, *) {
                    Button(intent: CaptureAndAskAIIntent()) {
                        HStack(spacing: 6) {
                            Image(systemName: "arrow.counterclockwise")
                                .font(.system(size: 11, weight: .bold))
                            Text("Спробувати ще")
                                .font(.system(size: 13, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(Self.accentBlue)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    .buttonStyle(.plain)
                }
            }

        default:
            // Recording / Idle — show "Ask AI" + Stop buttons
            VStack(spacing: 8) {
                if #available(iOS 17.0, *) {
                    Button(intent: CaptureAndAskAIIntent()) {
                        HStack(spacing: 8) {
                            Image(systemName: "camera.fill")
                                .font(.system(size: 13, weight: .bold))
                            Text("📸 Запитати AI")
                                .font(.system(size: 14, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            LinearGradient(
                                colors: [Self.accentBlue, Self.accentSky],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .buttonStyle(.plain)

                    Button(intent: StopBroadcastIntent()) {
                        HStack(spacing: 6) {
                            Image(systemName: "stop.fill")
                                .font(.system(size: 11))
                            Text("Зупинити")
                                .font(.system(size: 12, weight: .medium))
                        }
                        .foregroundColor(.red.opacity(0.8))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.top, 4)
        }
    }

    // MARK: - Lock Screen View

    @ViewBuilder
    private func lockScreenView(context: ActivityViewContext<QuiroActivityAttributes>) -> some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(statusColor(context.state.status).opacity(0.2))
                        .frame(width: 40, height: 40)
                    Image(systemName: statusIcon(context.state.status))
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(statusColor(context.state.status))
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("Qurio")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.primary)
                    Text(context.state.statusText)
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }

                Spacer()

                if context.state.status == .processing {
                    ProgressView()
                        .tint(Self.accentBlue)
                } else if context.state.status == .recording {
                    Circle()
                        .fill(.red)
                        .frame(width: 12, height: 12)
                        .overlay(
                            Circle()
                                .stroke(.red.opacity(0.3), lineWidth: 3)
                        )
                }
            }
            .padding(16)

            // Show answer on lock screen too
            if context.state.status == .answered && !context.state.answerText.isEmpty {
                HStack(alignment: .top, spacing: 6) {
                    Text("💡")
                        .font(.system(size: 13))
                    Text(context.state.answerText)
                        .font(.system(size: 13))
                        .foregroundColor(.primary)
                        .lineLimit(3)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16)
                .padding(.bottom, 12)
            }

            // Interactive buttons on lock screen
            if context.state.status != .processing {
                if #available(iOS 17.0, *) {
                    HStack(spacing: 8) {
                        Button(intent: CaptureAndAskAIIntent()) {
                            HStack(spacing: 6) {
                                Image(systemName: "camera.fill")
                                    .font(.system(size: 12, weight: .bold))
                                Text("📸 Запитати AI")
                                    .font(.system(size: 13, weight: .semibold))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(
                                LinearGradient(
                                    colors: [Self.accentBlue, Self.accentSky],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                        .buttonStyle(.plain)

                        Button(intent: StopBroadcastIntent()) {
                            Image(systemName: "stop.fill")
                                .font(.system(size: 12))
                                .foregroundColor(.white)
                                .padding(.vertical, 10)
                                .padding(.horizontal, 14)
                                .background(Color.red.opacity(0.8))
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 12)
                }
            }
        }
        .background(Color(.secondarySystemBackground))
    }

    // MARK: - Helpers

    private func statusColor(_ status: QuiroActivityAttributes.ContentState.RecordingStatus) -> Color {
        switch status {
        case .recording: return .green
        case .processing: return Self.accentBlue
        case .idle: return .gray
        case .error: return .red
        case .answered: return Self.accentSky
        }
    }

    private func statusIcon(_ status: QuiroActivityAttributes.ContentState.RecordingStatus) -> String {
        switch status {
        case .recording: return "camera.viewfinder"
        case .processing: return "brain"
        case .idle: return "circle"
        case .error: return "exclamationmark.triangle.fill"
        case .answered: return "checkmark.circle.fill"
        }
    }
}
