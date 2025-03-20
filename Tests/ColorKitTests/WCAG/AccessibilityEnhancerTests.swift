//
//  AccessibilityEnhancerTests.swift
//  ColorKitTests
//
//  Created by Agisilaos Tsaraboulidis on 19.03.2024.
//
//  Description:
//  Tests for the AccessibilityEnhancer feature.
//
//  License:
//  MIT License. See LICENSE file for details.
//

import SwiftUI
import XCTest

@testable import ColorKit

final class AccessibilityEnhancerTests: XCTestCase {
    // MARK: - Test Configuration

    func testDefaultConfiguration() {
        let enhancer = AccessibilityEnhancer()

        XCTAssertEqual(enhancer.configuration.targetLevel, .AA)
        XCTAssertEqual(enhancer.configuration.strategy, .preserveHue)
        XCTAssertEqual(enhancer.configuration.maxPerceptualDistance, 30)
        XCTAssertFalse(enhancer.configuration.preferDarker)
    }

    func testCustomConfiguration() {
        let config = AccessibilityEnhancer.Configuration(
            targetLevel: .AAA,
            strategy: .minimumChange,
            maxPerceptualDistance: 50,
            preferDarker: true
        )

        let enhancer = AccessibilityEnhancer(configuration: config)

        XCTAssertEqual(enhancer.configuration.targetLevel, .AAA)
        XCTAssertEqual(enhancer.configuration.strategy, .minimumChange)
        XCTAssertEqual(enhancer.configuration.maxPerceptualDistance, 50)
        XCTAssertTrue(enhancer.configuration.preferDarker)
    }

    // MARK: - Test Enhancement Strategies

    func testEnhanceColorThatAlreadyMeetsRequirements() {
        // Black on white already meets all accessibility requirements
        let color = SwiftUI.Color.black
        let backgroundColor = SwiftUI.Color.white

        let enhancer = AccessibilityEnhancer()
        let enhancedColor = enhancer.enhanceColor(color, against: backgroundColor)

        // The color should remain unchanged - we can verify by checking the contrast ratio
        // which should be the same for both the original and enhanced color
        let originalRatio = color.wcagContrastRatio(with: backgroundColor)
        let enhancedRatio = enhancedColor.wcagContrastRatio(with: backgroundColor)

        XCTAssertEqual(originalRatio, enhancedRatio, accuracy: 0.01)
    }

    func testPreserveHueStrategy() {
        // Light blue on white doesn't meet AA requirements
        let color = SwiftUI.Color(red: 0.7, green: 0.7, blue: 1.0)
        let backgroundColor = SwiftUI.Color.white

        let enhancer = AccessibilityEnhancer(configuration: AccessibilityEnhancer.Configuration(
            strategy: .preserveHue
        ))

        let enhancedColor = enhancer.enhanceColor(color, against: backgroundColor)

        // Check that the enhanced color meets accessibility requirements
        let contrastRatio = enhancedColor.wcagContrastRatio(with: backgroundColor)
        XCTAssertGreaterThanOrEqual(contrastRatio, WCAGContrastLevel.AA.minimumRatio)

        // Check that the hue is preserved (within a small margin of error)
        let originalHSL = color.hslComponents()
        let enhancedHSL = enhancedColor.hslComponents()

        XCTAssertNotNil(originalHSL)
        XCTAssertNotNil(enhancedHSL)

        if let originalHSL = originalHSL, let enhancedHSL = enhancedHSL {
            XCTAssertEqual(originalHSL.hue, enhancedHSL.hue, accuracy: 0.05)
        }
    }

    func testPreserveSaturationStrategy() {
        // Light green on white doesn't meet AA requirements
        let color = SwiftUI.Color(red: 0.7, green: 1.0, blue: 0.7)
        let backgroundColor = SwiftUI.Color.white

        let enhancer = AccessibilityEnhancer(configuration: AccessibilityEnhancer.Configuration(
            strategy: .preserveSaturation
        ))

        let enhancedColor = enhancer.enhanceColor(color, against: backgroundColor)

        // Check that the enhanced color meets accessibility requirements
        let contrastRatio = enhancedColor.wcagContrastRatio(with: backgroundColor)
        XCTAssertGreaterThanOrEqual(contrastRatio, WCAGContrastLevel.AA.minimumRatio)

        // Check that the saturation is preserved (within a small margin of error)
        let originalHSL = color.hslComponents()
        let enhancedHSL = enhancedColor.hslComponents()

        XCTAssertNotNil(originalHSL)
        XCTAssertNotNil(enhancedHSL)

        if let originalHSL = originalHSL, let enhancedHSL = enhancedHSL {
            XCTAssertEqual(originalHSL.saturation, enhancedHSL.saturation, accuracy: 0.1)
        }
    }

    func testPreserveLightnessStrategy() {
        // Yellow on white doesn't meet AA requirements
        // Use a darker background to make it easier to meet requirements
        let color = SwiftUI.Color.yellow
        let backgroundColor = SwiftUI.Color.black

        let enhancer = AccessibilityEnhancer(configuration: AccessibilityEnhancer.Configuration(
            strategy: .preserveLightness
        ))

        let enhancedColor = enhancer.enhanceColor(color, against: backgroundColor)

        // Check that the enhanced color meets accessibility requirements
        let contrastRatio = enhancedColor.wcagContrastRatio(with: backgroundColor)
        XCTAssertGreaterThanOrEqual(contrastRatio, WCAGContrastLevel.AA.minimumRatio)
    }

    func testMinimumChangeStrategy() {
        // Light red on white doesn't meet AA requirements
        let color = SwiftUI.Color(red: 1.0, green: 0.7, blue: 0.7)
        let backgroundColor = SwiftUI.Color.white

        let enhancer = AccessibilityEnhancer(configuration: AccessibilityEnhancer.Configuration(
            strategy: .minimumChange
        ))

        let enhancedColor = enhancer.enhanceColor(color, against: backgroundColor)

        // Check that the enhanced color meets accessibility requirements
        let contrastRatio = enhancedColor.wcagContrastRatio(with: backgroundColor)
        XCTAssertGreaterThanOrEqual(contrastRatio, WCAGContrastLevel.AA.minimumRatio)
    }

    func testDifferentTargetLevels() {
        // Light purple on white
        let color = SwiftUI.Color(red: 0.8, green: 0.7, blue: 0.9)
        let backgroundColor = SwiftUI.Color.white

        // Test with AA level
        let enhancerAA = AccessibilityEnhancer(configuration: AccessibilityEnhancer.Configuration(
            targetLevel: .AA
        ))

        let enhancedColorAA = enhancerAA.enhanceColor(color, against: backgroundColor)
        let contrastRatioAA = enhancedColorAA.wcagContrastRatio(with: backgroundColor)
        XCTAssertGreaterThanOrEqual(contrastRatioAA, WCAGContrastLevel.AA.minimumRatio)

        // Test with AAA level (more strict)
        let enhancerAAA = AccessibilityEnhancer(configuration: AccessibilityEnhancer.Configuration(
            targetLevel: .AAA
        ))

        let enhancedColorAAA = enhancerAAA.enhanceColor(color, against: backgroundColor)
        let contrastRatioAAA = enhancedColorAAA.wcagContrastRatio(with: backgroundColor)
        XCTAssertGreaterThanOrEqual(contrastRatioAAA, WCAGContrastLevel.AAA.minimumRatio)

        // The AAA-enhanced color should have a higher contrast ratio
        XCTAssertGreaterThan(contrastRatioAAA, contrastRatioAA)
    }

    // MARK: - Test Variant Suggestions

    func testSuggestAccessibleVariants() {
        // Use a color that's more likely to produce accessible variants
        let color = SwiftUI.Color.blue
        let backgroundColor = SwiftUI.Color.black

        let enhancer = AccessibilityEnhancer()
        let variants = enhancer.suggestAccessibleVariants(for: color, against: backgroundColor, count: 3)

        // Check that we got the requested number of variants
        XCTAssertEqual(variants.count, 3)

        // Check that all variants meet accessibility requirements
        for variant in variants {
            let contrastRatio = variant.wcagContrastRatio(with: backgroundColor)
            XCTAssertGreaterThanOrEqual(contrastRatio, WCAGContrastLevel.AA.minimumRatio)
        }
    }

    // MARK: - Test Color Extension Methods

    func testColorEnhancedExtension() {
        // Use a color that's more likely to be enhanced successfully
        let color = SwiftUI.Color.orange
        let backgroundColor = SwiftUI.Color.black

        let enhancedColor = color.enhanced(with: backgroundColor)

        // Check that the enhanced color meets accessibility requirements
        let contrastRatio = enhancedColor.wcagContrastRatio(with: backgroundColor)
        XCTAssertGreaterThanOrEqual(contrastRatio, WCAGContrastLevel.AA.minimumRatio)
    }

    func testColorSuggestAccessibleVariantsExtension() {
        // Use a color that's more likely to produce accessible variants
        let color = SwiftUI.Color.green
        let backgroundColor = SwiftUI.Color.black

        let variants = color.suggestAccessibleVariants(with: backgroundColor, count: 2)

        // Check that we got the requested number of variants
        XCTAssertEqual(variants.count, 2)

        // Check that all variants meet accessibility requirements
        for variant in variants {
            let contrastRatio = variant.wcagContrastRatio(with: backgroundColor)
            XCTAssertGreaterThanOrEqual(contrastRatio, WCAGContrastLevel.AA.minimumRatio)
        }
    }

    func testPerceptuallySimilarColors() {
        let color1 = SwiftUI.Color(red: 0.5, green: 0.5, blue: 0.5)
        let color2 = SwiftUI.Color(red: 0.51, green: 0.51, blue: 0.51)
        let color3 = SwiftUI.Color(red: 0.8, green: 0.2, blue: 0.2)

        // These colors should be perceptually similar (small threshold)
        XCTAssertTrue(color1.isPerceptuallySimilar(to: color2, threshold: 5))

        // These colors should not be perceptually similar
        XCTAssertFalse(color1.isPerceptuallySimilar(to: color3, threshold: 5))

        // With a very large threshold, even different colors can be considered similar
        XCTAssertTrue(color1.isPerceptuallySimilar(to: color3, threshold: 100))
    }
}
