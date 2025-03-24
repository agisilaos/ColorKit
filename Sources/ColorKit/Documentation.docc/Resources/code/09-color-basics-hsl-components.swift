//
//  09-color-basics-hsl-components.swift
//  ColorKit
//
//  Created for the ColorBasics tutorial.
//
//  Description:
//  Demonstrates how to work with HSL color components in ColorKit,
//  providing interactive controls to understand and manipulate colors 
//  in the HSL color space.
//
//  License:
//  MIT License. See LICENSE file for details.
//

import SwiftUI

struct ContentView: View {
    @State private var hue: Double = 0.583 // 210/360
    @State private var saturation: Double = 0.8
    @State private var lightness: Double = 0.5
    @State private var alpha: Double = 1.0

    // Derived color from HSL components
    private var currentColor: Color {
        Color(hue: CGFloat(hue), saturation: CGFloat(saturation), lightness: CGFloat(lightness))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 25) {
                Text("HSL Color Components")
                    .font(.title)
                    .padding(.top)

                // Color Preview
                VStack(spacing: 15) {
                    Text("Color Preview")
                        .font(.headline)

                    RoundedRectangle(cornerRadius: 10)
                        .fill(currentColor.opacity(alpha))
                        .frame(height: 120)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.gray, lineWidth: 0.5)
                        )

                    // HSL Values
                    VStack(alignment: .leading, spacing: 4) {
                        Text("HSL(\(Int(hue * 360)), \(Int(saturation * 100))%, \(Int(lightness * 100))%)")
                            .font(.system(.body, design: .monospaced))

                        if alpha < 1.0 {
                            Text("Alpha: \(Int(alpha * 100))%")
                                .font(.system(.body, design: .monospaced))
                        }
                    }
                    .padding(8)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(6)
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)

                // HSL Controls
                VStack(alignment: .leading, spacing: 20) {
                    Text("HSL Controls")
                        .font(.headline)

                    // Hue Control
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Hue: \(Int(hue * 360))°")
                            .font(.subheadline)

                        // Hue slider with color gradient background
                        HueSlider(hue: $hue)
                            .frame(height: 30)
                            .cornerRadius(5)
                    }

                    // Saturation Control
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Saturation: \(Int(saturation * 100))%")
                            .font(.subheadline)

                        // Saturation slider with gradient from gray to full color
                        SaturationSlider(hue: hue, lightness: lightness, saturation: $saturation)
                            .frame(height: 30)
                            .cornerRadius(5)
                    }

                    // Lightness Control
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Lightness: \(Int(lightness * 100))%")
                            .font(.subheadline)

                        // Lightness slider with gradient from black to white
                        LightnessSlider(hue: hue, saturation: saturation, lightness: $lightness)
                            .frame(height: 30)
                            .cornerRadius(5)
                    }

                    // Alpha Control
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Alpha: \(Int(alpha * 100))%")
                            .font(.subheadline)

                        // Alpha slider with checkerboard background
                        AlphaSlider(color: currentColor, alpha: $alpha)
                            .frame(height: 30)
                            .cornerRadius(5)
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)

                // Color Variations
                VStack(alignment: .leading, spacing: 15) {
                    Text("HSL Color Variations")
                        .font(.headline)

                    // Hue Variations
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Hue Variations")
                            .font(.subheadline)

                        HStack(spacing: 0) {
                            ForEach(0..<6) { i in
                                let variantHue = (hue + Double(i) * (1.0 / 6.0)).truncatingRemainder(dividingBy: 1.0)
                                Rectangle()
                                    .fill(Color(hue: CGFloat(variantHue), saturation: CGFloat(saturation), lightness: CGFloat(lightness)))
                                    .frame(maxWidth: .infinity, maxHeight: 40)
                            }
                        }
                        .cornerRadius(5)
                    }

                    // Saturation Variations
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Saturation Variations")
                            .font(.subheadline)

                        HStack(spacing: 0) {
                            ForEach(0..<5) { i in
                                let variantSaturation = Double(i) * 0.25
                                Rectangle()
                                    .fill(Color(hue: CGFloat(hue), saturation: CGFloat(variantSaturation), lightness: CGFloat(lightness)))
                                    .frame(maxWidth: .infinity, maxHeight: 40)
                            }
                        }
                        .cornerRadius(5)
                    }

                    // Lightness Variations
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Lightness Variations")
                            .font(.subheadline)

                        HStack(spacing: 0) {
                            ForEach(0..<5) { i in
                                let variantLightness = Double(i) * 0.25
                                Rectangle()
                                    .fill(Color(hue: CGFloat(hue), saturation: CGFloat(saturation), lightness: CGFloat(variantLightness)))
                                    .frame(maxWidth: .infinity, maxHeight: 40)
                            }
                        }
                        .cornerRadius(5)
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)

                // Code Example
                VStack(alignment: .leading, spacing: 15) {
                    Text("Code Example")
                        .font(.headline)

                    Text("""
                    // Create a color using HSL values
                    let color = Color(
                        hue: \(String(format: "%.2f", hue)),       // 0-1 (normalized)
                        saturation: \(String(format: "%.2f", saturation)),  // 0-1
                        lightness: \(String(format: "%.2f", lightness))    // 0-1
                    )

                    // Extract HSL components from a color
                    if let hslComponents = myColor.hslComponents() {
                        let hue = hslComponents.hue        // 0-1
                        let saturation = hslComponents.saturation  // 0-1
                        let lightness = hslComponents.lightness    // 0-1
                    }
                    """)
                    .font(.system(.body, design: .monospaced))
                    .padding(10)
                    .background(Color.black.opacity(0.05))
                    .cornerRadius(6)
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)
            }
            .padding()
        }
    }
}

struct HueSlider: View {
    @Binding var hue: Double

    var body: some View {
        ZStack(alignment: .leading) {
            // Hue gradient background
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(hue: 0, saturation: 1, lightness: 0.5),
                    Color(hue: 1.0 / 6.0, saturation: 1, lightness: 0.5),
                    Color(hue: 2.0 / 6.0, saturation: 1, lightness: 0.5),
                    Color(hue: 3.0 / 6.0, saturation: 1, lightness: 0.5),
                    Color(hue: 4.0 / 6.0, saturation: 1, lightness: 0.5),
                    Color(hue: 5.0 / 6.0, saturation: 1, lightness: 0.5),
                    Color(hue: 1, saturation: 1, lightness: 0.5)
                ]),
                startPoint: .leading,
                endPoint: .trailing
            )

            // Slider
            Slider(value: $hue, in: 0...1, step: 0.001)
                .padding(.horizontal, 2)
        }
    }
}

struct SaturationSlider: View {
    let hue: Double
    let lightness: Double
    @Binding var saturation: Double

    var body: some View {
        ZStack(alignment: .leading) {
            // Saturation gradient background
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(hue: CGFloat(hue), saturation: 0, lightness: CGFloat(lightness)),
                    Color(hue: CGFloat(hue), saturation: 1, lightness: CGFloat(lightness))
                ]),
                startPoint: .leading,
                endPoint: .trailing
            )

            // Slider
            Slider(value: $saturation, in: 0...1, step: 0.001)
                .padding(.horizontal, 2)
        }
    }
}

struct LightnessSlider: View {
    let hue: Double
    let saturation: Double
    @Binding var lightness: Double

    var body: some View {
        ZStack(alignment: .leading) {
            // Lightness gradient background
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.black,
                    Color(hue: CGFloat(hue), saturation: CGFloat(saturation), lightness: 0.5),
                    Color.white
                ]),
                startPoint: .leading,
                endPoint: .trailing
            )

            // Slider
            Slider(value: $lightness, in: 0...1, step: 0.001)
                .padding(.horizontal, 2)
        }
    }
}

struct AlphaSlider: View {
    let color: Color
    @Binding var alpha: Double

    var body: some View {
        ZStack(alignment: .leading) {
            // Checkerboard background for transparency
            CheckerboardBackground()

            // Alpha gradient overlay
            LinearGradient(
                gradient: Gradient(colors: [
                    color.opacity(0),
                    color.opacity(1)
                ]),
                startPoint: .leading,
                endPoint: .trailing
            )

            // Slider
            Slider(value: $alpha, in: 0...1, step: 0.001)
                .padding(.horizontal, 2)
        }
    }
}

struct CheckerboardBackground: View {
    let cellSize: CGFloat = 8

    var body: some View {
        Canvas { context, size in
            let columnCount = Int(size.width / cellSize) + 1
            let rowCount = Int(size.height / cellSize) + 1

            for row in 0..<rowCount {
                for column in 0..<columnCount {
                    let isEvenCell = (row + column) % 2 == 0
                    let rect = CGRect(
                        x: CGFloat(column) * cellSize,
                        y: CGFloat(row) * cellSize,
                        width: cellSize,
                        height: cellSize
                    )

                    if isEvenCell {
                        context.fill(Path(rect), with: .color(.white))
                    } else {
                        context.fill(Path(rect), with: .color(.gray.opacity(0.2)))
                    }
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
