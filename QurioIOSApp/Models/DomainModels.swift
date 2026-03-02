import Foundation

// MARK: - Screen Content (mirrors Models.kt)

struct ScreenContent {
    let question: String?
    let choices: [ChoiceItem]
    let appPackage: String
    let rawText: String
    let isPartial: Bool
    let warningMessage: String?
    
    init(
        question: String? = nil,
        choices: [ChoiceItem] = [],
        appPackage: String = "",
        rawText: String = "",
        isPartial: Bool = false,
        warningMessage: String? = nil
    ) {
        self.question = question
        self.choices = choices
        self.appPackage = appPackage
        self.rawText = rawText
        self.isPartial = isPartial
        self.warningMessage = warningMessage
    }
}

struct ChoiceItem {
    let text: String
    let selected: Bool
    
    init(text: String, selected: Bool = false) {
        self.text = text
        self.selected = selected
    }
}

// MARK: - AI Result

struct AiResult: Identifiable {
    let id = UUID()
    let answer: String
    let explanation: String
    let confidence: Double
    let isError: Bool
    let errorMessage: String?
    let isManualPrompt: Bool
    
    init(
        answer: String,
        explanation: String = "",
        confidence: Double = 0.0,
        isError: Bool = false,
        errorMessage: String? = nil,
        isManualPrompt: Bool = false
    ) {
        self.answer = answer
        self.explanation = explanation
        self.confidence = confidence
        self.isError = isError
        self.errorMessage = errorMessage
        self.isManualPrompt = isManualPrompt
    }
}

// MARK: - Test Question (mirrors TestQuestion.kt)

struct TestQuestion: Codable, Identifiable {
    let id = UUID()
    let question: String
    let options: [String]
    let correctIndex: Int
    
    enum CodingKeys: String, CodingKey {
        case question, options
        case correctIndex = "correct_index"
    }
}

// MARK: - Overlay State

enum OverlayStatus {
    case idle
    case capturing
    case thinking
    case done
    case error
    case summaryCollecting(current: Int, total: Int)
}

// MARK: - Auth State

enum AuthScreenState {
    case login
    case register
    case verify
    case forgotPassword
    case resetPassword
}

// MARK: - Summary Mode

enum SummaryMode: Int, CaseIterable {
    case compact = 0
    case medium = 1
    case large = 2
    
    var title: String {
        switch self {
        case .compact: return "Стислий"
        case .medium: return "Середній"
        case .large: return "Детальний"
        }
    }
    
    var icon: String {
        switch self {
        case .compact: return "text.alignleft"
        case .medium: return "text.justify"
        case .large: return "doc.text"
        }
    }
}

// MARK: - Streak Milestone

struct StreakMilestone: Identifiable {
    let id: Int
    let day: Int
    let rewardType: RewardType
    let amount: Int
    let label: String
    let iconName: String
    
    init(day: Int, rewardType: RewardType, amount: Int, label: String, iconName: String) {
        self.id = day
        self.day = day
        self.rewardType = rewardType
        self.amount = amount
        self.label = label
        self.iconName = iconName
    }
}

enum RewardType {
    case freeQueries
    case proDays
}

let streakMilestones: [StreakMilestone] = [
    StreakMilestone(day: 1,   rewardType: .freeQueries, amount: 5,  label: "5 безкоштовних запитів",  iconName: "gift"),
    StreakMilestone(day: 3,   rewardType: .freeQueries, amount: 10, label: "10 безкоштовних запитів", iconName: "bolt.fill"),
    StreakMilestone(day: 5,   rewardType: .freeQueries, amount: 20, label: "20 безкоштовних запитів", iconName: "star.fill"),
    StreakMilestone(day: 7,   rewardType: .proDays,     amount: 5,  label: "5 днів Pro",             iconName: "crown.fill"),
    StreakMilestone(day: 14,  rewardType: .proDays,     amount: 3,  label: "3 дні Pro",              iconName: "diamond.fill"),
    StreakMilestone(day: 21,  rewardType: .freeQueries, amount: 30, label: "30 безкоштовних запитів", iconName: "shippingbox.fill"),
    StreakMilestone(day: 30,  rewardType: .proDays,     amount: 7,  label: "7 днів Pro",             iconName: "trophy.fill"),
    StreakMilestone(day: 50,  rewardType: .freeQueries, amount: 50, label: "50 безкоштовних запитів", iconName: "flame.fill"),
    StreakMilestone(day: 75,  rewardType: .proDays,     amount: 15, label: "15 днів Pro",            iconName: "medal.fill"),
    StreakMilestone(day: 100, rewardType: .proDays,     amount: 30, label: "30 днів Pro",            iconName: "trophy.fill"),
]
