import SwiftUI
import XCTest

@testable import ColorKit

// CI runs this suite separately without parallel testing because it clears the shared cache.
final class ColorCacheIntegrationTests: XCTestCase {
    override func setUp() {
        super.setUp()
        ColorCache.shared.clearCache()
    }

    override func tearDown() {
        ColorCache.shared.clearCache()
        super.tearDown()
    }

    func testNearbyInterpolationAmountsMatchColdResultsInBothCallOrders() throws {
        let first = try fixedTestColor(components: [0.8, 0.1, 0.2, 1])
        let second = try fixedTestColor(components: [0.1, 0.6, 0.9, 1])
        let amounts: [CGFloat] = [0.5001, 0.5004]
        for space: GradientColorSpace in [.rgb, .hsl, .lab] {
            let cold = amounts.map { amount in
                ColorCache.shared.clearCache()
                return first.interpolated(with: second, amount: amount, in: space)
            }
            XCTAssertNotEqual(try XCTUnwrap(cold[0].cgColor?.components), try XCTUnwrap(cold[1].cgColor?.components))
            for order in [[0, 1], [1, 0]] {
                ColorCache.shared.clearCache()
                for index in order {
                    try assertCacheColorEqual(first.interpolated(with: second, amount: amounts[index], in: space), cold[index])
                }
                for index in order {
                    try assertCacheColorEqual(first.interpolated(with: second, amount: amounts[index], in: space), cold[index])
                }
            }
        }
    }

    func testColorSpaceOrderDoesNotChangeColdOrWarmConversions() throws {
        let colors = try [CGColorSpace.sRGB, CGColorSpace.linearSRGB, CGColorSpace.displayP3].map {
            try fixedTestColor(space: $0)
        }
        let other = try fixedTestColor(components: [0.9, 0.8, 0.7, 1])
        let cold = colors.map { color in
            ColorCache.shared.clearCache()
            return conversionValues(color, other: other)
        }
        for order in [[0, 1, 2], [2, 1, 0]] {
            ColorCache.shared.clearCache()
            for index in order {
                XCTAssertEqual(conversionValues(colors[index], other: other), cold[index])
            }
            for index in order {
                XCTAssertEqual(conversionValues(colors[index], other: other), cold[index])
            }
        }
    }

    func testBlendAndInterpolationPreserveOperandOrderWhenWarm() throws {
        let first = try fixedTestColor(components: [0.8, 0.1, 0.2, 1])
        let second = try fixedTestColor(components: [0.1, 0.6, 0.9, 0.5])
        let pairs = [(first, second), (second, first)]
        let coldBlends = pairs.map { base, blend in
            ColorCache.shared.clearCache()
            return base.blended(with: blend, mode: .normal)
        }
        let coldInterpolations = pairs.map { start, end in
            ColorCache.shared.clearCache()
            return start.interpolated(with: end, amount: 0.3)
        }
        XCTAssertNotEqual(coldBlends[0].cgColor?.components, coldBlends[1].cgColor?.components)
        XCTAssertNotEqual(coldInterpolations[0].cgColor?.components, coldInterpolations[1].cgColor?.components)
        for order in [[0, 1], [1, 0]] {
            ColorCache.shared.clearCache()
            for _ in 0..<2 {
                for index in order {
                    let (first, second) = pairs[index]
                    try assertCacheColorEqual(first.blended(with: second, mode: .normal), coldBlends[index])
                    try assertCacheColorEqual(first.interpolated(with: second, amount: 0.3), coldInterpolations[index])
                }
            }
        }
    }

    func testGrayscaleLABResolutionDoesNotChangeOtherFallbacksWhenCacheIsWarm() throws {
        let other = try fixedTestColor()
        let grays = try [0.25, 0.75].map { value in
            try fixedTestColor(space: CGColorSpace.genericGrayGamma2_2, components: [value, 1])
        }
        let cold = grays.map { color in
            ColorCache.shared.clearCache()
            return conversionValues(color, other: other)
        }
        for order in [[0, 1], [1, 0]] {
            ColorCache.shared.clearCache()
            for _ in 0..<2 {
                for index in order {
                    let gray = grays[index]
                    XCTAssertNotNil(gray.labComponents())
                    XCTAssertNil(gray.hslComponents())
                    XCTAssertEqual(conversionValues(gray, other: other), cold[index])
                    try assertCacheColorEqual(gray.blended(with: other, mode: .normal), gray)
                    try assertCacheColorEqual(gray.interpolated(with: other, amount: 0.3), gray)
                }
            }
        }
    }

    func testUnresolvedColorsKeepTheirFallbacksAfterOtherCalls() throws {
        let other = try fixedTestColor()
        let colors = [Color.primary, Color.secondary]
        let cold = colors.map { color in
            ColorCache.shared.clearCache()
            return conversionValues(color, other: other)
        }
        for order in [[0, 1], [1, 0]] {
            ColorCache.shared.clearCache()
            for _ in 0..<2 {
                for index in order {
                    let color = colors[index]
                    XCTAssertNil(color.cgColor)
                    XCTAssertEqual(conversionValues(color, other: other), cold[index])
                    XCTAssertEqual(color.blended(with: other, mode: .normal), color)
                    XCTAssertEqual(color.interpolated(with: other, amount: 0.3), color)
                    XCTAssertEqual(cachePresence(ColorCache.shared, color: color, other: other), Array(repeating: false, count: 6))
                }
            }
        }
    }

    func testInterpolationKeepsExistingClampingBeforeCacheLookup() throws {
        let first = try fixedTestColor()
        let second = try fixedTestColor(components: [0.8, 0.7, 0.1, 1])
        for (amount, clamped): (CGFloat, CGFloat) in [(-0.25, 0), (1.25, 1)] {
            ColorCache.shared.clearCache()
            let cold = first.interpolated(with: second, amount: clamped)
            try assertCacheColorEqual(first.interpolated(with: second, amount: amount), cold)
            XCTAssertNil(ColorCache.shared.getCachedInterpolatedColor(color1: first, with: second, amount: amount, colorSpace: "rgb"))
            XCTAssertNotNil(ColorCache.shared.getCachedInterpolatedColor(color1: first, with: second, amount: clamped, colorSpace: "rgb"))
        }
    }

    func testContrastingEndpointMatchesWithColdAndWarmCachesInBothOrders() throws {
        let cases: [(color: Color, expected: Color)] = try [
            (fixedTestColor(components: [0.46, 0.46, 0.46, 1]), .white),
            (fixedTestColor(components: [0.461, 0.461, 0.461, 1]), .black),
            (fixedTestColor(components: [0.5, 0.5, 0.5, 1]), .black),
            (fixedTestColor(components: [1, 0, 0, 1]), .black),
            (fixedTestColor(components: [0, 0, 1, 1]), .white)
        ]

        for (color, expected) in cases {
            for level in WCAGContrastLevel.allCases {
                ColorCache.shared.clearCache()
                XCTAssertNil(ColorCache.shared.getCachedContrastRatio(for: color, with: .black))
                XCTAssertNil(ColorCache.shared.getCachedContrastRatio(for: color, with: .white))

                XCTAssertEqual(color.accessibleContrastingColor(for: level), expected)

                XCTAssertNotNil(ColorCache.shared.getCachedContrastRatio(for: color, with: .black))
                XCTAssertNotNil(ColorCache.shared.getCachedContrastRatio(for: color, with: .white))
                XCTAssertEqual(color.accessibleContrastingColor(for: level), expected)
            }
        }

        for order in [cases, Array(cases.reversed())] {
            ColorCache.shared.clearCache()
            for (color, _) in order {
                // Populate the symmetric contrast keys through the reverse call direction.
                _ = Color.white.wcagContrastRatio(with: color)
                _ = Color.black.wcagContrastRatio(with: color)
            }
            for (color, expected) in order {
                for level in WCAGContrastLevel.allCases {
                    XCTAssertEqual(color.accessibleContrastingColor(for: level), expected)
                }
            }
        }
    }

    func testContrastingEndpointBreaksExactRatioTiesWithoutRounding() throws {
        let color = try fixedTestColor(components: [0.4603, 0.4603, 0.4603, 1])
        let ratio = sqrt(21.0)
        let cases: [(blackRatio: Double, expected: Color)] = [
            (ratio.nextDown, .white), (ratio, .black), (ratio.nextUp, .black)
        ]

        // Seed ratios to exercise exact equality and adjacent Doubles independently
        // of platform color conversion rounding at the luminance crossover.
        for (blackRatio, expected) in cases {
            ColorCache.shared.cacheContrastRatio(for: color, with: .black, ratio: blackRatio)
            ColorCache.shared.cacheContrastRatio(for: color, with: .white, ratio: ratio)
            XCTAssertEqual(color.wcagContrastRatio(with: .black), blackRatio)
            XCTAssertEqual(color.wcagContrastRatio(with: .white), ratio)

            for level in WCAGContrastLevel.allCases {
                XCTAssertEqual(color.accessibleContrastingColor(for: level), expected)
            }
        }
    }

    private func conversionValues(_ color: Color, other: Color) -> [Double?] {
        let lab = color.labComponents()
        let hsl = color.hslComponents()
        return [
            lab.map { Double($0.L) }, lab.map { Double($0.a) }, lab.map { Double($0.b) },
            hsl.map { Double($0.hue) }, hsl.map { Double($0.saturation) }, hsl.map { Double($0.lightness) },
            color.wcagRelativeLuminance(), color.wcagContrastRatio(with: other), other.wcagContrastRatio(with: color)
        ]
    }
}
