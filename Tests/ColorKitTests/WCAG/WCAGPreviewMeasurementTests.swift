import SwiftUI
import Vision
import XCTest

@testable import ColorKit

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

@MainActor
final class WCAGPreviewMeasurementTests: XCTestCase {
    func testTranslucentForegroundDisplaysItsCompositedRatio() throws {
        let foreground = Color(.sRGB, red: 0, green: 0, blue: 0, opacity: 0.9)
        let text = try recognizedPreviewText(foreground: foreground, background: .white)

        XCTAssertTrue(text.contains("17.49"), text)
        XCTAssertFalse(text.contains("1.00"), text)
    }

    func testDynamicForegroundDisplaysUnavailableAcrossAppearances() throws {
        #if canImport(UIKit)
        let foreground = Color(UIColor { traits in
            traits.userInterfaceStyle == .dark ? .white : .black
        })
        #else
        let foreground = Color(nsColor: NSColor(name: nil) { appearance in
            appearance.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua ? .white : .black
        })
        #endif
        for scheme in [ColorScheme.light, .dark] {
            let text = try recognizedPreviewText(foreground: foreground, background: .white, scheme: scheme)
            XCTAssertTrue(text.localizedCaseInsensitiveContains("unavailable"), text)
            XCTAssertFalse(text.contains("Contrast Ratio:"), text)
        }
    }

    func testOpaquePairStillDisplaysItsMeasuredRatio() throws {
        let text = try recognizedPreviewText(foreground: .black, background: .white)
        XCTAssertTrue(text.contains("21.00"), text)
    }

    func testTranslucentBackgroundDisplaysUnavailable() throws {
        let text = try recognizedPreviewText(foreground: .black, background: .white.opacity(0.5))
        XCTAssertTrue(text.localizedCaseInsensitiveContains("unavailable"), text)
        XCTAssertFalse(text.contains("Contrast Ratio:"), text)
    }

    private func recognizedPreviewText(
        foreground: Color,
        background: Color,
        scheme: ColorScheme = .light
    ) throws -> String {
        guard #available(iOS 16, macOS 13, *) else {
            throw XCTSkip("ImageRenderer requires iOS 16 or macOS 13")
        }
        let view = Text("Sample")
            .wcagCompliance(foreground: foreground, background: background)
            .padding()
            .frame(width: 500)
            .background(scheme == .dark ? Color.black : Color.white)
            .environment(\.colorScheme, scheme)
        let renderer = ImageRenderer(content: view)
        renderer.scale = 3
        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        let handler = VNImageRequestHandler(cgImage: try XCTUnwrap(renderer.cgImage))
        try handler.perform([request])
        return (request.results ?? []).compactMap { $0.topCandidates(1).first?.string }.joined(separator: "\n")
    }
}
