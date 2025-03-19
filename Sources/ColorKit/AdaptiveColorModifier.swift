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

public extension View {
    /// Applies adaptive color adjustments for Light/Dark mode with optional brightness adjustment.
    ///
    /// - Parameters:
    ///   - light: The color used in light mode.
    ///   - dark: The color used in dark mode.
    ///   - brightnessAdjustment: An optional adjustment to modify brightness dynamically.
    /// - Returns: A view with adaptive color adjustments applied.
    func adaptiveColor(light: Color, dark: Color, brightnessAdjustment: CGFloat = 0.0) -> some View {
        self.modifier(AdaptiveColorModifier(light: light, dark: dark, brightnessAdjustment: brightnessAdjustment))
    }

    /// Ensures a color meets a minimum contrast ratio against the background.
    ///
    /// - Parameters:
    ///   - base: The base color of the text or foreground element.
    ///   - background: The background color against which contrast is checked.
    ///   - minimumRatio: The minimum contrast ratio required for accessibility (default: 4.5).
    /// - Returns: A view with high-contrast color adjustments applied.
    func highContrastColor(base: Color, background: Color, minimumRatio: CGFloat = 4.5) -> some View {
        self.modifier(HighContrastColorModifier(base: base, background: background, minimumRatio: minimumRatio))
    }

    /// Executes a closure when the system color scheme changes.
    ///
    /// - Parameter action: A closure that receives the new `ColorScheme` value when it changes.
    /// - Returns: A view that executes an action when the system color scheme changes.
    func onAdaptiveColorChange(_ action: @escaping (ColorScheme) -> Void) -> some View {
        self.modifier(AdaptiveColorChangeModifier(action: action))
    }
}

// MARK: - AdaptiveColorModifier

/// A ViewModifier that applies adaptive color adjustments for Light/Dark mode.
private struct AdaptiveColorModifier: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme
    var light: Color
    var dark: Color
    var brightnessAdjustment: CGFloat

    func body(content: Content) -> some View {
        let baseColor = colorScheme == .dark ? dark : light
        let adjustedColor = baseColor.adjustBrightness(by: brightnessAdjustment)
        return content.foregroundColor(adjustedColor)
    }
}

// MARK: - HighContrastColorModifier

/// A ViewModifier that ensures a text or foreground element meets a minimum contrast ratio.
private struct HighContrastColorModifier: ViewModifier {
    var base: Color
    var background: Color
    var minimumRatio: CGFloat

    func body(content: Content) -> some View {
        let adjustedColor = base.adjustedForAccessibility(with: background, minimumRatio: minimumRatio)
        return content.foregroundColor(adjustedColor)
    }
}

// MARK: - AdaptiveColorChangeModifier

/// A ViewModifier that triggers a closure when the system color scheme changes.
private struct AdaptiveColorChangeModifier: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme
    var action: (ColorScheme) -> Void

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
    /// - Parameter amount: The amount by which to adjust brightness. Positive values increase brightness, negative values decrease it.
    /// - Returns: A new `Color` with adjusted brightness.
    func adjustBrightness(by amount: CGFloat) -> Color {
        guard let hsl = self.hslComponents() else { return self }

        let newLightness = min(1, max(0, hsl.lightness + amount))

        return Color(hue: hsl.hue, saturation: hsl.saturation, lightness: newLightness)
    }
}
