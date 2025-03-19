import SwiftUI

/// Represents the WCAG contrast ratio levels
public enum WCAGContrastLevel: String, CaseIterable, Identifiable, Sendable {
    case AALarge = "AA Large"
    case AA = "AA"
    case AAALarge = "AAA Large"
    case AAA = "AAA"

    public var id: String { rawValue }

    /// The minimum contrast ratio required for this level
    public var minimumRatio: Double {
        switch self {
        case .AALarge:
            return 3.0
        case .AA:
            return 4.5
        case .AAALarge:
            return 4.5
        case .AAA:
            return 7.0
        }
    }

    /// Description of the WCAG level
    public var description: String {
        switch self {
        case .AALarge:
            return "AA level for large text (18pt+)"
        case .AA:
            return "AA level for normal text"
        case .AAALarge:
            return "AAA level for large text (18pt+)"
        case .AAA:
            return "AAA level for normal text"
        }
    }
}

/// Result of a WCAG compliance check
public struct WCAGComplianceResult {
    public let contrastRatio: Double
    public let passesAA: Bool
    public let passesAALarge: Bool
    public let passesAAA: Bool
    public let passesAAALarge: Bool

    public var highestLevel: WCAGContrastLevel? {
        if passesAAA {
            return .AAA
        } else if passesAAALarge {
            return .AAALarge
        } else if passesAA {
            return .AA
        } else if passesAALarge {
            return .AALarge
        } else {
            return nil
        }
    }

    public var passes: [WCAGContrastLevel] {
        var result: [WCAGContrastLevel] = []
        if passesAALarge { result.append(.AALarge) }
        if passesAA { result.append(.AA) }
        if passesAAALarge { result.append(.AAALarge) }
        if passesAAA { result.append(.AAA) }
        return result
    }
}

// Extension to get RGBA components
extension Color {
    /// Get the RGBA components of a color
    func wcagRGBAComponents() -> (red: Double, green: Double, blue: Double, alpha: Double) {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0

        #if canImport(UIKit)
        UIColor(self).getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        #elseif canImport(AppKit)
        NSColor(self).usingColorSpace(.sRGB)?.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        #endif

        return (Double(red), Double(green), Double(blue), Double(alpha))
    }
}

public extension Color {
    /// Returns the RGBA components of a color
    ///
    /// - Returns: A tuple containing red, green, blue, and alpha components as Double values (0.0-1.0)
    func rgbaComponents() -> (red: Double, green: Double, blue: Double, alpha: Double) {
        return wcagRGBAComponents()
    }

    /// Calculate the relative luminance of a color as defined by WCAG 2.0
    func wcagRelativeLuminance() -> Double {
        // Check cache first
        if let cachedLuminance = ColorCache.shared.getCachedLuminance(for: self) {
            return cachedLuminance
        }

        let rgba = self.rgbaComponents()

        // Convert sRGB to linear RGB
        let r = rgba.red <= 0.03928 ? rgba.red / 12.92 : pow((rgba.red + 0.055) / 1.055, 2.4)
        let g = rgba.green <= 0.03928 ? rgba.green / 12.92 : pow((rgba.green + 0.055) / 1.055, 2.4)
        let b = rgba.blue <= 0.03928 ? rgba.blue / 12.92 : pow((rgba.blue + 0.055) / 1.055, 2.4)

        // Calculate relative luminance
        let luminance = 0.2126 * r + 0.7152 * g + 0.0722 * b

        // Cache the result
        ColorCache.shared.cacheLuminance(for: self, luminance: luminance)

        return luminance
    }

    /// Calculate the contrast ratio between this color and another color
    func wcagContrastRatio(with color: Color) -> Double {
        // Check cache first
        if let cachedRatio = ColorCache.shared.getCachedContrastRatio(for: self, with: color) {
            return cachedRatio
        }

        let luminance1 = self.wcagRelativeLuminance()
        let luminance2 = color.wcagRelativeLuminance()

        let lighter = max(luminance1, luminance2)
        let darker = min(luminance1, luminance2)

        let ratio = (lighter + 0.05) / (darker + 0.05)

        // Cache the result
        ColorCache.shared.cacheContrastRatio(for: self, with: color, ratio: ratio)

        return ratio
    }

    /// Check WCAG compliance between this color and another color
    func wcagCompliance(with color: Color) -> WCAGComplianceResult {
        let ratio = self.wcagContrastRatio(with: color)

        return WCAGComplianceResult(
            contrastRatio: ratio,
            passesAA: ratio >= 4.5,
            passesAALarge: ratio >= 3.0,
            passesAAA: ratio >= 7.0,
            passesAAALarge: ratio >= 4.5
        )
    }

    /// Get a suggested color that would meet the specified WCAG level when paired with this color
    func suggestedColor(for level: WCAGContrastLevel) -> Color {
        let luminance = self.wcagRelativeLuminance()

        // If the color is dark, suggest a lighter color, and vice versa
        if luminance < 0.5 {
            // Suggest a light color
            return .white
        } else {
            // Suggest a dark color
            return .black
        }
    }
}

/// Provides advanced color suggestions to achieve WCAG compliance
public struct WCAGColorSuggestions {
    private let baseColor: Color
    private let targetColor: Color
    private let targetLevel: WCAGContrastLevel

    /// Creates a new WCAG color suggestions generator
    /// - Parameters:
    ///   - baseColor: The base color that won't be changed
    ///   - targetColor: The color that needs to be adjusted for compliance
    ///   - targetLevel: The WCAG compliance level to aim for
    public init(baseColor: Color, targetColor: Color, targetLevel: WCAGContrastLevel = .AA) {
        self.baseColor = baseColor
        self.targetColor = targetColor
        self.targetLevel = targetLevel
    }

    /// Generates a set of color suggestions that meet WCAG compliance
    /// - Parameter preserveHue: Whether to preserve the original hue when generating suggestions
    /// - Returns: An array of suggested colors that meet the required contrast level
    public func generateSuggestions(preserveHue: Bool = true) -> [Color] {
        let currentCompliance = baseColor.wcagCompliance(with: targetColor)

        // If already compliant, return the original color
        if currentCompliance.passes.contains(targetLevel) {
            return [targetColor]
        }

        var suggestions: [Color] = []

        // Get target color components
        guard let hsl = targetColor.hslComponents() else {
            return [targetColor]
        }

        let baseLuminance = baseColor.wcagRelativeLuminance()
        let targetMinimumRatio = targetLevel.minimumRatio

        // Determine if we need to lighten or darken
        let needsDarkening = baseLuminance > 0.5

        // Generate a lighter/darker version maintaining hue and saturation
        if preserveHue {
            // Adjust lightness in increments
            let steps = 10
            for i in 1...steps {
                let adjustedLightness = needsDarkening
                    ? max(0.0, hsl.lightness - (Double(i) / Double(steps)) * hsl.lightness)
                    : min(1.0, hsl.lightness + (Double(i) / Double(steps)) * (1.0 - hsl.lightness))

                if let adjustedColor = Color.fromHSL(hue: hsl.hue, saturation: hsl.saturation, lightness: CGFloat(adjustedLightness)) {
                    let compliance = baseColor.wcagCompliance(with: adjustedColor)
                    if compliance.passes.contains(targetLevel) {
                        suggestions.append(adjustedColor)
                        break
                    }
                }
            }
        }

        // If we couldn't find a suitable color by adjusting lightness alone,
        // try adjusting saturation as well
        if suggestions.isEmpty {
            for saturationFactor in stride(from: 0.8, to: 0.0, by: -0.2) {
                let adjustedSaturation = hsl.saturation * saturationFactor

                let adjustedLightness = needsDarkening ? 0.0 : 1.0

                if let adjustedColor = Color.fromHSL(hue: hsl.hue, saturation: adjustedSaturation, lightness: CGFloat(adjustedLightness)) {
                    let compliance = baseColor.wcagCompliance(with: adjustedColor)
                    if compliance.passes.contains(targetLevel) {
                        suggestions.append(adjustedColor)
                        break
                    }
                }
            }
        }

        // If still no suggestions, add fallback colors
        if suggestions.isEmpty {
            suggestions.append(needsDarkening ? .black : .white)
        }

        return suggestions
    }
}

public extension Color {
    /// Creates a color from HSL components
    /// - Parameters:
    ///   - hue: Hue value (0-1)
    ///   - saturation: Saturation value (0-1)
    ///   - lightness: Lightness value (0-1)
    /// - Returns: A new color or nil if the conversion failed
    static func fromHSL(hue: CGFloat, saturation: CGFloat, lightness: CGFloat) -> Color? {
        // Convert HSL to RGB
        let h = hue
        let s = saturation
        let l = lightness

        let c = (1 - abs(2 * l - 1)) * s
        let x = c * (1 - abs(fmod(h * 6, 2) - 1))
        let m = l - c / 2

        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0

        if h < 1 / 6 {
            r = c; g = x; b = 0
        } else if h < 2 / 6 {
            r = x; g = c; b = 0
        } else if h < 3 / 6 {
            r = 0; g = c; b = x
        } else if h < 4 / 6 {
            r = 0; g = x; b = c
        } else if h < 5 / 6 {
            r = x; g = 0; b = c
        } else {
            r = c; g = 0; b = x
        }

        r += m
        g += m
        b += m

        #if canImport(UIKit)
        return Color(UIColor(red: r, green: g, blue: b, alpha: 1.0))
        #elseif canImport(AppKit)
        return Color(NSColor(calibratedRed: r, green: g, blue: b, alpha: 1.0))
        #else
        return nil
        #endif
    }

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
