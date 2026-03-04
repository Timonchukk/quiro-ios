import WidgetKit
import SwiftUI
import ActivityKit

// Import shared ActivityAttributes from main app
// QuiroActivityAttributes is defined in QurioIOSApp/LiveActivity/LiveActivityManager.swift

@main
struct QurioLiveActivityBundle: WidgetBundle {
    var body: some Widget {
        QurioLiveActivityWidget()
    }
}

struct QurioLiveActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: QuiroActivityAttributes.self) { context in
            // Lock Screen / Banner view
            lockScreenView(context: context)
        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded view (long press on Dynamic Island)
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
                    if context.state.status == .processing {
                        ProgressView()
                            .tint(.purple)
                            .scaleEffect(0.8)
                    }
                }
            } compactLeading: {
                // Compact leading (left side of pill)
                HStack(spacing: 4) {
                    Circle()
                        .fill(statusColor(context.state.status))
                        .frame(width: 8, height: 8)
                    Text("Q")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(.purple)
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
    
    // MARK: - Lock Screen View
    
    @ViewBuilder
    private func lockScreenView(context: ActivityViewContext<QuiroActivityAttributes>) -> some View {
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
                    .tint(.purple)
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
        .background(Color(.secondarySystemBackground))
    }
    
    // MARK: - Helpers
    
    private func statusColor(_ status: QuiroActivityAttributes.ContentState.RecordingStatus) -> Color {
        switch status {
        case .recording: return .green
        case .processing: return .purple
        case .idle: return .gray
        case .error: return .red
        }
    }
    
    private func statusIcon(_ status: QuiroActivityAttributes.ContentState.RecordingStatus) -> String {
        switch status {
        case .recording: return "camera.viewfinder"
        case .processing: return "brain"
        case .idle: return "circle"
        case .error: return "exclamationmark.triangle.fill"
        }
    }
}
