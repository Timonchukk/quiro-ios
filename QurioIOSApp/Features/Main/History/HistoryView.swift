import SwiftUI
import UIKit

/// History screen — glass-morphism redesign.
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
                        .font(.system(size: 28, weight: .bold, design: .rounded))
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
                
                // Pill Segmented Control
                pillSegmentedControl
                    .padding(.horizontal, 16)
                    .padding(.vertical, DesignTokens.spacingMedium)
                
                // Glass Search Bar
                HStack(spacing: 10) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 15))
                        .foregroundColor(theme.textTertiary)
                    TextField("Пошук...", text: $searchText)
                        .font(.system(size: 15))
                        .foregroundColor(theme.textPrimary)
                    if !searchText.isEmpty {
                        Button(action: { searchText = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 14))
                                .foregroundColor(theme.textTertiary)
                        }
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 11)
                .background(
                    RoundedRectangle(cornerRadius: DesignTokens.radiusMedium)
                        .fill(theme.glassBackground)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: DesignTokens.radiusMedium)
                        .stroke(theme.glassBorder, lineWidth: 0.5)
                )
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
    
    // MARK: - Pill Segmented Control
    
    private var pillSegmentedControl: some View {
        HStack(spacing: 0) {
            pillSegment(title: "Запити", icon: "bubble.left.fill", index: 0)
            pillSegment(title: "Тести", icon: "checkmark.circle.fill", index: 1)
        }
        .padding(3)
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.radiusMedium)
                .fill(theme.glassBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: DesignTokens.radiusMedium)
                .stroke(theme.glassBorder, lineWidth: 0.5)
        )
    }
    
    private func pillSegment(title: String, icon: String, index: Int) -> some View {
        Button(action: {
            HapticManager.selection()
            withAnimation(.spring(response: 0.3)) { selectedTab = index }
        }) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
            }
            .foregroundColor(selectedTab == index ? .white : theme.textSecondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(
                Group {
                    if selectedTab == index {
                        RoundedRectangle(cornerRadius: DesignTokens.radiusSmall)
                            .fill(
                                LinearGradient(
                                    colors: [.accentPurple, .violet],
                                    startPoint: .leading, endPoint: .trailing
                                )
                            )
                    }
                }
            )
        }
    }
    
    // MARK: - Query History List
    
    private var queryHistoryList: some View {
        Group {
            if filteredHistoryEntries.isEmpty {
                emptyState(icon: "clock.arrow.circlepath", message: "Історія запитів порожня", subtitle: "Ваші AI запити з'являться тут")
            } else {
                ScrollView {
                    LazyVStack(spacing: 10) {
                        ForEach(filteredHistoryEntries) { entry in
                            HistoryEntryCard(entry: entry)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 10)
                    .padding(.bottom, 30)
                }
            }
        }
    }
    
    // MARK: - Test Results List
    
    private var testResultsList: some View {
        Group {
            if filteredTestResults.isEmpty {
                emptyState(icon: "doc.text.magnifyingglass", message: "Результати тестів порожні", subtitle: "Пройдіть тест і результат буде тут")
            } else {
                ScrollView {
                    LazyVStack(spacing: 10) {
                        ForEach(filteredTestResults) { result in
                            TestResultCard(result: result)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 10)
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
    
    private func emptyState(icon: String, message: String, subtitle: String = "") -> some View {
        VStack(spacing: 14) {
            Spacer()
            
            ZStack {
                Circle()
                    .fill(theme.glassBackground)
                    .frame(width: 80, height: 80)
                Image(systemName: icon)
                    .font(.system(size: 32))
                    .foregroundColor(theme.textTertiary)
            }
            
            Text(message)
                .font(.system(size: 17, weight: .medium))
                .foregroundColor(theme.textSecondary)
            
            if !subtitle.isEmpty {
                Text(subtitle)
                    .font(.system(size: 14))
                    .foregroundColor(theme.textTertiary)
            }
            
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
    @State private var showShareSheet = false
    @State private var showPdfShare = false
    
    var body: some View {
        GlassCard(cornerRadius: DesignTokens.radiusMedium) {
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .top, spacing: 10) {
                    IconCircle(entry.question.hasPrefix("📝") ? "doc.text.fill" : "questionmark", tint: .accentPurple, size: 32)
                    
                    VStack(alignment: .leading, spacing: 4) {
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
                    }
                }
                
                // Explanation (if expanded)
                if expanded && !entry.explanation.isEmpty {
                    Text(entry.explanation)
                        .font(.system(size: 13))
                        .foregroundColor(theme.textSecondary)
                        .padding(.leading, 42)
                }
                
                // Footer
                HStack {
                    Text(formatDate(entry.timestamp))
                        .font(.system(size: 11))
                        .foregroundColor(theme.textTertiary)
                    
                    if entry.confidence > 0 {
                        Text("•")
                            .foregroundColor(theme.textTertiary)
                        Text("\(Int(entry.confidence * 100))%")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.summaryGreen)
                    }
                    
                    Spacer()
                    
                    // Actions menu
                    Menu {
                        Button(action: {
                            UIPasteboard.general.string = "\(entry.question)\n\n\(entry.answer)"
                        }) {
                            Label("Копіювати", systemImage: "doc.on.doc")
                        }
                        Button(action: { showShareSheet = true }) {
                            Label("Поділитися", systemImage: "square.and.arrow.up")
                        }
                        Button(action: { showPdfShare = true }) {
                            Label("Експорт PDF", systemImage: "doc.richtext")
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(theme.textTertiary)
                            .padding(6)
                            .background(Circle().fill(theme.glassBackground))
                    }
                    
                    Button(action: { withAnimation(.spring()) { expanded.toggle() } }) {
                        Image(systemName: expanded ? "chevron.up" : "chevron.down")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(theme.textTertiary)
                            .padding(6)
                            .background(Circle().fill(theme.glassBackground))
                    }
                }
            }
            .padding(DesignTokens.paddingMedium)
        }
        .sheet(isPresented: $showShareSheet) {
            ShareSheet(items: ["\(entry.question)\n\n\(entry.answer)\(entry.explanation.isEmpty ? "" : "\n\nПояснення: \(entry.explanation)")"])
        }
        .sheet(isPresented: $showPdfShare) {
            if let pdfData = generatePDF(for: entry) {
                let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("Qurio_\(formatDateFile(entry.timestamp)).pdf")
                let _ = try? pdfData.write(to: tempURL)
                ShareSheet(items: [tempURL])
            }
        }
    }
    
    private func formatDate(_ timestamp: Int64) -> String {
        let date = Date(timeIntervalSince1970: Double(timestamp) / 1000)
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM.yyyy HH:mm"
        return formatter.string(from: date)
    }
    
    private func formatDateFile(_ timestamp: Int64) -> String {
        let date = Date(timeIntervalSince1970: Double(timestamp) / 1000)
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HH-mm"
        return formatter.string(from: date)
    }
    
    private func generatePDF(for entry: HistoryEntry) -> Data? {
        let pageWidth: CGFloat = 595.2 // A4
        let pageHeight: CGFloat = 841.8
        let margin: CGFloat = 40
        let contentWidth = pageWidth - 2 * margin
        
        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight))
        
        return renderer.pdfData { context in
            context.beginPage()
            var y: CGFloat = margin
            
            // Title
            let titleFont = UIFont.boldSystemFont(ofSize: 22)
            let titleAttr: [NSAttributedString.Key: Any] = [.font: titleFont, .foregroundColor: UIColor.label]
            let titleStr = NSAttributedString(string: "Qurio — AI Відповідь", attributes: titleAttr)
            titleStr.draw(in: CGRect(x: margin, y: y, width: contentWidth, height: 30))
            y += 40
            
            // Date
            let dateFont = UIFont.systemFont(ofSize: 12)
            let dateAttr: [NSAttributedString.Key: Any] = [.font: dateFont, .foregroundColor: UIColor.secondaryLabel]
            let dateStr = NSAttributedString(string: formatDate(entry.timestamp), attributes: dateAttr)
            dateStr.draw(in: CGRect(x: margin, y: y, width: contentWidth, height: 18))
            y += 30
            
            // Question header
            let headerFont = UIFont.boldSystemFont(ofSize: 14)
            let headerAttr: [NSAttributedString.Key: Any] = [.font: headerFont, .foregroundColor: UIColor.systemPurple]
            let qHeader = NSAttributedString(string: "Питання:", attributes: headerAttr)
            qHeader.draw(in: CGRect(x: margin, y: y, width: contentWidth, height: 20))
            y += 24
            
            // Question text
            let bodyFont = UIFont.systemFont(ofSize: 14)
            let bodyAttr: [NSAttributedString.Key: Any] = [.font: bodyFont, .foregroundColor: UIColor.label]
            let qText = NSAttributedString(string: entry.question, attributes: bodyAttr)
            let qRect = qText.boundingRect(with: CGSize(width: contentWidth, height: .greatestFiniteMagnitude), options: [.usesLineFragmentOrigin], context: nil)
            qText.draw(in: CGRect(x: margin, y: y, width: contentWidth, height: qRect.height + 4))
            y += qRect.height + 20
            
            // Answer header
            let aHeader = NSAttributedString(string: "Відповідь:", attributes: headerAttr)
            aHeader.draw(in: CGRect(x: margin, y: y, width: contentWidth, height: 20))
            y += 24
            
            // Answer text
            let aText = NSAttributedString(string: entry.answer, attributes: bodyAttr)
            let aRect = aText.boundingRect(with: CGSize(width: contentWidth, height: .greatestFiniteMagnitude), options: [.usesLineFragmentOrigin], context: nil)
            
            // Check if we need a new page
            if y + aRect.height > pageHeight - margin {
                context.beginPage()
                y = margin
            }
            aText.draw(in: CGRect(x: margin, y: y, width: contentWidth, height: aRect.height + 4))
            y += aRect.height + 20
            
            // Explanation (if any)
            if !entry.explanation.isEmpty {
                let eHeader = NSAttributedString(string: "Пояснення:", attributes: headerAttr)
                eHeader.draw(in: CGRect(x: margin, y: y, width: contentWidth, height: 20))
                y += 24
                
                let eText = NSAttributedString(string: entry.explanation, attributes: bodyAttr)
                let eRect = eText.boundingRect(with: CGSize(width: contentWidth, height: .greatestFiniteMagnitude), options: [.usesLineFragmentOrigin], context: nil)
                if y + eRect.height > pageHeight - margin {
                    context.beginPage()
                    y = margin
                }
                eText.draw(in: CGRect(x: margin, y: y, width: contentWidth, height: eRect.height + 4))
            }
        }
    }
}

// MARK: - Test Result Card

struct TestResultCard: View {
    @Environment(\.appTheme) var theme
    @EnvironmentObject var settings: SettingsRepository
    let result: TestResultEntry
    @State private var showTestView = false
    @State private var showShareSheet = false
    
    private var scoreColor: Color {
        result.percentage >= 70 ? .summaryGreen : (result.percentage >= 40 ? .yellowDot : .accentRed)
    }
    
    private var decodedQuestions: [TestQuestion]? {
        guard !result.questionsJson.isEmpty,
              let data = result.questionsJson.data(using: .utf8) else { return nil }
        return try? JSONDecoder().decode([TestQuestion].self, from: data)
    }
    
    var body: some View {
        GlassCard(cornerRadius: DesignTokens.radiusMedium) {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    IconCircle("doc.text.fill", tint: scoreColor, size: 32)
                    
                    Text(result.summaryTitle.isEmpty ? "Тест" : result.summaryTitle)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(theme.textPrimary)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    Text("\(result.percentage)%")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(scoreColor)
                }
                
                HStack(spacing: 16) {
                    Label("\(result.score)/\(result.totalQuestions)", systemImage: "checkmark.circle")
                        .font(.system(size: 13))
                        .foregroundColor(theme.textSecondary)
                    
                    Label(formatDuration(result.totalTimeMs), systemImage: "clock")
                        .font(.system(size: 13))
                        .foregroundColor(theme.textSecondary)
                    
                    Spacer()
                    
                    Text(formatDate(result.timestamp))
                        .font(.system(size: 11))
                        .foregroundColor(theme.textTertiary)
                }
                
                // Action buttons
                HStack(spacing: 10) {
                    // Retry button
                    if decodedQuestions != nil {
                        Button(action: { showTestView = true }) {
                            HStack(spacing: 6) {
                                Image(systemName: "arrow.counterclockwise")
                                Text("Повторити")
                            }
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.accentPurple)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                Capsule().fill(Color.accentPurple.opacity(0.12))
                            )
                        }
                    }
                    
                    Spacer()
                    
                    // Actions menu
                    Menu {
                        Button(action: {
                            UIPasteboard.general.string = "Тест: \(result.summaryTitle)\nРезультат: \(result.score)/\(result.totalQuestions) (\(result.percentage)%)\nЧас: \(formatDuration(result.totalTimeMs))"
                        }) {
                            Label("Копіювати", systemImage: "doc.on.doc")
                        }
                        Button(action: { showShareSheet = true }) {
                            Label("Поділитися", systemImage: "square.and.arrow.up")
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(theme.textTertiary)
                            .padding(6)
                            .background(Circle().fill(theme.glassBackground))
                    }
                }
            }
            .padding(DesignTokens.paddingMedium)
        }
        .sheet(isPresented: $showTestView) {
            if let questions = decodedQuestions {
                TestView(questions: questions, summaryTitle: result.summaryTitle)
                    .environmentObject(settings)
            }
        }
        .sheet(isPresented: $showShareSheet) {
            ShareSheet(items: ["Тест: \(result.summaryTitle)\nРезультат: \(result.score)/\(result.totalQuestions) (\(result.percentage)%)\nЧас: \(formatDuration(result.totalTimeMs))"])
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
