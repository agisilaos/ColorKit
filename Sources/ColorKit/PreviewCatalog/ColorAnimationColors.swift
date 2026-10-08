import SwiftUI

struct ColorAnimationColors {
    var start: Color = .blue
    var end: Color = .red
    var current: Color = .blue

    func labDestination() -> Color? {
        let fixedEnd: Color
        if end.cgColor != nil {
            fixedEnd = end
        } else {
            // The preview owns appearance capture; strict LAB conversion stays fixed-input only.
            guard let rgba = AppearanceResolvedSRGBA.resolve(end) else { return nil }
            fixedEnd = Color(.sRGB, red: rgba.red, green: rgba.green, blue: rgba.blue, opacity: rgba.alpha)
        }
        guard let components = fixedEnd.labComponents() else { return nil }
        return Color(L: components.L, a: components.a, b: components.b)
    }

    mutating func selectStart(_ color: Color, isAnimating: Bool) {
        start = color
        if !isAnimating { current = color }
    }
}
