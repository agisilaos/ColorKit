import ColorKit
import SwiftUI

// Ordinary nonisolated public client; retain the released method-reference shapes.
func componentResultsClient(_ color: Color) {
    let typed: () -> ColorComponentConversionResults = color.componentConversionResults
    let inferred = color.componentConversionResults
    let unbound: (Color) -> () -> ColorComponentConversionResults = Color.componentConversionResults
    let result = typed()
    requireSendable(result)
    _ = inferred()
    _ = unbound(color)()

    // Consume every representation independently, even when another is unavailable.
    consume(result.srgba) { (v: SRGBAComponents) in _ = (v.red, v.green, v.blue, v.alpha) }
    consume(result.hsl) { (v: HSLComponents) in _ = (v.hue, v.saturation, v.lightness) }
    consume(result.hsb) { (v: HSBComponents) in _ = (v.hue, v.saturation, v.brightness) }
    consume(result.cmyk) { (v: CMYKComponents) in _ = (v.cyan, v.magenta, v.yellow, v.key) }
    consume(result.xyz) { (v: XYZComponents) in _ = (v.x, v.y, v.z) }
    consume(result.lab) { (v: LABComponents) in _ = (v.lightness, v.a, v.b) }
    consume(result.hex) { (v: String) in _ = v }
}

private func requireSendable<Value: Sendable>(_ value: Value) {}

private func consume<Value: Sendable & Equatable>(
    _ result: Result<Value, ColorConversionIssue>, success: (Value) -> Void
) {
    requireSendable(result)
    _ = result == result
    switch result {
    case .success(let value): success(value)
    case .failure(let issue):
        // No default: protect exhaustive handling of every released issue.
        switch issue {
        case .unresolvedInput, .unsupportedColorModel, .invalidComponents,
             .colorSpaceConversionFailed, .outOfSRGBGamut, .nonfiniteResult:
            break
        }
    }
}

func componentConversionWorkflows() {
    // Compile-only: sRGB successes and Display P3 partial availability.
    componentResultsClient(Color(.sRGB, red: 0.2, green: 0.4, blue: 0.6, opacity: 0.5))
    componentResultsClient(Color(.displayP3, red: 1, green: 0, blue: 0))
}
