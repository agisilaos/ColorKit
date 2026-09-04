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
/// Strategies are search preferences, not preservation guarantees. Fallbacks may
/// change the named characteristic, but result-bearing APIs never exceed their distance budget.
///
/// - ``preserveHue``: Keeps the color's basic identity
/// - ``preserveSaturation``: Maintains the color's intensity
/// - ``preserveLightness``: Keeps the perceived brightness
/// - ``minimumChange``: Prefers the smallest examined perceptual adjustment
///
/// Example:
/// ```swift
/// let strategy = AdjustmentStrategy.preserveHue
/// print(strategy.description) // "Prefers preserving hue..."
/// ```
public enum AdjustmentStrategy: String, CaseIterable, Identifiable {
    /// Prefers preserving hue while adjusting saturation and lightness.
    ///
    /// This strategy is best when maintaining brand colors is important.
    /// It adjusts the color's intensity and brightness while keeping its
    /// basic identity (e.g., "blue" stays "blue").
    case preserveHue

    /// Prefers preserving saturation while adjusting hue and lightness.
    ///
    /// This strategy maintains the color's intensity while allowing its
    /// hue to shift. Useful when the vibrancy of the color is more
    /// important than its specific hue.
    case preserveSaturation

    /// Prefers preserving lightness while adjusting hue and saturation.
    ///
    /// This strategy maintains the perceived brightness of the color
    /// while allowing other properties to change. Useful for maintaining
    /// the visual hierarchy of interface elements.
    case preserveLightness

    /// Prefers the smallest examined change across LAB and hue-fallback candidates.
    ///
    /// Result-bearing enhancement orders eligible candidates by CIEDE2000 distance.
    /// It does not promise a globally optimal color across the continuous color space.
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
            return "Prefers preserving hue while adjusting saturation and lightness"
        case .preserveSaturation:
            return "Prefers preserving saturation while adjusting hue and lightness"
        case .preserveLightness:
            return "Prefers preserving lightness while adjusting hue and saturation"
        case .minimumChange:
            return "Prefers the smallest examined perceptual change that meets the target"
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

        /// The inclusive CIEDE2000 Delta E 00 budget from the original foreground.
        ///
        /// Result-bearing enhancement requires a finite value in `0...100` and
        /// measures D65 LAB with reference weights equal to one. Equality is eligible;
        /// zero preserves the original. If no in-budget candidate passes, the highest-
        /// contrast examined candidate is best effort, never an over-budget fallback.
        ///
        /// Invalid values are stored unchanged and reported as `invalidConfiguration`
        /// by result-bearing APIs. Legacy color-returning APIs continue ignoring this value.
        public let maxPerceptualDistance: Double

        /// Whether to prefer darker adjustments when possible.
        public let preferDarker: Bool

        /// Creates a new configuration for the accessibility enhancer.
        ///
        /// - Parameters:
        ///   - targetLevel: The WCAG level to target (default: .AA)
        ///   - strategy: The adjustment strategy to use (default: .preserveHue)
        ///   - maxPerceptualDistance: The inclusive Delta E 00 limit enforced by result-bearing
        ///     enhancement, finite and in `0...100` (default: 30). Invalid values do not trap or clamp.
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
    /// This compatibility method preserves the original color-returning behavior and ignores the distance budget.
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

        return EnhancementCandidateSearch(configuration: configuration).candidate(
            for: color,
            against: backgroundColor
        ) { candidate in
            candidate.wcagContrastRatio(with: backgroundColor) >= configuration.targetLevel.minimumRatio
        }
    }

    /// Enhances and assesses a color against the configured WCAG target.
    ///
    /// Enforces the inclusive configured Delta E 00 budget. The original is examined
    /// first, then the first passing eligible strategy candidate wins. Minimum-change
    /// candidates are ordered by distance; other strategies retain their existing order.
    /// If none passes, select highest measured contrast, then smallest distance, then
    /// stable examination order. This is best examined effort, not a global optimum.
    ///
    /// The original must be fixed, opaque, and in sRGB gamut; the background must support
    /// strict contrast measurement. Invalid budgets and unavailable measurements return
    /// the original with diagnostic contrast when available, without reporting success.
    ///
    /// - Parameters:
    ///   - color: The foreground color to enhance.
    ///   - backgroundColor: The background against which the candidate is assessed.
    /// - Returns: The selected candidate and its measured outcome.
    public func enhanceColorResult(
        _ color: Color,
        against backgroundColor: Color
    ) -> ColorAccessibilityResult {
        BudgetedEnhancement(configuration: configuration).result(for: color, against: backgroundColor)
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

    /// Suggests in-budget variants with measured outcomes, retaining best-effort entries.
    ///
    /// Order is hue, saturation, lightness, minimum change, then the configured strategy
    /// with the opposite preference when needed. Pairwise Delta E 00 below 5 is a duplicate;
    /// equality is distinct. Each budget is measured from the original, not another variant.
    /// A positive request with invalid configuration or unavailable inputs returns one
    /// diagnostic result. Nonpositive counts return no results before validating configuration.
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
        guard requestedCount > 0 else { return [] }
        var variants: [ColorAccessibilityResult] = []
        let strategies = AdjustmentStrategy.allCases.map { ($0, configuration.preferDarker) }
            + [(configuration.strategy, !configuration.preferDarker)]
        for (strategy, preferDarker) in strategies {
            let result = BudgetedEnhancement(configuration: Configuration(
                targetLevel: configuration.targetLevel,
                strategy: strategy,
                maxPerceptualDistance: configuration.maxPerceptualDistance,
                preferDarker: preferDarker
            )).result(for: color, against: backgroundColor)
            if result.status == .invalidConfiguration || result.status == .unavailable {
                return [result]
            }
            let isDistinct = variants.allSatisfy { existing in
                guard case let .available(difference) = existing.color.comparisonResult(with: result.color)
                else { return false }
                return difference.perceptualDifference >= 5
            }
            if isDistinct { variants.append(result) }
            if variants.count == requestedCount { break }
        }
        return variants
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
    ///   - maxPerceptualDistance: The inclusive Delta E 00 budget, finite in `0...100` (default: 30).
    /// - Returns: The selected candidate and its measured outcome.
    func enhancementResult(
        with backgroundColor: Color,
        targetLevel: WCAGContrastLevel = .AA,
        strategy: AdjustmentStrategy = .preserveHue,
        maxPerceptualDistance: Double = 30
    ) -> ColorAccessibilityResult {
        let enhancer = AccessibilityEnhancer(configuration: AccessibilityEnhancer.Configuration(
            targetLevel: targetLevel,
            strategy: strategy,
            maxPerceptualDistance: maxPerceptualDistance
        ))
        return enhancer.enhanceColorResult(self, against: backgroundColor)
    }

    /// Attempts to enhance this color for a requested accessibility target.
    /// - Parameters:
    ///   - backgroundColor: The background color to check against
    ///   - targetLevel: The WCAG level to target (default: .AA)
    ///   - strategy: The adjustment strategy to use (default: .preserveHue)
    /// - Returns: The selected enhanced color candidate. Use ``enhancementResult(with:targetLevel:strategy:maxPerceptualDistance:)``
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
    ///   ``suggestAccessibleVariantResults(with:targetLevel:count:maxPerceptualDistance:)`` for measured outcomes.
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
    ///   - maxPerceptualDistance: The inclusive Delta E 00 budget from this color (default: 30).
    /// - Returns: Up to `count` candidates with their measured outcomes.
    func suggestAccessibleVariantResults(
        with backgroundColor: Color,
        targetLevel: WCAGContrastLevel = .AA,
        count: Int = 3,
        maxPerceptualDistance: Double = 30
    ) -> [ColorAccessibilityResult] {
        let enhancer = AccessibilityEnhancer(configuration: AccessibilityEnhancer.Configuration(
            targetLevel: targetLevel,
            maxPerceptualDistance: maxPerceptualDistance
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
