import ReplayKit
import UIKit
import CoreMedia

/// ReplayKit Broadcast Upload Extension handler.
/// Receives CMSampleBuffer frames, compresses to JPEG, writes to App Group container.
/// MUST NOT access SwiftData, repositories, or UI objects.
class SampleHandler: RPBroadcastSampleHandler {

    // MARK: - Constants (duplicated from Config — extension cannot import main app target)

    private let appGroupID = "group.com.quiro.app"
    private let broadcastActiveKey = "broadcast_active"
    private let latestFrameTimestampKey = "latest_frame_timestamp"
    private let latestFrameFilename = "latest_frame.jpg"
    private let darwinNotificationName = "com.quiro.app.newframe"

    // MARK: - Frame Throttle (Fix 6: Memory Safety)

    /// Maximum capture rate: 1 frame per second
    private let minFrameIntervalSeconds: TimeInterval = 1.0
    private var lastFrameTime: TimeInterval = 0

    /// Target downscale size (longest edge)
    private let maxFrameEdge: CGFloat = 1280

    /// Reusable CIContext — avoid re-creating per frame
    private lazy var ciContext = CIContext(options: [.useSoftwareRenderer: false])

    // MARK: - Lifecycle

    override func broadcastStarted(withSetupInfo setupInfo: [String: NSObject]?) {
        let defaults = UserDefaults(suiteName: appGroupID)
        defaults?.set(true, forKey: broadcastActiveKey)
        defaults?.synchronize()
    }

    override func broadcastPaused() {
        // No-op — keep state active
    }

    override func broadcastResumed() {
        // No-op
    }

    override func broadcastFinished() {
        let defaults = UserDefaults(suiteName: appGroupID)
        defaults?.set(false, forKey: broadcastActiveKey)
        defaults?.removeObject(forKey: latestFrameTimestampKey)
        defaults?.synchronize()

        // Clean up frame file
        if let containerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupID) {
            let fileURL = containerURL.appendingPathComponent(latestFrameFilename)
            try? FileManager.default.removeItem(at: fileURL)
        }
    }

    // MARK: - Frame Processing

    override func processSampleBuffer(_ sampleBuffer: CMSampleBuffer, with sampleBufferType: RPSampleBufferType) {
        // Only process video frames
        guard sampleBufferType == .video else { return }

        // Fix 6: Throttle to max 1 fps
        let now = CACurrentMediaTime()
        guard (now - lastFrameTime) >= minFrameIntervalSeconds else { return }
        lastFrameTime = now

        // Extract pixel buffer — do NOT retain the CMSampleBuffer
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

        // Convert to CGImage via CIImage (reuse ciContext)
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        let extent = ciImage.extent
        guard let cgImage = ciContext.createCGImage(ciImage, from: extent) else { return }

        // Downscale if necessary (Fix 6: reduce memory)
        let downscaled = downscaleIfNeeded(cgImage, maxEdge: maxFrameEdge)

        // Compress to JPEG (quality 0.6 — good balance of size/quality)
        let uiImage = UIImage(cgImage: downscaled)
        guard let jpegData = uiImage.jpegData(compressionQuality: 0.6) else { return }

        // Write to App Group shared container
        guard let containerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupID) else { return }
        let fileURL = containerURL.appendingPathComponent(latestFrameFilename)

        do {
            try jpegData.write(to: fileURL, options: .atomic)
        } catch {
            return
        }

        // Update timestamp flag
        let defaults = UserDefaults(suiteName: appGroupID)
        defaults?.set(Date().timeIntervalSince1970, forKey: latestFrameTimestampKey)
        defaults?.synchronize()

        // Notify main app via Darwin notification
        postDarwinNotification(darwinNotificationName)
    }

    // MARK: - Downscale Helper

    private func downscaleIfNeeded(_ image: CGImage, maxEdge: CGFloat) -> CGImage {
        let w = CGFloat(image.width)
        let h = CGFloat(image.height)
        let longestEdge = max(w, h)

        guard longestEdge > maxEdge else { return image }

        let scale = maxEdge / longestEdge
        let newW = Int(w * scale)
        let newH = Int(h * scale)

        guard let colorSpace = image.colorSpace,
              let ctx = CGContext(
                  data: nil,
                  width: newW,
                  height: newH,
                  bitsPerComponent: 8,
                  bytesPerRow: 0,
                  space: colorSpace,
                  bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue
              ) else {
            return image
        }

        ctx.interpolationQuality = .medium
        ctx.draw(image, in: CGRect(x: 0, y: 0, width: newW, height: newH))
        return ctx.makeImage() ?? image
    }

    // MARK: - Darwin Notification

    private func postDarwinNotification(_ name: String) {
        guard let center = CFNotificationCenterGetDarwinNotifyCenter() as CFNotificationCenter? else { return }
        CFNotificationCenterPostNotification(
            center,
            CFNotificationName(name as CFString),
            nil,
            nil,
            true
        )
    }
}
