//
//  AccessibilityEnhancerDemoView.swift
//  ColorKit
//
//  Created by Agisilaos Tsaraboulidis on 13.03.25.
//
//  Description:
//  Demonstrates the enhanced accessibility features of ColorKit.
//
//  Features:
//  - Interactive demo of accessibility enhancement strategies
//  - Visual comparison of original and enhanced colors
//  - Contrast ratio display
//  - Strategy selection
//
//  License:
//  MIT License. See LICENSE file for details.
//

import SwiftUI

/// A demo view that showcases the enhanced accessibility features of ColorKit
public struct AccessibilityEnhancerDemoView: View {
    @State private var originalColor = Color(.sRGB, red: 0, green: 0.478, blue: 1)
    @State private var backgroundColor = Color(.sRGB, red: 1, green: 1, blue: 1)
    @State private var targetLevel: WCAGContrastLevel = .AA
    @State private var strategy: AdjustmentStrategy = .preserveHue
    @State private var showVariants: Bool = false

    public init() {}

    public var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("Accessibility Enhancer Demo")
                    .font(.title)
                    .fontWeight(.bold)

                // Color pickers
                VStack(alignment: .leading, spacing: 10) {
                    Text("Original Color")
                        .font(.headline)

                    ColorPicker("Select Color", selection: $originalColor)
                        .padding()
                        .background(RoundedRectangle(cornerRadius: 8).fill(Color.gray.opacity(0.1)))

                    Text("Background Color")
                        .font(.headline)

                    ColorPicker("Select Background", selection: $backgroundColor)
                        .padding()
                        .background(RoundedRectangle(cornerRadius: 8).fill(Color.gray.opacity(0.1)))
                }
                .padding(.horizontal)

                // WCAG level picker
                VStack(alignment: .leading, spacing: 10) {
                    Text("Target WCAG Level")
                        .font(.headline)

                    Picker("WCAG Level", selection: $targetLevel) {
                        ForEach(WCAGContrastLevel.allCases) { level in
                            Text(level.rawValue).tag(level)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 8).fill(Color.gray.opacity(0.1)))
                }
                .padding(.horizontal)

                // Strategy picker
                VStack(alignment: .leading, spacing: 10) {
                    Text("Enhancement Strategy")
                        .font(.headline)

                    Picker("Strategy", selection: $strategy) {
                        ForEach(AdjustmentStrategy.allCases) { strategy in
                            Text(strategy.rawValue.capitalized).tag(strategy)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 8).fill(Color.gray.opacity(0.1)))

                    Text(strategy.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                }
                .padding(.horizontal)

                // Color comparison
                VStack(spacing: 20) {
                    Text("Color Comparison")
                        .font(.headline)

                    HStack(spacing: 20) {
                        // Original color
                        VStack {
                            Text("Original")
                                .font(.subheadline)

                            ZStack {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(backgroundColor)
                                    .frame(width: 120, height: 80)
                                    .shadow(radius: 2)

                                RoundedRectangle(cornerRadius: 4)
                                    .fill(originalColor)
                                    .frame(width: 100, height: 60)

                                Text("Text")
                                    .foregroundColor(originalColor)
                                    .fontWeight(.bold)
                            }

                            let originalResult = originalColor.accessibilityResult(
                                against: backgroundColor,
                                targetLevel: targetLevel
                            )

                            Text(ratioText(for: originalResult))
                                .font(.caption)
                                .foregroundColor(statusColor(for: originalResult.status))

                            Text(statusText(for: originalResult.status))
                                .font(.caption)
                                .foregroundColor(statusColor(for: originalResult.status))
                                .fontWeight(.bold)
                        }

                        // Enhanced color
                        VStack {
                            Text("Enhanced")
                                .font(.subheadline)

                            let enhancedResult = originalColor.enhancementResult(
                                with: backgroundColor,
                                targetLevel: targetLevel,
                                strategy: strategy
                            )

                            ZStack {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(backgroundColor)
                                    .frame(width: 120, height: 80)
                                    .shadow(radius: 2)

                                RoundedRectangle(cornerRadius: 4)
                                    .fill(enhancedResult.color)
                                    .frame(width: 100, height: 60)

                                Text("Text")
                                    .foregroundColor(enhancedResult.color)
                                    .fontWeight(.bold)
                            }

                            Text(ratioText(for: enhancedResult))
                                .font(.caption)
                                .foregroundColor(statusColor(for: enhancedResult.status))

                            Text(statusText(for: enhancedResult.status))
                                .font(.caption)
                                .foregroundColor(statusColor(for: enhancedResult.status))
                                .fontWeight(.bold)
                        }
                    }
                }
                .padding()
                .background(RoundedRectangle(cornerRadius: 12).fill(Color.gray.opacity(0.1)))
                .padding(.horizontal)

                // Variants
                VStack(alignment: .leading, spacing: 10) {
                    Button(
                        action: { showVariants.toggle() },
                        label: {
                            HStack {
                                Text(showVariants ? "Hide Variants" : "Show Suggested Variants")
                                Image(systemName: showVariants ? "chevron.up" : "chevron.down")
                            }
                            .font(.headline)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(RoundedRectangle(cornerRadius: 8).fill(Color.gray.opacity(0.1)))
                        }
                    )

                    if showVariants {
                        let results = originalColor.suggestAccessibleVariantResults(
                            with: backgroundColor,
                            targetLevel: targetLevel,
                            count: 4
                        )

                        Text("Each variant reports whether it meets the selected target:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.horizontal)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 15) {
                                ForEach(0..<results.count, id: \.self) { index in
                                    let result = results[index]

                                    VStack {
                                        ZStack {
                                            RoundedRectangle(cornerRadius: 8)
                                                .fill(backgroundColor)
                                                .frame(width: 100, height: 70)
                                                .shadow(radius: 2)

                                            RoundedRectangle(cornerRadius: 4)
                                                .fill(result.color)
                                                .frame(width: 80, height: 50)

                                            Text("Aa")
                                                .foregroundColor(result.color)
                                                .fontWeight(.bold)
                                        }

                                        Text(ratioText(for: result))
                                            .font(.caption)
                                        Text(statusText(for: result.status))
                                            .font(.caption2)
                                            .foregroundColor(statusColor(for: result.status))
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                }
                .padding(.horizontal)

                // Explanation
                VStack(alignment: .leading, spacing: 10) {
                    Text("How It Works")
                        .font(.headline)
                    Text("The enhancer adjusts colors toward a WCAG target while preserving visual identity. Assessed results report a pass, a measurable best effort, or an unavailable measurement.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(RoundedRectangle(cornerRadius: 12).fill(Color.gray.opacity(0.1)))
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
    }

    private func ratioText(for result: ColorAccessibilityResult) -> String {
        guard let ratio = result.contrastRatio else { return "Ratio: Unavailable" }
        return "Ratio: \(String(format: "%.2f", ratio))"
    }

    private func statusText(for status: ColorAccessibilityResult.Status) -> String {
        switch status {
        case .meetsTarget:
            return "Meets target"
        case .bestEffort:
            return "Best effort"
        case .unavailable:
            return "Unavailable"
        }
    }

    private func statusColor(for status: ColorAccessibilityResult.Status) -> Color {
        switch status {
        case .meetsTarget:
            return .green
        case .bestEffort:
            return .orange
        case .unavailable:
            return .secondary
        }
    }
}

#Preview {
    AccessibilityEnhancerDemoView()
}
