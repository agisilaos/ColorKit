//
//  06-accessibility-text-color.swift
//  ColorKit
//
//  Created for the AccessibilityGuide tutorial.
//
//  Description:
//  Demonstrates how to generate accessible text colors for different backgrounds
//  to ensure proper contrast and readability.
//
//  License:
//  MIT License. See LICENSE file for details.
//

import SwiftUI
import ColorKit

struct ContentView: View {
    let backgroundColors: [BackgroundOption] = [
        BackgroundOption(name: "Light", color: .white),
        BackgroundOption(name: "Light Gray", color: Color(white: 0.9)),
        BackgroundOption(name: "Medium", color: Color(white: 0.5)),
        BackgroundOption(name: "Dark Gray", color: Color(white: 0.3)),
        BackgroundOption(name: "Dark", color: .black),
        BackgroundOption(name: "Blue", color: Color.blue),
        BackgroundOption(name: "Green", color: Color.green),
        BackgroundOption(name: "Red", color: Color.red)
    ]
    
    @State private var selectedWcagLevel: WCAGContrastLevel = .AA
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("Accessible Text Colors")
                    .font(.largeTitle)
                    .padding(.top)
                
                // WCAG Level Selection
                VStack(alignment: .leading) {
                    Text("Target WCAG Level:")
                        .font(.headline)
                    
                    Picker("WCAG Level", selection: $selectedWcagLevel) {
                        ForEach(WCAGContrastLevel.allCases) { level in
                            Text(level.rawValue).tag(level)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)
                
                // Show text color examples for each background
                ForEach(backgroundColors) { bgOption in
                    TextColorExample(
                        backgroundColor: bgOption.color,
                        backgroundName: bgOption.name,
                        wcagLevel: selectedWcagLevel
                    )
                }
            }
            .padding()
        }
    }
}

struct BackgroundOption: Identifiable {
    let id = UUID()
    let name: String
    let color: Color
}

struct TextColorExample: View {
    let backgroundColor: Color
    let backgroundName: String
    let wcagLevel: WCAGContrastLevel
    
    var body: some View {
        // Generate accessible text color for this background
        let textColor = backgroundColor.accessibleContrastingColor(for: wcagLevel)
        
        // Calculate the contrast ratio for verification
        let contrastRatio = textColor.wcagContrastRatio(with: backgroundColor)
        
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Background: \(backgroundName)")
                    .font(.headline)
                
                Spacer()
                
                Text("Contrast: \(String(format: "%.2f", contrastRatio)):1")
                    .font(.caption)
                    .padding(4)
                    .background(Color.white.opacity(0.8))
                    .cornerRadius(4)
            }
            
            // Text color demonstration
            VStack(spacing: 15) {
                Text("Accessible Text")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(textColor)
                
                Text("This text color is dynamically generated to ensure it has sufficient contrast with the background, meeting \(wcagLevel.rawValue) level requirements (min \(String(format: "%.1f", wcagLevel.minimumRatio)):1).")
                    .foregroundColor(textColor)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(backgroundColor)
            .cornerRadius(10)
            
            // Implementation code
            Text("""
            // Generate accessible text color
            let textColor = backgroundColor.accessibleContrastingColor(for: .\(wcagLevel.rawValue))
            
            // Use in your SwiftUI views
            Text("My accessible text")
                .foregroundColor(textColor)
            """)
            .font(.system(.caption, design: .monospaced))
            .padding(8)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(6)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(10)
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
} 