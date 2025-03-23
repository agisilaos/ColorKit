//
//  11-color-basics-converter.swift
//  ColorKit
//
//  Created for the ColorBasics tutorial.
//
//  Description:
//  Demonstrates ColorKit's color space conversion capabilities, allowing
//  users to convert colors between multiple color spaces.
//
//  License:
//  MIT License. See LICENSE file for details.
//

import SwiftUI

struct ContentView: View {
    @State private var selectedColor = Color.blue
    @State private var sliderValue: CGFloat = 0.5
    
    // Generate a dynamic color
    var dynamicColor: Color {
        Color(hue: sliderValue, saturation: 1.0, brightness: 1.0)
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("Color Space Converter")
                    .font(.title)
                    .padding(.top)
                
                // Color selection
                VStack {
                    Rectangle()
                        .fill(dynamicColor)
                        .frame(height: 80)
                        .cornerRadius(10)
                    
                    // Hue slider
                    Slider(value: $sliderValue)
                        .padding(.horizontal)
                        .accentColor(dynamicColor)
                    
                    Text("Hue: \(Int(sliderValue * 360))°")
                        .font(.caption)
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)
                
                // Convert and display all color spaces
                ColorSpaceDisplay(color: dynamicColor)
            }
            .padding()
        }
    }
}

struct ColorSpaceDisplay: View {
    let color: Color
    
    // Use ColorSpaceConverter to get all components
    var colorComponents: ColorComponents {
        let converter = ColorSpaceConverter(color: color)
        return converter.getAllColorComponents()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Color Components")
                .font(.headline)
            
            // RGB
            ComponentSection(
                title: "RGB",
                components: [
                    ("Red", colorComponents.rgb.red, "%.2f"),
                    ("Green", colorComponents.rgb.green, "%.2f"),
                    ("Blue", colorComponents.rgb.blue, "%.2f"),
                    ("Alpha", colorComponents.rgb.alpha, "%.2f")
                ]
            )
            
            // HSL
            ComponentSection(
                title: "HSL",
                components: [
                    ("Hue", colorComponents.hsl.hue * 360, "%.0f°"),
                    ("Saturation", colorComponents.hsl.saturation, "%.2f"),
                    ("Lightness", colorComponents.hsl.lightness, "%.2f")
                ]
            )
            
            // HSB
            ComponentSection(
                title: "HSB",
                components: [
                    ("Hue", colorComponents.hsb.hue * 360, "%.0f°"),
                    ("Saturation", colorComponents.hsb.saturation, "%.2f"),
                    ("Brightness", colorComponents.hsb.brightness, "%.2f")
                ]
            )
            
            // CMYK
            ComponentSection(
                title: "CMYK",
                components: [
                    ("Cyan", colorComponents.cmyk.cyan * 100, "%.0f%%"),
                    ("Magenta", colorComponents.cmyk.magenta * 100, "%.0f%%"),
                    ("Yellow", colorComponents.cmyk.yellow * 100, "%.0f%%"),
                    ("Key (Black)", colorComponents.cmyk.key * 100, "%.0f%%")
                ]
            )
            
            // LAB
            ComponentSection(
                title: "LAB",
                components: [
                    ("L* (Lightness)", colorComponents.lab.l, "%.1f"),
                    ("a* (Green-Red)", colorComponents.lab.a, "%.1f"),
                    ("b* (Blue-Yellow)", colorComponents.lab.b, "%.1f")
                ]
            )
            
            // XYZ
            ComponentSection(
                title: "XYZ",
                components: [
                    ("X", colorComponents.xyz.x, "%.1f"),
                    ("Y", colorComponents.xyz.y, "%.1f"),
                    ("Z", colorComponents.xyz.z, "%.1f")
                ]
            )
        }
    }
}

struct ComponentSection: View {
    let title: String
    let components: [(name: String, value: Double, format: String)]
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.semibold)
            
            HStack {
                ForEach(components, id: \.name) { component in
                    VStack(alignment: .leading) {
                        Text(component.name)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text(String(format: component.format, component.value))
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(.horizontal, 5)
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
} 