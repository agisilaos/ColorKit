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
} 