import SwiftUI
import ReplayKit

/// Dynamic Island-style floating overlay mirroring OverlayService.kt.
/// Capsule at top center that expands into a glass panel with AI results.
///
/// Fix 2: Broadcast starts ONLY via RPSystemBroadcastPickerView
/// Fix 3: Consent sheet shown before broadcast picker
/// Fix 4: Live Activity starts when broadcast is active
/// Fix 7: Simulator guard for broadcast features
struct DynamicIslandOverlay: View {
    @Binding var isVisible: Bool
    @EnvironmentObject var settings: SettingsRepository
    @Environment(\.appTheme) var theme

    @State private var status: OverlayStatus = .idle
    @State private var isExpanded = false
    @State private var result: AiResult?
    @State private var summaryText: String?
    @State private var dragOffset = CGSize.zero
    @State private var showManualPrompt = false
    @State private var manualPromptText = ""
    @State private var testQuestions: [TestQuestion] = []
    @State private var showTestView = false
    @State private var isGeneratingTest = false

    @StateObject private var privacyManager = PrivacyManager.shared
    @StateObject private var broadcastReceiver = BroadcastReceiver.shared
    @StateObject private var liveActivityManager = LiveActivityManager.shared

    private let llmRepo = LlmRepository.shared
    private let captureService = ScreenCaptureService.shared

    var body: some View {
        ZStack {
            VStack {
                ZStack {
                    if isExpanded {
                        expandedPanel
                            .transition(.asymmetric(
                                insertion: .scale(scale: 0.8).combined(with: .opacity),
                                removal: .scale(scale: 0.8).combined(with: .opacity)
                            ))
                    } else {
                        capsule
                            .transition(.scale.combined(with: .opacity))
                    }
                }
                .offset(y: dragOffset.height)
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            dragOffset = value.translation
                        }
                        .onEnded { _ in
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                dragOffset = .zero
                            }
                        }
                )
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top, 60)

                Spacer()
            }
            .ignoresSafeArea()

            // Fix 3: Consent overlay
            if privacyManager.showingConsentSheet {
                CaptureConsentView()
                    .transition(.opacity)
            }
        }
        .onChange(of: broadcastReceiver.isBroadcastActive) { active in
            if active {
                // Fix 4: Start Live Activity when broadcast begins
                liveActivityManager.startLiveActivity()
            } else if liveActivityManager.isActivityActive {
                // Broadcast ended externally — end Live Activity
                liveActivityManager.endLiveActivity()
                privacyManager.resetConsent()
            }
        }
        .sheet(isPresented: $showTestView) {
            if !testQuestions.isEmpty {
                TestView(questions: testQuestions, summaryTitle: "Конспект")
                    .environmentObject(settings)
            }
        }
    }

    // MARK: - Capsule (collapsed state)

    private var capsule: some View {
        Button(action: {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                isExpanded = true
            }
        }) {
            HStack(spacing: 8) {
                statusCircle

                Text(statusLabel)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white)
                    .lineLimit(1)

                // Recording indicator when broadcast is active
                if broadcastReceiver.isBroadcastActive {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 6, height: 6)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(Color(red: 0.12, green: 0.12, blue: 0.15).opacity(0.92))
                    .overlay(
                        Capsule()
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
            )
            .shadow(color: .black.opacity(0.25), radius: 8, y: 4)
        }
    }

    // MARK: - Expanded Panel

    private var expandedPanel: some View {
        VStack(spacing: 0) {
            // Drag handle
            RoundedRectangle(cornerRadius: 3)
                .fill(Color.white.opacity(0.25))
                .frame(width: 36, height: 5)
                .padding(.top, 10)
                .padding(.bottom, 4)

            // Header bar with collapse/close
            HStack {
                Button(action: {
                    HapticManager.selection()
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                        isExpanded = false
                    }
                }) {
                    Image(systemName: "chevron.up")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white.opacity(0.6))
                }

                Spacer()

                statusChip

                Spacer()

                Button(action: {
                    HapticManager.impact(.light)
                    stopEverything()
                    withAnimation { isVisible = false }
                }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white.opacity(0.6))
                        .padding(6)
                        .background(Circle().fill(Color.white.opacity(0.1)))
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 6)
            .padding(.bottom, 8)

            Divider().opacity(0.15)

            // Content
            ScrollView(showsIndicators: false) {
                VStack(spacing: 14) {
                    switch status {
                    case .idle:
                        idleContent
                    case .capturing:
                        captureContent
                    case .thinking:
                        thinkingContent
                    case .done:
                        resultContent
                    case .error:
                        errorContent
                    case .summaryCollecting(let current, let total):
                        summaryCollectingContent(current: current, total: total)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .frame(maxHeight: 350)
        }
        .frame(width: min(UIScreen.main.bounds.width - 32, 360))
        .background(
            RoundedRectangle(cornerRadius: 26)
                .fill(Color(red: 0.12, green: 0.12, blue: 0.15).opacity(0.92))
                .overlay(
                    RoundedRectangle(cornerRadius: 26)
                        .fill(
                            LinearGradient(
                                colors: [Color.white.opacity(0.08), Color.white.opacity(0.02)],
                                startPoint: .topLeading, endPoint: .bottomTrailing
                            )
                        )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 26)
                        .stroke(Color.white.opacity(0.15), lineWidth: 1)
                )
        )
        .shadow(color: .black.opacity(0.3), radius: 16, y: 8)
    }

    // MARK: - Idle Content

    private var idleContent: some View {
        VStack(spacing: 14) {
            // Fix 7: Simulator guard
            if SimulatorGuard.isSimulator {
                VStack(spacing: 8) {
                    Image(systemName: "iphone.slash")
                        .font(.system(size: 28))
                        .foregroundColor(.secondary)
                    Text(SimulatorGuard.unavailableMessage)
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.vertical, 8)
            }

            // Broadcast status indicator
            if broadcastReceiver.isBroadcastActive {
                HStack(spacing: 6) {
                    Circle().fill(.red).frame(width: 8, height: 8)
                    Text("Запис екрану активний")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.red)
                }
                .padding(.vertical, 4)
                .padding(.horizontal, 12)
                .background(Capsule().fill(Color.red.opacity(0.1)))
            }

            // Capture Button — uses broadcast frame if active, in-app screenshot if not
            AccentButton("📸 Запитати AI", icon: "camera.fill") {
                captureAndAsk()
            }

            // Fix 2: Broadcast Picker — consent gate (only on real device)
            if !SimulatorGuard.isSimulator {
                if broadcastReceiver.isBroadcastActive {
                    // Stop broadcast button
                    OutlinedButton("🔴 Зупинити запис", icon: "stop.fill") {
                        stopEverything()
                    }
                } else {
                    // Start broadcast button — shows consent first
                    OutlinedButton("🎥 Запис екрану", icon: "record.circle") {
                        startBroadcastFlow()
                    }
                }
            }

            // Summary Mode — visible for all users, Pro-gated on action
            if settings.hasActiveSubscription {
                OutlinedButton("📝 Конспект (\(settings.remainingSummaries()) зал.)", icon: "doc.text") {
                    startSummaryMode()
                }
            } else {
                OutlinedButton("📝 Конспект (Pro ⭐)", icon: "doc.text") {
                    result = AiResult(answer: "", isError: true, errorMessage: "Конспекти доступні тільки для Pro ⭐")
                    withAnimation { status = .error }
                }
            }

            // Manual Prompt
            if showManualPrompt {
                VStack(spacing: 8) {
                    TextField("Ваше питання...", text: $manualPromptText)
                        .textFieldStyle(.roundedBorder)

                    AccentButton("Надіслати") {
                        sendManualPrompt()
                    }
                }
            } else {
                Button("✏️ Своє питання") {
                    withAnimation { showManualPrompt = true }
                }
                .font(.system(size: 14))
                .foregroundColor(.accentPurple)
            }

            // Remaining requests
            if !settings.hasActiveSubscription {
                Text("Залишилось \(settings.remainingTrialRequests()) безкоштовних запитів")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.4))
            }
        }
    }

    // MARK: - Capture Content

    private var captureContent: some View {
        VStack(spacing: 12) {
            ProgressView()
                .scaleEffect(1.2)
                .tint(.accentPurple)
            Text("Зйомка екрану...")
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
    }

    // MARK: - Thinking Content

    private var thinkingContent: some View {
        VStack(spacing: 12) {
            HStack(spacing: 8) {
                ProgressView()
                    .tint(.accentPurple)
                Text("AI думає...")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
    }

    // MARK: - Result Content

    private var resultContent: some View {
        VStack(alignment: .leading, spacing: 10) {
            if let result {
                // Answer
                HStack(alignment: .top, spacing: 8) {
                    Text("💡")
                        .font(.system(size: 16))
                    FormattedAIText(result.answer, fontSize: 15)
                        .foregroundColor(.white)
                }

                // Explanation
                if settings.showExplanation && !result.explanation.isEmpty {
                    Divider().opacity(0.15)
                    HStack(alignment: .top, spacing: 8) {
                        Text("📖")
                            .font(.system(size: 14))
                        FormattedAIText(result.explanation, fontSize: 13)
                            .foregroundColor(.white.opacity(0.7))
                    }
                }

                // Confidence
                if result.confidence > 0 {
                    HStack {
                        Text("Впевненість: \(Int(result.confidence * 100))%")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.4))
                        Spacer()

                        // Report button
                        Button(action: {
                            Task {
                                await AuthRepository.shared.sendReport(
                                    answer: result.answer,
                                    explanation: result.explanation
                                )
                            }
                        }) {
                            Image(systemName: "flag")
                                .font(.system(size: 12))
                                .foregroundColor(.white.opacity(0.3))
                        }
                    }
                }

                Divider().opacity(0.15)

                // Action buttons
                HStack(spacing: 12) {
                    Button("Нове питання") {
                        withAnimation { reset() }
                    }
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.accentPurple)

                    Spacer()

                    Button(action: {
                        UIPasteboard.general.string = result.answer
                    }) {
                        Image(systemName: "doc.on.doc")
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.5))
                    }
                }
            }

            if let summary = summaryText {
                Divider().opacity(0.15)
                FormattedAIText(summary, fontSize: 14)
                    .foregroundColor(.white)

                // Summary action buttons
                HStack(spacing: 12) {
                    // Generate Test button
                    if isGeneratingTest {
                        HStack(spacing: 8) {
                            ProgressView().tint(.accentPurple)
                            Text("Генерую тест...")
                                .font(.system(size: 13))
                                .foregroundColor(.white.opacity(0.7))
                        }
                    } else {
                        AccentButton("📝 Створити тест") {
                            generateTestFromSummary(summary)
                        }
                    }
                    
                    // Copy summary
                    Button(action: {
                        UIPasteboard.general.string = summary
                    }) {
                        Image(systemName: "doc.on.doc")
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.5))
                    }
                }
            }
        }
    }

    // MARK: - Error Content

    private var errorContent: some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 28))
                .foregroundColor(.accentRed)

            Text(result?.errorMessage ?? "Сталася помилка")
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)

            AccentButton("Спробувати ще раз") {
                reset()
            }
        }
        .padding(.vertical, 16)
    }

    // MARK: - Summary Collecting Content

    private func summaryCollectingContent(current: Int, total: Int) -> some View {
        VStack(spacing: 12) {
            Text("Конспект: \(current)/\(total) скріншотів")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.white)

            ProgressView(value: Double(current), total: Double(total))
                .tint(.summaryGreen)

            HStack(spacing: 12) {
                AccentButton("📸 Додати") {
                    addSummaryScreenshot()
                }

                if current >= 1 {
                    OutlinedButton("✅ Готово") {
                        completeSummary()
                    }
                }
            }
        }
    }

    // MARK: - Status Helpers

    private var statusCircle: some View {
        Circle()
            .fill(statusColor)
            .frame(width: 10, height: 10)
    }

    private var statusChip: some View {
        HStack(spacing: 4) {
            statusCircle
            Text(statusLabel)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white.opacity(0.7))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(Capsule().fill(statusColor.opacity(0.15)))
    }

    private var statusLabel: String {
        switch status {
        case .idle: return broadcastReceiver.isBroadcastActive ? "🔴 Запис" : "Qurio"
        case .capturing: return "Зйомка..."
        case .thinking: return "Думаю..."
        case .done: return "Готово"
        case .error: return "Помилка"
        case .summaryCollecting(let c, let t): return "Конспект \(c)/\(t)"
        }
    }

    private var statusColor: Color {
        switch status {
        case .idle: return broadcastReceiver.isBroadcastActive ? .red : .accentPurple
        case .capturing: return .yellowDot
        case .thinking: return .violet
        case .done: return .summaryGreen
        case .error: return .accentRed
        case .summaryCollecting: return .summaryGreen
        }
    }

    // MARK: - Actions

    /// Fix 2+3: Start broadcast flow with consent → picker
    private func startBroadcastFlow() {
        privacyManager.requestConsent {
            // Consent granted — programmatically trigger the broadcast picker
            triggerBroadcastPicker()
        }
    }

    /// Triggers RPSystemBroadcastPickerView programmatically
    private func triggerBroadcastPicker() {
        let picker = ScreenCaptureService.makeBroadcastPicker()
        // Find and tap the system button to show the consent dialog
        for subview in picker.subviews {
            if let button = subview as? UIButton {
                button.sendActions(for: .touchUpInside)
                break
            }
        }
    }

    /// Stops broadcast + Live Activity + resets consent
    private func stopEverything() {
        liveActivityManager.stopAll()
        privacyManager.resetConsent()
    }

    private func captureAndAsk() {
        guard settings.canMakeTrialRequest() else {
            result = AiResult(answer: "", isError: true, errorMessage: "Вичерпано безкоштовні запити. Оновіть до Pro!")
            status = .error
            return
        }

        withAnimation { status = .capturing }

        // Fix 4: Update Live Activity
        if liveActivityManager.isActivityActive {
            liveActivityManager.markProcessing()
        }

        Task {
            // Use broadcast frame if available, otherwise in-app screenshot
            let screenshot = captureService.captureScreenshot()

            if let screenshot {
                withAnimation { status = .thinking }

                let apiResult = await llmRepo.getVisionAnswer(screenshot: screenshot)

                switch apiResult {
                case .success(let answer):
                    settings.incrementTrialRequests()
                    settings.updateStreak()
                    result = AiResult(answer: answer.answer, explanation: answer.explanation, confidence: answer.confidence)

                    // Save to history
                    let entry = HistoryEntry(question: "Скріншот", answer: answer.answer, explanation: answer.explanation, confidence: answer.confidence)
                    await HistoryRepository.shared.save(entry)
                    await llmRepo.saveToContext(question: "Скріншот", answer: answer.answer)

                    withAnimation { status = .done }

                    // Return Live Activity to recording state
                    if liveActivityManager.isActivityActive {
                        liveActivityManager.markRecording()
                    }

                case .failure(let error):
                    result = AiResult(answer: "", isError: true, errorMessage: error.localizedDescription)
                    withAnimation { status = .error }

                    if liveActivityManager.isActivityActive {
                        liveActivityManager.markError()
                    }
                }
            } else {
                result = AiResult(answer: "", isError: true, errorMessage: "Не вдалося зробити скріншот")
                withAnimation { status = .error }
            }
        }
    }

    private func sendManualPrompt() {
        guard !manualPromptText.isEmpty else { return }

        withAnimation { status = .thinking }

        Task {
            let screenshot = captureService.captureScreenshot()

            if let screenshot {
                let apiResult = await llmRepo.getVisionAnswer(screenshot: screenshot, userQuestion: manualPromptText)

                switch apiResult {
                case .success(let answer):
                    result = AiResult(answer: answer.answer, explanation: answer.explanation, confidence: answer.confidence, isManualPrompt: true)
                    let entry = HistoryEntry(question: manualPromptText, answer: answer.answer,
                                             explanation: answer.explanation, confidence: answer.confidence)
                    await HistoryRepository.shared.save(entry)
                    await llmRepo.saveToContext(question: manualPromptText, answer: answer.answer)
                    withAnimation { status = .done }
                case .failure(let error):
                    result = AiResult(answer: "", isError: true, errorMessage: error.localizedDescription)
                    withAnimation { status = .error }
                }
            }
            manualPromptText = ""
        }
    }

    private func startSummaryMode() {
        guard settings.canMakeSummary() else { return }
        captureService.startSummaryMode()
        withAnimation { status = .summaryCollecting(current: 0, total: captureService.summaryMaxCount) }
    }

    private func addSummaryScreenshot() {
        if let screenshot = captureService.captureScreenshot() {
            captureService.addSummaryScreenshot(screenshot)
            withAnimation { status = .summaryCollecting(current: captureService.summaryScreenshots.count, total: captureService.summaryMaxCount) }
        }
    }

    private func completeSummary() {
        let screenshots = captureService.completeSummaryMode()
        guard !screenshots.isEmpty else { return }

        withAnimation { status = .thinking }
        settings.incrementSummaryCount()

        Task {
            let apiResult = await llmRepo.getSummaryAnswer(screenshots: screenshots, mode: settings.summaryMode)

            switch apiResult {
            case .success(let answer):
                summaryText = answer.answer
                result = AiResult(answer: "Конспект створено!", explanation: "")
                withAnimation { status = .done }
                // Save summary to history
                let historyEntry = HistoryEntry(
                    question: "📝 Конспект",
                    answer: answer.answer,
                    explanation: "",
                    confidence: 0.9,
                    appPackage: "com.qurio.ios"
                )
                await HistoryRepository.shared.save(historyEntry)
            case .failure(let error):
                result = AiResult(answer: "", isError: true, errorMessage: error.localizedDescription)
                withAnimation { status = .error }
            }
        }
    }

    private func generateTestFromSummary(_ summary: String) {
        isGeneratingTest = true
        Task {
            let testResult = await llmRepo.generateTest(summaryText: summary)
            isGeneratingTest = false
            switch testResult {
            case .success(let questions):
                testQuestions = questions
                showTestView = true
            case .failure(let error):
                result = AiResult(answer: "", isError: true, errorMessage: "Не вдалося створити тест: \(error.localizedDescription)")
                withAnimation { status = .error }
            }
        }
    }

    private func reset() {
        status = .idle
        result = nil
        summaryText = nil
        showManualPrompt = false
        manualPromptText = ""
        testQuestions = []
        isGeneratingTest = false
    }
}
