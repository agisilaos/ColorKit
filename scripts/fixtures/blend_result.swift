import ColorKit
import Foundation
import struct SwiftUI.Color

// Ordinary nonisolated client compiled at the library's minimum deployment targets.
func blendResultClient(_ base: Color, _ blend: Color) -> Result<Color, ColorBlendError> {
    let typed: (Color, BlendMode, CGFloat) -> Result<Color, ColorBlendError> = base.blendResult
    let inferred = base.blendResult
    let unbound = Color.blendResult
    _ = typed(blend, .multiply, 0.5)
    _ = inferred(blend, .overlay, 1)
    _ = unbound(base)(blend, .normal, 0)
    let result = base.blendResult(with: blend, mode: .multiply)
    switch result {
    case .success(let color):
        _ = color
    case .failure(let error):
        requireBlendError(error)
        switch error {
        case .invalidAmount, .nonfiniteResult:
            break
        case let .unavailableInputs(base, blend):
            let _: ColorConversionIssue? = base
            let _: ColorConversionIssue? = blend
        }
    }
    return result
}

private func requireBlendError<Value: Error & Equatable & Sendable>(_ value: Value) {}

// A selective SwiftUI import keeps the original spelling available for identity checks.
func blendModeIdentity(_ original: BlendMode, _ alias: ColorBlendMode) {
    let _: ColorBlendMode = original
    let _: BlendMode = alias
    let _: [ColorBlendMode] = [original]
    let _: BlendMode.Type = ColorBlendMode.self
}
