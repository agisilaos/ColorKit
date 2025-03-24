//
//  10-accessibility-custom-enhance.swift
//  ColorKit
//
//  Created for the AccessibilityGuide tutorial.
//
//  Description:
//  Shows how to customize the color enhancement process using different
//  strategies and parameters to fine-tune the accessibility adjustments.
//
//  License:
//  MIT License. See LICENSE file for details.
//

import SwiftUI

// Basic mock types to match ColorKit's API for the documentation sample
enum EnhancementStrategyDemo: String, CaseIterable {
    case preserveHue = "preserveHue"
    case preserveSaturation = "preserveSaturation"
    case preserveLightness = "preserveLightness"
    case minimizeShift = "minimizeShift"
    case smart = "smart"
}

enum WCAGContrastLevelDemo: String, CaseIterable, Identifiable {
    case A
    case AA
    case AAA

    var id: String { self.rawValue }

    var minimumRatio: Double {
        switch self {
        case .A: return 3.0
        case .AA: return 4.5
        case .AAA: return 7.0
        }
    }
}

struct ContentView: View {
    // Original brand colors
    private let originalBackgroundColor = Color(red: 0.98, green: 0.98, blue: 1.0)
    private let originalTextColor = Color(red: 0.4, green: 0.4, blue: 0.8)

    // Enhancement configuration
    @State private var selectedStrategy: EnhancementStrategyDemo = .preserveHue
    @State private var targetLevel: WCAGContrastLevelDemo = .AA
    @State private var preservePerceivedSaturation = true
    @State private var maxColorShift = 0.5

    // In a real app, we'd use ColorKit's enhancer
    private var enhancedColor: Color {
        // Demo version - simulate enhancement based on strategy
        switch selectedStrategy {
        case .preserveHue:
            return Color(red: 0.2, green: 0.2, blue: 0.7) // Darker blue
        case .preserveSaturation:
            return Color(red: 0.2, green: 0.2, blue: 0.9) // More saturated blue
        case .preserveLightness:
            return Color(red: 0.1, green: 0.1, blue: 0.9) // Different hue
        case .minimizeShift:
            return Color(red: 0.35, green: 0.35, blue: 0.75) // Slightly adjusted
        case .smart:
            return Color(red: 0.2, green: 0.2, blue: 0.8) // Smart adjusted
        }
    }

    // Simulated contrast ratio
    private var contrastRatio: Double {
        // Demo value - in real code we would use ColorKit's wcagContrastRatio method
        let ratio = 7.2
        return ratio
    }

    // Simulated color distance
    private var colorDistance: Double {
        // Demo value - in real code we would use ColorKit's colorDistance method
        let distance = 0.2
        return distance
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("Custom Color Enhancement")
                    .font(.largeTitle)
                    .padding(.top)

                // Color preview
                VStack(spacing: 25) {
                    HStack(spacing: 20) {
                        // Original color
                        VStack {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(originalTextColor)
                                .frame(width: 100, height: 100)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.gray, lineWidth: 0.5)
                                )

                            Text("Original")
                                .font(.headline)

                            let originalRatio = originalTextColor.wcagContrastRatio(with: originalBackgroundColor)
                            Text("\(String(format: "%.2f", originalRatio)):1")
                                .font(.caption)
                                .foregroundColor(originalRatio >= 4.5 ? .green : .red)
                        }

                        Image(systemName: "arrow.right")
                            .font(.title)
                            .foregroundColor(.gray)

                        // Enhanced color
                        VStack {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(enhancedColor)
                                .frame(width: 100, height: 100)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.gray, lineWidth: 0.5)
                                )

                            Text("Enhanced")
                                .font(.headline)

                            Text("\(String(format: "%.2f", contrastRatio)):1")
                                .font(.caption)
                                .foregroundColor(.green)
                        }
                    }

                    // Text preview
                    HStack(spacing: 20) {
                        // Original
                        VStack {
                            Text("Aa Bb Cc")
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(originalTextColor)
                                .padding()
                                .frame(width: 150, height: 80)
                                .background(originalBackgroundColor)
                                .cornerRadius(8)

                            Text("Original")
                                .font(.caption)
                        }

                        // Enhanced
                        VStack {
                            Text("Aa Bb Cc")
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(enhancedColor)
                                .padding()
                                .frame(width: 150, height: 80)
                                .background(originalBackgroundColor)
                                .cornerRadius(8)

                            Text("Enhanced")
                                .font(.caption)
                        }
                    }
                }
                .padding()
                .background(Color.white)
                .cornerRadius(12)
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)

                // Configuration options
                VStack(alignment: .leading, spacing: 16) {
                    Text("Enhancement Configuration")
                        .font(.headline)

                    // Strategy selection
                    VStack(alignment: .leading) {
                        Text("Enhancement Strategy")
                            .font(.subheadline)

                        Picker("Strategy", selection: $selectedStrategy) {
                            Text("Preserve Hue").tag(EnhancementStrategyDemo.preserveHue)
                            Text("Preserve Saturation").tag(EnhancementStrategyDemo.preserveSaturation)
                            Text("Preserve Lightness").tag(EnhancementStrategyDemo.preserveLightness)
                            Text("Minimize Shift").tag(EnhancementStrategyDemo.minimizeShift)
                            Text("Smart Enhance").tag(EnhancementStrategyDemo.smart)
                        }
                        .pickerStyle(SegmentedPickerStyle())
                    }

                    // WCAG level
                    VStack(alignment: .leading) {
                        Text("Target Accessibility Level")
                            .font(.subheadline)

                        Picker("WCAG Level", selection: $targetLevel) {
                            ForEach([WCAGContrastLevelDemo.A, .AA, .AAA]) { level in
                                Text("\(level.rawValue) (\(String(format: "%.1f", level.minimumRatio)):1)")
                                    .tag(level)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                    }

                    // Additional options
                    Toggle("Preserve Perceived Saturation", isOn: $preservePerceivedSaturation)
                        .font(.subheadline)

                    // Max color shift slider
                    VStack(alignment: .leading) {
                        HStack {
                            Text("Maximum Color Shift")
                                .font(.subheadline)

                            Spacer()

                            Text("\(Int(maxColorShift * 100))%")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        Slider(value: $maxColorShift, in: 0.1...1.0, step: 0.1)
                    }

                    // Results
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Results")
                            .font(.subheadline)
                            .bold()

                        HStack {
                            Text("Contrast Ratio:")
                            Spacer()
                            Text("\(String(format: "%.2f", contrastRatio)):1")
                                .foregroundColor(contrastRatio >= targetLevel.minimumRatio ? .green : .red)
                                .font(.callout)
                                .bold()
                        }

                        HStack {
                            Text("Color Distance:")
                            Spacer()
                            Text("\(String(format: "%.2f", colorDistance * 100))%")
                                .foregroundColor(colorDistance < 0.3 ? .green : (colorDistance < 0.5 ? .orange : .red))
                                .font(.callout)
                                .bold()
                        }

                        HStack {
                            Text("WCAG Level Compliance:")
                            Spacer()
                            HStack(spacing: 4) {
                                if contrastRatio >= WCAGContrastLevelDemo.A.minimumRatio {
                                    Text("A")
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(Color.green)
                                        .foregroundColor(.white)
                                        .cornerRadius(4)
                                }

                                if contrastRatio >= WCAGContrastLevelDemo.AA.minimumRatio {
                                    Text("AA")
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(Color.green)
                                        .foregroundColor(.white)
                                        .cornerRadius(4)
                                }

                                if contrastRatio >= WCAGContrastLevelDemo.AAA.minimumRatio {
                                    Text("AAA")
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(Color.green)
                                        .foregroundColor(.white)
                                        .cornerRadius(4)
                                }
                            }
                        }
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                }
                .padding()
                .background(Color.white)
                .cornerRadius(12)
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)

                // Code example
                VStack(alignment: .leading, spacing: 10) {
                    Text("Implementation Code")
                        .font(.headline)

                    Text("""
                    // Create custom configuration
                    let config = AccessibilityEnhancerConfig(
                        strategy: .\(selectedStrategy.rawValue),
                        preservePerceivedSaturation: \(preservePerceivedSaturation),
                        maxColorShift: \(String(format: "%.1f", maxColorShift))
                    )

                    // Create enhancer with configuration
                    let enhancer = AccessibilityEnhancer(config: config)

                    // Enhance the color
                    let enhancedColor = enhancer.enhanceColor(
                        originalColor,
                        background: backgroundColor,
                        targetLevel: .\(targetLevel.rawValue)
                    )
                    """)
                    .font(.system(.caption, design: .monospaced))
                    .padding()
                    .background(Color.black.opacity(0.05))
                    .cornerRadius(8)
                }
                .padding()
                .background(Color.white)
                .cornerRadius(12)
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)

                // Strategy explanation
                VStack(alignment: .leading, spacing: 12) {
                    Text("Strategy Explanation")
                        .font(.headline)

                    StrategyExplanationView(strategy: selectedStrategy)
                }
                .padding()
                .background(Color.white)
                .cornerRadius(12)
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
            }
            .padding()
        }
        .background(Color.gray.opacity(0.1))
    }
}

struct StrategyExplanationView: View {
    let strategy: EnhancementStrategyDemo

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Strategy icon and name
            HStack {
                Image(systemName: iconName)
                    .font(.title2)
                    .foregroundColor(.blue)
                    .frame(width: 30)

                Text(title)
                    .font(.title3)
                    .fontWeight(.semibold)
            }

            // Description
            Text(description)
                .font(.body)
                .foregroundColor(.secondary)
                .padding(.vertical, 4)

            // Best use cases
            VStack(alignment: .leading, spacing: 4) {
                Text("Best for:")
                    .font(.subheadline)
                    .fontWeight(.medium)

                ForEach(bestFor, id: \.self) { use in
                    HStack(alignment: .top, spacing: 6) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.caption)

                        Text(use)
                            .font(.subheadline)
                    }
                }
            }
            .padding(.vertical, 4)
        }
    }

    private var iconName: String {
        switch strategy {
        case .preserveHue:
            return "paintpalette"
        case .preserveSaturation:
            return "slider.horizontal.3"
        case .preserveLightness:
            return "sun.max"
        case .minimizeShift:
            return "arrow.left.and.right"
        case .smart:
            return "brain"
        }
    }

    private var title: String {
        switch strategy {
        case .preserveHue:
            return "Preserve Hue"
        case .preserveSaturation:
            return "Preserve Saturation"
        case .preserveLightness:
            return "Preserve Lightness"
        case .minimizeShift:
            return "Minimize Shift"
        case .smart:
            return "Smart Enhancement"
        }
    }

    private var description: String {
        switch strategy {
        case .preserveHue:
            return "Adjusts saturation and lightness to achieve the required contrast, but keeps the color's hue the same. This maintains brand color identity."
        case .preserveSaturation:
            return "Maintains the original saturation level while adjusting hue and lightness to meet contrast requirements."
        case .preserveLightness:
            return "Keeps the original lightness value of the color while modifying hue and saturation to achieve sufficient contrast."
        case .minimizeShift:
            return "Takes a holistic approach to minimize the perceptual distance between the original and enhanced colors, making the smallest possible changes."
        case .smart:
            return "Intelligently chooses the best strategy based on the specific color's properties and the background it's used against."
        }
    }

    private var bestFor: [String] {
        switch strategy {
        case .preserveHue:
            return [
                "Brand colors where hue is the key identifying characteristic",
                "Corporate identity systems with specific color palettes",
                "When color meaning must be preserved (e.g., red for error states)"
            ]
        case .preserveSaturation:
            return [
                "Vibrant UI designs where color vibrancy is important",
                "Maintaining the intensity of accent colors",
                "Interactive elements where color vividness indicates state"
            ]
        case .preserveLightness:
            return [
                "Color systems with carefully designed lightness hierarchies",
                "Maintaining visual hierarchy in interface elements",
                "Dark or light themes where lightness is the key differentiator"
            ]
        case .minimizeShift:
            return [
                "Staying as close as possible to the original design intent",
                "Subtle accessibility improvements with minimal visual change",
                "Situations where any color change should be imperceptible"
            ]
        case .smart:
            return [
                "General purpose enhancement that adapts to different colors",
                "Complex interfaces with varied color usage",
                "When you're unsure which strategy would work best"
            ]
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
