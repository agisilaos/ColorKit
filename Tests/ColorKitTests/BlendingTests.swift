//
//  BlendingTests.swift
//  ColorKitTests
//
//  Created by Agisilaos Tsaraboulidis on 11.03.2024.
//

import SwiftUI
import XCTest

@testable import ColorKit

final class BlendingTests: XCTestCase {
    // MARK: - Blending Mode Tests

    func testNormalBlending() {
        #if canImport(UIKit)
        let baseColor = Color(UIColor(red: 1.0, green: 0.0, blue: 0.0, alpha: 1.0))
        let blendColor = Color(UIColor(red: 0.0, green: 0.0, blue: 1.0, alpha: 1.0))
        #else
        let baseColor = Color(NSColor(red: 1.0, green: 0.0, blue: 0.0, alpha: 1.0))
        let blendColor = Color(NSColor(red: 0.0, green: 0.0, blue: 1.0, alpha: 1.0))
        #endif

        let resultColor = baseColor.blended(with: blendColor, mode: .normal)

        // Expected result is blend color (blue)
        #if canImport(UIKit)
        let uiColor = UIColor(resultColor)
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        #else
        let nsColor = NSColor(resultColor)
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        nsColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        #endif

        XCTAssertEqual(red, 0.0, accuracy: 0.01, "Red should be 0.0")
        XCTAssertEqual(green, 0.0, accuracy: 0.01, "Green should be 0.0")
        XCTAssertEqual(blue, 1.0, accuracy: 0.01, "Blue should be 1.0")
    }

    func testMultiplyBlending() {
        #if canImport(UIKit)
        let baseColor = Color(UIColor(red: 1.0, green: 0.0, blue: 0.0, alpha: 1.0))
        let blendColor = Color(UIColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 1.0))
        #else
        let baseColor = Color(NSColor(red: 1.0, green: 0.0, blue: 0.0, alpha: 1.0))
        let blendColor = Color(NSColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 1.0))
        #endif

        let resultColor = baseColor.blended(with: blendColor, mode: .multiply)

        // Expected result is red at 50% brightness (0.5, 0, 0)
        #if canImport(UIKit)
        let uiColor = UIColor(resultColor)
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        #else
        let nsColor = NSColor(resultColor)
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        nsColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        #endif

        XCTAssertEqual(red, 0.5, accuracy: 0.01, "Red should be 0.5")
        XCTAssertEqual(green, 0.0, accuracy: 0.01, "Green should be 0.0")
        XCTAssertEqual(blue, 0.0, accuracy: 0.01, "Blue should be 0.0")
    }

    func testScreenBlending() {
        #if canImport(UIKit)
        let baseColor = Color(UIColor(red: 0.5, green: 0.0, blue: 0.0, alpha: 1.0))
        let blendColor = Color(UIColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 1.0))
        #else
        let baseColor = Color(NSColor(red: 0.5, green: 0.0, blue: 0.0, alpha: 1.0))
        let blendColor = Color(NSColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 1.0))
        #endif

        let resultColor = baseColor.blended(with: blendColor, mode: .screen)

        // Expected result is (1 - (1-0.5)*(1-0.5), 0.5, 0.5) = (0.75, 0.5, 0.5)
        #if canImport(UIKit)
        let uiColor = UIColor(resultColor)
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        #else
        let nsColor = NSColor(resultColor)
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        nsColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        #endif

        XCTAssertEqual(red, 0.75, accuracy: 0.01, "Red should be 0.75")
        XCTAssertEqual(green, 0.5, accuracy: 0.01, "Green should be 0.5")
        XCTAssertEqual(blue, 0.5, accuracy: 0.01, "Blue should be 0.5")
    }

    func testOverlayBlending() {
        #if canImport(UIKit)
        let baseColor = Color(UIColor(red: 0.5, green: 0.0, blue: 0.0, alpha: 1.0))
        let blendColor = Color(UIColor(red: 1.0, green: 0.0, blue: 0.0, alpha: 1.0))
        #else
        let baseColor = Color(NSColor(red: 0.5, green: 0.0, blue: 0.0, alpha: 1.0))
        let blendColor = Color(NSColor(red: 1.0, green: 0.0, blue: 0.0, alpha: 1.0))
        #endif

        let resultColor = baseColor.blended(with: blendColor, mode: .overlay)

        // Overlay with a pure color tends to saturate that color
        #if canImport(UIKit)
        let uiColor = UIColor(resultColor)
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        #else
        let nsColor = NSColor(resultColor)
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        nsColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        #endif

        XCTAssertEqual(red, 1.0, accuracy: 0.01, "Red should be 1.0")
        XCTAssertEqual(green, 0.0, accuracy: 0.01, "Green should be 0.0")
        XCTAssertEqual(blue, 0.0, accuracy: 0.01, "Blue should be 0.0")
    }

    func testAlphaBlending() {
        #if canImport(UIKit)
        let baseColor = Color(UIColor(red: 1.0, green: 0.0, blue: 0.0, alpha: 1.0))
        let blendColor = Color(UIColor(red: 0.0, green: 0.0, blue: 1.0, alpha: 0.5))
        #else
        let baseColor = Color(NSColor(red: 1.0, green: 0.0, blue: 0.0, alpha: 1.0))
        let blendColor = Color(NSColor(red: 0.0, green: 0.0, blue: 1.0, alpha: 0.5))
        #endif

        let resultColor = baseColor.blended(with: blendColor, mode: .normal)

        // Expected result is a purple-ish color (0.5, 0, 0.5)
        #if canImport(UIKit)
        let uiColor = UIColor(resultColor)
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        #else
        let nsColor = NSColor(resultColor)
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        nsColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        #endif

        XCTAssertEqual(red, 0.5, accuracy: 0.01, "Red should be 0.5")
        XCTAssertEqual(green, 0.0, accuracy: 0.01, "Green should be 0.0")
        XCTAssertEqual(blue, 0.5, accuracy: 0.01, "Blue should be 0.5")
    }

    func testAlphaBoundaryValues() {
        #if canImport(UIKit)
        let baseColor = Color(UIColor(red: 1.0, green: 0.0, blue: 0.0, alpha: 1.0))
        let transparentColor = Color(UIColor(red: 0.0, green: 0.0, blue: 1.0, alpha: 0.0))
        let opaqueColor = Color(UIColor(red: 0.0, green: 0.0, blue: 1.0, alpha: 1.0))
        #else
        let baseColor = Color(NSColor(red: 1.0, green: 0.0, blue: 0.0, alpha: 1.0))
        let transparentColor = Color(NSColor(red: 0.0, green: 0.0, blue: 1.0, alpha: 0.0))
        let opaqueColor = Color(NSColor(red: 0.0, green: 0.0, blue: 1.0, alpha: 1.0))
        #endif

        // Test with alpha = 0 (should be unchanged base color)
        let transparentResult = baseColor.blended(with: transparentColor, mode: .normal)

        #if canImport(UIKit)
        var uiColor = UIColor(transparentResult)
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        #else
        var nsColor = NSColor(transparentResult)
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        nsColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        #endif

        XCTAssertEqual(red, 1.0, accuracy: 0.01, "Red should be 1.0 for transparent blend")
        XCTAssertEqual(green, 0.0, accuracy: 0.01, "Green should be 0.0 for transparent blend")
        XCTAssertEqual(blue, 0.0, accuracy: 0.01, "Blue should be 0.0 for transparent blend")

        // Test with alpha = 1 (should be full blend)
        let opaqueResult = baseColor.blended(with: opaqueColor, mode: .normal)

        #if canImport(UIKit)
        uiColor = UIColor(opaqueResult)
        uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        #else
        nsColor = NSColor(opaqueResult)
        nsColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        #endif

        XCTAssertEqual(red, 0.0, accuracy: 0.01, "Red should be 0.0 for opaque blend")
        XCTAssertEqual(green, 0.0, accuracy: 0.01, "Green should be 0.0 for opaque blend")
        XCTAssertEqual(blue, 1.0, accuracy: 0.01, "Blue should be 1.0 for opaque blend")
    }

    func testDarkenBlending() {
        #if canImport(UIKit)
        let baseColor = Color(UIColor(red: 0.7, green: 0.7, blue: 0.5, alpha: 1.0))
        let blendColor = Color(UIColor(red: 0.3, green: 0.3, blue: 0.5, alpha: 1.0))
        #else
        let baseColor = Color(NSColor(red: 0.7, green: 0.7, blue: 0.5, alpha: 1.0))
        let blendColor = Color(NSColor(red: 0.3, green: 0.3, blue: 0.5, alpha: 1.0))
        #endif

        let resultColor = baseColor.blended(with: blendColor, mode: .darken)

        // Expected result is (min(0.7, 0.3), min(0.7, 0.3), min(0.5, 0.5)) = (0.3, 0.3, 0.5)
        #if canImport(UIKit)
        let uiColor = UIColor(resultColor)
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        #else
        let nsColor = NSColor(resultColor)
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        nsColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        #endif

        XCTAssertEqual(red, 0.3, accuracy: 0.01, "Red should be 0.3")
        XCTAssertEqual(green, 0.3, accuracy: 0.01, "Green should be 0.3")
        XCTAssertEqual(blue, 0.5, accuracy: 0.01, "Blue should be 0.5")
    }

    func testLightenBlending() {
        #if canImport(UIKit)
        let baseColor = Color(UIColor(red: 0.7, green: 0.7, blue: 0.5, alpha: 1.0))
        let blendColor = Color(UIColor(red: 0.3, green: 0.3, blue: 0.5, alpha: 1.0))
        #else
        let baseColor = Color(NSColor(red: 0.7, green: 0.7, blue: 0.5, alpha: 1.0))
        let blendColor = Color(NSColor(red: 0.3, green: 0.3, blue: 0.5, alpha: 1.0))
        #endif

        let resultColor = baseColor.blended(with: blendColor, mode: .lighten)

        // Expected result is (max(0.7, 0.3), max(0.7, 0.3), max(0.5, 0.5)) = (0.7, 0.7, 0.5)
        #if canImport(UIKit)
        let uiColor = UIColor(resultColor)
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        #else
        let nsColor = NSColor(resultColor)
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        nsColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        #endif

        XCTAssertEqual(red, 0.7, accuracy: 0.01, "Red should be 0.7")
        XCTAssertEqual(green, 0.7, accuracy: 0.01, "Green should be 0.7")
        XCTAssertEqual(blue, 0.5, accuracy: 0.01, "Blue should be 0.5")
    }

    func testDifferenceBlending() {
        #if canImport(UIKit)
        let baseColor = Color(UIColor(red: 0.7, green: 0.7, blue: 0.5, alpha: 1.0))
        let blendColor = Color(UIColor(red: 0.3, green: 0.3, blue: 0.5, alpha: 1.0))
        #else
        let baseColor = Color(NSColor(red: 0.7, green: 0.7, blue: 0.5, alpha: 1.0))
        let blendColor = Color(NSColor(red: 0.3, green: 0.3, blue: 0.5, alpha: 1.0))
        #endif

        let resultColor = baseColor.blended(with: blendColor, mode: .difference)

        // Expected result is (|0.7 - 0.3|, |0.7 - 0.3|, |0.5 - 0.5|) = (0.4, 0.4, 0.0)
        #if canImport(UIKit)
        let uiColor = UIColor(resultColor)
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        #else
        let nsColor = NSColor(resultColor)
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        nsColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        #endif

        XCTAssertEqual(red, 0.4, accuracy: 0.01, "Red should be 0.4")
        XCTAssertEqual(green, 0.4, accuracy: 0.01, "Green should be 0.4")
        XCTAssertEqual(blue, 0.0, accuracy: 0.01, "Blue should be 0.0")
    }

    func testExclusionBlending() {
        #if canImport(UIKit)
        let baseColor = Color(UIColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 1.0))
        let blendColor = Color(UIColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 1.0))
        #else
        let baseColor = Color(NSColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 1.0))
        let blendColor = Color(NSColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 1.0))
        #endif

        let resultColor = baseColor.blended(with: blendColor, mode: .exclusion)

        // Exclusion of two identical 50% gray colors results in 50% gray
        // The formula is: result = base + blend - 2 * base * blend
        // For 50% gray: 0.5 + 0.5 - 2 * 0.5 * 0.5 = 1.0 - 0.5 = 0.5
        #if canImport(UIKit)
        let uiColor = UIColor(resultColor)
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        #else
        let nsColor = NSColor(resultColor)
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        nsColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        #endif

        XCTAssertEqual(red, 0.5, accuracy: 0.01, "Red should be 0.5")
        XCTAssertEqual(green, 0.5, accuracy: 0.01, "Green should be 0.5")
        XCTAssertEqual(blue, 0.5, accuracy: 0.01, "Blue should be 0.5")
    }

    // MARK: - Edge Cases

    func testBlendingWithSameColor() {
        #if canImport(UIKit)
        let color = Color(UIColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 1.0))
        #else
        let color = Color(NSColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 1.0))
        #endif

        // Test normal blend mode with the same color (should return the same color)
        let normalResult = color.blended(with: color, mode: .normal)

        // Check that normal blend preserves the original color
        #if canImport(UIKit)
        let uiColor = UIColor(normalResult)
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        #else
        let nsColor = NSColor(normalResult)
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        nsColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        #endif

        XCTAssertEqual(red, 0.5, accuracy: 0.01, "Red should be 0.5")
        XCTAssertEqual(green, 0.5, accuracy: 0.01, "Green should be 0.5")
        XCTAssertEqual(blue, 0.5, accuracy: 0.01, "Blue should be 0.5")

        // We could test other blend modes too, but this is sufficient to verify functionality
    }

    func testBlendingWithBlackAndWhite() {
        #if canImport(UIKit)
        let color = Color(UIColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 1.0))
        let black = Color(UIColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 1.0))
        let white = Color(UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0))
        #else
        let color = Color(NSColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 1.0))
        let black = Color(NSColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 1.0))
        let white = Color(NSColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0))
        #endif

        // Multiply with black should give black
        let multiplyBlack = color.blended(with: black, mode: .multiply)

        #if canImport(UIKit)
        var uiColor = UIColor(multiplyBlack)
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        #else
        var nsColor = NSColor(multiplyBlack)
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        nsColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        #endif

        XCTAssertEqual(red, 0.0, accuracy: 0.01, "Multiply with black should give black")
        XCTAssertEqual(green, 0.0, accuracy: 0.01, "Multiply with black should give black")
        XCTAssertEqual(blue, 0.0, accuracy: 0.01, "Multiply with black should give black")

        // Screen with white should give white
        let screenWhite = color.blended(with: white, mode: .screen)

        #if canImport(UIKit)
        uiColor = UIColor(screenWhite)
        uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        #else
        nsColor = NSColor(screenWhite)
        nsColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        #endif

        XCTAssertEqual(red, 1.0, accuracy: 0.01, "Screen with white should give white")
        XCTAssertEqual(green, 1.0, accuracy: 0.01, "Screen with white should give white")
        XCTAssertEqual(blue, 1.0, accuracy: 0.01, "Screen with white should give white")
    }
}
