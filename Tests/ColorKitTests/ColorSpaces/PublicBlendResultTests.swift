import ColorKit
import struct SwiftUI.Color
import XCTest

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

/// Public-client checks with no access to internal resolver or arithmetic helpers.
final class PublicBlendResultTests: XCTestCase {
    func testModeResultsAndOperandOrdering() throws {
        let base = Color(.sRGB, red: 0.25, green: 0.25, blue: 0.25)
        let blend = Color(.sRGB, red: 0.75, green: 0.75, blue: 0.75)
        let cases: [(BlendMode, Double)] = [
            (.normal, 0.75), (.multiply, 0.1875), (.screen, 0.8125),
            (.overlay, 0.375), (.darken, 0.25), (.lighten, 0.75),
            (.colorDodge, 1), (.colorBurn, 0), (.hardLight, 0.625),
            (.softLight, 0.375), (.difference, 0.5), (.exclusion, 0.625)
        ]
        for (mode, expected) in cases {
            let result = try base.blendResult(with: blend, mode: mode).get().componentConversionResults().srgba.get()
            XCTAssertEqual(result.red, expected, accuracy: 1e-6)
            XCTAssertEqual(result.green, expected, accuracy: 1e-6)
            XCTAssertEqual(result.blue, expected, accuracy: 1e-6)
        }
        let reversed = try blend.blendResult(with: base, mode: .overlay).get().componentConversionResults().srgba.get()
        XCTAssertEqual(reversed.red, 0.625, accuracy: 1e-6)
    }

    func testAmountAndBlendAlphaPreserveBaseAlpha() throws {
        for alpha in [0.0, 0.4, 1.0] {
            let base = Color(.sRGB, red: 1, green: 0, blue: 0, opacity: alpha)
            let blend = Color(.sRGB, red: 0, green: 0, blue: 1, opacity: 0.5)
            let result = try base.blendResult(with: blend, mode: .normal, amount: 0.5).get().componentConversionResults().srgba.get()
            XCTAssertEqual(result.red, 0.75, accuracy: 1e-6)
            XCTAssertEqual(result.blue, 0.25, accuracy: 1e-6)
            XCTAssertEqual(result.alpha, alpha, accuracy: 1e-6)
        }
    }

    func testUnchangedSuccessAndZeroContribution() throws {
        let base = Color(.sRGB, red: 0.25, green: 0.5, blue: 0.75, opacity: 0.5)
        let white = Color(.sRGB, red: 1, green: 1, blue: 1)
        for result in [
            base.blendResult(with: white, mode: .multiply),
            base.blendResult(with: white, mode: .normal, amount: 0),
            base.blendResult(with: white.opacity(0), mode: .normal)
        ] {
            XCTAssertEqual(try result.get().componentConversionResults().srgba.get(), try base.componentConversionResults().srgba.get())
        }
        // Color space may change on success: zero contribution returns resolved components.
        let gray = try fixedTestColor(space: CGColorSpace.genericGrayGamma2_2, components: [0.5, 1])
        let result = try gray.blendResult(with: white, mode: .normal, amount: 0).get().componentConversionResults().srgba.get()
        XCTAssertEqual(result.red, try gray.componentConversionResults().srgba.get().red, accuracy: 1e-6)
    }

    func testInvalidAmountsTakePrecedence() {
        for amount: CGFloat in [-0.01, 1.01, .nan, .infinity, -.infinity] {
            XCTAssertEqual(Color.primary.blendResult(with: .primary, mode: .normal, amount: amount), .failure(.invalidAmount))
        }
    }

    func testIssuesRetainBothRolesEvenAtZeroContribution() throws {
        let fixed = Color(.sRGB, red: 0, green: 0, blue: 0)
        for amount: CGFloat in [0, 0.5, 1] {
            XCTAssertEqual(Color.primary.blendResult(with: fixed, mode: .normal, amount: amount),
                           .failure(.unavailableInputs(base: .unresolvedInput, blend: nil)))
            XCTAssertEqual(fixed.blendResult(with: .primary, mode: .normal, amount: amount),
                           .failure(.unavailableInputs(base: nil, blend: .unresolvedInput)))
        }
        XCTAssertEqual(Color.primary.blendResult(with: fixed.opacity(0), mode: .normal),
                       .failure(.unavailableInputs(base: .unresolvedInput, blend: nil)))
        let pattern = try patternTestColor()
        XCTAssertEqual(Color.primary.blendResult(with: pattern, mode: .normal),
                       .failure(.unavailableInputs(base: .unresolvedInput, blend: .unsupportedColorModel)))
    }

    func testResolvedColorSpacesAndExtendedOutput() throws {
        let colors = try [
            fixedTestColor(space: CGColorSpace.genericGrayGamma2_2, components: [0.5, 0.5]),
            fixedTestColor(space: CGColorSpace.linearSRGB),
            fixedTestColor(space: CGColorSpace.displayP3, components: [1, 0, 0, 1]),
            fixedTestColor(space: CGColorSpace.extendedSRGB, components: [-0.5, 1.5, 0.25, 0.5])
        ]
        let white = Color(.sRGB, red: 1, green: 1, blue: 1)
        for color in colors {
            let expected = try color.componentConversionResults().srgba.get()
            let result = try color.blendResult(with: white, mode: .multiply).get().componentConversionResults().srgba.get()
            XCTAssertEqual(result.red, expected.red, accuracy: 1e-6)
            XCTAssertEqual(result.green, expected.green, accuracy: 1e-6)
            XCTAssertEqual(result.blue, expected.blue, accuracy: 1e-6)
            XCTAssertEqual(result.alpha, expected.alpha, accuracy: 1e-6)
        }
    }

    func testNonfiniteArithmeticAndZeroShortcut() throws {
        let huge = try fixedTestColor(space: CGColorSpace.extendedSRGB, components: [1e200, 0, 0, 1])
        let white = Color(.sRGB, red: 1, green: 1, blue: 1)
        XCTAssertEqual(huge.blendResult(with: huge, mode: .multiply), .failure(.nonfiniteResult))
        // A finite base and zero amount must not evaluate the overflowing mode.
        let base = Color(.sRGB, red: 0.25, green: 0.5, blue: 0.75)
        let result = try base.blendResult(with: huge, mode: .softLight, amount: 0).get()
        XCTAssertEqual(try result.componentConversionResults().srgba.get(), try base.componentConversionResults().srgba.get())
        let hugeResult = try huge.blendResult(with: white, mode: .multiply).get()
        XCTAssertEqual(try hugeResult.componentConversionResults().srgba.get().red, 1e200)
        let zeroResult = try huge.blendResult(with: huge, mode: .multiply, amount: 0).get()
        XCTAssertEqual(try zeroResult.componentConversionResults().srgba.get().red, 1e200)
        let transparentHuge = try fixedTestColor(space: CGColorSpace.extendedSRGB, components: [1e200, 0, 0, 0])
        let transparentResult = try huge.blendResult(with: transparentHuge, mode: .multiply).get()
        XCTAssertEqual(try transparentResult.componentConversionResults().srgba.get().red, 1e200)
        let negative = try fixedTestColor(space: CGColorSpace.extendedSRGB, components: [-1e308, 0, 0, 1])
        let positive = try fixedTestColor(space: CGColorSpace.extendedSRGB, components: [1e308, 0, 0, 1])
        XCTAssertEqual(negative.blendResult(with: positive, mode: .normal), .failure(.nonfiniteResult))
    }

    func testExplicitAppearanceCapture() throws {
        let source = Color.primary
        XCTAssertEqual(source.blendResult(with: source, mode: .normal),
                       .failure(.unavailableInputs(base: .unresolvedInput, blend: .unresolvedInput)))
        let captured: Color
        #if canImport(UIKit)
        captured = Color(UIColor(source).resolvedColor(with: UITraitCollection(userInterfaceStyle: .light)).cgColor)
        #else
        var components: CGColor?
        let appearance = try XCTUnwrap(NSAppearance(named: .aqua))
        appearance.performAsCurrentDrawingAppearance {
            components = NSColor(source).usingColorSpace(.sRGB)?.cgColor
        }
        captured = Color(try XCTUnwrap(components))
        #endif
        let result = try captured.blendResult(with: captured, mode: .normal).get()
        XCTAssertEqual(try result.componentConversionResults().srgba.get(), try captured.componentConversionResults().srgba.get())
    }

    func testPublicMethodReferencesAndErrorConformances() throws {
        let base = Color(.sRGB, red: 0, green: 0, blue: 0)
        let typed: (Color, BlendMode, CGFloat) -> Result<Color, ColorBlendError> = base.blendResult
        let inferred = base.blendResult
        let unbound = Color.blendResult
        _ = try typed(base, .normal, 1).get()
        _ = try inferred(base, .normal, 1).get()
        _ = try unbound(base)(base, .normal, 1).get()
        func requireConformances<T: Error & Sendable & Equatable>(_: T) {}
        requireConformances(ColorBlendError.invalidAmount)
        let result = base.blendResult(with: .primary, mode: .normal)
        switch result {
        case .success:
            XCTFail("Expected unavailable input")
        case .failure(let error):
            switch error {
            case .invalidAmount, .nonfiniteResult:
                XCTFail("Expected operand diagnosis")
            case let .unavailableInputs(baseIssue, blendIssue):
                XCTAssertNil(baseIssue)
                XCTAssertEqual(blendIssue, .unresolvedInput)
            }
        }
    }
}
