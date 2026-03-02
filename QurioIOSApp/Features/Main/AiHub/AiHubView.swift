import SwiftUI

/// AI Hub screen mirroring AiHubScreen.kt (894 lines).
/// Header with plan badge, stats row, action button, quick actions grid.
struct AiHubView: View {
    @EnvironmentObject var settings: SettingsRepository
    @EnvironmentObject var purchaseService: InAppPurchaseService
    @Environment(\.appTheme) var theme
    @Binding var showOverlay: Bool
    
    @State private var breathScale: CGFloat = 1.0
    @State private var showStreakRewards = false
    
    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    // Header Section
                    headerSection
                    
                    // Stats Row
                    statsRow
                    
                    // Action Button (Start/Stop Qurio)
                    actionButton
                    
                    // Quick Actions Grid
                    quickActionsGrid
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 30)
            }
            .background(theme.background.ignoresSafeArea())
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showStreakRewards) {
            StreakRewardsDialog()
        }
    }
    
    // MARK: - Header
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Привіт! 👋")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(theme.textPrimary)
                    
                    Text(settings.userName.isEmpty ? "Qurio AI" : settings.userName)
                        .font(.system(size: 16))
                        .foregroundColor(theme.textSecondary)
                }
                
                Spacer()
                
                // Plan badge
                ChipBadge(
                    settings.hasActiveSubscription ? "Pro" : "Free",
                    icon: settings.hasActiveSubscription ? "crown.fill" : "person.fill",
                    tint: settings.hasActiveSubscription ? .yellowDot : .accentPurple
                )
            }
            
            // Streak pill
            if settings.currentStreakCount() > 0 {
                ChipBadge(
                    "\(settings.currentStreakCount()) днів 🔥",
                    icon: "flame.fill",
                    tint: .streakOrange,
                    bgAlpha: 0.15,
                    onClick: { showStreakRewards = true }
                )
            }
        }
        .padding(.top, 8)
    }
    
    // MARK: - Stats Row
    
    private var statsRow: some View {
        HStack(spacing: 12) {
            MiniStatCard(
                value: settings.hasActiveSubscription ? "∞" : "\(settings.remainingTrialRequests())",
                label: "Запитів",
                icon: "bolt.fill",
                tint: .accentPurple
            )
            
            MiniStatCard(
                value: "\(settings.currentStreakCount())",
                label: "Серія",
                icon: "flame.fill",
                tint: .streakOrange
            )
            
            MiniStatCard(
                value: settings.hasActiveSubscription ? "\(settings.remainingSummaries())" : "—",
                label: "Конспекти",
                icon: "doc.text.fill",
                tint: .summaryGreen
            )
        }
    }
    
    // MARK: - Action Button
    
    private var actionButton: some View {
        Button(action: {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                showOverlay.toggle()
            }
        }) {
            HStack(spacing: 12) {
                Image(systemName: showOverlay ? "stop.fill" : "play.fill")
                    .font(.system(size: 22, weight: .bold))
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(showOverlay ? "Зупинити Qurio" : "Запустити Qurio")
                        .font(.system(size: 18, weight: .bold))
                    
                    if !showOverlay {
                        Text(settings.hasActiveSubscription
                             ? "Необмежені запити"
                             : "Залишилось \(settings.remainingTrialRequests()) запитів")
                            .font(.system(size: 13))
                            .opacity(0.7)
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .opacity(0.5)
            }
            .foregroundColor(.white)
            .padding(.horizontal, 20)
            .padding(.vertical, 18)
            .background(
                LinearGradient(
                    colors: showOverlay
                        ? [Color.accentRed, Color.accentRed.opacity(0.8)]
                        : [Color.accentPurple, Color.violet],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .shadow(
                color: (showOverlay ? Color.accentRed : .accentPurple).opacity(0.35),
                radius: 12, y: 6
            )
            .scaleEffect(breathScale)
        }
        .onAppear {
            if !showOverlay {
                withAnimation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true)) {
                    breathScale = 1.03
                }
            }
        }
    }
    
    // MARK: - Quick Actions
    
    private var quickActionsGrid: some View {
        VStack(spacing: 12) {
            Text("Швидкі дії")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(theme.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12)
            ], spacing: 12) {
                QuickActionTile(
                    title: "Пояснення",
                    subtitle: settings.showExplanation ? "Увімкнено" : "Вимкнено",
                    icon: "lightbulb.fill",
                    tint: .yellowDot,
                    isActive: settings.showExplanation
                ) {
                    settings.showExplanation.toggle()
                }
                
                QuickActionTile(
                    title: "Конспект",
                    subtitle: SummaryMode(rawValue: settings.summaryMode)?.title ?? "Детальний",
                    icon: "doc.text.fill",
                    tint: .summaryGreen,
                    isActive: true
                ) {
                    settings.summaryMode = (settings.summaryMode + 1) % 3
                }
                
                QuickActionTile(
                    title: "Тема",
                    subtitle: settings.themeMode == 2 ? "Темна" : "Світла",
                    icon: settings.themeMode == 2 ? "moon.fill" : "sun.max.fill",
                    tint: .violet,
                    isActive: settings.themeMode == 2
                ) {
                    settings.themeMode = settings.themeMode == 2 ? 1 : 2
                }
                
                QuickActionTile(
                    title: "Приватність",
                    subtitle: settings.privacyMode ? "Увімкнено" : "Вимкнено",
                    icon: "lock.shield.fill",
                    tint: .accentPurple,
                    isActive: settings.privacyMode
                ) {
                    settings.privacyMode.toggle()
                }
            }
        }
    }
}

// MARK: - Mini Stat Card

struct MiniStatCard: View {
    @Environment(\.appTheme) var theme
    let value: String
    let label: String
    let icon: String
    let tint: Color
    
    var body: some View {
        GlassSection {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(tint)
                
                Text(value)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(theme.textPrimary)
                
                Text(label)
                    .font(.system(size: 11))
                    .foregroundColor(theme.textSecondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
        }
    }
}

// MARK: - Quick Action Tile

struct QuickActionTile: View {
    @Environment(\.appTheme) var theme
    let title: String
    let subtitle: String
    let icon: String
    let tint: Color
    let isActive: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            GlassSection {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: icon)
                            .font(.system(size: 18))
                            .foregroundColor(tint)
                        Spacer()
                        Circle()
                            .fill(isActive ? tint : Color.gray.opacity(0.3))
                            .frame(width: 8, height: 8)
                    }
                    
                    Text(title)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(theme.textPrimary)
                    
                    Text(subtitle)
                        .font(.system(size: 12))
                        .foregroundColor(theme.textSecondary)
                }
                .padding(14)
            }
        }
    }
}
