//
//  ColorInspectorDemoView.swift
//  ColorKit
//
//  Created by Agisilaos Tsaraboulidis on 12.03.25.
//
//  Description:
//  Provides a demo view for the Color Inspector feature.
//
//  Features:
//  - Interactive color selection
//  - Real-time color inspection
//  - Demonstrates the Color Inspector functionality
//
//  License:
//  MIT License. See LICENSE file for details.
//

import SwiftUI

/// A demo view that showcases the Color Inspector functionality
public struct ColorInspectorDemoView: View {
    @State private var foregroundColor: Color = .blue
    @State private var backgroundColor: Color = .white
    @State private var showInspector: Bool = true
    @State private var inspectorPosition: ColorInspectorModifier.Position = .bottomTrailing
    
    public init() {}
    
    public var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header
                Text("Live Color Inspector")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                // Color Pickers
                VStack(alignment: .leading, spacing: 10) {
                    Text("Colors")
                        .font(.headline)
                    
                    ColorPicker("Primary Color", selection: $foregroundColor)
                    ColorPicker("Background Color", selection: $backgroundColor)
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)
                
                // Inspector Settings
                VStack(alignment: .leading, spacing: 10) {
                    Text("Inspector Settings")
                        .font(.headline)
                    
                    Toggle("Show Inspector", isOn: $showInspector)
                    
                    if showInspector {
                        Picker("Position", selection: $inspectorPosition) {
                            Text("Top Left").tag(ColorInspectorModifier.Position.topLeading)
                            Text("Top Right").tag(ColorInspectorModifier.Position.topTrailing)
                            Text("Bottom Left").tag(ColorInspectorModifier.Position.bottomLeading)
                            Text("Bottom Right").tag(ColorInspectorModifier.Position.bottomTrailing)
                        }
                        .pickerStyle(SegmentedPickerStyle())
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)
                
                // Color Preview
                VStack(spacing: 15) {
                    Text("Color Preview")
                        .font(.headline)
                    
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(backgroundColor)
                            .frame(height: 300)
                            .shadow(radius: 2)
                        
                        VStack(spacing: 20) {
                            Circle()
                                .fill(foregroundColor)
                                .frame(width: 100, height: 100)
                            
                            RoundedRectangle(cornerRadius: 8)
                                .fill(foregroundColor)
                                .frame(width: 200, height: 50)
                            
                            Text("Sample Text")
                                .font(.title)
                                .foregroundColor(foregroundColor)
                        }
                    }
                    .overlay(
                        Group {
                            if showInspector {
                                ColorInspectorView(
                                    color: foregroundColor,
                                    backgroundColor: backgroundColor
                                )
                                .padding()
                            }
                        },
                        alignment: inspectorPositionAlignment
                    )
                }
                .padding()
                
                // Information
                VStack(alignment: .leading, spacing: 8) {
                    Text("About the Color Inspector")
                        .font(.headline)
                    
                    Text("The Color Inspector provides real-time information about colors, including:")
                        .font(.subheadline)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("• HEX color values")
                        Text("• RGB color components")
                        Text("• HSL color components")
                        Text("• Contrast ratio with background")
                        Text("• WCAG compliance indicators")
                    }
                    .padding(.leading)
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)
            }
            .padding()
        }
    }
    
    private var inspectorPositionAlignment: Alignment {
        switch inspectorPosition {
        case .topLeading:
            return .topLeading
        case .topTrailing:
            return .topTrailing
        case .bottomLeading:
            return .bottomLeading
        case .bottomTrailing:
            return .bottomTrailing
        }
    }
}

struct ColorInspectorDemoView_Previews: PreviewProvider {
    static var previews: some View {
        ColorInspectorDemoView()
    }
} 