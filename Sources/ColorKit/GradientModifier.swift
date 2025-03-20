//
//  GradientModifier.swift
//  ColorKit
//
//  Created by Agisilaos Tsaraboulidis on 11.03.25.
//
//  Description:
//  Provides SwiftUI ViewModifiers for applying gradients to views.
//
//  Features:
//  - Apply linear, complementary, analogous, triadic, and monochromatic gradients to views
//  - Customize gradient direction, color space, and steps
//  - Easily create gradient backgrounds, fills, and strokes
//
//  License:
//  MIT License. See LICENSE file for details.
//

import SwiftUI

// MARK: - Public View Extensions
public extension View {
    /// Applies a linear gradient background between two colors.
    ///
    /// - Parameters:
    ///   - startColor: The starting color of the gradient.
    ///   - endColor: The ending color of the gradient.
    ///   - direction: The direction of the gradient.
    ///   - colorSpace: The color space in which to perform the interpolation.
    ///   - steps: The number of color steps to generate.
    /// - Returns: A view with a linear gradient background.
    func linearGradientBackground(
        from startColor: Color,
        to endColor: Color,
        direction: GradientDirection = .topLeadingToBottomTrailing,
        in colorSpace: GradientColorSpace = .rgb,
        steps: Int = 10
    ) -> some View {
        self.modifier(LinearGradientModifier(
            startColor: startColor,
            endColor: endColor,
            direction: direction,
            colorSpace: colorSpace,
            steps: steps
        ))
    }

    /// Applies a complementary gradient background.
    ///
    /// - Parameters:
    ///   - baseColor: The base color from which to generate the complementary gradient.
    ///   - direction: The direction of the gradient.
    ///   - colorSpace: The color space in which to perform the interpolation.
    ///   - steps: The number of color steps to generate.
    /// - Returns: A view with a complementary gradient background.
    func complementaryGradientBackground(
        from baseColor: Color,
        direction: GradientDirection = .topLeadingToBottomTrailing,
        in colorSpace: GradientColorSpace = .hsl,
        steps: Int = 10
    ) -> some View {
        self.modifier(ComplementaryGradientModifier(
            baseColor: baseColor,
            direction: direction,
            colorSpace: colorSpace,
            steps: steps
        ))
    }

    /// Applies an analogous gradient background.
    ///
    /// - Parameters:
    ///   - baseColor: The base color from which to generate the analogous gradient.
    ///   - direction: The direction of the gradient.
    ///   - angle: The angle on the color wheel to span (default: 30° or 0.0833 in normalized hue).
    ///   - colorSpace: The color space in which to perform the interpolation.
    ///   - steps: The number of color steps to generate.
    /// - Returns: A view with an analogous gradient background.
    func analogousGradientBackground(
        from baseColor: Color,
        direction: GradientDirection = .topLeadingToBottomTrailing,
        angle: CGFloat = 0.0833,
        in colorSpace: GradientColorSpace = .hsl,
        steps: Int = 10
    ) -> some View {
        self.modifier(AnalogousGradientModifier(
            baseColor: baseColor,
            direction: direction,
            angle: angle,
            colorSpace: colorSpace,
            steps: steps
        ))
    }

    /// Applies a triadic gradient background.
    ///
    /// - Parameters:
    ///   - baseColor: The base color from which to generate the triadic gradient.
    ///   - direction: The direction of the gradient.
    ///   - colorSpace: The color space in which to perform the interpolation.
    ///   - steps: The number of color steps to generate for each segment.
    /// - Returns: A view with a triadic gradient background.
    func triadicGradientBackground(
        from baseColor: Color,
        direction: GradientDirection = .topLeadingToBottomTrailing,
        in colorSpace: GradientColorSpace = .hsl,
        steps: Int = 5
    ) -> some View {
        self.modifier(TriadicGradientModifier(
            baseColor: baseColor,
            direction: direction,
            colorSpace: colorSpace,
            steps: steps
        ))
    }

    /// Applies a monochromatic gradient background.
    ///
    /// - Parameters:
    ///   - baseColor: The base color from which to generate the monochromatic gradient.
    ///   - direction: The direction of the gradient.
    ///   - lightnessRange: The range of lightness values to span.
    ///   - steps: The number of color steps to generate.
    /// - Returns: A view with a monochromatic gradient background.
    func monochromaticGradientBackground(
        from baseColor: Color,
        direction: GradientDirection = .topToBottom,
        lightnessRange: ClosedRange<CGFloat> = 0.1...0.9,
        steps: Int = 10
    ) -> some View {
        self.modifier(MonochromaticGradientModifier(
            baseColor: baseColor,
            direction: direction,
            lightnessRange: lightnessRange,
            steps: steps
        ))
    }
}

// MARK: - Gradient Direction
/// Defines the direction for a gradient.
public enum GradientDirection {
    /// Top to bottom gradient.
    case topToBottom

    /// Bottom to top gradient.
    case bottomToTop

    /// Leading to trailing gradient (left to right in LTR languages).
    case leadingToTrailing

    /// Trailing to leading gradient (right to left in LTR languages).
    case trailingToLeading

    /// Top leading to bottom trailing gradient (diagonal).
    case topLeadingToBottomTrailing

    /// Bottom trailing to top leading gradient (diagonal).
    case bottomTrailingToTopLeading

    /// Top trailing to bottom leading gradient (diagonal).
    case topTrailingToBottomLeading

    /// Bottom leading to top trailing gradient (diagonal).
    case bottomLeadingToTopTrailing

    /// Returns the start and end points for the gradient.
    var points: (start: UnitPoint, end: UnitPoint) {
        switch self {
        case .topToBottom:
            return (UnitPoint.top, UnitPoint.bottom)
        case .bottomToTop:
            return (UnitPoint.bottom, UnitPoint.top)
        case .leadingToTrailing:
            return (UnitPoint.leading, UnitPoint.trailing)
        case .trailingToLeading:
            return (UnitPoint.trailing, UnitPoint.leading)
        case .topLeadingToBottomTrailing:
            return (UnitPoint.topLeading, UnitPoint.bottomTrailing)
        case .bottomTrailingToTopLeading:
            return (UnitPoint.bottomTrailing, UnitPoint.topLeading)
        case .topTrailingToBottomLeading:
            return (UnitPoint.topTrailing, UnitPoint.bottomLeading)
        case .bottomLeadingToTopTrailing:
            return (UnitPoint.bottomLeading, UnitPoint.topTrailing)
        }
    }
}

// MARK: - Gradient Modifiers
/// A ViewModifier that applies a linear gradient background.
private struct LinearGradientModifier: ViewModifier {
    var startColor: Color
    var endColor: Color
    var direction: GradientDirection
    var colorSpace: GradientColorSpace
    var steps: Int

    func body(content: Content) -> some View {
        let colors = startColor.linearGradient(to: endColor, steps: steps, in: colorSpace)
        let points = direction.points

        return content
            .background(
                LinearGradient(
                    colors: colors,
                    startPoint: points.start,
                    endPoint: points.end
                )
            )
    }
}

/// A ViewModifier that applies a complementary gradient background.
private struct ComplementaryGradientModifier: ViewModifier {
    var baseColor: Color
    var direction: GradientDirection
    var colorSpace: GradientColorSpace
    var steps: Int

    func body(content: Content) -> some View {
        let colors = baseColor.complementaryGradient(steps: steps, in: colorSpace)
        let points = direction.points

        return content
            .background(
                LinearGradient(
                    colors: colors,
                    startPoint: points.start,
                    endPoint: points.end
                )
            )
    }
}

/// A ViewModifier that applies an analogous gradient background.
private struct AnalogousGradientModifier: ViewModifier {
    var baseColor: Color
    var direction: GradientDirection
    var angle: CGFloat
    var colorSpace: GradientColorSpace
    var steps: Int

    func body(content: Content) -> some View {
        let colors = baseColor.analogousGradient(steps: steps, angle: angle, in: colorSpace)
        let points = direction.points

        return content
            .background(
                LinearGradient(
                    colors: colors,
                    startPoint: points.start,
                    endPoint: points.end
                )
            )
    }
}

/// A ViewModifier that applies a triadic gradient background.
private struct TriadicGradientModifier: ViewModifier {
    var baseColor: Color
    var direction: GradientDirection
    var colorSpace: GradientColorSpace
    var steps: Int

    func body(content: Content) -> some View {
        let colors = baseColor.triadicGradient(steps: steps, in: colorSpace)
        let points = direction.points

        return content
            .background(
                LinearGradient(
                    colors: colors,
                    startPoint: points.start,
                    endPoint: points.end
                )
            )
    }
}

/// A ViewModifier that applies a monochromatic gradient background.
private struct MonochromaticGradientModifier: ViewModifier {
    var baseColor: Color
    var direction: GradientDirection
    var lightnessRange: ClosedRange<CGFloat>
    var steps: Int

    func body(content: Content) -> some View {
        let colors = baseColor.monochromaticGradient(steps: steps, lightnessRange: lightnessRange)
        let points = direction.points

        return content
            .background(
                LinearGradient(
                    colors: colors,
                    startPoint: points.start,
                    endPoint: points.end
                )
            )
    }
}
