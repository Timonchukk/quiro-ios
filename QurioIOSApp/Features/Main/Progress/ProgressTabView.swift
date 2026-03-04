import SwiftUI

/// Progress tab — glass-morphism redesign.
/// Shows streak counter, timeline milestones, and reward cards.
struct ProgressTabView: View {
    @EnvironmentObject var settings: SettingsRepository
    @Environment(\.appTheme) var theme
    
    @State private var showRewardsDialog = false
    @State private var selectedMilestone: StreakMilestone?
    
    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: DesignTokens.spacingXL) {
                    // Header
                    Text("Прогрес")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(theme.textPrimary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 8)
                    
                    // Streak Counter
                    streakCounterCard
                    
                    // Milestones
                    milestonesSection
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 30)
            }
            .background(theme.background.ignoresSafeArea())
            .navigationBarHidden(true)
        }
        .sheet(item: $selectedMilestone) { milestone in
            StreakRewardClaimSheet(milestone: milestone)
        }
    }
    
    // MARK: - Streak Counter Card
    
    private var streakCounterCard: some View {
        GlassCard(cornerRadius: DesignTokens.radiusXL) {
            VStack(spacing: 18) {
                // Flame icon with gradient ring
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [Color.streakOrange.opacity(0.2), Color.streakOrange.opacity(0.05)],
                                center: .center, startRadius: 0, endRadius: 50
                            )
                        )
                        .frame(width: 90, height: 90)
                    
                    Circle()
                        .stroke(Color.streakOrange.opacity(0.3), lineWidth: 2)
                        .frame(width: 90, height: 90)
                    
                    Image(systemName: "flame.fill")
                        .font(.system(size: 38))
                        .foregroundColor(.streakOrange)
                }
                
                // Count
                Text("\(settings.currentStreakCount())")
                    .font(.system(size: 56, weight: .bold, design: .rounded))
                    .foregroundColor(theme.textPrimary)
                
                Text(settings.isStreakActiveToday() ? "днів поспіль! 🔥" : "днів серія")
                    .font(.system(size: 16))
                    .foregroundColor(theme.textSecondary)
                
                // Status pill
                HStack(spacing: 8) {
                    Image(systemName: settings.isStreakActiveToday() ? "checkmark.circle.fill" : "xmark.circle")
                        .foregroundColor(settings.isStreakActiveToday() ? .summaryGreen : .accentRed)
                    Text(settings.isStreakActiveToday() ? "Сьогодні активовано" : "Зробіть запит для серії!")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(settings.isStreakActiveToday() ? .summaryGreen : .accentRed)
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 16)
                .background(
                    Capsule().fill(
                        (settings.isStreakActiveToday() ? Color.summaryGreen : .accentRed).opacity(0.1)
                    )
                )
            }
            .padding(DesignTokens.paddingXL)
            .frame(maxWidth: .infinity)
        }
    }
    
    // MARK: - Milestones
    
    private var milestonesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Нагороди за серію")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(theme.textPrimary)
            
            VStack(spacing: 10) {
                ForEach(streakMilestones) { milestone in
                    MilestoneRow(
                        milestone: milestone,
                        currentStreak: settings.currentStreakCount(),
                        isClaimed: settings.isRewardClaimed(day: milestone.day),
                        onClaim: {
                            HapticManager.impact(.medium)
                            selectedMilestone = milestone
                        }
                    )
                }
            }
        }
    }
}

// MARK: - Milestone Row

struct MilestoneRow: View {
    @Environment(\.appTheme) var theme
    let milestone: StreakMilestone
    let currentStreak: Int
    let isClaimed: Bool
    let onClaim: () -> Void
    
    private var isUnlocked: Bool { currentStreak >= milestone.day }
    
    var body: some View {
        GlassCard(cornerRadius: DesignTokens.radiusMedium) {
            HStack(spacing: 14) {
                // Status icon circle
                IconCircle(
                    isClaimed ? "checkmark" : milestone.iconName,
                    tint: isClaimed ? .summaryGreen : (isUnlocked ? .accentPurple : .gray),
                    size: 44
                )
                .opacity(isUnlocked || isClaimed ? 1 : 0.5)
                
                VStack(alignment: .leading, spacing: 3) {
                    Text("День \(milestone.day)")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(isUnlocked ? theme.textPrimary : theme.textTertiary)
                    
                    Text(milestone.label)
                        .font(.system(size: 13))
                        .foregroundColor(isUnlocked ? theme.textSecondary : theme.textTertiary)
                }
                
                Spacer()
                
                if isClaimed {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.summaryGreen)
                } else if isUnlocked {
                    Button(action: onClaim) {
                        Text("Забрати")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 7)
                            .background(
                                LinearGradient(
                                    colors: [.accentPurple, .violet],
                                    startPoint: .leading, endPoint: .trailing
                                )
                            )
                            .clipShape(Capsule())
                    }
                } else {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 14))
                        .foregroundColor(theme.textTertiary)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
        }
        .opacity(isUnlocked || isClaimed ? 1 : 0.6)
    }
}

// MARK: - Streak Rewards Dialog

struct StreakRewardsDialog: View {
    @EnvironmentObject var settings: SettingsRepository
    @Environment(\.dismiss) var dismiss
    @Environment(\.appTheme) var theme
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 12) {
                    ForEach(streakMilestones) { milestone in
                        MilestoneRow(
                            milestone: milestone,
                            currentStreak: settings.currentStreakCount(),
                            isClaimed: settings.isRewardClaimed(day: milestone.day),
                            onClaim: {
                                HapticManager.notification(.success)
                                _ = settings.claimReward(day: milestone.day)
                                Task { await AuthRepository.shared.syncStreakToServer() }
                            }
                        )
                    }
                }
                .padding()
            }
            .background(theme.background)
            .navigationTitle("Нагороди за серію 🎁")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Готово") { dismiss() }
                        .foregroundColor(.accentPurple)
                }
            }
        }
    }
}

// MARK: - Streak Reward Claim Sheet

struct StreakRewardClaimSheet: View {
    @EnvironmentObject var settings: SettingsRepository
    @Environment(\.dismiss) var dismiss
    let milestone: StreakMilestone
    @State private var claimed = false
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            ZStack {
                Circle()
                    .fill(Color.accentPurple.opacity(0.1))
                    .frame(width: 100, height: 100)
                Image(systemName: milestone.iconName)
                    .font(.system(size: 48))
                    .foregroundColor(.accentPurple)
            }
            
            Text("День \(milestone.day)!")
                .font(.system(size: 28, weight: .bold, design: .rounded))
            
            Text(milestone.label)
                .font(.system(size: 18))
                .foregroundColor(.secondary)
            
            if claimed {
                VStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 48))
                        .foregroundColor(.summaryGreen)
                    Text("Нагороду отримано!")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.summaryGreen)
                }
                .transition(.scale.combined(with: .opacity))
            } else {
                AccentButton("Забрати нагороду", icon: "gift") {
                    if settings.claimReward(day: milestone.day) {
                        HapticManager.notification(.success)
                        withAnimation(.spring()) { claimed = true }
                        Task { await AuthRepository.shared.syncStreakToServer() }
                    }
                }
                .padding(.horizontal, 40)
            }
            
            Spacer()
            
            Button("Закрити") {
                dismiss()
            }
            .foregroundColor(.accentPurple)
            .font(.system(size: 16, weight: .medium))
            .padding(.bottom, 30)
        }
        .padding()
    }
}
