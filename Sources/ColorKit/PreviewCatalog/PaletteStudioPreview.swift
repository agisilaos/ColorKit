import SwiftUI
import UniformTypeIdentifiers

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
    @State private var showResultMessage = false
    @State private var resultMessage = ""

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
        .alert("Result", isPresented: $showResultMessage) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(resultMessage)
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

        resultMessage = success ? "Copied to clipboard" : "Failed to copy to clipboard"
        showResultMessage = true
    }

    private func exportPalette() {
        // In SwiftUI previews, export functionality (like save panels) cannot be presented.
        // Simulate export action by showing a message.
        resultMessage = "Export action is disabled in preview."
        showResultMessage = true
    }

    private func sharePalette() {
        // In SwiftUI previews, share functionality (like share sheets) cannot be presented.
        // Simulate share action by showing a message.
        resultMessage = "Share action is disabled in preview."
        showResultMessage = true
    }

    private func randomizeColor() {
        seedColor = Color(
            red: Double.random(in: 0...1),
            green: Double.random(in: 0...1),
            blue: Double.random(in: 0...1)
        )
    }
}

#Preview {
    PaletteStudioPreview()
}
