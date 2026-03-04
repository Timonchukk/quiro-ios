import Foundation
import SwiftData

/// Context repository mirroring ContextRepository.kt (75 lines).
/// Manages conversation context buffer for AI prompts.
@MainActor
final class ContextRepository {
    static let shared = ContextRepository()
    
    private var modelContainer: ModelContainer?
    private var cleanupTask: Task<Void, Never>?
    
    private init() {
        do {
            // MUST include ALL SwiftData models — they share the same default.store file
            modelContainer = try ModelContainer(for: ContextEntry.self, HistoryEntry.self, TestResultEntry.self)
        } catch {
            print("ContextRepository: Failed to create ModelContainer: \(error)")
        }
    }
    
    // MARK: - Add Entry
    
    func addEntry(question: String, answer: String) async {
        guard let container = modelContainer else { return }
        let context = container.mainContext
        let entry = ContextEntry(questionText: question, answerText: answer)
        context.insert(entry)
        try? context.save()
    }
    
    // MARK: - Get Context Text
    
    func getContextText(maxEntries: Int = 6, maxChars: Int = 1400) async -> String {
        guard let container = modelContainer else { return "" }
        let context = container.mainContext
        
        do {
            var descriptor = FetchDescriptor<ContextEntry>(
                sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
            )
            descriptor.fetchLimit = maxEntries
            let entries = try context.fetch(descriptor).reversed()
            
            if entries.isEmpty { return "" }
            
            var sb = "=== PREVIOUS CONTEXT (use this to understand the topic/subject) ===\n"
            for (index, entry) in entries.enumerated() {
                let q = String(entry.questionText.prefix(180))
                let a = String(entry.answerText.prefix(260))
                sb += "\(index + 1). Q: \(q) → A: \(a)\n"
            }
            sb += "=== END OF CONTEXT ===\n\n"
            
            return sb.count > maxChars ? String(sb.suffix(maxChars)) : sb
        } catch {
            return ""
        }
    }
    
    // MARK: - Auto Cleanup
    
    func startAutoCleanup() {
        cleanupTask?.cancel()
        cleanupTask = Task {
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 60_000_000_000) // 60 seconds
                guard !Task.isCancelled else { break }
                await deleteOldest()
            }
        }
    }
    
    func stopAutoCleanup() {
        cleanupTask?.cancel()
        cleanupTask = nil
    }
    
    private func deleteOldest() async {
        guard let container = modelContainer else { return }
        let context = container.mainContext
        
        do {
            var descriptor = FetchDescriptor<ContextEntry>(
                sortBy: [SortDescriptor(\.timestamp, order: .forward)]
            )
            descriptor.fetchLimit = 1
            let oldest = try context.fetch(descriptor)
            if let entry = oldest.first {
                context.delete(entry)
                try? context.save()
            }
        } catch {}
    }
    
    func clearAll() async {
        guard let container = modelContainer else { return }
        let context = container.mainContext
        do {
            try context.delete(model: ContextEntry.self)
            try? context.save()
        } catch {}
    }
}
