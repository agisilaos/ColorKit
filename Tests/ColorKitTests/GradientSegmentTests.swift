import SwiftUI
import Testing

@testable import ColorKit

struct GradientSegmentTests {
    @Test(arguments: [2, 3, 8])
    func closedPathsKeepEverySampleInOrder(steps: Int) throws {
        let source = Color(hue: 0, saturation: 1, lightness: 0.5)
        let green = Color(hue: 1.0 / 3, saturation: 1, lightness: 0.5)
        let blue = Color(hue: 2.0 / 3, saturation: 1, lightness: 0.5)
        let yellow = Color(hue: 0.125, saturation: 1, lightness: 0.5)
        let cyan = Color(hue: 0.5, saturation: 1, lightness: 0.5)
        let violet = Color(hue: 0.625, saturation: 1, lightness: 0.5)

        for space in [GradientColorSpace.rgb, .hsl, .lab] {
            let paths = [
                (source.triadicGradient(steps: steps, in: space), [source, green, blue, source]),
                (source.splitComplementaryGradient(steps: steps, angle: 1.0 / 6, in: space), [source, green, blue, source]),
                (source.tetradicGradient(steps: steps, angle: 0.125, in: space), [source, yellow, cyan, violet, source])
            ]
            for (colors, stops) in paths {
                try #require(colors.count == (stops.count - 1) * (steps - 1) + 1)
                for index in colors.indices {
                    let segment = min(index / (steps - 1), stops.count - 2)
                    let amount = CGFloat(index - segment * (steps - 1)) / CGFloat(steps - 1)
                    let expected = stops[segment].interpolated(with: stops[segment + 1], amount: amount, in: space)
                    let actualRGB = try #require(ResolvedSRGBA.resolve(colors[index]))
                    let expectedRGB = try #require(ResolvedSRGBA.resolve(expected))
                    #expect(abs(actualRGB.red - expectedRGB.red) < 1e-6)
                    #expect(abs(actualRGB.green - expectedRGB.green) < 1e-6)
                    #expect(abs(actualRGB.blue - expectedRGB.blue) < 1e-6)
                    #expect(actualRGB.alpha == expectedRGB.alpha)
                }
            }
        }
    }

    @Test(arguments: [-1, 0, 1])
    func insufficientStepsKeepOriginal(steps: Int) {
        let source = Color(.sRGB, red: 0.2, green: 0.4, blue: 0.8, opacity: 0.5)
        #expect(source.triadicGradient(steps: steps) == [source])
        #expect(source.splitComplementaryGradient(steps: steps) == [source])
        #expect(source.tetradicGradient(steps: steps) == [source])
    }
}
