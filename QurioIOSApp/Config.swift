import Foundation

/// Central configuration constants for the Qurio iOS app.
enum Config {
    // MARK: - Server
    static let serverBaseURL = "https://quirhelp.com"
    
    // MARK: - AI Defaults
    static let defaultAIBaseURL = "https://generativelanguage.googleapis.com/v1beta/openai"
    static let defaultModel = "gemini-3-flash-preview"
    
    // MARK: - Trial System
    static let maxTrialRequests = 10
    static let trialPeriodSeconds: TimeInterval = 3 * 24 * 60 * 60  // 3 days
    
    // MARK: - Summary
    static let maxDailySummaries = 3
    
    // MARK: - Rate Limiter
    static let maxRequestsPerMinute = 60
    
    // MARK: - Admin Emails
    static let adminEmails = [
        "timonchukdesign@gmail.com",
        "max2021khmi@gmail.com",
        "mashatima850@gmail.com"
    ]
    
    // MARK: - StoreKit Product IDs
    static let proMonthlyProductID = "com.qurio.pro.monthly"
    static let proYearlyProductID = "com.qurio.pro.yearly"
    
    // MARK: - App Group (for Broadcast Extension)
    static let appGroupID = "group.com.quiro.app"
    
    // MARK: - Broadcast Extension
    static let broadcastExtensionBundleID = "com.quiro.app.BroadcastUploadExtension"
    
    // MARK: - Broadcast Shared Keys
    static let broadcastActiveKey = "broadcast_active"
    static let latestFrameTimestampKey = "latest_frame_timestamp"
    static let latestFrameFilename = "latest_frame.jpg"
    
    // MARK: - Darwin Notification
    static let darwinNotificationName = "com.quiro.app.newframe"
    
    // MARK: - Keychain
    static let keychainServiceName = "com.qurio.keychain"
    
    // MARK: - Google Sign-In
    static let googleClientID = "" // Set from GoogleService-Info.plist
}
