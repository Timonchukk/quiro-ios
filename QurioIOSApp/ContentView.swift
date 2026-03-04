import SwiftUI

/// Root navigation: Auth → Onboarding → MainView
/// Mirrors MainActivity.kt navigation logic.
struct ContentView: View {
    @EnvironmentObject var settings: SettingsRepository
    @EnvironmentObject var authRepo: AuthRepository
    @Environment(\.appTheme) var theme
    
    var body: some View {
        Group {
            if !settings.isLoggedIn {
                AuthView()
            } else if !settings.onboardingCompleted {
                OnboardingView(
                    onSkip: { settings.onboardingCompleted = true },
                    onComplete: { settings.onboardingCompleted = true }
                )
            } else {
                MainView()
            }
        }
        .animation(.easeInOut(duration: 0.3), value: settings.isLoggedIn)
        .animation(.easeInOut(duration: 0.3), value: settings.onboardingCompleted)
        .task {
            // Sync on app launch if logged in
            if settings.isLoggedIn {
                // 1. Check StoreKit subscriptions FIRST (local only)
                await InAppPurchaseService.shared.updateSubscriptionStatus()
                // 2. Then sync from server — server Pro status OVERRIDES local
                try? await authRepo.syncSettings()
                // 3. Fetch profile to get subscription.active from server
                try? await authRepo.getProfile()
                // 4. Sync history & streak
                await HistoryRepository.shared.pushAllToServer()
                await HistoryRepository.shared.syncFromServer()
                try? await authRepo.syncStreakToServer()
                settings.checkRewardProExpiry()
            }
        }
    }
}
