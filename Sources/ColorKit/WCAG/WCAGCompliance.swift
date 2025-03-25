import SwiftUI

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
