//
//  PaletteExporterTests.swift
//  ColorKitTests
//
//  Created by Agisilaos Tsaraboulidis on 13.03.25.
//
//  Description:
//  Tests for the palette export functionality.
//
//  Features:
//  - Tests for exporting palettes in various formats
//  - Tests for creating palettes from colors and themes
//
//  License:
//  MIT License. See LICENSE file for details.
//

import XCTest
import SwiftUI
@testable import ColorKit

#if canImport(SwiftUI) && (os(iOS) && !(targetEnvironment(macCatalyst)) && swift(>=5.5))
@available(iOS 14.0, macOS 11.0, *)
final class PaletteExporterTests: XCTestCase {
    
    // Test palette
    private let testPalette: [PaletteExporter.PaletteEntry] = [
        PaletteExporter.PaletteEntry(name: "Red", color: .red),
        PaletteExporter.PaletteEntry(name: "Green", color: .green),
        PaletteExporter.PaletteEntry(name: "Blue", color: .blue)
    ]
    
    // Test palette name
    private let testPaletteName = "Test Palette"
    
    func testExportToJSON() {
        // Export to JSON
        guard let jsonData = PaletteExporter.export(
            palette: testPalette,
            to: .json,
            paletteName: testPaletteName
        ) else {
            XCTFail("Failed to export palette to JSON")
            return
        }
        
        // Verify the JSON data
        do {
            guard let jsonObject = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any] else {
                XCTFail("Failed to parse JSON data")
                return
            }
            
            // Check palette name
            XCTAssertEqual(jsonObject["name"] as? String, testPaletteName)
            
            // Check colors array
            guard let colors = jsonObject["colors"] as? [[String: Any]] else {
                XCTFail("Colors array not found in JSON")
                return
            }
            
            // Check number of colors
            XCTAssertEqual(colors.count, testPalette.count)
            
            // Check first color
            if let firstColor = colors.first {
                XCTAssertEqual(firstColor["name"] as? String, "Red")
                XCTAssertNotNil(firstColor["hex"])
                XCTAssertNotNil(firstColor["rgb"])
            } else {
                XCTFail("First color not found in JSON")
            }
        } catch {
            XCTFail("Failed to parse JSON: \(error)")
        }
    }
    
    func testExportToCSS() {
        // Export to CSS
        guard let cssData = PaletteExporter.export(
            palette: testPalette,
            to: .css,
            paletteName: testPaletteName
        ) else {
            XCTFail("Failed to export palette to CSS")
            return
        }
        
        // Convert data to string
        guard let cssString = String(data: cssData, encoding: .utf8) else {
            XCTFail("Failed to convert CSS data to string")
            return
        }
        
        // Verify the CSS string
        XCTAssertTrue(cssString.contains("/* Test Palette Color Palette */"))
        XCTAssertTrue(cssString.contains(":root {"))
        XCTAssertTrue(cssString.contains("--red:"))
        XCTAssertTrue(cssString.contains("--green:"))
        XCTAssertTrue(cssString.contains("--blue:"))
    }
    
    func testExportToSVG() {
        // Export to SVG
        guard let svgData = PaletteExporter.export(
            palette: testPalette,
            to: .svg,
            paletteName: testPaletteName
        ) else {
            XCTFail("Failed to export palette to SVG")
            return
        }
        
        // Convert data to string
        guard let svgString = String(data: svgData, encoding: .utf8) else {
            XCTFail("Failed to convert SVG data to string")
            return
        }
        
        // Verify the SVG string
        XCTAssertTrue(svgString.contains("<svg"))
        XCTAssertTrue(svgString.contains("<title>Test Palette</title>"))
        XCTAssertTrue(svgString.contains("<rect"))
        XCTAssertTrue(svgString.contains("Red"))
        XCTAssertTrue(svgString.contains("Green"))
        XCTAssertTrue(svgString.contains("Blue"))
    }
    
    func testExportToASE() {
        // Export to ASE
        guard let aseData = PaletteExporter.export(
            palette: testPalette,
            to: .ase,
            paletteName: testPaletteName
        ) else {
            XCTFail("Failed to export palette to ASE")
            return
        }
        
        // Verify the ASE data
        XCTAssertGreaterThan(aseData.count, 0)
        
        // Check ASE signature
        let signature = aseData.prefix(4)
        XCTAssertEqual(signature, Data([0x41, 0x53, 0x45, 0x46])) // "ASEF"
    }
    
    func testCreatePaletteFromColors() {
        // Create a palette from colors
        let colors: [Color] = [.red, .green, .blue]
        let palette = PaletteExporter.createPalette(from: colors)
        
        // Verify the palette
        XCTAssertEqual(palette.count, colors.count)
        XCTAssertEqual(palette[0].name, "Color 1")
        XCTAssertEqual(palette[1].name, "Color 2")
        XCTAssertEqual(palette[2].name, "Color 3")
    }
    
    @MainActor
    func testCreatePaletteFromTheme() {
        // Create a theme
        let theme = ColorTheme(
            name: "Test Theme",
            primary: .red,
            secondary: .green,
            accent: .blue,
            background: .white,
            text: .black
        )
        
        // Create a palette from the theme
        let palette = PaletteExporter.createPalette(from: theme)
        
        // Verify the palette
        XCTAssertGreaterThan(palette.count, 0)
        XCTAssertTrue(palette.contains { $0.name == "Primary" })
        XCTAssertTrue(palette.contains { $0.name == "Secondary" })
        XCTAssertTrue(palette.contains { $0.name == "Accent" })
        XCTAssertTrue(palette.contains { $0.name == "Background" })
        XCTAssertTrue(palette.contains { $0.name == "Text" })
    }
}
#endif 