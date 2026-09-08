import SwiftUI
import XCTest

@testable import ColorKit

@MainActor
final class ComponentConversionPreviewTests: XCTestCase {
    func testBlackShowsAvailableZerosAndUnits() {
        let rows = rows(for: .black)
        XCTAssertEqual(rows.map(\.title), ["sRGBA", "HSL", "HSB", "CMYK", "XYZ", "LAB", "Hex"])
        XCTAssertTrue(rows.allSatisfy(\.isAvailable))
        XCTAssertEqual(rows[1].detail, "Hue 0°, saturation 0%, lightness 0%")
        XCTAssertEqual(rows[3].detail, "Cyan 0%, magenta 0%, yellow 0%, black 100%")
        XCTAssertEqual(rows[4].detail, "X 0, Y 0, Z 0")
        XCTAssertFalse(rows[4].detail.contains("%"))
        XCTAssertFalse(rows[5].detail.contains("%"))
        XCTAssertEqual(rows[6].detail, "#000000FF")
    }

    func testHueTurnsAndFractionsAreConvertedForDisplay() {
        let result = Color(.sRGB, red: 0, green: 1, blue: 0, opacity: 0).componentConversionResults()
        let rows = ComponentConversionRow.rows(for: result)
        XCTAssertEqual(rows[1].detail, "Hue 120°, saturation 100%, lightness 50%")
        XCTAssertEqual(rows[2].detail, "Hue 120°, saturation 100%, brightness 100%")
        XCTAssertEqual(rows[6].detail, "#00FF0000")
    }

    func testWideGamutPreservesSuccessfulRowsAndExplainsEachFailure() {
        let rows = rows(for: .wideGamut)
        XCTAssertEqual(rows.filter(\.isAvailable).map(\.title), ["sRGBA", "XYZ", "LAB"])
        XCTAssertEqual(rows.filter { !$0.isAvailable }.map(\.title), ["HSL", "HSB", "CMYK", "Hex"])
        for row in rows where !row.isAvailable {
            XCTAssertEqual(row.detail, "Outside sRGB: this representation would require clipping.")
        }
    }

    func testUnresolvedInputNeverUsesNumericFallbacks() {
        let rows = rows(for: .unresolved)
        XCTAssertTrue(rows.allSatisfy { !$0.isAvailable })
        for row in rows {
            XCTAssertEqual(row.detail, "No fixed components. Named or dynamic colors may need explicit appearance resolution.")
        }
        let issues: [ColorConversionIssue] = [
            .unresolvedInput, .unsupportedColorModel, .invalidComponents,
            .colorSpaceConversionFailed, .outOfSRGBGamut, .nonfiniteResult
        ]
        XCTAssertEqual(Set(issues.map(ComponentConversionRow.explanation)).count, issues.count)
        for issue in issues {
            let row = ComponentConversionRow("Test", units: "", result: Result<Int, ColorConversionIssue>.failure(issue)) { _ in
                XCTFail("An unavailable result must never enter the numeric formatter")
                return "0"
            }
            XCTAssertFalse(row.isAvailable)
            XCTAssertFalse(row.detail.isEmpty)
        }
    }

    func testHostedLightAndDarkInspectionStates() async throws {
        for sample in ComponentConversionSample.allCases {
            for scheme in [ColorScheme.light, .dark] {
                try await capture(sample: sample, scheme: scheme)
            }
        }
    }

    func testHostedAccessibilityTextSize() async throws {
        try await capture(sample: .wideGamut, scheme: .dark, size: .accessibilityExtraExtraExtraLarge)
    }

    private func rows(for sample: ComponentConversionSample) -> [ComponentConversionRow] {
        ComponentConversionRow.rows(for: sample.color.componentConversionResults())
    }

    #if !os(macOS)
    private func scrollView(in view: UIView) -> UIScrollView? {
        (view as? UIScrollView) ?? view.subviews.lazy.compactMap { self.scrollView(in: $0) }.first
    }
    #endif

    private func capture(sample: ComponentConversionSample, scheme: ColorScheme, size: ContentSizeCategory = .large) async throws {
        // Capture the real inspection content at a narrow width and enough height to review every row.
        let height: CGFloat = size == .large ? 3_000 : 4_000
        let appeared = expectation(description: "Inspection appeared")
        let root = ComponentConversionInspection(sample: sample)
            .environment(\.colorScheme, scheme)
            .environment(\.sizeCategory, size)
            .background(scheme == .dark ? Color.black : Color.white)
            .onAppear { appeared.fulfill() }
        let name = "\(sample)-\(scheme)-\(size)"
        #if os(macOS)
        let controller = NSHostingController(rootView: root)
        let window = NSWindow(contentViewController: controller)
        window.isReleasedWhenClosed = false
        window.setContentSize(NSSize(width: 390, height: height))
        window.appearance = NSAppearance(named: scheme == .dark ? .darkAqua : .aqua)
        window.orderFront(nil)
        defer { window.close() }
        await fulfillment(of: [appeared], timeout: 3)
        controller.view.layoutSubtreeIfNeeded()
        let bitmap = try XCTUnwrap(controller.view.bitmapImageRepForCachingDisplay(in: controller.view.bounds))
        controller.view.cacheDisplay(in: controller.view.bounds, to: bitmap)
        let image = NSImage(size: controller.view.bounds.size)
        image.addRepresentation(bitmap)
        #else
        let controller = UIHostingController(rootView: root)
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 390, height: height))
        window.overrideUserInterfaceStyle = scheme == .dark ? .dark : .light
        window.rootViewController = controller
        window.makeKeyAndVisible()
        defer {
            window.isHidden = true
            window.rootViewController = nil
        }
        await fulfillment(of: [appeared], timeout: 3)
        controller.view.layoutIfNeeded()
        let renderer = UIGraphicsImageRenderer(bounds: controller.view.bounds)
        let image = renderer.image { context in
            controller.view.layer.render(in: context.cgContext)
        }
        if size != .large {
            let scroll = try XCTUnwrap(scrollView(in: controller.view))
            XCTAssertGreaterThan(scroll.contentSize.height, scroll.bounds.height)
            XCTAssertLessThanOrEqual(scroll.contentSize.width, scroll.bounds.width)
            scroll.setContentOffset(CGPoint(x: 0, y: scroll.contentSize.height - scroll.bounds.height), animated: false)
            controller.view.layoutIfNeeded()
            let bottom = renderer.image { context in controller.view.layer.render(in: context.cgContext) }
            let attachment = XCTAttachment(image: bottom)
            attachment.name = "\(name)-scrolled-bottom"
            attachment.lifetime = .keepAlways
            add(attachment)
        }
        #endif
        let attachment = XCTAttachment(image: image)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
