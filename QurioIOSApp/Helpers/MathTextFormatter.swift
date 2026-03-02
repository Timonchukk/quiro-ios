import SwiftUI

/// Parses and renders AI response text with basic markdown formatting.
/// Mirrors MathTextFormatter.kt for rendering bold, headers, lists, and inline math.
struct FormattedAIText: View {
    let text: String
    let fontSize: CGFloat
    
    init(_ text: String, fontSize: CGFloat = 15) {
        self.text = text
        self.fontSize = fontSize
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            ForEach(Array(parseLines().enumerated()), id: \.offset) { _, line in
                line
            }
        }
    }
    
    private func parseLines() -> [AnyView] {
        let lines = text.components(separatedBy: "\n")
        return lines.map { line in
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            
            if trimmed.hasPrefix("## ") {
                let heading = String(trimmed.dropFirst(3))
                return AnyView(
                    Text(renderInline(heading))
                        .font(.system(size: fontSize + 4, weight: .bold))
                        .padding(.top, 8)
                )
            }
            
            if trimmed.hasPrefix("### ") {
                let heading = String(trimmed.dropFirst(4))
                return AnyView(
                    Text(renderInline(heading))
                        .font(.system(size: fontSize + 2, weight: .semibold))
                        .padding(.top, 6)
                )
            }
            
            if trimmed.hasPrefix("- ") || trimmed.hasPrefix("• ") {
                let item = String(trimmed.dropFirst(2))
                return AnyView(
                    HStack(alignment: .top, spacing: 6) {
                        Text("•")
                            .font(.system(size: fontSize))
                        Text(renderInline(item))
                            .font(.system(size: fontSize))
                    }
                    .padding(.leading, 8)
                )
            }
            
            // Numbered lists (1. 2. etc.)
            if let range = trimmed.range(of: #"^\d+\.\s"#, options: .regularExpression) {
                let num = String(trimmed[trimmed.startIndex..<range.lowerBound]) + String(trimmed[range])
                let rest = String(trimmed[range.upperBound...])
                return AnyView(
                    HStack(alignment: .top, spacing: 4) {
                        Text(num)
                            .font(.system(size: fontSize, weight: .medium))
                        Text(renderInline(rest))
                            .font(.system(size: fontSize))
                    }
                    .padding(.leading, 8)
                )
            }
            
            if trimmed.isEmpty {
                return AnyView(Spacer().frame(height: 4))
            }
            
            return AnyView(
                Text(renderInline(trimmed))
                    .font(.system(size: fontSize))
            )
        }
    }
    
    /// Renders inline markdown: **bold**, *italic*, `code`
    private func renderInline(_ text: String) -> AttributedString {
        var result = AttributedString(text)
        
        // Bold: **text**
        while let boldRange = result.range(of: "**", options: .literal) {
            // Find closing **
            let searchStart = result.index(afterCharacter: boldRange.upperBound)
            guard searchStart < result.endIndex,
                  let closeRange = result[searchStart...].range(of: "**", options: .literal) else { break }
            
            // Extract content between **...**
            let contentRange = boldRange.upperBound..<closeRange.lowerBound
            result[contentRange].font = .system(size: fontSize, weight: .bold)
            
            // Remove the closing ** first (to preserve indices)
            result.removeSubrange(closeRange)
            // Remove the opening **
            result.removeSubrange(boldRange)
        }
        
        return result
    }
}
