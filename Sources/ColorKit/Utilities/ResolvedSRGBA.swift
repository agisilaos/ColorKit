import CoreGraphics
import SwiftUI

/// A finite, nonlinear sRGB snapshot with unpremultiplied alpha.
/// RGB may extend beyond 0–1; consumers decide whether that range is representable.
struct ResolvedSRGBA {
    let red: CGFloat
    let green: CGFloat
    let blue: CGFloat
    let alpha: CGFloat

    var isInSRGBGamut: Bool {
        (0...1).contains(red) && (0...1).contains(green) && (0...1).contains(blue)
    }

    init?(sRGBComponents components: [CGFloat]) {
        guard components.count == 4,
              components.allSatisfy({ $0.isFinite }),
              (0...1).contains(components[3]) else { return nil }
        red = components[0]
        green = components[1]
        blue = components[2]
        alpha = components[3]
    }

    /// Resolves fixed RGB or grayscale inputs without consulting appearance or caches.
    static func resolve(_ color: Color) -> Self? {
        guard let source = color.cgColor,
              let space = source.colorSpace,
              space.model == .rgb || space.model == .monochrome,
              let components = source.components,
              components.count == space.numberOfComponents + 1,
              components.allSatisfy({ $0.isFinite }),
              let alpha = components.last,
              (0...1).contains(alpha),
              let sRGB = CGColorSpace(name: CGColorSpace.sRGB),
              let extendedSRGB = CGColorSpace(name: CGColorSpace.extendedSRGB) else { return nil }

        let resolved: [CGFloat]
        if CFEqual(space, sRGB) || CFEqual(space, extendedSRGB) {
            // These spaces share an encoding. Avoid conversion drift in existing sRGB values.
            resolved = components
        } else {
            guard let converted = source.converted(to: extendedSRGB, intent: .relativeColorimetric, options: nil),
                  let convertedComponents = converted.components else { return nil }
            resolved = convertedComponents
        }

        return Self(sRGBComponents: resolved)
    }
}
