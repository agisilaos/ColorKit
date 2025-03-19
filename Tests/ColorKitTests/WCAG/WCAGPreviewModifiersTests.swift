import SwiftUI
import XCTest

@testable import ColorKit

final class WCAGPreviewModifiersTests: XCTestCase {
    @MainActor
    func testWCAGComplianceModifier() throws {
        let foregroundColor = Color.blue
        let backgroundColor = Color.white
        let showDetails = true

        let modifier = WCAGComplianceModifier(
            foreground: foregroundColor,
            background: backgroundColor,
            showDetails: showDetails
        )

        // Test that the modifier can be created with various parameters
        XCTAssertNotNil(modifier)

        // Test with different show details values
        let modifierWithoutDetails = WCAGComplianceModifier(
            foreground: foregroundColor,
            background: backgroundColor,
            showDetails: false
        )
        XCTAssertNotNil(modifierWithoutDetails)
    }

    @MainActor
    func testColorBlindnessPreviewModifier() throws {
        // Test each type of color blindness
        let types = ColorBlindnessPreviewModifier.ColorBlindnessType.allCases
        for type in types {
            let modifier = ColorBlindnessPreviewModifier(type: type)
            XCTAssertNotNil(modifier)
        }
    }

    func testColorBlindnessTypes() throws {
        // Test that all expected types are available
        let types = ColorBlindnessPreviewModifier.ColorBlindnessType.allCases
        XCTAssertEqual(types.count, 5) // normal, protanopia, deuteranopia, tritanopia, achromatopsia

        // Test specific types
        let normal = ColorBlindnessPreviewModifier.ColorBlindnessType.normal
        let protanopia = ColorBlindnessPreviewModifier.ColorBlindnessType.protanopia
        let deuteranopia = ColorBlindnessPreviewModifier.ColorBlindnessType.deuteranopia
        let tritanopia = ColorBlindnessPreviewModifier.ColorBlindnessType.tritanopia
        let achromatopsia = ColorBlindnessPreviewModifier.ColorBlindnessType.achromatopsia

        XCTAssertTrue(types.contains(normal))
        XCTAssertTrue(types.contains(protanopia))
        XCTAssertTrue(types.contains(deuteranopia))
        XCTAssertTrue(types.contains(tritanopia))
        XCTAssertTrue(types.contains(achromatopsia))

        // Test raw values
        XCTAssertEqual(normal.rawValue, "Normal Vision")
        XCTAssertEqual(protanopia.rawValue, "Protanopia (Red-Blind)")
        XCTAssertEqual(deuteranopia.rawValue, "Deuteranopia (Green-Blind)")
        XCTAssertEqual(tritanopia.rawValue, "Tritanopia (Blue-Blind)")
        XCTAssertEqual(achromatopsia.rawValue, "Achromatopsia (No Color)")
    }

    func testColorEffect() throws {
        // Test identity matrix
        let identity = ColorEffect.identity
        XCTAssertEqual(identity.matrix.count, 20)
        XCTAssertEqual(identity.matrix[0], 1) // First diagonal element should be 1
        XCTAssertEqual(identity.matrix[5], 1) // Second diagonal element should be 1
        XCTAssertEqual(identity.matrix[10], 1) // Third diagonal element should be 1
        XCTAssertEqual(identity.matrix[15], 1) // Fourth diagonal element should be 1

        // Test protanopia matrix
        let protanopia = ColorEffect.protanopia
        XCTAssertEqual(protanopia.matrix.count, 20)
        XCTAssertEqual(protanopia.matrix[0], 0.567, accuracy: 0.001)
        XCTAssertEqual(protanopia.matrix[1], 0.433, accuracy: 0.001)

        // Test deuteranopia matrix
        let deuteranopia = ColorEffect.deuteranopia
        XCTAssertEqual(deuteranopia.matrix.count, 20)
        XCTAssertEqual(deuteranopia.matrix[0], 0.625, accuracy: 0.001)
        XCTAssertEqual(deuteranopia.matrix[1], 0.375, accuracy: 0.001)

        // Test tritanopia matrix
        let tritanopia = ColorEffect.tritanopia
        XCTAssertEqual(tritanopia.matrix.count, 20)
        XCTAssertEqual(tritanopia.matrix[0], 0.95, accuracy: 0.001)
        XCTAssertEqual(tritanopia.matrix[1], 0.05, accuracy: 0.001)

        // Test grayscale matrix
        let grayscale = ColorEffect.grayscale
        XCTAssertEqual(grayscale.matrix.count, 20)
        XCTAssertEqual(grayscale.matrix[0], 0.299, accuracy: 0.001)
        XCTAssertEqual(grayscale.matrix[1], 0.587, accuracy: 0.001)
        XCTAssertEqual(grayscale.matrix[2], 0.114, accuracy: 0.001)
    }

    @MainActor
    func testViewExtensions() throws {
        let view = Text("Test")

        // Test WCAG compliance modifier
        let wcagView = view.wcagCompliance(foreground: .blue, background: .white)
        XCTAssertNotNil(wcagView)

        // Test color blindness preview modifier
        let colorBlindView = view.colorBlindnessPreview(type: ColorBlindnessPreviewModifier.ColorBlindnessType.protanopia)
        XCTAssertNotNil(colorBlindView)

        // Test color effect modifier
        let effectView = view.colorEffect(ColorEffect.identity)
        XCTAssertNotNil(effectView)
    }
}
