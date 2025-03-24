//
//  08-color-basics-to-hex.swift
//  ColorKit
//
//  Created for the ColorBasics tutorial.
//
//  Description:
//  Demonstrates how to convert colors to and from hex string representations
//  using ColorKit's convenient hex conversion utilities.
//
//  License:
//  MIT License. See LICENSE file for details.
//

import SwiftUI

struct ContentView: View {
    @State private var inputHexValue: String = "#3A7BF7"
    @State private var includeAlpha: Bool = false
    @State private var selectedColor: Color = Color(red: 0.227, green: 0.482, blue: 0.969)
    @State private var selectedAlpha: Double = 1.0
    
    // Derived values
    private var colorFromHex: Color? {
        Color(hex: inputHexValue)
    }
    
    private var hexFromColor: String {
        if includeAlpha {
            // Format: #RRGGBBAA
            return selectedColor.withAlpha(selectedAlpha).hexStringWithAlpha ?? "#FFFFFFFF"
        } else {
            // Format: #RRGGBB
            return selectedColor.withAlpha(selectedAlpha).hexString ?? "#FFFFFF"
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 25) {
                Text("Hex Color Conversion")
                    .font(.title)
                    .padding(.top)
                
                // Hex to Color
                VStack(alignment: .leading, spacing: 15) {
                    Text("Hex to Color")
                        .font(.headline)
                    
                    HStack {
                        TextField("Enter hex value (e.g., #FF5500)", text: $inputHexValue)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                        
                        Button(action: {
                            // Clear the input
                            inputHexValue = ""
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.gray)
                        }
                        .buttonStyle(BorderlessButtonStyle())
                    }
                    
                    if let color = colorFromHex {
                        HStack(spacing: 15) {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(color)
                                .frame(width: 80, height: 80)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.gray, lineWidth: 0.5)
                                )
                            
                            VStack(alignment: .leading, spacing: 5) {
                                Text("RGB Values:")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                
                                let components = color.rgbComponents
                                Text("R: \(Int(components.red * 255))")
                                Text("G: \(Int(components.green * 255))")
                                Text("B: \(Int(components.blue * 255))")
                                
                                if components.alpha < 1.0 {
                                    Text("Alpha: \(String(format: "%.2f", components.alpha))")
                                }
                            }
                        }
                    } else {
                        Text("Invalid hex value")
                            .foregroundColor(.red)
                            .padding(.vertical, 5)
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)
                
                // Color to Hex
                VStack(alignment: .leading, spacing: 15) {
                    Text("Color to Hex")
                        .font(.headline)
                    
                    ColorPicker("Select Color", selection: $selectedColor)
                        .padding(.bottom, 5)
                    
                    VStack(alignment: .leading) {
                        Text("Alpha: \(Int(selectedAlpha * 100))%")
                        Slider(value: $selectedAlpha, in: 0...1, step: 0.01)
                    }
                    
                    Toggle("Include Alpha in Hex", isOn: $includeAlpha)
                        .padding(.vertical, 5)
                    
                    HStack(spacing: 15) {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(selectedColor.withAlpha(selectedAlpha))
                            .frame(width: 80, height: 80)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.gray, lineWidth: 0.5)
                            )
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Hex Value:")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            Text(hexFromColor)
                                .font(.system(.body, design: .monospaced))
                                .padding(8)
                                .background(Color.black.opacity(0.05))
                                .cornerRadius(4)
                            
                            Button(action: {
                                // In a real app, this would copy to clipboard
                                // UIPasteboard.general.string = hexFromColor
                            }) {
                                Label("Copy Hex Value", systemImage: "doc.on.doc")
                                    .font(.caption)
                            }
                            .buttonStyle(BorderlessButtonStyle())
                        }
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)
                
                // Examples
                VStack(alignment: .leading, spacing: 15) {
                    Text("Common Hex Color Examples")
                        .font(.headline)
                    
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 15) {
                        ColorHexExample(color: .red, name: "Red")
                        ColorHexExample(color: .green, name: "Green")
                        ColorHexExample(color: .blue, name: "Blue")
                        ColorHexExample(color: .yellow, name: "Yellow")
                        ColorHexExample(color: .purple, name: "Purple")
                        ColorHexExample(color: .orange, name: "Orange")
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)
                
                // Code Examples
                VStack(alignment: .leading, spacing: 15) {
                    Text("Code Examples")
                        .font(.headline)
                    
                    Text("Convert hex string to Color:")
                        .font(.subheadline)
                    
                    Text("""
                    // Create a color from a hex string
                    let blueColor = Color(hex: "#3A7BF7")
                    
                    // With alpha channel
                    let translucentRed = Color(hex: "#FF000080")
                    """)
                    .font(.system(.body, design: .monospaced))
                    .padding(10)
                    .background(Color.black.opacity(0.05))
                    .cornerRadius(6)
                    
                    Text("Convert Color to hex string:")
                        .font(.subheadline)
                        .padding(.top, 10)
                    
                    Text("""
                    // Get hex string with # prefix
                    let hexString = myColor.hexString // "#3A7BF7"
                    
                    // Get hex string without # prefix
                    let rawHex = myColor.hexStringWithoutHash // "3A7BF7"
                    
                    // Get hex string with alpha
                    let hexWithAlpha = myColor.hexStringWithAlpha // "#3A7BF7FF"
                    """)
                    .font(.system(.body, design: .monospaced))
                    .padding(10)
                    .background(Color.black.opacity(0.05))
                    .cornerRadius(6)
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)
            }
            .padding()
        }
    }
}

struct ColorHexExample: View {
    let color: Color
    let name: String
    
    private var hexValue: String {
        color.hexString ?? "#FFFFFF"
    }
    
    var body: some View {
        VStack(spacing: 5) {
            Circle()
                .fill(color)
                .frame(width: 40, height: 40)
                .overlay(
                    Circle()
                        .stroke(Color.gray, lineWidth: 0.5)
                )
            
            Text(name)
                .font(.caption)
                .fontWeight(.medium)
            
            Text(hexValue)
                .font(.system(.caption2, design: .monospaced))
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 5)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
} 