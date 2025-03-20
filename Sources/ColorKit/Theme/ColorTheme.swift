//
//  ColorTheme.swift
//  ColorKit
//
//  Created by Agisilaos Tsaraboulidis on 11.03.25.
//
//  Description:
//  Defines the core theme structure for ColorKit's theming system.
//
//  Features:
//  - Defines a complete color theme with semantic color roles
//  - Provides color sets for different UI elements
//  - Supports auto-generation of color variants
//
//  License:
//  MIT License. See LICENSE file for details.
//

import SwiftUI

/// A complete color theme that defines semantic colors for an application.
@available(iOS 14.0, macOS 11.0, *)
public struct ColorTheme: Equatable, Hashable, Sendable {
    /// The theme's name for identification
    public let name: String

    /// Primary colors used for main UI elements
    public let primary: ThemeColorSet

    /// Secondary colors for supporting UI elements
    public let secondary: ThemeColorSet

    /// Accent colors for highlights and emphasis
    public let accent: ThemeColorSet

    /// Background colors for different UI layers
    public let background: ThemeColorSet

    /// Text colors for various content types
    public let text: ThemeColorSet

    /// Status colors for feedback (success, warning, error)
    public let status: StatusColorSet

    /// Creates a new color theme with all color sets
    /// - Parameters:
    ///   - name: The name of the theme
    ///   - primary: Primary colors
    ///   - secondary: Secondary colors
    ///   - accent: Accent colors
    ///   - background: Background colors
    ///   - text: Text colors
    ///   - status: Status colors
    public init(
        name: String,
        primary: ThemeColorSet,
        secondary: ThemeColorSet,
        accent: ThemeColorSet,
        background: ThemeColorSet,
        text: ThemeColorSet,
        status: StatusColorSet
    ) {
        self.name = name
        self.primary = primary
        self.secondary = secondary
        self.accent = accent
        self.background = background
        self.text = text
        self.status = status
    }

    /// Creates a new color theme with default values that can be overridden
    /// - Parameters:
    ///   - name: The name of the theme
    ///   - primary: Primary color (with variants auto-generated)
    ///   - secondary: Secondary color (with variants auto-generated)
    ///   - accent: Accent color (with variants auto-generated)
    ///   - background: Main background color (with variants auto-generated)
    ///   - text: Main text color (with variants auto-generated)
    ///   - success: Success status color
    ///   - warning: Warning status color
    ///   - error: Error status color
    public init(
        name: String,
        primary: Color,
        secondary: Color,
        accent: Color,
        background: Color,
        text: Color,
        success: Color = .green,
        warning: Color = .yellow,
        error: Color = .red
    ) {
        self.name = name
        self.primary = ThemeColorSet.from(base: primary)
        self.secondary = ThemeColorSet.from(base: secondary)
        self.accent = ThemeColorSet.from(base: accent)
        self.background = ThemeColorSet.from(base: background)
        self.text = ThemeColorSet.from(base: text)
        self.status = StatusColorSet(success: success, warning: warning, error: error)
    }
}

/// A set of related colors with different intensities
@available(iOS 14.0, macOS 11.0, *)
public struct ThemeColorSet: Equatable, Hashable, Sendable {
    /// The main color
    public let base: Color

    /// A lighter variant of the base color
    public let light: Color

    /// A darker variant of the base color
    public let dark: Color

    /// Creates a new theme color set
    /// - Parameters:
    ///   - base: The main color
    ///   - light: A lighter variant
    ///   - dark: A darker variant
    public init(base: Color, light: Color, dark: Color) {
        self.base = base
        self.light = light
        self.dark = dark
    }

    /// Creates a theme color set from a base color, auto-generating light and dark variants
    /// - Parameter base: The base color to generate variants from
    /// - Returns: A complete theme color set
    public static func from(base: Color) -> ThemeColorSet {
        // Extract HSL components
        guard let hsl = base.hslComponents() else {
            // Fallback if HSL conversion fails
            return ThemeColorSet(base: base, light: base.opacity(0.7), dark: base.opacity(1.3))
        }

        // Create lighter variant (increase lightness)
        let lightVariant = Color(
            hue: hsl.hue,
            saturation: max(hsl.saturation - 0.1, 0),
            lightness: min(hsl.lightness + 0.15, 1)
        )

        // Create darker variant (decrease lightness)
        let darkVariant = Color(
            hue: hsl.hue,
            saturation: min(hsl.saturation + 0.1, 1),
            lightness: max(hsl.lightness - 0.15, 0)
        )

        return ThemeColorSet(base: base, light: lightVariant, dark: darkVariant)
    }
}

/// Status colors for feedback
@available(iOS 14.0, macOS 11.0, *)
public struct StatusColorSet: Equatable, Hashable, Sendable {
    /// Color for success states
    public let success: Color

    /// Color for warning states
    public let warning: Color

    /// Color for error states
    public let error: Color

    /// Creates a new status color set
    /// - Parameters:
    ///   - success: Color for success states
    ///   - warning: Color for warning states
    ///   - error: Color for error states
    public init(success: Color, warning: Color, error: Color) {
        self.success = success
        self.warning = warning
        self.error = error
    }
}
