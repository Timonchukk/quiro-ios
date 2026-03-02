import SwiftUI
import SwiftData

@main
struct QurioApp: App {
    @StateObject private var settings = SettingsRepository.shared
    @StateObject private var authRepo = AuthRepository.shared
    @StateObject private var historyRepo = HistoryRepository.shared
    @StateObject private var purchaseService = InAppPurchaseService.shared
    @StateObject private var captureService = ScreenCaptureService.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(settings)
                .environmentObject(authRepo)
                .environmentObject(historyRepo)
                .environmentObject(purchaseService)
                .environmentObject(captureService)
                .environment(\.appTheme, AppTheme(isDark: settings.themeMode == 2))
                .preferredColorScheme(settings.themeMode == 2 ? .dark : .light)
        }
    }
}
