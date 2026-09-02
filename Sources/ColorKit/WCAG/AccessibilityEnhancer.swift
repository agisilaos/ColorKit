//
//  AccessibilityEnhancer.swift
//  ColorKit
//
//  Created by Agisilaos Tsaraboulidis on 13.03.25.
//
//  Description:
//  Provides intelligent color adjustments for accessibility while preserving brand identity.
//
//  Features:
//  - Smart color adjustments that maintain brand identity
//  - Perceptually uniform adjustments using LAB color space
//  - Multiple adjustment strategies (preserve hue, preserve saturation, etc.)
//  - Harmony-preserving color suggestions
//
//  License:
//  MIT License. See LICENSE file for details.
//

import SwiftUI

/// Defines strategies for adjusting colors to meet accessibility requirements.
///
/// Each strategy represents a different approach to modifying colors while maintaining
/// certain characteristics of the original color:
///
/// - ``preserveHue``: Keeps the color's basic identity
/// - ``preserveSaturation``: Maintains the color's intensity
/// - ``preserveLightness``: Keeps the perceived brightness
/// - ``minimumChange``: Makes the smallest possible adjustment
///
/// Example:
/// ```swift
/// let strategy = AdjustmentStrategy.preserveHue
/// print(strategy.description) // "Maintains the color's hue..."
/// ```
public enum AdjustmentStrategy: String, CaseIterable, Identifiable {
    /// Preserves the hue while adjusting saturation and lightness.
    ///
    /// This strategy is best when maintaining brand colors is important.
    /// It adjusts the color's intensity and brightness while keeping its
    /// basic identity (e.g., "blue" stays "blue").
    case preserveHue

    /// Preserves the saturation while adjusting hue and lightness.
    ///
    /// This strategy maintains the color's intensity while allowing its
    /// hue to shift. Useful when the vibrancy of the color is more
    /// important than its specific hue.
    case preserveSaturation

    /// Preserves the lightness while adjusting hue and saturation.
    ///
    /// This strategy maintains the perceived brightness of the color
    /// while allowing other properties to change. Useful for maintaining
    /// the visual hierarchy of interface elements.
    case preserveLightness

    /// Adjusts all components to find the closest accessible color.
    ///
    /// This strategy makes the smallest possible change to achieve
    /// accessibility requirements. It considers all color properties
    /// and chooses the adjustment that results in the least
    /// perceptual difference.
    case minimumChange

    /// Unique identifier for the strategy.
    public var id: String { rawValue }

    /// A human-readable description of the adjustment strategy.
    ///
    /// This property provides a clear explanation of how the strategy
    /// modifies colors to achieve accessibility requirements.
    public var description: String {
        switch self {
        case .preserveHue:
            return "Maintains the color's hue while adjusting saturation and lightness"
        case .preserveSaturation:
            return "Maintains the color's saturation while adjusting hue and lightness"
        case .preserveLightness:
            return "Maintains the color's lightness while adjusting hue and saturation"
        case .minimumChange:
            return "Makes the smallest perceptual change needed to meet accessibility requirements"
        }
    }
}

/// A utility for enhancing colors to meet accessibility requirements while preserving visual identity.
///
/// `AccessibilityEnhancer` provides intelligent color adjustments that balance accessibility
/// needs with brand identity and aesthetic considerations. It offers multiple strategies
/// for color adjustment and can suggest alternative colors that maintain harmony with
/// the original design.
///
/// Example usage:
/// ```swift
/// // Create an enhancer targeting WCAG AA compliance
/// let config = AccessibilityEnhancer.Configuration(
///     targetLevel: .AA,
///     strategy: .preserveHue
/// )
/// let enhancer = AccessibilityEnhancer(configuration: config)
///
/// // Enhance a color against a background
/// let enhancedColor = enhancer.enhanceColor(
///     .blue,
///     against: .white
/// )
///
/// // Get multiple accessible variants
/// let variants = enhancer.suggestAccessibleVariants(
///     for: .blue,
///     against: .white,
///     count: 3
/// )
/// ```
public class AccessibilityEnhancer {
    /// Configuration options for the accessibility enhancement process.
    ///
    /// This structure defines how the enhancer should approach color adjustments,
    /// including the target accessibility level and preferred adjustment strategies.
    ///
    /// Example:
    /// ```swift
    /// let config = AccessibilityEnhancer.Configuration(
    ///     targetLevel: .AA,
    ///     strategy: .preserveHue,
    ///     maxPerceptualDistance: 25,
    ///     preferDarker: true
    /// )
    /// ```
    public struct Configuration {
        /// The WCAG contrast level to achieve.
        public let targetLevel: WCAGContrastLevel

        /// The strategy to use when adjusting colors.
        public let strategy: AdjustmentStrategy

        /// The requested maximum perceptual difference from the original color.
        ///
        /// Values range from 0 to 100, where:
        /// - 0-20: Subtle changes
        /// - 20-40: Moderate changes
        /// - 40+: Significant changes
        ///
        /// This value is retained for source compatibility. Current enhancement
        /// strategies do not enforce it.
        public let maxPerceptualDistance: Double

        /// Whether to prefer darker adjustments when possible.
        public let preferDarker: Bool

        /// Creates a new configuration for the accessibility enhancer.
        ///
        /// - Parameters:
        ///   - targetLevel: The WCAG level to target (default: .AA)
        ///   - strategy: The adjustment strategy to use (default: .preserveHue)
        ///   - maxPerceptualDistance: The requested perceptual-distance limit. Current
        ///     enhancement strategies do not enforce it (default: 30)
        ///   - preferDarker: Whether to prioritize darker adjustments (default: false)
        public init(
            targetLevel: WCAGContrastLevel = .AA,
            strategy: AdjustmentStrategy = .preserveHue,
            maxPerceptualDistance: Double = 30,
            preferDarker: Bool = false
        ) {
            self.targetLevel = targetLevel
            self.strategy = strategy
            self.maxPerceptualDistance = maxPerceptualDistance
            self.preferDarker = preferDarker
        }
    }

    /// The configuration controlling the enhancement behavior.
    public let configuration: Configuration

    /// Creates a new accessibility enhancer with the specified configuration.
    ///
    /// - Parameter configuration: The configuration to use for color enhancements.
    public init(configuration: Configuration = Configuration()) {
        self.configuration = configuration
    }

    /// Attempts to enhance a color for a requested accessibility target.
    ///
    /// This compatibility method preserves the original color-returning behavior.
    /// Use ``enhanceColorResult(_:against:)`` when the caller needs to distinguish
    /// a passing candidate from best effort or unavailable measurement.
    ///
    /// Example:
    /// ```swift
    /// let enhancer = AccessibilityEnhancer()
    /// let textColor = Color.blue
    /// let backgroundColor = Color.white
    ///
    /// // Get an accessible version of the text color
    /// let accessibleColor = enhancer.enhanceColor(
    ///     textColor,
    ///     against: backgroundColor
    /// )
    /// ```
    ///
    /// - Parameters:
    ///   - color: The color to enhance
    ///   - backgroundColor: The background color to check against
    /// - Returns: The selected enhanced color candidate.
    public func enhanceColor(_ color: Color, against backgroundColor: Color) -> Color {
        // Check if the color already meets requirements
        let contrastRatio = color.wcagContrastRatio(with: backgroundColor)
        if contrastRatio >= configuration.targetLevel.minimumRatio {
            return color
        }

        // Apply the appropriate strategy
        switch configuration.strategy {
        case .preserveHue:
            return enhancePreservingHue(color, against: backgroundColor)
        case .preserveSaturation:
            return enhancePreservingSaturation(color, against: backgroundColor)
        case .preserveLightness:
            return enhancePreservingLightness(color, against: backgroundColor)
        case .minimumChange:
            return enhanceWithMinimumChange(color, against: backgroundColor)
        }
    }

    /// Enhances and assesses a color against the configured WCAG target.
    ///
    /// Candidate selection preserves ``enhanceColor(_:against:)`` behavior. The result
    /// reports whether that candidate meets the target, is only the best available
    /// effort, or cannot be measured from the supplied colors.
    ///
    /// - Parameters:
    ///   - color: The foreground color to enhance.
    ///   - backgroundColor: The background against which the candidate is assessed.
    /// - Returns: The selected candidate and its measured outcome.
    public func enhanceColorResult(
        _ color: Color,
        against backgroundColor: Color
    ) -> ColorAccessibilityResult {
        enhanceColor(color, against: backgroundColor).accessibilityResult(
            against: backgroundColor,
            targetLevel: configuration.targetLevel
        )
    }

    /// Suggests multiple color variants that target the configured contrast level.
    ///
    /// This compatibility method generates alternative candidates while maintaining
    /// different aspects of the original color's character. Use
    /// ``suggestAccessibleVariantResults(for:against:count:)`` to inspect the measured
    /// outcome for each candidate.
    ///
    /// Example:
    /// ```swift
    /// let enhancer = AccessibilityEnhancer()
    /// let brandColor = Color.blue
    /// let backgroundColor = Color.white
    ///
    /// // Get three accessible variants
    /// let variants = enhancer.suggestAccessibleVariants(
    ///     for: brandColor,
    ///     against: backgroundColor,
    ///     count: 3
    /// )
    ///
    /// // Use variants in UI
    /// ForEach(variants, id: \.self) { variant in
    ///     Text("Sample Text")
    ///         .foregroundColor(variant)
    /// }
    /// ```
    ///
    /// - Parameters:
    ///   - color: The original color to base variants on
    ///   - backgroundColor: The background color to check against
    ///   - requestedCount: The maximum number of variants to generate. Nonpositive values
    ///     request no variants (default: 3)
    /// - Returns: Up to `count` color candidates targeting the configured level.
    public func suggestAccessibleVariants(
        for color: Color,
        against backgroundColor: Color,
        count requestedCount: Int = 3
    ) -> [Color] {
        guard requestedCount > 0 else { return [] }

        let distinctnessThreshold = 5.0
        var variants: [Color] = []

        // Create variants with different strategies
        let strategies: [AdjustmentStrategy] = [.preserveHue, .preserveSaturation, .preserveLightness, .minimumChange]

        for strategy in strategies {
            let enhancer = AccessibilityEnhancer(configuration: Configuration(
                targetLevel: configuration.targetLevel,
                strategy: strategy,
                maxPerceptualDistance: configuration.maxPerceptualDistance,
                preferDarker: configuration.preferDarker
            ))

            let variant = enhancer.enhanceColor(color, against: backgroundColor)
            if !variants.contains(where: {
                $0.isPerceptuallySimilar(to: variant, threshold: distinctnessThreshold)
            }) {
                variants.append(variant)
            }

            if variants.count >= requestedCount {
                break
            }
        }

        // If needed, try the configured strategy once in the opposite direction.
        if variants.count < requestedCount {
            let enhancer = AccessibilityEnhancer(configuration: Configuration(
                targetLevel: configuration.targetLevel,
                strategy: configuration.strategy,
                maxPerceptualDistance: configuration.maxPerceptualDistance,
                preferDarker: !configuration.preferDarker
            ))

            let variant = enhancer.enhanceColor(color, against: backgroundColor)
            if !variants.contains(where: {
                $0.isPerceptuallySimilar(to: variant, threshold: distinctnessThreshold)
            }) {
                variants.append(variant)
            }
        }

        return Array(variants.prefix(requestedCount))
    }

    /// Suggests variants and assesses each one against the configured WCAG target.
    ///
    /// - Parameters:
    ///   - color: The original color on which to base the variants.
    ///   - backgroundColor: The background against which every variant is assessed.
    ///   - requestedCount: The maximum number of variants to return.
    /// - Returns: Up to `requestedCount` candidates with their measured outcomes.
    public func suggestAccessibleVariantResults(
        for color: Color,
        against backgroundColor: Color,
        count requestedCount: Int = 3
    ) -> [ColorAccessibilityResult] {
        suggestAccessibleVariants(
            for: color,
            against: backgroundColor,
            count: requestedCount
        ).map {
            $0.accessibilityResult(
                against: backgroundColor,
                targetLevel: configuration.targetLevel
            )
        }
    }

    // MARK: - Private Methods

    private func enhancePreservingHue(_ color: Color, against backgroundColor: Color) -> Color {
        guard let hsl = color.hslComponents() else { return color }

        // Start with the original color's HSL values
        let hue = hsl.hue
        var saturation = hsl.saturation
        var lightness = hsl.lightness

        // Determine if we need to make the color lighter or darker
        let bgLuminance = backgroundColor.wcagRelativeLuminance()
        let needDarker = bgLuminance > 0.5

        // If we prefer the opposite of what's needed, adjust saturation more
        let adjustLightness = needDarker == configuration.preferDarker

        // Adjust lightness and saturation in small steps
        let maxSteps = 20
        var currentColor = color

        for _ in 0..<maxSteps {
            if adjustLightness {
                // Adjust lightness
                if needDarker {
                    lightness = max(0, lightness - 0.05)
                } else {
                    lightness = min(1, lightness + 0.05)
                }
            } else {
                // Adjust saturation
                saturation = min(1, saturation + 0.05)
            }

            // Create the adjusted color
            currentColor = Color(hue: hue, saturation: saturation, lightness: lightness)

            // Check if it meets the contrast requirements
            let newRatio = currentColor.wcagContrastRatio(with: backgroundColor)
            if newRatio >= configuration.targetLevel.minimumRatio {
                return currentColor
            }

            // If we've adjusted saturation a lot and still not meeting requirements, adjust lightness too
            if saturation > 0.9 && !adjustLightness {
                if needDarker {
                    lightness = max(0, lightness - 0.05)
                } else {
                    lightness = min(1, lightness + 0.05)
                }
                currentColor = Color(hue: hue, saturation: saturation, lightness: lightness)
            }
        }

        // If we couldn't find a suitable color, fall back to black or white
        return needDarker ? Color.black : Color.white
    }

    private func enhancePreservingSaturation(_ color: Color, against backgroundColor: Color) -> Color {
        guard let hsl = color.hslComponents() else { return color }

        // Start with the original color's HSL values
        var hue = hsl.hue
        let saturation = hsl.saturation
        var lightness = hsl.lightness

        // Determine if we need to make the color lighter or darker
        let bgLuminance = backgroundColor.wcagRelativeLuminance()
        let needDarker = bgLuminance > 0.5

        // Adjust hue and lightness in small steps
        let maxSteps = 20
        var currentColor = color

        for _ in 0..<maxSteps {
            // Adjust lightness
            if needDarker {
                lightness = max(0, lightness - 0.05)
            } else {
                lightness = min(1, lightness + 0.05)
            }

            // Adjust hue slightly
            hue = fmod(hue + 0.02, 1.0)

            // Create the adjusted color
            currentColor = Color(hue: hue, saturation: saturation, lightness: lightness)

            // Check if it meets the contrast requirements
            let newRatio = currentColor.wcagContrastRatio(with: backgroundColor)
            if newRatio >= configuration.targetLevel.minimumRatio {
                return currentColor
            }
        }

        // If we couldn't find a suitable color, fall back to black or white
        return needDarker ? Color.black : Color.white
    }

    private func enhancePreservingLightness(_ color: Color, against backgroundColor: Color) -> Color {
        guard let hsl = color.hslComponents() else { return color }

        // Start with the original color's HSL values
        var hue = hsl.hue
        var saturation = hsl.saturation
        let lightness = hsl.lightness

        // Adjust hue and saturation in small steps
        let maxSteps = 20
        var currentColor = color

        for _ in 0..<maxSteps {
            // Adjust saturation
            saturation = min(1, saturation + 0.05)

            // Adjust hue slightly
            hue = fmod(hue + 0.02, 1.0)

            // Create the adjusted color
            currentColor = Color(hue: hue, saturation: saturation, lightness: lightness)

            // Check if it meets the contrast requirements
            let newRatio = currentColor.wcagContrastRatio(with: backgroundColor)
            if newRatio >= configuration.targetLevel.minimumRatio {
                return currentColor
            }
        }

        // If we couldn't find a suitable color with preserved lightness,
        // we need to adjust lightness as a last resort
        return enhancePreservingHue(color, against: backgroundColor)
    }

    private func enhanceWithMinimumChange(_ color: Color, against backgroundColor: Color) -> Color {
        guard let lab = color.labComponents() else { return color }

        // Start with the original color's LAB values
        let originalL = lab.L
        let originalA = lab.a
        let originalB = lab.b

        // Determine if we need to make the color lighter or darker
        let bgLuminance = backgroundColor.wcagRelativeLuminance()
        let needDarker = bgLuminance > 0.5

        // Adjust LAB values in small steps
        let maxSteps = 30
        var currentColor = color
        var stepSize = 2.0

        for step in 0..<maxSteps {
            // Increase step size as we go to ensure we eventually find a solution
            if step > 10 {
                stepSize = 4.0
            } else if step > 20 {
                stepSize = 8.0
            }

            // Adjust L (lightness) based on whether we need darker or lighter
            let newL = needDarker
                ? max(0, originalL - CGFloat(step) * CGFloat(stepSize))
                : min(100, originalL + CGFloat(step) * CGFloat(stepSize))

            // Make small adjustments to a and b to maintain perceptual similarity
            let newA = originalA + CGFloat(sin(Double(step) * 0.2) * 2)
            let newB = originalB + CGFloat(cos(Double(step) * 0.2) * 2)

            // Create the adjusted color
            currentColor = Color(L: newL, a: newA, b: newB)

            // Check if it meets the contrast requirements
            let newRatio = currentColor.wcagContrastRatio(with: backgroundColor)
            if newRatio >= configuration.targetLevel.minimumRatio {
                return currentColor
            }
        }

        // If we couldn't find a suitable color with minimum change,
        // fall back to a more aggressive strategy
        return enhancePreservingHue(color, against: backgroundColor)
    }
}

// MARK: - Color Extensions

public extension Color {
    /// Enhances and assesses this color against a background and WCAG target.
    ///
    /// - Parameters:
    ///   - backgroundColor: The background against which the candidate is assessed.
    ///   - targetLevel: The WCAG contrast level to target.
    ///   - strategy: The adjustment strategy used to select a candidate.
    /// - Returns: The selected candidate and its measured outcome.
    func enhancementResult(
        with backgroundColor: Color,
        targetLevel: WCAGContrastLevel = .AA,
        strategy: AdjustmentStrategy = .preserveHue
    ) -> ColorAccessibilityResult {
        let enhancer = AccessibilityEnhancer(configuration: AccessibilityEnhancer.Configuration(
            targetLevel: targetLevel,
            strategy: strategy
        ))
        return enhancer.enhanceColorResult(self, against: backgroundColor)
    }

    /// Attempts to enhance this color for a requested accessibility target.
    /// - Parameters:
    ///   - backgroundColor: The background color to check against
    ///   - targetLevel: The WCAG level to target (default: .AA)
    ///   - strategy: The adjustment strategy to use (default: .preserveHue)
    /// - Returns: The selected enhanced color candidate. Use ``enhancementResult(with:targetLevel:strategy:)``
    ///   when the measured outcome is required.
    func enhanced(
        with backgroundColor: Color,
        targetLevel: WCAGContrastLevel = .AA,
        strategy: AdjustmentStrategy = .preserveHue
    ) -> Color {
        let enhancer = AccessibilityEnhancer(configuration: AccessibilityEnhancer.Configuration(
            targetLevel: targetLevel,
            strategy: strategy
        ))
        return enhancer.enhanceColor(self, against: backgroundColor)
    }

    /// Suggests color variants that target a contrast level while maintaining harmony.
    /// - Parameters:
    ///   - backgroundColor: The background color to check against
    ///   - targetLevel: The WCAG level to target (default: .AA)
    ///   - count: The maximum number of variants to suggest. Nonpositive values
    ///     request no variants (default: 3)
    /// - Returns: Up to `count` color candidates. Use
    ///   ``suggestAccessibleVariantResults(with:targetLevel:count:)`` for measured outcomes.
    func suggestAccessibleVariants(
        with backgroundColor: Color,
        targetLevel: WCAGContrastLevel = .AA,
        count: Int = 3
    ) -> [Color] {
        let enhancer = AccessibilityEnhancer(configuration: AccessibilityEnhancer.Configuration(
            targetLevel: targetLevel
        ))
        return enhancer.suggestAccessibleVariants(for: self, against: backgroundColor, count: count)
    }

    /// Suggests color variants with measured outcomes for the requested WCAG target.
    ///
    /// - Parameters:
    ///   - backgroundColor: The background against which every variant is assessed.
    ///   - targetLevel: The WCAG contrast level to target.
    ///   - count: The maximum number of variants to return.
    /// - Returns: Up to `count` candidates with their measured outcomes.
    func suggestAccessibleVariantResults(
        with backgroundColor: Color,
        targetLevel: WCAGContrastLevel = .AA,
        count: Int = 3
    ) -> [ColorAccessibilityResult] {
        let enhancer = AccessibilityEnhancer(configuration: AccessibilityEnhancer.Configuration(
            targetLevel: targetLevel
        ))
        return enhancer.suggestAccessibleVariantResults(
            for: self,
            against: backgroundColor,
            count: count
        )
    }

    /// Determines if this color is perceptually similar to another color
    /// - Parameters:
    ///   - color: The color to compare with
    ///   - threshold: The threshold for similarity (0-100, lower means more similar)
    /// - Returns: Whether the colors are perceptually similar
    func isPerceptuallySimilar(to color: Color, threshold: Double = 10) -> Bool {
        guard let lab1 = self.labComponents(),
              let lab2 = color.labComponents() else {
            return false
        }

        // Calculate Delta E (CIE76 formula)
        let deltaL = lab1.L - lab2.L
        let deltaA = lab1.a - lab2.a
        let deltaB = lab1.b - lab2.b

        let deltaE = sqrt(deltaL * deltaL + deltaA * deltaA + deltaB * deltaB)

        return Double(deltaE) < threshold
    }
}
