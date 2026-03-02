import SwiftUI

/// Test view mirroring TestScreen.kt.
/// Multiple-choice quiz with timer, question navigation, and results review.
struct TestView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.appTheme) var theme
    @EnvironmentObject var settings: SettingsRepository
    @StateObject private var viewModel: TestViewModel
    
    init(questions: [TestQuestion], summaryTitle: String = "") {
        _viewModel = StateObject(wrappedValue: TestViewModel(questions: questions, summaryTitle: summaryTitle))
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                theme.background.ignoresSafeArea()
                
                if viewModel.isFinished {
                    resultsView
                } else {
                    questionView
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Завершити") {
                        if viewModel.isFinished {
                            dismiss()
                        } else {
                            viewModel.finishTest()
                        }
                    }
                    .foregroundColor(.accentRed)
                }
                
                ToolbarItem(placement: .principal) {
                    Text(viewModel.isFinished ? "Результати" : "Питання \(viewModel.currentIndex + 1)/\(viewModel.questions.count)")
                        .font(.system(size: 16, weight: .semibold))
                }
            }
        }
    }
    
    // MARK: - Question View
    
    private var questionView: some View {
        VStack(spacing: 16) {
            // Timer
            if settings.testTimeLimitMinutes > 0 {
                HStack {
                    Image(systemName: "clock")
                        .foregroundColor(viewModel.remainingSeconds < 60 ? .accentRed : .accentPurple)
                    Text(viewModel.timerFormatted)
                        .font(.system(size: 16, weight: .medium, design: .monospaced))
                        .foregroundColor(viewModel.remainingSeconds < 60 ? .accentRed : theme.textPrimary)
                }
                .padding(.vertical, 8)
            }
            
            // Progress bar
            ProgressView(value: Double(viewModel.currentIndex + 1), total: Double(viewModel.questions.count))
                .tint(.accentPurple)
                .padding(.horizontal, 16)
            
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Question text
                    let question = viewModel.questions[viewModel.currentIndex]
                    
                    Text(question.question)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(theme.textPrimary)
                        .padding(.horizontal, 16)
                    
                    // Options
                    VStack(spacing: 10) {
                        ForEach(Array(question.options.enumerated()), id: \.offset) { index, option in
                            OptionButton(
                                label: optionLetter(index),
                                text: option,
                                isSelected: viewModel.selectedAnswers[viewModel.currentIndex] == index,
                                isCorrect: nil
                            ) {
                                viewModel.selectAnswer(index)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                }
                .padding(.vertical, 12)
            }
            
            // Navigation
            HStack(spacing: 12) {
                if viewModel.currentIndex > 0 {
                    OutlinedButton("← Назад") {
                        viewModel.previousQuestion()
                    }
                }
                
                if viewModel.currentIndex < viewModel.questions.count - 1 {
                    AccentButton("Далі →") {
                        viewModel.nextQuestion()
                    }
                } else {
                    AccentButton("Завершити", icon: "checkmark.circle") {
                        viewModel.finishTest()
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 20)
        }
    }
    
    // MARK: - Results View
    
    private var resultsView: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Score circle
                ZStack {
                    Circle()
                        .stroke(theme.divider, lineWidth: 8)
                        .frame(width: 120, height: 120)
                    
                    Circle()
                        .trim(from: 0, to: CGFloat(viewModel.percentage) / 100)
                        .stroke(scoreColor, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                        .frame(width: 120, height: 120)
                        .rotationEffect(.degrees(-90))
                    
                    VStack(spacing: 2) {
                        Text("\(viewModel.percentage)%")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(theme.textPrimary)
                        Text("\(viewModel.score)/\(viewModel.questions.count)")
                            .font(.system(size: 14))
                            .foregroundColor(theme.textSecondary)
                    }
                }
                .padding(.top, 20)
                
                // Stats row
                HStack(spacing: 20) {
                    StatPill(icon: "clock", value: viewModel.totalTimeFormatted, label: "Загалом")
                    StatPill(icon: "gauge.medium", value: viewModel.avgTimeFormatted, label: "Середній")
                    StatPill(icon: "bolt", value: viewModel.fastestFormatted, label: "Нашвидший")
                }
                
                // Results text
                Text(resultEmoji)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(theme.textPrimary)
                
                // Detailed answers (if show answers is enabled)
                if settings.testShowAnswers {
                    VStack(spacing: 12) {
                        ForEach(Array(viewModel.questions.enumerated()), id: \.offset) { index, question in
                            QuestionReviewCard(
                                index: index,
                                question: question,
                                selectedAnswer: viewModel.selectedAnswers[index]
                            )
                        }
                    }
                    .padding(.horizontal, 16)
                }
                
                AccentButton("Закрити") {
                    dismiss()
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 30)
            }
        }
    }
    
    private var scoreColor: Color {
        if viewModel.percentage >= 80 { return .summaryGreen }
        if viewModel.percentage >= 50 { return .yellowDot }
        return .accentRed
    }
    
    private var resultEmoji: String {
        if viewModel.percentage >= 90 { return "🏆 Відмінно!" }
        if viewModel.percentage >= 70 { return "👍 Добре!" }
        if viewModel.percentage >= 50 { return "📚 Непогано" }
        return "💪 Потрібно підтягнути"
    }
    
    private func optionLetter(_ index: Int) -> String {
        ["А", "Б", "В", "Г", "Д", "Е"][min(index, 5)]
    }
}

// MARK: - Option Button

struct OptionButton: View {
    @Environment(\.appTheme) var theme
    let label: String
    let text: String
    let isSelected: Bool
    let isCorrect: Bool?
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Text(label)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(isSelected ? .white : .accentPurple)
                    .frame(width: 28, height: 28)
                    .background(
                        Circle().fill(isSelected ? Color.accentPurple : Color.accentPurple.opacity(0.1))
                    )
                
                Text(text)
                    .font(.system(size: 15))
                    .foregroundColor(theme.textPrimary)
                    .multilineTextAlignment(.leading)
                
                Spacer()
                
                if let isCorrect {
                    Image(systemName: isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundColor(isCorrect ? .summaryGreen : .accentRed)
                }
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(isSelected ? Color.accentPurple.opacity(0.08) : theme.cardBackground.opacity(0.5))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(isSelected ? Color.accentPurple.opacity(0.4) : theme.divider, lineWidth: 1)
            )
        }
    }
}

// MARK: - Question Review Card

struct QuestionReviewCard: View {
    @Environment(\.appTheme) var theme
    let index: Int
    let question: TestQuestion
    let selectedAnswer: Int?
    
    var body: some View {
        GlassSection {
            VStack(alignment: .leading, spacing: 10) {
                Text("\(index + 1). \(question.question)")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(theme.textPrimary)
                
                ForEach(Array(question.options.enumerated()), id: \.offset) { i, option in
                    HStack(spacing: 8) {
                        Image(systemName: i == question.correctIndex ? "checkmark.circle.fill" : (i == selectedAnswer ? "xmark.circle.fill" : "circle"))
                            .font(.system(size: 14))
                            .foregroundColor(i == question.correctIndex ? .summaryGreen : (i == selectedAnswer ? .accentRed : theme.textTertiary))
                        
                        Text(option)
                            .font(.system(size: 13))
                            .foregroundColor(i == question.correctIndex ? .summaryGreen : (i == selectedAnswer && i != question.correctIndex ? .accentRed : theme.textSecondary))
                    }
                }
            }
            .padding(14)
        }
    }
}

// MARK: - Stat Pill

struct StatPill: View {
    @Environment(\.appTheme) var theme
    let icon: String
    let value: String
    let label: String
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(.accentPurple)
            Text(value)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(theme.textPrimary)
            Text(label)
                .font(.system(size: 11))
                .foregroundColor(theme.textSecondary)
        }
    }
}

// MARK: - View Model

@MainActor
final class TestViewModel: ObservableObject {
    let questions: [TestQuestion]
    let summaryTitle: String
    
    @Published var currentIndex = 0
    @Published var selectedAnswers: [Int?]
    @Published var isFinished = false
    @Published var remainingSeconds: Int
    
    @Published var score = 0
    @Published var percentage = 0
    @Published var questionTimes: [Int64] // ms per question
    
    private var startTime: Date
    private var questionStartTime: Date
    private var timer: Timer?
    private let settings = SettingsRepository.shared
    
    init(questions: [TestQuestion], summaryTitle: String) {
        self.questions = questions
        self.summaryTitle = summaryTitle
        self.selectedAnswers = Array(repeating: nil, count: questions.count)
        self.questionTimes = Array(repeating: 0, count: questions.count)
        self.remainingSeconds = settings.testTimeLimitMinutes * 60
        self.startTime = Date()
        self.questionStartTime = Date()
        
        if settings.testTimeLimitMinutes > 0 {
            startTimer()
        }
    }
    
    func selectAnswer(_ index: Int) {
        selectedAnswers[currentIndex] = index
    }
    
    func nextQuestion() {
        recordQuestionTime()
        if currentIndex < questions.count - 1 {
            currentIndex += 1
            questionStartTime = Date()
        }
    }
    
    func previousQuestion() {
        recordQuestionTime()
        if currentIndex > 0 {
            currentIndex -= 1
            questionStartTime = Date()
        }
    }
    
    func finishTest() {
        recordQuestionTime()
        timer?.invalidate()
        
        // Calculate score
        score = 0
        for (i, question) in questions.enumerated() {
            if selectedAnswers[i] == question.correctIndex {
                score += 1
            }
        }
        percentage = questions.isEmpty ? 0 : (score * 100 / questions.count)
        
        isFinished = true
        
        // Save test result
        Task {
            let totalMs = Int64(Date().timeIntervalSince(startTime) * 1000)
            let nonZeroTimes = questionTimes.filter { $0 > 0 }
            let avgMs = nonZeroTimes.isEmpty ? 0 : Int64(nonZeroTimes.reduce(0, +)) / Int64(nonZeroTimes.count)
            let fastMs = nonZeroTimes.min() ?? 0
            let slowMs = nonZeroTimes.max() ?? 0
            
            let questionsJson = (try? JSONEncoder().encode(questions)).flatMap { String(data: $0, encoding: .utf8) } ?? ""
            
            let entry = TestResultEntry(
                summaryTitle: summaryTitle,
                score: score,
                totalQuestions: questions.count,
                percentage: percentage,
                totalTimeMs: totalMs,
                avgTimeMs: avgMs,
                fastestMs: fastMs,
                slowestMs: slowMs,
                questionsJson: questionsJson
            )
            await HistoryRepository.shared.saveTestResult(entry)
        }
    }
    
    // MARK: - Timer
    
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self, self.remainingSeconds > 0 else {
                    self?.finishTest()
                    return
                }
                self.remainingSeconds -= 1
            }
        }
    }
    
    private func recordQuestionTime() {
        let elapsed = Int64(Date().timeIntervalSince(questionStartTime) * 1000)
        questionTimes[currentIndex] += elapsed
    }
    
    // MARK: - Formatted
    
    var timerFormatted: String {
        let m = remainingSeconds / 60
        let s = remainingSeconds % 60
        return String(format: "%02d:%02d", m, s)
    }
    
    var totalTimeFormatted: String {
        let total = Int(Date().timeIntervalSince(startTime))
        return String(format: "%d:%02d", total / 60, total % 60)
    }
    
    var avgTimeFormatted: String {
        let nonZero = questionTimes.filter { $0 > 0 }
        guard !nonZero.isEmpty else { return "0s" }
        let avg = nonZero.reduce(0, +) / Int64(nonZero.count) / 1000
        return "\(avg)s"
    }
    
    var fastestFormatted: String {
        let fastest = (questionTimes.filter { $0 > 0 }.min() ?? 0) / 1000
        return "\(fastest)s"
    }
}
