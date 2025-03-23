//
//  04-accessibility-palette.swift
//  ColorKit
//
//  Created for the AccessibilityGuide tutorial.
//
//  Description:
//  Shows how to use ColorKit to generate accessible color palettes
//  and themes based on seed colors.
//
//  License:
//  MIT License. See LICENSE file for details.
//

import SwiftUI
import ColorKit

struct ContentView: View {
    @State private var seedColor = Color.blue
    @State private var targetLevel: WCAGContrastLevel = .AA
    @State private var paletteSize = 5
    @State private var includeBlackAndWhite = true
    @State private var generatedPalette: [Color] = []
    @State private var generatedTheme: ColorTheme?
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("Accessible Color Palette Generator")
                    .font(.title)
                    .padding(.top)
                
                // Color Selection
                VStack(alignment: .leading, spacing: 10) {
                    Text("Seed Color")
                        .font(.headline)
                    
                    ColorPicker("Select Seed Color", selection: $seedColor)
                        .padding(.bottom, 5)
                    
                    // Parameter Configuration
                    VStack(alignment: .leading, spacing: 15) {
                        // WCAG Level Selection
                        VStack(alignment: .leading) {
                            Text("WCAG Compliance Level:")
                                .font(.headline)
                            
                            Picker("WCAG Level", selection: $targetLevel) {
                                ForEach(WCAGContrastLevel.allCases) { level in
                                    Text(level.rawValue).tag(level)
                                }
                            }
                            .pickerStyle(SegmentedPickerStyle())
                        }
                        
                        // Palette Size
                        VStack(alignment: .leading) {
                            Text("Palette Size: \(paletteSize)")
                                .font(.headline)
                            
                            Slider(value: Binding(
                                get: { Double(paletteSize) },
                                set: { paletteSize = Int($0) }
                            ), in: 3...10, step: 1)
                        }
                        
                        // Include Black and White
                        Toggle("Include Black and White", isOn: $includeBlackAndWhite)
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)
                
                // Generate Button
                Button(action: generatePaletteAndTheme) {
                    Text("Generate Accessible Palette")
                        .font(.headline)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding(.vertical)
                
                // Display Generated Palette
                if !generatedPalette.isEmpty {
                    VStack(alignment: .leading, spacing: 15) {
                        Text("Generated Palette")
                            .font(.headline)
                        
                        // Color Grid
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 60))], spacing: 10) {
                            ForEach(0..<generatedPalette.count, id: \.self) { index in
                                ColorSwatch(color: generatedPalette[index])
                            }
                        }
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(10)
                }
                
                // Display Generated Theme
                if let theme = generatedTheme {
                    VStack(alignment: .leading, spacing: 15) {
                        Text("Generated Theme")
                            .font(.headline)
                        
                        // Theme Preview
                        ThemePreview(theme: theme)
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(10)
                }
                
                // Usage Examples
                VStack(alignment: .leading, spacing: 15) {
                    Text("How to Use in Your Code")
                        .font(.headline)
                    
                    Text("Generate a palette:")
                        .font(.subheadline)
                    
                    Text("""
                    let palette = myColor.generateAccessiblePalette(
                        targetLevel: .AA,
                        paletteSize: 5,
                        includeBlackAndWhite: true
                    )
                    """)
                    .font(.system(.body, design: .monospaced))
                    .padding(10)
                    .background(Color.black.opacity(0.05))
                    .cornerRadius(5)
                    
                    Text("Generate a theme:")
                        .font(.subheadline)
                    
                    Text("""
                    let theme = myColor.generateAccessibleTheme(
                        name: "My Theme",
                        targetLevel: .AA
                    )
                    """)
                    .font(.system(.body, design: .monospaced))
                    .padding(10)
                    .background(Color.black.opacity(0.05))
                    .cornerRadius(5)
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)
            }
            .padding()
        }
    }
    
    private func generatePaletteAndTheme() {
        generatedPalette = seedColor.generateAccessiblePalette(
            targetLevel: targetLevel,
            paletteSize: paletteSize,
            includeBlackAndWhite: includeBlackAndWhite
        )
        
        generatedTheme = seedColor.generateAccessibleTheme(
            name: "Generated Theme",
            targetLevel: targetLevel
        )
    }
}

struct ColorSwatch: View {
    let color: Color
    
    var body: some View {
        VStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(color)
                .frame(height: 60)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray, lineWidth: 0.5)
                )
            
            if let hex = color.hexString {
                Text(hex)
                    .font(.caption)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
        }
    }
}

struct ThemePreview: View {
    let theme: ColorTheme
    
    var body: some View {
        VStack(spacing: 15) {
            // Header
            Text("Theme Preview")
                .font(.headline)
                .padding(8)
                .frame(maxWidth: .infinity)
                .background(theme.primary)
                .foregroundColor(theme.primary.accessibleContrastingColor())
                .cornerRadius(8)
            
            // Content
            VStack(alignment: .leading, spacing: 12) {
                Text("Primary Heading")
                    .font(.title3)
                    .foregroundColor(theme.primary)
                
                Text("Secondary Heading")
                    .font(.headline)
                    .foregroundColor(theme.secondary)
                
                Text("This is regular body text using the theme's text color.")
                    .foregroundColor(theme.text)
                
                Button(action: {}) {
                    Text("Accent Button")
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(theme.accent)
                        .foregroundColor(theme.accent.accessibleContrastingColor())
                        .cornerRadius(8)
                }
                .padding(.top, 8)
            }
            .padding()
            .background(theme.background)
            .cornerRadius(8)
            
            // Color Swatches
            HStack {
                ColorKey(name: "Primary", color: theme.primary)
                ColorKey(name: "Secondary", color: theme.secondary)
                ColorKey(name: "Accent", color: theme.accent)
                ColorKey(name: "Background", color: theme.background)
                ColorKey(name: "Text", color: theme.text)
            }
        }
    }
}

struct ColorKey: View {
    let name: String
    let color: Color
    
    var body: some View {
        VStack {
            Circle()
                .fill(color)
                .frame(width: 30, height: 30)
                .overlay(
                    Circle()
                        .stroke(Color.gray, lineWidth: 0.5)
                )
            
            Text(name)
                .font(.caption)
                .lineLimit(1)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
} 