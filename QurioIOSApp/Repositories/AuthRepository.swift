import Foundation
import Combine

/// Auth repository mirroring AuthRepository.kt (726 lines).
/// All API calls to Node.js server for auth, profile, sync, admin, and reporting.
final class AuthRepository: ObservableObject {
    static let shared = AuthRepository()
    
    private let network = NetworkingService.shared
    private let settings = SettingsRepository.shared
    
    // MARK: - Auth Exception
    
    struct AuthError: Error, LocalizedError {
        let message: String
        let needsVerification: Bool
        let email: String?
        
        init(_ message: String, needsVerification: Bool = false, email: String? = nil) {
            self.message = message
            self.needsVerification = needsVerification
            self.email = email
        }
        
        var errorDescription: String? { message }
    }
    
    // MARK: - Login
    
    func login(email: String, password: String) async throws {
        let (data, response) = try await network.serverRequest(
            endpoint: "/api/auth/login",
            method: "POST",
            body: ["email": email, "password": password]
        )
        
        let json = try parseJSON(data)
        
        if response.statusCode == 403, json["needsVerification"] as? Bool == true {
            throw AuthError(
                json["error"] as? String ?? "Потрібна верифікація",
                needsVerification: true,
                email: json["email"] as? String ?? email
            )
        }
        
        guard response.statusCode == 200 else {
            throw AuthError(json["error"] as? String ?? "Помилка входу")
        }
        
        saveAuthData(json)
    }
    
    // MARK: - Register
    
    func register(name: String, email: String, password: String) async throws {
        let (data, response) = try await network.serverRequest(
            endpoint: "/api/auth/register",
            method: "POST",
            body: ["name": name, "email": email, "password": password]
        )
        
        let json = try parseJSON(data)
        
        guard response.statusCode == 200 || response.statusCode == 201 else {
            throw AuthError(json["error"] as? String ?? "Помилка реєстрації")
        }
    }
    
    // MARK: - Verify Email
    
    func verifyEmail(email: String, code: String) async throws {
        let (data, response) = try await network.serverRequest(
            endpoint: "/api/auth/verify",
            method: "POST",
            body: ["email": email, "code": code]
        )
        
        let json = try parseJSON(data)
        
        guard response.statusCode == 200 else {
            throw AuthError(json["error"] as? String ?? "Невірний код")
        }
        
        saveAuthData(json)
    }
    
    // MARK: - Resend Code
    
    func resendCode(email: String) async throws {
        let (data, response) = try await network.serverRequest(
            endpoint: "/api/auth/resend-code",
            method: "POST",
            body: ["email": email]
        )
        
        let json = try parseJSON(data)
        
        guard response.statusCode == 200 else {
            throw AuthError(json["error"] as? String ?? "Не вдалося надіслати код")
        }
    }
    
    // MARK: - Google Auth
    
    func googleAuth(idToken: String) async throws {
        let (data, response) = try await network.serverRequest(
            endpoint: "/api/auth/google",
            method: "POST",
            body: ["idToken": idToken]
        )
        
        let json = try parseJSON(data)
        
        guard response.statusCode == 200 else {
            throw AuthError(json["error"] as? String ?? "Помилка Google авторизації")
        }
        
        saveAuthData(json)
    }
    
    // MARK: - Forgot Password
    
    func forgotPassword(email: String) async throws {
        let (data, response) = try await network.serverRequest(
            endpoint: "/api/auth/forgot-password",
            method: "POST",
            body: ["email": email]
        )
        
        let json = try parseJSON(data)
        
        guard response.statusCode == 200 else {
            throw AuthError(json["error"] as? String ?? "Помилка відновлення пароля")
        }
    }
    
    // MARK: - Reset Password
    
    func resetPassword(email: String, code: String, newPassword: String) async throws {
        let (data, response) = try await network.serverRequest(
            endpoint: "/api/auth/reset-password",
            method: "POST",
            body: ["email": email, "code": code, "newPassword": newPassword]
        )
        
        let json = try parseJSON(data)
        
        guard response.statusCode == 200 else {
            throw AuthError(json["error"] as? String ?? "Помилка скидання пароля")
        }
        
        saveAuthData(json)
    }
    
    // MARK: - Set Password (for Google users)
    
    func setPassword(password: String) async throws {
        try await authRequest { token in
            try await self.network.serverRequest(
                endpoint: "/api/user/set-password",
                method: "POST",
                body: ["password": password],
                token: token
            )
        }
    }
    
    // MARK: - Get Profile
    
    func getProfile() async throws {
        let (data, _) = try await authRequest { token in
            try await self.network.serverRequest(
                endpoint: "/api/user/profile",
                method: "GET",
                token: token
            )
        }
        
        let json = try parseJSON(data)
        if let user = json["user"] as? [String: Any] {
            saveProfileData(user)
        }
    }
    
    // MARK: - Sync Settings
    
    func syncSettings() async throws {
        let (data, _) = try await authRequest { token in
            try await self.network.serverRequest(
                endpoint: "/api/settings",
                method: "GET",
                token: token
            )
        }
        
        let json = try parseJSON(data)
        applySyncSettings(json)
        
        // If server didn't return an apiKey, request one (mirrors Android)
        if settings.apiKey.isEmpty {
            await requestApiKey()
        }
    }
    
    private func applySyncSettings(_ json: [String: Any]) {
        if let apiKey = json["apiKey"] as? String, !apiKey.isEmpty {
            settings.apiKey = apiKey
        }
        if let baseUrl = json["baseUrl"] as? String, !baseUrl.isEmpty {
            settings.apiBaseUrl = baseUrl
        }
        if let model = json["model"] as? String, !model.isEmpty {
            settings.modelName = model
        }
        if let sub = json["hasActiveSubscription"] as? Bool {
            settings.hasActiveSubscription = sub
        }
        if let streak = json["streakCount"] as? Int {
            settings.streakCount = streak
        }
        if let lastDate = json["streakLastDate"] as? String {
            settings.streakLastDate = lastDate
        }
        if let claimed = json["claimedRewards"] as? String {
            settings.restoreClaimedRewards(serverClaimed: claimed)
        }
        if let userSettings = json["settings"] as? [String: Any] {
            if let show = userSettings["showExplanation"] as? Bool {
                settings.showExplanation = show
            }
            if let mode = userSettings["summaryMode"] as? Int {
                settings.summaryMode = mode
            }
            if let count = userSettings["testQuestionCount"] as? Int {
                settings.testQuestionCount = count
            }
        }
    }
    
    // MARK: - Streak Sync
    
    func syncStreakToServer() async {
        do {
            let (data, _) = try await authRequest { token in
                try await self.network.serverRequest(
                    endpoint: "/api/user/streak",
                    method: "PUT",
                    body: [
                        "count": self.settings.currentStreakCount(),
                        "lastDate": self.settings.streakLastDate,
                        "claimedRewards": self.settings.claimedRewardsRaw,
                        "bonusQueries": self.settings.bonusQueries
                    ],
                    token: token
                )
            }
            // Read back merged streak from server (source of truth)
            let json = try parseJSON(data)
            if let streak = json["streak"] as? [String: Any] {
                if let count = (streak["count"] as? NSNumber)?.intValue {
                    settings.streakCount = count
                }
                if let lastDate = streak["lastDate"] as? String {
                    settings.streakLastDate = lastDate
                }
                if let claimed = streak["claimedRewards"] as? String {
                    settings.restoreClaimedRewards(serverClaimed: claimed)
                }
                if let bonus = (streak["bonusQueries"] as? NSNumber)?.intValue {
                    settings.bonusQueries = max(settings.bonusQueries, bonus)
                }
                print("✅ Streak synced from server: count=\(streak["count"] ?? 0), claimed=\(streak["claimedRewards"] ?? "")")
            }
        } catch {
            print("❌ Streak sync error: \(error)")
        }
    }
    
    // MARK: - Request API Key
    
    /// Requests an API key assignment from the server pool.
    /// Called automatically after syncSettings if no key is present.
    func requestApiKey() async {
        do {
            let (data, response) = try await authRequest { token in
                try await self.network.serverRequest(
                    endpoint: "/api/keys/assign",
                    method: "POST",
                    body: [:],
                    token: token
                )
            }
            let json = try parseJSON(data)
            if let key = json["apiKey"] as? String, !key.isEmpty {
                settings.apiKey = key
            }
        } catch { /* fire-and-forget */ }
    }
    
    // MARK: - History Sync
    
    func pushHistoryToServer(_ entries: [HistorySyncEntry]) async {
        guard !entries.isEmpty else { return }
        do {
            let entriesData = entries.map { entry -> [String: Any] in
                [
                    "question": entry.question,
                    "answer": entry.answer,
                    "explanation": entry.explanation ?? "",
                    "confidence": entry.confidence ?? 0,
                    "appPackage": entry.appPackage ?? "com.qurio.ios",
                    "timestamp": entry.timestamp
                ]
            }
            print("📤 Pushing \(entriesData.count) history entries to server...")
            let (data, _) = try await authRequest { token in
                try await self.network.serverRequest(
                    endpoint: "/api/user/history",
                    method: "PUT",
                    body: ["entries": entriesData],
                    token: token
                )
            }
            let json = try parseJSON(data)
            print("📤 History push result: \(json)")
        } catch {
            print("❌ History push error: \(error)")
        }
    }
    
    func pullHistoryFromServer() async -> [HistorySyncEntry] {
        do {
            print("📥 Pulling history from server...")
            let (data, _) = try await authRequest { token in
                try await self.network.serverRequest(
                    endpoint: "/api/user/history",
                    method: "GET",
                    token: token
                )
            }
            let json = try parseJSON(data)
            guard let entriesArray = json["entries"] as? [[String: Any]] else {
                print("❌ History pull: no 'entries' array in response. Keys: \(json.keys)")
                return []
            }
            
            print("📥 History pull: got \(entriesArray.count) entries from server")
            
            return entriesArray.compactMap { dict -> HistorySyncEntry? in
                guard let question = dict["question"] as? String,
                      let answer = dict["answer"] as? String else { return nil }
                // NSNumber-safe timestamp parsing (JSONSerialization returns NSNumber)
                guard let tsNumber = dict["timestamp"] as? NSNumber else { return nil }
                let timestamp = tsNumber.int64Value
                return HistorySyncEntry(
                    question: question,
                    answer: answer,
                    explanation: dict["explanation"] as? String,
                    confidence: (dict["confidence"] as? NSNumber)?.doubleValue,
                    appPackage: dict["appPackage"] as? String,
                    timestamp: timestamp
                )
            }
        } catch {
            print("❌ History pull error: \(error)")
            return []
        }
    }
    
    func pushTestResultsToServer(_ results: [TestResultSyncEntry]) async {
        guard !results.isEmpty else { return }
        do {
            let resultsData = results.map { r -> [String: Any] in
                [
                    "summaryTitle": r.summaryTitle ?? "",
                    "score": r.score,
                    "totalQuestions": r.totalQuestions,
                    "percentage": r.percentage,
                    "totalTimeMs": r.totalTimeMs,
                    "avgTimeMs": r.avgTimeMs,
                    "fastestMs": r.fastestMs,
                    "slowestMs": r.slowestMs,
                    "questionsJson": r.questionsJson ?? "",
                    "timestamp": r.timestamp
                ]
            }
            print("📤 Pushing \(resultsData.count) test results to server...")
            let (data, _) = try await authRequest { token in
                try await self.network.serverRequest(
                    endpoint: "/api/user/test-results",
                    method: "PUT",
                    body: ["results": resultsData],
                    token: token
                )
            }
            let json = try parseJSON(data)
            print("📤 Test results push result: \(json)")
        } catch {
            print("❌ Test results push error: \(error)")
        }
    }
    
    func pullTestResultsFromServer() async -> [TestResultSyncEntry] {
        do {
            print("📥 Pulling test results from server...")
            let (data, _) = try await authRequest { token in
                try await self.network.serverRequest(
                    endpoint: "/api/user/test-results",
                    method: "GET",
                    token: token
                )
            }
            let json = try parseJSON(data)
            guard let resultsArray = json["results"] as? [[String: Any]] else {
                print("❌ Test results pull: no 'results' array. Keys: \(json.keys)")
                return []
            }
            
            print("📥 Test results pull: got \(resultsArray.count) results from server")
            
            return resultsArray.compactMap { dict -> TestResultSyncEntry? in
                // NSNumber-safe parsing
                guard let tsNumber = dict["timestamp"] as? NSNumber else { return nil }
                let score = (dict["score"] as? NSNumber)?.intValue ?? 0
                let total = (dict["totalQuestions"] as? NSNumber)?.intValue ?? 0
                let pct = (dict["percentage"] as? NSNumber)?.intValue ?? 0
                guard total > 0 else { return nil }
                return TestResultSyncEntry(
                    summaryTitle: dict["summaryTitle"] as? String,
                    score: score,
                    totalQuestions: total,
                    percentage: pct,
                    totalTimeMs: (dict["totalTimeMs"] as? NSNumber)?.int64Value ?? 0,
                    avgTimeMs: (dict["avgTimeMs"] as? NSNumber)?.int64Value ?? 0,
                    fastestMs: (dict["fastestMs"] as? NSNumber)?.int64Value ?? 0,
                    slowestMs: (dict["slowestMs"] as? NSNumber)?.int64Value ?? 0,
                    questionsJson: dict["questionsJson"] as? String,
                    timestamp: tsNumber.int64Value
                )
            }
        } catch {
            print("❌ Test results pull error: \(error)")
            return []
        }
    }
    
    // MARK: - Report
    
    func sendReport(answer: String, explanation: String = "", source: String = "overlay") async {
        do {
            let _ = try await authRequest { token in
                try await self.network.serverRequest(
                    endpoint: "/api/report/",
                    method: "POST",
                    body: ["answer": answer, "explanation": explanation, "source": source],
                    token: token
                )
            }
        } catch { /* fire-and-forget */ }
    }
    
    // MARK: - Admin: Keys
    
    func adminGetKeys() async throws -> [[String: Any]] {
        let (data, _) = try await authRequest { token in
            try await self.network.serverRequest(endpoint: "/api/admin/keys", method: "GET", token: token)
        }
        let json = try parseJSON(data)
        return json["keys"] as? [[String: Any]] ?? []
    }
    
    func adminAddKeys(keys: String, note: String = "") async throws {
        let _ = try await authRequest { token in
            try await self.network.serverRequest(
                endpoint: "/api/admin/keys",
                method: "POST",
                body: ["keys": keys, "note": note],
                token: token
            )
        }
    }
    
    func adminDeleteKey(id: String) async throws {
        let _ = try await authRequest { token in
            try await self.network.serverRequest(endpoint: "/api/admin/keys/\(id)", method: "DELETE", token: token)
        }
    }
    
    func adminFreeKey(id: String) async throws {
        let _ = try await authRequest { token in
            try await self.network.serverRequest(
                endpoint: "/api/admin/keys/\(id)/free",
                method: "POST",
                token: token
            )
        }
    }
    
    // MARK: - Admin: Users
    
    func adminGetUsers() async throws -> [[String: Any]] {
        let (data, _) = try await authRequest { token in
            try await self.network.serverRequest(endpoint: "/api/admin/users", method: "GET", token: token)
        }
        let json = try parseJSON(data)
        return json["users"] as? [[String: Any]] ?? []
    }
    
    func adminSetUserKey(userId: String, key: String) async throws {
        let _ = try await authRequest { token in
            try await self.network.serverRequest(
                endpoint: "/api/admin/users/\(userId)/key",
                method: "POST",
                body: ["key": key],
                token: token
            )
        }
    }
    
    func adminFreeUserKey(userId: String) async throws {
        let _ = try await authRequest { token in
            try await self.network.serverRequest(endpoint: "/api/admin/users/\(userId)/free-key", method: "POST", token: token)
        }
    }
    
    func adminSetUserPro(userId: String, pro: Bool) async throws {
        let _ = try await authRequest { token in
            try await self.network.serverRequest(
                endpoint: "/api/admin/users/\(userId)/set-pro",
                method: "POST",
                body: ["pro": pro],
                token: token
            )
        }
    }
    
    func adminBlockUser(userId: String, blocked: Bool) async throws {
        let _ = try await authRequest { token in
            try await self.network.serverRequest(
                endpoint: "/api/admin/users/\(userId)/block",
                method: "POST",
                body: ["blocked": blocked],
                token: token
            )
        }
    }
    
    func adminGetStats() async throws -> [String: Any] {
        let (data, _) = try await authRequest { token in
            try await self.network.serverRequest(endpoint: "/api/admin/stats", method: "GET", token: token)
        }
        return try parseJSON(data)
    }
    
    // MARK: - Admin Management
    
    func adminGetAdmins() async throws -> [[String: Any]] {
        let (data, _) = try await authRequest { token in
            try await self.network.serverRequest(endpoint: "/api/admin/admins", method: "GET", token: token)
        }
        let json = try parseJSON(data)
        return json["admins"] as? [[String: Any]] ?? []
    }
    
    func adminAddAdmin(email: String) async throws {
        let _ = try await authRequest { token in
            try await self.network.serverRequest(
                endpoint: "/api/admin/admins",
                method: "POST",
                body: ["email": email],
                token: token
            )
        }
    }
    
    func adminRemoveAdmin(email: String) async throws {
        let _ = try await authRequest { token in
            try await self.network.serverRequest(
                endpoint: "/api/admin/admins",
                method: "DELETE",
                body: ["email": email],
                token: token
            )
        }
    }
    
    // MARK: - Token Management
    
    /// Makes an authenticated request with automatic token refresh on 401.
    @discardableResult
    private func authRequest(
        makeRequest: @escaping (String) async throws -> (Data, HTTPURLResponse)
    ) async throws -> (Data, HTTPURLResponse) {
        let token = settings.authToken
        if token.isEmpty {
            throw NetworkError.unauthorized
        }
        
        let (data, response) = try await makeRequest(token)
        
        if response.statusCode == 401 {
            // Try refreshing
            try await refreshTokens()
            let newToken = settings.authToken
            return try await makeRequest(newToken)
        }
        
        guard 200..<300 ~= response.statusCode else {
            let json = (try? parseJSON(data)) ?? [:]
            let msg = json["error"] as? String ?? "Помилка сервера (\(response.statusCode))"
            throw AuthError(msg)
        }
        
        return (data, response)
    }
    
    func refreshTokens() async throws {
        let rt = settings.refreshToken
        if rt.isEmpty {
            throw NetworkError.unauthorized
        }
        
        let (data, response) = try await network.serverRequest(
            endpoint: "/api/auth/refresh",
            method: "POST",
            body: ["refreshToken": rt]
        )
        
        guard response.statusCode == 200 else {
            // Refresh failed → log out
            settings.logout()
            throw NetworkError.unauthorized
        }
        
        let json = try parseJSON(data)
        if let token = json["token"] as? String {
            settings.authToken = token
        }
        if let refresh = json["refreshToken"] as? String {
            settings.refreshToken = refresh
        }
    }
    
    // MARK: - Helpers
    
    private func saveAuthData(_ json: [String: Any]) {
        if let token = json["token"] as? String {
            settings.authToken = token
        }
        if let refresh = json["refreshToken"] as? String {
            settings.refreshToken = refresh
        }
        if let user = json["user"] as? [String: Any] {
            saveProfileData(user)
        }
        settings.isLoggedIn = true
    }
    
    private func saveProfileData(_ user: [String: Any]) {
        if let name = user["name"] as? String { settings.userName = name }
        if let email = user["email"] as? String { settings.userEmail = email }
        if let google = user["isGoogleUser"] as? Bool { settings.isGoogleUser = google }
        // Pro status: check both formats — server returns subscription.active, 
        // Android-style sync returns hasActiveSubscription
        if let sub = user["hasActiveSubscription"] as? Bool {
            settings.hasActiveSubscription = sub
        } else if let subscription = user["subscription"] as? [String: Any],
                  let active = subscription["active"] as? Bool {
            settings.hasActiveSubscription = active
        }
        if let key = user["apiKey"] as? String { settings.apiKey = key }
        // Streak: check both formats — streakCount or streak.count
        if let streak = user["streakCount"] as? Int {
            settings.streakCount = streak
        } else if let streakObj = user["streak"] as? [String: Any],
                  let count = streakObj["count"] as? Int {
            settings.streakCount = count
            if let last = streakObj["lastDate"] as? String {
                settings.streakLastDate = last
            }
            if let claimed = streakObj["claimedRewards"] as? String {
                settings.restoreClaimedRewards(serverClaimed: claimed)
            }
        }
        if let last = user["streakLastDate"] as? String { settings.streakLastDate = last }
        if let claimed = user["claimedRewards"] as? String {
            settings.restoreClaimedRewards(serverClaimed: claimed)
        }
    }
    
    private func parseJSON(_ data: Data) throws -> [String: Any] {
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw AuthError("Невірний формат відповіді")
        }
        return json
    }
}
