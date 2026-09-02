import SwiftUI
import XCTest

@testable import ColorKit

final class WCAGColorSuggestionsTests: XCTestCase {
    func testLightnessSearchPreservesHueAndSaturationWhenDarkening() throws {
        try assertPreservedHueSuggestion(
            baseColor: .white,
            targetColor: Color(.sRGB, red: 1, green: 0.8, blue: 0.2, opacity: 1),
            needsDarkening: true
        )
    }

    func testSuccessfulDarkeningEndpointWithoutHuePreservation() throws {
        let baseColor = Color.white
        let targetColor = Color(.sRGB, red: 1, green: 1, blue: 0.8, opacity: 1)

        XCTAssertNotNil(targetColor.hslComponents())
        XCTAssertGreaterThan(baseColor.wcagRelativeLuminance(), 0.5)
        XCTAssertFalse(baseColor.wcagCompliance(with: targetColor).passes.contains(.AA))
        XCTAssertTrue(baseColor.wcagCompliance(with: .black).passes.contains(.AA))

        let suggestions = WCAGColorSuggestions(
            baseColor: baseColor,
            targetColor: targetColor,
            targetLevel: .AA
        ).generateSuggestions(preserveHue: false)

        XCTAssertEqual(suggestions.count, 1)
        XCTAssertEqual(try XCTUnwrap(suggestions.first), .black)
    }

    func testLightnessSearchPreservesHueAndSaturationWhenLightening() throws {
        try assertPreservedHueSuggestion(
            baseColor: .black,
            targetColor: Color(.sRGB, red: 0, green: 0, blue: 0.3, opacity: 1),
            needsDarkening: false
        )
    }

    func testSuccessfulLighteningEndpointWithoutHuePreservation() throws {
        let baseColor = Color.black
        let targetColor = Color(.sRGB, red: 0, green: 0, blue: 0.3, opacity: 1)

        XCTAssertNotNil(targetColor.hslComponents())
        XCTAssertLessThanOrEqual(baseColor.wcagRelativeLuminance(), 0.5)
        XCTAssertFalse(baseColor.wcagCompliance(with: targetColor).passes.contains(.AA))
        XCTAssertTrue(baseColor.wcagCompliance(with: .white).passes.contains(.AA))

        let suggestions = WCAGColorSuggestions(
            baseColor: baseColor,
            targetColor: targetColor,
            targetLevel: .AA
        ).generateSuggestions(preserveHue: false)

        XCTAssertEqual(suggestions.count, 1)
        XCTAssertEqual(try XCTUnwrap(suggestions.first), .white)
    }

    func testAlreadyCompliantInputsRemainUnchangedForBothHueSettings() throws {
        let fixtures = [
            (baseColor: Color.white, targetColor: Color.black.opacity(0.8)),
            (baseColor: Color.black, targetColor: Color.white)
        ]

        for fixture in fixtures {
            XCTAssertTrue(fixture.baseColor.wcagCompliance(with: fixture.targetColor).passes.contains(.AA))

            for preserveHue in [true, false] {
                let suggestions = WCAGColorSuggestions(
                    baseColor: fixture.baseColor,
                    targetColor: fixture.targetColor,
                    targetLevel: .AA
                ).generateSuggestions(preserveHue: preserveHue)

                XCTAssertEqual(suggestions.count, 1)
                XCTAssertEqual(try XCTUnwrap(suggestions.first), fixture.targetColor)
            }
        }
    }

    func testFailedLighteningEndpointPreservesWhiteFallbackForBothHueSettings() throws {
        let baseColor = Color(.sRGB, red: 0.5, green: 0.5, blue: 0.5, opacity: 1)
        let targetColor = Color(.sRGB, red: 0.6, green: 0.6, blue: 0.6, opacity: 1)

        XCTAssertNotNil(targetColor.hslComponents())
        XCTAssertLessThanOrEqual(baseColor.wcagRelativeLuminance(), 0.5)
        XCTAssertFalse(baseColor.wcagCompliance(with: targetColor).passes.contains(.AAA))
        XCTAssertFalse(baseColor.wcagCompliance(with: .white).passes.contains(.AAA))

        for preserveHue in [true, false] {
            let suggestions = WCAGColorSuggestions(
                baseColor: baseColor,
                targetColor: targetColor,
                targetLevel: .AAA
            ).generateSuggestions(preserveHue: preserveHue)

            XCTAssertEqual(suggestions.count, 1)
            XCTAssertEqual(try XCTUnwrap(suggestions.first), .white)
            XCTAssertFalse(baseColor.wcagCompliance(with: .white).passes.contains(.AAA))
        }
    }

    func testUnavailableHSLTargetRemainsUnchanged() throws {
        let baseColor = Color.black
        let targetColor = try patternTestColor()

        XCTAssertNil(targetColor.hslComponents())
        XCTAssertFalse(baseColor.wcagCompliance(with: targetColor).passes.contains(.AA))

        for preserveHue in [true, false] {
            let suggestions = WCAGColorSuggestions(
                baseColor: baseColor,
                targetColor: targetColor,
                targetLevel: .AA
            ).generateSuggestions(preserveHue: preserveHue)

            XCTAssertEqual(suggestions.count, 1)
            XCTAssertEqual(try XCTUnwrap(suggestions.first), targetColor)
        }
    }

    private func assertPreservedHueSuggestion(
        baseColor: Color,
        targetColor: Color,
        needsDarkening: Bool,
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws {
        let targetHSL = try XCTUnwrap(targetColor.hslComponents(), file: file, line: line)
        XCTAssertEqual(baseColor.wcagRelativeLuminance() > 0.5, needsDarkening, file: file, line: line)
        XCTAssertFalse(baseColor.wcagCompliance(with: targetColor).passes.contains(.AA), file: file, line: line)

        let suggestions = WCAGColorSuggestions(
            baseColor: baseColor,
            targetColor: targetColor,
            targetLevel: .AA
        ).generateSuggestions(preserveHue: true)

        XCTAssertEqual(suggestions.count, 1, file: file, line: line)
        let suggestion = try XCTUnwrap(suggestions.first, file: file, line: line)
        XCTAssertNotEqual(suggestion, needsDarkening ? .black : .white, file: file, line: line)
        XCTAssertTrue(baseColor.wcagCompliance(with: suggestion).passes.contains(.AA), file: file, line: line)

        let suggestionHSL = try XCTUnwrap(suggestion.hslComponents(), file: file, line: line)
        if needsDarkening {
            XCTAssertLessThan(suggestionHSL.lightness, targetHSL.lightness, file: file, line: line)
        } else {
            XCTAssertGreaterThan(suggestionHSL.lightness, targetHSL.lightness, file: file, line: line)
        }
        let hueDistance = min(abs(targetHSL.hue - suggestionHSL.hue), 1 - abs(targetHSL.hue - suggestionHSL.hue))
        XCTAssertEqual(hueDistance, 0, accuracy: 0.01, file: file, line: line)
        XCTAssertEqual(suggestionHSL.saturation, targetHSL.saturation, accuracy: 0.01, file: file, line: line)
    }
}
