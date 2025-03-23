//
//  02-accessibility-contrast.swift
//  ColorKit
//
//  Created for the AccessibilityGuide tutorial.
//
//  Description:
//  Demonstrates how to check WCAG contrast ratios between
//  foreground and background colors using ColorKit.
//
//  License:
//  MIT License. See LICENSE file for details.
//

import SwiftUI

struct ContentView: View {
    @State private var foregroundColor = Color.blue
    @State private var backgroundColor = Color.white
    
    var body: some View {
        VStack(spacing: 20) {
            Text("WCAG Contrast Checker")
                .font(.title)
                .padding(.top)
            
            // Color Preview
            VStack {
                Text("Sample Text")
                    .font(.title2)
                    .foregroundColor(foregroundColor)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(backgroundColor)
                    .cornerRadius(10)
                
                Text("Sample Small Text")
                    .font(.caption)
                    .foregroundColor(foregroundColor)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(backgroundColor)
                    .cornerRadius(10)
            }
            .padding(.horizontal)
            
            // Contrast Information
            ContrastInfoView(foregroundColor: foregroundColor, backgroundColor: backgroundColor)
            
            // Color Pickers
            VStack(spacing: 15) {
                ColorPicker("Text Color", selection: $foregroundColor)
                ColorPicker("Background Color", selection: $backgroundColor)
            }
            .padding()
        }
        .padding()
    }
}

struct ContrastInfoView: View {
    let foregroundColor: Color
    let backgroundColor: Color
    
    var body: some View {
        // Calculate contrast ratio and compliance
        let compliance = foregroundColor.wcagCompliance(with: backgroundColor)
        
        VStack(spacing: 10) {
            Text("Contrast Ratio: \(String(format: "%.2f", compliance.contrastRatio)):1")
                .font(.headline)
            
            // WCAG Compliance Levels
            VStack(alignment: .leading, spacing: 5) {
                ComplianceRow(
                    level: "AA", 
                    description: "Normal text (minimum 4.5:1)", 
                    passes: compliance.passesAA
                )
                
                ComplianceRow(
                    level: "AA+", 
                    description: "Large text (minimum 3:1)", 
                    passes: compliance.passesAALarge
                )
                
                ComplianceRow(
                    level: "AAA", 
                    description: "Normal text (minimum 7:1)", 
                    passes: compliance.passesAAA
                )
                
                ComplianceRow(
                    level: "AAA+", 
                    description: "Large text (minimum 4.5:1)", 
                    passes: compliance.passesAAALarge
                )
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(8)
        }
    }
}

struct ComplianceRow: View {
    let level: String
    let description: String
    let passes: Bool
    
    var body: some View {
        HStack {
            Image(systemName: passes ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundColor(passes ? .green : .red)
            
            VStack(alignment: .leading) {
                Text(level)
                    .font(.headline)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
} 