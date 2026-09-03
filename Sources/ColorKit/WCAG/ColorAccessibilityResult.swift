import SwiftUI

/// A measured accessibility result for one foreground color against one background.
public struct ColorAccessibilityResult: Sendable {
    /// The relationship between the measured contrast and requested target.
    public enum Status: Sendable {
        /// The measured contrast meets or exceeds the requested target.
        case meetsTarget
        /// The color is measurable but its contrast falls below the requested target.
        case bestEffort
        /// The supplied colors cannot be measured without additional context.
        case unavailable
    }

    /// The foreground candidate that was assessed.
    public let color: Color

    /// The WCAG level requested by the caller.
    public let targetLevel: WCAGContrastLevel

    /// The measured contrast ratio, or `nil` when measurement is unavailable.
    public let contrastRatio: Double?

    /// The minimum contrast ratio required by ``targetLevel``.
    public var minimumContrastRatio: Double {
        targetLevel.minimumRatio
    }

    /// Whether the measured contrast meets the requested target.
    public var meetsTarget: Bool {
        status == .meetsTarget
    }

    /// The result status derived from the ratio and requested target.
    public var status: Status {
        guard let contrastRatio else { return .unavailable }
        return contrastRatio >= minimumContrastRatio ? .meetsTarget : .bestEffort
    }

    init(color: Color, targetLevel: WCAGContrastLevel, contrastRatio: Double?) {
        self.color = color
        self.targetLevel = targetLevel
        self.contrastRatio = contrastRatio
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
