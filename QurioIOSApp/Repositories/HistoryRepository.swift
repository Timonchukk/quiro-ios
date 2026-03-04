import Foundation
import SwiftData
import Combine

/// History repository mirroring HistoryRepository.kt (89 lines).
/// Local SwiftData persistence + server sync.
@MainActor
final class HistoryRepository: ObservableObject {
    static let shared = HistoryRepository()
    
    private var modelContainer: ModelContainer?
    private let settings = SettingsRepository.shared
    private let authRepo = AuthRepository.shared
    
    @Published var historyEntries: [HistoryEntry] = []
    @Published var testResults: [TestResultEntry] = []
    
    private init() {
        modelContainer = Self.createContainer()
        if let container = modelContainer {
            // Test if tables actually exist by doing a quick fetch
            let context = container.mainContext
            do {
                var descriptor = FetchDescriptor<HistoryEntry>()
                descriptor.fetchLimit = 1
                _ = try context.fetch(descriptor)
                print("✅ HistoryRepo: ModelContainer OK")
            } catch {
                // Tables missing — delete old store and recreate
                print("⚠️ HistoryRepo: Tables missing, recreating store...")
                Self.deleteStore()
                modelContainer = Self.createContainer()
                print("✅ HistoryRepo: Store recreated")
            }
            Task { await loadAll() }
        }
    }
    
    private static func createContainer() -> ModelContainer? {
        do {
            // MUST include ALL SwiftData models — they share the same default.store file
            return try ModelContainer(for: HistoryEntry.self, TestResultEntry.self, ContextEntry.self)
        } catch {
            print("❌ HistoryRepo: Failed to create ModelContainer: \(error)")
            return nil
        }
    }
    
    private static func deleteStore() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let storeURL = appSupport.appendingPathComponent("default.store")
        for ext in ["", "-wal", "-shm"] {
            let fileURL = ext.isEmpty ? storeURL : storeURL.appendingPathExtension(ext.replacingOccurrences(of: "-", with: ""))
            try? FileManager.default.removeItem(at: fileURL)
        }
        // Also try the exact paths SwiftData might use
        let altURL = appSupport.appendingPathComponent("default.store")
        try? FileManager.default.removeItem(at: altURL)
        try? FileManager.default.removeItem(at: URL(fileURLWithPath: altURL.path + "-wal"))
        try? FileManager.default.removeItem(at: URL(fileURLWithPath: altURL.path + "-shm"))
    }
    
    // MARK: - History
    
    func loadAll() async {
        guard let container = modelContainer else { return }
        let context = container.mainContext
        
        do {
            let histDescriptor = FetchDescriptor<HistoryEntry>(
                sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
            )
            historyEntries = try context.fetch(histDescriptor)
            
            let testDescriptor = FetchDescriptor<TestResultEntry>(
                sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
            )
            testResults = try context.fetch(testDescriptor)
        } catch {}
    }
    
    func save(_ entry: HistoryEntry) async {
        if settings.privacyMode { return }
        guard let container = modelContainer else { return }
        let context = container.mainContext
        context.insert(entry)
        try? context.save()
        await loadAll()
        
        // Push to server (fire-and-forget)
        Task {
            let syncEntry = HistorySyncEntry(
                question: entry.question,
                answer: entry.answer,
                explanation: entry.explanation,
                confidence: entry.confidence,
                appPackage: entry.appPackage,
                timestamp: entry.timestamp
            )
            await authRepo.pushHistoryToServer([syncEntry])
        }
    }
    
    func clearAll() async {
        guard let container = modelContainer else { return }
        let context = container.mainContext
        do {
            try context.delete(model: HistoryEntry.self)
            try? context.save()
            historyEntries = []
        } catch {}
    }
    
    // MARK: - Test Results
    
    func saveTestResult(_ entry: TestResultEntry) async {
        guard let container = modelContainer else { return }
        let context = container.mainContext
        context.insert(entry)
        try? context.save()
        await loadAll()
        
        // Push to server (fire-and-forget)
        Task {
            let syncEntry = TestResultSyncEntry(
                summaryTitle: entry.summaryTitle,
                score: entry.score,
                totalQuestions: entry.totalQuestions,
                percentage: entry.percentage,
                totalTimeMs: entry.totalTimeMs,
                avgTimeMs: entry.avgTimeMs,
                fastestMs: entry.fastestMs,
                slowestMs: entry.slowestMs,
                questionsJson: entry.questionsJson,
                timestamp: entry.timestamp
            )
            await authRepo.pushTestResultsToServer([syncEntry])
        }
    }
    
    // MARK: - Server Sync
    
    /// Pull history from server into local DB.
    /// Clears all local data first to prevent stale data from previous accounts.
    func syncFromServer() async {
        // Clear all local data first to prevent mixing accounts
        await clearLocalData()
        
        guard let container = modelContainer else {
            print("❌ HistoryRepo: No ModelContainer")
            return
        }
        let context = container.mainContext
        
        // Pull history
        let serverHistory = await authRepo.pullHistoryFromServer()
        print("📥 HistoryRepo: Inserting \(serverHistory.count) history entries into local DB")
        for entry in serverHistory {
            let he = HistoryEntry(
                question: entry.question,
                answer: entry.answer,
                explanation: entry.explanation ?? "",
                confidence: entry.confidence ?? 0,
                appPackage: entry.appPackage ?? "",
                timestamp: entry.timestamp
            )
            context.insert(he)
        }
        
        // Pull test results
        let serverTests = await authRepo.pullTestResultsFromServer()
        print("📥 HistoryRepo: Inserting \(serverTests.count) test results into local DB")
        for result in serverTests {
            let tr = TestResultEntry(
                summaryTitle: result.summaryTitle ?? "",
                score: result.score,
                totalQuestions: result.totalQuestions,
                percentage: result.percentage,
                totalTimeMs: result.totalTimeMs,
                avgTimeMs: result.avgTimeMs,
                fastestMs: result.fastestMs,
                slowestMs: result.slowestMs,
                questionsJson: result.questionsJson ?? "",
                timestamp: result.timestamp
            )
            context.insert(tr)
        }
        
        try? context.save()
        await loadAll()
        print("✅ HistoryRepo: Sync complete. Local: \(historyEntries.count) history, \(testResults.count) tests")
    }
    
    func pushAllToServer() async {
        let histEntries = historyEntries.map { e in
            HistorySyncEntry(
                question: e.question, answer: e.answer,
                explanation: e.explanation, confidence: e.confidence,
                appPackage: e.appPackage, timestamp: e.timestamp
            )
        }
        if !histEntries.isEmpty {
            await authRepo.pushHistoryToServer(histEntries)
        }
        
        let testEntries = testResults.map { r in
            TestResultSyncEntry(
                summaryTitle: r.summaryTitle, score: r.score,
                totalQuestions: r.totalQuestions, percentage: r.percentage,
                totalTimeMs: r.totalTimeMs, avgTimeMs: r.avgTimeMs,
                fastestMs: r.fastestMs, slowestMs: r.slowestMs,
                questionsJson: r.questionsJson, timestamp: r.timestamp
            )
        }
        if !testEntries.isEmpty {
            await authRepo.pushTestResultsToServer(testEntries)
        }
    }
    
    /// Clear ALL local data (history + tests + context) — call on logout / before account switch
    func clearLocalData() async {
        guard let container = modelContainer else { return }
        let context = container.mainContext
        do {
            try context.delete(model: HistoryEntry.self)
            try context.delete(model: TestResultEntry.self)
            try? context.save()
            historyEntries = []
            testResults = []
        } catch {}
        // Also clear context history
        await ContextRepository.shared.clearAll()
    }
}
