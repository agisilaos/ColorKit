import SwiftUI
import XCTest

@testable import ColorKit

@MainActor
final class BlendingPreviewContrastTests: XCTestCase {
    func testModeTextMeetsNormalTextContrastInBothAppearances() throws {
        let accents: [Color] = [
            Color(.sRGB, red: 0, green: 136.0 / 255, blue: 1),
            .yellow, .purple
        ]
        for scheme in [ColorScheme.light, .dark] {
            for accent in accents {
                for selected in [false, true] {
                    let view = BlendModeButton(mode: .normal, isSelected: selected, action: {}).label
                        .accentColor(accent)
                    XCTAssertGreaterThanOrEqual(
                        try renderedTextContrast(view, scheme: scheme),
                        4.5,
                        "Mode text: \(scheme), selected=\(selected), accent=\(accent)"
                    )
                }
            }
        }
    }

    func testResultExplanationMeetsNormalTextContrastInBothAppearances() throws {
        for scheme in [ColorScheme.light, .dark] {
            let view = BlendingResultPreview(outcome: .failure([])).frame(width: 320)
            XCTAssertGreaterThanOrEqual(
                try renderedTextContrast(view, scheme: scheme, bottomLineOnly: true),
                4.5,
                "Opacity explanation: \(scheme)"
            )
        }
    }

    /// Compare the dominant solid text and background pixels, excluding antialiased edges.
    /// The footer crop contains its last line, so the heading cannot mask a low-contrast footer.
    private func renderedTextContrast(
        _ view: some View, scheme: ColorScheme, bottomLineOnly: Bool = false
    ) throws -> Double {
        guard #available(iOS 16, macOS 13, *) else {
            throw XCTSkip("ImageRenderer requires iOS 16 or macOS 13")
        }
        let renderer = ImageRenderer(content: view
            .background(scheme == .dark ? Color.black : Color.white)
            .environment(\.colorScheme, scheme)
            .environment(\.sizeCategory, .large))
        renderer.scale = 3
        var image = try XCTUnwrap(renderer.cgImage)
        if bottomLineOnly {
            image = try XCTUnwrap(image.cropping(to: CGRect(
                x: 0, y: image.height - 48, width: image.width, height: 48
            )))
        }
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
        var counts: [Int: Int] = [:]
        for offset in stride(from: 0, to: image.width * image.height * 4, by: 4) {
            let rgb = Int(pixels[offset]) << 16 | Int(pixels[offset + 1]) << 8 | Int(pixels[offset + 2])
            counts[rgb, default: 0] += 1
        }
        let colors = counts.sorted { $0.value > $1.value }.prefix(2).map { entry in
            Color(
                .sRGB,
                red: Double((entry.key >> 16) & 255) / 255,
                green: Double((entry.key >> 8) & 255) / 255,
                blue: Double(entry.key & 255) / 255
            )
        }
        XCTAssertEqual(colors.count, 2, "Expected visible text and its background")
        guard colors.count == 2 else { return 0 }
        return try XCTUnwrap(colors[0].contrastResult(with: colors[1]).ratio)
    }
}
