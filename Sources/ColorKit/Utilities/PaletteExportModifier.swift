//
//  PaletteExportModifier.swift
//  ColorKit
//
//  Created by Agisilaos Tsaraboulidis on 13.03.25.
//
//  Description:
//  Provides a view modifier to add export functionality to any view displaying a palette.
//
//  Features:
//  - Adds export button to any view
//  - Presents export options sheet
//  - Handles export and sharing
//
//  License:
//  MIT License. See LICENSE file for details.
//

import SwiftUI

/// A view modifier that adds export functionality to a view
public struct PaletteExportModifier: ViewModifier {
    /// The palette to export
    private let palette: [PaletteExporter.PaletteEntry]

    /// The name of the palette
    private let paletteName: String

    /// Whether the export sheet is presented
    @State private var isExportSheetPresented = false

    /// Creates a new palette export modifier
    /// - Parameters:
    ///   - palette: The palette to export
    ///   - paletteName: The name of the palette
    public init(palette: [PaletteExporter.PaletteEntry], paletteName: String) {
        self.palette = palette
        self.paletteName = paletteName
    }

    public func body(content: Content) -> some View {
        content
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(
                        action: { isExportSheetPresented = true },
                        label: {
                            Label("Export", systemImage: "square.and.arrow.up")
                        }
                    )
                }
            }
            .sheet(
                isPresented: $isExportSheetPresented,
                content: {
                    PaletteExportView(palette: palette, paletteName: paletteName)
                        .frame(minWidth: 400, minHeight: 300)
                        #if os(macOS)
                        .padding()
                        #endif
                }
            )
    }
}

public extension View {
    /// Adds export functionality to a view
    /// - Parameters:
    ///   - palette: The palette to export
    ///   - paletteName: The name of the palette
    /// - Returns: A view with export functionality
    func paletteExport(palette: [PaletteExporter.PaletteEntry], paletteName: String) -> some View {
        modifier(PaletteExportModifier(palette: palette, paletteName: paletteName))
    }

    /// Adds export functionality to a view
    /// - Parameters:
    ///   - colors: The colors to export
    ///   - paletteName: The name of the palette
    /// - Returns: A view with export functionality
    func paletteExport(colors: [Color], paletteName: String) -> some View {
        let palette = PaletteExporter.createPalette(from: colors)
        return modifier(PaletteExportModifier(palette: palette, paletteName: paletteName))
    }

    /// Adds export functionality to a view
    /// - Parameter theme: The theme to export
    /// - Returns: A view with export functionality
    func paletteExport(theme: ColorTheme) -> some View {
        let palette = PaletteExporter.createPalette(from: theme)
        return modifier(PaletteExportModifier(palette: palette, paletteName: theme.name))
    }
}
