//
//  04-accessibility-requirements.swift
//  ColorKit
//
//  Created for the AccessibilityGuide tutorial.
//
//  Description:
//  Illustrates how to check if colors meet various WCAG accessibility
//  standards (AA and AAA for both normal and large text).
//
//  License:
//  MIT License. See LICENSE file for details.
//

import SwiftUI

struct ContentView: View {
    // Sample colors to test
    let backgroundColors: [(name: String, color: Color)] = [
        ("White", .white),
        ("Light Gray", Color(white: 0.9)),
        ("Medium Gray", Color(white: 0.5)),
        ("Dark Gray", Color(white: 0.2)),
        ("Black", .black)
    ]

    let textColors: [(name: String, color: Color)] = [
        ("Black", .black),
        ("Dark Gray", Color(white: 0.3)),
        ("Blue", .blue),
        ("Green", .green),
        ("Red", .red),
        ("Yellow", .yellow),
        ("Purple", .purple),
        ("Light Gray", Color(white: 0.7)),
        ("White", .white)
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("WCAG Contrast Requirements")
                    .font(.largeTitle)
                    .padding(.top)

                Text("WCAG 2.1 defines the following minimum contrast ratios:")
                    .font(.headline)

                VStack(alignment: .leading, spacing: 5) {
                    RequirementRow(level: "AA", description: "Normal text (≥ 4.5:1)")
                    RequirementRow(level: "AA", description: "Large text (≥ 3:1)")
                    RequirementRow(level: "AAA", description: "Normal text (≥ 7:1)")
                    RequirementRow(level: "AAA", description: "Large text (≥ 4.5:1)")
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)

                Text("Color Combinations Test")
                    .font(.title)
                    .padding(.top)

                // Test multiple color combinations
                ForEach(backgroundColors, id: \.name) { bgInfo in
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Background: \(bgInfo.name)")
                            .font(.headline)

                        // Test each text color against this background
                        ForEach(textColors, id: \.name) { textInfo in
                            TestColorCombination(
                                textColor: textInfo.color,
                                textName: textInfo.name,
                                backgroundColor: bgInfo.color
                            )
                        }
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(10)
                    .padding(.vertical, 5)
                }
            }
            .padding()
        }
    }
}

struct RequirementRow: View {
    let level: String
    let description: String

    var body: some View {
        HStack {
            Text(level)
                .bold()
                .frame(width: 50, alignment: .leading)

            Text(description)
        }
        .padding(.vertical, 2)
    }
}

struct TestColorCombination: View {
    let textColor: Color
    let textName: String
    let backgroundColor: Color

    var body: some View {
        // Calculate contrast ratio and compliance
        let compliance = textColor.wcagCompliance(with: backgroundColor)

        HStack {
            // Text sample
            Text("Aa")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(textColor)
                .padding(8)
                .frame(width: 60, height: 44)
                .background(backgroundColor)
                .cornerRadius(6)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color.gray, lineWidth: 0.5)
                )

            // Color name and contrast info
            VStack(alignment: .leading, spacing: 2) {
                Text("Text: \(textName)")
                    .font(.subheadline)
                    .bold()

                Text("Contrast: \(String(format: "%.2f", compliance.contrastRatio)):1")
                    .font(.caption)
            }

            Spacer()

            // WCAG compliance badges
            VStack(alignment: .trailing, spacing: 4) {
                HStack(spacing: 8) {
                    WCAGBadge(level: "AA", passes: compliance.passesAA)
                    WCAGBadge(level: "AAA", passes: compliance.passesAAA)
                }

                HStack(spacing: 8) {
                    WCAGBadge(level: "AA+", passes: compliance.passesAALarge)
                    WCAGBadge(level: "AAA+", passes: compliance.passesAAALarge)
                }
            }
        }
        .padding(8)
        .background(Color.white.opacity(0.7))
        .cornerRadius(8)
    }
}

struct WCAGBadge: View {
    let level: String
    let passes: Bool

    var body: some View {
        Text(level)
            .font(.system(size: 10, weight: .bold))
            .padding(.horizontal, 4)
            .padding(.vertical, 2)
            .background(passes ? Color.green : Color.red)
            .foregroundColor(.white)
            .cornerRadius(3)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
