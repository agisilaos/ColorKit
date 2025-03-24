//
//  05-accessibility-info-display.swift
//  ColorKit
//
//  Created for the AccessibilityGuide tutorial.
//
//  Description:
//  Provides a reusable component for displaying detailed accessibility information
//  about color combinations, including contrast ratios and WCAG compliance.
//
//  License:
//  MIT License. See LICENSE file for details.
//

import SwiftUI

struct ContentView: View {
    @State private var foregroundColor = Color.blue
    @State private var backgroundColor = Color.white

    var body: some View {
        VStack(spacing: 25) {
            Text("Accessibility Info Display")
                .font(.largeTitle)
                .padding(.top)

            // Color selection controls
            VStack(spacing: 15) {
                ColorPicker("Text Color", selection: $foregroundColor)
                ColorPicker("Background Color", selection: $backgroundColor)
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(10)

            // Sample text with selected colors
            VStack(spacing: 10) {
                Text("Normal Text Sample")
                    .font(.body)
                    .foregroundColor(foregroundColor)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(backgroundColor)
                    .cornerRadius(10)

                Text("Large Text Sample")
                    .font(.title2)
                    .foregroundColor(foregroundColor)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(backgroundColor)
                    .cornerRadius(10)
            }
            .padding(.horizontal)

            // Accessibility information display
            AccessibilityInfoDisplay(
                foregroundColor: foregroundColor,
                backgroundColor: backgroundColor
            )

            Spacer()
        }
        .padding()
    }
}

/// A reusable view component for displaying accessibility information about a color combination
struct AccessibilityInfoDisplay: View {
    let foregroundColor: Color
    let backgroundColor: Color

    var body: some View {
        // Calculate contrast compliance
        let compliance = foregroundColor.wcagCompliance(with: backgroundColor)

        VStack(alignment: .leading, spacing: 15) {
            Text("Contrast Information")
                .font(.headline)

            // Contrast Ratio
            HStack {
                Text("Contrast Ratio:")
                    .bold()

                Spacer()

                Text("\(String(format: "%.2f", compliance.contrastRatio)):1")
                    .font(.system(.body, design: .monospaced))
                    .foregroundColor(getContrastRatingColor(compliance.contrastRatio))
            }

            // WCAG Compliance Results
            VStack(alignment: .leading, spacing: 12) {
                Text("WCAG Compliance:")
                    .bold()

                // Standard Text Requirements
                VStack(alignment: .leading, spacing: 4) {
                    Text("Standard Text")
                        .font(.subheadline)

                    ComplianceRow(
                        level: "AA",
                        requirement: "4.5:1",
                        passes: compliance.passesAA,
                        ratio: compliance.contrastRatio
                    )

                    ComplianceRow(
                        level: "AAA",
                        requirement: "7.0:1",
                        passes: compliance.passesAAA,
                        ratio: compliance.contrastRatio
                    )
                }
                .padding(.leading)

                // Large Text Requirements
                VStack(alignment: .leading, spacing: 4) {
                    Text("Large Text")
                        .font(.subheadline)

                    ComplianceRow(
                        level: "AA",
                        requirement: "3.0:1",
                        passes: compliance.passesAALarge,
                        ratio: compliance.contrastRatio
                    )

                    ComplianceRow(
                        level: "AAA",
                        requirement: "4.5:1",
                        passes: compliance.passesAAALarge,
                        ratio: compliance.contrastRatio
                    )
                }
                .padding(.leading)
            }

            // Overall Accessibility Rating
            HStack {
                Text("Overall Rating:")
                    .bold()

                Spacer()

                if let highestLevel = compliance.highestLevel {
                    Text(highestLevel.rawValue)
                        .bold()
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(4)
                } else {
                    Text("Fails All Levels")
                        .bold()
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.red)
                        .foregroundColor(.white)
                        .cornerRadius(4)
                }
            }

            // Suggestions if failing
            if compliance.highestLevel == nil {
                Text("Suggestion: Try enhancing the color contrast")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.top, 5)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(10)
    }

    /// Get a color that represents the rating for a contrast ratio
    private func getContrastRatingColor(_ ratio: Double) -> Color {
        if ratio >= 7.0 {
            return .green
        } else if ratio >= 4.5 {
            return .blue
        } else if ratio >= 3.0 {
            return .orange
        } else {
            return .red
        }
    }
}

/// A row showing compliance status for a specific WCAG level
struct ComplianceRow: View {
    let level: String
    let requirement: String
    let passes: Bool
    let ratio: Double

    var body: some View {
        HStack {
            Image(systemName: passes ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundColor(passes ? .green : .red)

            Text("Level \(level)")
                .font(.body)
                .bold()

            Text("(min \(requirement))")
                .font(.caption)
                .foregroundColor(.secondary)

            Spacer()

            // Progress indicator showing how close the ratio is to the requirement
            ProgressView(value: progressValue)
                .frame(width: 80)
                .progressViewStyle(BarProgressStyle(color: progressColor))
        }
    }

    /// Calculate how close the ratio is to meeting the requirement
    private var progressValue: Double {
        let minRequired = Double(requirement.replacingOccurrences(of: ":1", with: "")) ?? 1.0

        if ratio >= minRequired {
            return 1.0
        } else {
            // Calculate a percentage of how close we are
            return min(max(ratio / minRequired, 0.0), 1.0)
        }
    }

    /// Get an appropriate color for the progress bar
    private var progressColor: Color {
        if passes {
            return .green
        } else if progressValue > 0.8 {
            return .orange
        } else if progressValue > 0.5 {
            return .yellow
        } else {
            return .red
        }
    }
}

/// Custom progress view style
struct BarProgressStyle: ProgressViewStyle {
    var color: Color = .blue

    func makeBody(configuration: Configuration) -> some View {
        ZStack(alignment: .leading) {
            RoundedRectangle(cornerRadius: 10)
                .frame(height: 8)
                .foregroundColor(Color.gray.opacity(0.2))

            RoundedRectangle(cornerRadius: 10)
                .frame(width: configuration.fractionCompleted.map { $0 * 80 } ?? 0, height: 8)
                .foregroundColor(color)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
