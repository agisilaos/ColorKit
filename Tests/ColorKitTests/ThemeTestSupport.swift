import SwiftUI
import XCTest

@testable import ColorKit

#if os(macOS)
import AppKit
#else
import UIKit
#endif

@MainActor
final class ThemeObservations {
    func expect(_ themes: [String: ColorTheme], description: String) -> XCTestExpectation {
        let expectation = XCTestExpectation(description: description)
        expectedThemes = themes
        pendingExpectation = expectation
        fulfillIfReady()
        return expectation
    }

    func record(_ theme: ColorTheme, for key: String) {
        themes[key] = theme
        fulfillIfReady()
    }

    private var themes: [String: ColorTheme] = [:]
    private var expectedThemes: [String: ColorTheme] = [:]
    private var pendingExpectation: XCTestExpectation?

    private func fulfillIfReady() {
        guard expectedThemes.allSatisfy({ themes[$0.key] == $0.value }) else { return }
        pendingExpectation?.fulfill()
        pendingExpectation = nil
    }
}

// Deliberately reads only colorTheme: observing the manager here would hide a stale provider.
struct ThemeProbe: View {
    let key: String
    let observations: ThemeObservations
    @Environment(\.colorTheme)
    private var theme

    var body: some View {
        Text(theme.name)
            .onAppear { observations.record(theme, for: key) }
            .onChange(of: theme) { observations.record($0, for: key) }
    }
}

struct ThemeManagerAccessProbe: View {
    let onAppear: (ThemeManager?, ThemeManager) -> Void
    @Environment(\.themeManager)
    private var environmentManager
    @EnvironmentObject private var environmentObject: ThemeManager

    var body: some View {
        Text("Manager access")
            .onAppear { onAppear(environmentManager, environmentObject) }
    }
}

@MainActor
final class ThemeTestHost {
    #if os(macOS)
    private let window: NSWindow

    init(rootView: some View) {
        _ = NSApplication.shared
        let controller = NSHostingController(rootView: rootView)
        window = NSWindow(contentViewController: controller)
        window.isReleasedWhenClosed = false
        window.setContentSize(NSSize(width: 400, height: 300))
        window.orderFront(nil)
        controller.view.layoutSubtreeIfNeeded()
    }

    func close() {
        window.close()
    }
    #else
    private let window: UIWindow

    init(rootView: some View) {
        let controller = UIHostingController(rootView: rootView)
        window = UIWindow(frame: CGRect(x: 0, y: 0, width: 400, height: 300))
        window.rootViewController = controller
        window.makeKeyAndVisible()
        controller.view.layoutIfNeeded()
    }

    func close() {
        window.isHidden = true
        window.rootViewController = nil
    }
    #endif
}
