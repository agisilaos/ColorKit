import SwiftUI

/// Why a blend could not supply a computed color.
public enum ColorBlendError: Error, Sendable, Equatable {
    /// The amount is nonfinite or outside the inclusive range 0–1.
    case invalidAmount
    /// The independently observed conversion issues; emitted errors contain at least one issue.
    case unavailableInputs(base: ColorConversionIssue?, blend: ColorConversionIssue?)
    /// Blend arithmetic or the resulting color representation contains nonfinite components.
    case nonfiniteResult
}

public extension Color {
    /// Computes a blend, distinguishing successful unchanged colors from unavailable results.
    ///
    /// The receiver is the base operand. Both colors must resolve to fixed RGB or grayscale
    /// components, even at zero amount or zero blend alpha. Capture appearance-dependent colors
    /// explicitly before calling; this operation never selects an ambient appearance.
    ///
    /// The mode operates on nonlinear extended-sRGB channels. Its effect is weighted by
    /// `amount * blend.alpha`, while base alpha is preserved. This is not source-over
    /// compositing. Finite extended output is preserved without additional gamut clipping;
    /// individual modes retain their existing arithmetic and bounds.
    ///
    /// Invalid amount takes precedence over input issues. Otherwise both inputs are diagnosed
    /// independently. A zero contribution returns the resolved base without mode arithmetic.
    /// This operation neither reads nor writes the legacy blend cache.
    ///
    /// - Parameters:
    ///   - color: The blend operand applied to the receiver; operand order matters.
    ///   - mode: The blend-mode arithmetic to apply.
    ///   - amount: A finite strength in 0–1, defaulting to full strength. Invalid values are rejected.
    /// - Returns: A computed color, including a legitimate unchanged result, or the reason it is unavailable.
    func blendResult(with color: Color, mode: BlendMode, amount: CGFloat = 1) -> Result<Color, ColorBlendError> {
        guard amount.isFinite, (0...1).contains(amount) else { return .failure(.invalidAmount) }

        let baseResult = ResolvedSRGBA.resolveResult(self)
        let blendResult = ResolvedSRGBA.resolveResult(color)
        let base: ResolvedSRGBA
        let blend: ResolvedSRGBA
        switch (baseResult, blendResult) {
        case let (.success(resolvedBase), .success(resolvedBlend)):
            base = resolvedBase
            blend = resolvedBlend
        case let (.failure(baseIssue), .failure(blendIssue)):
            return .failure(.unavailableInputs(base: baseIssue, blend: blendIssue))
        case let (.failure(issue), .success):
            return .failure(.unavailableInputs(base: issue, blend: nil))
        case let (.success, .failure(issue)):
            return .failure(.unavailableInputs(base: nil, blend: issue))
        }

        var red = base.red
        var green = base.green
        var blue = base.blue
        if amount != 0, blend.alpha != 0 {
            let mixed = mode.blend(
                base: (base.red, base.green, base.blue),
                blend: (blend.red, blend.green, blend.blue)
            )
            guard [mixed.r, mixed.g, mixed.b].allSatisfy(\.isFinite) else {
                return .failure(.nonfiniteResult)
            }
            red += (mixed.r - base.red) * amount * blend.alpha
            green += (mixed.g - base.green) * amount * blend.alpha
            blue += (mixed.b - base.blue) * amount * blend.alpha
        }
        guard [red, green, blue].allSatisfy(\.isFinite) else { return .failure(.nonfiniteResult) }
        // Construct through Core Graphics to retain finite extended components beyond Float's range.
        guard let space = CGColorSpace(name: CGColorSpace.extendedSRGB),
              let output = CGColor(colorSpace: space, components: [red, green, blue, base.alpha]) else {
            return .failure(.nonfiniteResult)
        }
        return .success(Color(output))
    }
}
