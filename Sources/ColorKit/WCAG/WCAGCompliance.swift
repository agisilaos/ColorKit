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
        if let cachedRatio = ColorCache.shared.getCachedContrastRatio(for: self, and: color) {
            return cachedRatio
        }
        
        let luminance1 = self.wcagRelativeLuminance()
        let luminance2 = color.wcagRelativeLuminance()
        
        let lighter = max(luminance1, luminance2)
        let darker = min(luminance1, luminance2)
        
        let ratio = (lighter + 0.05) / (darker + 0.05)
        
        // Cache the result
        ColorCache.shared.cacheContrastRatio(for: self, and: color, ratio: ratio)
        
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