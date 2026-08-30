//
//  Color+AccessiblePalette.swift
//  ColorKit
//
//  Created by Agisilaos Tsaraboulidis on 12.03.25.
//
//  Description:
//  Extends Color with methods to generate accessible color palettes and themes.
//
//  Features:
//  - Generate accessible color palettes from any color
//  - Create accessible themes with proper contrast ratios
//  - Find contrasting colors that meet WCAG guidelines
//
//  License:
//  MIT License. See LICENSE file for details.
//

import SwiftUI

/// Extension providing accessible color palette and theme generation for SwiftUI's Color type.
///
/// This extension adds methods for creating accessible color combinations that meet
/// WCAG guidelines while maintaining visual harmony. Key features include:
///
/// - Generating accessible color palettes
/// - Creating complete accessible themes
/// - Finding contrasting colors that meet WCAG requirements
///
/// Example usage:
/// ```swift
/// let brandColor = Color.blue
///
/// // Generate an accessible palette
/// let palette = brandColor.generateAccessiblePalette(
///     targetLevel: .AA,
///     paletteSize: 5
/// )
///
/// // Create an accessible theme
/// let theme = brandColor.generateAccessibleTheme(
///     name: "Brand Theme"
/// )
///
/// // Find a contrasting color
/// let textColor = brandColor.accessibleContrastingColor()
/// ```
public extension Color {
    /// Generates an accessible color palette based on this color.
    ///
    /// This method creates a palette of colors that all meet WCAG contrast
    /// requirements while maintaining visual harmony with the base color.
    /// The palette is suitable for use in interfaces where accessibility
    /// is a priority.
    ///
    /// Example:
    /// ```swift
    /// let brandColor = Color.blue
    ///
    /// // Generate a palette with custom settings
    /// let palette = brandColor.generateAccessiblePalette(
    ///     targetLevel: .AAA,      // Highest accessibility
    ///     paletteSize: 7,         // 7 colors
    ///     includeBlackAndWhite: true
    /// )
    ///
    /// // Use in SwiftUI
    /// ForEach(palette, id: \.self) { color in
    ///     Rectangle()
    ///         .fill(color)
    ///         .frame(height: 50)
    /// }
    /// ```
    ///
    /// - Parameters:
    ///   - targetLevel: The WCAG level to target (default: .AA)
    ///   - paletteSize: The number of colors to generate (default: 5)
    ///   - includeBlackAndWhite: Whether to include black and white (default: true)
    /// - Returns: An array of colors that form an accessible palette
    func generateAccessiblePalette(
        targetLevel: WCAGContrastLevel = .AA,
        paletteSize: Int = 5,
        includeBlackAndWhite: Bool = true
    ) -> [Color] {
        let configuration = AccessiblePaletteGenerator.Configuration(
            targetLevel: targetLevel,
            paletteSize: paletteSize,
            includeBlackAndWhite: includeBlackAndWhite
        )

        let generator = AccessiblePaletteGenerator(configuration: configuration)
        return generator.generatePalette(from: self)
    }

    /// Generates an accessible theme based on this color.
    ///
    /// This method creates a complete color theme that ensures all color combinations
    /// meet WCAG contrast requirements. The theme includes colors for:
    /// - Primary content
    /// - Secondary content
    /// - Accents
    /// - Backgrounds
    /// - Text
    ///
    /// Example:
    /// ```swift
    /// let brandColor = Color.blue
    ///
    /// // Create a theme with AAA compliance
    /// let theme = brandColor.generateAccessibleTheme(
    ///     name: "High Contrast Theme",
    ///     targetLevel: .AAA
    /// )
    ///
    /// // Use in SwiftUI
    /// VStack {
    ///     Text("Heading")
    ///         .foregroundColor(theme.text)
    ///         .background(theme.primary)
    ///     Button("Action") {
    ///         // Action
    ///     }
    ///     .foregroundColor(theme.text)
    ///     .background(theme.accent)
    /// }
    /// .background(theme.background)
    /// ```
    ///
    /// - Parameters:
    ///   - name: The name for the theme
    ///   - targetLevel: The WCAG level to target (default: .AA)
    /// - Returns: A ColorTheme with accessible color combinations
    func generateAccessibleTheme(
        name: String,
        targetLevel: WCAGContrastLevel = .AA
    ) -> ColorTheme {
        let configuration = AccessiblePaletteGenerator.Configuration(
            targetLevel: targetLevel,
            paletteSize: 7, // Larger palette for theme generation
            includeBlackAndWhite: true
        )

        let generator = AccessiblePaletteGenerator(configuration: configuration)
        return generator.generateAccessibleTheme(from: self, name: name)
    }

    /// Returns the best available contrasting endpoint, either black or white.
    ///
    /// Compares both endpoints using `wcagContrastRatio(with:)` and returns the one
    /// with the higher ratio. Exact ties return black.
    ///
    /// The result is independent of the requested level: the stronger endpoint is
    /// returned even when neither meets the target. In particular, AAA may be
    /// unattainable. Color resolution follows the existing WCAG calculation.
    ///
    /// Example:
    /// ```swift
    /// let backgroundColor = Color.blue
    ///
    /// // Get a contrasting color for text
    /// let textColor = backgroundColor.accessibleContrastingColor(
    ///     for: .AAA  // Highest contrast requirement
    /// )
    ///
    /// // Use in SwiftUI
    /// Text("Accessible Text")
    ///     .foregroundColor(textColor)
    ///     .background(backgroundColor)
    /// ```
    ///
    /// - Parameter level: The desired WCAG level (default: .AA), retained for API
    ///   compatibility. Meeting this level is not guaranteed.
    /// - Returns: Black or white, whichever provides the greater WCAG contrast ratio.
    func accessibleContrastingColor(for level: WCAGContrastLevel = .AA) -> Color {
        let blackRatio = wcagContrastRatio(with: .black)
        let whiteRatio = wcagContrastRatio(with: .white)
        return blackRatio >= whiteRatio ? .black : .white
    }
}
