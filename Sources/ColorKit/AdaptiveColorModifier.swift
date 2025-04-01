//
//  AdaptiveColorModifier.swift
//  ColorKit
//
//  Created by Agisilaos Tsaraboulidis on 10.03.25.
//
//  Description:
//  Provides SwiftUI ViewModifiers for adaptive color handling.
//
//  Features:
//  - `adaptiveColor`: Applies a light or dark color based on system appearance.
//  - `highContrastColor`: Ensures text meets a minimum contrast ratio.
//  - `onAdaptiveColorChange`: Executes an action when the system color scheme changes.
//
//  License:
//  MIT License. See LICENSE file for details.
//
import SwiftUI

/// Extension providing adaptive color modifiers for SwiftUI views.
///
/// This extension adds view modifiers that help create adaptive, accessible color
/// schemes that work well in both light and dark modes while maintaining WCAG
/// compliance. Key features include:
///
/// - Automatic light/dark mode color switching
/// - Contrast ratio enforcement for accessibility
/// - Dynamic brightness adjustments
/// - Color scheme change monitoring
///
/// Example usage:
/// ```swift
/// struct AdaptiveView: View {
///     var body: some View {
///         Text("Hello, World!")
///             // Switch between colors based on mode
///             .adaptiveColor(
///                 light: .blue,
///                 dark: .cyan
///             )
///
///             // Ensure text is readable
///             .highContrastColor(
///                 base: .blue,
///                 background: .white
///             )
///
///             // React to color scheme changes
///             .onAdaptiveColorChange { scheme in
///                 print("Switched to \(scheme) mode")
///             }
///     }
/// }
/// ```
public extension View {
    /// Applies adaptive color adjustments for Light/Dark mode with optional brightness adjustment.
    ///
    /// This modifier automatically switches between two colors based on the system's
    /// appearance setting, with an optional brightness adjustment for fine-tuning.
    ///
    /// Example:
    /// ```swift
    /// Text("Adaptive Text")
    ///     .adaptiveColor(
    ///         light: .blue,      // Color for light mode
    ///         dark: .cyan,       // Color for dark mode
    ///         brightnessAdjustment: 0.1  // Slightly brighter
    ///     )
    ///
    /// Button("Action") {
    ///     // Action here
    /// }
    /// .adaptiveColor(
    ///     light: .indigo,
    ///     dark: .mint
    /// )
    /// ```
    ///
    /// - Parameters:
    ///   - light: The color used in light mode
    ///   - dark: The color used in dark mode
    ///   - brightnessAdjustment: An optional adjustment to modify brightness dynamically
    /// - Returns: A view with adaptive color adjustments applied
    func adaptiveColor(light: Color, dark: Color, brightnessAdjustment: CGFloat = 0.0) -> some View {
        self.modifier(AdaptiveColorModifier(light: light, dark: dark, brightnessAdjustment: brightnessAdjustment))
    }

    /// Ensures a color meets a minimum contrast ratio against the background.
    ///
    /// This modifier automatically adjusts the color to meet WCAG contrast
    /// requirements, ensuring text and UI elements remain readable. It will
    /// attempt to preserve the original color while meeting the contrast
    /// requirements.
    ///
    /// Example:
    /// ```swift
    /// // Ensure text meets WCAG AA standard (4.5:1)
    /// Text("Readable Text")
    ///     .highContrastColor(
    ///         base: .blue,
    ///         background: .white
    ///     )
    ///
    /// // Meet stricter WCAG AAA standard (7:1)
    /// Text("High Contrast Text")
    ///     .highContrastColor(
    ///         base: .purple,
    ///         background: .white,
    ///         minimumRatio: 7.0
    ///     )
    /// ```
    ///
    /// - Parameters:
    ///   - base: The base color of the text or foreground element
    ///   - background: The background color against which contrast is checked
    ///   - minimumRatio: The minimum contrast ratio required for accessibility (default: 4.5)
    /// - Returns: A view with high-contrast color adjustments applied
    func highContrastColor(base: Color, background: Color, minimumRatio: CGFloat = 4.5) -> some View {
        self.modifier(HighContrastColorModifier(base: base, background: background, minimumRatio: minimumRatio))
    }

    /// Executes a closure when the system color scheme changes.
    ///
    /// This modifier allows you to respond to system appearance changes
    /// (light/dark mode) by executing custom logic. It's useful for:
    /// - Updating UI elements
    /// - Adjusting color schemes
    /// - Persisting user preferences
    ///
    /// Example:
    /// ```swift
    /// struct AdaptiveView: View {
    ///     @State private var currentScheme: ColorScheme = .light
    ///
    ///     var body: some View {
    ///         Text("Current mode: \(currentScheme == .dark ? "Dark" : "Light")")
    ///             .onAdaptiveColorChange { newScheme in
    ///                 currentScheme = newScheme
    ///                 updateColors()
    ///             }
    ///     }
    ///
    ///     func updateColors() {
    ///         // Update colors based on new scheme
    ///     }
    /// }
    /// ```
    ///
    /// - Parameter action: A closure that receives the new `ColorScheme` value when it changes
    /// - Returns: A view that executes an action when the system color scheme changes
    func onAdaptiveColorChange(_ action: @escaping (ColorScheme) -> Void) -> some View {
        self.modifier(AdaptiveColorChangeModifier(action: action))
    }
}

/// A ViewModifier that applies adaptive color adjustments for Light/Dark mode.
///
/// This modifier handles the automatic switching between light and dark mode colors,
/// applying optional brightness adjustments to fine-tune the appearance.
///
/// Example:
/// ```swift
/// Text("Hello")
///     .modifier(AdaptiveColorModifier(
///         light: .blue,
///         dark: .cyan,
///         brightnessAdjustment: 0.1
///     ))
/// ```
private struct AdaptiveColorModifier: ViewModifier {
    @Environment(\.colorScheme)
    private var colorScheme

    let light: Color
    let dark: Color
    let brightnessAdjustment: CGFloat

    func body(content: Content) -> some View {
        let baseColor = colorScheme == .dark ? dark : light
        let adjustedColor = baseColor.adjustBrightness(by: brightnessAdjustment)
        return content.foregroundColor(adjustedColor)
    }
}

/// A ViewModifier that ensures a text or foreground element meets a minimum contrast ratio.
///
/// This modifier automatically adjusts colors to meet WCAG accessibility guidelines
/// while attempting to preserve the original color's characteristics.
///
/// Example:
/// ```swift
/// Text("Accessible")
///     .modifier(HighContrastColorModifier(
///         base: .blue,
///         background: .white,
///         minimumRatio: 4.5
///     ))
/// ```
private struct HighContrastColorModifier: ViewModifier {
    let base: Color
    let background: Color
    let minimumRatio: CGFloat

    func body(content: Content) -> some View {
        let adjustedColor = base.adjustedForAccessibility(with: background, minimumRatio: minimumRatio)
        return content.foregroundColor(adjustedColor)
    }
}

/// A ViewModifier that triggers a closure when the system color scheme changes.
///
/// This modifier monitors the system appearance setting and executes a provided
/// closure whenever it changes between light and dark mode.
///
/// Example:
/// ```swift
/// Text("Mode Aware")
///     .modifier(AdaptiveColorChangeModifier { scheme in
///         print("Changed to \(scheme) mode")
///     })
/// ```
private struct AdaptiveColorChangeModifier: ViewModifier {
    @Environment(\.colorScheme)
    private var colorScheme

    let action: (ColorScheme) -> Void

    func body(content: Content) -> some View {
        content.onAppear {
            action(colorScheme)
        }
        .onChange(of: colorScheme) { newScheme in
            action(newScheme)
        }
    }
}

// MARK: - Brightness & Contrast Adjustments

private extension Color {
    /// Adjusts the brightness of a color by a given percentage.
    ///
    /// This method modifies a color's brightness while preserving its hue and
    /// saturation. It's useful for creating subtle variations of a base color
    /// for different UI states or emphasis levels.
    ///
    /// Example:
    /// ```swift
    /// let baseColor = Color.blue
    /// let brighterColor = baseColor.adjustBrightness(by: 0.2)  // 20% brighter
    /// let darkerColor = baseColor.adjustBrightness(by: -0.2)   // 20% darker
    /// ```
    ///
    /// - Parameter amount: The amount by which to adjust brightness. Positive values
    ///                    increase brightness, negative values decrease it.
    /// - Returns: A new `Color` with adjusted brightness.
    func adjustBrightness(by amount: CGFloat) -> Color {
        guard let hsl = self.hslComponents() else { return self }
        let newLightness = min(1, max(0, hsl.lightness + amount))
        return Color(hue: hsl.hue, saturation: hsl.saturation, lightness: newLightness)
    }
}
