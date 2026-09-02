import SwiftUI
import XCTest

@testable import ColorKit

final class LABResolutionTests: XCTestCase {
    func testEquivalentRGBRepresentationsProduceEquivalentLAB() throws {
        let reference = try fixedTestColor(components: [0.2, 0.4, 0.6, 0.5])
        let source = try XCTUnwrap(reference.cgColor)
        let expected = try XCTUnwrap(reference.labComponents())

        for name in [CGColorSpace.linearSRGB, CGColorSpace.extendedLinearSRGB, CGColorSpace.displayP3] {
            let space = try XCTUnwrap(CGColorSpace(name: name))
            let represented = try XCTUnwrap(
                source.converted(to: space, intent: .relativeColorimetric, options: nil)
            )
            let components = try XCTUnwrap(represented.components)
            XCTAssertNotEqual(Array(components.prefix(3)), [0.2, 0.4, 0.6])

            let color = try fixedTestColor(space: space, components: components)
            try assertLABEqual(color.labComponents(), expected, accuracy: 0.001)
        }
    }

    func testEncodedAndLinearGrayscaleResolveToEquivalentSRGBLAB() throws {
        let encoded: CGFloat = 0.5370987304831942
        let encodedReference = try fixedTestColor(components: [0.5, 0.5, 0.5, 0.25])
        let linearReference = try fixedTestColor(components: [encoded, encoded, encoded, 0.25])
        let encodedLAB = try XCTUnwrap(encodedReference.labComponents())
        let linearLAB = try XCTUnwrap(linearReference.labComponents())

        for name in [CGColorSpace.genericGrayGamma2_2, CGColorSpace.extendedGray] {
            let color = try fixedTestColor(space: name, components: [0.5, 0.25])
            try assertLABEqual(color.labComponents(), encodedLAB, accuracy: 0.00001)
        }

        for name in [CGColorSpace.linearGray, CGColorSpace.extendedLinearGray] {
            let color = try fixedTestColor(space: name, components: [0.25, 0.25])
            try assertLABEqual(color.labComponents(), linearLAB, accuracy: 0.00001)
        }
    }

    func testDisplayP3OutsideSRGBGamutProducesUnclippedLAB() throws {
        let color = try fixedTestColor(space: CGColorSpace.displayP3, components: [1, 0, 0, 0.5])
        let snapshot = try XCTUnwrap(ResolvedSRGBA.resolve(color))
        XCTAssertFalse(snapshot.isInSRGBGamut)

        try assertLABEqual(color.labComponents(), expectedLAB(from: snapshot), accuracy: 0.00001)
    }

    func testFiniteExtendedRangeProducesUnclippedLAB() throws {
        for components: [CGFloat] in [
            [-0.25, 0.4, 0.6, 0.5],
            [1.25, 0.4, 0.6, 0.5]
        ] {
            let color = try fixedTestColor(space: CGColorSpace.extendedSRGB, components: components)
            let snapshot = try XCTUnwrap(ResolvedSRGBA.resolve(color))
            XCTAssertFalse(snapshot.isInSRGBGamut)

            try assertLABEqual(color.labComponents(), expectedLAB(from: snapshot), accuracy: 0.00001)
        }
    }

    func testNonfiniteSourceAndOverflowingLABRemainUnavailable() throws {
        for value: CGFloat in [.nan, .infinity, -.infinity, .greatestFiniteMagnitude] {
            let color = try fixedTestColor(
                space: CGColorSpace.extendedSRGB,
                components: [value, 0.4, 0.6, 0.5]
            )
            XCTAssertNil(color.labComponents())
            XCTAssertNil(ColorCache.shared.getCachedLABComponents(for: color))
        }
    }

    func testAlphaDoesNotChangeLABCoordinates() throws {
        let colors = try [0, 0.5, 1].map { alpha in
            try fixedTestColor(components: [0.2, 0.4, 0.6, CGFloat(alpha)])
        }
        let expected = try XCTUnwrap(colors[0].labComponents())

        for color in colors.dropFirst() {
            try assertLABEqual(color.labComponents(), expected, accuracy: 0)
        }
    }

    func testDynamicSemanticPatternAndCMYKInputsRemainUnavailable() throws {
        #if canImport(AppKit)
        let dynamic = Color(NSColor(name: nil) { _ in .red })
        #else
        let dynamic = Color(UIColor { _ in .red })
        #endif
        let cmykSpace = CGColorSpaceCreateDeviceCMYK()
        let cmyk = try fixedTestColor(space: cmykSpace, components: [0.2, 0.4, 0.6, 0.1, 1])
        let colors = [dynamic, Color.primary, Color.secondary, try patternTestColor(), cmyk]

        for color in colors {
            XCTAssertNil(color.labComponents())
            XCTAssertNil(color.labString())
        }
    }

    func testConvertibleCacheIneligibleSourceStillProducesLABWithoutCaching() throws {
        let color = try fixedTestColor(space: CGColorSpace.adobeRGB1998, components: [0.5, 0.4, 0.6, 1])

        XCTAssertNotNil(color.labComponents())
        XCTAssertNil(ColorCache.shared.getCachedLABComponents(for: color))
    }

    private func expectedLAB(from snapshot: ResolvedSRGBA) -> (L: CGFloat, a: CGFloat, b: CGFloat) {
        let xyz = SRGBColorConversion.xyz(
            from: (Double(snapshot.red), Double(snapshot.green), Double(snapshot.blue))
        )
        let lab = SRGBColorConversion.lab(from: xyz)
        return (CGFloat(lab.l), CGFloat(lab.a), CGFloat(lab.b))
    }

    private func assertLABEqual(
        _ actual: (L: CGFloat, a: CGFloat, b: CGFloat)?,
        _ expected: (L: CGFloat, a: CGFloat, b: CGFloat),
        accuracy: CGFloat,
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws {
        let actual = try XCTUnwrap(actual, file: file, line: line)
        XCTAssertEqual(actual.L, expected.L, accuracy: accuracy, file: file, line: line)
        XCTAssertEqual(actual.a, expected.a, accuracy: accuracy, file: file, line: line)
        XCTAssertEqual(actual.b, expected.b, accuracy: accuracy, file: file, line: line)
    }
}
