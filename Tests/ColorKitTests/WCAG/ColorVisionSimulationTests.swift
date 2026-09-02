import CoreGraphics
import SwiftUI
import XCTest

@testable import ColorKit

final class ColorVisionSimulationTests: XCTestCase {
    func testMachadoSeverityOneFixtures() throws {
        for fixture in Self.fixtures {
            let input = try fixedTestColor(components: fixture.input)
            let simulated = try XCTUnwrap(input.simulated(for: fixture.deficiency), fixture.name)
            assertComponents(of: simulated, equalTo: fixture.expected)
        }
    }

    func testSimulationRejectsColorsWithoutAnInGamutSRGBSnapshot() throws {
        XCTAssertNil(Color.primary.simulated(for: .protanopia))
        XCTAssertNil(try patternTestColor().simulated(for: .deuteranopia))
        XCTAssertNil(
            try fixedTestColor(
                space: try XCTUnwrap(CGColorSpace(name: CGColorSpace.extendedSRGB)),
                components: [1.2, 0, 0, 1]
            ).simulated(for: .tritanopia)
        )
        XCTAssertNil(
            try fixedTestColor(
                space: try XCTUnwrap(CGColorSpace(name: CGColorSpace.extendedSRGB)),
                components: [.nan, 0, 0, 1]
            ).simulated(for: .protanopia)
        )
    }

    @MainActor
    func testAccessibilityLabSwatchRendersPublishedProtanopiaFixture() throws {
        guard #available(iOS 16.0, macOS 13.0, *) else {
            throw XCTSkip("ImageRenderer requires iOS 16 or macOS 13")
        }
        let input = try fixedTestColor(components: [1, 0, 0, 1])
        let swatch = AccessibilityLabSimulationSwatch(color: input, deficiency: .protanopia)

        XCTAssertEqual(try renderedPixel(of: swatch), [109, 95, 0, 255])
    }

    @MainActor
    func testLegacyArbitraryViewModifierLeavesRenderedContentUnchanged() throws {
        guard #available(iOS 16.0, macOS 13.0, *) else {
            throw XCTSkip("ImageRenderer requires iOS 16 or macOS 13")
        }
        let input = try fixedTestColor(components: [1, 0, 0, 1])
        let view = Rectangle()
            .foregroundColor(input)
            .colorBlindnessPreview(type: .deuteranopia)

        XCTAssertEqual(try renderedPixel(of: view), [255, 0, 0, 255])
    }

    private func assertComponents(
        of color: Color,
        equalTo expected: [CGFloat],
        accuracy: CGFloat = 0.000001,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        guard let actual = ResolvedSRGBA.resolve(color) else {
            return XCTFail("Expected a fixed sRGB color", file: file, line: line)
        }
        for (actualComponent, expectedComponent) in zip(
            [actual.red, actual.green, actual.blue, actual.alpha],
            expected
        ) {
            XCTAssertEqual(actualComponent, expectedComponent, accuracy: accuracy, file: file, line: line)
        }
    }

    @available(iOS 16.0, macOS 13.0, *)
    @MainActor
    private func renderedPixel(of view: some View) throws -> [UInt8] {
        let renderer = ImageRenderer(content: view.frame(width: 1, height: 1))
        renderer.scale = 1
        let image = try XCTUnwrap(renderer.cgImage)
        var pixel = [UInt8](repeating: 0, count: 4)
        try pixel.withUnsafeMutableBytes { bytes in
            let context = try XCTUnwrap(CGContext(
                data: bytes.baseAddress,
                width: 1,
                height: 1,
                bitsPerComponent: 8,
                bytesPerRow: 4,
                space: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
            ))
            context.draw(image, in: CGRect(x: 0, y: 0, width: 1, height: 1))
        }
        return pixel
    }

    private struct Fixture {
        let name: String
        let deficiency: ColorVisionDeficiency
        let input: [CGFloat]
        let expected: [CGFloat]
    }

    // Expected nonlinear-sRGB values were independently precomputed from the
    // Machado–Oliveira–Fernandes severity-1 matrices, not from production code.
    private static let fixtures: [Fixture] = [
        Fixture(name: "protanopia black", deficiency: .protanopia, input: [0, 0, 0, 1], expected: [0, 0, 0, 1]),
        Fixture(name: "protanopia white", deficiency: .protanopia, input: [1, 1, 1, 1], expected: [1, 1, 1, 1]),
        Fixture(name: "protanopia red", deficiency: .protanopia, input: [1, 0, 0, 1], expected: [0.426608472, 0.372654277, 0, 1]),
        Fixture(name: "protanopia green", deficiency: .protanopia, input: [0, 1, 0, 1], expected: [1, 0.899428066, 0, 1]),
        Fixture(name: "protanopia blue", deficiency: .protanopia, input: [0, 0, 1, 1], expected: [0, 0.347866826, 1, 1]),
        Fixture(name: "protanopia midtone", deficiency: .protanopia, input: [0.2, 0.4, 0.6, 1], expected: [0.312605538, 0.409837291, 0.608525882, 1]),
        Fixture(name: "protanopia alpha", deficiency: .protanopia, input: [0.8, 0.3, 0.1, 0.35], expected: [0.445466208, 0.392570615, 0.057814687, 0.35]),
        Fixture(name: "deuteranopia black", deficiency: .deuteranopia, input: [0, 0, 0, 1], expected: [0, 0, 0, 1]),
        Fixture(name: "deuteranopia white", deficiency: .deuteranopia, input: [1, 1, 1, 1], expected: [1, 0.999999560, 1, 1]),
        Fixture(name: "deuteranopia red", deficiency: .deuteranopia, input: [1, 0, 0, 1], expected: [0.640059555, 0.565806941, 0, 1]),
        Fixture(name: "deuteranopia green", deficiency: .deuteranopia, input: [0, 1, 0, 1], expected: [0.936051046, 0.839247735, 0.229191866, 1]),
        Fixture(name: "deuteranopia blue", deficiency: .deuteranopia, input: [0, 0, 1, 1], expected: [0, 0.241171359, 0.986194366, 1]),
        Fixture(name: "deuteranopia midtone", deficiency: .deuteranopia, input: [0.2, 0.4, 0.6, 1], expected: [0.257412495, 0.371448157, 0.596043244, 1]),
        Fixture(name: "deuteranopia alpha", deficiency: .deuteranopia, input: [0.8, 0.3, 0.1, 0.35], expected: [0.568074890, 0.505163404, 0.067684245, 0.35]),
        Fixture(name: "tritanopia black", deficiency: .tritanopia, input: [0, 0, 0, 1], expected: [0, 0, 0, 1]),
        Fixture(name: "tritanopia white", deficiency: .tritanopia, input: [1, 1, 1, 1], expected: [1, 1, 1, 1]),
        Fixture(name: "tritanopia red", deficiency: .tritanopia, input: [1, 0, 0, 1], expected: [1, 0, 0.058385974, 1]),
        Fixture(name: "tritanopia green", deficiency: .tritanopia, input: [0, 1, 0, 1], expected: [0, 0.968947521, 0.849616272, 1]),
        Fixture(name: "tritanopia blue", deficiency: .tritanopia, input: [0, 0, 1, 1], expected: [0, 0.420379986, 0.587278796, 1]),
        Fixture(name: "tritanopia midtone", deficiency: .tritanopia, input: [0.2, 0.4, 0.6, 1], expected: [0, 0.446844922, 0.471755956, 1]),
        Fixture(name: "tritanopia alpha", deficiency: .tritanopia, input: [0.8, 0.3, 0.1, 0.35], expected: [0.881193657, 0.161311660, 0.263710981, 0.35])
    ]
}
