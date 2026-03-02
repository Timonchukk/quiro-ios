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
                await HistoryRepository.shared.syncFromServer()
                settings.checkRewardProExpiry()
                await InAppPurchaseService.shared.updateSubscriptionStatus()
            }
        }
    }
}
