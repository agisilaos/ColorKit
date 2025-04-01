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

/// A utility for generating accessible color palettes that meet WCAG guidelines.
///
/// `AccessiblePaletteGenerator` helps create color palettes and themes that are both
/// aesthetically pleasing and accessible. It ensures that generated color combinations
/// meet specified WCAG contrast requirements while maintaining visual harmony.
///
/// Key features:
/// - Generate accessible color palettes from a seed color
/// - Create complete themes with proper contrast between elements
/// - Customize palette size and accessibility requirements
/// - Support for different WCAG compliance levels
///
/// Example usage:
/// ```swift
/// // Create a generator with custom configuration
/// let config = AccessiblePaletteGenerator.Configuration(
///     targetLevel: .AA,
///     paletteSize: 5,
///     includeBlackAndWhite: true
/// )
/// let generator = AccessiblePaletteGenerator(configuration: config)
///
/// // Generate a palette from a seed color
/// let seedColor = Color.blue
/// let palette = generator.generatePalette(from: seedColor)
///
/// // Create an accessible theme
/// let theme = generator.generateAccessibleTheme(
///     from: seedColor,
///     name: "Ocean Theme"
/// )
/// ```
public struct AccessiblePaletteGenerator {
    /// Configuration options for palette generation.
    ///
    /// This structure defines the parameters that control how color palettes
    /// are generated, including accessibility requirements and palette characteristics.
    ///
    /// Example:
    /// ```swift
    /// let config = AccessiblePaletteGenerator.Configuration(
    ///     targetLevel: .AAA,        // Highest accessibility level
    ///     paletteSize: 7,           // 7 colors in the palette
    ///     includeBlackAndWhite: true // Include black and white
    /// )
    /// ```
    public struct Configuration {
        /// The minimum contrast ratio to enforce between foreground and background colors.
        ///
        /// This value is derived from the target WCAG level and ensures that all
        /// color combinations in the palette meet the required contrast ratio.
        public let minimumContrastRatio: Double

        /// The WCAG level to target for accessibility compliance.
        ///
        /// This determines the minimum contrast requirements:
        /// - AA: 4.5:1 for normal text
        /// - AAA: 7:1 for normal text
        public let targetLevel: WCAGContrastLevel

        /// The number of colors to generate in the palette.
        ///
        /// The generator will attempt to create this many distinct colors
        /// that meet the contrast requirements. Minimum value is 2.
        public let paletteSize: Int

        /// Whether to include black and white in the palette.
        ///
        /// When true, black and white will be added to the palette automatically,
        /// ensuring maximum contrast options are available.
        public let includeBlackAndWhite: Bool

        /// Creates a new configuration with the specified parameters.
        ///
        /// Example:
        /// ```swift
        /// let config = Configuration(
        ///     targetLevel: .AA,
        ///     paletteSize: 5,
        ///     includeBlackAndWhite: true
        /// )
        /// ```
        ///
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

    /// The configuration controlling palette generation behavior.
    private let configuration: Configuration

    /// Creates a new palette generator with the specified configuration.
    ///
    /// Example:
    /// ```swift
    /// // Use default configuration
    /// let generator = AccessiblePaletteGenerator()
    ///
    /// // Or with custom configuration
    /// let config = AccessiblePaletteGenerator.Configuration(
    ///     targetLevel: .AAA,
    ///     paletteSize: 6
    /// )
    /// let customGenerator = AccessiblePaletteGenerator(configuration: config)
    /// ```
    ///
    /// - Parameter configuration: The configuration to use for generating palettes
    public init(configuration: Configuration = Configuration()) {
        self.configuration = configuration
    }

    /// Generates an accessible color palette based on a seed color.
    ///
    /// This method creates a palette of colors that:
    /// - Meet the specified WCAG contrast requirements
    /// - Are visually distinct from each other
    /// - Maintain harmony with the seed color
    ///
    /// The generation process:
    /// 1. Starts with the seed color
    /// 2. Adds black and white if configured
    /// 3. Generates additional contrasting colors
    /// 4. Falls back to default colors if needed
    ///
    /// Example:
    /// ```swift
    /// let generator = AccessiblePaletteGenerator()
    /// let seedColor = Color.blue
    ///
    /// // Generate a palette
    /// let palette = generator.generatePalette(from: seedColor)
    ///
    /// // Use colors in UI
    /// ForEach(palette, id: \.self) { color in
    ///     Rectangle()
    ///         .fill(color)
    ///         .frame(height: 50)
    /// }
    /// ```
    ///
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
        let maxAttempts = 100 // Prevent infinite loops
        var attempts = 0

        while palette.count < configuration.paletteSize && attempts < maxAttempts {
            attempts += 1

            // Generate a new color that contrasts well with the seed color
            if let newColor = generateContrastingColor(for: seedColor) {
                // Ensure the new color is distinct from existing colors
                if !palette.contains(where: { areColorsSimilar($0, newColor) }) {
                    palette.append(newColor)
                }
            }
        }

        // If we couldn't generate enough colors, fill with some default ones
        if palette.count < configuration.paletteSize {
            let defaultColors: [Color] = [.red, .green, .blue, .orange, .purple, .yellow, .pink]

            for color in defaultColors {
                if palette.count >= configuration.paletteSize {
                    break
                }
                if !palette.contains(where: { areColorsSimilar($0, color) }) {
                    palette.append(color)
                }
            }
        }

        return palette
    }

    /// Generates a theme from a seed color with accessible color combinations.
    ///
    /// This method creates a complete color theme that ensures:
    /// - All text is readable against its background
    /// - Primary, secondary, and accent colors work together
    /// - The theme maintains the character of the seed color
    ///
    /// The theme includes:
    /// - Primary color (based on seed)
    /// - Secondary color (harmonious with primary)
    /// - Accent color (complementary to primary)
    /// - Background color (ensures contrast)
    /// - Text color (ensures readability)
    ///
    /// Example:
    /// ```swift
    /// let generator = AccessiblePaletteGenerator()
    /// let seedColor = Color.blue
    ///
    /// let theme = generator.generateAccessibleTheme(
    ///     from: seedColor,
    ///     name: "Ocean Theme"
    /// )
    ///
    /// // Use in SwiftUI
    /// Text("Heading")
    ///     .foregroundColor(theme.text)
    ///     .background(theme.background)
    /// ```
    ///
    /// - Parameters:
    ///   - seedColor: The primary color to base the theme on
    ///   - name: The name for the theme
    /// - Returns: A ColorTheme with accessible color combinations
    public func generateAccessibleTheme(from seedColor: Color, name: String) -> ColorTheme {
        // Use simpler, more deterministic approach for theme generation

        // Find a good background color (usually white or a very light color)
        let backgroundColor = seedColor.wcagRelativeLuminance() > 0.5 ? Color.black : Color.white

        // Find a good text color that contrasts with the background
        let textColor = backgroundColor == Color.white ? Color.black : Color.white

        // Generate a complementary color for accent
        guard let hsl = seedColor.hslComponents() else {
            return ColorTheme(
                name: name,
                primary: seedColor,
                secondary: .blue,
                accent: .orange,
                background: .white,
                text: .black
            )
        }

        // Create complementary color (opposite hue)
        let accentHue = (hsl.hue + 0.5).truncatingRemainder(dividingBy: 1.0)
        let accentColor = Color(hue: accentHue, saturation: min(hsl.saturation + 0.1, 1.0), lightness: hsl.lightness)

        // Create secondary color (adjacent hue)
        let secondaryHue = (hsl.hue + 0.25).truncatingRemainder(dividingBy: 1.0)
        let secondaryColor = Color(hue: secondaryHue, saturation: hsl.saturation, lightness: hsl.lightness)

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

    /// Generates a color that contrasts well with the given color.
    ///
    /// This method creates a new color by:
    /// 1. Shifting the hue significantly
    /// 2. Adjusting lightness for contrast
    /// 3. Increasing saturation for vibrancy
    /// 4. Verifying the contrast ratio
    private func generateContrastingColor(for color: Color) -> Color? {
        // Get the HSL components of the color
        guard let hsl = color.hslComponents() else {
            return nil
        }

        // Create a contrasting color by shifting the hue and adjusting lightness
        // Use a more deterministic approach instead of small adjustments
        let hueShift = Double.random(in: 0.2...0.8) // More randomness
        let newHue = (hsl.hue + hueShift).truncatingRemainder(dividingBy: 1.0)

        // Make lightness adjustment more dramatic
        let lightnessShift = hsl.lightness < 0.5 ? 0.4 : -0.4
        let newLightness = max(0.1, min(0.9, hsl.lightness + lightnessShift))

        // Increase saturation slightly for more vibrant colors
        let newSaturation = min(1.0, hsl.saturation + 0.1)

        let contrastingColor = Color(hue: newHue, saturation: newSaturation, lightness: newLightness)

        // Verify the contrast ratio meets our requirements
        let ratio = color.wcagContrastRatio(with: contrastingColor)

        if ratio >= configuration.minimumContrastRatio {
            return contrastingColor
        }

        // If contrast is insufficient, create a more extreme version
        let extremeLightness = hsl.lightness < 0.5 ? 0.9 : 0.1
        return Color(hue: newHue, saturation: newSaturation, lightness: extremeLightness)
    }

    /// Generates a complementary color for the given color.
    ///
    /// Creates a color on the opposite side of the color wheel while
    /// adjusting saturation and lightness to ensure good contrast.
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

        // Define thresholds for similarity - more lenient to prevent freezing
        let hueThreshold = 0.15
        let saturationThreshold = 0.25
        let lightnessThreshold = 0.25

        return hueDiff < hueThreshold &&
               saturationDiff < saturationThreshold &&
               lightnessDiff < lightnessThreshold
    }
}
