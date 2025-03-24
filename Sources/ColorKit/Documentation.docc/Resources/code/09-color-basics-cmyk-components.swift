//
//  09-color-basics-cmyk-components.swift
//  ColorKit
//
//  Created for the ColorBasics tutorial.
//
//  Description:
//  Shows how to extract CMYK (Cyan, Magenta, Yellow, Black) components
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
            Text("Extract CMYK Components")
                .font(.title2)
                .padding(.top)

            // Extract CMYK components for each color
            Group {
                ColorComponentView(
                    color: redColor,
                    name: "Red",
                    components: {
                        let cmyk = redColor.cmykComponents() ?? (cyan: 0, magenta: 0, yellow: 0, key: 0)
                        return [
                            ("Cyan", cmyk.cyan),
                            ("Magenta", cmyk.magenta),
                            ("Yellow", cmyk.yellow),
                            ("Key (Black)", cmyk.key)
                        ]
                    }()
                )

                ColorComponentView(
                    color: greenColor,
                    name: "Green",
                    components: {
                        let cmyk = greenColor.cmykComponents() ?? (cyan: 0, magenta: 0, yellow: 0, key: 0)
                        return [
                            ("Cyan", cmyk.cyan),
                            ("Magenta", cmyk.magenta),
                            ("Yellow", cmyk.yellow),
                            ("Key (Black)", cmyk.key)
                        ]
                    }()
                )

                ColorComponentView(
                    color: blueColor,
                    name: "Blue",
                    components: {
                        let cmyk = blueColor.cmykComponents() ?? (cyan: 0, magenta: 0, yellow: 0, key: 0)
                        return [
                            ("Cyan", cmyk.cyan),
                            ("Magenta", cmyk.magenta),
                            ("Yellow", cmyk.yellow),
                            ("Key (Black)", cmyk.key)
                        ]
                    }()
                )

                ColorComponentView(
                    color: purpleColor,
                    name: "Purple",
                    components: {
                        let cmyk = purpleColor.cmykComponents() ?? (cyan: 0, magenta: 0, yellow: 0, key: 0)
                        return [
                            ("Cyan", cmyk.cyan),
                            ("Magenta", cmyk.magenta),
                            ("Yellow", cmyk.yellow),
                            ("Key (Black)", cmyk.key)
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

            HStack(spacing: 12) {
                ForEach(components, id: \.0) { component in
                    VStack {
                        Text(component.0.prefix(1)) // First letter for the component
                            .font(.caption)

                        Text(String(format: "%.0f%%", component.1 * 100))
                            .font(.caption)
                            .bold()
                    }
                    .frame(minWidth: 40)
                }
            }
            .padding(.horizontal)
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }
}

#Preview {
    ContentView()
}
