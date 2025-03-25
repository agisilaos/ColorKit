import SwiftUI

public extension Color {
    /// Get suggested colors that would comply with the specified WCAG level when paired with this color
    /// - Parameters:
    ///   - color: The color to improve contrast with
    ///   - level: The WCAG compliance level to achieve
    ///   - preserveHue: Whether to try preserving the original hue
    /// - Returns: An array of suggested colors that meet the compliance level
    func suggestedAccessibleColors(for color: Color, level: WCAGContrastLevel = .AA, preserveHue: Bool = true) -> [Color] {
        let suggestions = WCAGColorSuggestions(baseColor: self, targetColor: color, targetLevel: level)
        return suggestions.generateSuggestions(preserveHue: preserveHue)
    }
}
