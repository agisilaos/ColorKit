//
//  AccessiblePaletteGenerator.swift
//  ColorKit
//
//  Created by Agisilaos Tsaraboulidis on 12.03.25.
//
//  Description:
//  Provides functionality to generate accessible color palettes that meet WCAG guidelines.
//
//  Features:
//  - Generates color palettes that meet specific WCAG contrast levels
//  - Creates accessible themes with proper contrast between elements
//  - Customizable palette size and accessibility requirements
//
//  License:
//  MIT License. See LICENSE file for details.
//

import SwiftUI

/// A generator for creating accessible color palettes that meet WCAG guidelines
@available(iOS 14.0, macOS 11.0, *)
public struct AccessiblePaletteGenerator {
    /// Configuration options for palette generation
    public struct Configuration {
        /// The minimum contrast ratio to enforce between foreground and background colors
        public let minimumContrastRatio: Double
        
        /// The WCAG level to target
        public let targetLevel: WCAGContrastLevel
        
        /// The number of colors to generate in the palette
        public let paletteSize: Int
        
        /// Whether to include black and white in the palette
        public let includeBlackAndWhite: Bool
        
        /// Creates a new configuration with the specified parameters
        /// - Parameters:
        ///   - targetLevel: The WCAG level to target (default: .AA)
        ///   - paletteSize: The number of colors to generate (default: 5)
        ///   - includeBlackAndWhite: Whether to include black and white (default: true)
        public init(
            targetLevel: WCAGContrastLevel = .AA,
            paletteSize: Int = 5,
            includeBlackAndWhite: Bool = true
        ) {
            self.targetLevel = targetLevel
            self.minimumContrastRatio = targetLevel.minimumRatio
            self.paletteSize = max(paletteSize, 2) // Minimum of 2 colors
            self.includeBlackAndWhite = includeBlackAndWhite
        }
    }
    
    /// The configuration for palette generation
    private let configuration: Configuration
    
    /// Creates a new palette generator with the specified configuration
    /// - Parameter configuration: The configuration to use
    public init(configuration: Configuration = Configuration()) {
        self.configuration = configuration
    }
    
    /// Generates an accessible color palette based on a seed color
    /// - Parameter seedColor: The color to base the palette on
    /// - Returns: An array of colors that form an accessible palette
    public func generatePalette(from seedColor: Color) -> [Color] {
        var palette: [Color] = []
        
        // Add seed color to the palette
        palette.append(seedColor)
        
        // Add black and white if configured
        if configuration.includeBlackAndWhite {
            palette.append(.black)
            palette.append(.white)
        }
        
        // Generate additional colors to reach the desired palette size
        while palette.count < configuration.paletteSize {
            // Generate a new color that contrasts well with the seed color
            if let newColor = generateContrastingColor(for: seedColor) {
                // Ensure the new color is distinct from existing colors
                if !palette.contains(where: { areColorsSimilar($0, newColor) }) {
                    palette.append(newColor)
                }
            }
        }
        
        return palette
    }
    
    /// Generates a theme from a seed color with accessible color combinations
    /// - Parameters:
    ///   - seedColor: The primary color to base the theme on
    ///   - name: The name for the theme
    /// - Returns: A ColorTheme with accessible color combinations
    public func generateAccessibleTheme(from seedColor: Color, name: String) -> ColorTheme {
        // Generate a palette of colors
        let palette = generatePalette(from: seedColor)
        
        // Find a good background color (usually white or a very light color)
        let backgroundColor = findBestBackgroundColor(in: palette, for: seedColor)
        
        // Find a good text color that contrasts with the background
        let textColor = findBestTextColor(for: backgroundColor)
        
        // Find a good accent color that contrasts with both background and primary
        let accentColor = findBestAccentColor(in: palette, background: backgroundColor, primary: seedColor)
        
        // Generate a secondary color that complements the primary
        let secondaryColor = generateComplementaryColor(for: seedColor)
        
        // Create the theme
        return ColorTheme(
            name: name,
            primary: seedColor,
            secondary: secondaryColor,
            accent: accentColor,
            background: backgroundColor,
            text: textColor
        )
    }
    
    // MARK: - Private Helper Methods
    
    /// Generates a color that contrasts well with the given color
    private func generateContrastingColor(for color: Color) -> Color? {
        // Get the HSL components of the color
        guard let hsl = color.hslComponents() else { return nil }
        
        // Create a contrasting color by shifting the hue and adjusting lightness
        let newHue = (hsl.hue + 0.5).truncatingRemainder(dividingBy: 1.0)
        let newLightness = hsl.lightness < 0.5 ? min(hsl.lightness + 0.3, 0.9) : max(hsl.lightness - 0.3, 0.1)
        
        let contrastingColor = Color(hue: newHue, saturation: hsl.saturation, lightness: newLightness)
        
        // Verify the contrast ratio meets our requirements
        let ratio = color.wcagContrastRatio(with: contrastingColor)
        if ratio >= configuration.minimumContrastRatio {
            return contrastingColor
        }
        
        // If contrast is insufficient, adjust lightness further
        let adjustedLightness = hsl.lightness < 0.5 ? 0.9 : 0.1
        return Color(hue: newHue, saturation: hsl.saturation, lightness: adjustedLightness)
    }
    
    /// Generates a complementary color for the given color
    private func generateComplementaryColor(for color: Color) -> Color {
        guard let hsl = color.hslComponents() else { return color }
        
        // Complementary color has opposite hue
        let complementaryHue = (hsl.hue + 0.5).truncatingRemainder(dividingBy: 1.0)
        
        // Adjust saturation and lightness to ensure good contrast
        let saturation = min(hsl.saturation + 0.1, 1.0)
        let lightness = hsl.lightness < 0.5 ? min(hsl.lightness + 0.1, 0.9) : max(hsl.lightness - 0.1, 0.1)
        
        return Color(hue: complementaryHue, saturation: saturation, lightness: lightness)
    }
    
    /// Finds the best background color from a palette
    private func findBestBackgroundColor(in palette: [Color], for primaryColor: Color) -> Color {
        // Prefer white or very light colors for background
        let candidates = palette.filter { color in
            guard let hsl = color.hslComponents() else { return false }
            return hsl.lightness > 0.85 && color.wcagContrastRatio(with: primaryColor) >= configuration.minimumContrastRatio
        }
        
        if let bestCandidate = candidates.first {
            return bestCandidate
        }
        
        // If no suitable background found, use white
        return .white
    }
    
    /// Finds the best text color for a background
    private func findBestTextColor(for backgroundColor: Color) -> Color {
        // For light backgrounds, use dark text
        let backgroundLuminance = backgroundColor.wcagRelativeLuminance()
        
        if backgroundLuminance > 0.5 {
            return .black
        } else {
            return .white
        }
    }
    
    /// Finds the best accent color from a palette
    private func findBestAccentColor(in palette: [Color], background: Color, primary: Color) -> Color {
        // Find colors that contrast well with both background and primary
        let candidates = palette.filter { color in
            let contrastWithBackground = color.wcagContrastRatio(with: background)
            let contrastWithPrimary = color.wcagContrastRatio(with: primary)
            return contrastWithBackground >= configuration.minimumContrastRatio && 
                   contrastWithPrimary >= 2.0 && // Lower threshold for primary contrast
                   color != primary && 
                   color != background
        }
        
        if let bestCandidate = candidates.first {
            return bestCandidate
        }
        
        // If no suitable accent found, generate one
        if let accent = generateContrastingColor(for: background) {
            return accent
        }
        
        // Fallback to a standard accent color
        return .blue
    }
    
    /// Determines if two colors are visually similar
    private func areColorsSimilar(_ color1: Color, _ color2: Color) -> Bool {
        guard let hsl1 = color1.hslComponents(),
              let hsl2 = color2.hslComponents() else {
            return false
        }
        
        // Calculate the difference in hue, saturation, and lightness
        let hueDiff = min(abs(hsl1.hue - hsl2.hue), 1 - abs(hsl1.hue - hsl2.hue))
        let saturationDiff = abs(hsl1.saturation - hsl2.saturation)
        let lightnessDiff = abs(hsl1.lightness - hsl2.lightness)
        
        // Define thresholds for similarity
        let hueThreshold = 0.08 // About 30 degrees in the color wheel
        let saturationThreshold = 0.15
        let lightnessThreshold = 0.15
        
        return hueDiff < hueThreshold && 
               saturationDiff < saturationThreshold && 
               lightnessDiff < lightnessThreshold
    }
} 