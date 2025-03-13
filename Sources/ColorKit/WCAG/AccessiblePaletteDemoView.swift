//
//  AccessiblePaletteDemoView.swift
//  ColorKit
//
//  Created by Agisilaos Tsaraboulidis on 12.03.25.
//
//  Description:
//  A demo view that showcases the accessible palette generation feature.
//
//  Features:
//  - Interactive UI to generate and preview accessible color palettes
//  - Customizable WCAG level, palette size, and other options
//  - Live preview of generated themes with accessibility information
//
//  License:
//  MIT License. See LICENSE file for details.
//

import SwiftUI

/// A demo view that showcases the accessible palette generation feature
@available(iOS 14.0, macOS 11.0, *)
public struct AccessiblePaletteDemoView: View {
    @State private var seedColor: Color = .blue
    @State private var targetLevel: WCAGContrastLevel = .AA
    @State private var paletteSize: Int = 5
    @State private var includeBlackAndWhite: Bool = true
    
    // Store the generated palette and theme in state properties
    @State private var palette: [Color] = []
    @State private var theme: ColorTheme?
    @State private var isGenerating: Bool = false
    
    public init() {}
    
    public var body: some View {
        VStack(spacing: 20) {
            Text("Accessible Palette Generator")
                .font(.title)
                .fontWeight(.bold)
            
            // Color picker for seed color
            ColorPicker("Seed Color", selection: $seedColor)
                .padding(.horizontal)
            
            // WCAG level picker
            Picker("WCAG Level", selection: $targetLevel) {
                ForEach(WCAGContrastLevel.allCases) { level in
                    Text(level.rawValue).tag(level)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(.horizontal)
            
            // Palette size slider
            VStack(alignment: .leading) {
                Text("Palette Size: \(paletteSize)")
                Slider(value: Binding(
                    get: { Double(paletteSize) },
                    set: { paletteSize = max(2, min(10, Int($0))) }
                ), in: 2...10, step: 1)
            }
            .padding(.horizontal)
            
            // Include black and white toggle
            Toggle("Include Black & White", isOn: $includeBlackAndWhite)
                .padding(.horizontal)
            
            // Generate button
            Button(action: generatePaletteAndTheme) {
                HStack {
                    Text("Generate Palette")
                    if isGenerating {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                    }
                }
            }
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(8)
            .disabled(isGenerating)
            
            // Display the generated palette
            ScrollView {
                VStack(spacing: 10) {
                    Text("Generated Palette")
                        .font(.headline)
                    
                    if palette.isEmpty && !isGenerating {
                        Text("Tap 'Generate Palette' to create a palette")
                            .foregroundColor(.secondary)
                    } else if isGenerating {
                        ProgressView("Generating palette...")
                    } else {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 10) {
                            ForEach(0..<palette.count, id: \.self) { index in
                                let color = palette[index]
                                let contrastingColor = color.accessibleContrastingColor(for: targetLevel)
                                
                                VStack {
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(color)
                                        .frame(height: 100)
                                        .overlay(
                                            Text("Color \(index + 1)")
                                                .foregroundColor(contrastingColor)
                                        )
                                    
                                    // Display contrast ratios with other colors
                                    if index == 0 { // Only for the seed color
                                        VStack(alignment: .leading) {
                                            ForEach(1..<min(palette.count, 4), id: \.self) { otherIndex in
                                                let otherColor = palette[otherIndex]
                                                let ratio = color.wcagContrastRatio(with: otherColor)
                                                let passes = ratio >= targetLevel.minimumRatio
                                                
                                                HStack {
                                                    Circle()
                                                        .fill(otherColor)
                                                        .frame(width: 12, height: 12)
                                                    Text("Ratio: \(String(format: "%.1f", ratio))")
                                                        .font(.caption)
                                                        .foregroundColor(passes ? .green : .red)
                                                }
                                            }
                                        }
                                        .padding(.top, 4)
                                    }
                                }
                                .padding(8)
                                .background(Color.secondary.opacity(0.1))
                                .cornerRadius(10)
                            }
                        }
                        .padding()
                    }
                }
            }
            
            // Theme preview
            VStack(spacing: 10) {
                Text("Theme Preview")
                    .font(.headline)
                
                if let theme = theme {
                    HStack(spacing: 10) {
                        // Primary colors
                        VStack {
                            Text("Primary")
                                .font(.caption)
                            RoundedRectangle(cornerRadius: 4)
                                .fill(theme.primary.base)
                                .frame(width: 60, height: 60)
                                .overlay(
                                    Text("P")
                                        .foregroundColor(theme.primary.base.accessibleContrastingColor(for: targetLevel))
                                )
                        }
                        
                        // Secondary colors
                        VStack {
                            Text("Secondary")
                                .font(.caption)
                            RoundedRectangle(cornerRadius: 4)
                                .fill(theme.secondary.base)
                                .frame(width: 60, height: 60)
                                .overlay(
                                    Text("S")
                                        .foregroundColor(theme.secondary.base.accessibleContrastingColor(for: targetLevel))
                                )
                        }
                        
                        // Accent colors
                        VStack {
                            Text("Accent")
                                .font(.caption)
                            RoundedRectangle(cornerRadius: 4)
                                .fill(theme.accent.base)
                                .frame(width: 60, height: 60)
                                .overlay(
                                    Text("A")
                                        .foregroundColor(theme.accent.base.accessibleContrastingColor(for: targetLevel))
                                )
                        }
                    }
                    
                    // Background with text
                    RoundedRectangle(cornerRadius: 8)
                        .fill(theme.background.base)
                        .frame(height: 80)
                        .overlay(
                            VStack {
                                Text("Background with Text")
                                    .foregroundColor(theme.text.base)
                                
                                Button(action: {}) {
                                    Text("Primary Button")
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 8)
                                        .background(theme.primary.base)
                                        .foregroundColor(theme.primary.base.accessibleContrastingColor(for: targetLevel))
                                        .cornerRadius(4)
                                }
                            }
                        )
                } else if isGenerating {
                    ProgressView("Generating theme...")
                } else {
                    Text("Generate a palette to see the theme preview")
                        .foregroundColor(.secondary)
                }
            }
            .padding()
        }
        .padding()
        .onAppear {
            // Generate initial palette and theme when the view appears
            generatePaletteAndTheme()
        }
    }
    
    // Function to generate palette and theme on a background thread
    private func generatePaletteAndTheme() {
        isGenerating = true
        
        // Capture the values before passing to background thread
        let currentSeedColor = seedColor
        let currentTargetLevel = targetLevel
        let currentPaletteSize = paletteSize
        let currentIncludeBlackAndWhite = includeBlackAndWhite
        
        // Use a background thread for the generation
        DispatchQueue.global(qos: .userInitiated).async {
            // Generate the palette
            let newPalette = currentSeedColor.generateAccessiblePalette(
                targetLevel: currentTargetLevel,
                paletteSize: currentPaletteSize,
                includeBlackAndWhite: currentIncludeBlackAndWhite
            )
            
            // Generate the theme
            let newTheme = currentSeedColor.generateAccessibleTheme(
                name: "Generated Theme", 
                targetLevel: currentTargetLevel
            )
            
            // Update the UI on the main thread
            DispatchQueue.main.async {
                palette = newPalette
                theme = newTheme
                isGenerating = false
            }
        }
    }
} 