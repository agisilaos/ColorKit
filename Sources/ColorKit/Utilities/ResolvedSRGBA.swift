import CoreGraphics
import SwiftUI

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

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

/// sRGBA components resolved through the platform color types for the current appearance.
///
/// This is the lenient policy recorded in
/// [ADR 0010](../../../docs/adr/0010-resolve-legacy-luminance-leniently.md), used by the
/// accessors that must answer for colors ``ResolvedSRGBA`` cannot represent. It differs
/// from that strict snapshot in two ways:
///
/// - It resolves named SwiftUI colors, which carry no `cgColor`, and dynamic colors,
///   reporting whatever the appearance in effect produces.
/// - Gamut handling follows the platform: UIKit preserves extended sRGB components,
///   while AppKit converts to bounded sRGB. Consumers such as HSL clamp as needed.
///
/// Prefer ``ResolvedSRGBA`` wherever a measurement must be reproducible from its inputs.
enum AppearanceResolvedSRGBA {
    /// Resolves a color to unpremultiplied sRGBA components, which may extend beyond 0-1 on UIKit.
    ///
    /// - Returns: The components, or `nil` when the platform color cannot produce them,
    ///   as for a pattern color.
    static func resolve(_ color: Color) -> (red: Double, green: Double, blue: Double, alpha: Double)? {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0

        #if canImport(UIKit)
        guard UIColor(color).getRed(&red, green: &green, blue: &blue, alpha: &alpha) else { return nil }
        #elseif canImport(AppKit)
        guard let converted = NSColor(color).usingColorSpace(.sRGB) else { return nil }
        converted.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        #endif

        return (Double(red), Double(green), Double(blue), Double(alpha))
    }
}
