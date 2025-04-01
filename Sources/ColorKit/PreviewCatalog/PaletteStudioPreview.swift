//
//  PaletteStudioPreview.swift
//  ColorKit
//
//  Created by Agisilaos Tsaraboulidis on 20.03.2025.
//
//  Description:
//  A preview component for generating and exporting color palettes.
//
//  Features:
//  - Interactive palette generation from seed colors
//  - WCAG compliance options (AA/AAA)
//  - Customizable palette size and options
//  - Export to multiple formats (JSON, CSS, SVG, ASE, PNG)
//  - One-click copying and sharing functionality
//
//  License:
//  MIT License. See LICENSE file for details.
//

import SwiftUI

/// A preview component for generating, customizing, and exporting color palettes
/// - Note: This preview doesn't export and share actions because interactive elements such as sheets or save panels are not supported in SwiftUI previews.
public struct PaletteStudioPreview: View {
    // MARK: - State Properties

    @State private var seedColor: Color = .blue
    @State private var targetLevel: WCAGContrastLevel = .AA
    @State private var paletteSize: Int = 5
    @State private var includeBlackAndWhite: Bool = true
    @State private var selectedExportFormat: PaletteExportFormat = .json
    @State private var generatedPalette: [Color] = []
    @State private var paletteName: String = "My Palette"

    // MARK: - Body

    public var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header
                Text("Palette Studio")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                // Color Picker Section
                seedColorSection

                // Generation Options Section
                optionsSection

                // Generated Palette Preview
                palettePreviewSection

                // Export Options Section
                exportSection
            }
            .padding()
        }
    }

    // MARK: - Sections

    private var seedColorSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Seed Color")
                .font(.headline)

            HStack {
                Button(action: randomizeColor) {
                    Circle()
                        .fill(seedColor)
                        .frame(width: 44, height: 44)
                        .overlay(Circle().stroke(Color.secondary, lineWidth: 1))
                }
                .buttonStyle(.plain)
                .help("Tap to randomize color")
            }

            Button(action: generatePalette) {
                Label("Generate Palette", systemImage: "wand.and.stars")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(seedColor)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .buttonStyle(.plain)
        }
        .padding()
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(15)
    }

    private var optionsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Generation Options")
                .font(.headline)

            Picker("WCAG Level", selection: $targetLevel) {
                Text("AA").tag(WCAGContrastLevel.AA)
                Text("AAA").tag(WCAGContrastLevel.AAA)
            }
            .pickerStyle(SegmentedPickerStyle())

            Stepper("Palette Size: \(paletteSize)", value: $paletteSize, in: 3...10)

            Toggle("Include Black & White", isOn: $includeBlackAndWhite)
        }
        .padding()
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(15)
    }

    private var palettePreviewSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Generated Palette")
                .font(.headline)

            if generatedPalette.isEmpty {
                Text("Generate a palette to see the preview")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, minHeight: 100)
                    .background(Color.secondary.opacity(0.1))
                    .cornerRadius(10)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 15) {
                        ForEach(generatedPalette.indices, id: \.self) { index in
                            VStack {
                                Circle()
                                    .fill(generatedPalette[index])
                                    .frame(width: 60, height: 60)
                                    .overlay(Circle().stroke(Color.secondary, lineWidth: 1))

                                let hexString = generatedPalette[index].hexString() ?? "#000000"
                                Text(hexString)
                                    .font(.caption)
                            }
                        }
                    }
                    .padding(.vertical)
                }
            }
        }
        .padding()
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(15)
    }

    private var exportSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Export Options")
                .font(.headline)

            TextField("Palette Name", text: $paletteName)
                .textFieldStyle(RoundedBorderTextFieldStyle())

            Picker("Export Format", selection: $selectedExportFormat) {
                ForEach(PaletteExportFormat.allCases) { format in
                    Text(format.rawValue).tag(format)
                }
            }
            .pickerStyle(MenuPickerStyle())

            HStack {
                Button(action: copyToClipboard) {
                    Label("Copy", systemImage: "doc.on.clipboard")
                        .frame(maxWidth: .infinity)
                }

                Button(action: exportPalette) {
                    Label("Export", systemImage: "square.and.arrow.down")
                        .frame(maxWidth: .infinity)
                }

                Button(action: sharePalette) {
                    Label("Share", systemImage: "square.and.arrow.up")
                        .frame(maxWidth: .infinity)
                }
            }
            .disabled(generatedPalette.isEmpty)
            .buttonStyle(.plain)
        }
        .padding()
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(15)
    }

    // MARK: - Actions

    private func generatePalette() {
        let configuration = AccessiblePaletteGenerator.Configuration(
            targetLevel: targetLevel,
            paletteSize: paletteSize,
            includeBlackAndWhite: includeBlackAndWhite
        )

        let generator = AccessiblePaletteGenerator(configuration: configuration)
        generatedPalette = generator.generatePalette(from: seedColor)
    }

    private func copyToClipboard() {
        let entries = PaletteExporter.createPalette(from: generatedPalette)
        let success = PaletteExporter.copyToClipboard(
            palette: entries,
            format: selectedExportFormat,
            paletteName: paletteName
        )

        print(success ? "Copied to clipboard" : "Failed to copy to clipboard")
    }

    private func exportPalette() {
        print("Export action is disabled in preview.")
    }

    private func sharePalette() {
        print("Share action is disabled in preview.")
    }

    private func randomizeColor() {
        seedColor = Color(
            red: Double.random(in: 0...1),
            green: Double.random(in: 0...1),
            blue: Double.random(in: 0...1)
        )
    }
}

// MARK: - Preview

#Preview {
    PaletteStudioPreview()
}
