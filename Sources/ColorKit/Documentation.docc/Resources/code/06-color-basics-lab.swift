//
//  06-color-basics-lab.swift
//  ColorKit
//
//  Created for the ColorBasics tutorial.
//
//  Description:
//  Demonstrates creating colors using LAB color space, which is designed
//  to be perceptually uniform and approximates human vision.
//
//  License:
//  MIT License. See LICENSE file for details.
//

import SwiftUI

struct ContentView: View {
    // Basic LAB colors
    let neutralGray = Color(L: 50, a: 0, b: 0)
    let redColor = Color(L: 50, a: 80, b: 67)
    let greenColor = Color(L: 50, a: -80, b: 80)
    let blueColor = Color(L: 50, a: 20, b: -80)

    // Lightness variations
    let darkColor = Color(L: 20, a: 0, b: 0)
    let mediumColor = Color(L: 50, a: 0, b: 0)
    let lightColor = Color(L: 80, a: 0, b: 0)

    // A-axis variations (red to green)
    let strongRed = Color(L: 50, a: 80, b: 0)
    let neutralA = Color(L: 50, a: 0, b: 0)
    let strongGreen = Color(L: 50, a: -80, b: 0)

    // B-axis variations (yellow to blue)
    let strongYellow = Color(L: 50, a: 0, b: 80)
    let neutralB = Color(L: 50, a: 0, b: 0)
    let strongBlue = Color(L: 50, a: 0, b: -80)

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("LAB Color Examples")
                    .font(.headline)

                HStack(spacing: 15) {
                    ColorSwatch(color: neutralGray, name: "Gray\nL:50 a:0 b:0")
                    ColorSwatch(color: redColor, name: "Red\nL:50 a:80 b:67")
                    ColorSwatch(color: greenColor, name: "Green\nL:50 a:-80 b:80")
                    ColorSwatch(color: blueColor, name: "Blue\nL:50 a:20 b:-80")
                }

                Divider()

                Text("Lightness (L) Axis")
                    .font(.headline)

                HStack(spacing: 15) {
                    ColorSwatch(color: darkColor, name: "Dark\nL:20 a:0 b:0")
                    ColorSwatch(color: mediumColor, name: "Medium\nL:50 a:0 b:0")
                    ColorSwatch(color: lightColor, name: "Light\nL:80 a:0 b:0")
                }

                Divider()

                Text("A-Axis (Red to Green)")
                    .font(.headline)

                HStack(spacing: 15) {
                    ColorSwatch(color: strongRed, name: "Red\nL:50 a:80 b:0")
                    ColorSwatch(color: neutralA, name: "Neutral\nL:50 a:0 b:0")
                    ColorSwatch(color: strongGreen, name: "Green\nL:50 a:-80 b:0")
                }

                Divider()

                Text("B-Axis (Yellow to Blue)")
                    .font(.headline)

                HStack(spacing: 15) {
                    ColorSwatch(color: strongYellow, name: "Yellow\nL:50 a:0 b:80")
                    ColorSwatch(color: neutralB, name: "Neutral\nL:50 a:0 b:0")
                    ColorSwatch(color: strongBlue, name: "Blue\nL:50 a:0 b:-80")
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
