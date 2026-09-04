//
//  AccessibilityLabPreview.swift
//  ColorKit
//
//  Created by Agisilaos Tsaraboulidis on 20.03.2025.
//
//  Description:
//  A preview component for testing color accessibility features.
//
//  Features:
//  - Fixed-color dichromacy simulation for supported deficiencies
//  - Interactive contrast ratio checker
//  - WCAG compliance testing (AA/AAA)
//  - Accessibility enhancement suggestions
//
//  License:
//  MIT License. See LICENSE file for details.
//

import SwiftUI

/// A preview component for testing fixed-color simulation and color accessibility features.
public struct AccessibilityLabPreview: View {
    /// Creates the interactive preview with its default configuration.
    public init() {}

    // MARK: - State Properties

    @State private var selectedTab = AccessibilityTab.colorVisionDeficiency
    @State private var foregroundColor = Color(.sRGB, red: 1, green: 1, blue: 1)
    @State private var backgroundColor = Color(.sRGB, red: 0, green: 0.478, blue: 1)
    @State private var selectedSimulation = ColorVisionDeficiency.protanopia
    @State private var fontSize: CGFloat = 16
    @State private var isBold = false
    @State private var showEnhancedColors = false
    @State private var selectedStrategy: AdjustmentStrategy = .preserveHue
    @State private var targetLevel: WCAGContrastLevel = .AA

    // MARK: - Constants

    private enum AccessibilityTab: String, CaseIterable {
        case colorVisionDeficiency = "CVD Simulation"
        case contrast = "Contrast"
        case guidelines = "Guidelines"

        var icon: String {
            switch self {
            case .colorVisionDeficiency: return "eye"
            case .contrast: return "circle.lefthalf.filled"
            case .guidelines: return "checklist"
            }
        }
    }

    // MARK: - Body

    public var body: some View {
        VStack(spacing: 20) {
            // Header
            Text("Accessibility Lab")
                .font(.largeTitle)
                .fontWeight(.bold)

            // Tab Selection
            Picker("Select Tool", selection: $selectedTab) {
                ForEach(AccessibilityTab.allCases, id: \.self) { tab in
                    Label(tab.rawValue, systemImage: tab.icon)
                        .tag(tab)
                }
            }
            .pickerStyle(SegmentedPickerStyle())

            // Content
            ScrollView {
                switch selectedTab {
                case .colorVisionDeficiency:
                    colorVisionDeficiencySection
                case .contrast:
                    contrastCheckerSection
                case .guidelines:
                    guidelinesSection
                }
            }
        }
        .padding()
    }

    // MARK: - Sections

    private var colorVisionDeficiencySection: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Simulation Type Selection
            VStack(alignment: .leading, spacing: 10) {
                Text("Simulation Type")
                    .font(.headline)

                Picker("Select Type", selection: $selectedSimulation) {
                    ForEach(ColorVisionDeficiency.allCases) { deficiency in
                        Text(deficiency.previewPresentation.name).tag(deficiency)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())

                Text(selectedSimulation.previewPresentation.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color.secondary.opacity(0.1))
            .cornerRadius(15)

            // Color Selection
            VStack(alignment: .leading, spacing: 10) {
                Text("Test Colors")
                    .font(.headline)

                HStack(spacing: 20) {
                    VStack(alignment: .leading) {
                        Text("Original Color")
                            .font(.subheadline)
                        ColorPicker("Select color", selection: $backgroundColor)
                            .labelsHidden()
                    }

                    VStack(alignment: .leading) {
                        Text("Simulated View")
                            .font(.subheadline)
                        AccessibilityLabSimulationSwatch(
                            color: backgroundColor,
                            deficiency: selectedSimulation
                        )
                            .frame(width: 44, height: 44)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.secondary, lineWidth: 1))
                    }
                }
            }
            .padding()
            .background(Color.secondary.opacity(0.1))
            .cornerRadius(15)

            // Preview
            VStack(alignment: .leading, spacing: 10) {
                Text("Preview")
                    .font(.headline)

                HStack(spacing: 20) {
                    // Original
                    VStack {
                        Text("Original")
                            .font(.subheadline)
                        previewCard(color: backgroundColor)
                    }

                    // Simulated
                    VStack {
                        Text("Simulated")
                            .font(.subheadline)
                        if let simulatedColor {
                            previewCard(color: simulatedColor)
                        } else {
                            simulationUnavailableCard
                        }
                    }
                }
            }
            .padding()
            .background(Color.secondary.opacity(0.1))
            .cornerRadius(15)
        }
    }

    private var contrastCheckerSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Color Selection
            VStack(alignment: .leading, spacing: 10) {
                Text("Colors")
                    .font(.headline)

                HStack(spacing: 20) {
                    VStack(alignment: .leading) {
                        Text("Text Color")
                            .font(.subheadline)
                        ColorPicker("Select text color", selection: $foregroundColor)
                            .labelsHidden()
                    }

                    VStack(alignment: .leading) {
                        Text("Background Color")
                            .font(.subheadline)
                        ColorPicker("Select background color", selection: $backgroundColor)
                            .labelsHidden()
                    }
                }
            }
            .padding()
            .background(Color.secondary.opacity(0.1))
            .cornerRadius(15)

            // Enhancement Options
            VStack(alignment: .leading, spacing: 10) {
                Text("Enhancement Options")
                    .font(.headline)

                Picker("Target Level", selection: $targetLevel) {
                    Text("AA").tag(WCAGContrastLevel.AA)
                    Text("AAA").tag(WCAGContrastLevel.AAA)
                }
                .pickerStyle(SegmentedPickerStyle())

                Picker("Strategy", selection: $selectedStrategy) {
                    ForEach(AdjustmentStrategy.allCases) { strategy in
                        Text(strategy.rawValue.capitalized).tag(strategy)
                    }
                }
                .pickerStyle(MenuPickerStyle())

                Toggle("Show Enhanced Colors", isOn: $showEnhancedColors)
            }
            .padding()
            .background(Color.secondary.opacity(0.1))
            .cornerRadius(15)

            // Text Options
            VStack(alignment: .leading, spacing: 10) {
                Text("Text Options")
                    .font(.headline)

                HStack {
                    Slider(value: $fontSize, in: 12...32) {
                        Text("Font Size: \(Int(fontSize))pt")
                    }

                    Toggle("Bold", isOn: $isBold)
                }
            }
            .padding()
            .background(Color.secondary.opacity(0.1))
            .cornerRadius(15)

            // Preview
            VStack(alignment: .leading, spacing: 10) {
                Text("Preview")
                    .font(.headline)

                if showEnhancedColors {
                    let enhancedResult = foregroundColor.enhancementResult(
                        with: backgroundColor,
                        targetLevel: targetLevel,
                        strategy: selectedStrategy
                    )

                    HStack(spacing: 20) {
                        // Original
                        VStack {
                            Text("Original")
                                .font(.subheadline)
                            previewBox(text: "Sample Text", textColor: foregroundColor)
                        }

                        // Enhanced
                        VStack {
                            Text("Enhanced")
                                .font(.subheadline)
                            previewBox(text: "Sample Text", textColor: enhancedResult.color)
                            resultSummary(enhancedResult)
                        }
                    }

                    // Show suggested variants
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Alternative Suggestions:")
                            .font(.subheadline)

                        let results = foregroundColor.suggestAccessibleVariantResults(
                            with: backgroundColor,
                            targetLevel: targetLevel,
                            count: 3
                        )

                        HStack {
                            ForEach(0..<results.count, id: \.self) { index in
                                VStack {
                                    previewBox(text: "Aa", textColor: results[index].color)
                                    resultSummary(results[index])
                                }
                                .frame(maxWidth: 80)
                            }
                        }
                    }
                    .padding(.top)
                } else {
                    previewBox(text: "Sample Text", textColor: foregroundColor)
                }

                // Contrast Information
                VStack(alignment: .leading, spacing: 5) {
                    HStack {
                        Text("Contrast Ratio:")
                            .font(.headline)
                        Text(String(format: "%.2f:1", contrastRatio))
                            .font(.system(.headline, design: .monospaced))
                    }

                    HStack {
                        Text("WCAG 2.1 AA:")
                            .font(.subheadline)
                        Image(systemName: meetsWCAGAA ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundColor(meetsWCAGAA ? .green : .red)
                    }

                    HStack {
                        Text("WCAG 2.1 AAA:")
                            .font(.subheadline)
                        Image(systemName: meetsWCAGAAA ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundColor(meetsWCAGAAA ? .green : .red)
                    }

                    if !meetsWCAGAA {
                        Text("Tip: Enable 'Show Enhanced Colors' to see accessible alternatives")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.top, 5)
                    }
                }
            }
            .padding()
            .background(Color.secondary.opacity(0.1))
            .cornerRadius(15)
        }
    }

    private var guidelinesSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            // WCAG Guidelines
            VStack(alignment: .leading, spacing: 10) {
                Text("WCAG 2.1 Guidelines")
                    .font(.headline)

                VStack(alignment: .leading, spacing: 5) {
                    Text("Contrast Requirements:")
                        .font(.subheadline)
                    Text("• AA - Normal Text: 4.5:1")
                    Text("• AA - Large Text: 3:1")
                    Text("• AAA - Normal Text: 7:1")
                    Text("• AAA - Large Text: 4.5:1")
                }
            }
            .padding()
            .background(Color.secondary.opacity(0.1))
            .cornerRadius(15)

            // Best Practices
            VStack(alignment: .leading, spacing: 10) {
                Text("Best Practices")
                    .font(.headline)

                VStack(alignment: .leading, spacing: 5) {
                    Text("• Use sufficient color contrast")
                    Text("• Don't rely on color alone")
                    Text("• Provide text alternatives")
                    Text("• Support high contrast mode")
                    Text("• Test fixed colors with CVD simulators")
                }
            }
            .padding()
            .background(Color.secondary.opacity(0.1))
            .cornerRadius(15)

            // Resources
            VStack(alignment: .leading, spacing: 10) {
                Text("Resources")
                    .font(.headline)

                VStack(alignment: .leading, spacing: 5) {
                    Text("• WCAG 2.1 Documentation")
                    Text("• Color Contrast Analyzer")
                    Text("• WebAIM Resources")
                    Text("• A11Y Project Guidelines")
                }
            }
            .padding()
            .background(Color.secondary.opacity(0.1))
            .cornerRadius(15)
        }
    }

    // MARK: - Helper Views

    private func previewCard(color: Color) -> some View {
        VStack(spacing: 10) {
            RoundedRectangle(cornerRadius: 8)
                .fill(color)
                .frame(height: 100)
                .overlay(
                    Text(color.hexString() ?? "#000000")
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(.white)
                        .shadow(radius: 1)
                )

            Text("Sample Text")
                .foregroundColor(color)
        }
    }

    private var simulationUnavailableCard: some View {
        VStack(spacing: 10) {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.secondary.opacity(0.1))
                .frame(height: 100)
                .overlay(
                    Label(
                        "Simulation unavailable for this color",
                        systemImage: "exclamationmark.triangle.fill"
                    )
                    .font(.caption)
                    .multilineTextAlignment(.center)
                    .padding()
                )

            Text("No simulated color")
                .foregroundColor(.secondary)
        }
    }

    private func previewBox(text: String, textColor: Color) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 15)
                .fill(backgroundColor)

            Text(text)
                .font(.system(size: fontSize, weight: isBold ? .bold : .regular))
                .foregroundColor(textColor)
        }
        .frame(height: 100)
    }

    @ViewBuilder
    private func resultSummary(_ result: ColorAccessibilityResult) -> some View {
        switch result.status {
        case .meetsTarget:
            Label(ratioText(for: result), systemImage: "checkmark.circle.fill")
                .foregroundColor(.green)
        case .bestEffort:
            Label(ratioText(for: result), systemImage: "exclamationmark.circle.fill")
                .foregroundColor(.orange)
        case .unavailable:
            Label("Unavailable", systemImage: "questionmark.circle.fill")
                .foregroundColor(.secondary)
        case .invalidConfiguration:
            Label("Invalid configuration", systemImage: "exclamationmark.triangle.fill")
                .foregroundColor(.red)
        }
    }

    private func ratioText(for result: ColorAccessibilityResult) -> String {
        guard let ratio = result.contrastRatio else { return "Unavailable" }
        return String(format: "%.2f:1", ratio)
    }

    // MARK: - Computed Properties

    private var simulatedColor: Color? {
        backgroundColor.simulated(for: selectedSimulation)
    }

    private var contrastRatio: Double {
        foregroundColor.wcagContrastRatio(with: backgroundColor)
    }

    private var meetsWCAGAA: Bool {
        let compliance = foregroundColor.wcagCompliance(with: backgroundColor)
        return isBold || fontSize >= 18 ? compliance.passesAALarge : compliance.passesAA
    }

    private var meetsWCAGAAA: Bool {
        let compliance = foregroundColor.wcagCompliance(with: backgroundColor)
        return isBold || fontSize >= 18 ? compliance.passesAAALarge : compliance.passesAAA
    }
}

#if os(iOS)
// This preview is iOS-only because ColorPicker doesn't work in macOS Previews.
// It works fine on a running macOS app, but Xcode's Preview does not support it.
#Preview {
    AccessibilityLabPreview()
}
#endif
