import SwiftUI
import XCTest

@testable import ColorKit

// SplitMix64 fixture with an optional repeated sample to exercise similarity rejection.
struct PaletteTestRandomNumberGenerator: RandomNumberGenerator, Equatable {
    var state: UInt64
    var draws = 0
    var repeating = false

    mutating func next() -> UInt64 {
        draws += 1
        if !repeating { state &+= 0x9E37_79B9_7F4A_7C15 }
        var value = state
        value = (value ^ (value >> 30)) &* 0xBF58_476D_1CE4_E5B9
        value = (value ^ (value >> 27)) &* 0x94D0_49BB_1331_11EB
        return value ^ (value >> 31)
    }
}

func paletteComponents(_ colors: [Color]) throws -> [[CGFloat]] {
    try colors.map { color in
        let rgba = try XCTUnwrap(ResolvedSRGBA.resolve(color))
        return [rgba.red, rgba.green, rgba.blue, rgba.alpha]
    }
}

final class PaletteReplayTests: XCTestCase {
    private let seed = Color(.sRGB, red: 0.2, green: 0.4, blue: 0.7)
    private let white = Color(.sRGB, red: 1, green: 1, blue: 1)

    func testReplayContinuationAndAssessmentShareRandomState() throws {
        let generator = AccessiblePaletteGenerator()
        var random = PaletteTestRandomNumberGenerator(state: 42)
        var replay = random
        let first = generator.generatePalette(from: seed, using: &random)
        let assessed = generator.generateAssessedPalette(from: seed, against: white, using: &replay)
        XCTAssertGreaterThan(random.draws, 0)
        XCTAssertEqual(random, replay)
        XCTAssertEqual(try paletteComponents(first), try paletteComponents(assessed.map(\.color)))
        XCTAssertTrue(assessed.contains { $0.status == .meetsTarget })
        XCTAssertTrue(assessed.contains { $0.status == .bestEffort })
        for entry in assessed {
            let independent = entry.color.accessibilityResult(against: white)
            XCTAssertEqual(entry.status, independent.status)
            XCTAssertEqual(entry.contrastRatio, independent.contrastRatio)
            XCTAssertNil(entry.perceptualDistance)
            XCTAssertNil(entry.maximumPerceptualDistance)
        }

        let second = generator.generatePalette(from: seed, using: &random)
        let continued = generator.generatePalette(from: seed, using: &replay)
        XCTAssertEqual(try paletteComponents(second), try paletteComponents(continued))
        XCTAssertEqual(random, replay)

        var unavailableRandom = PaletteTestRandomNumberGenerator(state: 42)
        let unavailable = generator.generateAssessedPalette(
            from: seed,
            against: Color(.sRGB, red: 1, green: 1, blue: 1, opacity: 0.5),
            using: &unavailableRandom
        )
        XCTAssertEqual(try paletteComponents(first), try paletteComponents(unavailable.map(\.color)))
        XCTAssertTrue(unavailable.allSatisfy { $0.status == .unavailable && $0.contrastRatio == nil })
        var firstRequest = PaletteTestRandomNumberGenerator(state: 42)
        _ = generator.generatePalette(from: seed, using: &firstRequest)
        XCTAssertEqual(unavailableRandom, firstRequest)
    }

    func testInitialEntriesNeedNoRandomnessAndPreserveSizeQuirk() {
        let generator = AccessiblePaletteGenerator(configuration: .init(paletteSize: 2))
        var random = PaletteTestRandomNumberGenerator(state: 42)
        let initial = random
        let palette = generator.generatePalette(from: seed, using: &random)
        XCTAssertEqual(palette, [seed, .black, .white])
        XCTAssertEqual(random, initial)
        XCTAssertEqual(generator.generatePalette(from: seed), palette)
    }

    func testRejectedCandidatesConsumeAttemptsBeforeOrderedFallbacks() {
        let generator = AccessiblePaletteGenerator(configuration: .init(
            paletteSize: 100, includeBlackAndWhite: false
        ))
        var random = PaletteTestRandomNumberGenerator(state: 42, repeating: true)
        let palette = generator.generatePalette(from: seed, using: &random)
        // One identical candidate is retained; later attempts are rejected as similar.
        // For this fixture/toolchain each Double draw consumes one next() call.
        XCTAssertEqual(random.draws, 100)
        XCTAssertEqual(palette.first, seed)
        XCTAssertGreaterThan(palette.count, 2)
        XCTAssertLessThanOrEqual(palette.count, 9)
        let fallbacks: [Color] = [.red, .green, .blue, .orange, .purple, .yellow, .pink]
        var remaining = fallbacks[...]
        for color in palette.dropFirst(2) {
            guard let index = remaining.firstIndex(of: color) else {
                return XCTFail("Fallbacks must retain their original order")
            }
            remaining = remaining.suffix(from: remaining.index(after: index))
        }
    }

    func testInsufficientContrastUsesExistingExtremeLightnessCandidate() throws {
        let generator = AccessiblePaletteGenerator(configuration: .init(
            targetLevel: .AAA, paletteSize: 2, includeBlackAndWhite: false
        ))
        let gray = Color(.sRGB, red: 0.5, green: 0.5, blue: 0.5)
        var random = PaletteTestRandomNumberGenerator(state: 42)
        let palette = generator.generatePalette(from: gray, using: &random)
        XCTAssertEqual(palette.count, 2)
        let hsl = try XCTUnwrap(palette[1].hslComponents())
        XCTAssertEqual(hsl.lightness, 0.1, accuracy: 1e-6)
        XCTAssertFalse(palette[1].accessibilityResult(against: gray, targetLevel: .AAA).meetsTarget)
    }

    func testUnresolvableSeedRetainsFallbacksWithoutDrawingRandomness() throws {
        let seed = try patternTestColor()
        let generator = AccessiblePaletteGenerator(configuration: .init(
            paletteSize: 100, includeBlackAndWhite: false
        ))
        var random = PaletteTestRandomNumberGenerator(state: 42)
        let results = generator.generateAssessedPalette(from: seed, against: white, using: &random)
        XCTAssertEqual(random.draws, 0)
        XCTAssertEqual(results.first?.color, seed)
        XCTAssertEqual(results.first?.status, .unavailable)
        XCTAssertGreaterThan(results.count, 1)
        XCTAssertLessThan(results.count, 100)
    }

    func testDynamicSeedRemainsAcceptedWithUnavailableAssessment() {
        var random = PaletteTestRandomNumberGenerator(state: 42)
        let results = AccessiblePaletteGenerator().generateAssessedPalette(
            from: .primary, against: white, using: &random
        )
        XCTAssertEqual(results.first?.color, .primary)
        XCTAssertEqual(results.first?.status, .unavailable)
        XCTAssertGreaterThan(random.draws, 0)
    }
}
