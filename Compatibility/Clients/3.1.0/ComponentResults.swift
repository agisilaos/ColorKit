import ColorKit
import SwiftUI

// Compile as an ordinary nonisolated public client, independently of @MainActor examples.
func componentResultsClient(_ color: Color) -> ColorComponentConversionResults {
    let typed: () -> ColorComponentConversionResults = color.componentConversionResults
    let inferred = color.componentConversionResults
    let unbound: (Color) -> () -> ColorComponentConversionResults = Color.componentConversionResults
    let result = typed()
    let _: Result<SRGBAComponents, ColorConversionIssue> = result.srgba
    let _: Result<HSLComponents, ColorConversionIssue> = result.hsl
    let _: Result<HSBComponents, ColorConversionIssue> = result.hsb
    let _: Result<CMYKComponents, ColorConversionIssue> = result.cmyk
    let _: Result<XYZComponents, ColorConversionIssue> = result.xyz
    let _: Result<LABComponents, ColorConversionIssue> = result.lab
    let _: Result<String, ColorConversionIssue> = result.hex
    requireSendable(result)
    _ = unbound(color)()
    _ = describeComponents(result)
    return inferred()
}

private func requireSendable<Value: Sendable>(_ value: Value) {}

// Each representation is consumed independently: a failed Hex conversion must
// not prevent this client from using successful extended sRGBA, XYZ, or LAB.
private func describeComponents(_ result: ColorComponentConversionResults) -> [String] {
    [
        describe(result.srgba) { "\($0.red),\($0.green),\($0.blue),\($0.alpha)" },
        describe(result.hsl) { "\($0.hue),\($0.saturation),\($0.lightness)" },
        describe(result.hsb) { "\($0.hue),\($0.saturation),\($0.brightness)" },
        describe(result.cmyk) { "\($0.cyan),\($0.magenta),\($0.yellow),\($0.key)" },
        describe(result.xyz) { "\($0.x),\($0.y),\($0.z)" },
        describe(result.lab) { "\($0.lightness),\($0.a),\($0.b)" },
        describe(result.hex) { $0 }
    ]
}

// Preserve the released payload conformances and exhaustive Result handling.
private func describe<Value: Sendable & Equatable>(
    _ result: Result<Value, ColorConversionIssue>,
    success: (Value) -> String
) -> String {
    requireSendable(result)
    _ = result == result
    switch result {
    case .success(let value): return success(value)
    case .failure(let issue): return describeIssue(issue)
    }
}

// No default: a new issue case can break a released exhaustive client.
private func describeIssue(_ issue: ColorConversionIssue) -> String {
    switch issue {
    case .unresolvedInput: "unresolved input"
    case .unsupportedColorModel: "unsupported color model"
    case .invalidComponents: "invalid components"
    case .colorSpaceConversionFailed: "color space conversion failed"
    case .outOfSRGBGamut: "outside sRGB"
    case .nonfiniteResult: "nonfinite result"
    }
}

func componentConversionWorkflows() -> [[String]] {
    // Ordinary sRGB succeeds in all seven representations. Display P3 red can
    // retain sRGBA/XYZ/LAB while bounded HSL/HSB/CMYK/Hex are unavailable.
    // These are compile-only workflows; runtime assertions live in the test suite.
    let ordinary = Color(.sRGB, red: 0.2, green: 0.4, blue: 0.6, opacity: 0.5)
    let extended = Color(.displayP3, red: 1, green: 0, blue: 0)
    return [ordinary, extended].map { describeComponents(componentResultsClient($0)) }
}
