//
//  AccessibilityEnhancerDemoView.swift
//  ColorKit
//
//  Created by Agisilaos Tsaraboulidis on 13.03.25.
//
//  Description:
//  Demonstrates the enhanced accessibility features of ColorKit.
//
//  Features:
//  - Interactive demo of accessibility enhancement strategies
//  - Visual comparison of original and enhanced colors
//  - Contrast ratio display
//  - Strategy selection
//
//  License:
//  MIT License. See LICENSE file for details.
//

import SwiftUI

/// A demo view that showcases the enhanced accessibility features of ColorKit
@available(iOS 14.0, macOS 11.0, *)
public struct AccessibilityEnhancerDemoView: View {
    @State private var originalColor: Color = .blue
    @State private var backgroundColor: Color = .white
    @State private var targetLevel: WCAGContrastLevel = .AA
    @State private var strategy: AdjustmentStrategy = .preserveHue
    @State private var showVariants: Bool = false
    
    public init() {}
    
    public var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("Accessibility Enhancer Demo")
                    .font(.title)
                    .fontWeight(.bold)
                
                // Color pickers
                VStack(alignment: .leading, spacing: 10) {
                    Text("Original Color")
                        .font(.headline)
                    
                    ColorPicker("Select Color", selection: $originalColor)
                        .padding()
                        .background(RoundedRectangle(cornerRadius: 8).fill(Color.gray.opacity(0.1)))
                    
                    Text("Background Color")
                        .font(.headline)
                    
                    ColorPicker("Select Background", selection: $backgroundColor)
                        .padding()
                        .background(RoundedRectangle(cornerRadius: 8).fill(Color.gray.opacity(0.1)))
                }
                .padding(.horizontal)
                
                // WCAG level picker
                VStack(alignment: .leading, spacing: 10) {
                    Text("Target WCAG Level")
                        .font(.headline)
                    
                    Picker("WCAG Level", selection: $targetLevel) {
                        ForEach(WCAGContrastLevel.allCases) { level in
                            Text(level.rawValue).tag(level)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 8).fill(Color.gray.opacity(0.1)))
                }
                .padding(.horizontal)
                
                // Strategy picker
                VStack(alignment: .leading, spacing: 10) {
                    Text("Enhancement Strategy")
                        .font(.headline)
                    
                    Picker("Strategy", selection: $strategy) {
                        ForEach(AdjustmentStrategy.allCases) { strategy in
                            Text(strategy.rawValue.capitalized).tag(strategy)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 8).fill(Color.gray.opacity(0.1)))
                    
                    Text(strategy.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                }
                .padding(.horizontal)
                
                // Color comparison
                VStack(spacing: 20) {
                    Text("Color Comparison")
                        .font(.headline)
                    
                    HStack(spacing: 20) {
                        // Original color
                        VStack {
                            Text("Original")
                                .font(.subheadline)
                            
                            ZStack {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(backgroundColor)
                                    .frame(width: 120, height: 80)
                                    .shadow(radius: 2)
                                
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(originalColor)
                                    .frame(width: 100, height: 60)
                                
                                Text("Text")
                                    .foregroundColor(originalColor)
                                    .fontWeight(.bold)
                            }
                            
                            let originalRatio = originalColor.wcagContrastRatio(with: backgroundColor)
                            let originalPasses = originalRatio >= targetLevel.minimumRatio
                            
                            Text("Ratio: \(String(format: "%.2f", originalRatio))")
                                .font(.caption)
                                .foregroundColor(originalPasses ? .green : .red)
                            
                            Text(originalPasses ? "Passes" : "Fails")
                                .font(.caption)
                                .foregroundColor(originalPasses ? .green : .red)
                                .fontWeight(.bold)
                        }
                        
                        // Enhanced color
                        VStack {
                            Text("Enhanced")
                                .font(.subheadline)
                            
                            let enhancedColor = originalColor.enhanced(
                                with: backgroundColor,
                                targetLevel: targetLevel,
                                strategy: strategy
                            )
                            
                            ZStack {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(backgroundColor)
                                    .frame(width: 120, height: 80)
                                    .shadow(radius: 2)
                                
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(enhancedColor)
                                    .frame(width: 100, height: 60)
                                
                                Text("Text")
                                    .foregroundColor(enhancedColor)
                                    .fontWeight(.bold)
                            }
                            
                            let enhancedRatio = enhancedColor.wcagContrastRatio(with: backgroundColor)
                            let enhancedPasses = enhancedRatio >= targetLevel.minimumRatio
                            
                            Text("Ratio: \(String(format: "%.2f", enhancedRatio))")
                                .font(.caption)
                                .foregroundColor(enhancedPasses ? .green : .red)
                            
                            Text(enhancedPasses ? "Passes" : "Fails")
                                .font(.caption)
                                .foregroundColor(enhancedPasses ? .green : .red)
                                .fontWeight(.bold)
                        }
                    }
                }
                .padding()
                .background(RoundedRectangle(cornerRadius: 12).fill(Color.gray.opacity(0.1)))
                .padding(.horizontal)
                
                // Variants
                VStack(alignment: .leading, spacing: 10) {
                    Button(action: {
                        showVariants.toggle()
                    }) {
                        HStack {
                            Text(showVariants ? "Hide Variants" : "Show Suggested Variants")
                            Image(systemName: showVariants ? "chevron.up" : "chevron.down")
                        }
                        .font(.headline)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(RoundedRectangle(cornerRadius: 8).fill(Color.gray.opacity(0.1)))
                    }
                    
                    if showVariants {
                        let variants = originalColor.suggestAccessibleVariants(
                            with: backgroundColor,
                            targetLevel: targetLevel,
                            count: 4
                        )
                        
                        Text("These variants maintain harmony with your original color while meeting accessibility requirements:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 15) {
                                ForEach(0..<variants.count, id: \.self) { index in
                                    let variant = variants[index]
                                    
                                    VStack {
                                        ZStack {
                                            RoundedRectangle(cornerRadius: 8)
                                                .fill(backgroundColor)
                                                .frame(width: 100, height: 70)
                                                .shadow(radius: 2)
                                            
                                            RoundedRectangle(cornerRadius: 4)
                                                .fill(variant)
                                                .frame(width: 80, height: 50)
                                            
                                            Text("Aa")
                                                .foregroundColor(variant)
                                                .fontWeight(.bold)
                                        }
                                        
                                        let ratio = variant.wcagContrastRatio(with: backgroundColor)
                                        Text("Ratio: \(String(format: "%.2f", ratio))")
                                            .font(.caption)
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                }
                .padding(.horizontal)
                
                // Explanation
                VStack(alignment: .leading, spacing: 10) {
                    Text("How It Works")
                        .font(.headline)
                    
                    Text("The AccessibilityEnhancer intelligently adjusts colors to meet WCAG contrast requirements while preserving brand identity. It uses perceptual color models to make the smallest possible changes needed to meet accessibility standards.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(RoundedRectangle(cornerRadius: 12).fill(Color.gray.opacity(0.1)))
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
    }
}

@available(iOS 14.0, macOS 11.0, *)
struct AccessibilityEnhancerDemoView_Previews: PreviewProvider {
    static var previews: some View {
        AccessibilityEnhancerDemoView()
    }
} 
