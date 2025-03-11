//
//  ContentView.swift
//  ColorKitDemo
//
//  Created by Agisilaos Tsaraboulidis on 11.03.25.
//

import SwiftUI
import ColorKit

import SwiftUI
import ColorKit

struct ContentView: View {
    @State private var selectedColor = Color.blue
    @State private var backgroundColor = Color.white

    var body: some View {
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
        }
        .padding()
    }
}

