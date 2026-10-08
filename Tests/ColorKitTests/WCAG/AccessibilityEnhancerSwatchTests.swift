import SwiftUI
import XCTest

@testable import ColorKit

@MainActor
final class AccessibilityEnhancerSwatchTests: XCTestCase {
    func testComparisonAndVariantTextRendersAgainstTheAssessedBackground() throws {
        let original = Color(.sRGB, red: 0, green: 0.478, blue: 1)
        let enhanced = original.enhancementResult(with: .white).color
        for foreground in [original, enhanced] {
            try assertVisibleText(foreground: foreground, width: 120, height: 80, text: "Text")
        }
        try assertVisibleText(foreground: .black, width: 100, height: 70, text: "Aa")
    }

    func testTranslucentSampleUsesOneForegroundLayer() throws {
        let foreground = Color(.sRGB, red: 0, green: 0, blue: 0, opacity: 0.5)
        try assertVisibleText(foreground: foreground, width: 120, height: 80, text: "Text", minimumRed: 126)
    }

    private func assertVisibleText(
        foreground: Color,
        width: CGFloat,
        height: CGFloat,
        text: String,
        minimumRed: UInt8 = 0
    ) throws {
        guard #available(iOS 16, macOS 13, *) else {
            throw XCTSkip("ImageRenderer requires iOS 16 or macOS 13")
        }
        let view = AccessibilityEnhancerSwatch(
            foreground: foreground,
            background: .white,
            width: width,
            height: height,
            text: text
        )
        .environment(\.colorScheme, .light)
        let renderer = ImageRenderer(content: view)
        renderer.scale = 3
        let fullImage = try XCTUnwrap(renderer.cgImage)
        // Inspect the text area, excluding outer corners and shadows.
        let image = try XCTUnwrap(fullImage.cropping(to: CGRect(
            x: fullImage.width / 4,
            y: fullImage.height / 4,
            width: fullImage.width / 2,
            height: fullImage.height / 2
        )))
        let context = try XCTUnwrap(CGContext(
            data: nil,
            width: image.width,
            height: image.height,
            bitsPerComponent: 8,
            bytesPerRow: image.width * 4,
            space: CGColorSpace(name: CGColorSpace.sRGB)!,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Big.rawValue
        ))
        context.draw(image, in: CGRect(x: 0, y: 0, width: image.width, height: image.height))
        let pixels = try XCTUnwrap(context.data).assumingMemoryBound(to: UInt8.self)
        var backgroundPixels = 0
        var foregroundPixels = 0
        var darkestRed: UInt8 = 255
        for offset in stride(from: 0, to: image.width * image.height * 4, by: 4) {
            if pixels[offset] > 250, pixels[offset + 1] > 250, pixels[offset + 2] > 250 {
                backgroundPixels += 1
            }
            if pixels[offset] < 200 { foregroundPixels += 1 }
            darkestRed = min(darkestRed, pixels[offset])
        }
        XCTAssertGreaterThan(backgroundPixels, image.width * image.height / 2, "Text must sit on the assessed white background")
        XCTAssertGreaterThan(foregroundPixels, 10, "The foreground text must remain visible")
        XCTAssertGreaterThanOrEqual(darkestRed, minimumRed, "Foreground opacity must be composited only once")
    }
}
