import ColorKit
import SwiftUI
import Testing

struct GradientOpacityTests {
    @Test(arguments: ["rgb", "hsl", "lab"], [0.0, 0.5, 1.0])
    func interpolationRetainsAlpha(_ name: String, _ amount: Double) throws {
        let space: GradientColorSpace = name == "rgb" ? .rgb : name == "hsl" ? .hsl : .lab
        let start = Color(.sRGB, red: 1, green: 0, blue: 0, opacity: 0.2)
        let end = Color(.sRGB, red: 0, green: 0, blue: 1, opacity: 0.8)
        let result = start.interpolated(with: end, amount: amount, in: space)
        let components = try result.componentConversionResults().srgba.get()
        #expect(abs(components.alpha - (0.2 + 0.6 * amount)) < 1e-6)
    }

    @Test(arguments: ["rgb", "hsl", "lab"])
    func generatedGradientRetainsTransparentEndpoints(_ name: String) throws {
        let space: GradientColorSpace = name == "rgb" ? .rgb : name == "hsl" ? .hsl : .lab
        let start = Color(.sRGB, red: 1, green: 0, blue: 0, opacity: 0)
        let end = Color(.sRGB, red: 0, green: 0, blue: 1, opacity: 1)
        let colors = start.linearGradient(to: end, steps: 3, in: space)
        let alpha = try colors.map { try $0.componentConversionResults().srgba.get().alpha }
        #expect(alpha == [0, 0.5, 1])
    }
}
