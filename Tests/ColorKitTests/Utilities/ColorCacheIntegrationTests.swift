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

    func testInjectedContrastCannotMakeTranslucentInputsCompliant() throws {
        let faintBlack = try fixedTestColor(components: [0, 0, 0, 0.1])
        let white = try fixedTestColor(components: [1, 1, 1, 1])
        let cache = ColorCache.shared
        cache.cacheContrastRatio(for: faintBlack, with: white, ratio: 21)
        XCTAssertEqual(try XCTUnwrap(cache.getCachedContrastRatio(for: faintBlack, with: white)), 21)

        for _ in 0..<2 {
            for (first, second) in [(faintBlack, white), (white, faintBlack)] {
                XCTAssertEqual(first.wcagContrastRatio(with: second), 1)
                let compliance = first.wcagCompliance(with: second)
                XCTAssertEqual(compliance.contrastRatio, 1)
                XCTAssertFalse(compliance.passesAA)
                XCTAssertFalse(compliance.passesAALarge)
                XCTAssertFalse(compliance.passesAAA)
                XCTAssertFalse(compliance.passesAAALarge)
                XCTAssertEqual(try XCTUnwrap(cache.getCachedContrastRatio(for: first, with: second)), 21)
            }
        }
        XCTAssertEqual(try XCTUnwrap(faintBlack.contrastResult(with: white).ratio), 1.2538626591661473, accuracy: 1e-9)
        XCTAssertNil(white.contrastResult(with: faintBlack).ratio)
    }

    func testInjectedLuminanceDoesNotBecomeContrastMeasurement() throws {
        let black = try fixedTestColor(components: [0, 0, 0, 1])
        let white = try fixedTestColor(components: [1, 1, 1, 1])
        ColorCache.shared.cacheLuminance(for: black, luminance: 0.875)
        XCTAssertEqual(try XCTUnwrap(ColorCache.shared.getCachedLuminance(for: black)), 0.875)
        XCTAssertEqual(black.wcagRelativeLuminance(), 0.875)
        XCTAssertEqual(black.relativeLuminance(), 0.875)
        XCTAssertFalse(black.isDarkColor())
        XCTAssertEqual(black.contrastRatio(with: white), 1.05 / 0.925, accuracy: 1e-12)
        XCTAssertEqual(black.suggestedColor(for: .AA), .black)
        XCTAssertEqual(try XCTUnwrap(black.relativeLuminanceValue()), 0)
        XCTAssertEqual(black.wcagContrastRatio(with: white), 21)
        XCTAssertEqual(try XCTUnwrap(black.contrastResult(with: white).ratio), 21)
    }

    func testInjectedContrastDoesNotBecomeStrictMeasurement() throws {
        let black = try fixedTestColor(components: [0, 0, 0, 1])
        let white = try fixedTestColor(components: [1, 1, 1, 1])
        ColorCache.shared.cacheContrastRatio(for: black, with: white, ratio: 1.25)
        XCTAssertEqual(try XCTUnwrap(ColorCache.shared.getCachedContrastRatio(for: black, with: white)), 1.25)
        XCTAssertEqual(black.wcagContrastRatio(with: white), 1.25)
        XCTAssertEqual(white.wcagContrastRatio(with: black), 1.25)
        XCTAssertFalse(black.wcagCompliance(with: white).passesAA)
        XCTAssertEqual(black.contrastRatio(with: white), 21)
        XCTAssertEqual(try XCTUnwrap(black.contrastResult(with: white).ratio), 21)
        guard case let .available(comparison) = black.comparisonResult(with: white) else {
            return XCTFail("Fixed opaque endpoints must be comparable")
        }
        XCTAssertEqual(comparison.contrastRatio, 21)
        XCTAssertEqual(comparison.perceptualDifference, 100, accuracy: 0.0001)
        XCTAssertEqual(white.accessibleContrastingColorResult().contrastRatio, 21)
        XCTAssertEqual(black.accessibilityResult(against: white).status, .meetsTarget)
        XCTAssertEqual(black.accessibilityResult(against: white).contrastRatio, 21)
        let enhanced = AccessibilityEnhancer().enhanceColorResult(black, against: white)
        XCTAssertEqual(enhanced.contrastRatio, 21)
        XCTAssertEqual(enhanced.perceptualDistance, 0)
        XCTAssertEqual(ColorCache.shared.getCachedContrastRatio(for: black, with: white), 1.25)
    }

    func testInjectedInterpolationFeedsGradientButNotInputMeasurements() throws {
        let black = try fixedTestColor(components: [0, 0, 0, 1])
        let white = try fixedTestColor(components: [1, 1, 1, 1])
        let marker = try fixedTestColor(components: [1, 0, 0, 1])
        for space: GradientColorSpace in [.rgb, .hsl, .lab] {
            ColorCache.shared.cacheInterpolatedColor(
                color1: black, with: white, amount: 0.5, colorSpace: String(describing: space), result: marker
            )
            try assertCacheColorEqual(ColorCache.shared.getCachedInterpolatedColor(
                color1: black, with: white, amount: 0.5, colorSpace: String(describing: space)), marker)
            try assertCacheColorEqual(black.interpolated(with: white, amount: 0.5, in: space), marker)
            try assertCacheColorEqual(black.linearGradient(to: white, steps: 3, in: space)[1], marker)
        }
        XCTAssertEqual(try black.componentConversionResults().srgba.get().red, 0)
        XCTAssertEqual(try XCTUnwrap(black.contrastResult(with: white).ratio), 21)
        let blended = try black.blendResult(with: white, mode: .multiply).get()
        XCTAssertEqual(try blended.componentConversionResults().srgba.get().red, 0)
    }

    func testBudgetedEnhancementMeasuresCandidatesDespiteInjectedCaches() throws {
        let gray = try fixedTestColor(components: [0.6, 0.6, 0.6, 1])
        let white = try fixedTestColor(components: [1, 1, 1, 1])
        ColorCache.shared.cacheLuminance(for: white, luminance: 0.125)
        ColorCache.shared.cacheContrastRatio(for: gray, with: white, ratio: 19)
        XCTAssertEqual(try XCTUnwrap(ColorCache.shared.getCachedLuminance(for: white)), 0.125)
        XCTAssertEqual(try XCTUnwrap(ColorCache.shared.getCachedContrastRatio(for: gray, with: white)), 19)
        for strategy in AdjustmentStrategy.allCases {
            let enhancer = AccessibilityEnhancer(configuration: .init(strategy: strategy, maxPerceptualDistance: 30))
            let results = [enhancer.enhanceColorResult(gray, against: white)] +
                enhancer.suggestAccessibleVariantResults(for: gray, against: white, count: 2)
            for result in results {
                XCTAssertEqual(result.contrastRatio, result.color.contrastResult(with: white).ratio)
                guard case let .available(comparison) = gray.comparisonResult(with: result.color) else {
                    return XCTFail("The selected candidate must have a strict distance")
                }
                XCTAssertEqual(try XCTUnwrap(result.perceptualDistance), comparison.perceptualDifference, accuracy: 1e-10)
                XCTAssertTrue(try XCTUnwrap(result.isWithinPerceptualDistanceBudget))
                XCTAssertNotEqual(result.contrastRatio, 19)
            }
        }
    }

    func testAssessedPaletteMeasuresLegacyGeneratedCandidates() throws {
        let seed = try fixedTestColor(components: [0.6, 0.6, 0.6, 1])
        let white = try fixedTestColor(components: [1, 1, 1, 1])
        let generator = AccessiblePaletteGenerator()
        ColorCache.shared.cacheLuminance(for: seed, luminance: 0.875)
        ColorCache.shared.cacheContrastRatio(for: seed, with: white, ratio: 19)
        XCTAssertEqual(try XCTUnwrap(ColorCache.shared.getCachedLuminance(for: seed)), 0.875)
        XCTAssertEqual(try XCTUnwrap(ColorCache.shared.getCachedContrastRatio(for: seed, with: white)), 19)
        let assessed = generator.generateAssessedPalette(from: seed, against: white)
        XCTAssertFalse(assessed.isEmpty)
        for result in assessed {
            XCTAssertEqual(result.contrastRatio, result.color.contrastResult(with: white).ratio)
        }
    }

    func testBlendResultsIgnoreAndDoNotPopulateLegacyCache() throws {
        let base = try fixedTestColor(components: [0.5, 0.5, 0.5, 1])
        let blend = try fixedTestColor(components: [0.5, 0.5, 0.5, 1])
        let result = try base.blendResult(with: blend, mode: .multiply).get()
        XCTAssertEqual(try result.componentConversionResults().srgba.get().red, 0.25)
        XCTAssertNil(ColorCache.shared.getCachedBlendedColor(color1: base, with: blend, blendMode: "multiply"))
        let inserted = Color(.sRGB, red: 1, green: 0, blue: 0)
        ColorCache.shared.cacheBlendedColor(color1: base, with: blend, blendMode: "multiply", result: inserted)
        try assertCacheColorEqual(ColorCache.shared.getCachedBlendedColor(color1: base, with: blend, blendMode: "multiply"), inserted)
        XCTAssertEqual(try base.blendResult(with: blend, mode: .multiply).get().componentConversionResults().srgba.get().red, 0.25)
        XCTAssertEqual(try base.multiply(with: blend, amount: 0.5).componentConversionResults().srgba.get().red, 0.375, accuracy: 1e-7)
        try assertCacheColorEqual(base.multiply(with: blend), inserted)
        try assertCacheColorEqual(ColorCache.shared.getCachedBlendedColor(color1: base, with: blend, blendMode: "multiply"), inserted)
    }

    func testComponentResultsIgnoreAndDoNotReplaceLegacyCacheEntries() throws {
        let color = try fixedTestColor(components: [1, 0, 0, 1])
        let other = try fixedTestColor(components: [1, 1, 1, 1])
        populateCache(ColorCache.shared, color: color, other: other)
        try assertCacheMarker(ColorCache.shared, color: color, other: other, marker: 0.25)
        ColorCache.shared.cacheHSLComponents(for: color, hue: 0.4, saturation: 0.2, lightness: 0.3)
        ColorCache.shared.cacheLABComponents(for: color, L: 12, a: 34, b: 56)

        XCTAssertEqual(try XCTUnwrap(ColorCache.shared.getCachedHSLComponents(for: color)).hue, 0.4)
        XCTAssertEqual(try XCTUnwrap(ColorCache.shared.getCachedLABComponents(for: color)).L, 12)
        let result = color.componentConversionResults()
        XCTAssertEqual(try result.hsl.get(), HSLComponents(hue: 0, saturation: 1, lightness: 0.5))
        XCTAssertEqual(try result.lab.get().lightness, 53.2407941413, accuracy: 1e-9)
        XCTAssertEqual(try XCTUnwrap(color.hslComponents()).hue, 0.4)
        XCTAssertEqual(try XCTUnwrap(color.labComponents()).L, 12)
        ColorCache.shared.clearCache()
        let cold = color.componentConversionResults()
        XCTAssertEqual(try result.srgba.get(), try cold.srgba.get())
        XCTAssertEqual(try result.hsl.get(), try cold.hsl.get())
        XCTAssertEqual(try result.hsb.get(), try cold.hsb.get())
        XCTAssertEqual(try result.cmyk.get(), try cold.cmyk.get())
        XCTAssertEqual(try result.xyz.get(), try cold.xyz.get())
        XCTAssertEqual(try result.lab.get(), try cold.lab.get())
        XCTAssertEqual(try result.hex.get(), try cold.hex.get())
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

    func testGrayscaleResultsMatchColdValuesInBothCallOrders() throws {
        let other = try fixedTestColor()
        let grays = try [0.25, 0.75].map { value in
            try fixedTestColor(space: CGColorSpace.genericGrayGamma2_2, components: [value, 1])
        }
        let cold = grays.map { color in
            ColorCache.shared.clearCache()
            return conversionValues(color, other: other)
        }
        let coldBlends = grays.map { color -> Color in
            ColorCache.shared.clearCache()
            return color.blended(with: other, mode: .normal)
        }
        let coldInterpolations = grays.map { color -> Color in
            ColorCache.shared.clearCache()
            return color.interpolated(with: other, amount: 0.3)
        }

        // Grayscale now resolves for blending and interpolation instead of being
        // returned unchanged, so these are real results rather than the operand.
        for index in grays.indices {
            XCTAssertNotEqual(
                try XCTUnwrap(coldBlends[index].cgColor?.components),
                try XCTUnwrap(grays[index].cgColor?.components)
            )
            XCTAssertNotEqual(
                try XCTUnwrap(coldInterpolations[index].cgColor?.components),
                try XCTUnwrap(grays[index].cgColor?.components)
            )
        }

        for order in [[0, 1], [1, 0]] {
            ColorCache.shared.clearCache()
            for _ in 0..<2 {
                for index in order {
                    let gray = grays[index]
                    XCTAssertNotNil(gray.labComponents())
                    XCTAssertNotNil(gray.hslComponents())
                    XCTAssertEqual(conversionValues(gray, other: other), cold[index])
                    try assertCacheColorEqual(gray.blended(with: other, mode: .normal), coldBlends[index])
                    try assertCacheColorEqual(gray.interpolated(with: other, amount: 0.3), coldInterpolations[index])
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
