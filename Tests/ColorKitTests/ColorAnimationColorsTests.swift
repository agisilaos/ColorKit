@testable import ColorKit
import SwiftUI
import Testing

@MainActor
struct ColorAnimationColorsTests {
    @Test
    func defaultLABDestinationMatchesTheDisplayedEndColor() throws {
        let colors = ColorAnimationColors()
        let destination = try #require(colors.labDestination())
        let expected = colors.end.rgbaComponents()
        let actual = destination.rgbaComponents()
        #expect(abs(actual.red - expected.red) < 0.00001)
        #expect(abs(actual.green - expected.green) < 0.00001)
        #expect(abs(actual.blue - expected.blue) < 0.00001)
        #expect(destination != colors.current)
    }

    @Test
    func fixedLABDestinationStillConvertsAndInvalidInputRemainsUnavailable() throws {
        var colors = ColorAnimationColors()
        colors.end = Color(.sRGB, red: 0.2, green: 0.4, blue: 0.6)
        let result = try #require(colors.labDestination()).rgbaComponents()
        #expect(abs(result.red - 0.2) < 0.00001)
        #expect(abs(result.green - 0.4) < 0.00001)
        #expect(abs(result.blue - 0.6) < 0.00001)
        colors.end = Color(.sRGB, red: .nan, green: 0, blue: 0)
        #expect(colors.labDestination() == nil)
    }

    @Test
    func selectingStartWhileStoppedUpdatesDisplayedStartingColor() {
        var colors = ColorAnimationColors()
        let selected = Color(.sRGB, red: 0.2, green: 0.6, blue: 0.4, opacity: 0.5)
        let end = colors.end
        colors.selectStart(selected, isAnimating: false)
        #expect(colors.start == selected)
        #expect(colors.current == selected)
        #expect(colors.end == end)
    }

    @Test
    func selectingFutureStartDoesNotInterruptActiveAnimation() {
        var colors = ColorAnimationColors()
        colors.current = colors.end
        let current = colors.current
        let selected = Color(.sRGB, red: 0.3, green: 0.4, blue: 0.5)
        colors.selectStart(selected, isAnimating: true)
        #expect(colors.start == selected)
        #expect(colors.current == current)
    }
}
