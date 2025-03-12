// The Swift Programming Language
// https://docs.swift.org/swift-book

import SwiftUI

/// ColorKit is a comprehensive color utility library for SwiftUI
public enum ColorKit {
    /// The current version of ColorKit
    public static let version = "1.0.0"
    
    /// WCAG Compliance Checker
    public struct WCAG {
        /// Returns a demo view for the WCAG compliance checker
        @MainActor
        public static func demoView() -> some View {
            WCAGDemoView()
        }
    }
}
