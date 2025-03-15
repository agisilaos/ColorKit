//
//  ContentView.swift
//  ColorKitDemo
//
//  Created by Agisilaos Tsaraboulidis on 11.03.25.
//

import SwiftUI
import ColorKit

struct ContentView: View {
    @State private var selectedColor = Color.blue
    @State private var backgroundColor = Color.white
    @State private var showWCAGDemo = false
    @State private var showPaletteDemo = false
    @State private var showAccessibilityEnhancerDemo = false
    
    var body: some View {
        NavigationView {
            VStack {
                ColorPicker("Pick a Foreground Color", selection: $selectedColor)
                    .padding()

                ColorPicker("Pick a Background Color", selection: $backgroundColor)
                    .padding()

                // HEX Value Display
                Text("HEX: \(selectedColor.hexValue() ?? "N/A")")
                    .adaptiveColor(light: .black, dark: .white)
                    .padding()

                // HSL Values Display
                if let hsl = selectedColor.hslComponents() {
                    Text("HSL: Hue \(hsl.hue), Sat \(hsl.saturation), Light \(hsl.lightness)")
                        .padding()
                }

                // High Contrast Text (Dynamically Adjusts for Readability)
                Text("This text adapts for high contrast")
                    .highContrastColor(base: selectedColor, background: backgroundColor)
                    .padding()

                // Theme Change Detection
                Text("Theme Change Detector")
                    .onAdaptiveColorChange { newScheme in
                        print("Color scheme changed to: \(newScheme)")
                    }
                
                // Demo Buttons Section
                VStack(spacing: 12) {
                    // WCAG Compliance Demo Button
                    Button("Open WCAG Compliance Checker") {
                        showWCAGDemo = true
                    }
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .frame(maxWidth: .infinity)
                    
                    // Accessible Palette Generator Demo Button
                    Button("Open Accessible Palette Generator") {
                        showPaletteDemo = true
                    }
                    .padding()
                    .background(Color.purple)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .frame(maxWidth: .infinity)
                    
                    // Accessibility Enhancer Demo Button
                    Button("Open Accessibility Enhancer") {
                        showAccessibilityEnhancerDemo = true
                    }
                    .padding()
                    .background(Color.orange)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .frame(maxWidth: .infinity)
                }
                .padding(.horizontal)
                
                Spacer()
            }
            .padding()
            .navigationTitle("ColorKit Demo")
            .sheet(isPresented: $showWCAGDemo) {
                ColorKit.WCAG.demoView()
            }
            .sheet(isPresented: $showPaletteDemo) {
                ColorKit.ColorInspector.accessiblePaletteDemoView()
            }
            .sheet(isPresented: $showAccessibilityEnhancerDemo) {
                AccessibilityEnhancerDemoView()
            }
        }
    }
}

// Preview
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

