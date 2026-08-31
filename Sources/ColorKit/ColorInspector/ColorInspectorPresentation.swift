import SwiftUI

/// The inspector's conversion results for one set of current inputs.
struct ColorInspectorPresentation {
    enum Contrast: Equatable {
        case hidden
        case unavailable
        case available(ratio: Double)

        var ratio: Double? {
            guard case let .available(ratio) = self else { return nil }
            return ratio
        }

        var ratioText: String {
            guard let ratio else { return "Ratio: Unavailable" }
            return "Ratio: \(String(format: "%.2f", ratio))"
        }
    }

    let hexValue: String?
    let rgbValues: (r: Int, g: Int, b: Int)?
    let hslValues: (hue: CGFloat, saturation: CGFloat, lightness: CGFloat)?
    let contrast: Contrast

    init(color: Color, backgroundColor: Color, showContrastInfo: Bool) {
        hexValue = color.hexValue()
        hslValues = color.hslComponents()

        let components = color.cgColor?.components
        if let components, components.count >= 3 {
            rgbValues = (
                Int(components[0] * 255),
                Int(components[1] * 255),
                Int(components[2] * 255)
            )
        } else {
            rgbValues = nil
        }

        if !showContrastInfo {
            contrast = .hidden
        } else if let components, components.count >= 3,
                  let backgroundComponents = backgroundColor.cgColor?.components, backgroundComponents.count >= 3 {
            let luminance = Self.luminance(components)
            let backgroundLuminance = Self.luminance(backgroundComponents)
            let lighter = max(luminance, backgroundLuminance)
            let darker = min(luminance, backgroundLuminance)
            contrast = .available(ratio: (lighter + 0.05) / (darker + 0.05))
        } else {
            contrast = .unavailable
        }
    }

    var rgbText: String {
        guard let rgbValues else { return "Unavailable" }
        return "R: \(rgbValues.r), G: \(rgbValues.g), B: \(rgbValues.b)"
    }

    var hslText: String {
        guard let hslValues else { return "Unavailable" }
        return "H: \(Int(hslValues.hue * 360))°, S: \(Int(hslValues.saturation * 100))%, L: \(Int(hslValues.lightness * 100))%"
    }

    private static func luminance(_ components: [CGFloat]) -> Double {
        // Preserve the inspector's legacy transfer function and component interpretation.
        let red = components[0] <= 0.03928 ? components[0] / 12.92 : pow((components[0] + 0.055) / 1.055, 2.4)
        let green = components[1] <= 0.03928 ? components[1] / 12.92 : pow((components[1] + 0.055) / 1.055, 2.4)
        let blue = components[2] <= 0.03928 ? components[2] / 12.92 : pow((components[2] + 0.055) / 1.055, 2.4)
        return 0.2126 * red + 0.7152 * green + 0.0722 * blue
    }
}
