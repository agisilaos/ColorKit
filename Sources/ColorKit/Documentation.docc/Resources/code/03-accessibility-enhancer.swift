//
//  03-accessibility-enhancer.swift
//  ColorKit
//
//  Created for the AccessibilityGuide tutorial.
//
//  Description:
//  Demonstrates using the AccessibilityEnhancer to improve color
//  accessibility while preserving visual identity.
//
//  License:
//  MIT License. See LICENSE file for details.
//

import SwiftUI

struct ContentView: View {
    @State private var originalColor = Color.blue
    @State private var backgroundColor = Color.white
    @State private var targetLevel: WCAGContrastLevel = .AA
    @State private var strategy: AdjustmentStrategy = .preserveHue

    var body: some View {
        VStack(spacing: 20) {
            Text("Accessibility Color Enhancer")
                .font(.title)
                .padding(.top)

            // Original and Enhanced Color Preview
            VStack(spacing: 15) {
                // Calculate enhanced color
                let enhancedColor = originalColor.enhanced(
                    with: backgroundColor,
                    targetLevel: targetLevel,
                    strategy: strategy
                )

                // Original color
                ColorPreviewRow(
                    title: "Original",
                    color: originalColor,
                    backgroundColor: backgroundColor,
                    contrastRatio: originalColor.wcagContrastRatio(with: backgroundColor)
                )

                // Enhanced color
                ColorPreviewRow(
                    title: "Enhanced",
                    color: enhancedColor,
                    backgroundColor: backgroundColor,
                    contrastRatio: enhancedColor.wcagContrastRatio(with: backgroundColor)
                )
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(10)

            // Color Selection Controls
            VStack(alignment: .leading, spacing: 15) {
                ColorPicker("Select Color to Enhance", selection: $originalColor)

                ColorPicker("Background Color", selection: $backgroundColor)

                // WCAG Level Selection
                VStack(alignment: .leading) {
                    Text("Target WCAG Level:")
                        .font(.headline)

                    Picker("WCAG Level", selection: $targetLevel) {
                        ForEach(WCAGContrastLevel.allCases) { level in
                            Text(level.rawValue).tag(level)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }

                // Strategy Selection
                VStack(alignment: .leading) {
                    Text("Enhancement Strategy:")
                        .font(.headline)

                    Picker("Strategy", selection: $strategy) {
                        ForEach(AdjustmentStrategy.allCases) { strategy in
                            Text(strategy.rawValue.capitalized).tag(strategy)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
            }
            .padding()

            // Suggested Alternatives
            SuggestedAlternativesView(
                originalColor: originalColor,
                backgroundColor: backgroundColor,
                targetLevel: targetLevel
            )
        }
        .padding()
    }
}

struct ColorPreviewRow: View {
    let title: String
    let color: Color
    let backgroundColor: Color
    let contrastRatio: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title)
                .font(.headline)

            HStack {
                // Color sample
                RoundedRectangle(cornerRadius: 8)
                    .fill(color)
                    .frame(width: 60, height: 60)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray, lineWidth: 1)
                    )

                VStack(alignment: .leading) {
                    Text("Contrast Ratio: \(String(format: "%.2f", contrastRatio)):1")
                        .font(.subheadline)

                    // Compliance indicators
                    let passesAA = contrastRatio >= 4.5
                    let passesAAA = contrastRatio >= 7.0

                    HStack {
                        ComplianceBadge(level: "AA", passes: passesAA)
                        ComplianceBadge(level: "AAA", passes: passesAAA)
                    }
                }

                Spacer()

                // Text sample
                Text("Aa")
                    .font(.title)
                    .foregroundColor(color)
                    .padding(8)
                    .background(backgroundColor)
                    .cornerRadius(8)
            }
        }
    }
}

struct ComplianceBadge: View {
    let level: String
    let passes: Bool

    var body: some View {
        Text(level)
            .font(.caption)
            .bold()
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(passes ? Color.green : Color.red)
            .foregroundColor(.white)
            .cornerRadius(6)
    }
}

struct SuggestedAlternativesView: View {
    let originalColor: Color
    let backgroundColor: Color
    let targetLevel: WCAGContrastLevel

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Suggested Alternatives")
                .font(.headline)

            let suggestedColors = originalColor.suggestAccessibleVariants(
                with: backgroundColor,
                targetLevel: targetLevel,
                count: 3
            )

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 20) {
                    ForEach(0..<suggestedColors.count, id: \.self) { index in
                        let color = suggestedColors[index]
                        let ratio = color.wcagContrastRatio(with: backgroundColor)

                        VStack {
                            Text("Option \(index + 1)")
                                .font(.caption)
                                .bold()

                            RoundedRectangle(cornerRadius: 8)
                                .fill(color)
                                .frame(width: 50, height: 50)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.gray, lineWidth: 1)
                                )

                            Text("\(String(format: "%.1f", ratio)):1")
                                .font(.caption)
                        }
                    }
                }
                .padding(.vertical, 8)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(10)
    }
}

#Preview {
    ContentView()
}
