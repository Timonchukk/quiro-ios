import SwiftUI

/// Profile screen mirroring ProfileScreen.kt.
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
                VStack(spacing: 20) {
                    // Header
                    Text("Профіль")
                        .font(.system(size: 28, weight: .bold))
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
                    Text("Qurio iOS v1.0.0")
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
        GlassCard {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(colors: [.accentPurple, .violet],
                                           startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                        .frame(width: 56, height: 56)
                    
                    Text(String(settings.userName.prefix(1)).uppercased())
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: 3) {
                    Text(settings.userName)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(theme.textPrimary)
                    
                    Text(settings.userEmail)
                        .font(.system(size: 14))
                        .foregroundColor(theme.textSecondary)
                    
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
            .padding(16)
        }
    }
    
    // MARK: - Subscription Card
    
    private var subscriptionCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "crown.fill")
                        .foregroundColor(.yellowDot)
                    Text("Підписка")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(theme.textPrimary)
                }
                
                if settings.hasActiveSubscription {
                    Text("✅ Pro план активний")
                        .font(.system(size: 14))
                        .foregroundColor(.summaryGreen)
                    
                    Text("• Необмежені запити\n• Конспекти\n• Тести\n• Пріоритетна підтримка")
                        .font(.system(size: 13))
                        .foregroundColor(theme.textSecondary)
                } else {
                    Text("Оновіть для необмежених запитів та конспектів")
                        .font(.system(size: 14))
                        .foregroundColor(theme.textSecondary)
                    
                    ForEach(purchaseService.products, id: \.id) { product in
                        Button(action: {
                            Task { try? await purchaseService.purchase(product) }
                        }) {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(product.displayName)
                                        .font(.system(size: 14, weight: .semibold))
                                    Text(product.description)
                                        .font(.system(size: 12))
                                        .foregroundColor(theme.textSecondary)
                                }
                                Spacer()
                                Text(product.displayPrice)
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.accentPurple)
                            }
                            .padding(12)
                            .background(RoundedRectangle(cornerRadius: 10).fill(Color.accentPurple.opacity(0.08)))
                        }
                    }
                    
                    Button("Відновити покупки") {
                        Task { await purchaseService.restorePurchases() }
                    }
                    .font(.system(size: 13))
                    .foregroundColor(.accentPurple)
                }
            }
            .padding(16)
        }
    }
    
    // MARK: - AI Settings
    
    private var aiSettingsSection: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Image(systemName: "brain")
                        .foregroundColor(.accentPurple)
                    Text("Налаштування AI")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(theme.textPrimary)
                }
                
                Divider().opacity(0.2)
                
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
                
                Divider().opacity(0.2)
                
                // Summary mode
                VStack(alignment: .leading, spacing: 8) {
                    Text("Режим конспекту")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(theme.textPrimary)
                    
                    Picker("", selection: $settings.summaryMode) {
                        ForEach(SummaryMode.allCases, id: \.rawValue) { mode in
                            Label(mode.title, systemImage: mode.icon)
                                .tag(mode.rawValue)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                
                Divider().opacity(0.2)
                
                // Theme
                VStack(alignment: .leading, spacing: 8) {
                    Text("Тема")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(theme.textPrimary)
                    
                    Picker("", selection: $settings.themeMode) {
                        Text("Світла").tag(1)
                        Text("Темна").tag(2)
                    }
                    .pickerStyle(.segmented)
                }
            }
            .padding(16)
        }
    }
    
    // MARK: - Test Settings
    
    private var testSettingsSection: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Image(systemName: "checkmark.circle")
                        .foregroundColor(.summaryGreen)
                    Text("Налаштування тестів")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(theme.textPrimary)
                }
                
                Divider().opacity(0.2)
                
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
                }
                
                SettingsToggle(
                    title: "Показувати відповіді",
                    subtitle: "Після завершення тесту",
                    icon: "eye",
                    isOn: $settings.testShowAnswers
                )
            }
            .padding(16)
        }
    }
    
    // MARK: - Account Actions
    
    private var accountActionsSection: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Image(systemName: "person.circle")
                        .foregroundColor(.accentPurple)
                    Text("Акаунт")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(theme.textPrimary)
                }
                
                Divider().opacity(0.2)
                
                if settings.isGoogleUser {
                    Button(action: { showSetPassword = true }) {
                        SettingsRow(icon: "key", title: "Встановити пароль", tint: .accentPurple)
                    }
                }
                
                Button(action: {
                    settings.logout()
                }) {
                    SettingsRow(icon: "arrow.right.square", title: "Вийти", tint: .accentRed)
                }
            }
            .padding(16)
        }
        .alert("Встановити пароль", isPresented: $showSetPassword) {
            SecureField("Новий пароль", text: $newPassword)
            Button("Встановити") {
                Task {
                    try? await AuthRepository.shared.setPassword(password: newPassword)
                    newPassword = ""
                }
            }
            Button("Скасувати", role: .cancel) {}
        }
    }
    
    // MARK: - Admin Entry
    
    private var adminEntry: some View {
        Button(action: { showAdmin = true }) {
            GlassCard {
                HStack(spacing: 12) {
                    Image(systemName: "shield.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.accentRed)
                    
                    Text("Адмін панель")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(theme.textPrimary)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .foregroundColor(theme.textTertiary)
                }
                .padding(16)
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
    }
}

struct SettingsRow: View {
    let icon: String
    let title: String
    let tint: Color
    
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .foregroundColor(tint)
                .frame(width: 20)
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(tint)
            Spacer()
            Image(systemName: "chevron.right")
                .font(.system(size: 12))
                .foregroundColor(tint.opacity(0.5))
        }
    }
}
