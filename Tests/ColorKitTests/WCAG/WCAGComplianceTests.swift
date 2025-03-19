import XCTest
@testable import ColorKit
import SwiftUI

final class WCAGComplianceTests: XCTestCase {
    // Test colors
    let white = Color.white
    let black = Color.black
    let gray50 = Color(.sRGB, red: 0.5, green: 0.5, blue: 0.5, opacity: 1)
    let blue = Color.blue
    let red = Color.red
    
    func testRelativeLuminance() throws {
        // White should have relative luminance of 1.0
        XCTAssertEqual(white.wcagRelativeLuminance(), 1.0, accuracy: 0.01)
        
        // Black should have relative luminance of 0.0
        XCTAssertEqual(black.wcagRelativeLuminance(), 0.0, accuracy: 0.01)
        
        // 50% gray should have relative luminance around 0.21
        XCTAssertEqual(gray50.wcagRelativeLuminance(), 0.21, accuracy: 0.01)
    }
    
    func testContrastRatio() throws {
        // White on black should have maximum contrast ratio (21:1)
        XCTAssertEqual(white.wcagContrastRatio(with: black), 21.0, accuracy: 0.1)
        
        // Black on white should have the same contrast ratio
        XCTAssertEqual(black.wcagContrastRatio(with: white), 21.0, accuracy: 0.1)
        
        // A color with itself should have minimum contrast ratio (1:1)
        XCTAssertEqual(blue.wcagContrastRatio(with: blue), 1.0, accuracy: 0.1)
        
        // 50% gray with white should have contrast ratio around 3.95:1
        XCTAssertEqual(gray50.wcagContrastRatio(with: white), 3.95, accuracy: 0.1)
    }
    
    func testWCAGCompliance() throws {
        // Test white on black (should pass all levels)
        let whiteOnBlack = white.wcagCompliance(with: black)
        XCTAssertTrue(whiteOnBlack.passesAA)
        XCTAssertTrue(whiteOnBlack.passesAAA)
        XCTAssertTrue(whiteOnBlack.passesAALarge)
        XCTAssertTrue(whiteOnBlack.passesAAALarge)
        XCTAssertEqual(whiteOnBlack.highestLevel, WCAGContrastLevel.AAA)
        
        // Test blue on blue (should fail all levels)
        let blueOnBlue = blue.wcagCompliance(with: blue)
        XCTAssertFalse(blueOnBlue.passesAA)
        XCTAssertFalse(blueOnBlue.passesAAA)
        XCTAssertFalse(blueOnBlue.passesAALarge)
        XCTAssertFalse(blueOnBlue.passesAAALarge)
        XCTAssertNil(blueOnBlue.highestLevel)
        
        // Test gray50 on white (should pass AA Large but fail AA)
        let grayOnWhite = gray50.wcagCompliance(with: white)
        XCTAssertTrue(grayOnWhite.passesAALarge)
        XCTAssertFalse(grayOnWhite.passesAA)
        XCTAssertFalse(grayOnWhite.passesAAA)
        XCTAssertFalse(grayOnWhite.passesAAALarge)
        XCTAssertEqual(grayOnWhite.highestLevel, WCAGContrastLevel.AALarge)
    }
    
    func testSuggestedColors() throws {
        // Dark colors should suggest white
        XCTAssertEqual(black.suggestedColor(for: WCAGContrastLevel.AA), white)
        XCTAssertEqual(blue.suggestedColor(for: WCAGContrastLevel.AA), white)
        
        // Light colors should suggest black
        XCTAssertEqual(white.suggestedColor(for: WCAGContrastLevel.AA), black)
        
        // Mid-gray should suggest based on luminance
        let suggestedColor = gray50.suggestedColor(for: WCAGContrastLevel.AA)
        let luminance = gray50.wcagRelativeLuminance()
        XCTAssertEqual(
            suggestedColor,
            luminance < 0.5 ? .white : .black
        )
    }
    
    func testWCAGContrastLevel() throws {
        // Test minimum ratios
        XCTAssertEqual(WCAGContrastLevel.AALarge.minimumRatio, 3.0)
        XCTAssertEqual(WCAGContrastLevel.AA.minimumRatio, 4.5)
        XCTAssertEqual(WCAGContrastLevel.AAALarge.minimumRatio, 4.5)
        XCTAssertEqual(WCAGContrastLevel.AAA.minimumRatio, 7.0)
        
        // Test descriptions
        XCTAssertEqual(WCAGContrastLevel.AALarge.description, "AA level for large text (18pt+)")
        XCTAssertEqual(WCAGContrastLevel.AA.description, "AA level for normal text")
        XCTAssertEqual(WCAGContrastLevel.AAALarge.description, "AAA level for large text (18pt+)")
        XCTAssertEqual(WCAGContrastLevel.AAA.description, "AAA level for normal text")
    }
    
    func testWCAGContrastRatio() {
        // White and black have the maximum contrast ratio
        let white = Color.white
        let black = Color.black
        
        // WCAG contrast ratio for white and black should be 21:1
        let ratio = white.wcagContrastRatio(with: black)
        XCTAssertEqual(ratio, 21.0, accuracy: 1.0)
        
        // Similar colors should have low contrast
        let lightGray = Color(white: 0.8)
        let slightlyLighterGray = Color(white: 0.9)
        
        let lowRatio = lightGray.wcagContrastRatio(with: slightlyLighterGray)
        XCTAssertLessThan(lowRatio, 2.0) // Should be less than AA requirement
    }
    
    func testWCAGComplianceLevels() {
        let white = Color.white
        let black = Color.black
        let compliance = white.wcagCompliance(with: black)
        
        // Should pass all levels
        XCTAssertTrue(compliance.passesAA)
        XCTAssertTrue(compliance.passesAAA)
        XCTAssertTrue(compliance.passesAALarge)
        XCTAssertTrue(compliance.passesAAALarge)
        
        // Poor contrast colors
        let lightGray = Color(white: 0.8)
        let slightlyLighterGray = Color(white: 0.9)
        let poorCompliance = lightGray.wcagCompliance(with: slightlyLighterGray)
        
        // Should fail all levels
        XCTAssertFalse(poorCompliance.passesAA)
        XCTAssertFalse(poorCompliance.passesAAA)
        XCTAssertFalse(poorCompliance.passesAALarge)
        XCTAssertFalse(poorCompliance.passesAAALarge)
    }
    
    func testWCAGColorSuggestions() {
        // Test with a background color (white) and a problematic foreground color (light yellow)
        let backgroundColor = Color.white
        let problematicColor = Color(red: 1.0, green: 1.0, blue: 0.8) // Light yellow
        
        // Get suggestions for AA level
        let suggestions = backgroundColor.suggestedAccessibleColors(for: problematicColor, level: .AA)
        
        // Should have at least one suggestion
        XCTAssertFalse(suggestions.isEmpty)
        
        // The suggestion should have better contrast
        if let suggestedColor = suggestions.first {
            let originalContrast = backgroundColor.wcagContrastRatio(with: problematicColor)
            let suggestedContrast = backgroundColor.wcagContrastRatio(with: suggestedColor)
            
            XCTAssertGreaterThan(suggestedContrast, originalContrast)
            
            // The suggested color should meet AA requirements
            let compliance = backgroundColor.wcagCompliance(with: suggestedColor)
            XCTAssertTrue(compliance.passesAA)
        }
    }
    
    func testWCAGColorSuggestionsPreserveHue() {
        // Test with a background color (black) and a problematic foreground color (dark blue)
        let backgroundColor = Color.black
        let problematicColor = Color(red: 0.0, green: 0.0, blue: 0.3) // Dark blue
        
        // Get suggestions with preserved hue
        let suggestions = backgroundColor.suggestedAccessibleColors(
            for: problematicColor, 
            level: .AA, 
            preserveHue: true
        )
        
        // Should have at least one suggestion
        XCTAssertFalse(suggestions.isEmpty)
        
        if let suggestedColor = suggestions.first {
            // Get the HSL components
            let originalHSL = problematicColor.hslComponents()
            let suggestedHSL = suggestedColor.hslComponents()
            
            // Hue should be similar if preserveHue is true
            XCTAssertNotNil(originalHSL)
            XCTAssertNotNil(suggestedHSL)
            
            if let originalHue = originalHSL?.hue, let suggestedHue = suggestedHSL?.hue {
                // Allowing some small difference due to HSL conversion precision
                // Calculate the smallest angle between hues (considering that hue is circular)
                let hueDiff = min(abs(originalHue - suggestedHue), 1 - abs(originalHue - suggestedHue))
                XCTAssertLessThan(hueDiff, 0.1) // Less than 10% of the hue wheel
            }
            
            // Contrast should meet AA requirements
            let compliance = backgroundColor.wcagCompliance(with: suggestedColor)
            XCTAssertTrue(compliance.passesAA)
        }
    }
    
    func testWCAGColorSuggestionsForDifferentLevels() {
        let backgroundColor = Color.white
        let problematicColor = Color(red: 0.5, green: 0.5, blue: 0.5) // Gray
        
        // Test for different compliance levels
        let aaSuggestions = backgroundColor.suggestedAccessibleColors(for: problematicColor, level: .AA)
        let aaaSuggestions = backgroundColor.suggestedAccessibleColors(for: problematicColor, level: .AAA)
        
        // Should have suggestions for both levels
        XCTAssertFalse(aaSuggestions.isEmpty)
        XCTAssertFalse(aaaSuggestions.isEmpty)
        
        if let aaSuggestion = aaSuggestions.first, let aaaSuggestion = aaaSuggestions.first {
            // AAA suggestion should have higher contrast
            let aaContrast = backgroundColor.wcagContrastRatio(with: aaSuggestion)
            let aaaContrast = backgroundColor.wcagContrastRatio(with: aaaSuggestion)
            
            // The AAA contrast should be higher (or equal if both reached maximum contrast)
            XCTAssertGreaterThanOrEqual(aaaContrast, aaContrast)
            
            // Check actual compliance
            let aaCompliance = backgroundColor.wcagCompliance(with: aaSuggestion)
            let aaaCompliance = backgroundColor.wcagCompliance(with: aaaSuggestion)
            
            XCTAssertTrue(aaCompliance.passesAA)
            XCTAssertTrue(aaaCompliance.passesAAA)
        }
    }
} 