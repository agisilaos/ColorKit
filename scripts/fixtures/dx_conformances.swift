import ColorKit
import SwiftUI

// Ordinary Swift 6 client: no @testable import or client-side conformances.
private func requireSendable<T: Sendable>(_: T) {}

func transferableAccessibilitySettings() async {
    let enhancement = AccessibilityEnhancer.Configuration(
        targetLevel: .AAA, strategy: .minimumChange, maxPerceptualDistance: 12)
    let palette = AccessiblePaletteGenerator.Configuration(targetLevel: .AA, paletteSize: 4)
    requireSendable(enhancement.strategy)
    requireSendable(enhancement)
    requireSendable(palette)

    // Construct each processor where it is used; only settings cross the boundary.
    let enhance: @Sendable () -> ColorAccessibilityResult = {
        let foreground = Color(.sRGB, red: 0.5, green: 0.5, blue: 0.5)
        let background = Color(.sRGB, red: 1, green: 1, blue: 1)
        return AccessibilityEnhancer(configuration: enhancement)
            .enhanceColorResult(foreground, against: background)
    }
    let generate: @Sendable () -> [Color] = {
        AccessiblePaletteGenerator(configuration: palette)
            .generatePalette(from: Color(.sRGB, red: 0, green: 0, blue: 1))
    }
    async let enhanced = enhance()
    async let generated = generate()
    _ = await (enhanced, generated)
}
