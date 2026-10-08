import ColorKit
import SwiftUI
import XCTest

@MainActor
final class AdaptiveColorModifierTests: XCTestCase {
    func testZeroBrightnessPreservesSelectedColorRendering() throws {
        let light = Color(.sRGB, red: 1, green: 0, blue: 0, opacity: 0.25)
        let dark = Color(.sRGB, red: 0, green: 0, blue: 1, opacity: 0.5)
        for scheme in [ColorScheme.light, .dark] {
            let expected = try pixel(Rectangle().foregroundColor(scheme == .dark ? dark : light), scheme: scheme)
            let actual = try pixel(Rectangle().adaptiveColor(light: light, dark: dark), scheme: scheme)
            XCTAssertEqual(actual, expected, "Zero brightness adjustment: \(scheme)")

            let dynamic = Color.primary.opacity(0.25)
            XCTAssertEqual(
                try pixel(Rectangle().adaptiveColor(light: dynamic, dark: dynamic), scheme: scheme),
                try pixel(Rectangle().foregroundColor(dynamic), scheme: scheme),
                "Zero adjustment must retain appearance-dependent rendering"
            )
        }
    }

    func testNonzeroBrightnessPreservesOpacityWhileAdjustingRGB() throws {
        let color = Color(.sRGB, red: 1, green: 0, blue: 0, opacity: 0.25)
        let original = try pixel(Rectangle().foregroundColor(color), scheme: .light)
        for amount: CGFloat in [-0.2, 0.2] {
            let adjusted = try pixel(Rectangle().adaptiveColor(
                light: color, dark: color, brightnessAdjustment: amount
            ), scheme: .light)
            XCTAssertEqual(adjusted[3], original[3], "Brightness adjustment must retain opacity")
            XCTAssertNotEqual(Array(adjusted.prefix(3)), Array(original.prefix(3)), "Brightness must still change")
        }
    }

    private func pixel(_ view: some View, scheme: ColorScheme) throws -> [UInt8] {
        guard #available(iOS 16, macOS 13, *) else {
            throw XCTSkip("ImageRenderer requires iOS 16 or macOS 13")
        }
        let renderer = ImageRenderer(content: view.frame(width: 20, height: 20).environment(\.colorScheme, scheme))
        let image = try XCTUnwrap(renderer.cgImage)
        let space = try XCTUnwrap(CGColorSpace(name: CGColorSpace.sRGB))
        let context = try XCTUnwrap(CGContext(
            data: nil,
            width: image.width,
            height: image.height,
            bitsPerComponent: 8,
            bytesPerRow: image.width * 4,
            space: space,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Big.rawValue
        ))
        context.draw(image, in: CGRect(x: 0, y: 0, width: image.width, height: image.height))
        let pixels = try XCTUnwrap(context.data).assumingMemoryBound(to: UInt8.self)
        let offset = (image.height / 2 * image.width + image.width / 2) * 4
        return Array(UnsafeBufferPointer(start: pixels + offset, count: 4))
    }
}
