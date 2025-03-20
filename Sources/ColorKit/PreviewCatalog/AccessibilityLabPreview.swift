//
//  AccessibilityLabPreview.swift
//  ColorKit
//
//  Created by Agisilaos Tsaraboulidis on 20.03.2024.
//
//  Description:
//  A preview component for testing and simulating color accessibility features.
//
//  Features:
//  - Color blindness simulation for different types (TBD)
//  - Interactive contrast ratio checker
//  - WCAG compliance testing (AA/AAA)
//  - Accessibility enhancement suggestions
//
//  License:
//  MIT License. See LICENSE file for details.
//

import SwiftUI

/// A preview component for testing and simulating color accessibility features
public struct AccessibilityLabPreview: View {
    // MARK: - State Properties

    @State private var selectedTab = AccessibilityTab.colorBlindness
    @State private var foregroundColor: Color = .white
    @State private var backgroundColor: Color = .blue
    @State private var selectedSimulation = ColorBlindnessType.protanopia
    @State private var fontSize: CGFloat = 16
    @State private var isBold = false
    @State private var showEnhancedColors = false
    @State private var selectedStrategy: AdjustmentStrategy = .preserveHue
    @State private var targetLevel: WCAGContrastLevel = .AA

    // MARK: - Constants

    private enum AccessibilityTab: String, CaseIterable {
        case colorBlindness = "Color Blindness"
        case contrast = "Contrast"
        case guidelines = "Guidelines"

        var icon: String {
            switch self {
            case .colorBlindness: return "eye"
            case .contrast: return "circle.lefthalf.filled"
            case .guidelines: return "checklist"
            }
        }
    }

    private enum ColorBlindnessType: String, CaseIterable {
        case protanopia = "Protanopia"
        case deuteranopia = "Deuteranopia"
        case tritanopia = "Tritanopia"
        case achromatopsia = "Achromatopsia"

        var description: String {
            switch self {
            case .protanopia: return "Red-blind (1% of males)"
            case .deuteranopia: return "Green-blind (1% of males)"
            case .tritanopia: return "Blue-blind (0.003% of population)"
            case .achromatopsia: return "Complete color blindness"
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
                case .colorBlindness:
                    colorBlindnessSection
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

    private var colorBlindnessSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Simulation Type Selection
            VStack(alignment: .leading, spacing: 10) {
                Text("Simulation Type")
                    .font(.headline)

                Picker("Select Type", selection: $selectedSimulation) {
                    ForEach(ColorBlindnessType.allCases, id: \.self) { type in
                        Text(type.rawValue).tag(type)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())

                Text(selectedSimulation.description)
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
                        RoundedRectangle(cornerRadius: 8)
                            .fill(simulatedColor)
                            .frame(width: 44, height: 44)
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
                        previewCard(color: simulatedColor)
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
                    let enhancedColor = foregroundColor.enhanced(
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
                            previewBox(text: "Sample Text", textColor: enhancedColor)
                        }
                    }

                    // Show suggested variants
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Alternative Suggestions:")
                            .font(.subheadline)

                        let variants = foregroundColor.suggestAccessibleVariants(
                            with: backgroundColor,
                            targetLevel: targetLevel,
                            count: 3
                        )

                        HStack {
                            ForEach(0..<variants.count, id: \.self) { index in
                                previewBox(text: "Aa", textColor: variants[index])
                                    .frame(maxWidth: 60)
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
                    Text("• Test with color blindness simulators")
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

    // MARK: - Computed Properties

    private var simulatedColor: Color {
        // Note: Color blindness simulation is not yet implemented in ColorKit's public interface
        // For now, return the original color
        backgroundColor
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
