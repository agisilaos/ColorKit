import ColorKit
import SwiftUI

// Compile as an ordinary nonisolated public client, independently of @MainActor examples.
func componentResultsClient(_ color: Color) -> ColorComponentConversionResults {
    let typed: () -> ColorComponentConversionResults = color.componentConversionResults
    let inferred = color.componentConversionResults
    let result = typed()
    let _: Result<SRGBAComponents, ColorConversionIssue> = result.srgba
    let _: Result<HSLComponents, ColorConversionIssue> = result.hsl
    let _: Result<HSBComponents, ColorConversionIssue> = result.hsb
    let _: Result<CMYKComponents, ColorConversionIssue> = result.cmyk
    let _: Result<XYZComponents, ColorConversionIssue> = result.xyz
    let _: Result<LABComponents, ColorConversionIssue> = result.lab
    let _: Result<String, ColorConversionIssue> = result.hex
    requireSendable(result)
    if case .failure(let issue) = result.srgba {
        switch issue {
        case .unresolvedInput, .unsupportedColorModel, .invalidComponents,
             .colorSpaceConversionFailed, .outOfSRGBGamut, .nonfiniteResult:
            break
        }
    }
    return inferred()
}

private func requireSendable<Value: Sendable>(_ value: Value) {}
