//
//  AccessiblePaletteGeneratorTests.swift
//  ColorKitTests
//
//  Created by Agisilaos Tsaraboulidis on 12.03.2024.
//
//  Description:
//  Tests for the accessible palette generator functionality.
//
//  Features:
//  - Tests basic configuration properties
//  - Tests core functionality without relying on complex SwiftUI operations
//
//  License:
//  MIT License. See LICENSE file for details.
//

import SwiftUI
import XCTest

@testable import ColorKit

final class AccessiblePaletteGeneratorTests: XCTestCase {
    // MARK: - Configuration Tests

    func testConfigurationInitialization() {
        // Test default values
        let defaultConfig = AccessiblePaletteGenerator.Configuration()
        XCTAssertEqual(defaultConfig.targetLevel, .AA)
        XCTAssertEqual(defaultConfig.paletteSize, 5)
        XCTAssertTrue(defaultConfig.includeBlackAndWhite)
        XCTAssertEqual(defaultConfig.minimumContrastRatio, 4.5) // AA level ratio

        // Test custom values
        let customConfig = AccessiblePaletteGenerator.Configuration(
            targetLevel: .AAA,
            paletteSize: 7,
            includeBlackAndWhite: false
        )
        XCTAssertEqual(customConfig.targetLevel, .AAA)
        XCTAssertEqual(customConfig.paletteSize, 7)
        XCTAssertFalse(customConfig.includeBlackAndWhite)
        XCTAssertEqual(customConfig.minimumContrastRatio, 7.0) // AAA level ratio

        // Test minimum palette size enforcement
        let smallConfig = AccessiblePaletteGenerator.Configuration(paletteSize: 1)
        XCTAssertEqual(smallConfig.paletteSize, 2) // Should enforce minimum of 2
    }

    // MARK: - Generator Tests

    func testGeneratorInitialization() {
        // Test that generators can be created without errors
        let defaultGenerator = AccessiblePaletteGenerator()
        XCTAssertNotNil(defaultGenerator)

        let customConfig = AccessiblePaletteGenerator.Configuration(
            targetLevel: .AAA,
            paletteSize: 5,
            includeBlackAndWhite: false
        )
        let customGenerator = AccessiblePaletteGenerator(configuration: customConfig)
        XCTAssertNotNil(customGenerator)
    }

    // MARK: - WCAG Contrast Level Tests

    func testWCAGContrastLevels() {
        // Test minimum ratios for each level
        XCTAssertEqual(WCAGContrastLevel.AALarge.minimumRatio, 3.0)
        XCTAssertEqual(WCAGContrastLevel.AA.minimumRatio, 4.5)
        XCTAssertEqual(WCAGContrastLevel.AAALarge.minimumRatio, 4.5)
        XCTAssertEqual(WCAGContrastLevel.AAA.minimumRatio, 7.0)
    }
}
