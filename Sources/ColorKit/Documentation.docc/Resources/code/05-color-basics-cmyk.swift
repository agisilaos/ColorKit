//
//  05-color-basics-cmyk.swift
//  ColorKit
//
//  Created for the ColorBasics tutorial.
//
//  Description:
//  Demonstrates how to create colors using the CMYK (Cyan, Magenta, Yellow, Black)
//  color space, which is commonly used in print design.
//
//  License:
//  MIT License. See LICENSE file for details.
//

import SwiftUI

struct ContentView: View {
    // Basic CMYK colors
    let cyanColor = Color(cyan: 1, magenta: 0, yellow: 0, key: 0)
    let magentaColor = Color(cyan: 0, magenta: 1, yellow: 0, key: 0)
    let yellowColor = Color(cyan: 0, magenta: 0, yellow: 1, key: 0)
    let blackColor = Color(cyan: 0, magenta: 0, yellow: 0, key: 1)
    
    // Combined CMYK colors
    let redColor = Color(cyan: 0, magenta: 1, yellow: 1, key: 0)
    let greenColor = Color(cyan: 1, magenta: 0, yellow: 1, key: 0)
    let blueColor = Color(cyan: 1, magenta: 1, yellow: 0, key: 0)
    
    // Colors with key (black) component
    let darkRed = Color(cyan: 0, magenta: 1, yellow: 1, key: 0.5)
    let darkGreen = Color(cyan: 1, magenta: 0, yellow: 1, key: 0.5)
    let darkBlue = Color(cyan: 1, magenta: 1, yellow: 0, key: 0.5)
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("CMYK Primary Colors")
                    .font(.headline)
                
                HStack(spacing: 15) {
                    ColorSwatch(color: cyanColor, name: "Cyan\nC:1 M:0 Y:0 K:0")
                    ColorSwatch(color: magentaColor, name: "Magenta\nC:0 M:1 Y:0 K:0")
                    ColorSwatch(color: yellowColor, name: "Yellow\nC:0 M:0 Y:1 K:0")
                    ColorSwatch(color: blackColor, name: "Black\nC:0 M:0 Y:0 K:1")
                }
                
                Divider()
                
                Text("CMYK Combined Colors")
                    .font(.headline)
                
                HStack(spacing: 15) {
                    ColorSwatch(color: redColor, name: "Red\nC:0 M:1 Y:1 K:0")
                    ColorSwatch(color: greenColor, name: "Green\nC:1 M:0 Y:1 K:0")
                    ColorSwatch(color: blueColor, name: "Blue\nC:1 M:1 Y:0 K:0")
                }
                
                Divider()
                
                Text("CMYK with Black Component")
                    .font(.headline)
                
                HStack(spacing: 15) {
                    ColorSwatch(color: darkRed, name: "Dark Red\nC:0 M:1 Y:1 K:0.5")
                    ColorSwatch(color: darkGreen, name: "Dark Green\nC:1 M:0 Y:1 K:0.5")
                    ColorSwatch(color: darkBlue, name: "Dark Blue\nC:1 M:1 Y:0 K:0.5")
                }
            }
            .padding()
        }
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