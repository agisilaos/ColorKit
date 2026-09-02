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
            contrastRatio: StrictWCAGContrast.ratio(foreground: self, background: backgroundColor)
        )
    }
}

private enum StrictWCAGContrast {
    static func ratio(foreground: Color, background: Color) -> Double? {
        guard let foreground = ResolvedSRGBA.resolve(foreground),
              let background = ResolvedSRGBA.resolve(background),
              foreground.isInSRGBGamut,
              background.isInSRGBGamut,
              background.alpha == 1 else { return nil }

        let inverseAlpha = 1 - foreground.alpha
        let composited = (
            red: foreground.red * foreground.alpha + background.red * inverseAlpha,
            green: foreground.green * foreground.alpha + background.green * inverseAlpha,
            blue: foreground.blue * foreground.alpha + background.blue * inverseAlpha
        )
        let foregroundLuminance = luminance(composited)
        let backgroundLuminance = luminance((background.red, background.green, background.blue))
        let lighter = max(foregroundLuminance, backgroundLuminance)
        let darker = min(foregroundLuminance, backgroundLuminance)
        return (lighter + 0.05) / (darker + 0.05)
    }

    private static func luminance(_ components: (red: CGFloat, green: CGFloat, blue: CGFloat)) -> Double {
        let red = linearized(Double(components.red))
        let green = linearized(Double(components.green))
        let blue = linearized(Double(components.blue))
        return 0.2126 * red + 0.7152 * green + 0.0722 * blue
    }

    private static func linearized(_ component: Double) -> Double {
        component <= 0.03928
            ? component / 12.92
            : pow((component + 0.055) / 1.055, 2.4)
    }
}
