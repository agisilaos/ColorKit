//
//  AccessiblePaletteDemoView.swift
//  ColorKit
//
//  Created by Agisilaos Tsaraboulidis on 12.03.25.
//
//  Description:
//  A demo view that showcases the accessible palette generation feature.
//
//  Features:
//  - Interactive UI to generate and preview accessible color palettes
//  - Customizable WCAG level, palette size, and other options
//  - Live preview of generated themes with accessibility information
//
//  License:
//  MIT License. See LICENSE file for details.
//

import SwiftUI
import UniformTypeIdentifiers

/// A demo view that showcases the accessible palette generation feature
public struct AccessiblePaletteDemoView: View {
    // MARK: - State Properties

    // Control States
    @State private var seedColor: Color = .blue
    @State private var targetLevel: WCAGContrastLevel = .AA
    @State private var paletteSize: Int = 5
    @State private var includeBlackAndWhite: Bool = true

    // Generation States
    @State private var palette: [Color] = []
    @State private var theme: ColorTheme?
    @State private var isGenerating: Bool = false

    // Export States
    @StateObject private var export = AccessiblePaletteExport()
    @State private var selectedExportFormat: PaletteExportFormat = .json

    // MARK: - Initialization

    public init() {}

    init(export: AccessiblePaletteExport) {
        _export = StateObject(wrappedValue: export)
    }

    // MARK: - Body

    public var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                headerSection
                controlsSection
                generatedPaletteSection
                themePreviewSection
                Spacer(minLength: 32)
                exportSection
            }
            .padding()
        }
        .onAppear {
            generatePaletteAndTheme()
        }
        .modifier(ExportResultModifier(export: export))
        #if os(iOS)
        .sheet(item: $export.shareItem) { item in
            ShareSheet(items: [item.url])
        }
        #endif
    }

    // MARK: - View Sections

    private var headerSection: some View {
        Text("Accessible Palette Generator")
            .font(.title)
            .fontWeight(.bold)
            .padding(.top)
    }

    private var controlsSection: some View {
        VStack(spacing: 16) {
            ColorPicker("Seed Color", selection: $seedColor)
                .padding(.horizontal)

            Picker("WCAG Level", selection: $targetLevel) {
                ForEach(WCAGContrastLevel.allCases) { level in
                    Text(level.rawValue).tag(level)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(.horizontal)

            VStack(alignment: .leading) {
                Text("Palette Size: \(paletteSize)")
                Slider(
                    value: Binding<Double>(
                        get: { Double(paletteSize) },
                        set: { paletteSize = max(2, min(10, Int($0))) }
                    ),
                    in: 2...10,
                    step: 1,
                    label: {
                        Text("Palette Size: \(paletteSize)")
                    }
                )
            }
            .padding(.horizontal)

            Toggle("Include Black & White", isOn: $includeBlackAndWhite)
                .padding(.horizontal)

            generateButton
        }
        .padding(.bottom)
    }

    private var generateButton: some View {
        Button(action: generatePaletteAndTheme) {
            HStack {
                Text("Generate Palette")
                if isGenerating {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                }
            }
        }
        .padding()
        .background(Color.blue)
        .foregroundColor(.white)
        .cornerRadius(8)
        .disabled(isGenerating)
    }

    private var generatedPaletteSection: some View {
        VStack(spacing: 16) {
            Text("Generated Palette")
                .font(.title2)
                .fontWeight(.semibold)

            if palette.isEmpty && !isGenerating {
                emptyPaletteView
            } else if isGenerating {
                ProgressView("Generating palette...")
                    .padding()
            } else {
                paletteGrid
            }
        }
        .padding(.vertical)
    }

    private var emptyPaletteView: some View {
        Text("Tap 'Generate Palette' to create a palette")
            .foregroundColor(.secondary)
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.secondary.opacity(0.1))
            .cornerRadius(12)
    }

    private var paletteGrid: some View {
        LazyVGrid(
            columns: [GridItem(.adaptive(minimum: 150, maximum: 200), spacing: 16)],
            spacing: 16
        ) {
            ForEach(0..<palette.count, id: \.self) { index in
                paletteItemView(for: index)
            }
        }
        .padding(.horizontal)
    }

    private func paletteItemView(for index: Int) -> some View {
        let color = palette[index]
        let contrastingColor = color.accessibleContrastingColor(for: targetLevel)

        return VStack(spacing: 8) {
            RoundedRectangle(cornerRadius: 12)
                .fill(color)
                .frame(height: 120)
                .overlay(
                    Text("Color \(index + 1)")
                        .font(.headline)
                        .foregroundColor(contrastingColor)
                )
                .shadow(radius: 2)

            if index == 0 {
                contrastRatiosView(for: color)
            }
        }
        .padding(12)
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(16)
    }

    private func contrastRatiosView(for color: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Contrast Ratios:")
                .font(.caption)
                .foregroundColor(.secondary)

            ForEach(1..<min(palette.count, 4), id: \.self) { otherIndex in
                contrastRatioRow(color: color, with: palette[otherIndex], index: otherIndex)
            }
        }
        .padding(.top, 4)
    }

    private func contrastRatioRow(color: Color, with otherColor: Color, index: Int) -> some View {
        let ratio = color.wcagContrastRatio(with: otherColor)
        let passes = ratio >= targetLevel.minimumRatio

        return HStack {
            Circle()
                .fill(otherColor)
                .frame(width: 16, height: 16)
            Text("Color \(index + 1): \(String(format: "%.1f", ratio))")
                .font(.caption)
                .foregroundColor(passes ? .green : .red)
        }
    }

    private var exportSection: some View {
        VStack(spacing: 16) {
            Divider()
                .padding(.vertical, 8)

            Text("Export Options")
                .font(.headline)

            Picker("Export Format", selection: $selectedExportFormat) {
                ForEach(PaletteExportFormat.allCases) { format in
                    Text(format.rawValue).tag(format)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(.horizontal)

            exportButtons
        }
    }

    private var exportButtons: some View {
        VStack(spacing: 12) {
            Button(action: showPaletteExport) {
                HStack {
                    Label("Export Palette", systemImage: "square.and.arrow.up")
                    Spacer()
                    Image(systemName: "chevron.right")
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.accentColor)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            .disabled(palette.isEmpty || export.shareItem != nil)

            Button(action: showThemeExport) {
                HStack {
                    Label("Export Theme", systemImage: "square.and.arrow.up.on.square")
                    Spacer()
                    Image(systemName: "chevron.right")
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.accentColor)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            .disabled(theme == nil || export.shareItem != nil)
        }
        .padding(.horizontal)
    }

    private var themePreviewSection: some View {
        Group {
            if let theme = theme {
                VStack(spacing: 16) {
                    Text("Theme Preview")
                        .font(.title2)
                        .fontWeight(.semibold)

                    HStack(spacing: 16) {
                        // Primary colors
                        VStack {
                            Text("Primary")
                                .font(.caption)
                            RoundedRectangle(cornerRadius: 8)
                                .fill(theme.primary.base)
                                .frame(width: 80, height: 80)
                                .overlay(
                                    Text("P")
                                        .foregroundColor(theme.primary.base.accessibleContrastingColor(for: targetLevel))
                                )
                                .shadow(radius: 2)
                        }

                        // Secondary colors
                        VStack {
                            Text("Secondary")
                                .font(.caption)
                            RoundedRectangle(cornerRadius: 8)
                                .fill(theme.secondary.base)
                                .frame(width: 80, height: 80)
                                .overlay(
                                    Text("S")
                                        .foregroundColor(theme.secondary.base.accessibleContrastingColor(for: targetLevel))
                                )
                                .shadow(radius: 2)
                        }

                        // Accent colors
                        VStack {
                            Text("Accent")
                                .font(.caption)
                            RoundedRectangle(cornerRadius: 8)
                                .fill(theme.accent.base)
                                .frame(width: 80, height: 80)
                                .overlay(
                                    Text("A")
                                        .foregroundColor(theme.accent.base.accessibleContrastingColor(for: targetLevel))
                                )
                                .shadow(radius: 2)
                        }
                    }
                    .padding()

                    // Background with text
                    RoundedRectangle(cornerRadius: 12)
                        .fill(theme.background.base)
                        .frame(height: 100)
                        .overlay(
                            VStack {
                                Text("Background with Text")
                                    .foregroundColor(theme.text.base)

                        Button(action: {}, label: {
                            Text("Primary Button")
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(theme.primary.base)
                                .foregroundColor(theme.primary.base.accessibleContrastingColor(for: targetLevel))
                                .cornerRadius(8)
                        })
                            }
                        )
                }
                .padding()
                .background(Color.secondary.opacity(0.1))
                .cornerRadius(16)
            }
        }
    }

    // MARK: - Helper Methods

    private func generatePaletteAndTheme() {
        isGenerating = true

        let currentSeedColor = seedColor
        let currentTargetLevel = targetLevel
        let currentPaletteSize = paletteSize
        let currentIncludeBlackAndWhite = includeBlackAndWhite

        DispatchQueue.global(qos: .userInitiated).async {
            let newPalette = currentSeedColor.generateAccessiblePalette(
                targetLevel: currentTargetLevel,
                paletteSize: currentPaletteSize,
                includeBlackAndWhite: currentIncludeBlackAndWhite
            )

            let newTheme = currentSeedColor.generateAccessibleTheme(
                name: "Generated Theme",
                targetLevel: currentTargetLevel
            )

            DispatchQueue.main.async {
                palette = newPalette
                theme = newTheme
                isGenerating = false
            }
        }
    }

    private func showPaletteExport() {
        exportSnapshot(AccessiblePaletteExport.Snapshot(
            entries: PaletteExporter.createPalette(from: palette),
            name: "Accessible Palette",
            format: selectedExportFormat
        ))
    }

    private func showThemeExport() {
        guard let theme else { return }
        exportSnapshot(AccessiblePaletteExport.Snapshot(
            entries: PaletteExporter.createPalette(from: theme),
            name: "Generated Theme",
            format: selectedExportFormat
        ))
    }

    private func exportSnapshot(_ snapshot: AccessiblePaletteExport.Snapshot) {
        #if os(macOS)
        export.save(snapshot) {
            let savePanel = NSSavePanel()
            savePanel.allowedContentTypes = [UTType(filenameExtension: snapshot.format.fileExtension) ?? .data]
            savePanel.nameFieldStringValue = snapshot.filename
            return savePanel.runModal() == .OK ? savePanel.url : nil
        }
        #else
        export.share(snapshot)
        #endif
    }
}

// MARK: - Export Result Modifier

private struct ExportResultModifier: ViewModifier {
    @ObservedObject var export: AccessiblePaletteExport

    func body(content: Content) -> some View {
        content
            #if os(iOS)
            .alert(isPresented: $export.showResult) {
                Alert(
                    title: Text("Export Result"),
                    message: Text(export.resultMessage),
                    dismissButton: .default(Text("OK"))
                )
            }
            #elseif os(macOS)
            .onChange(of: export.showResult) { show in
                if show {
                    DispatchQueue.main.async {
                        let alert = NSAlert()
                        alert.messageText = "Export Result"
                        alert.informativeText = export.resultMessage
                        alert.addButton(withTitle: "OK")
                        alert.alertStyle = .informational
                        alert.runModal()
                        export.showResult = false
                    }
                }
            }
            #endif
    }
}
