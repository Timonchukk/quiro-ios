import ActivityKit
import Foundation

struct QuiroActivityAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        var status: RecordingStatus
        var framesProcessed: Int
        var statusText: String
        var answerText: String = ""

        enum RecordingStatus: String, Codable, Hashable {
            case recording
            case processing   // AI is thinking
            case idle
            case error
            case answered      // AI responded — show answer
        }
    }
    var appName: String = "Quiro"
}
