import AppIntents
import ActivityKit
import UIKit
import Foundation

/// AppIntent that runs when user taps "📸 Запитати AI" in Dynamic Island.
/// Executes in the MAIN APP process — has full access to LlmRepository, services, etc.
@available(iOS 17.0, *)
struct CaptureAndAskAIIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Запитати AI"
    static var description: IntentDescription = IntentDescription("Зробити скрін і запитати AI")

    func perform() async throws -> some IntentResult {
        // 1. Mark Live Activity as "processing"
        await MainActor.run {
            LiveActivityManager.shared.markProcessing()
        }

        // 2. Read the latest broadcast frame from App Group shared container
        let screenshot = readLatestFrameFromContainer()

        guard let screenshot else {
            // No frame available — show error
            await MainActor.run {
                LiveActivityManager.shared.markAnswered(text: "❌ Немає скріншота. Переконайтесь що трансляція активна.")
            }
            return .result()
        }

        // 3. Call AI API
        let llmRepo = LlmRepository.shared
        let result = await llmRepo.getVisionAnswer(screenshot: screenshot)

        switch result {
        case .success(let answer):
            // 4. Trim answer for Dynamic Island (max ~150 chars)
            let shortAnswer = trimForIsland(answer.answer)

            // 5. Save to history
            let entry = HistoryEntry(
                question: "📸 Dynamic Island",
                answer: answer.answer,
                explanation: answer.explanation,
                confidence: answer.confidence
            )
            await HistoryRepository.shared.save(entry)

            // 6. Update streak & trial
            await MainActor.run {
                SettingsRepository.shared.incrementTrialRequests()
                SettingsRepository.shared.updateStreak()
                LiveActivityManager.shared.markAnswered(text: shortAnswer)
            }

        case .failure(let error):
            await MainActor.run {
                LiveActivityManager.shared.markAnswered(
                    text: "❌ \(error.localizedDescription)"
                )
            }
        }

        return .result()
    }

    // MARK: - Helpers

    /// Read latest broadcast frame from App Group container (same as BroadcastReceiver)
    private func readLatestFrameFromContainer() -> UIImage? {
        guard let containerURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: "group.com.quiro.app"
        ) else { return nil }

        let fileURL = containerURL.appendingPathComponent("latest_frame.jpg")

        guard FileManager.default.fileExists(atPath: fileURL.path),
              let data = try? Data(contentsOf: fileURL),
              let image = UIImage(data: data) else { return nil }

        return image
    }

    /// Trim answer to fit Dynamic Island expanded view (~150 chars)
    private func trimForIsland(_ text: String) -> String {
        // Remove markdown formatting
        var clean = text
            .replacingOccurrences(of: "**", with: "")
            .replacingOccurrences(of: "##", with: "")
            .replacingOccurrences(of: "#", with: "")
            .replacingOccurrences(of: "`", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        // Take first meaningful portion
        if clean.count > 150 {
            clean = String(clean.prefix(147)) + "..."
        }

        return clean
    }
}

// MARK: - Stop Broadcast Intent

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
