import ColorKit
import SwiftUI

// Keep both full imports: selective imports would hide the client naming collision.
struct BlendOptions {
    var mode: ColorBlendMode = .multiply
    var modes: [ColorBlendMode] = [.multiply, .screen, .overlay]
}

func colorBlendModeClient(_ base: Color, _ blend: Color) {
    let modes: [ColorBlendMode] = [ColorBlendMode.multiply, .screen]
    let legacy: (Color, ColorBlendMode, CGFloat) -> Color = base.blended(with:mode:amount:)
    let result: (Color, ColorBlendMode, CGFloat) -> Result<Color, ColorBlendError> = base.blendResult(with:mode:amount:)
    let unbound: (Color) -> (Color, ColorBlendMode, CGFloat) -> Color = Color.blended(with:mode:amount:)
    let unboundResult: (Color) -> (Color, ColorBlendMode, CGFloat) -> Result<Color, ColorBlendError> = Color.blendResult(with:mode:amount:)
    for mode in modes {
        _ = legacy(blend, mode, 0.5)
        _ = result(blend, mode, 1)
        _ = unbound(base)(blend, mode, 0.5)
        _ = unboundResult(base)(blend, mode, 1)
    }

    let inferredLegacy = base.blended(with:mode:amount:)
    let inferredResult = base.blendResult(with:mode:amount:)
    _ = inferredLegacy(blend, .multiply, 1)
    _ = inferredResult(blend, .screen, 1)
    _ = base.blended(with: blend, mode: .multiply)
    _ = base.blendResult(with: blend, mode: .screen)
}

func exhaustiveColorBlendMode(_ mode: ColorBlendMode) {
    switch mode {
    case .normal, .multiply, .screen, .overlay, .darken, .lighten,
         .colorDodge, .colorBurn, .hardLight, .softLight, .difference, .exclusion:
        break
    }
}
