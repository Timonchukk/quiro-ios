import Foundation
import SwiftData

// MARK: - History Entry (mirrors Room HistoryEntry)

@Model
final class HistoryEntry {
    @Attribute(.unique) var id: UUID
    var question: String
    var answer: String
    var explanation: String
    var confidence: Double
    var appPackage: String
    var timestamp: Int64
    
    init(
        id: UUID = UUID(),
        question: String,
        answer: String,
        explanation: String = "",
        confidence: Double = 0.0,
        appPackage: String = "",
        timestamp: Int64 = Int64(Date().timeIntervalSince1970 * 1000)
    ) {
        self.id = id
        self.question = question
        self.answer = answer
        self.explanation = explanation
        self.confidence = confidence
        self.appPackage = appPackage
        self.timestamp = timestamp
    }
}

// MARK: - Context Entry (mirrors Room ContextEntry)

@Model
final class ContextEntry {
    @Attribute(.unique) var id: UUID
    var questionText: String
    var answerText: String
    var timestamp: Int64
    
    init(
        id: UUID = UUID(),
        questionText: String,
        answerText: String,
        timestamp: Int64 = Int64(Date().timeIntervalSince1970 * 1000)
    ) {
        self.id = id
        self.questionText = questionText
        self.answerText = answerText
        self.timestamp = timestamp
    }
}

// MARK: - Test Result Entry (mirrors Room TestResultEntry)

@Model
final class TestResultEntry {
    @Attribute(.unique) var id: UUID
    var summaryTitle: String
    var score: Int
    var totalQuestions: Int
    var percentage: Int
    var totalTimeMs: Int64
    var avgTimeMs: Int64
    var fastestMs: Int64
    var slowestMs: Int64
    var questionsJson: String
    var timestamp: Int64
    
    init(
        id: UUID = UUID(),
        summaryTitle: String = "",
        score: Int,
        totalQuestions: Int,
        percentage: Int,
        totalTimeMs: Int64,
        avgTimeMs: Int64,
        fastestMs: Int64,
        slowestMs: Int64,
        questionsJson: String = "",
        timestamp: Int64 = Int64(Date().timeIntervalSince1970 * 1000)
    ) {
        self.id = id
        self.summaryTitle = summaryTitle
        self.score = score
        self.totalQuestions = totalQuestions
        self.percentage = percentage
        self.totalTimeMs = totalTimeMs
        self.avgTimeMs = avgTimeMs
        self.fastestMs = fastestMs
        self.slowestMs = slowestMs
        self.questionsJson = questionsJson
        self.timestamp = timestamp
    }
}
