//
//  08-accessibility-apply-enhanced.swift
//  ColorKit
//
//  Created for the AccessibilityGuide tutorial.
//
//  Description:
//  Shows how to apply enhanced accessible colors to various UI components
//  to ensure proper accessibility compliance.
//
//  License:
//  MIT License. See LICENSE file for details.
//

import SwiftUI

struct ContentView: View {
    // Original brand colors (potentially inaccessible)
    private let originalPrimaryColor = Color(red: 0.2, green: 0.4, blue: 0.8) // Blue
    private let originalSecondaryColor = Color(red: 0.6, green: 0.2, blue: 0.8) // Purple
    private let originalAccentColor = Color(red: 0.8, green: 0.3, blue: 0.2) // Red
    private let originalBackgroundColor = Color(red: 0.98, green: 0.98, blue: 1.0) // Light blue-gray
    
    // Enhanced accessible colors
    private var enhancedPrimaryColor: Color {
        originalPrimaryColor.enhanced(with: originalBackgroundColor, targetLevel: .AA)
    }
    
    private var enhancedSecondaryColor: Color {
        originalSecondaryColor.enhanced(with: originalBackgroundColor, targetLevel: .AA)
    }
    
    private var enhancedAccentColor: Color {
        originalAccentColor.enhanced(with: originalBackgroundColor, targetLevel: .AA)
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 25) {
                Text("Enhanced Accessible UI")
                    .font(.largeTitle)
                    .foregroundColor(enhancedPrimaryColor)
                    .padding(.top)
                
                // Information card
                VStack(alignment: .leading, spacing: 15) {
                    Text("Applying Enhanced Colors")
                        .font(.headline)
                        .foregroundColor(enhancedPrimaryColor)
                    
                    Text("This demo shows how to enhance your original brand colors and apply them to UI components while maintaining WCAG compliance.")
                        .foregroundColor(enhancedPrimaryColor)
                    
                    // Compare original vs. enhanced colors
                    ColorComparisonView(
                        color1: originalPrimaryColor,
                        color2: enhancedPrimaryColor
                    )
                    
                    ColorComparisonView(
                        color1: originalSecondaryColor,
                        color2: enhancedSecondaryColor
                    )
                    
                    ColorComparisonView(
                        color1: originalAccentColor,
                        color2: enhancedAccentColor
                    )
                }
                .padding()
                .background(originalBackgroundColor)
                .cornerRadius(10)
                
                // Example UI Components
                VStack(alignment: .leading, spacing: 15) {
                    Text("Accessible UI Components")
                        .font(.headline)
                        .foregroundColor(enhancedPrimaryColor)
                    
                    // Text Elements
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Heading Example")
                            .font(.title3)
                            .foregroundColor(enhancedPrimaryColor)
                        
                        Text("Subheading Example")
                            .font(.subheadline)
                            .foregroundColor(enhancedSecondaryColor)
                        
                        Text("This is body text using the enhanced primary color to ensure it's readable against the background.")
                            .foregroundColor(enhancedPrimaryColor)
                    }
                    .padding()
                    .background(originalBackgroundColor.opacity(0.5))
                    .cornerRadius(8)
                    
                    // Button Examples
                    HStack(spacing: 15) {
                        // Primary Button
                        Button(action: {}) {
                            Text("Primary")
                                .fontWeight(.semibold)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .background(enhancedPrimaryColor)
                                .foregroundColor(enhancedPrimaryColor.accessibleContrastingColor())
                                .cornerRadius(8)
                        }
                        
                        // Secondary Button
                        Button(action: {}) {
                            Text("Secondary")
                                .fontWeight(.semibold)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .background(enhancedSecondaryColor)
                                .foregroundColor(enhancedSecondaryColor.accessibleContrastingColor())
                                .cornerRadius(8)
                        }
                        
                        // Accent Button
                        Button(action: {}) {
                            Text("Accent")
                                .fontWeight(.semibold)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .background(enhancedAccentColor)
                                .foregroundColor(enhancedAccentColor.accessibleContrastingColor())
                                .cornerRadius(8)
                        }
                    }
                    .padding(.vertical)
                    
                    // Implementation Example
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Implementation Code:")
                            .font(.subheadline)
                            .bold()
                        
                        Text("""
                        // Define enhanced colors
                        private var enhancedPrimaryColor: Color {
                            originalPrimaryColor.enhanced(
                                with: backgroundColor, 
                                targetLevel: .AA
                            )
                        }
                        
                        // Apply to UI components
                        Text("Heading")
                            .foregroundColor(enhancedPrimaryColor)
                        
                        Button(action: {}) {
                            Text("Button")
                                .background(enhancedAccentColor)
                                .foregroundColor(enhancedAccentColor.accessibleContrastingColor())
                        }
                        """)
                        .font(.system(.caption, design: .monospaced))
                        .padding(8)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(6)
                    }
                }
                .padding()
                .background(originalBackgroundColor)
                .cornerRadius(10)
            }
            .padding()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
} 