import SwiftUI

/// A measured accessibility result for one foreground color against one background.
public struct ColorAccessibilityResult: Sendable {
    /// The relationship between the measured contrast and requested target.
    public enum Status: Sendable {
        /// The measured contrast meets or exceeds the requested target.
        case meetsTarget
        /// The color is measurable but its contrast falls below the requested target.
        case bestEffort
        /// A required contrast or enhancement-distance measurement is unavailable.
        case unavailable
        /// The enhancement budget is nonfinite or outside the inclusive range 0...100.
        case invalidConfiguration
    }

    /// The selected foreground, or the unchanged input when enhancement cannot run.
    public let color: Color

    /// The WCAG level requested by the caller.
    public let targetLevel: WCAGContrastLevel

    /// The measured contrast ratio, or `nil` when measurement is unavailable.
    public let contrastRatio: Double?

    /// The original-to-candidate CIEDE2000 Delta E 00, or `nil` when not measured.
    /// Ordinary contrast assessments do not measure enhancement distance.
    public let perceptualDistance: Double?

    /// The requested enhancement budget, including its raw value when invalid.
    /// `nil` means this is an ordinary assessment without an enhancement budget.
    public let maximumPerceptualDistance: Double?

    /// Whether measured distance is within a valid inclusive budget.
    /// `nil` means no budget applies, the budget is invalid, or distance is unavailable.
    public var isWithinPerceptualDistanceBudget: Bool? {
        guard let maximumPerceptualDistance,
              AccessibilityEnhancer.Configuration.isValidDistanceBudget(maximumPerceptualDistance),
              let perceptualDistance else { return nil }
        return perceptualDistance <= maximumPerceptualDistance
    }

    /// The minimum contrast ratio required by ``targetLevel``.
    public var minimumContrastRatio: Double {
        targetLevel.minimumRatio
    }

    /// Whether the measured contrast meets the requested target.
    public var meetsTarget: Bool {
        status == .meetsTarget
    }

    /// The outcome derived from configuration validity, required measurements, and contrast.
    /// Invalid and unavailable outcomes may retain diagnostic contrast, but never report success.
    public var status: Status {
        if let maximumPerceptualDistance {
            guard AccessibilityEnhancer.Configuration.isValidDistanceBudget(maximumPerceptualDistance)
            else { return .invalidConfiguration }
            guard isWithinPerceptualDistanceBudget == true else { return .unavailable }
        }
        guard let contrastRatio else { return .unavailable }
        return contrastRatio >= minimumContrastRatio ? .meetsTarget : .bestEffort
    }

    init(
        color: Color,
        targetLevel: WCAGContrastLevel,
        contrastRatio: Double?,
        perceptualDistance: Double? = nil,
        maximumPerceptualDistance: Double? = nil
    ) {
        self.color = color
        self.targetLevel = targetLevel
        self.contrastRatio = contrastRatio
        self.perceptualDistance = perceptualDistance
        self.maximumPerceptualDistance = maximumPerceptualDistance
    }
}

public extension Color {
    /// Assesses this foreground color against an explicit background and WCAG target.
    ///
    /// Both colors must resolve to finite, in-gamut sRGB values. The background must
    /// be opaque. A translucent foreground is composited over that background before
    /// measurement. Dynamic colors and translucent backgrounds return an unavailable
    /// result because their contrast depends on context not supplied to this method.
    ///
    /// - Parameters:
    ///   - backgroundColor: The background behind this foreground color.
    ///   - targetLevel: The WCAG contrast level to assess.
    /// - Returns: A result that distinguishes a pass, best effort, and unavailable measurement.
    func accessibilityResult(
        against backgroundColor: Color,
        targetLevel: WCAGContrastLevel = .AA
    ) -> ColorAccessibilityResult {
        ColorAccessibilityResult(
            color: self,
            targetLevel: targetLevel,
            contrastRatio: StrictWCAGContrast.measure(
                foreground: self,
                background: backgroundColor
            ).ratio
        )
    }
}
