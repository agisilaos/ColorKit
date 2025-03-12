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
    
    @State private var hexValue: String = ""
    @State private var rgbValues: (r: Int, g: Int, b: Int) = (0, 0, 0)
    @State private var hslValues: (h: CGFloat, s: CGFloat, l: CGFloat) = (0, 0, 0)
    @State private var contrastRatio: Double = 0
    
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
                    
                    Text(hexValue)
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
                
                Text("R: \(rgbValues.r), G: \(rgbValues.g), B: \(rgbValues.b)")
                    .font(.system(.body, design: .monospaced))
                    .applyTextSelection()
            }
            
            // HSL values
            VStack(alignment: .leading, spacing: 4) {
                Text("HSL")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text("H: \(Int(hslValues.h * 360))°, S: \(Int(hslValues.s * 100))%, L: \(Int(hslValues.l * 100))%")
                    .font(.system(.body, design: .monospaced))
                    .applyTextSelection()
            }
            
            // Contrast information
            if showContrastInfo {
                Divider()
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Contrast")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    HStack {
                        Text("Ratio: \(String(format: "%.2f", contrastRatio))")
                            .font(.system(.body, design: .monospaced))
                            .applyTextSelection()
                        
                        Spacer()
                        
                        // WCAG compliance indicators
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
        .padding()
        .background(backgroundColorView)
        .cornerRadius(12)
        .shadow(radius: 2)
        .onAppear {
            updateColorInfo()
        }
        .onChange(of: color) { _ in
            updateColorInfo()
        }
        .onChange(of: backgroundColor) { _ in
            if showContrastInfo {
                updateContrastInfo()
            }
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
    
    private func updateColorInfo() {
        // Update HEX value
        hexValue = color.hexValue() ?? "#??????"
        
        // Update RGB values
        if let components = color.cgColor?.components, components.count >= 3 {
            rgbValues = (
                Int(components[0] * 255),
                Int(components[1] * 255),
                Int(components[2] * 255)
            )
        }
        
        // Update HSL values
        if let hsl = color.hslComponents() {
            hslValues = (hsl.hue, hsl.saturation, hsl.lightness)
        }
        
        // Update contrast info if needed
        if showContrastInfo {
            updateContrastInfo()
        }
    }
    
    private func updateContrastInfo() {
        // Calculate contrast ratio manually if wcagContrastRatio is not available
        if let components1 = color.cgColor?.components, components1.count >= 3,
           let components2 = backgroundColor.cgColor?.components, components2.count >= 3 {
            
            // Calculate luminance for the first color
            let r1 = components1[0] <= 0.03928 ? components1[0] / 12.92 : pow((components1[0] + 0.055) / 1.055, 2.4)
            let g1 = components1[1] <= 0.03928 ? components1[1] / 12.92 : pow((components1[1] + 0.055) / 1.055, 2.4)
            let b1 = components1[2] <= 0.03928 ? components1[2] / 12.92 : pow((components1[2] + 0.055) / 1.055, 2.4)
            let luminance1 = 0.2126 * r1 + 0.7152 * g1 + 0.0722 * b1
            
            // Calculate luminance for the second color
            let r2 = components2[0] <= 0.03928 ? components2[0] / 12.92 : pow((components2[0] + 0.055) / 1.055, 2.4)
            let g2 = components2[1] <= 0.03928 ? components2[1] / 12.92 : pow((components2[1] + 0.055) / 1.055, 2.4)
            let b2 = components2[2] <= 0.03928 ? components2[2] / 12.92 : pow((components2[2] + 0.055) / 1.055, 2.4)
            let luminance2 = 0.2126 * r2 + 0.7152 * g2 + 0.0722 * b2
            
            // Calculate contrast ratio
            let lighter = max(luminance1, luminance2)
            let darker = min(luminance1, luminance2)
            contrastRatio = (lighter + 0.05) / (darker + 0.05)
        }
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
struct ColorInspectorView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            ColorInspectorView(color: .blue)
                .padding()
            
            ColorInspectorView(color: .red, backgroundColor: .black)
                .padding()
        }
        .previewLayout(.sizeThatFits)
    }
} 