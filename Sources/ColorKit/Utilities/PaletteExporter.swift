//
//  PaletteExporter.swift
//  ColorKit
//
//  Created by Agisilaos Tsaraboulidis on 13.03.25.
//
//  Description:
//  Provides functionality to export color palettes in various formats.
//
//  Features:
//  - Export palettes to JSON, CSS, SVG, and Adobe ASE formats
//  - Copy palette data to clipboard in different formats
//  - Generate shareable images of palettes
//
//  License:
//  MIT License. See LICENSE file for details.
//

import SwiftUI
import Foundation
import UniformTypeIdentifiers
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

/// Supported formats for exporting color palettes
@available(iOS 14.0, macOS 11.0, *)
public enum PaletteExportFormat: String, CaseIterable, Identifiable {
    case json = "JSON"
    case css = "CSS"
    case svg = "SVG"
    case ase = "Adobe ASE"
    case png = "PNG Image"
    
    public var id: String { rawValue }
    
    /// File extension for the export format
    public var fileExtension: String {
        switch self {
        case .json: return "json"
        case .css: return "css"
        case .svg: return "svg"
        case .ase: return "ase"
        case .png: return "png"
        }
    }
    
    /// MIME type for the export format
    public var mimeType: String {
        switch self {
        case .json: return "application/json"
        case .css: return "text/css"
        case .svg: return "image/svg+xml"
        case .ase: return "application/octet-stream"
        case .png: return "image/png"
        }
    }
}

/// A utility for exporting color palettes in various formats
@available(iOS 14.0, macOS 11.0, *)
public struct PaletteExporter {
    
    /// A color palette entry with name and color
    public struct PaletteEntry: Identifiable, Equatable, Hashable {
        public let id = UUID()
        public let name: String
        public let color: Color
        
        public init(name: String, color: Color) {
            self.name = name
            self.color = color
        }
    }
    
    /// Export a color palette to a specific format
    /// - Parameters:
    ///   - palette: The array of colors to export
    ///   - format: The format to export to
    ///   - paletteName: The name of the palette
    /// - Returns: Data representing the exported palette
    public static func export(
        palette: [PaletteEntry],
        to format: PaletteExportFormat,
        paletteName: String
    ) -> Data? {
        switch format {
        case .json:
            return exportToJSON(palette: palette, paletteName: paletteName)
        case .css:
            return exportToCSS(palette: palette, paletteName: paletteName)
        case .svg:
            return exportToSVG(palette: palette, paletteName: paletteName)
        case .ase:
            return exportToASE(palette: palette, paletteName: paletteName)
        case .png:
            return exportToPNG(palette: palette, paletteName: paletteName)
        }
    }
    
    /// Export a color palette to JSON format
    /// - Parameters:
    ///   - palette: The array of colors to export
    ///   - paletteName: The name of the palette
    /// - Returns: JSON data representing the palette
    private static func exportToJSON(palette: [PaletteEntry], paletteName: String) -> Data? {
        var jsonObject: [String: Any] = [
            "name": paletteName,
            "colors": []
        ]
        
        var colorsArray: [[String: Any]] = []
        
        for entry in palette {
            let rgba = entry.color.rgbaComponents()
            
            let colorDict: [String: Any] = [
                "name": entry.name,
                "hex": entry.color.hexString() ?? "#000000",
                "rgb": [
                    "r": Int(rgba.red * 255),
                    "g": Int(rgba.green * 255),
                    "b": Int(rgba.blue * 255)
                ],
                "alpha": rgba.alpha
            ]
            
            colorsArray.append(colorDict)
        }
        
        jsonObject["colors"] = colorsArray
        
        return try? JSONSerialization.data(withJSONObject: jsonObject, options: .prettyPrinted)
    }
    
    /// Export a color palette to CSS format
    /// - Parameters:
    ///   - palette: The array of colors to export
    ///   - paletteName: The name of the palette
    /// - Returns: CSS data representing the palette
    private static func exportToCSS(palette: [PaletteEntry], paletteName: String) -> Data? {
        var css = "/* \(paletteName) Color Palette */\n"
        css += ":root {\n"
        
        for entry in palette {
            let hexString = entry.color.hexString() ?? "#000000"
            let cssVarName = entry.name.lowercased().replacingOccurrences(of: " ", with: "-")
            css += "  --\(cssVarName): \(hexString);\n"
        }
        
        css += "}\n"
        
        return css.data(using: .utf8)
    }
    
    /// Export a color palette to SVG format
    /// - Parameters:
    ///   - palette: The array of colors to export
    ///   - paletteName: The name of the palette
    /// - Returns: SVG data representing the palette
    private static func exportToSVG(palette: [PaletteEntry], paletteName: String) -> Data? {
        let width = 800
        let height = 400
        let swatchWidth = width / max(palette.count, 1)
        let swatchHeight = height
        
        var svg = """
        <svg width="\(width)" height="\(height)" viewBox="0 0 \(width) \(height)" xmlns="http://www.w3.org/2000/svg">
          <title>\(paletteName)</title>
        
        """
        
        for (index, entry) in palette.enumerated() {
            let x = index * swatchWidth
            let hexString = entry.color.hexString() ?? "#000000"
            
            svg += """
              <rect x="\(x)" y="0" width="\(swatchWidth)" height="\(swatchHeight)" fill="\(hexString)" />
              <text x="\(x + swatchWidth/2)" y="\(swatchHeight - 20)" font-family="Arial" font-size="14" fill="white" text-anchor="middle" stroke="black" stroke-width="0.5">\(entry.name)</text>
              <text x="\(x + swatchWidth/2)" y="\(swatchHeight - 40)" font-family="Arial" font-size="12" fill="white" text-anchor="middle" stroke="black" stroke-width="0.5">\(hexString)</text>
            
            """
        }
        
        svg += "</svg>"
        
        return svg.data(using: .utf8)
    }
    
    /// Export a color palette to Adobe ASE format
    /// - Parameters:
    ///   - palette: The array of colors to export
    ///   - paletteName: The name of the palette
    /// - Returns: ASE data representing the palette
    private static func exportToASE(palette: [PaletteEntry], paletteName: String) -> Data? {
        // ASE format is binary, this is a simplified implementation
        var data = Data()
        
        // ASE file signature "ASEF"
        data.append(contentsOf: [0x41, 0x53, 0x45, 0x46])
        
        // Version (1.0)
        data.append(contentsOf: [0x00, 0x01, 0x00, 0x00])
        
        // Number of blocks (1 block per color)
        let blockCount = UInt32(palette.count).bigEndian
        withUnsafeBytes(of: blockCount) { data.append(contentsOf: $0) }
        
        // Add each color as a block
        for entry in palette {
            let rgba = entry.color.rgbaComponents()
            
            // Block type (0x0001 for color)
            data.append(contentsOf: [0x00, 0x01])
            
            // Block length placeholder (will calculate later)
            let blockLengthPos = data.count
            data.append(contentsOf: [0x00, 0x00, 0x00, 0x00])
            
            // Color name length (including null terminator)
            let nameData = entry.name.data(using: .utf16BigEndian) ?? Data()
            let nameLength = UInt16(nameData.count / 2 + 1).bigEndian
            withUnsafeBytes(of: nameLength) { data.append(contentsOf: $0) }
            
            // Color name as UTF-16BE with null terminator
            data.append(nameData)
            data.append(contentsOf: [0x00, 0x00])
            
            // Color model ("RGB ")
            data.append(contentsOf: [0x52, 0x47, 0x42, 0x20])
            
            // RGB values as 32-bit floats
            let r = Float(rgba.red).bitPattern.bigEndian
            let g = Float(rgba.green).bitPattern.bigEndian
            let b = Float(rgba.blue).bitPattern.bigEndian
            withUnsafeBytes(of: r) { data.append(contentsOf: $0) }
            withUnsafeBytes(of: g) { data.append(contentsOf: $0) }
            withUnsafeBytes(of: b) { data.append(contentsOf: $0) }
            
            // Color type (0 = global)
            data.append(contentsOf: [0x00, 0x00])
            
            // Update block length
            let blockLength = UInt32(data.count - blockLengthPos - 4).bigEndian
            withUnsafeBytes(of: blockLength) { bytes in
                for i in 0..<4 {
                    data[blockLengthPos + i] = bytes[i]
                }
            }
        }
        
        return data
    }
    
    /// Export a color palette to PNG image
    /// - Parameters:
    ///   - palette: The array of colors to export
    ///   - paletteName: The name of the palette
    /// - Returns: PNG data representing the palette
    private static func exportToPNG(palette: [PaletteEntry], paletteName: String) -> Data? {
        #if canImport(UIKit)
        let width = 800
        let height = 400
        let swatchWidth = width / max(palette.count, 1)
        
        UIGraphicsBeginImageContextWithOptions(CGSize(width: width, height: height), true, 2.0)
        guard let context = UIGraphicsGetCurrentContext() else { return nil }
        
        // Draw each color swatch
        for (index, entry) in palette.enumerated() {
            let rect = CGRect(x: index * swatchWidth, y: 0, width: swatchWidth, height: height)
            
            let rgba = entry.color.rgbaComponents()
            context.setFillColor(red: CGFloat(rgba.red), green: CGFloat(rgba.green), blue: CGFloat(rgba.blue), alpha: CGFloat(rgba.alpha))
            context.fill(rect)
            
            // Draw color name and hex value
            let hexString = entry.color.hexString() ?? "#000000"
            let nameAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 14, weight: .bold),
                .foregroundColor: UIColor.white,
                .strokeColor: UIColor.black,
                .strokeWidth: -1.0
            ]
            
            let hexAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 12),
                .foregroundColor: UIColor.white,
                .strokeColor: UIColor.black,
                .strokeWidth: -1.0
            ]
            
            let nameSize = (entry.name as NSString).size(withAttributes: nameAttributes)
            let hexSize = (hexString as NSString).size(withAttributes: hexAttributes)
            
            let nameX = CGFloat(index * swatchWidth) + CGFloat(swatchWidth - Int(nameSize.width)) / 2
            let hexX = CGFloat(index * swatchWidth) + CGFloat(swatchWidth - Int(hexSize.width)) / 2
            
            (entry.name as NSString).draw(at: CGPoint(x: nameX, y: CGFloat(height - 40)), withAttributes: nameAttributes)
            (hexString as NSString).draw(at: CGPoint(x: hexX, y: CGFloat(height - 20)), withAttributes: hexAttributes)
        }
        
        // Add title
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 18, weight: .bold),
            .foregroundColor: UIColor.white,
            .strokeColor: UIColor.black,
            .strokeWidth: -2.0
        ]
        
        let titleSize = (paletteName as NSString).size(withAttributes: titleAttributes)
        let titleX = (CGFloat(width) - titleSize.width) / 2
        (paletteName as NSString).draw(at: CGPoint(x: titleX, y: 20), withAttributes: titleAttributes)
        
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return image?.pngData()
        #elseif canImport(AppKit)
        let width = 800
        let height = 400
        let swatchWidth = width / max(palette.count, 1)
        
        let image = NSImage(size: NSSize(width: width, height: height))
        image.lockFocus()
        
        // Draw each color swatch
        for (index, entry) in palette.enumerated() {
            let rect = NSRect(x: index * swatchWidth, y: 0, width: swatchWidth, height: height)
            
            let rgba = entry.color.rgbaComponents()
            NSColor(red: CGFloat(rgba.red), green: CGFloat(rgba.green), blue: CGFloat(rgba.blue), alpha: CGFloat(rgba.alpha)).setFill()
            rect.fill()
            
            // Draw color name and hex value
            let hexString = entry.color.hexString() ?? "#000000"
            let nameAttributes: [NSAttributedString.Key: Any] = [
                .font: NSFont.systemFont(ofSize: 14, weight: .bold),
                .foregroundColor: NSColor.white,
                .strokeColor: NSColor.black,
                .strokeWidth: -1.0
            ]
            
            let hexAttributes: [NSAttributedString.Key: Any] = [
                .font: NSFont.systemFont(ofSize: 12),
                .foregroundColor: NSColor.white,
                .strokeColor: NSColor.black,
                .strokeWidth: -1.0
            ]
            
            let nameSize = (entry.name as NSString).size(withAttributes: nameAttributes)
            let hexSize = (hexString as NSString).size(withAttributes: hexAttributes)
            
            let nameX = CGFloat(index * swatchWidth) + CGFloat(swatchWidth - Int(nameSize.width)) / 2
            let hexX = CGFloat(index * swatchWidth) + CGFloat(swatchWidth - Int(hexSize.width)) / 2
            
            (entry.name as NSString).draw(at: NSPoint(x: nameX, y: CGFloat(height - 40)), withAttributes: nameAttributes)
            (hexString as NSString).draw(at: NSPoint(x: hexX, y: CGFloat(height - 20)), withAttributes: hexAttributes)
        }
        
        // Add title
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 18, weight: .bold),
            .foregroundColor: NSColor.white,
            .strokeColor: NSColor.black,
            .strokeWidth: -2.0
        ]
        
        let titleSize = (paletteName as NSString).size(withAttributes: titleAttributes)
        let titleX = (CGFloat(width) - titleSize.width) / 2
        (paletteName as NSString).draw(at: NSPoint(x: titleX, y: 20), withAttributes: titleAttributes)
        
        image.unlockFocus()
        
        guard let tiffData = image.tiffRepresentation,
              let bitmapImage = NSBitmapImageRep(data: tiffData),
              let pngData = bitmapImage.representation(using: .png, properties: [:]) else {
            return nil
        }
        
        return pngData
        #else
        return nil
        #endif
    }
    
    /// Copy palette data to clipboard in a specific format
    /// - Parameters:
    ///   - palette: The array of colors to export
    ///   - format: The format to export to
    ///   - paletteName: The name of the palette
    /// - Returns: Whether the copy operation was successful
    @MainActor
    public static func copyToClipboard(
        palette: [PaletteEntry],
        format: PaletteExportFormat,
        paletteName: String
    ) -> Bool {
        guard let data = export(palette: palette, to: format, paletteName: paletteName) else {
            return false
        }
        
        #if canImport(UIKit)
        switch format {
        case .json, .css, .svg:
            guard let string = String(data: data, encoding: .utf8) else { return false }
            UIPasteboard.general.string = string
            return true
        case .png:
            guard let image = UIImage(data: data) else { return false }
            UIPasteboard.general.image = image
            return true
        case .ase:
            // ASE is binary, so we'll convert to base64 for clipboard
            let base64String = data.base64EncodedString()
            UIPasteboard.general.string = base64String
            return true
        }
        #elseif canImport(AppKit)
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        
        switch format {
        case .json, .css, .svg:
            guard let string = String(data: data, encoding: .utf8) else { return false }
            return pasteboard.setString(string, forType: .string)
        case .png:
            guard let image = NSImage(data: data) else { return false }
            return pasteboard.writeObjects([image])
        case .ase:
            // ASE is binary, so we'll convert to base64 for clipboard
            let base64String = data.base64EncodedString()
            return pasteboard.setString(base64String, forType: .string)
        }
        #else
        return false
        #endif
    }
    
    /// Create a palette from an array of colors
    /// - Parameters:
    ///   - colors: The array of colors
    ///   - namePrefix: Optional prefix for color names
    /// - Returns: An array of palette entries
    public static func createPalette(from colors: [Color], namePrefix: String = "Color") -> [PaletteEntry] {
        return colors.enumerated().map { index, color in
            PaletteEntry(name: "\(namePrefix) \(index + 1)", color: color)
        }
    }
    
    /// Create a palette from a theme
    /// - Parameter theme: The color theme
    /// - Returns: An array of palette entries
    public static func createPalette(from theme: ColorTheme) -> [PaletteEntry] {
        var palette: [PaletteEntry] = []
        
        // Add primary colors
        palette.append(PaletteEntry(name: "Primary", color: theme.primary.base))
        palette.append(PaletteEntry(name: "Primary Light", color: theme.primary.light))
        palette.append(PaletteEntry(name: "Primary Dark", color: theme.primary.dark))
        
        // Add secondary colors
        palette.append(PaletteEntry(name: "Secondary", color: theme.secondary.base))
        palette.append(PaletteEntry(name: "Secondary Light", color: theme.secondary.light))
        palette.append(PaletteEntry(name: "Secondary Dark", color: theme.secondary.dark))
        
        // Add accent colors
        palette.append(PaletteEntry(name: "Accent", color: theme.accent.base))
        palette.append(PaletteEntry(name: "Accent Light", color: theme.accent.light))
        palette.append(PaletteEntry(name: "Accent Dark", color: theme.accent.dark))
        
        // Add background colors
        palette.append(PaletteEntry(name: "Background", color: theme.background.base))
        palette.append(PaletteEntry(name: "Background Light", color: theme.background.light))
        palette.append(PaletteEntry(name: "Background Dark", color: theme.background.dark))
        
        // Add text colors
        palette.append(PaletteEntry(name: "Text", color: theme.text.base))
        palette.append(PaletteEntry(name: "Text Light", color: theme.text.light))
        palette.append(PaletteEntry(name: "Text Dark", color: theme.text.dark))
        
        // Add status colors
        palette.append(PaletteEntry(name: "Success", color: theme.status.success))
        palette.append(PaletteEntry(name: "Warning", color: theme.status.warning))
        palette.append(PaletteEntry(name: "Error", color: theme.status.error))
        
        return palette
    }
} 
