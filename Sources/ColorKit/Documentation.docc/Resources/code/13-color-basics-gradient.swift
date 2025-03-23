//
//  13-color-basics-gradient.swift
//  ColorKit
//
//  Created for the ColorBasics tutorial.
//
//  Description:
//  Demonstrates how to create and customize color gradients, including
//  linear, radial, and angular gradients with different color interpolation methods.
//
//  License:
//  MIT License. See LICENSE file for details.
//

import SwiftUI

struct ContentView: View {
    // Define colors for gradients
    let startColor = Color.blue
    let endColor = Color.red
    let midColor = Color.green
    
    var body: some View {
        ScrollView {
            VStack(spacing: 25) {
                Text("Color Gradients")
                    .font(.title)
                    .padding(.top)
                
                // Linear interpolation between two colors
                GradientSection(
                    title: "Linear Interpolation (Two Colors)",
                    description: "Interpolate between two colors using different color spaces",
                    content: {
                        VStack(spacing: 15) {
                            // RGB interpolation
                            GradientRow(
                                title: "RGB Interpolation",
                                colors: [
                                    startColor.interpolated(with: endColor, amount: 0.0, in: .rgb),
                                    startColor.interpolated(with: endColor, amount: 0.25, in: .rgb),
                                    startColor.interpolated(with: endColor, amount: 0.5, in: .rgb),
                                    startColor.interpolated(with: endColor, amount: 0.75, in: .rgb),
                                    startColor.interpolated(with: endColor, amount: 1.0, in: .rgb)
                                ]
                            )
                            
                            // HSL interpolation
                            GradientRow(
                                title: "HSL Interpolation",
                                colors: [
                                    startColor.interpolated(with: endColor, amount: 0.0, in: .hsl),
                                    startColor.interpolated(with: endColor, amount: 0.25, in: .hsl),
                                    startColor.interpolated(with: endColor, amount: 0.5, in: .hsl),
                                    startColor.interpolated(with: endColor, amount: 0.75, in: .hsl),
                                    startColor.interpolated(with: endColor, amount: 1.0, in: .hsl)
                                ]
                            )
                            
                            // LAB interpolation
                            GradientRow(
                                title: "LAB Interpolation",
                                colors: [
                                    startColor.interpolated(with: endColor, amount: 0.0, in: .lab),
                                    startColor.interpolated(with: endColor, amount: 0.25, in: .lab),
                                    startColor.interpolated(with: endColor, amount: 0.5, in: .lab),
                                    startColor.interpolated(with: endColor, amount: 0.75, in: .lab),
                                    startColor.interpolated(with: endColor, amount: 1.0, in: .lab)
                                ]
                            )
                        }
                    }()
                )
                
                // Generated gradients
                GradientSection(
                    title: "Generated Gradients",
                    description: "Create gradients with multiple colors and customization",
                    content: {
                        VStack(spacing: 15) {
                            // Two-color gradient
                            VStack(alignment: .leading, spacing: 5) {
                                Text("Two-Color Gradient")
                                    .font(.subheadline)
                                
                                Rectangle()
                                    .fill(
                                        LinearGradient(
                                            gradient: Gradient(colors: [startColor, endColor]),
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .frame(height: 30)
                                    .cornerRadius(5)
                            }
                            
                            // Three-color gradient
                            VStack(alignment: .leading, spacing: 5) {
                                Text("Three-Color Gradient")
                                    .font(.subheadline)
                                
                                Rectangle()
                                    .fill(
                                        LinearGradient(
                                            gradient: Gradient(colors: [startColor, midColor, endColor]),
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .frame(height: 30)
                                    .cornerRadius(5)
                            }
                            
                            // Custom stops
                            VStack(alignment: .leading, spacing: 5) {
                                Text("Custom Color Stops")
                                    .font(.subheadline)
                                
                                Rectangle()
                                    .fill(
                                        LinearGradient(
                                            gradient: Gradient(
                                                stops: [
                                                    .init(color: startColor, location: 0),
                                                    .init(color: midColor, location: 0.3),
                                                    .init(color: endColor, location: 1)
                                                ]
                                            ),
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .frame(height: 30)
                                    .cornerRadius(5)
                            }
                            
                            // Radial gradient
                            VStack(alignment: .leading, spacing: 5) {
                                Text("Radial Gradient")
                                    .font(.subheadline)
                                
                                Rectangle()
                                    .fill(
                                        RadialGradient(
                                            gradient: Gradient(colors: [startColor, endColor]),
                                            center: .center,
                                            startRadius: 5,
                                            endRadius: 100
                                        )
                                    )
                                    .frame(height: 100)
                                    .cornerRadius(5)
                            }
                            
                            // Angular gradient
                            VStack(alignment: .leading, spacing: 5) {
                                Text("Angular Gradient")
                                    .font(.subheadline)
                                
                                Rectangle()
                                    .fill(
                                        AngularGradient(
                                            gradient: Gradient(colors: [startColor, midColor, endColor, startColor]),
                                            center: .center
                                        )
                                    )
                                    .frame(height: 100)
                                    .cornerRadius(5)
                            }
                        }
                    }()
                )
            }
            .padding()
        }
    }
}

struct GradientSection: View {
    let title: String
    let description: String
    let content: AnyView
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.headline)
            
            Text(description)
                .font(.caption)
                .foregroundColor(.secondary)
            
            content
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(10)
    }
}

struct GradientRow: View {
    let title: String
    let colors: [Color]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title)
                .font(.subheadline)
            
            HStack(spacing: 2) {
                ForEach(0..<colors.count, id: \.self) { index in
                    Rectangle()
                        .fill(colors[index])
                        .frame(maxWidth: .infinity)
                        .frame(height: 30)
                        .cornerRadius(index == 0 ? 5 : 0, corners: .topLeft)
                        .cornerRadius(index == 0 ? 5 : 0, corners: .bottomLeft)
                        .cornerRadius(index == colors.count - 1 ? 5 : 0, corners: .topRight)
                        .cornerRadius(index == colors.count - 1 ? 5 : 0, corners: .bottomRight)
                }
            }
        }
    }
}

// Helper for rounded corners on specific sides
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect, 
            byRoundingCorners: corners, 
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
} 