@testable import ColorKit
import SwiftUI
import Testing

@MainActor
struct ThemeCodeGeneratorTests {
    @Test
    func exportsFixedComponentsAndAlpha() throws {
        let color = Color(.sRGB, red: 0.25, green: 0.5, blue: 0.75, opacity: 0.5)
        let code = try #require(ThemeCodeGenerator.source(primary: color, secondary: color, accent: color))
        #expect(code.contains("red: 0.25, green: 0.5, blue: 0.75, opacity: 0.5"))
        #expect(code.contains("static let primary = Color(.sRGB,"))
        #expect(code.contains("static let secondary = Color(.sRGB,"))
        #expect(code.contains("static let accent = Color(.sRGB,"))
    }

    @Test
    func exportsNamedDefaults() throws {
        let code = try #require(ThemeCodeGenerator.source(primary: .blue, secondary: .purple, accent: .orange))
        #expect(code.contains("import SwiftUI"))
        #expect(!code.contains("Color.adaptive"))
    }

    @Test
    func rejectsNonfiniteFixedInput() {
        let invalid = Color(.sRGB, red: .nan, green: 0, blue: 0)
        #expect(ThemeCodeGenerator.source(primary: invalid, secondary: .blue, accent: .orange) == nil)
    }
}
