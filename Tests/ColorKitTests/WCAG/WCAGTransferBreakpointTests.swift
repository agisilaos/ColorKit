import SwiftUI
import XCTest

@testable import ColorKit

final class WCAGTransferBreakpointTests: XCTestCase {
    func testRelativeLuminanceUsesCurrentSRGBLinearSegment() throws {
        let color = Color(.sRGB, red: 0.04, green: 0.04, blue: 0.04)
        let components = try XCTUnwrap(ResolvedSRGBA.resolve(color))
        let expected = Double(components.red) / 12.92

        XCTAssertEqual(try XCTUnwrap(color.relativeLuminanceValue()), expected, accuracy: 1e-12)
        XCTAssertEqual(color.wcagRelativeLuminance(), color.rgbaComponents().red / 12.92, accuracy: 1e-12)
    }

    func testFloatingPointPairBelowAAIsNotClassifiedAsPassing() throws {
        let foreground = Color(.sRGB, red: 0.04, green: 0.04, blue: 0.04)
        let backgroundValue = 0.47188030163064804
        let background = Color(.sRGB, red: backgroundValue, green: backgroundValue, blue: backgroundValue)
        let first = try XCTUnwrap(ResolvedSRGBA.resolve(foreground))
        let second = try XCTUnwrap(ResolvedSRGBA.resolve(background))
        // Independently calculate the current W3C sRGB branches from the stored channels.
        let foregroundLuminance = Double(first.red) / 12.92
        let backgroundLuminance = pow((Double(second.red) + 0.055) / 1.055, 2.4)
        let expected = (backgroundLuminance + 0.05) / (foregroundLuminance + 0.05)
        let result = foreground.accessibilityResult(against: background, targetLevel: .AA)

        XCTAssertLessThan(expected, WCAGContrastLevel.AA.minimumRatio)
        XCTAssertEqual(try XCTUnwrap(result.contrastRatio), expected, accuracy: 1e-12)
        XCTAssertFalse(result.meetsTarget)
        XCTAssertEqual(result.status, .bestEffort)
    }
}
