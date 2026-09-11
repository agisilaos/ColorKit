import SwiftUI
import Testing

@testable import ColorKit

struct GradientModifierTests {
    @Test
    func directionPoints() {
        let cases: [(GradientDirection, UnitPoint, UnitPoint)] = [
            (.topToBottom, UnitPoint.top, UnitPoint.bottom),
            (.bottomToTop, .bottom, .top),
            (.leadingToTrailing, .leading, .trailing),
            (.trailingToLeading, .trailing, .leading),
            (.topLeadingToBottomTrailing, .topLeading, .bottomTrailing),
            (.bottomTrailingToTopLeading, .bottomTrailing, .topLeading),
            (.topTrailingToBottomLeading, .topTrailing, .bottomLeading),
            (.bottomLeadingToTopTrailing, .bottomLeading, .topTrailing)
        ]
        for (direction, start, end) in cases {
            #expect(direction.points.start == start)
            #expect(direction.points.end == end)
        }
    }
}

// Compile coverage for public argument labels and defaults, without claiming UI validation.
@MainActor
private func gradientBackgroundCalls() {
    let view = Text("Gradient")
    _ = view.linearGradientBackground(from: .red, to: .blue, direction: .topToBottom, in: .rgb, steps: 10)
    _ = view.complementaryGradientBackground(from: .red, direction: .topToBottom, in: .hsl, steps: 10)
    _ = view.analogousGradientBackground(from: .red, direction: .topToBottom, angle: 0.0833, in: .hsl, steps: 10)
    _ = view.triadicGradientBackground(from: .red, direction: .topToBottom, in: .hsl, steps: 5)
    _ = view.monochromaticGradientBackground(from: .red, direction: .topToBottom, lightnessRange: 0.1...0.9, steps: 10)
    _ = view.linearGradientBackground(from: .red, to: .blue)
    _ = view.complementaryGradientBackground(from: .red)
    _ = view.analogousGradientBackground(from: .red)
    _ = view.triadicGradientBackground(from: .red)
    _ = view.monochromaticGradientBackground(from: .red)
}
