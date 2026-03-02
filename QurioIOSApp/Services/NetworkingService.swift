import Foundation
import UIKit

/// URLSession-based networking service mirroring LlmApiClient.kt (507 lines).
/// Handles Vision, Text, Multi-Image AI calls with retry logic.
final class NetworkingService {
    static let shared = NetworkingService()
    
    private let session: URLSession
    private let maxRetries = 3
    private let retryDelays: [TimeInterval] = [3, 6, 12]
    
    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 60
        config.timeoutIntervalForResource = 120
        self.session = URLSession(configuration: config)
    }
    
    // MARK: - Vision Answer (screenshot → AI)
    
    func getVisionAnswer(
        apiKey: String,
        baseUrl: String,
        model: String,
        imageBase64: String,
        systemPrompt: String,
        userText: String,
        maxTokens: Int = 1024,
        rawMode: Bool = false
    ) async -> Result<AiAnswer, Error> {
        var lastError: Error?
        
        for attempt in 0...maxRetries {
            do {
                let requestBody: [String: Any] = [
                    "model": model,
                    "max_tokens": maxTokens,
                    "temperature": 0.2,
                    "messages": [
                        ["role": "system", "content": systemPrompt],
                        ["role": "user", "content": [
                            ["type": "text", "text": userText],
                            ["type": "image_url", "image_url": [
                                "url": "data:image/jpeg;base64,\(imageBase64)"
                            ]]
                        ]]
                    ]
                ]
                
                let result = try await doRequest(
                    url: "\(baseUrl)/chat/completions",
                    apiKey: apiKey,
                    body: requestBody,
                    rawMode: rawMode
                )
                return .success(result)
            } catch let error as NetworkError where error.isRetryable && attempt < maxRetries {
                lastError = error
                try? await Task.sleep(nanoseconds: UInt64(retryDelays[attempt] * 1_000_000_000))
                continue
            } catch {
                lastError = error
                if attempt < maxRetries {
                    try? await Task.sleep(nanoseconds: UInt64(retryDelays[attempt] * 1_000_000_000))
                    continue
                }
            }
        }
        
        return .failure(lastError ?? NetworkError.unknown("Google API перевантажений. Зачекайте 30 сек і спробуйте знову."))
    }
    
    // MARK: - Text-Only Answer
    
    func getTextOnlyAnswer(
        apiKey: String,
        baseUrl: String,
        model: String,
        systemPrompt: String,
        userText: String,
        maxTokens: Int = 1024,
        rawMode: Bool = false
    ) async -> Result<AiAnswer, Error> {
        var lastError: Error?
        
        for attempt in 0...maxRetries {
            do {
                let requestBody: [String: Any] = [
                    "model": model,
                    "max_tokens": maxTokens,
                    "temperature": 0.3,
                    "messages": [
                        ["role": "system", "content": systemPrompt],
                        ["role": "user", "content": [
                            ["type": "text", "text": userText]
                        ]]
                    ]
                ]
                
                let result = try await doRequest(
                    url: "\(baseUrl)/chat/completions",
                    apiKey: apiKey,
                    body: requestBody,
                    rawMode: rawMode
                )
                return .success(result)
            } catch let error as NetworkError where error.isRetryable && attempt < maxRetries {
                lastError = error
                try? await Task.sleep(nanoseconds: UInt64(retryDelays[attempt] * 1_000_000_000))
                continue
            } catch {
                lastError = error
                if attempt < maxRetries {
                    try? await Task.sleep(nanoseconds: UInt64(retryDelays[attempt] * 1_000_000_000))
                    continue
                }
            }
        }
        
        return .failure(lastError ?? NetworkError.unknown("Google API перевантажений. Зачекайте 30 сек і спробуйте знову."))
    }
    
    // MARK: - Multi-Image Answer (summary mode)
    
    func getMultiImageAnswer(
        apiKey: String,
        baseUrl: String,
        model: String,
        imagesBase64: [String],
        systemPrompt: String,
        userText: String,
        maxTokens: Int = 4096
    ) async -> Result<AiAnswer, Error> {
        var lastError: Error?
        
        for attempt in 0...maxRetries {
            do {
                var contentArray: [[String: Any]] = [
                    ["type": "text", "text": userText]
                ]
                for img in imagesBase64 {
                    contentArray.append([
                        "type": "image_url",
                        "image_url": ["url": "data:image/jpeg;base64,\(img)"]
                    ])
                }
                
                let requestBody: [String: Any] = [
                    "model": model,
                    "max_tokens": maxTokens,
                    "temperature": 0.3,
                    "messages": [
                        ["role": "system", "content": systemPrompt],
                        ["role": "user", "content": contentArray]
                    ]
                ]
                
                let result = try await doRequest(
                    url: "\(baseUrl)/chat/completions",
                    apiKey: apiKey,
                    body: requestBody,
                    rawMode: true
                )
                return .success(result)
            } catch let error as NetworkError where error.isRetryable && attempt < maxRetries {
                lastError = error
                try? await Task.sleep(nanoseconds: UInt64(retryDelays[attempt] * 1_000_000_000))
                continue
            } catch {
                lastError = error
                if attempt < maxRetries {
                    try? await Task.sleep(nanoseconds: UInt64(retryDelays[attempt] * 1_000_000_000))
                    continue
                }
            }
        }
        
        return .failure(lastError ?? NetworkError.unknown("Google API перевантажений. Зачекайте 30 сек і спробуйте знову."))
    }
    
    // MARK: - Generic Server Request (for auth, sync, etc.)
    
    func serverRequest(
        endpoint: String,
        method: String = "POST",
        body: [String: Any]? = nil,
        token: String? = nil
    ) async throws -> (Data, HTTPURLResponse) {
        let url = "\(Config.serverBaseURL)\(endpoint)"
        guard let requestURL = URL(string: url) else {
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: requestURL)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let token {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        if let body, method != "GET" {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        }
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }
        
        return (data, httpResponse)
    }
    
    // MARK: - Private: Core Request
    
    private func doRequest(
        url: String,
        apiKey: String,
        body: [String: Any],
        rawMode: Bool
    ) async throws -> AiAnswer {
        guard let requestURL = URL(string: url) else {
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: requestURL)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }
        
        if !( 200..<300 ~= httpResponse.statusCode) {
            let errorBody = String(data: data, encoding: .utf8) ?? ""
            switch httpResponse.statusCode {
            case 401: throw NetworkError.apiError("Невірний API ключ. Перевірте ключ в налаштуваннях.")
            case 403: throw NetworkError.apiError("Доступ заборонено. Перевірте API ключ.")
            case 404: throw NetworkError.apiError("Модель не знайдена. Перевірте назву моделі.")
            case 429: throw NetworkError.rateLimited
            default: throw NetworkError.apiError("Помилка API (\(httpResponse.statusCode)): \(String(errorBody.prefix(200)))")
            }
        }
        
        return try parseResponse(data: data, rawMode: rawMode)
    }
    
    // MARK: - Response Parsing
    
    private func parseResponse(data: Data, rawMode: Bool) throws -> AiAnswer {
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let choices = json["choices"] as? [[String: Any]] else {
            throw NetworkError.parseError("Не вдалося розпарсити відповідь.")
        }
        
        var rawContent: String?
        for choice in choices {
            if let msg = choice["message"] as? [String: Any],
               let content = msg["content"] as? String, !content.isEmpty {
                rawContent = content
                break
            }
        }
        
        guard let content = rawContent, !content.isEmpty else {
            throw NetworkError.parseError("Порожня відповідь від LLM.")
        }
        
        if rawMode {
            return AiAnswer(answer: content, explanation: "", confidence: 0.9)
        }
        
        let (answer, explanation) = parseLabeledAnswer(content)
        return AiAnswer(answer: answer, explanation: explanation, confidence: 0.9)
    }
    
    /// Parses "Відповідь: ... \n Пояснення: ..." format from the AI.
    /// Mirrors LlmApiClient.parseLabeledAnswer()
    private func parseLabeledAnswer(_ raw: String) -> (String, String) {
        let text = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if text.isEmpty { return ("", "") }
        
        let lines = text.components(separatedBy: "\n")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        
        func extractValue(_ line: String) -> String {
            guard let colonIdx = line.firstIndex(of: ":") else { return line }
            return String(line[line.index(after: colonIdx)...]).trimmingCharacters(in: .whitespaces)
        }
        
        let tvirLine = lines.first { $0.lowercased().hasPrefix("твір:") }
        let answerLine = lines.first { $0.lowercased().hasPrefix("відповідь") }
        let explLine = lines.first { $0.lowercased().hasPrefix("пояснення") }
        
        let answerValue = answerLine.map { extractValue($0) } ?? lines.first ?? ""
        let explanationValue = explLine.map { extractValue($0) } ?? ""
        
        let cleanedExplanation = cleanExplanation(explanationValue)
        
        var combinedAnswer = answerValue.trimmingCharacters(in: .whitespaces)
        if let tvir = tvirLine, !tvir.isEmpty {
            combinedAnswer += "\n" + tvir.trimmingCharacters(in: .whitespaces)
        }
        
        return (combinedAnswer, cleanedExplanation)
    }
    
    /// Removes common lead-in phrases from explanations.
    /// Mirrors LlmApiClient.cleanExplanation()
    private func cleanExplanation(_ expl: String) -> String {
        var s = expl.trimmingCharacters(in: .whitespacesAndNewlines)
        if s.isEmpty { return s }
        
        // Remove duplicate label
        for prefix in ["Пояснення:", "пояснення:"] {
            if s.hasPrefix(prefix) { s = String(s.dropFirst(prefix.count)).trimmingCharacters(in: .whitespaces) }
        }
        
        // Strip common Ukrainian lead-in phrases
        let patterns: [(String, NSRegularExpression.Options)] = [
            (#"^питання\s+(запитує|питає|просить)\s*[,.:\-]?\s*"#, [.caseInsensitive]),
            (#"^у\s+цьому\s+питанні\s+(йдеться|питають|запитують)\s*[,.:\-]?\s*"#, [.caseInsensitive]),
            (#"^у\s+питанні\s+(йдеться|питають|запитують)\s*[,.:\-]?\s*"#, [.caseInsensitive]),
            (#"^це\s+питання\s+про\s*[,.:\-]?\s*"#, [.caseInsensitive])
        ]
        
        for (pattern, _) in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
                let range = NSRange(s.startIndex..., in: s)
                let replaced = regex.stringByReplacingMatches(in: s, range: range, withTemplate: "")
                if replaced != s {
                    s = replaced.trimmingCharacters(in: .whitespaces)
                    break
                }
            }
        }
        
        // If not starting with "Бо"/"Тому що", find causal fragment
        if !s.lowercased().hasPrefix("бо") && !s.lowercased().hasPrefix("тому що") {
            let markers = ["бо ", "тому що ", "оскільки ", "адже ", "через "]
            var bestPos = Int.max
            for marker in markers {
                if let range = s.range(of: marker, options: .caseInsensitive) {
                    let pos = s.distance(from: s.startIndex, to: range.lowerBound)
                    if pos < bestPos {
                        bestPos = pos
                    }
                }
            }
            if bestPos < s.count {
                let idx = s.index(s.startIndex, offsetBy: bestPos)
                s = String(s[idx...]).trimmingCharacters(in: .whitespaces)
                // Normalize start
                if s.lowercased().hasPrefix("бо ") {
                    s = "Бо" + s.dropFirst(2)
                }
                if s.lowercased().hasPrefix("тому що") {
                    s = "Тому що" + s.dropFirst(7)
                }
            }
        }
        
        return s.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    // MARK: - Image Utilities
    
    /// Converts UIImage to base64-encoded JPEG string (scaled to max 1024px).
    /// Mirrors LlmRepository.bitmapToBase64()
    static func imageToBase64(_ image: UIImage) -> String? {
        let scaled = scaleImage(image, maxDimension: 1024)
        guard let data = scaled.jpegData(compressionQuality: 0.85) else { return nil }
        return data.base64EncodedString()
    }
    
    private static func scaleImage(_ image: UIImage, maxDimension: CGFloat) -> UIImage {
        let w = image.size.width
        let h = image.size.height
        if w <= maxDimension && h <= maxDimension { return image }
        
        let ratio = maxDimension / max(w, h)
        let newSize = CGSize(width: w * ratio, height: h * ratio)
        
        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}

// MARK: - Network Error

enum NetworkError: Error, LocalizedError {
    case invalidURL
    case invalidResponse
    case rateLimited
    case apiError(String)
    case parseError(String)
    case unauthorized
    case unknown(String)
    
    var isRetryable: Bool {
        switch self {
        case .rateLimited: return true
        default: return false
        }
    }
    
    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Невірна URL адреса."
        case .invalidResponse: return "Невірна відповідь сервера."
        case .rateLimited: return "Забагато запитів. Зачекайте хвилину."
        case .apiError(let msg): return msg
        case .parseError(let msg): return msg
        case .unauthorized: return "Не авторизовано. Увійдіть знову."
        case .unknown(let msg): return msg
        }
    }
}
