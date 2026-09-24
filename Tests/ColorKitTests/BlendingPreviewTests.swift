import SwiftUI
import XCTest

@testable import ColorKit

@MainActor
final class BlendingPreviewTests: XCTestCase {
    private let base = Color(.sRGB, red: 0.2, green: 0.4, blue: 0.8, opacity: 0.5)
    private let blend = Color(.sRGB, red: 0.8, green: 0.6, blue: 0.1)

    func testOrdinarySuccessUsesOrderedOperandsAndPreservesBaseAlpha() throws {
        let outcome = BlendingPreviewOutcome(base: base, blend: blend, mode: .overlay, amount: 0.5)
        guard case let .success(color, explanation) = outcome else { return XCTFail("Expected success") }
        let actual = try color.componentConversionResults().srgba.get()
        XCTAssertEqual(actual.red, 0.26, accuracy: 1e-6)
        XCTAssertEqual(actual.green, 0.44, accuracy: 1e-6)
        XCTAssertEqual(actual.blue, 0.72, accuracy: 1e-6)
        XCTAssertEqual(actual.alpha, 0.5, accuracy: 1e-6)
        XCTAssertNil(explanation)
    }

    func testUnchangedSuccessExplainsOnlyKnownZeroContributions() throws {
        let white = Color(.sRGB, red: 1, green: 1, blue: 1)
        let cases: [(Color, CGFloat, String?)] = [
            (white, 0, "Amount is 0%; the result matches the base."),
            (white.opacity(0), 1, "The blend color is fully transparent; the result matches the base."),
            (white.opacity(0), 0, "Amount is 0%; the result matches the base."),
            (white, 1, nil)
        ]
        for (blend, amount, expected) in cases {
            let outcome = BlendingPreviewOutcome(base: base, blend: blend, mode: .multiply, amount: amount)
            guard case let .success(color, explanation) = outcome else { return XCTFail("Expected unchanged success") }
            XCTAssertEqual(try color.componentConversionResults().srgba.get(), try base.componentConversionResults().srgba.get())
            XCTAssertEqual(explanation, expected)
        }
    }

    func testZeroAmountStillReportsBothUnavailableOperands() {
        let outcome = BlendingPreviewOutcome(base: .primary, blend: .secondary, mode: .normal, amount: 0)
        guard case .failure(let messages) = outcome else { return XCTFail("Expected failure, not zero-amount success") }
        XCTAssertEqual(messages, [
            "Base color: This color doesn't provide fixed color values for blending. Choose another color.",
            "Blend color: This color doesn't provide fixed color values for blending. Choose another color."
        ])
    }

    func testEachInputIssueIdentifiesTheAffectedOperand() {
        let issues: [ColorConversionIssue] = [
            .unresolvedInput, .unsupportedColorModel, .invalidComponents,
            .colorSpaceConversionFailed, .outOfSRGBGamut, .nonfiniteResult
        ]
        var explanations: Set<String> = []
        for issue in issues {
            let baseMessages = BlendingPreviewOutcome.explanations(for: .unavailableInputs(base: issue, blend: nil))
            let blendMessages = BlendingPreviewOutcome.explanations(for: .unavailableInputs(base: nil, blend: issue))
            XCTAssertEqual(baseMessages.count, 1)
            XCTAssertEqual(blendMessages.count, 1)
            XCTAssertTrue(baseMessages[0].hasPrefix("Base color: "))
            XCTAssertTrue(blendMessages[0].hasPrefix("Blend color: "))
            XCTAssertTrue(baseMessages[0].contains("Choose"))
            XCTAssertFalse(baseMessages[0].contains(String(describing: issue)))
            explanations.insert(baseMessages[0])
        }
        XCTAssertEqual(explanations.count, issues.count)
        XCTAssertFalse(BlendingPreviewOutcome.explanations(for: .unavailableInputs(base: nil, blend: nil)).isEmpty)
    }

    func testInvalidAmountAndCalculationFailureExplainRecovery() throws {
        for amount: CGFloat in [-0.1, 1.1, .nan, .infinity, -.infinity] {
            let outcome = BlendingPreviewOutcome(base: .primary, blend: blend, mode: .normal, amount: amount)
            guard case .failure(let messages) = outcome else { return XCTFail("Expected invalid amount") }
            XCTAssertEqual(messages, ["Choose a blend amount between 0% and 100%."])
        }
        let space = try XCTUnwrap(CGColorSpace(name: CGColorSpace.extendedSRGB))
        let negative = Color(try XCTUnwrap(CGColor(colorSpace: space, components: [-1e308, 0, 0, 1])))
        let positive = Color(try XCTUnwrap(CGColor(colorSpace: space, components: [1e308, 0, 0, 1])))
        let outcome = BlendingPreviewOutcome(base: negative, blend: positive, mode: .normal, amount: 1)
        guard case .failure(let messages) = outcome else { return XCTFail("Expected calculation failure") }
        XCTAssertEqual(messages, ["This combination produced color values the preview can't use. Try another blend mode or different colors."])
    }

    func testFixedPickerColorsRetainTransparencyAndWideGamut() throws {
        let space = try XCTUnwrap(CGColorSpace(name: CGColorSpace.displayP3))
        for alpha: CGFloat in [0, 0.5, 1] {
            let selection = try XCTUnwrap(CGColor(colorSpace: space, components: [1, 0, 0, alpha]))
            let fixed = Color(selection)
            let outcome = BlendingPreviewOutcome(base: fixed, blend: blend, mode: .normal, amount: 0)
            guard case let .success(color, _) = outcome else { return XCTFail("Expected fixed picker value to resolve") }
            let components = try color.componentConversionResults().srgba.get()
            XCTAssertEqual(components, try fixed.componentConversionResults().srgba.get())
            XCTAssertEqual(components.alpha, alpha)
            XCTAssertGreaterThan(components.red, 1)
        }
    }

    func testHostedResultStatesAndRecovery() async throws {
        let states: [(String, BlendingPreviewOutcome)] = [
            ("success", BlendingPreviewOutcome(base: base, blend: blend, mode: .overlay, amount: 0.5)),
            ("zero-amount", BlendingPreviewOutcome(base: base, blend: blend, mode: .normal, amount: 0)),
            ("transparent-blend", BlendingPreviewOutcome(base: base, blend: blend.opacity(0), mode: .normal, amount: 1)),
            ("transparent-result", BlendingPreviewOutcome(base: base.opacity(0), blend: blend, mode: .normal, amount: 1)),
            ("base-unavailable", BlendingPreviewOutcome(base: .primary, blend: blend, mode: .normal, amount: 1)),
            ("both-unavailable", BlendingPreviewOutcome(base: .primary, blend: .secondary, mode: .normal, amount: 1)),
            ("recovered", BlendingPreviewOutcome(base: base, blend: blend, mode: .normal, amount: 1))
        ]
        let views = states.map { name, outcome in
            (name, AnyView(ScrollView { BlendingResultPreview(outcome: outcome).padding() }))
        }
        for scheme in [ColorScheme.light, .dark] {
            try await capture(views, scheme: scheme)
        }
        try await capture(views, scheme: .dark, size: .accessibilityExtraExtraExtraLarge)
    }

    func testHostedPickerControls() async throws {
        for scheme in [ColorScheme.light, .dark] {
            try await capture([("picker-controls", AnyView(BlendingPreview()))], scheme: scheme)
        }
        try await capture([("picker-controls", AnyView(BlendingPreview()))], scheme: .dark, size: .accessibilityExtraExtraExtraLarge)
    }

    #if !os(macOS)
    private func scrollView(in view: UIView) -> UIScrollView? {
        (view as? UIScrollView) ?? view.subviews.lazy.compactMap { self.scrollView(in: $0) }.first
    }
    #endif

    /// Replace the same host's content to exercise success/failure/recovery without retaining an old result view.
    private func capture(_ states: [(String, AnyView)], scheme: ColorScheme, size: ContentSizeCategory = .large) async throws {
        #if os(macOS)
        let controller = NSHostingController(rootView: AnyView(EmptyView()))
        let window = NSWindow(contentViewController: controller)
        window.isReleasedWhenClosed = false
        window.setContentSize(NSSize(width: 390, height: 900))
        window.appearance = NSAppearance(named: scheme == .dark ? .darkAqua : .aqua)
        window.orderFront(nil)
        defer { window.close() }
        #else
        let controller = UIHostingController(rootView: AnyView(EmptyView()))
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 390, height: 900))
        window.overrideUserInterfaceStyle = scheme == .dark ? .dark : .light
        window.rootViewController = controller
        window.makeKeyAndVisible()
        defer { window.isHidden = true; window.rootViewController = nil }
        #endif
        for (name, view) in states {
            let appeared = expectation(description: name)
            controller.rootView = AnyView(view
                .environment(\.colorScheme, scheme)
                .environment(\.sizeCategory, size)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .background(scheme == .dark ? Color.black : Color.white)
                .onAppear { appeared.fulfill() }
                .id(name))
            await fulfillment(of: [appeared], timeout: 3)
            #if os(macOS)
            controller.view.layoutSubtreeIfNeeded()
            let bitmap = try XCTUnwrap(controller.view.bitmapImageRepForCachingDisplay(in: controller.view.bounds))
            controller.view.cacheDisplay(in: controller.view.bounds, to: bitmap)
            let image = NSImage(size: controller.view.bounds.size)
            image.addRepresentation(bitmap)
            #else
            controller.view.layoutIfNeeded()
            let renderer = UIGraphicsImageRenderer(bounds: controller.view.bounds)
            let image = renderer.image { context in controller.view.layer.render(in: context.cgContext) }
            #endif
            let attachment = XCTAttachment(image: image)
            attachment.name = "blending-\(name)-\(scheme)-\(size)"
            attachment.lifetime = .keepAlways
            add(attachment)
            #if !os(macOS)
            if size != .large {
                let scroll = try XCTUnwrap(scrollView(in: controller.view))
                XCTAssertLessThanOrEqual(scroll.contentSize.width, scroll.bounds.width)
                scroll.setContentOffset(CGPoint(x: 0, y: max(0, scroll.contentSize.height - scroll.bounds.height)), animated: false)
                controller.view.layoutIfNeeded()
                let bottom = renderer.image { context in controller.view.layer.render(in: context.cgContext) }
                let bottomAttachment = XCTAttachment(image: bottom)
                bottomAttachment.name = "blending-\(name)-large-text-scrolled-bottom"
                bottomAttachment.lifetime = .keepAlways
                add(bottomAttachment)
            }
            #endif
        }
    }
}
