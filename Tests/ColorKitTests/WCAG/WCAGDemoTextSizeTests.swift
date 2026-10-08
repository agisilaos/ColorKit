import SwiftUI
import Vision
import XCTest

@testable import ColorKit

#if canImport(AppKit)
import AppKit
#endif

@MainActor
final class WCAGDemoTextSizeTests: XCTestCase {
    #if os(macOS)
    func testPublicDemoShowsOnlyItsTextSizeAwareAssessment() throws {
        let host = NSHostingView(rootView: WCAGDemoView()
            .environment(\.colorScheme, .light)
            .background(.white))
        let frame = CGRect(x: -10_000, y: -10_000, width: 700, height: 1_500)
        let window = NSWindow(contentRect: frame, styleMask: [.borderless], backing: .buffered, defer: false)
        window.isReleasedWhenClosed = false
        window.appearance = NSAppearance(named: .aqua)
        window.contentView = host
        window.setIsVisible(true)
        defer { window.close() }
        for _ in 0..<3 {
            RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.05))
            host.layoutSubtreeIfNeeded()
        }
        let bitmap = try XCTUnwrap(host.bitmapImageRepForCachingDisplay(in: host.bounds))
        host.cacheDisplay(in: host.bounds, to: bitmap)
        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        try VNImageRequestHandler(cgImage: XCTUnwrap(bitmap.cgImage)).perform([request])
        let text = (request.results ?? []).compactMap { $0.topCandidates(1).first?.string }.joined(separator: "\n")

        XCTAssertEqual(text.lowercased().components(separatedBy: "contrast ratio").count - 1, 1, text)
        XCTAssertTrue(text.contains("Does not meet any compliance level"), text)
    }
    #endif

    func testSimulationAssessmentMeasuresTheDisplayedPair() throws {
        let foreground = Color(.sRGB, red: 1, green: 0, blue: 0)
        let background = Color.white
        let assessment = WCAGDemoAssessment(foreground: foreground, background: background, deficiency: .protanopia)
        let displayed = try XCTUnwrap(assessment.pair)
        let expected = try XCTUnwrap(displayed.foreground.contrastResult(with: displayed.background).ratio)
        let original = try XCTUnwrap(foreground.contrastResult(with: background).ratio)

        XCTAssertGreaterThan(abs(expected - original), 1, "The fixture must distinguish displayed and original contrast")
        XCTAssertEqual(try XCTUnwrap(assessment.contrastRatio), expected, accuracy: 1e-12)
    }

    func testOrdinaryAndUnavailableSimulationAssessmentRetainTheirOutcomes() throws {
        let foreground = Color(.sRGB, red: 1, green: 0, blue: 0)
        let ordinary = WCAGDemoAssessment(foreground: foreground, background: .white, deficiency: nil)
        XCTAssertEqual(ordinary.pair?.foreground, foreground)
        XCTAssertEqual(ordinary.contrastRatio, foreground.contrastResult(with: .white).ratio)
        let unavailable = WCAGDemoAssessment(foreground: .primary, background: .white, deficiency: .protanopia)
        XCTAssertNil(unavailable.pair)
        XCTAssertNil(unavailable.contrastRatio)
    }

    func testRegularTextBelowEighteenPointsDoesNotUseLargeTextLevels() {
        for size in [8.0, 13, 14, 16, 17, 17.99] {
            let details = WCAGDemoComplianceDetails(ratio: 3.5, fontSize: size)
            XCTAssertFalse(details.isLargeText, "Regular \(size)pt")
            XCTAssertFalse(details.isRelevant(.AALarge))
            XCTAssertFalse(details.isRelevant(.AAALarge))
            XCTAssertNil(details.highestLevel)
        }
    }

    func testHighestLevelUsesOnlyLevelsApplicableToTheSample() {
        XCTAssertEqual(WCAGDemoComplianceDetails(ratio: 4.5, fontSize: 16).highestLevel, .AA)
        XCTAssertEqual(WCAGDemoComplianceDetails(ratio: 7, fontSize: 16).highestLevel, .AAA)
        let large = WCAGDemoComplianceDetails(ratio: 3.5, fontSize: 18)
        XCTAssertTrue(large.isLargeText)
        XCTAssertTrue(large.isRelevant(.AALarge))
        XCTAssertEqual(large.highestLevel, .AALarge)
        XCTAssertEqual(WCAGDemoComplianceDetails(ratio: 4.5, fontSize: 18).highestLevel, .AAALarge)
    }

    func testVisibleSummaryDoesNotAdvertiseInapplicableCompliance() throws {
        guard #available(iOS 16, macOS 13, *) else {
            throw XCTSkip("ImageRenderer requires iOS 16 or macOS 13")
        }
        let view = VStack {
            WCAGDemoComplianceDetails(ratio: 3.5, fontSize: 16)
        }
        .frame(width: 500)
        .padding()
        .background(.white)
        .environment(\.colorScheme, .light)
        let renderer = ImageRenderer(content: view)
        renderer.scale = 3
        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        try VNImageRequestHandler(cgImage: XCTUnwrap(renderer.cgImage)).perform([request])
        let text = (request.results ?? []).compactMap { $0.topCandidates(1).first?.string }.joined(separator: "\n")

        XCTAssertTrue(text.contains("Does not meet any compliance level"), text)
        XCTAssertFalse(text.contains("Highest Compliance Level:"), text)
    }
}
