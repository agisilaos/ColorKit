@testable import ColorKit
import SwiftUI
import Testing

@MainActor
struct ColorSpacePreviewTests {
    @Test(arguments: [0.0, 1.0 / 3, 2.0 / 3])
    func hueDisplaysDegreesWhileSliderKeepsTurns(_ hue: Double) {
        let row = ColorComponentRow.hue(hue)
        #expect(row.value == hue)
        #expect(row.formattedValue == String(format: "%.2f°", hue * 360))
    }
}
