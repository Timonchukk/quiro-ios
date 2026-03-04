import Foundation
import SwiftData

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
        do {
            modelContainer = try ModelContainer(for: HistoryEntry.self, TestResultEntry.self)
            Task { await loadAll() }
        } catch {
            print("HistoryRepository: Failed to create ModelContainer: \(error)")
        }
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
        
        guard let container = modelContainer else { return }
        let context = container.mainContext
        
        // Pull history
        let serverHistory = await authRepo.pullHistoryFromServer()
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
