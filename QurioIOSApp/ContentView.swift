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
                try? await authRepo.syncSettings()
                // Same user re-opening — push local data then sync from server
                await HistoryRepository.shared.pushAllToServer()
                await HistoryRepository.shared.syncFromServer()
                // Push local streak (including claimed rewards) to server
                try? await authRepo.syncStreakToServer()
                settings.checkRewardProExpiry()
                await InAppPurchaseService.shared.updateSubscriptionStatus()
            }
        }
    }
}
