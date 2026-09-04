import SwiftUI

/// Generates fixed sRGB literals, never SwiftUI debug descriptions or fallback colors.
@MainActor
enum ThemeCodeGenerator {
    static func source(primary: Color, secondary: Color, accent: Color) -> String? {
        guard let primary = literal(primary),
              let secondary = literal(secondary),
              let accent = literal(accent) else { return nil }
        return """
        import SwiftUI

        // Fixed colors captured in the current platform appearance.
        enum Theme {
            static let primary = \(primary)
            static let secondary = \(secondary)
            static let accent = \(accent)
        }
        """
    }

    private static func literal(_ color: Color) -> String? {
        let fixedColor: Color
        if color.cgColor != nil {
            fixedColor = color
        } else {
            // ColorPicker's named defaults need platform resolution for export only.
            // Do not change strict measurement APIs or retry invalid fixed components.
            #if canImport(UIKit)
            fixedColor = Color(UIColor(color).cgColor)
            #elseif canImport(AppKit)
            guard let resolved = NSColor(color).usingColorSpace(.extendedSRGB) else { return nil }
            fixedColor = Color(resolved.cgColor)
            #endif
        }
        guard let components = ResolvedSRGBA.resolve(fixedColor) else { return nil }
        return "Color(.sRGB, red: \(components.red), green: \(components.green), "
            + "blue: \(components.blue), opacity: \(components.alpha))"
    }
}
