import Foundation

/// Rate limiter: max [maxPerMinute] requests per rolling minute.
/// Mirrors RateLimiter.kt using Swift concurrency (actor for thread safety).
actor RateLimiter {
    static let shared = RateLimiter()
    
    private let maxPerMinute: Int = 60 // Config.maxRequestsPerMinute
    private var timestamps: [TimeInterval] = []
    
    func tryAcquire() -> Bool {
        let now = Date().timeIntervalSince1970
        timestamps.removeAll { now - $0 > 60 }
        if timestamps.count >= maxPerMinute { return false }
        timestamps.append(now)
        return true
    }
    
    func remainingRequests() -> Int {
        let now = Date().timeIntervalSince1970
        timestamps.removeAll { now - $0 > 60 }
        return maxPerMinute - timestamps.count
    }
}
