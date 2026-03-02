import SwiftUI

/// Progress tab mirroring ProgressScreen.kt.
/// Shows streak counter, timeline milestones, and reward cards.
struct ProgressTabView: View {
    @EnvironmentObject var settings: SettingsRepository
    @Environment(\.appTheme) var theme
    
    @State private var showRewardsDialog = false
    @State private var selectedMilestone: StreakMilestone?
    
    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    // Header
                    Text("Прогрес")
                        .font(.system(size: 28, weight: .bold))
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
        GlassCard {
            VStack(spacing: 16) {
                // Flame icon
                ZStack {
                    Circle()
                        .fill(Color.streakOrange.opacity(0.15))
                        .frame(width: 80, height: 80)
                    
                    Image(systemName: "flame.fill")
                        .font(.system(size: 36))
                        .foregroundColor(.streakOrange)
                }
                
                // Count
                Text("\(settings.currentStreakCount())")
                    .font(.system(size: 56, weight: .bold, design: .rounded))
                    .foregroundColor(theme.textPrimary)
                
                Text(settings.isStreakActiveToday() ? "днів поспіль! 🔥" : "днів серія")
                    .font(.system(size: 16))
                    .foregroundColor(theme.textSecondary)
                
                // Status
                HStack(spacing: 8) {
                    Image(systemName: settings.isStreakActiveToday() ? "checkmark.circle.fill" : "xmark.circle")
                        .foregroundColor(settings.isStreakActiveToday() ? .summaryGreen : .accentRed)
                    Text(settings.isStreakActiveToday() ? "Сьогодні активовано" : "Зробіть запит для серії!")
                        .font(.system(size: 14))
                        .foregroundColor(theme.textSecondary)
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 16)
                .background(
                    Capsule().fill(
                        (settings.isStreakActiveToday() ? Color.summaryGreen : .accentRed).opacity(0.1)
                    )
                )
            }
            .padding(24)
            .frame(maxWidth: .infinity)
        }
    }
    
    // MARK: - Milestones
    
    private var milestonesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Нагороди за серію")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(theme.textPrimary)
            
            VStack(spacing: 0) {
                ForEach(streakMilestones) { milestone in
                    MilestoneRow(
                        milestone: milestone,
                        currentStreak: settings.currentStreakCount(),
                        isClaimed: settings.isRewardClaimed(day: milestone.day),
                        onClaim: {
                            selectedMilestone = milestone
                        }
                    )
                    
                    if milestone.day != streakMilestones.last?.day {
                        // Timeline connector
                        HStack(spacing: 0) {
                            Spacer().frame(width: 23)
                            Rectangle()
                                .fill(theme.divider)
                                .frame(width: 2, height: 20)
                            Spacer()
                        }
                    }
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
        GlassSection {
            HStack(spacing: 14) {
                // Status circle
                ZStack {
                    Circle()
                        .fill(isClaimed ? Color.summaryGreen.opacity(0.15) : (isUnlocked ? Color.accentPurple.opacity(0.15) : theme.divider))
                        .frame(width: 46, height: 46)
                    
                    Image(systemName: isClaimed ? "checkmark" : milestone.iconName)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(isClaimed ? .summaryGreen : (isUnlocked ? .accentPurple : theme.textTertiary))
                }
                
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
                    Text("✓")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.summaryGreen)
                } else if isUnlocked {
                    Button("Забрати") { onClaim() }
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 7)
                        .background(Color.accentPurple)
                        .clipShape(Capsule())
                } else {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 14))
                        .foregroundColor(theme.textTertiary)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
        }
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
                VStack(spacing: 16) {
                    ForEach(streakMilestones) { milestone in
                        MilestoneRow(
                            milestone: milestone,
                            currentStreak: settings.currentStreakCount(),
                            isClaimed: settings.isRewardClaimed(day: milestone.day),
                            onClaim: {
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
            
            Image(systemName: milestone.iconName)
                .font(.system(size: 64))
                .foregroundColor(.accentPurple)
            
            Text("День \(milestone.day)!")
                .font(.system(size: 28, weight: .bold))
            
            Text(milestone.label)
                .font(.system(size: 18))
                .foregroundColor(.secondary)
            
            if claimed {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 48))
                    .foregroundColor(.summaryGreen)
                Text("Нагороду отримано!")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.summaryGreen)
            } else {
                AccentButton("Забрати нагороду", icon: "gift") {
                    if settings.claimReward(day: milestone.day) {
                        claimed = true
                        Task { await AuthRepository.shared.syncStreakToServer() }
                    }
                }
                .padding(.horizontal, 40)
            }
            
            Spacer()
            
            Button("Закрити") { dismiss() }
                .foregroundColor(.accentPurple)
                .padding(.bottom, 30)
        }
        .padding()
    }
}
