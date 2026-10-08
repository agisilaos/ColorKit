@testable import ColorKit
import SwiftUI
import Testing

struct ColorAnimationColorsTests {
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
