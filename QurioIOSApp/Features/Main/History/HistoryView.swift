import SwiftUI
import UIKit

/// History screen mirroring HistoryScreen.kt.
/// Two sub-tabs: AI queries and Test results, with PDF export.
struct HistoryView: View {
    @EnvironmentObject var historyRepo: HistoryRepository
    @EnvironmentObject var settings: SettingsRepository
    @Environment(\.appTheme) var theme
    
    @State private var selectedTab = 0
    @State private var searchText = ""
    @State private var showExportSheet = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("Історія")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(theme.textPrimary)
                    Spacer()
                    
                    if !historyRepo.historyEntries.isEmpty || !historyRepo.testResults.isEmpty {
                        Button(action: { showExportSheet = true }) {
                            Image(systemName: "square.and.arrow.up")
                                .font(.system(size: 18))
                                .foregroundColor(.accentPurple)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                
                // Segmented Control
                Picker("", selection: $selectedTab) {
                    Text("Запити").tag(0)
                    Text("Тести").tag(1)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                
                // Search
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(theme.textTertiary)
                    TextField("Пошук...", text: $searchText)
                        .foregroundColor(theme.textPrimary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(RoundedRectangle(cornerRadius: 10).fill(theme.cardBackground))
                .padding(.horizontal, 16)
                
                // Content
                if selectedTab == 0 {
                    queryHistoryList
                } else {
                    testResultsList
                }
            }
            .background(theme.background.ignoresSafeArea())
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showExportSheet) {
            if selectedTab == 0 {
                ShareSheet(items: [generateHistoryText()])
            }
        }
    }
    
    // MARK: - Query History List
    
    private var queryHistoryList: some View {
        Group {
            if filteredHistoryEntries.isEmpty {
                emptyState(icon: "clock", message: "Історія запитів порожня")
            } else {
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(filteredHistoryEntries) { entry in
                            HistoryEntryCard(entry: entry)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .padding(.bottom, 30)
                }
            }
        }
    }
    
    // MARK: - Test Results List
    
    private var testResultsList: some View {
        Group {
            if filteredTestResults.isEmpty {
                emptyState(icon: "checkmark.circle", message: "Результати тестів порожні")
            } else {
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(filteredTestResults) { result in
                            TestResultCard(result: result)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .padding(.bottom, 30)
                }
            }
        }
    }
    
    // MARK: - Filtered
    
    private var filteredHistoryEntries: [HistoryEntry] {
        if searchText.isEmpty { return historyRepo.historyEntries }
        return historyRepo.historyEntries.filter {
            $0.question.localizedCaseInsensitiveContains(searchText) ||
            $0.answer.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    private var filteredTestResults: [TestResultEntry] {
        if searchText.isEmpty { return historyRepo.testResults }
        return historyRepo.testResults.filter {
            $0.summaryTitle.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    // MARK: - Empty State
    
    private func emptyState(icon: String, message: String) -> some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundColor(theme.textTertiary)
            Text(message)
                .font(.system(size: 16))
                .foregroundColor(theme.textTertiary)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - PDF Text Generation
    
    private func generateHistoryText() -> String {
        var text = "Qurio — Історія запитів\n\n"
        for entry in historyRepo.historyEntries {
            let date = Date(timeIntervalSince1970: Double(entry.timestamp) / 1000)
            let formatter = DateFormatter()
            formatter.dateFormat = "dd.MM.yyyy HH:mm"
            text += "[\(formatter.string(from: date))]\n"
            text += "Q: \(entry.question)\n"
            text += "A: \(entry.answer)\n"
            if !entry.explanation.isEmpty {
                text += "Пояснення: \(entry.explanation)\n"
            }
            text += "\n---\n\n"
        }
        return text
    }
}

// MARK: - History Entry Card

struct HistoryEntryCard: View {
    @Environment(\.appTheme) var theme
    let entry: HistoryEntry
    @State private var expanded = false
    
    var body: some View {
        GlassSection {
            VStack(alignment: .leading, spacing: 8) {
                // Question
                Text(entry.question)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(theme.textPrimary)
                    .lineLimit(expanded ? nil : 2)
                
                // Answer
                Text(entry.answer)
                    .font(.system(size: 14))
                    .foregroundColor(.accentPurple)
                    .lineLimit(expanded ? nil : 1)
                
                // Explanation (if expanded)
                if expanded && !entry.explanation.isEmpty {
                    Text(entry.explanation)
                        .font(.system(size: 13))
                        .foregroundColor(theme.textSecondary)
                }
                
                // Footer
                HStack {
                    Text(formatDate(entry.timestamp))
                        .font(.system(size: 11))
                        .foregroundColor(theme.textTertiary)
                    
                    if entry.confidence > 0 {
                        Spacer()
                        Text("\(Int(entry.confidence * 100))%")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.summaryGreen)
                    }
                    
                    Spacer()
                    
                    Button(action: { withAnimation { expanded.toggle() } }) {
                        Image(systemName: expanded ? "chevron.up" : "chevron.down")
                            .font(.system(size: 12))
                            .foregroundColor(theme.textTertiary)
                    }
                }
            }
            .padding(14)
        }
    }
    
    private func formatDate(_ timestamp: Int64) -> String {
        let date = Date(timeIntervalSince1970: Double(timestamp) / 1000)
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM.yyyy HH:mm"
        return formatter.string(from: date)
    }
}

// MARK: - Test Result Card

struct TestResultCard: View {
    @Environment(\.appTheme) var theme
    let result: TestResultEntry
    
    var body: some View {
        GlassSection {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text(result.summaryTitle.isEmpty ? "Тест" : result.summaryTitle)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(theme.textPrimary)
                        .lineLimit(1)
                    Spacer()
                    Text("\(result.percentage)%")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(result.percentage >= 70 ? .summaryGreen : (result.percentage >= 40 ? .yellowDot : .accentRed))
                }
                
                HStack(spacing: 16) {
                    Label("\(result.score)/\(result.totalQuestions)", systemImage: "checkmark.circle")
                        .font(.system(size: 13))
                        .foregroundColor(theme.textSecondary)
                    
                    Label(formatDuration(result.totalTimeMs), systemImage: "clock")
                        .font(.system(size: 13))
                        .foregroundColor(theme.textSecondary)
                }
                
                Text(formatDate(result.timestamp))
                    .font(.system(size: 11))
                    .foregroundColor(theme.textTertiary)
            }
            .padding(14)
        }
    }
    
    private func formatDuration(_ ms: Int64) -> String {
        let seconds = ms / 1000
        let m = seconds / 60
        let s = seconds % 60
        return "\(m):\(String(format: "%02d", s))"
    }
    
    private func formatDate(_ timestamp: Int64) -> String {
        let date = Date(timeIntervalSince1970: Double(timestamp) / 1000)
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM.yyyy HH:mm"
        return formatter.string(from: date)
    }
}

// MARK: - Share Sheet

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
