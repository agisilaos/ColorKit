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
public extension Color {
    /// Returns a color from `ThemeManager.shared.currentTheme` at the time of the call.
    ///
    /// This lookup does not read the view's `colorTheme` environment or respect
    /// `applyTheme(_:)` overrides. It does not observe later theme selections;
    /// call it again to obtain a color from the new selection.
    ///
    /// For view styling that follows the nearest theme provider, use
    /// `themedColor(_:)` or read `@Environment(\.colorTheme)` in a descendant view
    /// and pass a theme color to `fill(_:)` or another style modifier.
    /// - Parameter role: The semantic color role
    /// - Returns: The role's color from the shared manager's selected theme
    @MainActor
    static func themed(_ role: ThemeColorRole) -> Color {
        color(for: role, in: ThemeManager.shared.currentTheme)
    }
}

// View extension to get themed colors from environment
public extension View {
    /// Applies a foreground color from the view's `colorTheme` environment.
    ///
    /// Follows the nearest `applyTheme(_:)` or `withThemeManager(_:)` provider,
    /// including subsequent changes to the inherited theme.
    /// - Parameter role: The semantic color role
    /// - Returns: A view styled with the role's color from the environment theme
    func themedColor(_ role: ThemeColorRole) -> some View {
        modifier(ThemedColorModifier(role: role))
    }
}

/// A modifier that applies a themed color
struct ThemedColorModifier: ViewModifier {
    let role: ThemeColorRole
    @Environment(\.colorTheme)
    private var theme

    func body(content: Content) -> some View {
        content.foregroundColor(color(for: role, in: theme))
    }
}

private func color(for role: ThemeColorRole, in theme: ColorTheme) -> Color {
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
