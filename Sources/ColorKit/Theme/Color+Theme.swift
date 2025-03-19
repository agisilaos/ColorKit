//
//  Color+Theme.swift
//  ColorKit
//
//  Created by Agisilaos Tsaraboulidis on 11.03.25.
//
//  Description:
//  Extends Color with theme-related functionality.
//
//  Features:
//  - Provides semantic color access
//  - Enables easy access to themed colors
//
//  License:
//  MIT License. See LICENSE file for details.
//

import SwiftUI

/// Semantic color roles in a theme
@available(iOS 14.0, macOS 11.0, *)
public enum ThemeColorRole: Sendable {
    case primary
    case primaryLight
    case primaryDark
    case secondary
    case secondaryLight
    case secondaryDark
    case accent
    case accentLight
    case accentDark
    case background
    case backgroundElevated
    case backgroundLowered
    case text
    case textSecondary
    case textTertiary
    case success
    case warning
    case error
}

// Extension to add semantic color access
@available(iOS 14.0, macOS 11.0, *)
public extension Color {
    /// Returns a themed color based on the current theme
    /// - Parameter role: The semantic color role
    /// - Returns: The appropriate color from the current theme
    @MainActor
    static func themed(_ role: ThemeColorRole) -> Color {
        // This is a convenience method that will be used in views
        // The actual implementation will use the environment
        // This is just a fallback for static contexts
        let theme = ThemeManager.shared.currentTheme

        switch role {
        case .primary:
            return theme.primary.base
        case .primaryLight:
            return theme.primary.light
        case .primaryDark:
            return theme.primary.dark
        case .secondary:
            return theme.secondary.base
        case .secondaryLight:
            return theme.secondary.light
        case .secondaryDark:
            return theme.secondary.dark
        case .accent:
            return theme.accent.base
        case .accentLight:
            return theme.accent.light
        case .accentDark:
            return theme.accent.dark
        case .background:
            return theme.background.base
        case .backgroundElevated:
            return theme.background.light
        case .backgroundLowered:
            return theme.background.dark
        case .text:
            return theme.text.base
        case .textSecondary:
            return theme.text.light
        case .textTertiary:
            return theme.text.dark
        case .success:
            return theme.status.success
        case .warning:
            return theme.status.warning
        case .error:
            return theme.status.error
        }
    }
}

// View extension to get themed colors from environment
@available(iOS 14.0, macOS 11.0, *)
public extension View {
    /// Gets a themed color from the environment
    /// - Parameter role: The semantic color role
    /// - Returns: The appropriate color from the current theme in the environment
    func themedColor(_ role: ThemeColorRole) -> some View {
        modifier(ThemedColorModifier(role: role))
    }
}

/// A modifier that applies a themed color
@available(iOS 14.0, macOS 11.0, *)
struct ThemedColorModifier: ViewModifier {
    let role: ThemeColorRole
    @Environment(\.colorTheme) private var theme

    func body(content: Content) -> some View {
        content.foregroundColor(colorForRole(role))
    }

    private func colorForRole(_ role: ThemeColorRole) -> Color {
        switch role {
        case .primary:
            return theme.primary.base
        case .primaryLight:
            return theme.primary.light
        case .primaryDark:
            return theme.primary.dark
        case .secondary:
            return theme.secondary.base
        case .secondaryLight:
            return theme.secondary.light
        case .secondaryDark:
            return theme.secondary.dark
        case .accent:
            return theme.accent.base
        case .accentLight:
            return theme.accent.light
        case .accentDark:
            return theme.accent.dark
        case .background:
            return theme.background.base
        case .backgroundElevated:
            return theme.background.light
        case .backgroundLowered:
            return theme.background.dark
        case .text:
            return theme.text.base
        case .textSecondary:
            return theme.text.light
        case .textTertiary:
            return theme.text.dark
        case .success:
            return theme.status.success
        case .warning:
            return theme.status.warning
        case .error:
            return theme.status.error
        }
    }
}
