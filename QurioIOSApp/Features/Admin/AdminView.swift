import SwiftUI
import Combine

/// Admin panel mirroring AdminScreen.kt.
/// API keys CRUD, user management, stats dashboard.
struct AdminView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.appTheme) var theme
    @StateObject private var viewModel = AdminViewModel()
    @State private var selectedTab = 0
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("", selection: $selectedTab) {
                    Text("Ключі").tag(0)
                    Text("Юзери").tag(1)
                    Text("Статистика").tag(2)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                
                switch selectedTab {
                case 0: keysTab
                case 1: usersTab
                case 2: statsTab
                default: EmptyView()
                }
            }
            .background(theme.background)
            .navigationTitle("Адмін панель")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Готово") { dismiss() }
                }
            }
            .task {
                await viewModel.loadAll()
            }
        }
    }
    
    // MARK: - Keys Tab
    
    private var keysTab: some View {
        VStack(spacing: 12) {
            // Add key
            HStack {
                TextField("API ключ", text: $viewModel.newKey)
                    .textFieldStyle(.roundedBorder)
                Button(action: { Task { await viewModel.addKey() } }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.accentPurple)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            
            if viewModel.isLoading {
                ProgressView().padding()
            }
            
            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(viewModel.keys, id: \.self) { key in
                        let keyDict = key
                        GlassSection {
                            VStack(alignment: .leading, spacing: 6) {
                                Text(keyDict["key"] as? String ?? "")
                                    .font(.system(size: 13, design: .monospaced))
                                    .foregroundColor(theme.textPrimary)
                                    .lineLimit(1)
                                
                                if let assigned = keyDict["assignedEmail"] as? String, !assigned.isEmpty {
                                    Text("→ \(assigned)")
                                        .font(.system(size: 12))
                                        .foregroundColor(.accentPurple)
                                }
                                
                                HStack {
                                    if let id = keyDict["_id"] as? String {
                                        Button("Звільнити") {
                                            Task { try? await AuthRepository.shared.adminFreeKey(id: id) }
                                        }
                                        .font(.system(size: 12))
                                        .foregroundColor(.yellowDot)
                                        
                                        Spacer()
                                        
                                        Button("Видалити") {
                                            Task { try? await AuthRepository.shared.adminDeleteKey(id: id) }
                                        }
                                        .font(.system(size: 12))
                                        .foregroundColor(.accentRed)
                                    }
                                }
                            }
                            .padding(12)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 30)
            }
        }
    }
    
    // MARK: - Users Tab
    
    private var usersTab: some View {
        ScrollView {
            if viewModel.isLoading {
                ProgressView().padding()
            }
            
            LazyVStack(spacing: 8) {
                ForEach(viewModel.users, id: \.self) { user in
                    GlassSection {
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text(user["name"] as? String ?? "No name")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(theme.textPrimary)
                                
                                Spacer()
                                
                                if user["hasActiveSubscription"] as? Bool == true {
                                    ChipBadge("Pro", icon: "crown.fill", tint: .yellowDot)
                                }
                            }
                            
                            Text(user["email"] as? String ?? "")
                                .font(.system(size: 13))
                                .foregroundColor(theme.textSecondary)
                            
                            if let key = user["apiKey"] as? String, !key.isEmpty {
                                Text("Key: \(String(key.prefix(12)))...")
                                    .font(.system(size: 11, design: .monospaced))
                                    .foregroundColor(theme.textTertiary)
                            }
                            
                            HStack(spacing: 12) {
                                if let id = user["_id"] as? String {
                                    Button("Pro") {
                                        Task { try? await AuthRepository.shared.adminSetUserPro(userId: id, pro: true) }
                                    }
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.yellowDot)
                                    
                                    let isBlocked = user["isBlocked"] as? Bool ?? false
                                    Button(isBlocked ? "Розблокувати" : "Заблокувати") {
                                        Task { try? await AuthRepository.shared.adminBlockUser(userId: id, blocked: !isBlocked) }
                                    }
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(isBlocked ? .summaryGreen : .accentRed)
                                }
                            }
                        }
                        .padding(12)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 30)
        }
    }
    
    // MARK: - Stats Tab
    
    private var statsTab: some View {
        ScrollView {
            VStack(spacing: 16) {
                if viewModel.isLoading {
                    ProgressView().padding()
                }
                
                if let stats = viewModel.stats {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        StatBox(title: "Всього юзерів", value: "\(stats["totalUsers"] as? Int ?? 0)", icon: "person.3.fill", tint: .accentPurple)
                        StatBox(title: "Pro юзерів", value: "\(stats["proUsers"] as? Int ?? 0)", icon: "crown.fill", tint: .yellowDot)
                        StatBox(title: "Всього ключів", value: "\(stats["totalKeys"] as? Int ?? 0)", icon: "key.fill", tint: .summaryGreen)
                        StatBox(title: "Вільних ключів", value: "\(stats["freeKeys"] as? Int ?? 0)", icon: "key", tint: .streakOrange)
                    }
                    .padding(.horizontal, 16)
                }
            }
            .padding(.top, 16)
        }
    }
}

// MARK: - Stat Box

struct StatBox: View {
    @Environment(\.appTheme) var theme
    let title: String
    let value: String
    let icon: String
    let tint: Color
    
    var body: some View {
        GlassSection {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(tint)
                Text(value)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(theme.textPrimary)
                Text(title)
                    .font(.system(size: 12))
                    .foregroundColor(theme.textSecondary)
            }
            .frame(maxWidth: .infinity)
            .padding(14)
        }
    }
}

// MARK: - View Model

@MainActor
final class AdminViewModel: ObservableObject {
    @Published var keys: [[String: Any]] = []
    @Published var users: [[String: Any]] = []
    @Published var stats: [String: Any]?
    @Published var isLoading = false
    @Published var newKey = ""
    
    private let authRepo = AuthRepository.shared
    
    func loadAll() async {
        isLoading = true
        do {
            keys = try await authRepo.adminGetKeys()
            users = try await authRepo.adminGetUsers()
            stats = try await authRepo.adminGetStats()
        } catch {}
        isLoading = false
    }
    
    func addKey() async {
        guard !newKey.isEmpty else { return }
        do {
            try await authRepo.adminAddKeys(keys: newKey)
            newKey = ""
            keys = try await authRepo.adminGetKeys()
        } catch {}
    }
}

// Make dictionaries Hashable for ForEach
extension Dictionary: @retroactive Hashable where Key == String, Value == Any {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(self["_id"] as? String ?? UUID().uuidString)
    }
}
