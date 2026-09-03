import SwiftUI
import XCTest

@testable import ColorKit

/// Covers how blending and interpolation resolve their operands, rather than the
/// blend and interpolation formulas themselves.
final class BlendResolutionTests: XCTestCase {
    override func setUp() {
        super.setUp()
        ColorCache.shared.clearCache()
    }

    override func tearDown() {
        ColorCache.shared.clearCache()
        super.tearDown()
    }

    // MARK: - Grayscale operands

    func testGrayscaleMultipliedByBlackIsBlack() throws {
        let gray = try fixedTestColor(space: CGColorSpace.genericGrayGamma2_2, components: [0.5, 1])

        let blended = gray.blended(with: .black, mode: .multiply)

        // Multiplying by black darkens to black; the operand was previously returned unchanged.
        let components = try XCTUnwrap(blended.cgColor?.components)
        XCTAssertEqual(components[0], 0, accuracy: 1e-6)
        XCTAssertEqual(components[1], 0, accuracy: 1e-6)
        XCTAssertEqual(components[2], 0, accuracy: 1e-6)
    }

    func testGrayscaleMultipliedByWhiteKeepsItsResolvedValue() throws {
        let gray = try fixedTestColor(space: CGColorSpace.genericGrayGamma2_2, components: [0.5, 1])
        let resolved = try XCTUnwrap(ResolvedSRGBA.resolve(gray))

        let blended = gray.blended(with: .white, mode: .multiply)

        let components = try XCTUnwrap(blended.cgColor?.components)
        XCTAssertEqual(components[0], resolved.red, accuracy: 1e-6)
        XCTAssertEqual(components[1], resolved.green, accuracy: 1e-6)
        XCTAssertEqual(components[2], resolved.blue, accuracy: 1e-6)
    }

    func testGrayscaleInterpolationIsNotANoOp() throws {
        let gray = try fixedTestColor(space: CGColorSpace.genericGrayGamma2_2, components: [0.25, 1])
        let resolved = try XCTUnwrap(ResolvedSRGBA.resolve(gray))

        let interpolated = gray.interpolated(with: .white, amount: 0.5)

        let components = try XCTUnwrap(interpolated.cgColor?.components)
        XCTAssertEqual(components[0], (resolved.red + 1) / 2, accuracy: 1e-6)
        XCTAssertEqual(components[1], (resolved.green + 1) / 2, accuracy: 1e-6)
        XCTAssertEqual(components[2], (resolved.blue + 1) / 2, accuracy: 1e-6)
    }

    func testGrayscaleResolvesThroughItsColorSpaceRatherThanItsRawComponent() throws {
        // Generic gray 0.5 is not sRGB 0.5; reading the raw component would use 0.5 directly.
        let gray = Color(CGColor(gray: 0.5, alpha: 1))
        let resolved = try XCTUnwrap(ResolvedSRGBA.resolve(gray))

        XCTAssertNotEqual(resolved.red, 0.5, accuracy: 1e-3)

        let blended = gray.blended(with: .white, mode: .multiply)
        let components = try XCTUnwrap(blended.cgColor?.components)

        XCTAssertEqual(components[0], resolved.red, accuracy: 1e-6)
        XCTAssertNotEqual(components[0], 0.5, accuracy: 1e-3)
    }

    // MARK: - Wider-gamut operands

    func testWideGamutOperandIsConvertedRatherThanReadAsSRGB() {
        let p3Red = Color(.displayP3, red: 1, green: 0, blue: 0)
        let sRGBRed = Color(.sRGB, red: 1, green: 0, blue: 0)

        let blendedP3 = p3Red.blended(with: .white, mode: .multiply)
        let blendedSRGB = sRGBRed.blended(with: .white, mode: .multiply)

        // These were previously identical because P3 components were read as sRGB.
        XCTAssertNotEqual(
            blendedP3.cgColor?.components,
            blendedSRGB.cgColor?.components
        )
    }

    func testWideGamutOperandKeepsItsExtendedComponents() throws {
        let p3Red = Color(.displayP3, red: 1, green: 0, blue: 0)
        let resolved = try XCTUnwrap(ResolvedSRGBA.resolve(p3Red))
        XCTAssertFalse(resolved.isInSRGBGamut)

        let blended = p3Red.blended(with: .white, mode: .multiply)

        // Multiplying by white is the identity, so the extended value survives unclamped.
        let components = try XCTUnwrap(blended.cgColor?.components)
        XCTAssertEqual(components[0], resolved.red, accuracy: 1e-5)
        XCTAssertGreaterThan(components[0], 1)
    }

    func testWideGamutInterpolationDiffersFromSRGBInterpolation() {
        let p3Red = Color(.displayP3, red: 1, green: 0, blue: 0)
        let sRGBRed = Color(.sRGB, red: 1, green: 0, blue: 0)

        let fromP3 = p3Red.interpolated(with: .white, amount: 0.5)
        let fromSRGB = sRGBRed.interpolated(with: .white, amount: 0.5)

        XCTAssertNotEqual(fromP3.cgColor?.components, fromSRGB.cgColor?.components)
    }

    // MARK: - Unresolvable operands

    func testUnresolvableOperandStillReturnsTheReceiver() {
        // Dynamic colors have no fixed components, so blending has nothing to combine.
        XCTAssertEqual(Color.primary.blended(with: .black, mode: .multiply), Color.primary)
        XCTAssertEqual(Color.black.blended(with: .primary, mode: .multiply), Color.black)
        XCTAssertEqual(Color.primary.interpolated(with: .black, amount: 0.5), Color.primary)
    }

    // MARK: - Existing behavior preserved

    func testSRGBBlendingIsUnchanged() throws {
        let base = try fixedTestColor(components: [0.8, 0.1, 0.2, 1])
        let blend = try fixedTestColor(components: [0.1, 0.6, 0.9, 1])

        let blended = base.blended(with: blend, mode: .multiply)

        let components = try XCTUnwrap(blended.cgColor?.components)
        XCTAssertEqual(components[0], 0.8 * 0.1, accuracy: 1e-5)
        XCTAssertEqual(components[1], 0.1 * 0.6, accuracy: 1e-5)
        XCTAssertEqual(components[2], 0.2 * 0.9, accuracy: 1e-5)
    }

    func testBlendPreservesReceiverOpacity() throws {
        let base = try fixedTestColor(components: [0.8, 0.1, 0.2, 0.4])

        let blended = base.blended(with: .white, mode: .multiply)

        let components = try XCTUnwrap(blended.cgColor?.components)
        XCTAssertEqual(try XCTUnwrap(components.last), 0.4, accuracy: 1e-6)
    }

    func testZeroAmountReturnsReceiverUnchanged() throws {
        let base = try fixedTestColor(components: [0.8, 0.1, 0.2, 1])

        XCTAssertEqual(base.blended(with: .white, mode: .multiply, amount: 0), base)
    }
}
