//
//  ColorSpacePreview.swift
//  ColorKit
//
//  Created by Agisilaos Tsaraboulidis on 20.03.25.
//
//  Description:
//  Interactive preview for exploring color spaces and conversions.
//
//  License:
//  MIT License. See LICENSE file for details.
//

import SwiftUI

/// A preview view for exploring color spaces and conversions
public struct ColorSpacePreview: View {
    // MARK: - State

    @State private var selectedColor = Color.blue
    @State private var showColorPicker = false
    @State private var selectedColorSpace = ColorSpace.rgb
    @State private var copiedValue: String?

    // MARK: - Properties

    private let colorSpaces = ColorSpace.allCases

    public var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Color Preview Section
                colorPreviewSection

                // Color Space Selection
                colorSpaceSelection

                // Color Components
                colorComponentsSection

                // Color Values
                colorValuesSection
            }
            .padding()
        }
        .navigationTitle("Color Spaces")
        .sheet(isPresented: $showColorPicker) {
            ColorPicker("Select Color", selection: $selectedColor)
                .padding()
        }
    }

    // MARK: - View Components
    private var colorPreviewSection: some View {
        VStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 12)
                .fill(selectedColor)
                .frame(height: 100)
                .shadow(radius: 2)
                .onTapGesture {
                    showColorPicker = true
                }

            Text("Tap to change color")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    private var colorSpaceSelection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Color Space")
                .font(.headline)

            Picker("Color Space", selection: $selectedColorSpace) {
                ForEach(colorSpaces, id: \.self) { space in
                    Text(space.name).tag(space)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
        }
    }

    private var colorComponentsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Components")
                .font(.headline)

            let components = selectedColor.colorSpaceComponents()

            switch selectedColorSpace {
            case .rgb:
                ColorComponentRow(label: "Red", value: components.rgb.red)
                ColorComponentRow(label: "Green", value: components.rgb.green)
                ColorComponentRow(label: "Blue", value: components.rgb.blue)
            case .hsl:
                ColorComponentRow(label: "Hue", value: components.hsl.hue, suffix: "°")
                ColorComponentRow(label: "Saturation", value: components.hsl.saturation, isPercentage: true)
                ColorComponentRow(label: "Lightness", value: components.hsl.lightness, isPercentage: true)
            case .lab:
                ColorComponentRow(label: "L*", value: components.lab.l)
                ColorComponentRow(label: "a*", value: components.lab.a)
                ColorComponentRow(label: "b*", value: components.lab.b)
            case .xyz:
                ColorComponentRow(label: "X", value: components.xyz.x)
                ColorComponentRow(label: "Y", value: components.xyz.y)
                ColorComponentRow(label: "Z", value: components.xyz.z)
            }
        }
    }

    private var colorValuesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Color Values")
                .font(.headline)

            if let hex = selectedColor.hexValue() {
                CopyableValueRow(label: "HEX", value: hex)
            }

            let components = selectedColor.colorSpaceComponents()
            CopyableValueRow(label: "RGB", value: String(format: "R: %.2f, G: %.2f, B: %.2f", components.rgb.red, components.rgb.green, components.rgb.blue))
            CopyableValueRow(label: "HSL", value: String(format: "H: %.0f°, S: %.0f%%, L: %.0f%%", components.hsl.hue * 360, components.hsl.saturation * 100, components.hsl.lightness * 100))
            CopyableValueRow(label: "LAB", value: String(format: "L: %.2f, a: %.2f, b: %.2f", components.lab.l, components.lab.a, components.lab.b))
            CopyableValueRow(label: "XYZ", value: String(format: "X: %.2f, Y: %.2f, Z: %.2f", components.xyz.x, components.xyz.y, components.xyz.z))
        }
    }
}

// MARK: - Supporting Types

private enum ColorSpace: String, CaseIterable {
    case rgb = "RGB"
    case hsl = "HSL"
    case lab = "LAB"
    case xyz = "XYZ"

    var name: String { rawValue }
}

// MARK: - Supporting Views

private struct ColorComponentRow: View {
    let label: String
    let value: Double
    var suffix: String = ""
    var isPercentage: Bool = false

    var body: some View {
        HStack {
            Text(label)
                .frame(width: 100, alignment: .leading)

            Slider(value: .constant(value), in: 0...1)
                .disabled(true)

            Text(formattedValue)
                .font(.system(.body, design: .monospaced))
                .frame(width: 60, alignment: .trailing)
        }
    }

    private var formattedValue: String {
        if isPercentage {
            return String(format: "%.0f%%", value * 100)
        }
        return String(format: "%.2f%@", value, suffix)
    }
}

@available(iOS 14.0, macOS 11.0, *)
private struct CopyableValueRow: View {
    let label: String
    let value: String
    @State private var isCopied = false

    var body: some View {
        HStack {
            Text(label)
                .frame(width: 60, alignment: .leading)

            Text(value)
                .font(.system(.body, design: .monospaced))

            Spacer()

            Button(action: copyValue) {
                Image(systemName: isCopied ? "checkmark.circle.fill" : "doc.on.doc")
                    .foregroundColor(isCopied ? .green : .accentColor)
            }
            .buttonStyle(.borderless)
        }
        .padding(8)
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(8)
    }

    private func copyValue() {
#if os(iOS)
        UIPasteboard.general.string = value
#elseif os(macOS)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(value, forType: .string)
#endif

        withAnimation {
            isCopied = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation {
                isCopied = false
            }
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationView {
        ColorSpacePreview()
    }
}
