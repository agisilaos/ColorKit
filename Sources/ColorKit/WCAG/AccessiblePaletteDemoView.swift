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
    @State private var showingExportSheet = false
    @State private var exportingTheme = false
    
    // Store the generated palette and theme in state properties
    @State private var palette: [Color] = []
    @State private var theme: ColorTheme?
    @State private var isGenerating: Bool = false
    
    public init() {}
    
    public var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header
                Text("Accessible Palette Generator")
                    .font(.title)
                    .fontWeight(.bold)
                    .padding(.top)
                
                // Controls Section
                VStack(spacing: 16) {
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
                }
                .padding(.bottom)
                
                // Generated Palette Section
                VStack(spacing: 16) {
                    Text("Generated Palette")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    if palette.isEmpty && !isGenerating {
                        Text("Tap 'Generate Palette' to create a palette")
                            .foregroundColor(.secondary)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.secondary.opacity(0.1))
                            .cornerRadius(12)
                    } else if isGenerating {
                        ProgressView("Generating palette...")
                            .padding()
                    } else {
                        LazyVGrid(
                            columns: [
                                GridItem(.adaptive(minimum: 150, maximum: 200), spacing: 16)
                            ],
                            spacing: 16
                        ) {
                            ForEach(0..<palette.count, id: \.self) { index in
                                let color = palette[index]
                                let contrastingColor = color.accessibleContrastingColor(for: targetLevel)
                                
                                VStack(spacing: 8) {
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(color)
                                        .frame(height: 120)
                                        .overlay(
                                            Text("Color \(index + 1)")
                                                .font(.headline)
                                                .foregroundColor(contrastingColor)
                                        )
                                        .shadow(radius: 2)
                                    
                                    // Display contrast ratios with other colors
                                    if index == 0 { // Only for the seed color
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text("Contrast Ratios:")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                            
                                            ForEach(1..<min(palette.count, 4), id: \.self) { otherIndex in
                                                let otherColor = palette[otherIndex]
                                                let ratio = color.wcagContrastRatio(with: otherColor)
                                                let passes = ratio >= targetLevel.minimumRatio
                                                
                                                HStack {
                                                    Circle()
                                                        .fill(otherColor)
                                                        .frame(width: 16, height: 16)
                                                    Text("Color \(otherIndex + 1): \(String(format: "%.1f", ratio))")
                                                        .font(.caption)
                                                        .foregroundColor(passes ? .green : .red)
                                                }
                                            }
                                        }
                                        .padding(.top, 4)
                                    }
                                }
                                .padding(12)
                                .background(Color.secondary.opacity(0.1))
                                .cornerRadius(16)
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical)
                
                // Theme Preview Section
                if let theme = theme {
                    VStack(spacing: 16) {
                        Text("Theme Preview")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        HStack(spacing: 16) {
                            // Primary colors
                            VStack {
                                Text("Primary")
                                    .font(.caption)
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(theme.primary.base)
                                    .frame(width: 80, height: 80)
                                    .overlay(
                                        Text("P")
                                            .foregroundColor(theme.primary.base.accessibleContrastingColor(for: targetLevel))
                                    )
                                    .shadow(radius: 2)
                            }
                            
                            // Secondary colors
                            VStack {
                                Text("Secondary")
                                    .font(.caption)
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(theme.secondary.base)
                                    .frame(width: 80, height: 80)
                                    .overlay(
                                        Text("S")
                                            .foregroundColor(theme.secondary.base.accessibleContrastingColor(for: targetLevel))
                                    )
                                    .shadow(radius: 2)
                            }
                            
                            // Accent colors
                            VStack {
                                Text("Accent")
                                    .font(.caption)
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(theme.accent.base)
                                    .frame(width: 80, height: 80)
                                    .overlay(
                                        Text("A")
                                            .foregroundColor(theme.accent.base.accessibleContrastingColor(for: targetLevel))
                                    )
                                    .shadow(radius: 2)
                            }
                        }
                        .padding()
                        
                        // Background with text
                        RoundedRectangle(cornerRadius: 12)
                            .fill(theme.background.base)
                            .frame(height: 100)
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
                                            .cornerRadius(8)
                                    }
                                }
                            )
                    }
                    .padding()
                    .background(Color.secondary.opacity(0.1))
                    .cornerRadius(16)
                }
                
                Spacer(minLength: 32)
                
                // Export section at the bottom
                VStack(spacing: 16) {
                    Divider()
                        .padding(.vertical, 8)
                    
                    Text("Export Options")
                        .font(.headline)
                    
                    VStack(spacing: 12) {
                        Button(action: {
                            showPaletteExport()
                        }) {
                            HStack {
                                Label("Export Palette", systemImage: "square.and.arrow.up")
                                Spacer()
                                Image(systemName: "chevron.right")
                            }
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.accentColor)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }
                        
                        Button(action: {
                            showThemeExport()
                        }) {
                            HStack {
                                Label("Export Theme", systemImage: "square.and.arrow.up.on.square")
                                Spacer()
                                Image(systemName: "chevron.right")
                            }
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.accentColor)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .padding()
        }
        .onAppear {
            // Generate initial palette and theme when the view appears
            generatePaletteAndTheme()
        }
        .sheet(isPresented: $showingExportSheet) {
            if exportingTheme {
                let theme = seedColor.generateAccessibleTheme(name: "Generated Theme", targetLevel: targetLevel)
                PaletteExportView(
                    palette: PaletteExporter.createPalette(from: theme),
                    paletteName: "Generated Theme"
                )
                .frame(minWidth: 400, minHeight: 300)
                #if os(macOS)
                .padding()
                #endif
            } else {
                PaletteExportView(
                    palette: PaletteExporter.createPalette(from: palette),
                    paletteName: "Accessible Palette"
                )
                .frame(minWidth: 400, minHeight: 300)
                #if os(macOS)
                .padding()
                #endif
            }
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
    
    private func showPaletteExport() {
        exportingTheme = false
        showingExportSheet = true
    }
    
    private func showThemeExport() {
        exportingTheme = true
        showingExportSheet = true
    }
} 
