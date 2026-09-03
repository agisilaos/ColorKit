import SwiftUI
import XCTest

@testable import ColorKit

/// Covers how `wcagContrastRatio(with:)` treats opacity, rather than its formula.
final class WCAGContrastOpacityTests: XCTestCase {
    override func setUp() {
        super.setUp()
        ColorCache.shared.clearCache()
    }

    override func tearDown() {
        ColorCache.shared.clearCache()
        super.tearDown()
    }

    func testFaintOverlayIsNotMeasuredAsFullySaturated() {
        let faint = Color(.sRGB, red: 0, green: 0, blue: 0, opacity: 0.1)

        // Previously 21:1, which certified a barely visible overlay as passing AAA.
        XCTAssertEqual(faint.wcagContrastRatio(with: .white), 1, accuracy: 1e-12)
    }

    func testFaintOverlayDoesNotPassAnyLevel() {
        let faint = Color(.sRGB, red: 0, green: 0, blue: 0, opacity: 0.1)

        let compliance = faint.wcagCompliance(with: .white)

        XCTAssertTrue(compliance.passes.isEmpty)
    }

    func testTranslucentInputIsDeclinedInBothOrderings() {
        let translucent = Color(.sRGB, red: 0, green: 0, blue: 0, opacity: 0.5)

        // The ratio stays symmetric, so neither ordering measures an unsupplied backdrop.
        XCTAssertEqual(translucent.wcagContrastRatio(with: .white), 1, accuracy: 1e-12)
        XCTAssertEqual(Color.white.wcagContrastRatio(with: translucent), 1, accuracy: 1e-12)
    }

    func testDeclinedRatioIsStableAcrossCallOrderAndCacheWarmth() {
        let translucent = Color(.sRGB, red: 0, green: 0, blue: 0, opacity: 0.5)

        for _ in 0..<2 {
            XCTAssertEqual(Color.white.wcagContrastRatio(with: translucent), 1, accuracy: 1e-12)
            XCTAssertEqual(translucent.wcagContrastRatio(with: .white), 1, accuracy: 1e-12)
            XCTAssertEqual(Color.black.wcagContrastRatio(with: .white), 21, accuracy: 1e-9)
        }
    }

    func testOpaqueRatiosAreUnchanged() throws {
        let cases: [(hex: String, expected: Double)] = [
            ("#000000", 21.0),
            ("#595959", 7.0),
            ("#767676", 4.54),
            ("#FFFFFF", 1.0)
        ]

        for (hex, expected) in cases {
            let color = try XCTUnwrap(Color(hex: hex))

            XCTAssertEqual(color.wcagContrastRatio(with: .white), expected, accuracy: 0.01, hex)
        }
    }

    func testCompositingIsAvailableThroughTheResultAPI() {
        let faint = Color(.sRGB, red: 0, green: 0, blue: 0, opacity: 0.1)

        // The honest measurement still exists; it requires an explicit opaque background.
        guard case .available(let measurement) = faint.contrastResult(with: .white) else {
            return XCTFail("Expected an available measurement")
        }

        XCTAssertEqual(measurement.ratio, 1.2538, accuracy: 0.001)
    }
}
