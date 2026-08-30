import SwiftUI

/// Keeps the inherited theme in sync even when the enclosing view does not observe the manager.
@MainActor
struct ThemeManagerProvider<Content: View>: View {
    @ObservedObject var manager: ThemeManager
    let content: Content

    var body: some View {
        content
            .environmentObject(manager)
            .environment(\.colorTheme, manager.currentTheme)
            .environment(\.themeManager, manager)
    }
}
