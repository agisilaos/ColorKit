import SwiftUI
import XCTest

@testable import ColorKit

@MainActor
final class AccessiblePaletteExportPresentationTests: XCTestCase {
    // MARK: - Rendering

    func testHostedDemoRedrawsDoNotPrepareAgainOrChangeSharedFile() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        var preparations = 0
        let export = AccessiblePaletteExport(files: AccessiblePaletteExportFiles(root: root)) { _ in
            preparations += 1
            return Data("fixed payload".utf8)
        }
        let driver = RedrawDriver()
        var renderedScheme: ColorScheme?
        let host = Host(content: TestContent(export: export, driver: driver) { scheme in
            renderedScheme = scheme
        })
        defer { host.close() }
        // Drive layout explicitly so native share-sheet transitions cannot gate the assertions.
        host.render()
        XCTAssertEqual(renderedScheme, .light)
        XCTAssertEqual(preparations, 0)

        export.share(AccessiblePaletteExport.Snapshot(entries: [], name: "Prepared", format: .json))
        let item = try XCTUnwrap(export.shareItem)
        renderedScheme = nil
        driver.scheme = .dark
        host.render()
        XCTAssertEqual(renderedScheme, .dark)

        XCTAssertEqual(preparations, 1)
        XCTAssertEqual(export.shareItem?.id, item.id)
        XCTAssertEqual(try Data(contentsOf: item.url), Data("fixed payload".utf8))

        export.shareItem = nil
        renderedScheme = nil
        driver.scheme = .light
        host.render()
        XCTAssertEqual(renderedScheme, .light)

        XCTAssertEqual(preparations, 1)
        XCTAssertTrue(FileManager.default.fileExists(atPath: item.url.path))
    }

    // MARK: - Test Host

    @MainActor
    private final class RedrawDriver: ObservableObject {
        @Published var scheme = ColorScheme.light
    }

    private struct TestContent: View {
        let export: AccessiblePaletteExport
        @ObservedObject var driver: RedrawDriver
        let rendered: (ColorScheme) -> Void

        var body: some View {
            rendered(driver.scheme)
            return AccessiblePaletteDemoView(export: export)
                .environment(\.colorScheme, driver.scheme)
        }
    }

    @MainActor
    private final class Host {
        #if os(macOS)
        init(content: some View) {
            _ = NSApplication.shared
            let controller = NSHostingController(rootView: content)
            window = NSWindow(contentViewController: controller)
            window.isReleasedWhenClosed = false
            window.setContentSize(NSSize(width: 500, height: 700))
            window.orderFront(nil)
        }

        func close() { window.close() }

        func render() {
            window.contentView?.needsLayout = true
            window.contentView?.layoutSubtreeIfNeeded()
        }

        private let window: NSWindow
        #else
        init(content: some View) {
            window = UIWindow(frame: CGRect(x: 0, y: 0, width: 400, height: 800))
            window.rootViewController = UIHostingController(rootView: content)
            window.makeKeyAndVisible()
        }

        func close() {
            window.isHidden = true
            window.rootViewController = nil
        }

        func render() {
            window.rootViewController?.view.setNeedsLayout()
            window.rootViewController?.view.layoutIfNeeded()
        }

        private let window: UIWindow
        #endif
    }
}
