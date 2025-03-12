// The Swift Programming Language
// https://docs.swift.org/swift-book

import SwiftUI

/// ColorKit is a comprehensive color utility library for SwiftUI
public enum ColorKit {
    /// The current version of ColorKit
    public static let version = "1.2.0"
    
    /// WCAG Compliance Checker
    public struct WCAG {
        /// Returns a demo view for the WCAG compliance checker
        @MainActor
        public static func demoView() -> some View {
            return WCAGDemoView()
        }
    }
    
    /// Live Color Inspector
    public struct ColorInspector {
        /// Returns a demo view for the color inspector
        @MainActor
        public static func demoView() -> some View {
            return ColorInspectorDemoView()
        }
        
        /// Returns a demo view for the accessible palette generator
        @available(iOS 14.0, macOS 11.0, *)
        @MainActor
        public static func accessiblePaletteDemoView() -> some View {
            AccessiblePaletteDemoView()
        }
        
        /// Generates an accessible color palette based on a seed color
        /// - Parameters:
        ///   - seedColor: The color to base the palette on
        ///   - targetLevel: The WCAG level to target (default: .AA)
        ///   - paletteSize: The number of colors to generate (default: 5)
        ///   - includeBlackAndWhite: Whether to include black and white (default: true)
        /// - Returns: An array of colors that form an accessible palette
        @available(iOS 14.0, macOS 11.0, *)
        public static func generateAccessiblePalette(
            from seedColor: Color,
            targetLevel: WCAGContrastLevel = .AA,
            paletteSize: Int = 5,
            includeBlackAndWhite: Bool = true
        ) -> [Color] {
            seedColor.generateAccessiblePalette(
                targetLevel: targetLevel,
                paletteSize: paletteSize,
                includeBlackAndWhite: includeBlackAndWhite
            )
        }
        
        /// Generates an accessible theme based on a seed color
        /// - Parameters:
        ///   - seedColor: The color to base the theme on
        ///   - name: The name for the theme
        ///   - targetLevel: The WCAG level to target (default: .AA)
        /// - Returns: A ColorTheme with accessible color combinations
        @available(iOS 14.0, macOS 11.0, *)
        public static func generateAccessibleTheme(
            from seedColor: Color,
            name: String,
            targetLevel: WCAGContrastLevel = .AA
        ) -> ColorTheme {
            seedColor.generateAccessibleTheme(
                name: name,
                targetLevel: targetLevel
            )
        }
    }
}
