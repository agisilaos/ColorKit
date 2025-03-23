//
//  09-accessibility-compare.swift
//  ColorKit
//
//  Created for the AccessibilityGuide tutorial.
//
//  Description:
//  Shows how to implement a toggle to compare original (potentially inaccessible)
//  colors with enhanced accessible alternatives.
//
//  License:
//  MIT License. See LICENSE file for details.
//

import SwiftUI
import UIKit

struct ContentView: View {
    // Original brand colors
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
    
    @State private var useEnhancedColors = true
    @State private var selectedTab = 0
    
    // Dynamic colors based on toggle state
    private var primaryColor: Color {
        useEnhancedColors ? enhancedPrimaryColor : originalPrimaryColor
    }
    
    private var secondaryColor: Color {
        useEnhancedColors ? enhancedSecondaryColor : originalSecondaryColor
    }
    
    private var accentColor: Color {
        useEnhancedColors ? enhancedAccentColor : originalAccentColor
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with enhancement toggle
            VStack(spacing: 10) {
                HStack {
                    Text("Color Accessibility Demo")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(primaryColor)
                    
                    Spacer()
                }
                
                HStack {
                    Toggle("Use Enhanced Colors", isOn: $useEnhancedColors)
                        .toggleStyle(SwitchToggleStyle(tint: accentColor))
                        .onChange(of: useEnhancedColors) { _ in
                            // Haptic feedback when toggling
                            let generator = UIImpactFeedbackGenerator(style: .medium)
                            generator.impactOccurred()
                        }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing) {
                        if useEnhancedColors {
                            Text("WCAG AA Compliant")
                                .font(.footnote)
                                .foregroundColor(.green)
                        } else {
                            Text("Potentially Inaccessible")
                                .font(.footnote)
                                .foregroundColor(.red)
                        }
                    }
                }
            }
            .padding()
            .background(Color.white)
            .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 3)
            
            // Tab bar
            HStack(spacing: 0) {
                TabButton(
                    title: "Dashboard",
                    systemImage: "chart.bar",
                    isSelected: selectedTab == 0,
                    color: primaryColor
                ) {
                    selectedTab = 0
                }
                
                TabButton(
                    title: "Settings",
                    systemImage: "gear",
                    isSelected: selectedTab == 1,
                    color: primaryColor
                ) {
                    selectedTab = 1
                }
                
                TabButton(
                    title: "Profile",
                    systemImage: "person",
                    isSelected: selectedTab == 2,
                    color: primaryColor
                ) {
                    selectedTab = 2
                }
                
                TabButton(
                    title: "More",
                    systemImage: "ellipsis",
                    isSelected: selectedTab == 3,
                    color: primaryColor
                ) {
                    selectedTab = 3
                }
            }
            .padding(.top, 5)
            .background(Color.white)
            .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 3)
            
            // Content area
            ZStack {
                originalBackgroundColor.edgesIgnoringSafeArea(.all)
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Information panel
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Color Accessibility Comparison")
                                .font(.headline)
                                .foregroundColor(primaryColor)
                            
                            Text("Toggle the switch above to see how enhanced colors improve accessibility while maintaining your brand identity. This demonstration shows how ColorKit can help make your app more accessible to users with visual impairments.")
                                .foregroundColor(primaryColor)
                                .font(.body)
                            
                            // Contrast information
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text("Contrast Ratios:")
                                        .bold()
                                        .foregroundColor(primaryColor)
                                    
                                    Spacer()
                                    
                                    Text(useEnhancedColors ? "Enhanced" : "Original")
                                        .foregroundColor(primaryColor)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 4)
                                        .background(primaryColor.opacity(0.15))
                                        .cornerRadius(12)
                                }
                                
                                ContrastRow(
                                    name: "Primary on Background",
                                    color: primaryColor,
                                    backgroundColor: originalBackgroundColor
                                )
                                
                                ContrastRow(
                                    name: "Secondary on Background",
                                    color: secondaryColor,
                                    backgroundColor: originalBackgroundColor
                                )
                                
                                ContrastRow(
                                    name: "Accent on Background",
                                    color: accentColor,
                                    backgroundColor: originalBackgroundColor
                                )
                            }
                            .padding()
                            .background(Color.white.opacity(0.6))
                            .cornerRadius(10)
                        }
                        .padding()
                        .background(originalBackgroundColor)
                        .cornerRadius(12)
                        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 3)
                        
                        // Sample UI elements
                        VStack(alignment: .leading, spacing: 15) {
                            Text("Sample UI Elements")
                                .font(.headline)
                                .foregroundColor(primaryColor)
                            
                            // Buttons
                            HStack(spacing: 15) {
                                // Primary button
                                Button(action: {}) {
                                    Label("Primary", systemImage: "checkmark.circle")
                                        .padding(.horizontal, 15)
                                        .padding(.vertical, 10)
                                        .background(primaryColor)
                                        .foregroundColor(Color.white)
                                        .cornerRadius(8)
                                }
                                
                                // Secondary button
                                Button(action: {}) {
                                    Label("Secondary", systemImage: "star")
                                        .padding(.horizontal, 15)
                                        .padding(.vertical, 10)
                                        .background(secondaryColor)
                                        .foregroundColor(Color.white)
                                        .cornerRadius(8)
                                }
                                
                                // Accent button
                                Button(action: {}) {
                                    Label("Accent", systemImage: "bell")
                                        .padding(.horizontal, 15)
                                        .padding(.vertical, 10)
                                        .background(accentColor)
                                        .foregroundColor(Color.white)
                                        .cornerRadius(8)
                                }
                            }
                            .padding(.vertical, 5)
                            
                            // Text samples
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Heading with Primary Color")
                                    .font(.title3)
                                    .fontWeight(.bold)
                                    .foregroundColor(primaryColor)
                                
                                Text("Subheading with Secondary Color")
                                    .font(.subheadline)
                                    .foregroundColor(secondaryColor)
                                
                                Text("Body text with primary color. This text should be easily readable against the background color when enhanced colors are enabled.")
                                    .foregroundColor(primaryColor)
                                
                                Text("Important note with accent color")
                                    .font(.caption)
                                    .foregroundColor(accentColor)
                                    .padding(.top, 5)
                            }
                            .padding()
                            .background(Color.white.opacity(0.6))
                            .cornerRadius(10)
                        }
                        .padding()
                        .background(originalBackgroundColor)
                        .cornerRadius(12)
                        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 3)
                        
                        // Implementation info
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Implementation")
                                .font(.headline)
                                .foregroundColor(primaryColor)
                            
                            Text("""
                            // Define togglable colors
                            @State private var useEnhancedColors = true
                            
                            private var primaryColor: Color {
                                useEnhancedColors ? 
                                    originalPrimaryColor.enhanced(with: backgroundColor, targetLevel: .AA) : 
                                    originalPrimaryColor
                            }
                            
                            // Apply to UI
                            Text("Heading")
                                .foregroundColor(primaryColor)
                            """)
                            .font(.system(.caption, design: .monospaced))
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                        }
                        .padding()
                        .background(originalBackgroundColor)
                        .cornerRadius(12)
                        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 3)
                    }
                    .padding()
                }
            }
            .clipShape(Rectangle())
        }
    }
}

struct TabButton: View {
    let title: String
    let systemImage: String
    let isSelected: Bool
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: systemImage)
                    .font(.system(size: 24))
                    .foregroundColor(isSelected ? color : .gray)
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(isSelected ? color : .gray)
            }
            .frame(maxWidth: .infinity)
            .padding(.bottom, 10)
            .overlay(
                Rectangle()
                    .frame(height: 3)
                    .foregroundColor(isSelected ? color : .clear)
                    .padding(.top, 40)
            )
        }
    }
}

struct ContrastRow: View {
    let name: String
    let color: Color
    let backgroundColor: Color
    
    private var contrastRatio: Double {
        color.wcagContrastRatio(with: backgroundColor)
    }
    
    private var isAACompliant: Bool {
        contrastRatio >= 4.5
    }
    
    private var isAAACompliant: Bool {
        contrastRatio >= 7.0
    }
    
    var body: some View {
        HStack {
            Text(name)
                .foregroundColor(.primary)
            
            Spacer()
            
            // Color sample
            HStack(spacing: 2) {
                Rectangle()
                    .fill(color)
                    .frame(width: 14, height: 14)
                    .cornerRadius(2)
                
                Text("on")
                    .font(.caption)
                    .foregroundColor(.gray)
                
                Rectangle()
                    .fill(backgroundColor)
                    .frame(width: 14, height: 14)
                    .cornerRadius(2)
                    .overlay(
                        RoundedRectangle(cornerRadius: 2)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
            }
            
            // Ratio and compliance level
            VStack(alignment: .trailing) {
                Text("\(String(format: "%.1f", contrastRatio)):1")
                    .fontWeight(.medium)
                    .foregroundColor(isAACompliant ? .green : .red)
                
                HStack(spacing: 3) {
                    Text("AA")
                        .font(.system(size: 9))
                        .padding(.horizontal, 3)
                        .padding(.vertical, 1)
                        .background(isAACompliant ? Color.green : Color.red.opacity(0.7))
                        .foregroundColor(.white)
                        .cornerRadius(2)
                    
                    Text("AAA")
                        .font(.system(size: 9))
                        .padding(.horizontal, 3)
                        .padding(.vertical, 1)
                        .background(isAAACompliant ? Color.green : Color.red.opacity(0.7))
                        .foregroundColor(.white)
                        .cornerRadius(2)
                }
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
} 