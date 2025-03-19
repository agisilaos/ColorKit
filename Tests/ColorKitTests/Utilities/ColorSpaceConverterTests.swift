import XCTest
import SwiftUI
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
    
    func testXYZConversion() {
        let white = Color(red: 1.0, green: 1.0, blue: 1.0, opacity: 1.0) // White with known RGB values
        let components = white.colorSpaceComponents()
        
        // White in XYZ should have Y close to 100
        XCTAssertEqual(components.xyz.y, 100.0, accuracy: 5.0)
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
} 