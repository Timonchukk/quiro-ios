import Foundation

// MARK: - Request Models (mirrors LlmModels.kt)

struct LlmRequest: Codable {
    let model: String
    let messages: [LlmMessage]
    let temperature: Double
    let maxTokens: Int
    
    enum CodingKeys: String, CodingKey {
        case model, messages, temperature
        case maxTokens = "max_tokens"
    }
    
    init(
        model: String = Config.defaultModel,
        messages: [LlmMessage],
        temperature: Double = 0.2,
        maxTokens: Int = 256
    ) {
        self.model = model
        self.messages = messages
        self.temperature = temperature
        self.maxTokens = maxTokens
    }
}

struct LlmMessage: Codable {
    let role: String
    let content: String?
    
    init(role: String, content: String? = nil) {
        self.role = role
        self.content = content
    }
}

struct ResponseFormat: Codable {
    let type: String
}

// MARK: - Response Models

struct LlmResponseBody: Codable {
    let choices: [LlmChoice]
}

struct LlmChoice: Codable {
    let message: LlmMessage
}

// MARK: - Parsed AI Answer

struct AiAnswer: Codable {
    let answer: String
    let explanation: String
    let confidence: Double
    
    init(answer: String, explanation: String = "", confidence: Double = 0.0) {
        self.answer = answer
        self.explanation = explanation
        self.confidence = confidence
    }
}

// MARK: - Server Auth Response Models

struct AuthResponse: Codable {
    let token: String?
    let refreshToken: String?
    let user: UserProfile?
    let message: String?
    let error: String?
    let needsVerification: Bool?
    let email: String?
    
    enum CodingKeys: String, CodingKey {
        case token, refreshToken, user, message, error
        case needsVerification, email
    }
}

struct UserProfile: Codable {
    let id: String?
    let name: String?
    let email: String?
    let isGoogleUser: Bool?
    let hasActiveSubscription: Bool?
    let plan: String?
    let apiKey: String?
    let isAdmin: Bool?
    let streakCount: Int?
    let streakLastDate: String?
    let claimedRewards: String?
    let settings: UserSettings?
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case name, email, isGoogleUser, hasActiveSubscription
        case plan, apiKey, isAdmin, streakCount, streakLastDate
        case claimedRewards, settings
    }
}

struct UserSettings: Codable {
    let showExplanation: Bool?
    let summaryMode: Int?
    let testQuestionCount: Int?
    let testTimeLimitMinutes: Int?
    let testShowAnswers: Bool?
    let overlayAlpha: Double?
    let overlaySizeScale: Double?
}

// MARK: - Admin Models

struct AdminKeyInfo: Codable, Identifiable {
    let id: String
    let key: String
    let note: String?
    let assignedTo: String?
    let assignedEmail: String?
    let createdAt: String?
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case key, note, assignedTo, assignedEmail, createdAt
    }
}

struct AdminUserInfo: Codable, Identifiable {
    let id: String
    let name: String?
    let email: String
    let plan: String?
    let apiKey: String?
    let isBlocked: Bool?
    let hasActiveSubscription: Bool?
    let createdAt: String?
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case name, email, plan, apiKey, isBlocked
        case hasActiveSubscription, createdAt
    }
}

struct AdminStats: Codable {
    let totalUsers: Int?
    let proUsers: Int?
    let totalKeys: Int?
    let assignedKeys: Int?
    let freeKeys: Int?
}

// MARK: - Report Model

struct ReportRequest: Codable {
    let answer: String
    let explanation: String
    let source: String
}

// MARK: - History Sync Models

struct HistorySyncEntry: Codable {
    let question: String
    let answer: String
    let explanation: String?
    let confidence: Double?
    let appPackage: String?
    let timestamp: Int64
}

struct TestResultSyncEntry: Codable {
    let summaryTitle: String?
    let score: Int
    let totalQuestions: Int
    let percentage: Int
    let totalTimeMs: Int64
    let avgTimeMs: Int64
    let fastestMs: Int64
    let slowestMs: Int64
    let questionsJson: String?
    let timestamp: Int64
}
