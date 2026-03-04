import ActivityKit
import Foundation

// MARK: - Activity Attributes (shared between app and widget extension)
// This file must be added to BOTH targets: QuiroIOSApp AND QurioWidgetExtensionExtension

struct QuiroActivityAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        var status: RecordingStatus
        var framesProcessed: Int
        var statusText: String

        enum RecordingStatus: String, Codable, Hashable {
            case recording
            case processing
            case idle
            case error
        }
    }
    var appName: String = "Quiro"
}
