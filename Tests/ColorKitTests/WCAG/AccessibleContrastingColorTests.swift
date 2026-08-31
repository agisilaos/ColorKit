import SwiftUI
import XCTest

@testable import ColorKit

final class AccessibleContrastingColorTests: XCTestCase {
    func testMiddleGraysChooseStrongerEndpointForEveryLevel() {
        let cases: [(gray: Double, expected: Color)] = [
            (0.4, .white), (0.46, .white), (0.461, .black),
            (0.5, .black), (0.6, .black), (0.7, .black)
        ]

        for (gray, expected) in cases {
            let color = Color(.sRGB, red: gray, green: gray, blue: gray)
            assertStrongestEndpoint(for: color, expected: expected)
        }
    }

    func testSaturatedColorsChooseStrongerEndpointForEveryLevel() {
        let cases: [(color: Color, expected: Color)] = [
            (Color(.sRGB, red: 1, green: 0, blue: 0), .black),
            (Color(.sRGB, red: 0, green: 1, blue: 0), .black),
            (Color(.sRGB, red: 0, green: 0, blue: 1), .white),
            (Color(.sRGB, red: 0, green: 1, blue: 1), .black),
            (Color(.sRGB, red: 1, green: 0, blue: 1), .black),
            (Color(.sRGB, red: 1, green: 1, blue: 0), .black)
        ]

        for (color, expected) in cases {
            assertStrongestEndpoint(for: color, expected: expected)
        }
    }

    func testExtremesChooseOppositeEndpointForEveryLevel() {
        assertStrongestEndpoint(for: .black, expected: .white)
        assertStrongestEndpoint(for: .white, expected: .black)
        for (gray, expected): (Double, Color) in [(0.0001, .white), (0.9999, .black)] {
            let color = Color(.sRGB, red: gray, green: gray, blue: gray)
            assertStrongestEndpoint(for: color, expected: expected)
        }
    }

    func testUnattainableAAAReturnsBestEndpointWithoutTinting() {
        for (gray, expected): (Double, Color) in [(0.45, .white), (0.5, .black)] {
            let color = Color(.sRGB, red: gray, green: gray, blue: gray)
            XCTAssertLessThan(color.wcagContrastRatio(with: .black), WCAGContrastLevel.AAA.minimumRatio)
            XCTAssertLessThan(color.wcagContrastRatio(with: .white), WCAGContrastLevel.AAA.minimumRatio)

            let result = color.accessibleContrastingColor(for: .AAA)

            XCTAssertEqual(result, expected)
            XCTAssertFalse(color.wcagCompliance(with: result).passesAAA)
            assertStrongestEndpoint(for: color, expected: expected)
        }
    }

    func testSuggestedColorKeepsItsExistingHeuristic() {
        let color = Color(.sRGB, red: 0.5, green: 0.5, blue: 0.5)

        for level in WCAGContrastLevel.allCases {
            XCTAssertEqual(color.suggestedColor(for: level), .white)
            XCTAssertEqual(color.accessibleContrastingColor(for: level), .black)
        }
    }

    private func assertStrongestEndpoint(
        for color: Color, expected: Color,
        file: StaticString = #filePath, line: UInt = #line
    ) {
        let blackRatio = color.wcagContrastRatio(with: .black)
        let whiteRatio = color.wcagContrastRatio(with: .white)
        XCTAssertEqual(color.accessibleContrastingColor(), expected, file: file, line: line)
        for level in WCAGContrastLevel.allCases {
            let result = color.accessibleContrastingColor(for: level)

            XCTAssertEqual(result, expected, "Level: \(level)", file: file, line: line)
            XCTAssertEqual(color.wcagContrastRatio(with: result), max(blackRatio, whiteRatio), file: file, line: line)
        }
    }
}
