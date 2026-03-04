import Foundation
import UIKit
import Combine

/// Receives broadcast frames written by the Broadcast Upload Extension.
/// Listens via Darwin notifications and reads JPEG from the App Group shared container.
/// DOES NOT access SwiftData or repositories — passes frames out via publisher.
@MainActor
final class BroadcastReceiver: ObservableObject {
    static let shared = BroadcastReceiver()

    // MARK: - Published State

    @Published var isBroadcastActive = false
    @Published var latestFrame: UIImage?
    @Published var frameTimestamp: TimeInterval = 0

    /// Fires each time a new frame arrives from the broadcast extension
    let frameReceived = PassthroughSubject<UIImage, Never>()

    // MARK: - Private

    private let defaults: UserDefaults?
    private var pollTimer: Timer?
    private var lastReadTimestamp: TimeInterval = 0
    private var darwinObserverToken: UnsafeMutableRawPointer?

    private init() {
        defaults = UserDefaults(suiteName: Config.appGroupID)

        // Start monitoring broadcast state
        startPollingBroadcastState()

        // Register Darwin notification listener for frame updates
        registerDarwinObserver()
    }

    deinit {
        pollTimer?.invalidate()
        // Call directly to avoid @MainActor isolation issue in deinit
        let center = CFNotificationCenterGetDarwinNotifyCenter()
        CFNotificationCenterRemoveEveryObserver(center, Unmanaged.passUnretained(self).toOpaque())
    }

    // MARK: - Broadcast State Polling

    /// Poll broadcast_active flag every 0.5s — lightweight, no IPC overhead
    private func startPollingBroadcastState() {
        pollTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.checkBroadcastState()
            }
        }
    }

    private func checkBroadcastState() {
        let active = defaults?.bool(forKey: Config.broadcastActiveKey) ?? false
        if active != isBroadcastActive {
            isBroadcastActive = active

            if !active {
                // Broadcast ended — clear frame
                latestFrame = nil
                lastReadTimestamp = 0
            }
        }
    }

    // MARK: - Darwin Notification Observer

    private func registerDarwinObserver() {
        let center = CFNotificationCenterGetDarwinNotifyCenter()
        let name = CFNotificationName(Config.darwinNotificationName as CFString)
        let observer = Unmanaged.passUnretained(self).toOpaque()

        // Use a static callback — Swift closures can't be used directly
        CFNotificationCenterAddObserver(
            center,
            observer,
            { _, observerPtr, _, _, _ in
                // Called on arbitrary thread — dispatch to main
                guard let observerPtr else { return }
                let receiver = Unmanaged<BroadcastReceiver>.fromOpaque(observerPtr).takeUnretainedValue()
                Task { @MainActor in
                    receiver.onNewFrameNotification()
                }
            },
            name.rawValue,
            nil,
            .deliverImmediately
        )
    }

    private func unregisterDarwinObserver() {
        let center = CFNotificationCenterGetDarwinNotifyCenter()
        CFNotificationCenterRemoveEveryObserver(center, Unmanaged.passUnretained(self).toOpaque())
    }

    // MARK: - Frame Loading

    private func onNewFrameNotification() {
        guard isBroadcastActive else { return }

        // Check timestamp to avoid re-reading same frame
        let timestamp = defaults?.double(forKey: Config.latestFrameTimestampKey) ?? 0
        guard timestamp > lastReadTimestamp else { return }
        lastReadTimestamp = timestamp

        // Load JPEG from shared container
        guard let containerURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: Config.appGroupID
        ) else { return }

        let fileURL = containerURL.appendingPathComponent(Config.latestFrameFilename)

        guard FileManager.default.fileExists(atPath: fileURL.path),
              let data = try? Data(contentsOf: fileURL),
              let image = UIImage(data: data) else { return }

        latestFrame = image
        frameTimestamp = timestamp
        frameReceived.send(image)
    }

    // MARK: - Manual Frame Request

    /// Force-read the latest frame (e.g. user taps capture button while broadcast is active)
    func readLatestFrame() -> UIImage? {
        guard let containerURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: Config.appGroupID
        ) else { return nil }

        let fileURL = containerURL.appendingPathComponent(Config.latestFrameFilename)

        guard FileManager.default.fileExists(atPath: fileURL.path),
              let data = try? Data(contentsOf: fileURL),
              let image = UIImage(data: data) else { return nil }

        return image
    }

    // MARK: - Stop Broadcast

    /// Signal the extension to stop (best-effort — system controls actual stop)
    func requestStopBroadcast() {
        defaults?.set(false, forKey: Config.broadcastActiveKey)
        defaults?.synchronize()
        isBroadcastActive = false
        latestFrame = nil
    }
}
