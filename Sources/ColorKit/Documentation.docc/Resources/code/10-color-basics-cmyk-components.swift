//
//  10-color-basics-cmyk-components.swift
//  ColorKit
//
//  Created for the ColorBasics tutorial.
//
//  Description:
//  Demonstrates how to work with CMYK color components in ColorKit,
//  providing interactive controls to understand and manipulate colors 
//  in the CMYK color space used for print design.
//
//  License:
//  MIT License. See LICENSE file for details.
//

import SwiftUI

struct ContentView: View {
    @State private var cyan: Double = 0.7
    @State private var magenta: Double = 0.3
    @State private var yellow: Double = 0.0
    @State private var black: Double = 0.1
    
    // Derived color from CMYK components
    private var currentColor: Color {
        Color(cyan: CGFloat(cyan), magenta: CGFloat(magenta), yellow: CGFloat(yellow), key: CGFloat(black))
    }
    
    // The equivalent RGB values (derived from CMYK)
    private var derivedRGB: (red: Int, green: Int, blue: Int) {
        guard let components = currentColor.cgColor?.components, components.count >= 3 else {
            return (red: 0, green: 0, blue: 0)
        }
        return (
            red: Int(components[0] * 255),
            green: Int(components[1] * 255),
            blue: Int(components[2] * 255)
        )
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 25) {
                Text("CMYK Color Components")
                    .font(.title)
                    .padding(.top)
                
                // CMYK Explanation
                VStack(alignment: .leading, spacing: 12) {
                    Text("Understanding CMYK")
                        .font(.headline)
                    
                    Text("CMYK (Cyan, Magenta, Yellow, Key/Black) is primarily used in print design. Unlike RGB which is additive (adding light), CMYK is subtractive (removing light by adding ink).")
                        .font(.body)
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 15) {
                        // Color components visualization
                        VStack(spacing: 8) {
                            Circle()
                                .fill(Color.cyan)
                                .frame(width: 50, height: 50)
                                .overlay(Circle().stroke(Color.gray, lineWidth: 0.5))
                            
                            Text("Cyan")
                                .font(.caption)
                        }
                        
                        VStack(spacing: 8) {
                            Circle()
                                .fill(Color(red: 1, green: 0, blue: 1))
                                .frame(width: 50, height: 50)
                                .overlay(Circle().stroke(Color.gray, lineWidth: 0.5))
                            
                            Text("Magenta")
                                .font(.caption)
                        }
                        
                        VStack(spacing: 8) {
                            Circle()
                                .fill(Color.yellow)
                                .frame(width: 50, height: 50)
                                .overlay(Circle().stroke(Color.gray, lineWidth: 0.5))
                            
                            Text("Yellow")
                                .font(.caption)
                        }
                        
                        VStack(spacing: 8) {
                            Circle()
                                .fill(Color.black)
                                .frame(width: 50, height: 50)
                                .overlay(Circle().stroke(Color.gray, lineWidth: 0.5))
                            
                            Text("Black")
                                .font(.caption)
                        }
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)
                
                // Color Preview
                VStack(spacing: 15) {
                    Text("Color Preview")
                        .font(.headline)
                    
                    RoundedRectangle(cornerRadius: 10)
                        .fill(currentColor)
                        .frame(height: 120)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.gray, lineWidth: 0.5)
                        )
                    
                    // CMYK and RGB Values
                    HStack(spacing: 20) {
                        VStack(alignment: .leading, spacing: 5) {
                            Text("CMYK Values:")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            Text("C: \(Int(cyan * 100))%")
                                .font(.system(.caption, design: .monospaced))
                            Text("M: \(Int(magenta * 100))%")
                                .font(.system(.caption, design: .monospaced))
                            Text("Y: \(Int(yellow * 100))%")
                                .font(.system(.caption, design: .monospaced))
                            Text("K: \(Int(black * 100))%")
                                .font(.system(.caption, design: .monospaced))
                        }
                        
                        VStack(alignment: .leading, spacing: 5) {
                            Text("RGB Values:")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            Text("R: \(derivedRGB.red)")
                                .font(.system(.caption, design: .monospaced))
                            Text("G: \(derivedRGB.green)")
                                .font(.system(.caption, design: .monospaced))
                            Text("B: \(derivedRGB.blue)")
                                .font(.system(.caption, design: .monospaced))
                        }
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)
                
                // CMYK Controls
                VStack(alignment: .leading, spacing: 20) {
                    Text("CMYK Controls")
                        .font(.headline)
                    
                    // Cyan Control
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Cyan: \(Int(cyan * 100))%")
                            .font(.subheadline)
                        
                        CMYKSlider(
                            value: $cyan,
                            color: .cyan,
                            background: LinearGradient(
                                gradient: Gradient(colors: [.white, .cyan]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                    }
                    
                    // Magenta Control
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Magenta: \(Int(magenta * 100))%")
                            .font(.subheadline)
                        
                        CMYKSlider(
                            value: $magenta,
                            color: Color(red: 1, green: 0, blue: 1), // System magenta color
                            background: LinearGradient(
                                gradient: Gradient(colors: [.white, Color(red: 1, green: 0, blue: 1)]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                    }
                    
                    // Yellow Control
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Yellow: \(Int(yellow * 100))%")
                            .font(.subheadline)
                        
                        CMYKSlider(
                            value: $yellow,
                            color: .yellow,
                            background: LinearGradient(
                                gradient: Gradient(colors: [.white, .yellow]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                    }
                    
                    // Black Control
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Black (K): \(Int(black * 100))%")
                            .font(.subheadline)
                        
                        CMYKSlider(
                            value: $black,
                            color: .black,
                            background: LinearGradient(
                                gradient: Gradient(colors: [.white, .black]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)
                
                // Print Swatches
                VStack(alignment: .leading, spacing: 15) {
                    Text("Common Print Colors")
                        .font(.headline)
                    
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 120))], spacing: 10) {
                        PrintColorSwatch(
                            name: "Process Cyan",
                            cmyk: (1.0, 0.0, 0.0, 0.0)
                        )
                        
                        PrintColorSwatch(
                            name: "Process Magenta",
                            cmyk: (0.0, 1.0, 0.0, 0.0)
                        )
                        
                        PrintColorSwatch(
                            name: "Process Yellow",
                            cmyk: (0.0, 0.0, 1.0, 0.0)
                        )
                        
                        PrintColorSwatch(
                            name: "Rich Black",
                            cmyk: (0.6, 0.5, 0.5, 1.0)
                        )
                        
                        PrintColorSwatch(
                            name: "Navy Blue",
                            cmyk: (1.0, 0.7, 0.0, 0.5)
                        )
                        
                        PrintColorSwatch(
                            name: "Forest Green",
                            cmyk: (0.8, 0.0, 0.8, 0.5)
                        )
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)
                
                // Code Example
                VStack(alignment: .leading, spacing: 15) {
                    Text("Code Example")
                        .font(.headline)
                    
                    Text("""
                    // Create a color using CMYK values
                    let color = Color(
                        cyan: \(String(format: "%.2f", cyan)),      // 0-1
                        magenta: \(String(format: "%.2f", magenta)),   // 0-1
                        yellow: \(String(format: "%.2f", yellow)),    // 0-1
                        key: \(String(format: "%.2f", black))       // 0-1
                    )
                    
                    // Extract CMYK components from a color
                    if let cmykComponents = myColor.cmykComponents() {
                        let cyan = cmykComponents.cyan
                        let magenta = cmykComponents.magenta
                        let yellow = cmykComponents.yellow
                        let key = cmykComponents.key
                    }
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

struct CMYKSlider: View {
    @Binding var value: Double
    let color: Color
    let background: LinearGradient
    
    var body: some View {
        ZStack(alignment: .leading) {
            // Background gradient
            background
                .frame(height: 30)
                .cornerRadius(5)
            
            // Slider
            Slider(value: $value, in: 0...1, step: 0.01)
                .padding(.horizontal, 2)
        }
    }
}

struct PrintColorSwatch: View {
    let name: String
    let cmyk: (cyan: Double, magenta: Double, yellow: Double, black: Double)
    
    var color: Color {
        Color(cyan: CGFloat(cmyk.cyan), magenta: CGFloat(cmyk.magenta), yellow: CGFloat(cmyk.yellow), key: CGFloat(cmyk.black))
    }
    
    var body: some View {
        VStack(spacing: 5) {
            RoundedRectangle(cornerRadius: 8)
                .fill(color)
                .frame(height: 50)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray, lineWidth: 0.5)
                )
            
            Text(name)
                .font(.caption)
                .fontWeight(.medium)
            
            Text("C:\(Int(cmyk.cyan * 100)) M:\(Int(cmyk.magenta * 100)) Y:\(Int(cmyk.yellow * 100)) K:\(Int(cmyk.black * 100))")
                .font(.system(.caption2, design: .monospaced))
                .foregroundColor(.secondary)
        }
    }
}
#Preview {
    ContentView()
}