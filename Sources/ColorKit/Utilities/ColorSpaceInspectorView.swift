//
//  ColorSpaceInspectorView.swift
//  ColorKit
//
//  Created by Agisilaos Tsaraboulidis on 25.03.25.
//
//  Description:
//  A view that displays detailed color information in multiple color spaces.
//
//  Features:
//  - Displays color components in RGB, HSL, HSB, CMYK, LAB, and XYZ color spaces
//  - Provides a preview of the color in a color picker
//  - Allows for easy color component inspection
//
//  License:
//  MIT License. See LICENSE file for details.

import SwiftUI
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

/// A view that displays detailed color information in multiple color spaces
public struct ColorSpaceInspectorView: View {
    private let color: Color
    private let components: ColorComponents

    public init(color: Color) {
        self.color = color
        self.components = color.colorSpaceComponents()
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            colorPreview
            Divider()
            colorComponentsScrollView
        }
        .padding()
        .background(backgroundColorView)
        .cornerRadius(12)
        .shadow(radius: 2)
    }

    private var colorPreview: some View {
        HStack(spacing: 16) {
            RoundedRectangle(cornerRadius: 8)
                .fill(color)
                .frame(width: 60, height: 60)
                .shadow(radius: 2)

            VStack(alignment: .leading) {
                Text("Color Space Inspector")
                    .font(.headline)

                if let hex = color.hexValue() {
                    Text(hex)
                        .font(.system(.body, design: .monospaced))
                        .applyTextSelection()
                }
            }
        }
    }

    private var colorComponentsScrollView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                ColorSpaceSection(title: "RGB", values: rgbValues)
                ColorSpaceSection(title: "HSL", values: hslValues)
                ColorSpaceSection(title: "HSB", values: hsbValues)
                ColorSpaceSection(title: "CMYK", values: cmykValues)
                ColorSpaceSection(title: "LAB", values: labValues)
                ColorSpaceSection(title: "XYZ", values: xyzValues)
            }
            .padding()
        }
    }

    private var rgbValues: [(String, String)] {
        [
            ("R", String(format: "%.0f", components.rgb.red * 255)),
            ("G", String(format: "%.0f", components.rgb.green * 255)),
            ("B", String(format: "%.0f", components.rgb.blue * 255)),
            ("A", String(format: "%.2f", components.rgb.alpha))
        ]
    }

    private var hslValues: [(String, String)] {
        [
            ("H", String(format: "%.0f°", components.hsl.hue * 360)),
            ("S", String(format: "%.0f%%", components.hsl.saturation * 100)),
            ("L", String(format: "%.0f%%", components.hsl.lightness * 100))
        ]
    }

    private var hsbValues: [(String, String)] {
        [
            ("H", String(format: "%.0f°", components.hsb.hue * 360)),
            ("S", String(format: "%.0f%%", components.hsb.saturation * 100)),
            ("B", String(format: "%.0f%%", components.hsb.brightness * 100))
        ]
    }

    private var cmykValues: [(String, String)] {
        [
            ("C", String(format: "%.0f%%", components.cmyk.cyan * 100)),
            ("M", String(format: "%.0f%%", components.cmyk.magenta * 100)),
            ("Y", String(format: "%.0f%%", components.cmyk.yellow * 100)),
            ("K", String(format: "%.0f%%", components.cmyk.key * 100))
        ]
    }

    private var labValues: [(String, String)] {
        [
            ("L", String(format: "%.1f", components.lab.l)),
            ("a", String(format: "%.1f", components.lab.a)),
            ("b", String(format: "%.1f", components.lab.b))
        ]
    }

    private var xyzValues: [(String, String)] {
        [
            ("X", String(format: "%.1f", components.xyz.x)),
            ("Y", String(format: "%.1f", components.xyz.y)),
            ("Z", String(format: "%.1f", components.xyz.z))
        ]
    }
}

    private var backgroundColorView: some View {
        #if canImport(UIKit)
        return Color(UIColor.systemBackground)
        #elseif canImport(AppKit)
        return Color(NSColor.windowBackgroundColor)
        #else
        return Color.white
        #endif
    }

private struct ColorSpaceSection: View {
    let title: String
    let values: [(String, String)]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)

            VStack(alignment: .leading, spacing: 4) {
                ForEach(values, id: \.0) { value in
                    HStack {
                        Text(value.0)
                            .font(.system(.body, design: .monospaced))
                            .frame(width: 20, alignment: .leading)

                        Text(value.1)
                            .font(.system(.body, design: .monospaced))
                            .applyTextSelection()
                    }
                }
            }
        }
    }
}
