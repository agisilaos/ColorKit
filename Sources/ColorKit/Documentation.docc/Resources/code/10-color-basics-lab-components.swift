//
//  10-color-basics-lab-components.swift
//  ColorKit
//
//  Created for the ColorBasics tutorial.
//
//  Description:
//  Demonstrates how to extract LAB color space components from colors
//  and display them in a user interface.
//
//  License:
//  MIT License. See LICENSE file for details.
//

import SwiftUI
import ColorKit

struct ContentView: View {
    // Sample colors
    let redColor = Color.red
    let greenColor = Color.green
    let blueColor = Color.blue
    let purpleColor = Color.purple
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Extract LAB Components")
                .font(.title2)
                .padding(.top)
            
            // Extract LAB components for each color
            Group {
                ColorComponentView(
                    color: redColor, 
                    name: "Red",
                    components: {
                        let lab = redColor.labComponents() ?? (L: 0, a: 0, b: 0)
                        return [
                            ("L* (Lightness)", lab.L),
                            ("a* (Green-Red)", lab.a),
                            ("b* (Blue-Yellow)", lab.b)
                        ]
                    }()
                )
                
                ColorComponentView(
                    color: greenColor, 
                    name: "Green",
                    components: {
                        let lab = greenColor.labComponents() ?? (L: 0, a: 0, b: 0)
                        return [
                            ("L* (Lightness)", lab.L),
                            ("a* (Green-Red)", lab.a),
                            ("b* (Blue-Yellow)", lab.b)
                        ]
                    }()
                )
                
                ColorComponentView(
                    color: blueColor, 
                    name: "Blue",
                    components: {
                        let lab = blueColor.labComponents() ?? (L: 0, a: 0, b: 0)
                        return [
                            ("L* (Lightness)", lab.L),
                            ("a* (Green-Red)", lab.a),
                            ("b* (Blue-Yellow)", lab.b)
                        ]
                    }()
                )
                
                ColorComponentView(
                    color: purpleColor, 
                    name: "Purple",
                    components: {
                        let lab = purpleColor.labComponents() ?? (L: 0, a: 0, b: 0)
                        return [
                            ("L* (Lightness)", lab.L),
                            ("a* (Green-Red)", lab.a),
                            ("b* (Blue-Yellow)", lab.b)
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
            
            ForEach(components, id: \.0) { component in
                HStack {
                    Text(component.0)
                        .font(.caption)
                        .frame(width: 110, alignment: .leading)
                    
                    Text(String(format: "%.1f", component.1))
                        .font(.caption)
                        .bold()
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