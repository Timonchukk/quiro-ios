import Foundation
import ReplayKit
import UIKit

/// Screen capture service using ReplayKit.
/// Fix 2: Capture starts ONLY via RPSystemBroadcastPickerView — no automatic broadcast start.
/// Integrates with BroadcastReceiver for frame retrieval from the extension.
@MainActor
final class ScreenCaptureService: ObservableObject {
    static let shared = ScreenCaptureService()

    @Published var isRecording = false
    @Published var capturedScreenshot: UIImage?
    @Published var summaryScreenshots: [UIImage] = []
    @Published var isSummaryMode = false
    @Published var summaryMaxCount = 5

    /// Whether the broadcast extension is currently active (read from BroadcastReceiver)
    var isBroadcastActive: Bool {
        BroadcastReceiver.shared.isBroadcastActive
    }

    private init() {}

    // MARK: - In-App Screenshot (fallback when broadcast is not active)

    /// Captures a screenshot of the current app window.
    /// This only captures the app's own UI, not other apps.
    func captureInAppScreenshot() -> UIImage? {
        guard let window = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first?.windows.first else { return nil }

        let renderer = UIGraphicsImageRenderer(size: window.bounds.size)
        let image = renderer.image { _ in
            window.drawHierarchy(in: window.bounds, afterScreenUpdates: true)
        }
        return image
    }

    // MARK: - Broadcast Frame (from extension via shared container)

    /// Reads the latest frame captured by the Broadcast Upload Extension.
    /// Returns nil if broadcast is not active or no frame available.
    func readBroadcastFrame() -> UIImage? {
        return BroadcastReceiver.shared.readLatestFrame()
    }

    /// Returns the best available screenshot:
    /// - If broadcast is active → reads from shared container
    /// - Otherwise → captures in-app screenshot
    func captureScreenshot() -> UIImage? {
        if isBroadcastActive, let frame = readBroadcastFrame() {
            return frame
        }
        return captureInAppScreenshot()
    }

    // MARK: - Stop Broadcast

    /// Requests the broadcast to stop.
    func stopBroadcast() {
        BroadcastReceiver.shared.requestStopBroadcast()
        isRecording = false
    }

    // MARK: - Summary Mode

    func startSummaryMode(maxScreenshots: Int = 5) {
        isSummaryMode = true
        summaryMaxCount = maxScreenshots
        summaryScreenshots = []
    }

    func addSummaryScreenshot(_ image: UIImage) {
        if summaryScreenshots.count < summaryMaxCount {
            summaryScreenshots.append(image)
        }
    }

    func completeSummaryMode() -> [UIImage] {
        let screenshots = summaryScreenshots
        summaryScreenshots = []
        isSummaryMode = false
        return screenshots
    }

    func cancelSummaryMode() {
        summaryScreenshots = []
        isSummaryMode = false
    }

    // MARK: - Broadcast Picker (Fix 2: ONLY way to start broadcast)

    /// Creates an RPSystemBroadcastPickerView targeting our extension.
    /// This is the ONLY approved method to start screen recording per Apple guidelines.
    static func makeBroadcastPicker() -> RPSystemBroadcastPickerView {
        let picker = RPSystemBroadcastPickerView(frame: CGRect(x: 0, y: 0, width: 44, height: 44))
        picker.preferredExtension = Config.broadcastExtensionBundleID
        picker.showsMicrophoneButton = false
        return picker
    }
}

// MARK: - Errors

enum ScreenCaptureError: Error, LocalizedError {
    case recorderUnavailable
    case captureFailed
    case permissionDenied
    case simulatorNotSupported

    var errorDescription: String? {
        switch self {
        case .recorderUnavailable: return "Запис екрану недоступний на цьому пристрої."
        case .captureFailed: return "Не вдалося зробити скріншот."
        case .permissionDenied: return "Дозвіл на запис екрану відхилено."
        case .simulatorNotSupported: return SimulatorGuard.unavailableMessage
        }
    }
}

// MARK: - Broadcast Picker SwiftUI Wrapper (Fix 2: explicit consent via system picker)

/// SwiftUI wrapper for RPSystemBroadcastPickerView.
/// This presents the system broadcast consent dialog — the ONLY way to start broadcast.
struct BroadcastPickerView: UIViewRepresentable {
    let buttonLabel: String

    init(buttonLabel: String = "Почати запис") {
        self.buttonLabel = buttonLabel
    }

    func makeUIView(context: Context) -> UIView {
        let container = UIView(frame: CGRect(x: 0, y: 0, width: 200, height: 44))

        let picker = RPSystemBroadcastPickerView(frame: container.bounds)
        picker.preferredExtension = Config.broadcastExtensionBundleID
        picker.showsMicrophoneButton = false
        picker.autoresizingMask = [.flexibleWidth, .flexibleHeight]

        // Make the system button transparent so our custom styling shows through
        for subview in picker.subviews {
            if let button = subview as? UIButton {
                button.setImage(nil, for: .normal)
                button.setTitle(nil, for: .normal)
                button.backgroundColor = .clear
            }
        }

        container.addSubview(picker)
        return container
    }

    func updateUIView(_ uiView: UIView, context: Context) {}
}
