//
//  07-color-basics-rgb-components.swift
//  ColorKit
//
//  Created for the ColorBasics tutorial.
//
//  Description:
//  Shows how to extract and display individual RGB components
//  from colors using ColorKit's utility methods.
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
            Text("Extract RGB Components")
                .font(.title2)
                .padding(.top)

            // Extract RGB components for each color
            Group {
                ColorComponentView(
                    color: redColor,
                    name: "Red",
                    components: {
                        let rgb = redColor.rgbaComponents()
                        return [
                            ("Red", rgb.red),
                            ("Green", rgb.green),
                            ("Blue", rgb.blue),
                            ("Alpha", rgb.alpha)
                        ]
                    }()
                )

                ColorComponentView(
                    color: greenColor,
                    name: "Green",
                    components: {
                        let rgb = greenColor.rgbaComponents()
                        return [
                            ("Red", rgb.red),
                            ("Green", rgb.green),
                            ("Blue", rgb.blue),
                            ("Alpha", rgb.alpha)
                        ]
                    }()
                )

                ColorComponentView(
                    color: blueColor,
                    name: "Blue",
                    components: {
                        let rgb = blueColor.rgbaComponents()
                        return [
                            ("Red", rgb.red),
                            ("Green", rgb.green),
                            ("Blue", rgb.blue),
                            ("Alpha", rgb.alpha)
                        ]
                    }()
                )

                ColorComponentView(
                    color: purpleColor,
                    name: "Purple",
                    components: {
                        let rgb = purpleColor.rgbaComponents()
                        return [
                            ("Red", rgb.red),
                            ("Green", rgb.green),
                            ("Blue", rgb.blue),
                            ("Alpha", rgb.alpha)
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
    let components: [(String, Double)]

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

                        Text(String(format: "%.2f", component.1))
                            .font(.caption)
                            .bold()
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
