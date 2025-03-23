//
//  04-color-basics-hsl.swift
//  ColorKit
//
//  Created for the ColorBasics tutorial.
//
//  Description:
//  Shows how to create colors using HSL (Hue, Saturation, Lightness)
//  color space and demonstrates the effects of varying these components.
//
//  License:
//  MIT License. See LICENSE file for details.
//

import SwiftUI
import ColorKit

struct ContentView: View {
    // Create colors from HSL values
    let redHSL = Color(hue: 0, saturation: 1, lightness: 0.5)
    let greenHSL = Color(hue: 0.33, saturation: 1, lightness: 0.5)
    let blueHSL = Color(hue: 0.66, saturation: 1, lightness: 0.5)
    
    // Variations with different lightness
    let darkBlue = Color(hue: 0.66, saturation: 1, lightness: 0.3)
    let lightBlue = Color(hue: 0.66, saturation: 1, lightness: 0.7)
    
    // Variations with different saturation
    let fullSaturation = Color(hue: 0.33, saturation: 1, lightness: 0.5)
    let mediumSaturation = Color(hue: 0.33, saturation: 0.6, lightness: 0.5)
    let lowSaturation = Color(hue: 0.33, saturation: 0.3, lightness: 0.5)
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Colors from HSL")
                .font(.headline)
            
            HStack(spacing: 15) {
                ColorSwatch(color: redHSL, name: "H:0 S:1 L:0.5")
                ColorSwatch(color: greenHSL, name: "H:0.33 S:1 L:0.5")
                ColorSwatch(color: blueHSL, name: "H:0.66 S:1 L:0.5")
            }
            
            Divider()
            
            Text("Lightness Variations")
                .font(.headline)
            
            HStack(spacing: 15) {
                ColorSwatch(color: darkBlue, name: "L:0.3")
                ColorSwatch(color: blueHSL, name: "L:0.5")
                ColorSwatch(color: lightBlue, name: "L:0.7")
            }
            
            Divider()
            
            Text("Saturation Variations")
                .font(.headline)
            
            HStack(spacing: 15) {
                ColorSwatch(color: lowSaturation, name: "S:0.3")
                ColorSwatch(color: mediumSaturation, name: "S:0.6")
                ColorSwatch(color: fullSaturation, name: "S:1.0")
            }
        }
        .padding()
    }
}

struct ColorSwatch: View {
    let color: Color
    let name: String
    
    var body: some View {
        VStack {
            Rectangle()
                .fill(color)
                .frame(width: 80, height: 80)
                .cornerRadius(8)
            
            Text(name)
                .font(.caption)
                .multilineTextAlignment(.center)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
} 