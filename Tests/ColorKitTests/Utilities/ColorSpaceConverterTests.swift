//
//  ColorSpaceConverterTests.swift
//  ColorKitTests
//
//  Created by Agisilaos Tsaraboulidis on 19.03.2025.
//
//  Description:
//  Tests for color space conversion functionality.
//
//  Features:
//  - Tests for RGB color space conversions
//  - Tests for HSL color space conversions
//  - Tests for CMYK color space conversions
//  - Tests for LAB color space conversions
//  - Tests for XYZ color space conversions
//  - Tests for color component descriptions
//
//  License:
//  MIT License. See LICENSE file for details.
//

import SwiftUI
import XCTest

@testable import ColorKit

final class ColorSpaceConverterTests: XCTestCase {
    func testColorSpaceComponentsConversion() {
        // Create specific colors with known RGB values instead of using system colors
        let red = Color(red: 1.0, green: 0.0, blue: 0.0, opacity: 1.0)
        let green = Color(red: 0.0, green: 1.0, blue: 0.0, opacity: 1.0)
        let blue = Color(red: 0.0, green: 0.0, blue: 1.0, opacity: 1.0)
        let white = Color(red: 1.0, green: 1.0, blue: 1.0, opacity: 1.0)
        let black = Color(red: 0.0, green: 0.0, blue: 0.0, opacity: 1.0)

        // Get components
        let redComponents = red.colorSpaceComponents()
        let greenComponents = green.colorSpaceComponents()
        let blueComponents = blue.colorSpaceComponents()
        let whiteComponents = white.colorSpaceComponents()
        let blackComponents = black.colorSpaceComponents()

        // Test RGB values
        // Red
        XCTAssertEqual(redComponents.rgb.red, 1.0, accuracy: 0.01)
        XCTAssertEqual(redComponents.rgb.green, 0.0, accuracy: 0.01)
        XCTAssertEqual(redComponents.rgb.blue, 0.0, accuracy: 0.01)

        // Green
        XCTAssertEqual(greenComponents.rgb.red, 0.0, accuracy: 0.01)
        XCTAssertEqual(greenComponents.rgb.green, 1.0, accuracy: 0.01)
        XCTAssertEqual(greenComponents.rgb.blue, 0.0, accuracy: 0.01)

        // Blue
        XCTAssertEqual(blueComponents.rgb.red, 0.0, accuracy: 0.01)
        XCTAssertEqual(blueComponents.rgb.green, 0.0, accuracy: 0.01)
        XCTAssertEqual(blueComponents.rgb.blue, 1.0, accuracy: 0.01)

        // White
        XCTAssertEqual(whiteComponents.rgb.red, 1.0, accuracy: 0.01)
        XCTAssertEqual(whiteComponents.rgb.green, 1.0, accuracy: 0.01)
        XCTAssertEqual(whiteComponents.rgb.blue, 1.0, accuracy: 0.01)

        // Black
        XCTAssertEqual(blackComponents.rgb.red, 0.0, accuracy: 0.01)
        XCTAssertEqual(blackComponents.rgb.green, 0.0, accuracy: 0.01)
        XCTAssertEqual(blackComponents.rgb.blue, 0.0, accuracy: 0.01)

        // Test HSL values
        // Red should have hue around 0/360
        XCTAssertTrue(redComponents.hsl.hue < 0.05 || redComponents.hsl.hue > 0.95)
        XCTAssertEqual(redComponents.hsl.saturation, 1.0, accuracy: 0.05)

        // Green should have hue around 120° (0.33)
        XCTAssertEqual(greenComponents.hsl.hue, 0.33, accuracy: 0.05)
        XCTAssertEqual(greenComponents.hsl.saturation, 1.0, accuracy: 0.05)

        // Blue should have hue around 240° (0.66)
        XCTAssertEqual(blueComponents.hsl.hue, 0.66, accuracy: 0.05)
        XCTAssertEqual(blueComponents.hsl.saturation, 1.0, accuracy: 0.05)

        // White should have 0 saturation and 1.0 lightness
        XCTAssertEqual(whiteComponents.hsl.saturation, 0.0, accuracy: 0.05)
        XCTAssertEqual(whiteComponents.hsl.lightness, 1.0, accuracy: 0.05)

        // Black should have 0 saturation and 0.0 lightness
        XCTAssertEqual(blackComponents.hsl.saturation, 0.0, accuracy: 0.05)
        XCTAssertEqual(blackComponents.hsl.lightness, 0.0, accuracy: 0.05)

        // Test LAB values - these are approximate and may vary by color space conversion
        // White should have L around 100
        XCTAssertEqual(whiteComponents.lab.l, 100.0, accuracy: 5.0)

        // Black should have L around 0
        XCTAssertEqual(blackComponents.lab.l, 0.0, accuracy: 5.0)
    }

    func testColorComponentsDescription() {
        let color = Color(red: 1.0, green: 0.0, blue: 0.0, opacity: 1.0) // Red with known RGB values
        let components = color.colorSpaceComponents()

        // Description should contain all color space names
        let description = components.description
        XCTAssertTrue(description.contains("RGB"))
        XCTAssertTrue(description.contains("HSL"))
        XCTAssertTrue(description.contains("HSB"))
        XCTAssertTrue(description.contains("CMYK"))
        XCTAssertTrue(description.contains("LAB"))
        XCTAssertTrue(description.contains("XYZ"))
    }

    func testHexCodeRoundtripping() {
        let hex = "#232323FF" // known to cause rounding issues when round tripping
        let color = Color(hex: hex)
        let hex2 = color?.hexString() ?? ""
        XCTAssertEqual(hex, hex2)
    }

    func testXYZConversion() {
        let white = Color(red: 1.0, green: 1.0, blue: 1.0, opacity: 1.0) // White with known RGB values
        let components = white.colorSpaceComponents()

        // White in XYZ should have Y close to 100
        XCTAssertEqual(components.xyz.y, 100.0, accuracy: 5.0)
    }

    func testLABMatchesStandaloneConversionForExplicitSRGBColors() throws {
        for rgb in srgbSamples {
            let color = Color(.sRGB, red: rgb.red, green: rgb.green, blue: rgb.blue)
            let standalone = try XCTUnwrap(color.labComponents())
            let aggregate = ColorSpaceConverter(color: color).getAllColorComponents().lab

            XCTAssertEqual(aggregate.l, Double(standalone.L), accuracy: 0.0001, "RGB: \(rgb)")
            XCTAssertEqual(aggregate.a, Double(standalone.a), accuracy: 0.0001, "RGB: \(rgb)")
            XCTAssertEqual(aggregate.b, Double(standalone.b), accuracy: 0.0001, "RGB: \(rgb)")
        }
    }

    func testAggregateLABRoundTripsToSRGB() {
        for rgb in srgbSamples {
            let color = Color(.sRGB, red: rgb.red, green: rgb.green, blue: rgb.blue)
            let lab = color.colorSpaceComponents().lab
            let restored = Color(L: CGFloat(lab.l), a: CGFloat(lab.a), b: CGFloat(lab.b)).rgbaComponents()

            XCTAssertEqual(restored.red, rgb.red, accuracy: 0.00002, "RGB: \(rgb)")
            XCTAssertEqual(restored.green, rgb.green, accuracy: 0.00002, "RGB: \(rgb)")
            XCTAssertEqual(restored.blue, rgb.blue, accuracy: 0.00002, "RGB: \(rgb)")
        }
    }

    func testPrimaryXYZValuesUseReferenceWhiteY100Scale() {
        let samples: [(rgb: (Double, Double, Double), xyz: (Double, Double, Double))] = [
            ((1, 0, 0), (41.24564, 21.26729, 1.93339)),
            ((0, 1, 0), (35.75761, 71.51522, 11.9192)),
            ((0, 0, 1), (18.04375, 7.2175, 95.03041)),
            ((1, 1, 1), (95.047, 100.00001, 108.883)),
            ((0.5, 0.5, 0.5), (20.34396828, 21.40411619, 23.30544150)),
            ((0, 0, 0), (0, 0, 0))
        ]

        for (rgb, expected) in samples {
            let color = Color(.sRGB, red: rgb.0, green: rgb.1, blue: rgb.2)
            let xyz = color.colorSpaceComponents().xyz

            XCTAssertEqual(xyz.x, expected.0, accuracy: 0.0001, "RGB: \(rgb)")
            XCTAssertEqual(xyz.y, expected.1, accuracy: 0.0001, "RGB: \(rgb)")
            XCTAssertEqual(xyz.z, expected.2, accuracy: 0.0001, "RGB: \(rgb)")
        }
    }

    func testSRGBLinearizationThreshold() {
        // Fixed reference values below, at, and above the encoded-sRGB breakpoint.
        let samples: [(value: Double, xyz: (Double, Double, Double))] = [
            (0.040449, (0.002975662618421053, 0.003130727867252322, 0.003408830082817338)),
            (0.040450, (0.002975736184210526, 0.003130805266640867, 0.003408914357585139)),
            (0.040451, (0.002975813221014465, 0.003130886317922488, 0.003409002608643282))
        ]

        for (value, expected) in samples {
            let xyz = SRGBColorConversion.xyz(from: (value, value, value))

            XCTAssertEqual(xyz.x, expected.0, accuracy: 1e-15, "sRGB: \(value)")
            XCTAssertEqual(xyz.y, expected.1, accuracy: 1e-15, "sRGB: \(value)")
            XCTAssertEqual(xyz.z, expected.2, accuracy: 1e-15, "sRGB: \(value)")
        }
    }

    func testLABThresholdAndD65Normalization() {
        let samples: [(y: Double, lab: (Double, Double, Double))] = [
            (0.008855, (7.998650660, 396.557540258621, -158.623016103448)),
            (0.008856, (7.999553952, 396.553646758621, -158.621458703448)),
            (0.008857, (8.000495286075, 396.549589284159, -158.619835713664))
        ]

        for (y, expected) in samples {
            // X and Z are the D65 reference white; only Y crosses the LAB breakpoint.
            let lab = SRGBColorConversion.lab(from: (0.95047, y, 1.08883))

            XCTAssertEqual(lab.l, expected.0, accuracy: 1e-9, "Y: \(y)")
            XCTAssertEqual(lab.a, expected.1, accuracy: 1e-9, "Y: \(y)")
            XCTAssertEqual(lab.b, expected.2, accuracy: 1e-9, "Y: \(y)")
        }

        let white = SRGBColorConversion.lab(from: (0.95047, 1, 1.08883))
        XCTAssertEqual(white.l, 100, accuracy: 1e-12)
        XCTAssertEqual(white.a, 0, accuracy: 1e-12)
        XCTAssertEqual(white.b, 0, accuracy: 1e-12)
    }

    func testAggregateLABDoesNotUseOrReplaceStandaloneCache() throws {
        let color = Color(.sRGB, red: 1, green: 0, blue: 0)
        ColorCache.shared.clearCache()
        defer { ColorCache.shared.clearCache() }
        ColorCache.shared.cacheLABComponents(for: color, L: 12, a: 34, b: 56)

        let aggregate = color.colorSpaceComponents().lab
        let cached = try XCTUnwrap(color.labComponents())

        XCTAssertEqual(aggregate.l, 53.24079414, accuracy: 0.0001)
        XCTAssertEqual(aggregate.a, 80.09245960, accuracy: 0.0001)
        XCTAssertEqual(aggregate.b, 67.20319652, accuracy: 0.0001)
        XCTAssertEqual(cached.L, 12)
        XCTAssertEqual(cached.a, 34)
        XCTAssertEqual(cached.b, 56)
    }

    func testCMYKConversion() {
        // Create primary colors with known RGB values
        let red = Color(red: 1.0, green: 0.0, blue: 0.0, opacity: 1.0)
        let green = Color(red: 0.0, green: 1.0, blue: 0.0, opacity: 1.0)
        let blue = Color(red: 0.0, green: 0.0, blue: 1.0, opacity: 1.0)
        let black = Color(red: 0.0, green: 0.0, blue: 0.0, opacity: 1.0)

        let redComponents = red.colorSpaceComponents()
        let greenComponents = green.colorSpaceComponents()
        let blueComponents = blue.colorSpaceComponents()
        let blackComponents = black.colorSpaceComponents()

        // Red should be (0, 1, 1, 0) in CMYK
        XCTAssertEqual(redComponents.cmyk.cyan, 0.0, accuracy: 0.05)
        XCTAssertEqual(redComponents.cmyk.magenta, 1.0, accuracy: 0.05)
        XCTAssertEqual(redComponents.cmyk.yellow, 1.0, accuracy: 0.05)
        XCTAssertEqual(redComponents.cmyk.key, 0.0, accuracy: 0.05)

        // Green should be (1, 0, 1, 0) in CMYK
        XCTAssertEqual(greenComponents.cmyk.cyan, 1.0, accuracy: 0.05)
        XCTAssertEqual(greenComponents.cmyk.magenta, 0.0, accuracy: 0.05)
        XCTAssertEqual(greenComponents.cmyk.yellow, 1.0, accuracy: 0.05)
        XCTAssertEqual(greenComponents.cmyk.key, 0.0, accuracy: 0.05)

        // Blue should be (1, 1, 0, 0) in CMYK
        XCTAssertEqual(blueComponents.cmyk.cyan, 1.0, accuracy: 0.05)
        XCTAssertEqual(blueComponents.cmyk.magenta, 1.0, accuracy: 0.05)
        XCTAssertEqual(blueComponents.cmyk.yellow, 0.0, accuracy: 0.05)
        XCTAssertEqual(blueComponents.cmyk.key, 0.0, accuracy: 0.05)

        // Black should have high key/black value
        XCTAssertEqual(blackComponents.cmyk.key, 1.0, accuracy: 0.05)
    }

    private var srgbSamples: [(red: Double, green: Double, blue: Double)] {
        [
            (1, 0, 0), (0, 1, 0), (0, 0, 1),
            (0, 0, 0), (1, 1, 1), (0.5, 0.5, 0.5), (0.01, 0.01, 0.01),
            (0.2, 0.4, 0.6), (0.73, 0.21, 0.49), (0.9, 0.7, 0.2),
            (0.040449, 0.04045, 0.040451)
        ]
    }
}
