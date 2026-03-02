import SwiftUI

/// Main tab view with 4 tabs mirroring Android's MainScreen.kt.
struct MainView: View {
    @EnvironmentObject var settings: SettingsRepository
    @Environment(\.appTheme) var theme
    @State private var selectedTab = 0
    @State private var showOverlay = false
    
    var body: some View {
        ZStack {
            TabView(selection: $selectedTab) {
                AiHubView(showOverlay: $showOverlay)
                    .tabItem {
                        Image(systemName: "brain.head.profile")
                        Text("AI Хаб")
                    }
                    .tag(0)
                
                ProgressTabView()
                    .tabItem {
                        Image(systemName: "flame.fill")
                        Text("Прогрес")
                    }
                    .tag(1)
                
                HistoryView()
                    .tabItem {
                        Image(systemName: "clock.arrow.circlepath")
                        Text("Історія")
                    }
                    .tag(2)
                
                ProfileView()
                    .tabItem {
                        Image(systemName: "person.fill")
                        Text("Профіль")
                    }
                    .tag(3)
            }
            .tint(.accentPurple)
            
            // Dynamic Island Overlay
            if showOverlay {
                DynamicIslandOverlay(isVisible: $showOverlay)
            }
        }
    }
}
