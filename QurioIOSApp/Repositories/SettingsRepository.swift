import Foundation
import Combine

/// Settings repository mirroring SettingsRepository.kt (496 lines).
/// Uses UserDefaults for general settings and KeychainService for sensitive tokens.
/// All properties are @Published for SwiftUI reactivity.
final class SettingsRepository: ObservableObject {
    static let shared = SettingsRepository()
    
    private let defaults = UserDefaults.standard
    private let keychain = KeychainService.shared
    
    // MARK: - API Settings
    
    @Published var apiKey: String {
        didSet { keychain.save(apiKey, forKey: "api_key") }
    }
    
    @Published var apiBaseUrl: String {
        didSet { defaults.set(apiBaseUrl, forKey: "api_base_url") }
    }
    
    @Published var showExplanation: Bool {
        didSet { defaults.set(showExplanation, forKey: "show_explanation") }
    }
    
    @Published var privacyMode: Bool {
        didSet { defaults.set(privacyMode, forKey: "privacy_mode") }
    }
    
    @Published var modelName: String {
        didSet { defaults.set(modelName, forKey: "model_name") }
    }
    
    // MARK: - Theme
    
    @Published var themeMode: Int {
        didSet { defaults.set(themeMode, forKey: "theme_mode") }
    }
    
    // MARK: - Overlay Customization
    
    @Published var overlayAlpha: Float {
        didSet { defaults.set(overlayAlpha, forKey: "overlay_alpha") }
    }
    
    @Published var overlaySizeScale: Float {
        didSet { defaults.set(overlaySizeScale, forKey: "overlay_size_scale") }
    }
    
    @Published var overlayWidthDp: Int {
        didSet { defaults.set(overlayWidthDp, forKey: "overlay_width_dp") }
    }
    
    @Published var overlayHeightDp: Int {
        didSet { defaults.set(overlayHeightDp, forKey: "overlay_height_dp") }
    }
    
    // MARK: - Onboarding
    
    @Published var onboardingCompleted: Bool {
        didSet { defaults.set(onboardingCompleted, forKey: "onboarding_completed") }
    }
    
    // MARK: - Auth
    
    @Published var isLoggedIn: Bool {
        didSet { defaults.set(isLoggedIn, forKey: "logged_in") }
    }
    
    @Published var userName: String {
        didSet { defaults.set(userName, forKey: "user_name") }
    }
    
    @Published var userEmail: String {
        didSet { defaults.set(userEmail, forKey: "user_email") }
    }
    
    @Published var isGoogleUser: Bool {
        didSet { defaults.set(isGoogleUser, forKey: "is_google_user") }
    }
    
    var authToken: String {
        get { keychain.read(forKey: "auth_token") ?? "" }
        set { keychain.save(newValue, forKey: "auth_token") }
    }
    
    var refreshToken: String {
        get { keychain.read(forKey: "refresh_token") ?? "" }
        set { keychain.save(newValue, forKey: "refresh_token") }
    }
    
    // MARK: - Subscription
    
    @Published var hasActiveSubscription: Bool {
        didSet { defaults.set(hasActiveSubscription, forKey: "has_active_subscription") }
    }
    
    // MARK: - Trial System (10 requests per 3 days)
    
    private var trialRequestCount: Int {
        get { defaults.integer(forKey: "trial_request_count") }
        set { defaults.set(newValue, forKey: "trial_request_count") }
    }
    
    private var trialPeriodStart: TimeInterval {
        get { defaults.double(forKey: "trial_period_start") }
        set { defaults.set(newValue, forKey: "trial_period_start") }
    }
    
    @Published var bonusQueries: Int {
        didSet { defaults.set(bonusQueries, forKey: "bonus_queries") }
    }
    
    private func resetTrialIfExpired() {
        let now = Date().timeIntervalSince1970
        if trialPeriodStart == 0 || now - trialPeriodStart > Config.trialPeriodSeconds {
            trialRequestCount = 0
            bonusQueries = 0
            trialPeriodStart = now
        }
    }
    
    func canMakeTrialRequest() -> Bool {
        if hasActiveSubscription { return true }
        resetTrialIfExpired()
        return trialRequestCount < Config.maxTrialRequests + bonusQueries
    }
    
    func incrementTrialRequests() {
        if hasActiveSubscription { return }
        resetTrialIfExpired()
        trialRequestCount += 1
    }
    
    func remainingTrialRequests() -> Int {
        if hasActiveSubscription { return Int.max }
        resetTrialIfExpired()
        return max(Config.maxTrialRequests + bonusQueries - trialRequestCount, 0)
    }
    
    func totalTrialLimit() -> Int {
        resetTrialIfExpired()
        return Config.maxTrialRequests + bonusQueries
    }
    
    // MARK: - Admin
    
    var isAdmin: Bool {
        Config.adminEmails.contains(where: { $0.lowercased() == userEmail.lowercased() })
    }
    
    // MARK: - Streak System
    
    @Published var streakCount: Int {
        didSet { defaults.set(streakCount, forKey: "streak_count") }
    }
    
    @Published var streakLastDate: String {
        didSet { defaults.set(streakLastDate, forKey: "streak_last_date") }
    }
    
    private func todayStr() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }
    
    /// Call after every successful AI request
    func updateStreak() {
        let today = todayStr()
        let lastDate = streakLastDate
        if lastDate == today { return }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let yesterday = formatter.string(from: Calendar.current.date(byAdding: .day, value: -1, to: Date())!)
        
        streakCount = (lastDate == yesterday) ? streakCount + 1 : 1
        streakLastDate = today
    }
    
    func isStreakActiveToday() -> Bool {
        return streakLastDate == todayStr()
    }
    
    func currentStreakCount() -> Int {
        let lastDate = streakLastDate
        if lastDate.isEmpty { return 0 }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        guard let last = formatter.date(from: lastDate) else { return 0 }
        
        let days = Calendar.current.dateComponents([.day], from: last, to: Date()).day ?? 0
        return days <= 1 ? streakCount : 0
    }
    
    // MARK: - Streak Rewards
    
    var claimedRewardsRaw: String {
        get { defaults.string(forKey: "claimed_streak_rewards") ?? "" }
        set { defaults.set(newValue, forKey: "claimed_streak_rewards") }
    }
    
    func restoreClaimedRewards(serverClaimed: String) {
        let local = claimedSet()
        let server = Set(serverClaimed.split(separator: ",").compactMap { Int($0.trimmingCharacters(in: .whitespaces)) })
        let merged = local.union(server)
        claimedRewardsRaw = merged.map(String.init).joined(separator: ",")
    }
    
    private func claimedSet() -> Set<Int> {
        Set(claimedRewardsRaw.split(separator: ",").compactMap { Int($0.trimmingCharacters(in: .whitespaces)) })
    }
    
    func isRewardClaimed(day: Int) -> Bool {
        claimedSet().contains(day)
    }
    
    func claimReward(day: Int) -> Bool {
        guard let milestone = streakMilestones.first(where: { $0.day == day }) else { return false }
        let current = currentStreakCount()
        if current < day { return false }
        if isRewardClaimed(day: day) { return false }
        
        var set = claimedSet()
        set.insert(day)
        claimedRewardsRaw = set.map(String.init).joined(separator: ",")
        
        switch milestone.rewardType {
        case .freeQueries:
            bonusQueries += milestone.amount
        case .proDays:
            let currentEnd = defaults.double(forKey: "pro_reward_end")
            let now = Date().timeIntervalSince1970
            let base = currentEnd > now ? currentEnd : now
            let newEnd = base + Double(milestone.amount) * 24 * 60 * 60
            defaults.set(newEnd, forKey: "pro_reward_end")
            hasActiveSubscription = true
        }
        return true
    }
    
    func checkRewardProExpiry() {
        let end = defaults.double(forKey: "pro_reward_end")
        if end > 0 && Date().timeIntervalSince1970 > end {
            defaults.set(0.0, forKey: "pro_reward_end")
            hasActiveSubscription = false
        }
    }
    
    func hasRewardPro() -> Bool {
        let end = defaults.double(forKey: "pro_reward_end")
        return end > 0 && Date().timeIntervalSince1970 <= end
    }
    
    // MARK: - Summary Daily Limit (Pro only, 3/day)
    
    private var summaryUsedCount: Int {
        get { defaults.integer(forKey: "summary_used_count") }
        set { defaults.set(newValue, forKey: "summary_used_count") }
    }
    
    private var summaryLastDate: String {
        get { defaults.string(forKey: "summary_last_date") ?? "" }
        set { defaults.set(newValue, forKey: "summary_last_date") }
    }
    
    private func resetSummaryIfNewDay() {
        let today = todayStr()
        if summaryLastDate != today {
            summaryUsedCount = 0
            summaryLastDate = today
        }
    }
    
    func canMakeSummary() -> Bool {
        if !hasActiveSubscription { return false }
        if isAdmin { return true }
        resetSummaryIfNewDay()
        return summaryUsedCount < Config.maxDailySummaries
    }
    
    func incrementSummaryCount() {
        resetSummaryIfNewDay()
        summaryUsedCount += 1
    }
    
    func remainingSummaries() -> Int {
        if !hasActiveSubscription { return 0 }
        resetSummaryIfNewDay()
        return max(Config.maxDailySummaries - summaryUsedCount, 0)
    }
    
    // MARK: - Summary Mode
    
    @Published var summaryMode: Int {
        didSet { defaults.set(summaryMode, forKey: "summary_mode") }
    }
    
    // MARK: - Test Settings
    
    @Published var testQuestionCount: Int {
        didSet { defaults.set(min(max(testQuestionCount, 1), 24), forKey: "test_question_count") }
    }
    
    @Published var testTimeLimitMinutes: Int {
        didSet { defaults.set(max(testTimeLimitMinutes, 0), forKey: "test_time_limit") }
    }
    
    @Published var testShowAnswers: Bool {
        didSet { defaults.set(testShowAnswers, forKey: "test_show_answers") }
    }
    
    // MARK: - Init
    
    private init() {
        // Load all values from storage
        self.apiKey = KeychainService.shared.read(forKey: "api_key") ?? ""
        self.apiBaseUrl = UserDefaults.standard.string(forKey: "api_base_url") ?? Config.defaultAIBaseURL
        self.showExplanation = UserDefaults.standard.object(forKey: "show_explanation") != nil ? UserDefaults.standard.bool(forKey: "show_explanation") : true
        self.privacyMode = UserDefaults.standard.bool(forKey: "privacy_mode")
        
        let savedModel = UserDefaults.standard.string(forKey: "model_name") ?? Config.defaultModel
        self.modelName = savedModel == "gemini-2.0-flash" ? Config.defaultModel : savedModel
        
        self.themeMode = UserDefaults.standard.object(forKey: "theme_mode") != nil ? UserDefaults.standard.integer(forKey: "theme_mode") : 1
        self.overlayAlpha = UserDefaults.standard.object(forKey: "overlay_alpha") != nil ? UserDefaults.standard.float(forKey: "overlay_alpha") : 0.85
        self.overlaySizeScale = UserDefaults.standard.object(forKey: "overlay_size_scale") != nil ? UserDefaults.standard.float(forKey: "overlay_size_scale") : 1.0
        self.overlayWidthDp = UserDefaults.standard.object(forKey: "overlay_width_dp") != nil ? UserDefaults.standard.integer(forKey: "overlay_width_dp") : 200
        self.overlayHeightDp = UserDefaults.standard.object(forKey: "overlay_height_dp") != nil ? UserDefaults.standard.integer(forKey: "overlay_height_dp") : 180
        self.onboardingCompleted = UserDefaults.standard.bool(forKey: "onboarding_completed")
        self.isLoggedIn = UserDefaults.standard.bool(forKey: "logged_in")
        self.userName = UserDefaults.standard.string(forKey: "user_name") ?? ""
        self.userEmail = UserDefaults.standard.string(forKey: "user_email") ?? ""
        self.isGoogleUser = UserDefaults.standard.bool(forKey: "is_google_user")
        self.hasActiveSubscription = UserDefaults.standard.bool(forKey: "has_active_subscription")
        self.bonusQueries = UserDefaults.standard.integer(forKey: "bonus_queries")
        self.streakCount = UserDefaults.standard.integer(forKey: "streak_count")
        self.streakLastDate = UserDefaults.standard.string(forKey: "streak_last_date") ?? ""
        self.summaryMode = UserDefaults.standard.object(forKey: "summary_mode") != nil ? UserDefaults.standard.integer(forKey: "summary_mode") : 2
        self.testQuestionCount = UserDefaults.standard.object(forKey: "test_question_count") != nil ? UserDefaults.standard.integer(forKey: "test_question_count") : 12
        self.testTimeLimitMinutes = UserDefaults.standard.integer(forKey: "test_time_limit")
        self.testShowAnswers = UserDefaults.standard.object(forKey: "test_show_answers") != nil ? UserDefaults.standard.bool(forKey: "test_show_answers") : true
    }
    
    // MARK: - Logout
    
    func logout() {
        let authKeys = [
            "user_name", "user_email", "is_google_user", "logged_in",
            "has_active_subscription", "streak_count", "streak_last_date",
            "claimed_streak_rewards", "pro_reward_end"
        ]
        for key in authKeys {
            defaults.removeObject(forKey: key)
        }
        keychain.delete(forKey: "auth_token")
        keychain.delete(forKey: "refresh_token")
        keychain.delete(forKey: "api_key")
        
        // Reset published properties
        apiKey = ""
        userName = ""
        userEmail = ""
        isGoogleUser = false
        isLoggedIn = false
        hasActiveSubscription = false
        streakCount = 0
        streakLastDate = ""
    }
}
