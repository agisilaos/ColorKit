//
//  08-color-basics-hsl-components.swift
//  ColorKit
//
//  Created for the ColorBasics tutorial.
//
//  Description:
//  Demonstrates how to extract HSL (Hue, Saturation, Lightness) components
//  from colors and display them in a user interface.
//
//  License:
//  MIT License. See LICENSE file for details.
//

import SwiftUI

struct ContentView: View {
    // Sample colors
    let redColor = Color.red
    let greenColor = Color.green
    let blueColor = Color.blue
    let purpleColor = Color.purple
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Extract HSL Components")
                .font(.title2)
                .padding(.top)
            
            // Extract HSL components for each color
            Group {
                ColorComponentView(
                    color: redColor, 
                    name: "Red",
                    components: {
                        let hsl = redColor.hslComponents() ?? (hue: 0, saturation: 0, lightness: 0)
                        return [
                            ("Hue", hsl.hue),
                            ("Saturation", hsl.saturation),
                            ("Lightness", hsl.lightness)
                        ]
                    }()
                )
                
                ColorComponentView(
                    color: greenColor, 
                    name: "Green",
                    components: {
                        let hsl = greenColor.hslComponents() ?? (hue: 0, saturation: 0, lightness: 0)
                        return [
                            ("Hue", hsl.hue),
                            ("Saturation", hsl.saturation),
                            ("Lightness", hsl.lightness)
                        ]
                    }()
                )
                
                ColorComponentView(
                    color: blueColor, 
                    name: "Blue",
                    components: {
                        let hsl = blueColor.hslComponents() ?? (hue: 0, saturation: 0, lightness: 0)
                        return [
                            ("Hue", hsl.hue),
                            ("Saturation", hsl.saturation),
                            ("Lightness", hsl.lightness)
                        ]
                    }()
                )
                
                ColorComponentView(
                    color: purpleColor, 
                    name: "Purple",
                    components: {
                        let hsl = purpleColor.hslComponents() ?? (hue: 0, saturation: 0, lightness: 0)
                        return [
                            ("Hue", hsl.hue),
                            ("Saturation", hsl.saturation),
                            ("Lightness", hsl.lightness)
                        ]
                    }()
                )
            }
        }
        .padding()
    }
}

struct ColorComponentView: View {
    let color: Color
    let name: String
    let components: [(String, CGFloat)]
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Rectangle()
                    .fill(color)
                    .frame(width: 30, height: 30)
                    .cornerRadius(4)
                
                Text(name)
                    .font(.headline)
            }
            
            HStack(spacing: 20) {
                ForEach(components, id: \.0) { component in
                    VStack {
                        Text(component.0)
                            .font(.caption)
                        
                        if component.0 == "Hue" {
                            Text(String(format: "%.0f°", component.1 * 360))
                                .font(.caption)
                                .bold()
                        } else {
                            Text(String(format: "%.2f", component.1))
                                .font(.caption)
                                .bold()
                        }
                    }
                }
            }
            .padding(.horizontal)
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