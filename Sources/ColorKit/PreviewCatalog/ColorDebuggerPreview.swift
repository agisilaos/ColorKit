//
//  ColorDebuggerPreview.swift
//  ColorKit
//
//  Created by Agisilaos Tsaraboulidis on 20.03.25.
//
//  Description:
//  Interactive preview for debugging and inspecting colors.
//
//  Features:
//  - Real-time color inspection
//  - Color space visualization
//  - Component analysis
//  - Color comparison tools
//
//  License:
//  MIT License. See LICENSE file for details.
//

import SwiftUI

/// A preview view for debugging and inspecting colors
public struct ColorDebuggerPreview: View {
    // MARK: - State

    @State private var selectedColor: Color = .blue
    @State private var comparisonColor: Color = .white
    @State private var selectedTab = DebuggerTab.inspector
    @State private var showColorPicker = false
    @State private var showComparisonPicker = false

    // MARK: - Properties

    private enum DebuggerTab {
        case inspector
        case spaceAnalysis
        case comparison
    }

    // MARK: - Body

    public var body: some View {
        VStack(spacing: 20) {
            // Tab Selection
            Picker("Debug Mode", selection: $selectedTab) {
                Text("Inspector").tag(DebuggerTab.inspector)
                Text("Color Spaces").tag(DebuggerTab.spaceAnalysis)
                Text("Comparison").tag(DebuggerTab.comparison)
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(.horizontal)

            // Color Selection
            colorSelectionSection

            // Content based on selected tab
            ScrollView {
                VStack(spacing: 24) {
                    switch selectedTab {
                    case .inspector:
                        ColorInspectorView(color: selectedColor, backgroundColor: comparisonColor)
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(12)

                    case .spaceAnalysis:
                        ColorSpaceInspectorView(color: selectedColor)
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(12)

                    case .comparison:
                        comparisonSection
                    }
                }
                .padding()
            }
        }
        .navigationTitle("Color Debugger")
        .sheet(isPresented: $showColorPicker) {
            ColorPicker("Select Color", selection: $selectedColor)
                .padding()
        }
        .sheet(isPresented: $showComparisonPicker) {
            ColorPicker("Select Comparison Color", selection: $comparisonColor)
                .padding()
        }
    }

    // MARK: - View Components

    private var colorSelectionSection: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading) {
                Text("Primary Color")
                    .font(.caption)
                    .foregroundColor(.secondary)

                RoundedRectangle(cornerRadius: 8)
                    .fill(selectedColor)
                    .frame(width: 60, height: 60)
                    .shadow(radius: 2)
                    .onTapGesture {
                        showColorPicker = true
                    }
            }

            if selectedTab == .comparison {
                VStack(alignment: .leading) {
                    Text("Comparison Color")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    RoundedRectangle(cornerRadius: 8)
                        .fill(comparisonColor)
                        .frame(width: 60, height: 60)
                        .shadow(radius: 2)
                        .onTapGesture {
                            showComparisonPicker = true
                        }
                }
            }

            Spacer()
        }
        .padding(.horizontal)
    }

    private var comparisonSection: some View {
        VStack(spacing: 16) {
            // Color Preview
            HStack(spacing: 0) {
                Rectangle()
                    .fill(selectedColor)
                    .frame(height: 100)

                Rectangle()
                    .fill(comparisonColor)
                    .frame(height: 100)
            }
            .cornerRadius(12)
            .shadow(radius: 2)

            // Contrast Information
            VStack(alignment: .leading, spacing: 8) {
                Text("Contrast Analysis")
                    .font(.headline)

                let contrastRatio = calculateContrastRatio(between: selectedColor, and: comparisonColor)
                Text("Contrast Ratio: \(String(format: "%.2f", contrastRatio)):1")
                    .font(.system(.body, design: .monospaced))

                // WCAG Compliance
                HStack(spacing: 12) {
                    WCAGComplianceBadge(
                        level: "AA",
                        isLargeText: false,
                        passes: contrastRatio >= 4.5
                    )

                    WCAGComplianceBadge(
                        level: "AA",
                        isLargeText: true,
                        passes: contrastRatio >= 3.0
                    )

                    WCAGComplianceBadge(
                        level: "AAA",
                        isLargeText: false,
                        passes: contrastRatio >= 7.0
                    )

                    WCAGComplianceBadge(
                        level: "AAA",
                        isLargeText: true,
                        passes: contrastRatio >= 4.5
                    )
                }
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(12)

            // Color Differences
            VStack(alignment: .leading, spacing: 8) {
                Text("Color Differences")
                    .font(.headline)

                let components1 = selectedColor.colorSpaceComponents()
                let components2 = comparisonColor.colorSpaceComponents()

                Group {
                    colorDifferenceRow("RGB Δ", components: [
                        abs(components1.rgb.red - components2.rgb.red),
                        abs(components1.rgb.green - components2.rgb.green),
                        abs(components1.rgb.blue - components2.rgb.blue)
                    ])

                    colorDifferenceRow("HSL Δ", components: [
                        abs(components1.hsl.hue - components2.hsl.hue),
                        abs(components1.hsl.saturation - components2.hsl.saturation),
                        abs(components1.hsl.lightness - components2.hsl.lightness)
                    ])

                    colorDifferenceRow("LAB Δ", components: [
                        abs(components1.lab.l - components2.lab.l) / 100,
                        (abs(components1.lab.a - components2.lab.a) / 128 + 1) / 2,
                        (abs(components1.lab.b - components2.lab.b) / 128 + 1) / 2
                    ])
                }
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(12)
        }
    }

    private func colorDifferenceRow(_ label: String, components: [Double]) -> some View {
        HStack {
            Text(label)
                .frame(width: 60, alignment: .leading)
                .font(.system(.body, design: .monospaced))

            ForEach(components.indices, id: \.self) { index in
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.blue.opacity(components[index]))
                    .frame(height: 20)
                    .overlay(
                        Text(String(format: "%.2f", components[index]))
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundColor(.white)
                    )
            }
        }
    }

    // MARK: - Helper Functions

    private func calculateContrastRatio(between color1: Color, and color2: Color) -> Double {
        return color1.wcagContrastRatio(with: color2)
    }
}

// MARK: - Supporting Views

private struct WCAGComplianceBadge: View {
    let level: String
    let isLargeText: Bool
    let passes: Bool

    var body: some View {
        Text("\(level)\(isLargeText ? "+" : "")")
            .font(.system(size: 10, weight: .bold))
            .padding(.horizontal, 4)
            .padding(.vertical, 2)
            .background(passes ? Color.green : Color.red)
            .foregroundColor(.white)
            .cornerRadius(4)
    }
}

// MARK: - Preview

#Preview {
    NavigationView {
        ColorDebuggerPreview()
    }
}
