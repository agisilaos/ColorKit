//
//  AccessiblePaletteGenerator+Export.swift
//  ColorKit
//
//  Created by Agisilaos Tsaraboulidis on 13.03.25.
//
//  Description:
//  Extends the AccessiblePaletteGenerator with export functionality.
//
//  Features:
//  - Convert accessible palettes to exportable format
//  - Export accessible palettes to various formats
//
//  License:
//  MIT License. See LICENSE file for details.
//

import SwiftUI

@available(iOS 14.0, macOS 11.0, *)
public extension AccessiblePaletteGenerator {
    /// Export a palette to a specific format
    /// - Parameters:
    ///   - palette: The array of colors to export
    ///   - format: The format to export to
    ///   - paletteName: The name of the palette
    /// - Returns: Data representing the exported palette
    func exportPalette(
        _ palette: [Color],
        to format: PaletteExportFormat,
        paletteName: String
    ) -> Data? {
        let entries = palette.enumerated().map { index, color in
            PaletteExporter.PaletteEntry(name: "Color \(index + 1)", color: color)
        }

        return PaletteExporter.export(
            palette: entries,
            to: format,
            paletteName: paletteName
        )
    }

    /// Export a theme to a specific format
    /// - Parameters:
    ///   - theme: The theme to export
    ///   - format: The format to export to
    /// - Returns: Data representing the exported theme
    func exportTheme(
        _ theme: ColorTheme,
        to format: PaletteExportFormat
    ) -> Data? {
        let entries = PaletteExporter.createPalette(from: theme)

        return PaletteExporter.export(
            palette: entries,
            to: format,
            paletteName: theme.name
        )
    }
}

@available(iOS 14.0, macOS 11.0, *)
public extension Color {
    /// Export a palette generated from this color
    /// - Parameters:
    ///   - targetLevel: The WCAG level to target
    ///   - paletteSize: The number of colors to generate
    ///   - includeBlackAndWhite: Whether to include black and white
    ///   - format: The format to export to
    ///   - paletteName: The name of the palette
    /// - Returns: Data representing the exported palette
    func exportAccessiblePalette(
        targetLevel: WCAGContrastLevel = .AA,
        paletteSize: Int = 5,
        includeBlackAndWhite: Bool = true,
        to format: PaletteExportFormat,
        paletteName: String
    ) -> Data? {
        let configuration = AccessiblePaletteGenerator.Configuration(
            targetLevel: targetLevel,
            paletteSize: paletteSize,
            includeBlackAndWhite: includeBlackAndWhite
        )

        let generator = AccessiblePaletteGenerator(configuration: configuration)
        let palette = generator.generatePalette(from: self)

        return generator.exportPalette(palette, to: format, paletteName: paletteName)
    }
}
