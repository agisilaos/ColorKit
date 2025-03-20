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

public extension Color {
    /// Generates an accessible color palette based on this color
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

    /// Generates an accessible theme based on this color
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

    /// Finds a color that contrasts well with this color and meets the specified WCAG level
    /// - Parameter level: The WCAG level to target
    /// - Returns: A color that contrasts well with this color
    func accessibleContrastingColor(for level: WCAGContrastLevel = .AA) -> Color {
        // Get the luminance of this color
        let luminance = self.wcagRelativeLuminance()

        // Start with black or white based on luminance
        let contrastingColor: Color = luminance < 0.5 ? .white : .black

        // Check if the contrast is sufficient
        let ratio = self.wcagContrastRatio(with: contrastingColor)
        if ratio >= level.minimumRatio {
            return contrastingColor
        }

        // If not, try to find a color with sufficient contrast
        // Extract HSL components
        guard let hsl = self.hslComponents() else {
            // Fallback to black or white if HSL conversion fails
            return luminance < 0.5 ? .white : .black
        }

        // Adjust lightness to ensure sufficient contrast
        let targetLightness = luminance < 0.5 ? 0.9 : 0.1

        return Color(
            hue: hsl.hue,
            saturation: hsl.saturation,
            lightness: targetLightness
        )
    }
}
