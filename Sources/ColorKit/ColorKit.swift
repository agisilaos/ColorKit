// The Swift Programming Language
// https://docs.swift.org/swift-book

import SwiftUI

/// ColorKit is a comprehensive color utility library for SwiftUI.
///
/// ColorKit provides a rich set of tools for working with colors in SwiftUI applications,
/// including:
///
/// - WCAG accessibility compliance checking and enhancement
/// - Professional-grade color blending operations
/// - Color space conversions (RGB, HSL, LAB, CMYK)
/// - Accessible color palette generation
/// - Live color inspection and analysis
/// - Theme management and generation
/// - Gradient creation and manipulation
///
/// Example usage:
/// ```swift
/// // Check WCAG compliance
/// let contrast = Color.blue.contrastRatio(with: .white)
/// let isAccessible = Color.blue.isAccessible(against: .white)
///
/// // Generate accessible palette
/// let palette = ColorKit.ColorInspector.generateAccessiblePalette(
///     from: .blue,
///     targetLevel: .AAA
/// )
///
/// // Create theme
/// let theme = ColorKit.ColorInspector.generateAccessibleTheme(
///     from: .blue,
///     name: "Ocean"
/// )
/// ```
public enum ColorKit {
    /// The current version of ColorKit.
    ///
    /// This version number follows semantic versioning (MAJOR.MINOR.PATCH):
    /// - MAJOR version for incompatible API changes
    /// - MINOR version for added functionality in a backward compatible manner
    /// - PATCH version for backward compatible bug fixes
    public static let version = "1.5.0"

    /// WCAG Compliance Checker namespace.
    ///
    /// This namespace contains tools for checking and ensuring WCAG accessibility
    /// compliance in your color combinations.
    ///
    /// Example:
    /// ```swift
    /// // Show the WCAG demo view
    /// ColorKit.WCAG.demoView()
    /// ```
    public struct WCAG {
        /// Returns a demo view for the WCAG compliance checker.
        ///
        /// This view demonstrates the WCAG compliance checking capabilities
        /// of ColorKit, allowing you to:
        /// - Test color combinations for accessibility
        /// - View contrast ratios
        /// - Check compliance levels (AA, AAA)
        /// - Get suggestions for accessible alternatives
        ///
        /// Example:
        /// ```swift
        /// struct ContentView: View {
        ///     var body: some View {
        ///         ColorKit.WCAG.demoView()
        ///     }
        /// }
        /// ```
        @MainActor
        public static func demoView() -> some View {
            return WCAGDemoView()
        }
    }

    /// Live Color Inspector namespace.
    ///
    /// This namespace provides tools for real-time color inspection,
    /// analysis, and palette generation.
    ///
    /// Example:
    /// ```swift
    /// // Show the color inspector
    /// ColorKit.ColorInspector.demoView()
    ///
    /// // Generate an accessible palette
    /// let palette = ColorKit.ColorInspector.generateAccessiblePalette(
    ///     from: .blue
    /// )
    /// ```
    public struct ColorInspector {
        /// Returns a demo view for the color inspector.
        ///
        /// This view provides a comprehensive color inspection interface that allows you to:
        /// - View color in different color spaces
        /// - Analyze color properties
        /// - Test accessibility
        /// - Generate variations
        ///
        /// Example:
        /// ```swift
        /// struct ContentView: View {
        ///     var body: some View {
        ///         ColorKit.ColorInspector.demoView()
        ///     }
        /// }
        /// ```
        @MainActor
        public static func demoView() -> some View {
            return ColorInspectorDemoView()
        }

        /// Returns a demo view for the accessible palette generator.
        ///
        /// This view demonstrates the palette generation capabilities of ColorKit,
        /// allowing you to:
        /// - Generate accessible color combinations
        /// - Preview palettes in context
        /// - Export palettes for use in your app
        ///
        /// Example:
        /// ```swift
        /// struct ContentView: View {
        ///     var body: some View {
        ///         ColorKit.ColorInspector.accessiblePaletteDemoView()
        ///     }
        /// }
        /// ```
        @MainActor
        public static func accessiblePaletteDemoView() -> some View {
            AccessiblePaletteDemoView()
        }

        /// Generates an accessible color palette based on a seed color.
        ///
        /// This method creates a harmonious color palette that meets WCAG
        /// accessibility guidelines. The generated colors are guaranteed to:
        /// - Meet the specified contrast level when used together
        /// - Maintain visual harmony with the seed color
        /// - Work well in both light and dark modes
        ///
        /// Example:
        /// ```swift
        /// let brandColor = Color.blue
        /// let palette = ColorKit.ColorInspector.generateAccessiblePalette(
        ///     from: brandColor,
        ///     targetLevel: .AAA,
        ///     paletteSize: 7,
        ///     includeBlackAndWhite: true
        /// )
        ///
        /// // Use in SwiftUI
        /// ForEach(palette, id: \.self) { color in
        ///     Rectangle()
        ///         .fill(color)
        /// }
        /// ```
        ///
        /// - Parameters:
        ///   - seedColor: The color to base the palette on
        ///   - targetLevel: The WCAG level to target (default: .AA)
        ///   - paletteSize: The number of colors to generate (default: 5)
        ///   - includeBlackAndWhite: Whether to include black and white (default: true)
        /// - Returns: An array of colors that form an accessible palette
        public static func generateAccessiblePalette(
            from seedColor: Color,
            targetLevel: WCAGContrastLevel = .AA,
            paletteSize: Int = 5,
            includeBlackAndWhite: Bool = true
        ) -> [Color] {
            seedColor.generateAccessiblePalette(
                targetLevel: targetLevel,
                paletteSize: paletteSize,
                includeBlackAndWhite: includeBlackAndWhite
            )
        }

        /// Generates an accessible theme based on a seed color.
        ///
        /// This method creates a complete color theme that meets WCAG
        /// accessibility guidelines. The generated theme includes:
        /// - Primary and secondary colors
        /// - Background colors
        /// - Text colors
        /// - Accent colors
        ///
        /// All color combinations in the theme are guaranteed to meet
        /// the specified WCAG contrast level.
        ///
        /// Example:
        /// ```swift
        /// let brandColor = Color.blue
        /// let theme = ColorKit.ColorInspector.generateAccessibleTheme(
        ///     from: brandColor,
        ///     name: "Ocean",
        ///     targetLevel: .AAA
        /// )
        ///
        /// // Apply theme
        /// ContentView()
        ///     .environmentObject(theme)
        /// ```
        ///
        /// - Parameters:
        ///   - seedColor: The color to base the theme on
        ///   - name: The name for the theme
        ///   - targetLevel: The WCAG level to target (default: .AA)
        /// - Returns: A ColorTheme with accessible color combinations
        public static func generateAccessibleTheme(
            from seedColor: Color,
            name: String,
            targetLevel: WCAGContrastLevel = .AA
        ) -> ColorTheme {
            seedColor.generateAccessibleTheme(
                name: name,
                targetLevel: targetLevel
            )
        }
    }
}
