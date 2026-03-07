import SwiftUI

/// AI Hub screen — glass-morphism redesign.
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
                VStack(spacing: DesignTokens.spacingLarge) {
                    // Header Section
                    headerSection
                    
                    // Stats Row
                    statsRow
                    
                    // Action Button (Start/Stop Quiro)
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
        GlassCard(cornerRadius: DesignTokens.radiusXL) {
            VStack(alignment: .leading, spacing: DesignTokens.spacingMedium) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Привіт! 👋")
                            .font(.system(size: 26, weight: .bold, design: .rounded))
                            .foregroundColor(theme.textPrimary)
                        
                        Text(settings.userName.isEmpty ? "Quiro AI" : settings.userName)
                            .font(.system(size: 15))
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
            .padding(DesignTokens.paddingLarge)
        }
    }
    
    // MARK: - Stats Row
    
    private var statsRow: some View {
        HStack(spacing: DesignTokens.spacingMedium) {
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
            HapticManager.impact(.heavy)
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                showOverlay.toggle()
            }
        }) {
            HStack(spacing: 14) {
                // Icon circle
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.15))
                        .frame(width: 44, height: 44)
                    Image(systemName: showOverlay ? "stop.fill" : "play.fill")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: 3) {
                    Text(showOverlay ? "Зупинити Quiro" : "Запустити Quiro")
                        .font(.system(size: 17, weight: .bold))
                    
                    if !showOverlay {
                        Text(settings.hasActiveSubscription
                             ? "Необмежені запити"
                             : "Залишилось \(settings.remainingTrialRequests()) запитів")
                            .font(.system(size: 13))
                            .opacity(0.75)
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .opacity(0.5)
            }
            .foregroundColor(.white)
            .padding(.horizontal, DesignTokens.paddingLarge)
            .padding(.vertical, 18)
            .background(
                LinearGradient(
                    colors: showOverlay
                        ? [Color.accentRed, Color.accentRed.opacity(0.8)]
                        : [Color.accentBlue, Color.accentSky],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.radiusLarge))
            .shadow(
                color: (showOverlay ? Color.accentRed : .accentBlue).opacity(0.35),
                radius: 14, y: 6
            )
            .scaleEffect(breathScale)
        }
        .onAppear {
            if !showOverlay {
                withAnimation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true)) {
                    breathScale = 1.02
                }
            }
        }
    }
    
    // MARK: - Quick Actions
    
    private var quickActionsGrid: some View {
        VStack(spacing: DesignTokens.spacingMedium) {
            Text("Швидкі дії")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(theme.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: DesignTokens.spacingMedium),
                GridItem(.flexible(), spacing: DesignTokens.spacingMedium)
            ], spacing: DesignTokens.spacingMedium) {
                QuickActionTile(
                    title: "Пояснення",
                    subtitle: settings.showExplanation ? "Увімкнено" : "Вимкнено",
                    icon: "lightbulb.fill",
                    isActive: settings.showExplanation
                ) {
                    settings.showExplanation.toggle()
                }
                
                QuickActionTile(
                    title: "Конспект",
                    subtitle: SummaryMode(rawValue: settings.summaryMode)?.title ?? "Детальний",
                    icon: "doc.text.fill",
                    isActive: true
                ) {
                    settings.summaryMode = (settings.summaryMode + 1) % 3
                }
                
                QuickActionTile(
                    title: "Тема",
                    subtitle: settings.themeMode == 2 ? "Темна" : "Світла",
                    icon: settings.themeMode == 2 ? "moon.fill" : "sun.max.fill",
                    isActive: settings.themeMode == 2
                ) {
                    settings.themeMode = settings.themeMode == 2 ? 1 : 2
                }
                
                QuickActionTile(
                    title: "Приватність",
                    subtitle: settings.privacyMode ? "Увімкнено" : "Вимкнено",
                    icon: "lock.shield.fill",
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
        GlassCard(cornerRadius: DesignTokens.radiusLarge) {
            VStack(spacing: 8) {
                IconCircle(icon, tint: tint, size: 34)
                
                Text(value)
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundColor(theme.textPrimary)
                
                Text(label)
                    .font(.system(size: 11))
                    .foregroundColor(theme.textSecondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, DesignTokens.paddingMedium)
            .padding(.horizontal, 8)
        }
    }
}

// MARK: - Quick Action Tile

struct QuickActionTile: View {
    @Environment(\.appTheme) var theme
    let title: String
    let subtitle: String
    let icon: String
    let isActive: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            HapticManager.selection()
            action()
        }) {
            GlassCard(cornerRadius: DesignTokens.radiusLarge) {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        // Unified gradient icon circle (like Android)
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [.accentBlue, .accentSky],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 38, height: 38)
                            Image(systemName: icon)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                        }
                        Spacer()
                        Circle()
                            .fill(isActive ? Color.accentBlue : Color.gray.opacity(0.25))
                            .frame(width: 8, height: 8)
                    }
                    
                    Text(title)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(theme.textPrimary)
                    
                    Text(subtitle)
                        .font(.system(size: 12))
                        .foregroundColor(theme.textSecondary)
                }
                .padding(DesignTokens.paddingMedium)
            }
        }
    }
}
