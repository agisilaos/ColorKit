import SwiftUI

/// Compiled alongside the real generator, not a copied version of its implementation.
@main
struct EmitTheme {
    enum Failure: Error {
        case unavailable
    }

    @MainActor
    static func main() throws {
        let colors: (Color, Color, Color)
        if CommandLine.arguments.last == "named" {
            colors = (.blue, .purple, .orange)
        } else {
            colors = (
                Color(.sRGB, red: 0.25, green: 0.5, blue: 0.75, opacity: 0.5),
                Color(.displayP3, red: 1, green: 0, blue: 0),
                Color(white: 0.4)
            )
        }
        guard let source = ThemeCodeGenerator.source(
            primary: colors.0, secondary: colors.1, accent: colors.2
        ) else { throw Failure.unavailable }
        print(source)
    }
}
