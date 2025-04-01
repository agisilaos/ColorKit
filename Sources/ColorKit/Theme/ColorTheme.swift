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
///
/// `ColorTheme` provides a structured way to define and manage colors across an application.
/// It organizes colors into semantic roles (primary, secondary, accent, etc.) and ensures
/// consistent color usage throughout the UI.
///
/// Each color role includes multiple variants through `ThemeColorSet`, allowing for:
/// - Base colors for standard usage
/// - Light variants for subtle elements
/// - Dark variants for emphasis
///
/// Example usage:
/// ```swift
/// // Create a theme with individual colors
/// let oceanTheme = ColorTheme(
///     name: "Ocean",
///     primary: .blue,
///     secondary: .cyan,
///     accent: .teal,
///     background: .white,
///     text: .black
/// )
///
/// // Use in SwiftUI views
/// Text("Primary Button")
///     .foregroundColor(oceanTheme.text.base)
///     .background(oceanTheme.primary.base)
///
/// Text("Secondary Text")
///     .foregroundColor(oceanTheme.text.light)
///
/// // Use status colors
/// Text("Success!")
///     .foregroundColor(oceanTheme.status.success)
/// ```
public struct ColorTheme: Equatable, Hashable, Sendable {
    /// The theme's name for identification and display purposes.
    public let name: String

    /// Primary colors used for main UI elements.
    ///
    /// These colors should be used for:
    /// - Main call-to-action buttons
    /// - Key interactive elements
    /// - Primary branding elements
    public let primary: ThemeColorSet

    /// Secondary colors for supporting UI elements.
    ///
    /// These colors should be used for:
    /// - Secondary buttons
    /// - Supporting interface elements
    /// - Alternative interactive elements
    public let secondary: ThemeColorSet

    /// Accent colors for highlights and emphasis.
    ///
    /// These colors should be used for:
    /// - Highlighting selected items
    /// - Drawing attention to specific elements
    /// - Decorative elements
    public let accent: ThemeColorSet

    /// Background colors for different UI layers.
    ///
    /// These colors should be used for:
    /// - Main view backgrounds
    /// - Card backgrounds
    /// - Modal backgrounds
    public let background: ThemeColorSet

    /// Text colors for various content types.
    ///
    /// These colors should be used for:
    /// - Body text
    /// - Headings
    /// - Labels and captions
    public let text: ThemeColorSet

    /// Status colors for feedback and system states.
    ///
    /// These colors provide visual feedback for:
    /// - Success messages and confirmations
    /// - Warning alerts and notifications
    /// - Error states and critical messages
    public let status: StatusColorSet

    /// Creates a new color theme with fully customized color sets.
    ///
    /// This initializer allows complete control over all color variants
    /// in each color set. Use this when you need precise control over
    /// every color in the theme.
    ///
    /// Example:
    /// ```swift
    /// let theme = ColorTheme(
    ///     name: "Custom Theme",
    ///     primary: ThemeColorSet(
    ///         base: .blue,
    ///         light: .blue.opacity(0.8),
    ///         dark: .blue.opacity(1.2)
    ///     ),
    ///     secondary: ThemeColorSet(
    ///         base: .gray,
    ///         light: .gray.opacity(0.8),
    ///         dark: .gray.opacity(1.2)
    ///     ),
    ///     accent: ThemeColorSet(
    ///         base: .purple,
    ///         light: .purple.opacity(0.8),
    ///         dark: .purple.opacity(1.2)
    ///     ),
    ///     background: ThemeColorSet(
    ///         base: .white,
    ///         light: .gray.opacity(0.1),
    ///         dark: .gray.opacity(0.2)
    ///     ),
    ///     text: ThemeColorSet(
    ///         base: .black,
    ///         light: .gray,
    ///         dark: .black
    ///     ),
    ///     status: StatusColorSet(
    ///         success: .green,
    ///         warning: .yellow,
    ///         error: .red
    ///     )
    /// )
    /// ```
    ///
    /// - Parameters:
    ///   - name: The name of the theme
    ///   - primary: Primary color set
    ///   - secondary: Secondary color set
    ///   - accent: Accent color set
    ///   - background: Background color set
    ///   - text: Text color set
    ///   - status: Status color set
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

    /// Creates a new color theme with automatic variant generation.
    ///
    /// This convenience initializer takes base colors and automatically
    /// generates light and dark variants for each color set. It's ideal
    /// when you want to quickly create a theme without manually specifying
    /// every variant.
    ///
    /// Example:
    /// ```swift
    /// // Create a theme with just base colors
    /// let quickTheme = ColorTheme(
    ///     name: "Quick Theme",
    ///     primary: .blue,      // Variants auto-generated
    ///     secondary: .gray,    // Variants auto-generated
    ///     accent: .purple,     // Variants auto-generated
    ///     background: .white,  // Variants auto-generated
    ///     text: .black        // Variants auto-generated
    /// )
    ///
    /// // Access auto-generated variants
    /// let lightPrimary = quickTheme.primary.light
    /// let darkPrimary = quickTheme.primary.dark
    /// ```
    ///
    /// - Parameters:
    ///   - name: The name of the theme
    ///   - primary: Primary base color
    ///   - secondary: Secondary base color
    ///   - accent: Accent base color
    ///   - background: Background base color
    ///   - text: Text base color
    ///   - success: Success status color (defaults to green)
    ///   - warning: Warning status color (defaults to yellow)
    ///   - error: Error status color (defaults to red)
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

/// A set of related colors with different intensities for UI hierarchy.
///
/// `ThemeColorSet` provides a base color along with light and dark variants,
/// allowing for consistent color usage across different emphasis levels in
/// the UI. The variants are designed to work together while maintaining
/// visual harmony.
///
/// Example usage:
/// ```swift
/// // Create manually
/// let blueSet = ThemeColorSet(
///     base: .blue,
///     light: .blue.opacity(0.8),
///     dark: .blue.opacity(1.2)
/// )
///
/// // Or auto-generate variants
/// let autoSet = ThemeColorSet.from(base: .blue)
///
/// // Use in SwiftUI
/// VStack {
///     Text("Strong Emphasis")
///         .foregroundColor(blueSet.dark)
///     Text("Normal Text")
///         .foregroundColor(blueSet.base)
///     Text("Subtle Text")
///         .foregroundColor(blueSet.light)
/// }
/// ```
public struct ThemeColorSet: Equatable, Hashable, Sendable {
    /// The main color for standard usage.
    ///
    /// This color should be used for the default state of UI elements.
    public let base: Color

    /// A lighter variant for subtle or secondary elements.
    ///
    /// This color should be used for:
    /// - Secondary text
    /// - Disabled states
    /// - Background elements
    public let light: Color

    /// A darker variant for emphasis or hover states.
    ///
    /// This color should be used for:
    /// - Hover states
    /// - Active states
    /// - Strong emphasis
    public let dark: Color

    /// Creates a new theme color set with explicit variants.
    ///
    /// Example:
    /// ```swift
    /// let primaryColors = ThemeColorSet(
    ///     base: .blue,
    ///     light: .blue.opacity(0.8),
    ///     dark: .blue.opacity(1.2)
    /// )
    /// ```
    ///
    /// - Parameters:
    ///   - base: The main color
    ///   - light: A lighter variant
    ///   - dark: A darker variant
    public init(base: Color, light: Color, dark: Color) {
        self.base = base
        self.light = light
        self.dark = dark
    }

    /// Creates a theme color set by auto-generating variants from a base color.
    ///
    /// This method automatically creates light and dark variants by adjusting
    /// the HSL components of the base color. The variants are designed to
    /// maintain the color's character while providing clear visual hierarchy.
    ///
    /// Example:
    /// ```swift
    /// let blueSet = ThemeColorSet.from(base: .blue)
    /// print("Light variant is less saturated and lighter")
    /// print("Dark variant is more saturated and darker")
    /// ```
    ///
    /// - Parameter base: The base color to generate variants from
    /// - Returns: A complete theme color set with auto-generated variants
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

/// A collection of colors for different status states in the UI.
///
/// `StatusColorSet` provides a consistent set of colors for communicating
/// system status, feedback, and alerts to users. Each color is semantically
/// linked to a specific type of message or state.
///
/// Example usage:
/// ```swift
/// let statusColors = StatusColorSet(
///     success: .green,
///     warning: .yellow,
///     error: .red
/// )
///
/// // Use in SwiftUI
/// struct StatusMessage: View {
///     let message: String
///     let status: Status
///     let colors: StatusColorSet
///
///     var body: some View {
///         Text(message)
///             .foregroundColor(statusColor)
///     }
///
///     var statusColor: Color {
///         switch status {
///         case .success: return colors.success
///         case .warning: return colors.warning
///         case .error: return colors.error
///         }
///     }
/// }
/// ```
public struct StatusColorSet: Equatable, Hashable, Sendable {
    /// Color for success states and positive feedback.
    ///
    /// Use this color for:
    /// - Successful operations
    /// - Completed tasks
    /// - Positive confirmations
    public let success: Color

    /// Color for warning states and cautionary messages.
    ///
    /// Use this color for:
    /// - Warning messages
    /// - Required attention
    /// - Potential issues
    public let warning: Color

    /// Color for error states and critical messages.
    ///
    /// Use this color for:
    /// - Error messages
    /// - Failed operations
    /// - Critical alerts
    public let error: Color

    /// Creates a new status color set.
    ///
    /// Example:
    /// ```swift
    /// let statusColors = StatusColorSet(
    ///     success: .green,
    ///     warning: .yellow,
    ///     error: .red
    /// )
    /// ```
    ///
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
