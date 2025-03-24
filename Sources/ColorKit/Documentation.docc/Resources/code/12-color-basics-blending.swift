//
//  12-color-basics-blending.swift
//  ColorKit
//
//  Created for the ColorBasics tutorial.
//
//  Description:
//  Shows how to blend colors using different blending modes such as
//  normal, multiply, screen, and overlay.
//
//  License:
//  MIT License. See LICENSE file for details.
//

import SwiftUI

struct ContentView: View {
    // Define base colors for blending
    let redColor = Color.red
    let blueColor = Color.blue
    let greenColor = Color.green

    var body: some View {
        ScrollView {
            VStack(spacing: 25) {
                Text("Color Blending")
                    .font(.title)
                    .padding(.top)

                // Normal Blending
                BlendingSection(
                    title: "Normal Blending",
                    description: "Blend colors with different alphas",
                    blendItems: [
                        BlendItem(
                            color1: redColor,
                            color2: blueColor,
                            result: redColor.normal(with: blueColor, amount: 0.5),
                            description: "Red + Blue (50%)"
                        ),
                        BlendItem(
                            color1: redColor,
                            color2: greenColor,
                            result: redColor.normal(with: greenColor, amount: 0.7),
                            description: "Red + Green (70%)"
                        ),
                        BlendItem(
                            color1: blueColor,
                            color2: greenColor,
                            result: blueColor.normal(with: greenColor, amount: 0.3),
                            description: "Blue + Green (30%)"
                        )
                    ]
                )

                // Multiply Blending
                BlendingSection(
                    title: "Multiply Blending",
                    description: "Multiplies the source and destination colors",
                    blendItems: [
                        BlendItem(
                            color1: redColor,
                            color2: blueColor,
                            result: redColor.multiply(with: blueColor),
                            description: "Red × Blue"
                        ),
                        BlendItem(
                            color1: redColor,
                            color2: greenColor,
                            result: redColor.multiply(with: greenColor),
                            description: "Red × Green"
                        ),
                        BlendItem(
                            color1: blueColor,
                            color2: greenColor,
                            result: blueColor.multiply(with: greenColor),
                            description: "Blue × Green"
                        )
                    ]
                )

                // Screen Blending
                BlendingSection(
                    title: "Screen Blending",
                    description: "Multiplies the complements of the colors",
                    blendItems: [
                        BlendItem(
                            color1: redColor,
                            color2: blueColor,
                            result: redColor.screen(with: blueColor),
                            description: "Red + Blue (Screen)"
                        ),
                        BlendItem(
                            color1: redColor,
                            color2: greenColor,
                            result: redColor.screen(with: greenColor),
                            description: "Red + Green (Screen)"
                        ),
                        BlendItem(
                            color1: blueColor,
                            color2: greenColor,
                            result: blueColor.screen(with: greenColor),
                            description: "Blue + Green (Screen)"
                        )
                    ]
                )

                // Overlay Blending
                BlendingSection(
                    title: "Overlay Blending",
                    description: "Combines Multiply and Screen blend modes",
                    blendItems: [
                        BlendItem(
                            color1: redColor,
                            color2: blueColor,
                            result: redColor.overlay(with: blueColor),
                            description: "Red over Blue"
                        ),
                        BlendItem(
                            color1: redColor,
                            color2: greenColor,
                            result: redColor.overlay(with: greenColor),
                            description: "Red over Green"
                        ),
                        BlendItem(
                            color1: blueColor,
                            color2: greenColor,
                            result: blueColor.overlay(with: greenColor),
                            description: "Blue over Green"
                        )
                    ]
                )
            }
            .padding()
        }
    }
}

struct BlendingSection: View {
    let title: String
    let description: String
    let blendItems: [BlendItem]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.headline)

            Text(description)
                .font(.caption)
                .foregroundColor(.secondary)

            ForEach(blendItems, id: \.description) { item in
                BlendItemView(item: item)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(10)
    }
}

struct BlendItem {
    let color1: Color
    let color2: Color
    let result: Color
    let description: String
}

struct BlendItemView: View {
    let item: BlendItem

    var body: some View {
        HStack(spacing: 15) {
            // First color
            Rectangle()
                .fill(item.color1)
                .frame(width: 40, height: 40)
                .cornerRadius(4)

            // Plus sign
            Image(systemName: "plus")
                .foregroundColor(.secondary)

            // Second color
            Rectangle()
                .fill(item.color2)
                .frame(width: 40, height: 40)
                .cornerRadius(4)

            // Equals sign
            Image(systemName: "equal")
                .foregroundColor(.secondary)

            // Result color
            Rectangle()
                .fill(item.result)
                .frame(width: 40, height: 40)
                .cornerRadius(4)

            // Description
            Text(item.description)
                .font(.caption)
        }
        .padding(.vertical, 5)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
