import SwiftUI
import XCTest

@testable import ColorKit

@MainActor
final class ColorInspectorPresentationTests: XCTestCase {
    private let red = Color(.sRGB, red: 1, green: 0, blue: 0)
    private let blue = Color(.sRGB, red: 0, green: 0, blue: 1)
    private let black = Color(.sRGB, red: 0, green: 0, blue: 0)
    private let white = Color(.sRGB, red: 1, green: 1, blue: 1)

    func testInitialPresentationUsesInputsWithoutAppearanceCallbacks() throws {
        let presentation = ColorInspectorView(color: red).presentation

        XCTAssertEqual(presentation.hexValue, "#FF0000FF")
        XCTAssertEqual(presentation.rgbText, "R: 255, G: 0, B: 0")
        XCTAssertEqual(presentation.hslText, "H: 0°, S: 100%, L: 50%")
        XCTAssertEqual(try XCTUnwrap(presentation.contrast.ratio), 3.9984767707539985, accuracy: 1e-12)
        XCTAssertEqual(presentation.contrast.ratioText, "Ratio: 4.00")
    }

    func testContrastVisibilityChangesWithoutColorChanges() {
        var inspector = ColorInspectorView(color: black, backgroundColor: white, showContrastInfo: false)
        XCTAssertEqual(inspector.presentation.contrast, .hidden)

        inspector = ColorInspectorView(color: black, backgroundColor: white, showContrastInfo: true)
        XCTAssertEqual(inspector.presentation.contrast, .available(ratio: 21))

        inspector = ColorInspectorView(color: black, backgroundColor: white, showContrastInfo: false)
        XCTAssertEqual(inspector.presentation.contrast, .hidden)
    }

    func testForegroundChangesWhileContrastIsVisible() throws {
        var inspector = ColorInspectorView(color: red, backgroundColor: white)
        let original = inspector.presentation

        inspector = ColorInspectorView(color: blue, backgroundColor: white)
        let updated = inspector.presentation

        XCTAssertEqual(updated.hexValue, "#0000FFFF")
        XCTAssertEqual(updated.rgbText, "R: 0, G: 0, B: 255")
        XCTAssertEqual(updated.hslText, "H: 240°, S: 100%, L: 50%")
        XCTAssertEqual(try XCTUnwrap(updated.contrast.ratio), 8.592471358428805, accuracy: 1e-12)
        XCTAssertEqual(original.hexValue, "#FF0000FF")
        XCTAssertNotEqual(original.contrast, updated.contrast)
    }

    func testBackgroundChangesWhileContrastIsVisible() {
        var inspector = ColorInspectorView(color: black, backgroundColor: white)
        XCTAssertEqual(inspector.presentation.contrast, .available(ratio: 21))

        inspector = ColorInspectorView(color: black, backgroundColor: black)
        XCTAssertEqual(inspector.presentation.contrast, .available(ratio: 1))
        XCTAssertEqual(inspector.presentation.hexValue, "#000000FF")
    }

    func testInputsChangedWhileHiddenAreUsedWhenContrastIsShown() {
        var inspector = ColorInspectorView(color: black, backgroundColor: white)
        XCTAssertEqual(inspector.presentation.contrast, .available(ratio: 21))

        inspector = ColorInspectorView(color: black, backgroundColor: white, showContrastInfo: false)
        XCTAssertEqual(inspector.presentation.contrast, .hidden)

        inspector = ColorInspectorView(color: red, backgroundColor: white, showContrastInfo: false)
        XCTAssertEqual(inspector.presentation.hexValue, "#FF0000FF")
        XCTAssertEqual(inspector.presentation.contrast, .hidden)

        inspector = ColorInspectorView(color: red, backgroundColor: red, showContrastInfo: false)
        XCTAssertEqual(inspector.presentation.contrast, .hidden)

        inspector = ColorInspectorView(color: red, backgroundColor: red)
        XCTAssertEqual(inspector.presentation.contrast, .available(ratio: 1))
    }

    func testForegroundConversionFailureDoesNotRetainEarlierFields() {
        var inspector = ColorInspectorView(color: red, backgroundColor: white)
        XCTAssertNotNil(inspector.presentation.hexValue)
        XCTAssertNotNil(inspector.presentation.contrast.ratio)
        XCTAssertNil(Color.primary.cgColor, "The failure fixture must not expose fixed components")

        inspector = ColorInspectorView(color: .primary, backgroundColor: white)
        let unavailable = inspector.presentation

        XCTAssertNil(unavailable.hexValue)
        XCTAssertNil(unavailable.rgbValues)
        XCTAssertNil(unavailable.hslValues)
        XCTAssertEqual(unavailable.rgbText, "Unavailable")
        XCTAssertEqual(unavailable.hslText, "Unavailable")
        XCTAssertEqual(unavailable.contrast, .unavailable)
        XCTAssertNil(unavailable.contrast.ratio)
        XCTAssertEqual(unavailable.contrast.ratioText, "Ratio: Unavailable")

        inspector = ColorInspectorView(color: blue, backgroundColor: blue)
        XCTAssertEqual(inspector.presentation.hexValue, "#0000FFFF")
        XCTAssertEqual(inspector.presentation.rgbText, "R: 0, G: 0, B: 255")
        XCTAssertEqual(inspector.presentation.hslText, "H: 240°, S: 100%, L: 50%")
        XCTAssertEqual(inspector.presentation.contrast, .available(ratio: 1))
    }

    func testBackgroundConversionFailurePreservesForegroundInformation() {
        var inspector = ColorInspectorView(color: red, backgroundColor: white)
        XCTAssertNotNil(inspector.presentation.contrast.ratio)

        inspector = ColorInspectorView(color: red, backgroundColor: .primary)
        let unavailable = inspector.presentation

        XCTAssertEqual(unavailable.hexValue, "#FF0000FF")
        XCTAssertEqual(unavailable.rgbText, "R: 255, G: 0, B: 0")
        XCTAssertEqual(unavailable.hslText, "H: 0°, S: 100%, L: 50%")
        XCTAssertEqual(unavailable.contrast, .unavailable)
        XCTAssertNil(unavailable.contrast.ratio)

        inspector = ColorInspectorView(color: red, backgroundColor: red)
        XCTAssertEqual(inspector.presentation.contrast, .available(ratio: 1))
    }

    func testConversionFailureWhileHiddenRemainsUnavailableWhenShown() {
        var inspector = ColorInspectorView(color: red, backgroundColor: white)
        XCTAssertNotNil(inspector.presentation.contrast.ratio)

        inspector = ColorInspectorView(color: .primary, backgroundColor: white, showContrastInfo: false)
        XCTAssertNil(inspector.presentation.rgbValues)
        XCTAssertNil(inspector.presentation.hslValues)
        XCTAssertEqual(inspector.presentation.contrast, .hidden)

        inspector = ColorInspectorView(color: .primary, backgroundColor: white)
        XCTAssertEqual(inspector.presentation.contrast, .unavailable)
        XCTAssertNil(inspector.presentation.hexValue)
    }

    func testGrayscaleHexIsAvailableWithoutMigratingOtherInspectorFields() throws {
        let color = Color(CGColor(gray: 0.5, alpha: 1))
        XCTAssertEqual(try XCTUnwrap(color.cgColor?.components).count, 2)

        let presentation = ColorInspectorView(color: color, backgroundColor: white).presentation

        XCTAssertNotNil(presentation.hexValue)
        XCTAssertNil(presentation.rgbValues)
        XCTAssertNil(presentation.hslValues)
        XCTAssertEqual(presentation.contrast, .unavailable)
    }

    func testFormattingPreservesRoundingAndTruncation() {
        let color = Color(.sRGB, red: 0.5, green: 0.25, blue: 0.75, opacity: 0.5)
        let presentation = ColorInspectorView(color: color).presentation

        XCTAssertEqual(presentation.hexValue, "#8040BF80")
        XCTAssertEqual(presentation.rgbText, "R: 127, G: 63, B: 191")
        XCTAssertEqual(presentation.hslText, "H: 270°, S: 50%, L: 50%")
    }

    func testContrastPreservesLegacyTransferFunctionAndIgnoresAlpha() throws {
        let cases: [(component: Double, ratio: Double)] = [
            (0.02, 20.36936936936937),
            (0.04, 19.775687361166366),
            (0.5, 3.976653024912438)
        ]

        for (component, expectedRatio) in cases {
            let color = Color(.sRGB, red: component, green: component, blue: component, opacity: 0.25)
            let presentation = ColorInspectorView(color: color, backgroundColor: white).presentation
            let reversed = ColorInspectorView(color: white, backgroundColor: color).presentation

            // SwiftUI rounds these input components to Float precision.
            XCTAssertEqual(try XCTUnwrap(presentation.contrast.ratio), expectedRatio, accuracy: 1e-7)
            XCTAssertEqual(reversed.contrast, presentation.contrast)
        }
    }
}
