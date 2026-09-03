import CoreGraphics
import SwiftUI
import XCTest

@available(iOS 16.0, macOS 13.0, *)
@MainActor
func renderedPixel(
    of view: some View,
    file: StaticString = #filePath,
    line: UInt = #line
) throws -> [UInt8] {
    let content = view
        .frame(width: 1, height: 1)
        .environment(\.colorScheme, .light)
    let renderer = ImageRenderer(content: content)
    renderer.scale = 1
    let image = try XCTUnwrap(renderer.cgImage, file: file, line: line)
    var pixel = [UInt8](repeating: 0, count: 4)
    try pixel.withUnsafeMutableBytes { bytes in
        let context = try XCTUnwrap(
            CGContext(
                data: bytes.baseAddress,
                width: 1,
                height: 1,
                bitsPerComponent: 8,
                bytesPerRow: 4,
                space: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
            ),
            file: file,
            line: line
        )
        context.draw(image, in: CGRect(x: 0, y: 0, width: 1, height: 1))
    }
    return pixel
}
