//
//  PaletteExportView.swift
//  ColorKit
//
//  Created by Agisilaos Tsaraboulidis on 13.03.25.
//
//  Description:
//  Provides a UI for exporting and sharing color palettes.
//
//  Features:
//  - UI for selecting export format
//  - Export to file functionality
//  - Share via system share sheet
//  - Copy to clipboard functionality
//
//  License:
//  MIT License. See LICENSE file for details.
//

import SwiftUI
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
import UniformTypeIdentifiers
#endif

/// A view for exporting and sharing color palettes
@available(iOS 14.0, macOS 11.0, *)
public struct PaletteExportView: View {
    /// The palette to export
    private let palette: [PaletteExporter.PaletteEntry]

    /// The name of the palette
    private let paletteName: String

    /// The selected export format
    @State private var selectedFormat: PaletteExportFormat = .json

    /// Whether the export sheet is presented
    @State private var isExportSheetPresented = false

    /// Whether the share sheet is presented
    @State private var isShareSheetPresented = false

    /// The exported data
    @State private var exportedData: Data?

    /// The export action result message
    @State private var resultMessage: String?

    /// Whether to show the result message
    @State private var showResultMessage = false

    /// Creates a new palette export view
    /// - Parameters:
    ///   - palette: The palette to export
    ///   - paletteName: The name of the palette
    public init(palette: [PaletteExporter.PaletteEntry], paletteName: String) {
        self.palette = palette
        self.paletteName = paletteName
    }

    public var body: some View {
        VStack(spacing: 20) {
            // Preview of the palette
            palettePreview

            // Format selection
            formatSelector

            // Action buttons
            actionButtons
        }
        .padding()
        .frame(minWidth: 300, maxWidth: 600)
        #if os(iOS)
        .sheet(isPresented: $isShareSheetPresented) {
            if let data = exportedData {
                ShareSheet(items: [data])
            }
        }
        #endif
        .alert(isPresented: $showResultMessage) {
            Alert(
                title: Text("Export Result"),
                message: Text(resultMessage ?? ""),
                dismissButton: .default(Text("OK"))
            )
        }
    }

    /// Preview of the palette
    private var palettePreview: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 4) {
                ForEach(palette) { entry in
                    VStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(entry.color)
                            .frame(width: 60, height: 60)

                        Text(entry.name)
                            .font(.caption)
                            .lineLimit(1)
                    }
                    .frame(width: 70)
                }
            }
            .padding(.horizontal, 4)
        }
        .frame(height: 100)
    }

    /// Format selector
    private var formatSelector: some View {
        VStack(alignment: .leading) {
            Text("Export Format")
                .font(.headline)

            Picker("Format", selection: $selectedFormat) {
                ForEach(PaletteExportFormat.allCases) { format in
                    Text(format.rawValue).tag(format)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
        }
    }

    /// Action buttons
    private var actionButtons: some View {
        HStack {
            Button(action: copyToClipboard) {
                Label("Copy", systemImage: "doc.on.clipboard")
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.accentColor.opacity(0.1))
                    .cornerRadius(8)
            }

            Spacer()

            Button(action: exportToFile) {
                Label("Export", systemImage: "square.and.arrow.down")
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.accentColor.opacity(0.1))
                    .cornerRadius(8)
            }

            Spacer()

            Button(action: share) {
                Label("Share", systemImage: "square.and.arrow.up")
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.accentColor.opacity(0.1))
                    .cornerRadius(8)
            }
        }
    }

    /// Copy the palette to the clipboard
    private func copyToClipboard() {
        let success = PaletteExporter.copyToClipboard(
            palette: palette,
            format: selectedFormat,
            paletteName: paletteName
        )

        resultMessage = success ? "Copied to clipboard" : "Failed to copy to clipboard"
        showResultMessage = true
    }

    /// Export the palette to a file
    private func exportToFile() {
        guard let data = PaletteExporter.export(
            palette: palette,
            to: selectedFormat,
            paletteName: paletteName
        ) else {
            resultMessage = "Failed to export palette"
            showResultMessage = true
            return
        }

        exportedData = data
        isExportSheetPresented = true

        #if os(macOS)
        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [UTType(filenameExtension: selectedFormat.fileExtension) ?? .data]
        savePanel.nameFieldStringValue = "\(paletteName).\(selectedFormat.fileExtension)"

        savePanel.begin { response in
            if response == .OK, let url = savePanel.url {
                do {
                    try data.write(to: url)
                    resultMessage = "Palette exported successfully"
                } catch {
                    resultMessage = "Failed to save file: \(error.localizedDescription)"
                }
                showResultMessage = true
            }
        }
        #endif
    }

    /// Share the palette
    private func share() {
        guard let data = PaletteExporter.export(
            palette: palette,
            to: selectedFormat,
            paletteName: paletteName
        ) else {
            resultMessage = "Failed to export palette"
            showResultMessage = true
            return
        }

        exportedData = data
        isShareSheetPresented = true
    }
}

#if os(iOS)
/// A view that presents the system share sheet
@available(iOS 14.0, *)
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: items,
            applicationActivities: nil
        )
        return controller
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {
        // Nothing to update
    }
}
#endif

/// A preview provider for the palette export view
@available(iOS 14.0, macOS 11.0, *)
struct PaletteExportView_Previews: PreviewProvider {
    static var previews: some View {
        let palette = [
            PaletteExporter.PaletteEntry(name: "Red", color: .red),
            PaletteExporter.PaletteEntry(name: "Green", color: .green),
            PaletteExporter.PaletteEntry(name: "Blue", color: .blue),
            PaletteExporter.PaletteEntry(name: "Yellow", color: .yellow),
            PaletteExporter.PaletteEntry(name: "Purple", color: .purple)
        ]

        PaletteExportView(palette: palette, paletteName: "Sample Palette")
    }
}
