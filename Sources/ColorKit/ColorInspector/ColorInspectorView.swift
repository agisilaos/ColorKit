//
//  ColorInspectorView.swift
//  ColorKit
//
//  Created by Agisilaos Tsaraboulidis on 12.03.25.
//
//  Description:
//  Provides a live color inspector view that displays color information in real-time.
//
//  Features:
//  - Displays HEX, RGB, HSL values for a selected color
//  - Shows contrast ratio with a background color
//  - Updates in real-time as colors change
//
//  License:
//  MIT License. See LICENSE file for details.
//

import SwiftUI
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

/// A view that displays detailed information about a color in real-time
public struct ColorInspectorView: View {
    private let color: Color
    private let backgroundColor: Color
    private let showContrastInfo: Bool

    /// Creates a new color inspector view
    /// - Parameters:
    ///   - color: The color to inspect
    ///   - backgroundColor: The background color (for contrast calculations)
    ///   - showContrastInfo: Whether to show contrast information
    public init(color: Color, backgroundColor: Color = .white, showContrastInfo: Bool = true) {
        self.color = color
        self.backgroundColor = backgroundColor
        self.showContrastInfo = showContrastInfo
    }

    public var body: some View {
        let presentation = self.presentation

        VStack(alignment: .leading, spacing: 12) {
            // Color preview
            HStack(spacing: 16) {
                RoundedRectangle(cornerRadius: 8)
                    .fill(color)
                    .frame(width: 60, height: 60)
                    .shadow(radius: 2)

                VStack(alignment: .leading) {
                    Text("Color Inspector")
                        .font(.headline)

                    Text(presentation.hexValue ?? "#??????")
                        .font(.system(.body, design: .monospaced))
                        .applyTextSelection()
                }
            }

            Divider()

            // RGB values
            VStack(alignment: .leading, spacing: 4) {
                Text("RGB")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Text(presentation.rgbText)
                    .font(.system(.body, design: .monospaced))
                    .applyTextSelection()
            }

            // HSL values
            VStack(alignment: .leading, spacing: 4) {
                Text("HSL")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Text(presentation.hslText)
                    .font(.system(.body, design: .monospaced))
                    .applyTextSelection()
            }

            // Contrast information
            if presentation.contrast != .hidden {
                Divider()

                VStack(alignment: .leading, spacing: 4) {
                    Text("Contrast")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    HStack {
                        Text(presentation.contrast.ratioText)
                            .font(.system(.body, design: .monospaced))
                            .applyTextSelection()

                        Spacer()

                        // WCAG compliance indicators
                        if let contrastRatio = presentation.contrast.ratio {
                            HStack(spacing: 4) {
                                WCAGComplianceBadge(level: "AA", isLargeText: true, passes: contrastRatio >= 3.0)
                                WCAGComplianceBadge(level: "AA", isLargeText: false, passes: contrastRatio >= 4.5)
                                WCAGComplianceBadge(level: "AAA", isLargeText: true, passes: contrastRatio >= 4.5)
                                WCAGComplianceBadge(level: "AAA", isLargeText: false, passes: contrastRatio >= 7.0)
                            }
                        }
                    }
                }
            }
        }
        .padding()
        .background(backgroundColorView)
        .cornerRadius(12)
        .shadow(radius: 2)
    }

    var presentation: ColorInspectorPresentation {
        ColorInspectorPresentation(color: color, backgroundColor: backgroundColor, showContrastInfo: showContrastInfo)
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
}

/// A small badge showing WCAG compliance status
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

// Extension to handle text selection availability
extension View {
    @ViewBuilder
    func applyTextSelection() -> some View {
        if #available(iOS 15.0, macOS 12.0, *) {
            self.textSelection(.enabled)
        } else {
            self
        }
    }
}

/// A preview provider for the ColorInspectorView
#Preview {
    VStack {
        ColorInspectorView(color: .blue).padding()
        ColorInspectorView(color: .red, backgroundColor: .black).padding()
    }
}
