import SwiftUI
import XCTest

@testable import ColorKit

final class ColorContrastResultTests: XCTestCase {
    // MARK: - Reference values

    /// Published WCAG contrast ratios that the un-linearized calculation could not produce.
    private static let referencePairs: [(hex: String, ratioWithWhite: Double)] = [
        ("#000000", 21.0),
        ("#595959", 7.0),
        ("#767676", 4.54),
        ("#008000", 5.14),
        ("#0000FF", 8.59),
        ("#FF0000", 3.998),
        ("#FFFFFF", 1.0)
    ]

    func testContrastRatioMatchesPublishedWCAGValues() throws {
        for (hex, expected) in Self.referencePairs {
            let color = try XCTUnwrap(Color(hex: hex))

            XCTAssertEqual(
                Double(color.contrastRatio(with: .white)),
                expected,
                accuracy: 0.01,
                "\(hex) against white"
            )
        }
    }

    func testRelativeLuminanceLinearizesComponents() throws {
        // Mid gray is 0.216 in linear light, not the 0.502 a gamma-encoded sum would give.
        let midGray = try XCTUnwrap(Color(hex: "#808080"))

        XCTAssertEqual(Double(midGray.relativeLuminance()), 0.2159, accuracy: 0.001)
    }

    func testRelativeLuminanceEndpoints() {
        XCTAssertEqual(Double(Color.black.relativeLuminance()), 0, accuracy: 1e-9)
        XCTAssertEqual(Double(Color.white.relativeLuminance()), 1, accuracy: 1e-9)
    }

    func testBlackOnWhiteIsTwentyOne() {
        XCTAssertEqual(Double(Color.black.contrastRatio(with: .white)), 21, accuracy: 1e-9)
    }

    func testContrastRatioIsSymmetric() throws {
        let first = try XCTUnwrap(Color(hex: "#3366CC"))
        let second = try XCTUnwrap(Color(hex: "#F0E68C"))

        XCTAssertEqual(first.contrastRatio(with: second), second.contrastRatio(with: first))
    }

    // MARK: - Dark color classification

    func testIsDarkColorUsesEqualContrastThreshold() throws {
        // Just below the threshold white contrasts better; just above it black does.
        let belowThreshold = try XCTUnwrap(Color(hex: "#757575"))
        let aboveThreshold = try XCTUnwrap(Color(hex: "#767676"))

        XCTAssertTrue(belowThreshold.isDarkColor())
        XCTAssertFalse(aboveThreshold.isDarkColor())
    }

    func testIsDarkColorAgreesWithStrongerEndpoint() {
        for step in 0...100 {
            let value = Double(step) / 100
            let color = Color(.sRGB, red: value, green: value, blue: value)
            let whiteIsStronger = color.contrastRatio(with: .white) > color.contrastRatio(with: .black)

            XCTAssertEqual(color.isDarkColor(), whiteIsStronger, "gray \(value)")
        }
    }

    func testBlackAndWhiteClassification() {
        XCTAssertTrue(Color.black.isDarkColor())
        XCTAssertFalse(Color.white.isDarkColor())
    }

    // MARK: - Result API

    func testAvailableResultReportsRatioAndLuminances() throws {
        let foreground = try XCTUnwrap(Color(hex: "#595959"))

        guard case .available(let measurement) = foreground.contrastResult(with: .white) else {
            return XCTFail("Expected an available measurement")
        }

        XCTAssertEqual(measurement.ratio, 7.0, accuracy: 0.01)
        XCTAssertEqual(measurement.backgroundLuminance, 1, accuracy: 1e-9)
        XCTAssertEqual(measurement.foregroundLuminance, 0.1, accuracy: 0.01)
    }

    func testPassingLevelsReflectMeasuredRatio() throws {
        let foreground = try XCTUnwrap(Color(hex: "#595959"))

        guard case .available(let measurement) = foreground.contrastResult(with: .white) else {
            return XCTFail("Expected an available measurement")
        }

        XCTAssertEqual(Set(measurement.passingLevels), Set(WCAGContrastLevel.allCases))
    }

    func testPassingLevelsCanBeEmptyWithoutBeingUnavailable() {
        let result = Color.white.contrastResult(with: .white)

        guard case .available(let measurement) = result else {
            return XCTFail("Expected an available measurement")
        }

        XCTAssertEqual(measurement.ratio, 1, accuracy: 1e-9)
        XCTAssertTrue(measurement.passingLevels.isEmpty)
    }

    func testUnresolvedForegroundIsDiagnosedIndependently() {
        guard case .unavailable(let issues) = Color.primary.contrastResult(with: .white) else {
            return XCTFail("Expected an unavailable measurement")
        }

        XCTAssertEqual(issues.foreground, [.unresolved])
        XCTAssertTrue(issues.background.isEmpty)
    }

    func testUnresolvedBackgroundIsDiagnosedIndependently() {
        guard case .unavailable(let issues) = Color.white.contrastResult(with: .primary) else {
            return XCTFail("Expected an unavailable measurement")
        }

        XCTAssertTrue(issues.foreground.isEmpty)
        XCTAssertEqual(issues.background, [.unresolved])
    }

    func testBothInputsAreDiagnosedWithoutHidingEachOther() {
        guard case .unavailable(let issues) = Color.primary.contrastResult(with: .primary) else {
            return XCTFail("Expected an unavailable measurement")
        }

        XCTAssertEqual(issues.foreground, [.unresolved])
        XCTAssertEqual(issues.background, [.unresolved])
    }

    func testTranslucentBackgroundIsUnavailable() {
        let background = Color(.sRGB, red: 1, green: 1, blue: 1, opacity: 0.5)

        guard case .unavailable(let issues) = Color.black.contrastResult(with: background) else {
            return XCTFail("Expected an unavailable measurement")
        }

        XCTAssertEqual(issues.background, [.translucentBackground])
    }

    func testTranslucentForegroundIsCompositedRatherThanRejected() {
        let foreground = Color(.sRGB, red: 0, green: 0, blue: 0, opacity: 0.5)

        guard case .available(let measurement) = foreground.contrastResult(with: .white) else {
            return XCTFail("Expected an available measurement")
        }

        // Half-strength black over white composites to 0.5 in nonlinear sRGB.
        let composited = Color(.sRGB, red: 0.5, green: 0.5, blue: 0.5)
        XCTAssertEqual(
            measurement.ratio,
            Double(composited.contrastRatio(with: .white)),
            accuracy: 1e-9
        )
    }

    func testOutOfGamutInputIsNotClampedIntoEligibility() {
        let wide = Color(.displayP3, red: 1, green: 0, blue: 0)

        guard case .unavailable(let issues) = wide.contrastResult(with: .white) else {
            return XCTFail("Expected an unavailable measurement")
        }

        XCTAssertEqual(issues.foreground, [.outOfSRGBGamut])
    }

    func testUnavailableResultHasNoRatio() {
        XCTAssertNil(Color.primary.contrastResult(with: .white).ratio)
    }

    func testAvailableResultExposesRatioAccessor() throws {
        let result = Color.black.contrastResult(with: .white)

        XCTAssertEqual(try XCTUnwrap(result.ratio), 21, accuracy: 1e-9)
    }

    // MARK: - Luminance value API

    func testRelativeLuminanceValueIsNilForUnresolvableColor() {
        XCTAssertNil(Color.primary.relativeLuminanceValue())
    }

    func testRelativeLuminanceValueDistinguishesUnavailableFromBlack() throws {
        XCTAssertEqual(try XCTUnwrap(Color.black.relativeLuminanceValue()), 0, accuracy: 1e-9)
        XCTAssertNil(Color.primary.relativeLuminanceValue())

        // Primary resolves for the current appearance in the lenient accessor.
        // Only a color that cannot resolve at all shares black's zero fallback.
        let unresolved = unresolvableTestColor()
        XCTAssertNil(unresolved.relativeLuminanceValue())
        XCTAssertEqual(unresolved.relativeLuminance(), 0)
        XCTAssertEqual(Color.black.relativeLuminance(), 0)
    }

    func testRelativeLuminanceValueAgreesWithNonOptionalAccessor() throws {
        for (hex, _) in Self.referencePairs {
            let color = try XCTUnwrap(Color(hex: hex))
            let value = try XCTUnwrap(color.relativeLuminanceValue())

            XCTAssertEqual(Double(color.relativeLuminance()), value, accuracy: 1e-12, hex)
        }
    }

    // MARK: - Cross-API agreement

    func testAgreesWithStrictAccessibilityResult() throws {
        let pairs: [(foreground: String, background: String)] = [
            ("#595959", "#FFFFFF"),
            ("#767676", "#FFFFFF"),
            ("#0000FF", "#FFFFFF"),
            ("#FFFFFF", "#000000")
        ]

        for (foregroundHex, backgroundHex) in pairs {
            let foreground = try XCTUnwrap(Color(hex: foregroundHex))
            let background = try XCTUnwrap(Color(hex: backgroundHex))

            let result = foreground.accessibilityResult(against: background, targetLevel: .AA)
            let measured = try XCTUnwrap(foreground.contrastResult(with: background).ratio)

            XCTAssertEqual(try XCTUnwrap(result.contrastRatio), measured, accuracy: 1e-9)
        }
    }

    func testAvailabilityAgreesWithStrictAccessibilityResult() {
        // Both result APIs derive from one strict measurement, so they never disagree
        // about whether a pair can be measured.
        let pairs: [(foreground: Color, background: Color)] = [
            (.primary, .white),
            (.white, .primary),
            (.primary, .primary),
            (Color(.displayP3, red: 1, green: 0, blue: 0), .white),
            (.black, Color(.sRGB, red: 1, green: 1, blue: 1, opacity: 0.5)),
            (.blue, .white)
        ]

        for (foreground, background) in pairs {
            XCTAssertNil(foreground.contrastResult(with: background).ratio)
            XCTAssertNil(foreground.accessibilityResult(against: background).contrastRatio)
        }
    }

    func testAgreesWithWCAGContrastRatioForResolvableColors() throws {
        for (hex, _) in Self.referencePairs {
            let color = try XCTUnwrap(Color(hex: hex))

            XCTAssertEqual(
                Double(color.contrastRatio(with: .white)),
                color.wcagContrastRatio(with: .white),
                accuracy: 1e-9,
                hex
            )
        }
    }
}
