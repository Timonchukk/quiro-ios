import SwiftUI
import StoreKit

/// Profile screen — glass-morphism redesign.
/// User info, plan, subscription, AI/overlay/test settings, admin entry.
struct ProfileView: View {
    @EnvironmentObject var settings: SettingsRepository
    @EnvironmentObject var purchaseService: InAppPurchaseService
    @Environment(\.appTheme) var theme
    
    @State private var showSetPassword = false
    @State private var showDeleteConfirm = false
    @State private var showAdmin = false
    @State private var newPassword = ""
    @State private var isSettingPassword = false
    
    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: DesignTokens.spacingLarge) {
                    // Header
                    Text("Профіль")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(theme.textPrimary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 8)
                    
                    // User Info Card
                    userInfoCard
                    
                    // Subscription Card
                    subscriptionCard
                    
                    // AI Settings
                    aiSettingsSection
                    
                    // Test Settings
                    testSettingsSection
                    
                    // Account Actions
                    accountActionsSection
                    
                    // Admin Entry (if admin)
                    if settings.isAdmin {
                        adminEntry
                    }
                    
                    // App Version
                    Text("Quiro iOS v1.0.0")
                        .font(.system(size: 12))
                        .foregroundColor(theme.textTertiary)
                        .padding(.top, 8)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 30)
            }
            .background(theme.background.ignoresSafeArea())
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showAdmin) {
            AdminView()
        }
    }
    
    // MARK: - User Info Card
    
    private var userInfoCard: some View {
        GlassCard(cornerRadius: DesignTokens.radiusXL) {
            HStack(spacing: 14) {
                // Avatar
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(colors: [.accentPurple, .violet],
                                           startPoint: .topLeading,
                                           endPoint: .bottomTrailing)
                        )
                        .frame(width: 52, height: 52)
                    
                    Text(String(settings.userName.prefix(1)).uppercased())
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(settings.userName.isEmpty ? "Quiro User" : settings.userName)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(theme.textPrimary)
                    
                    Text(settings.userEmail.isEmpty ? "" : settings.userEmail)
                        .font(.system(size: 13))
                        .foregroundColor(theme.textSecondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                    
                    if settings.isGoogleUser {
                        ChipBadge("Google", icon: "g.circle", tint: .blue)
                    }
                }
                
                Spacer()
                
                ChipBadge(
                    settings.hasActiveSubscription ? "Pro" : "Free",
                    icon: settings.hasActiveSubscription ? "crown.fill" : "person.fill",
                    tint: settings.hasActiveSubscription ? .yellowDot : .accentPurple
                )
            }
            .padding(DesignTokens.paddingLarge)
        }
    }
    
    // MARK: - Subscription Card
    
    private var subscriptionCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: DesignTokens.spacingMedium) {
                HStack {
                    IconCircle("crown.fill", tint: .yellowDot, size: 34)
                    Text("Підписка")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(theme.textPrimary)
                }
                
                Divider().opacity(0.15)
                
                if settings.hasActiveSubscription {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundColor(.summaryGreen)
                        Text("Pro план активний")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.summaryGreen)
                    }
                } else {
                    Text("Оновіть для необмежених запитів та конспектів")
                        .font(.system(size: 14))
                        .foregroundColor(theme.textSecondary)
                    
                    // IAP products
                    if !purchaseService.products.isEmpty {
                        ForEach(purchaseService.products, id: \.id) { product in
                            Button(action: {
                                HapticManager.impact(.medium)
                                Task { try? await purchaseService.purchase(product) }
                            }) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(product.displayName)
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundColor(theme.textPrimary)
                                        Text(product.description)
                                            .font(.system(size: 12))
                                            .foregroundColor(theme.textSecondary)
                                    }
                                    Spacer()
                                    Text(product.displayPrice)
                                        .font(.system(size: 15, weight: .bold))
                                        .foregroundColor(.accentPurple)
                                }
                                .padding(DesignTokens.paddingMedium)
                                .background(
                                    RoundedRectangle(cornerRadius: DesignTokens.radiusSmall)
                                        .fill(Color.accentPurple.opacity(0.08))
                                )
                            }
                        }
                    }
                    
                    Button("Відновити покупки") {
                        Task { await purchaseService.restorePurchases() }
                    }
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.accentPurple)
                }
            }
            .padding(DesignTokens.paddingLarge)
        }
    }
    
    // MARK: - AI Settings
    
    private var aiSettingsSection: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: DesignTokens.spacingMedium) {
                HStack {
                    IconCircle("brain", tint: .accentPurple, size: 34)
                    Text("Налаштування AI")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(theme.textPrimary)
                }
                
                Divider().opacity(0.15)
                
                SettingsToggle(
                    title: "Пояснення",
                    subtitle: "Показувати пояснення до відповідей",
                    icon: "lightbulb",
                    isOn: $settings.showExplanation
                )
                
                SettingsToggle(
                    title: "Режим приватності",
                    subtitle: "Не зберігати контекст між запитами",
                    icon: "lock.shield",
                    isOn: $settings.privacyMode
                )
                
                Divider().opacity(0.15)
                
                // Summary mode
                VStack(alignment: .leading, spacing: 8) {
                    Text("Режим конспекту")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(theme.textPrimary)
                    
                    pillPicker(
                        selection: $settings.summaryMode,
                        options: SummaryMode.allCases.map { ($0.rawValue, $0.title) }
                    )
                }
                
                Divider().opacity(0.15)
                
                // Theme
                VStack(alignment: .leading, spacing: 8) {
                    Text("Тема")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(theme.textPrimary)
                    
                    pillPicker(
                        selection: $settings.themeMode,
                        options: [(1, "Світла"), (2, "Темна")]
                    )
                }
            }
            .padding(DesignTokens.paddingLarge)
        }
    }
    
    // MARK: - Pill Picker
    
    private func pillPicker(selection: Binding<Int>, options: [(Int, String)]) -> some View {
        HStack(spacing: 0) {
            ForEach(options, id: \.0) { option in
                Button(action: {
                    HapticManager.selection()
                    withAnimation(.spring(response: 0.3)) { selection.wrappedValue = option.0 }
                }) {
                    Text(option.1)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(selection.wrappedValue == option.0 ? .white : theme.textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 9)
                        .background(
                            Group {
                                if selection.wrappedValue == option.0 {
                                    RoundedRectangle(cornerRadius: 8)
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
        }
        .padding(3)
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.radiusSmall)
                .fill(theme.glassBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: DesignTokens.radiusSmall)
                .stroke(theme.glassBorder, lineWidth: 0.5)
        )
    }
    
    // MARK: - Test Settings
    
    private var testSettingsSection: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: DesignTokens.spacingMedium) {
                HStack {
                    IconCircle("checkmark.circle", tint: .summaryGreen, size: 34)
                    Text("Налаштування тестів")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(theme.textPrimary)
                }
                
                Divider().opacity(0.15)
                
                // Question count
                HStack {
                    Text("Кількість питань")
                        .font(.system(size: 14))
                        .foregroundColor(theme.textPrimary)
                    Spacer()
                    Stepper("\(settings.testQuestionCount)",
                            value: $settings.testQuestionCount,
                            in: 3...24)
                        .font(.system(size: 14))
                        .onChange(of: settings.testQuestionCount) { _ in
                            HapticManager.selection()
                        }
                }
                
                // Time limit
                HStack {
                    Text("Обмеження часу (хв)")
                        .font(.system(size: 14))
                        .foregroundColor(theme.textPrimary)
                    Spacer()
                    Stepper(settings.testTimeLimitMinutes == 0 ? "Без обмежень" : "\(settings.testTimeLimitMinutes) хв",
                            value: $settings.testTimeLimitMinutes,
                            in: 0...60)
                        .font(.system(size: 14))
                        .onChange(of: settings.testTimeLimitMinutes) { _ in
                            HapticManager.selection()
                        }
                }
                
                SettingsToggle(
                    title: "Показувати відповіді",
                    subtitle: "Після завершення тесту",
                    icon: "eye",
                    isOn: $settings.testShowAnswers
                )
            }
            .padding(DesignTokens.paddingLarge)
        }
    }
    
    // MARK: - Account Actions
    
    private var accountActionsSection: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    IconCircle("person.circle", tint: .accentPurple, size: 34)
                    Text("Акаунт")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(theme.textPrimary)
                }
                .padding(.bottom, DesignTokens.spacingMedium)
                
                Divider().opacity(0.15)
                
                if settings.isGoogleUser {
                    Button(action: { showSetPassword = true }) {
                        SettingsRow(icon: "key", title: "Встановити пароль", tint: .accentPurple)
                    }
                    .padding(.vertical, DesignTokens.spacingMedium)
                    
                    Divider().opacity(0.15)
                }
                
                Button(action: {
                    HapticManager.impact(.medium)
                    Task {
                        await HistoryRepository.shared.pushAllToServer()
                        await HistoryRepository.shared.clearLocalData()
                        settings.logout()
                    }
                }) {
                    SettingsRow(icon: "arrow.right.square", title: "Вийти", tint: .accentRed)
                }
                .padding(.vertical, DesignTokens.spacingMedium)
            }
            .padding(DesignTokens.paddingLarge)
        }
        .alert("Встановити пароль", isPresented: $showSetPassword) {
            SecureField("Новий пароль", text: $newPassword)
            Button("Встановити") {
                Task {
                    do {
                        try await AuthRepository.shared.setPassword(password: newPassword)
                        newPassword = ""
                    } catch {
                        print("Failed: \(error)")
                    }
                }
            }
            Button("Скасувати", role: .cancel) {}
        }
    }
    
    // MARK: - Admin Entry
    
    private var adminEntry: some View {
        Button(action: {
            HapticManager.selection()
            showAdmin = true
        }) {
            GlassCard {
                HStack(spacing: 12) {
                    IconCircle("shield.fill", tint: .accentRed, size: 34)
                    
                    Text("Адмін панель")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(theme.textPrimary)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 13))
                        .foregroundColor(theme.textTertiary)
                }
                .padding(DesignTokens.paddingLarge)
            }
        }
    }
}

// MARK: - Settings Components

struct SettingsToggle: View {
    @Environment(\.appTheme) var theme
    let title: String
    let subtitle: String
    let icon: String
    @Binding var isOn: Bool
    
    var body: some View {
        Toggle(isOn: $isOn) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .foregroundColor(.accentPurple)
                    .frame(width: 20)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(theme.textPrimary)
                    Text(subtitle)
                        .font(.system(size: 12))
                        .foregroundColor(theme.textSecondary)
                }
            }
        }
        .tint(.accentPurple)
        .onChange(of: isOn) { _ in
            HapticManager.selection()
        }
    }
}

struct SettingsRow: View {
    let icon: String
    let title: String
    let tint: Color
    
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 15))
                .foregroundColor(tint)
                .frame(width: 20)
            Text(title)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(tint)
            Spacer()
            Image(systemName: "chevron.right")
                .font(.system(size: 12))
                .foregroundColor(tint.opacity(0.5))
        }
    }
}
