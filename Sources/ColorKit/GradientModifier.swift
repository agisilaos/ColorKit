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

/// A collection of SwiftUI view modifiers for applying sophisticated gradients to views.
///
/// GradientModifier provides a rich set of gradient types including:
/// - Linear gradients between two colors
/// - Complementary gradients based on color theory
/// - Analogous gradients for harmonious color transitions
/// - Triadic gradients for vibrant color combinations
/// - Monochromatic gradients for subtle variations
///
/// Example usage:
/// ```swift
/// struct GradientExample: View {
///     var body: some View {
///         VStack {
///             // Simple linear gradient
///             Text("Linear Gradient")
///                 .linearGradientBackground(from: .blue, to: .purple)
///
///             // Complementary gradient
///             Text("Complementary")
///                 .complementaryGradientBackground(from: .blue)
///
///             // Analogous gradient
///             Text("Analogous")
///                 .analogousGradientBackground(from: .blue)
///         }
///     }
/// }
/// ```
///
/// All gradients support customization of:
/// - Direction (8 different orientations)
/// - Color space (RGB, HSL, LAB)
/// - Number of interpolation steps
/// - Additional parameters specific to each gradient type
public extension View {
    /// Applies a linear gradient background between two colors.
    ///
    /// A linear gradient creates a smooth transition between two colors along a straight line.
    /// The transition can be customized by specifying the color space and number of interpolation steps.
    ///
    /// Example:
    /// ```swift
    /// Text("Gradient Text")
    ///     .linearGradientBackground(
    ///         from: .blue,
    ///         to: .purple,
    ///         direction: .topToBottom,
    ///         in: .hsl,
    ///         steps: 10
    ///     )
    /// ```
    ///
    /// - Parameters:
    ///   - startColor: The starting color of the gradient.
    ///   - endColor: The ending color of the gradient.
    ///   - direction: The direction of the gradient (default: .topLeadingToBottomTrailing).
    ///   - colorSpace: The color space in which to perform the interpolation (default: .rgb).
    ///   - steps: The number of color steps to generate (default: 10).
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
    /// Creates a gradient using colors that are opposite each other on the color wheel.
    /// This creates high-contrast, visually striking gradients that work well for
    /// highlighting important content.
    ///
    /// Example:
    /// ```swift
    /// Button("Action") {
    ///     // Action here
    /// }
    /// .complementaryGradientBackground(
    ///     from: .blue,
    ///     direction: .leadingToTrailing,
    ///     in: .hsl
    /// )
    /// ```
    ///
    /// - Parameters:
    ///   - baseColor: The base color from which to generate the complementary gradient.
    ///   - direction: The direction of the gradient (default: .topLeadingToBottomTrailing).
    ///   - colorSpace: The color space in which to perform the interpolation (default: .hsl).
    ///   - steps: The number of color steps to generate (default: 10).
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
    /// Creates a gradient using colors that are adjacent on the color wheel.
    /// Analogous gradients create harmonious, natural-looking color transitions
    /// that are pleasing to the eye.
    ///
    /// Example:
    /// ```swift
    /// Rectangle()
    ///     .analogousGradientBackground(
    ///         from: .blue,
    ///         angle: 0.1, // Wider spread between colors
    ///         in: .hsl,
    ///         steps: 15
    ///     )
    ///     .frame(height: 200)
    /// ```
    ///
    /// - Parameters:
    ///   - baseColor: The base color from which to generate the analogous gradient.
    ///   - direction: The direction of the gradient (default: .topLeadingToBottomTrailing).
    ///   - angle: The angle on the color wheel to span (default: 30° or 0.0833 in normalized hue).
    ///   - colorSpace: The color space in which to perform the interpolation (default: .hsl).
    ///   - steps: The number of color steps to generate (default: 10).
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
    /// Creates a gradient using three colors evenly spaced around the color wheel.
    /// Triadic color schemes are vibrant and balanced, even when using muted hues.
    ///
    /// Example:
    /// ```swift
    /// Circle()
    ///     .triadicGradientBackground(
    ///         from: .blue,
    ///         direction: .topToBottom,
    ///         in: .hsl,
    ///         steps: 7
    ///     )
    ///     .frame(width: 200, height: 200)
    /// ```
    ///
    /// - Parameters:
    ///   - baseColor: The base color from which to generate the triadic gradient.
    ///   - direction: The direction of the gradient (default: .topLeadingToBottomTrailing).
    ///   - colorSpace: The color space in which to perform the interpolation (default: .hsl).
    ///   - steps: The number of color steps to generate for each segment (default: 5).
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
    /// Creates a gradient using variations of a single color by adjusting its lightness.
    /// Monochromatic gradients are subtle and professional, perfect for backgrounds
    /// and non-distracting UI elements.
    ///
    /// Example:
    /// ```swift
    /// VStack {
    ///     Text("Header")
    ///         .monochromaticGradientBackground(
    ///             from: .blue,
    ///             lightnessRange: 0.3...0.7,
    ///             steps: 8
    ///         )
    /// }
    /// ```
    ///
    /// - Parameters:
    ///   - baseColor: The base color from which to generate the monochromatic gradient.
    ///   - direction: The direction of the gradient (default: .topToBottom).
    ///   - lightnessRange: The range of lightness values to span (default: 0.1...0.9).
    ///   - steps: The number of color steps to generate (default: 10).
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
/// Defines the direction in which gradients are applied to views.
///
/// GradientDirection provides 8 standard orientations for gradients:
/// - Diagonal directions (top-leading to bottom-trailing, etc.)
/// - Vertical directions (top to bottom)
/// - Horizontal directions (leading to trailing)
///
/// Example:
/// ```swift
/// // Apply gradient in different directions
/// Text("Diagonal")
///     .linearGradientBackground(
///         from: .blue,
///         to: .purple,
///         direction: .topLeadingToBottomTrailing
///     )
///
/// Text("Vertical")
///     .linearGradientBackground(
///         from: .blue,
///         to: .purple,
///         direction: .topToBottom
///     )
///
/// Text("Horizontal")
///     .linearGradientBackground(
///         from: .blue,
///         to: .purple,
///         direction: .leadingToTrailing
///     )
/// ```
public enum GradientDirection {
    /// Gradient flows from top-leading to bottom-trailing corner
    case topLeadingToBottomTrailing

    /// Gradient flows from top-trailing to bottom-leading corner
    case topTrailingToBottomLeading

    /// Gradient flows from bottom-leading to top-trailing corner
    case bottomLeadingToTopTrailing

    /// Gradient flows from bottom-trailing to top-leading corner
    case bottomTrailingToTopLeading

    /// Gradient flows from top to bottom
    case topToBottom

    /// Gradient flows from bottom to top
    case bottomToTop

    /// Gradient flows from leading to trailing edge
    case leadingToTrailing

    /// Gradient flows from trailing to leading edge
    case trailingToLeading

    /// Returns the start and end points for the gradient.
    ///
    /// These points are used by SwiftUI's LinearGradient to determine
    /// the gradient's orientation.
    ///
    /// - Returns: A tuple containing the start and end points for the gradient.
    var points: (start: UnitPoint, end: UnitPoint) {
        switch self {
        case .topLeadingToBottomTrailing:
            return (.topLeading, .bottomTrailing)
        case .topTrailingToBottomLeading:
            return (.topTrailing, .bottomLeading)
        case .bottomLeadingToTopTrailing:
            return (.bottomLeading, .topTrailing)
        case .bottomTrailingToTopLeading:
            return (.bottomTrailing, .topLeading)
        case .topToBottom:
            return (.top, .bottom)
        case .bottomToTop:
            return (.bottom, .top)
        case .leadingToTrailing:
            return (.leading, .trailing)
        case .trailingToLeading:
            return (.trailing, .leading)
        }
    }
}

// MARK: - Gradient Modifiers
/// A view modifier that applies a linear gradient background.
///
/// This modifier creates a smooth transition between two colors along
/// a specified direction. It supports different color spaces and
/// customizable step counts for fine-tuning the gradient appearance.
///
/// Example:
/// ```swift
/// Text("Gradient")
///     .modifier(LinearGradientModifier(
///         startColor: .blue,
///         endColor: .purple,
///         direction: .topToBottom,
///         colorSpace: .hsl,
///         steps: 10
///     ))
/// ```
struct LinearGradientModifier: ViewModifier {
    let startColor: Color
    let endColor: Color
    let direction: GradientDirection
    let colorSpace: GradientColorSpace
    let steps: Int

    func body(content: Content) -> some View {
        content.background(
            LinearGradient(
                colors: startColor.linearGradient(
                    to: endColor,
                    steps: steps,
                    in: colorSpace
                ),
                startPoint: direction.points.start,
                endPoint: direction.points.end
            )
        )
    }
}

/// A view modifier that applies a complementary gradient background.
///
/// This modifier creates a gradient between a color and its complement
/// (opposite on the color wheel). It's useful for creating high-contrast,
/// eye-catching backgrounds.
///
/// Example:
/// ```swift
/// Button(action: {}) {
///     Text("Action")
/// }
/// .modifier(ComplementaryGradientModifier(
///     baseColor: .blue,
///     direction: .leadingToTrailing,
///     colorSpace: .hsl,
///     steps: 10
/// ))
/// ```
struct ComplementaryGradientModifier: ViewModifier {
    let baseColor: Color
    let direction: GradientDirection
    let colorSpace: GradientColorSpace
    let steps: Int

    func body(content: Content) -> some View {
        content.background(
            LinearGradient(
                colors: baseColor.complementaryGradient(
                    steps: steps,
                    in: colorSpace
                ),
                startPoint: direction.points.start,
                endPoint: direction.points.end
            )
        )
    }
}

/// A view modifier that applies an analogous gradient background.
///
/// This modifier creates a gradient using colors adjacent on the color wheel.
/// It produces harmonious, natural-looking transitions that are easy on the eyes.
///
/// Example:
/// ```swift
/// Rectangle()
///     .modifier(AnalogousGradientModifier(
///         baseColor: .blue,
///         direction: .topToBottom,
///         angle: 0.1,
///         colorSpace: .hsl,
///         steps: 15
///     ))
///     .frame(height: 200)
/// ```
struct AnalogousGradientModifier: ViewModifier {
    let baseColor: Color
    let direction: GradientDirection
    let angle: CGFloat
    let colorSpace: GradientColorSpace
    let steps: Int

    func body(content: Content) -> some View {
        content.background(
            LinearGradient(
                colors: baseColor.analogousGradient(
                    steps: steps,
                    angle: angle,
                    in: colorSpace
                ),
                startPoint: direction.points.start,
                endPoint: direction.points.end
            )
        )
    }
}

/// A view modifier that applies a triadic gradient background.
///
/// This modifier creates a gradient using three colors evenly spaced
/// around the color wheel. It produces vibrant, balanced color schemes
/// that work well for dynamic interfaces.
///
/// Example:
/// ```swift
/// Circle()
///     .modifier(TriadicGradientModifier(
///         baseColor: .blue,
///         direction: .topToBottom,
///         colorSpace: .hsl,
///         steps: 7
///     ))
///     .frame(width: 200, height: 200)
/// ```
struct TriadicGradientModifier: ViewModifier {
    let baseColor: Color
    let direction: GradientDirection
    let colorSpace: GradientColorSpace
    let steps: Int

    func body(content: Content) -> some View {
        content.background(
            LinearGradient(
                colors: baseColor.triadicGradient(
                    steps: steps,
                    in: colorSpace
                ),
                startPoint: direction.points.start,
                endPoint: direction.points.end
            )
        )
    }
}

/// A view modifier that applies a monochromatic gradient background.
///
/// This modifier creates a gradient by varying the lightness of a single
/// color. It's perfect for subtle, professional-looking backgrounds and
/// non-distracting UI elements.
///
/// Example:
/// ```swift
/// VStack {
///     Text("Header")
///         .modifier(MonochromaticGradientModifier(
///             baseColor: .blue,
///             direction: .topToBottom,
///             lightnessRange: 0.3...0.7,
///             steps: 8
///         ))
/// }
/// ```
struct MonochromaticGradientModifier: ViewModifier {
    let baseColor: Color
    let direction: GradientDirection
    let lightnessRange: ClosedRange<CGFloat>
    let steps: Int

    func body(content: Content) -> some View {
        content.background(
            LinearGradient(
                colors: baseColor.monochromaticGradient(
                    steps: steps,
                    lightnessRange: lightnessRange
                ),
                startPoint: direction.points.start,
                endPoint: direction.points.end
            )
        )
    }
}
