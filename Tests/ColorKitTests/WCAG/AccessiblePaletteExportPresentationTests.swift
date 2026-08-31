import SwiftUI
import XCTest

@testable import ColorKit

@MainActor
final class AccessiblePaletteExportPresentationTests: XCTestCase {
    // MARK: - Rendering

    func testHostedDemoRedrawsDoNotPrepareAgainOrChangeSharedFile() async throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        var preparations = 0
        let export = AccessiblePaletteExport(files: AccessiblePaletteExportFiles(root: root)) { _ in
            preparations += 1
            return Data("fixed payload".utf8)
        }
        let driver = RedrawDriver()
        var pending: XCTestExpectation? = expectation(description: "Initial render")
        let initial = try XCTUnwrap(pending)
        let host = Host(content: TestContent(export: export, driver: driver) {
            pending?.fulfill()
            pending = nil
        })
        defer { host.close() }
        await fulfillment(of: [initial], timeout: 5)
        XCTAssertEqual(preparations, 0)

        export.share(AccessiblePaletteExport.Snapshot(entries: [], name: "Prepared", format: .json))
        let item = try XCTUnwrap(export.shareItem)
        let redrawn = expectation(description: "Redraw while sharing")
        pending = redrawn
        driver.scheme = .dark
        await fulfillment(of: [redrawn], timeout: 5)

        XCTAssertEqual(preparations, 1)
        XCTAssertEqual(export.shareItem?.id, item.id)
        XCTAssertEqual(try Data(contentsOf: item.url), Data("fixed payload".utf8))

        export.shareItem = nil
        let dismissed = expectation(description: "Redraw after dismissal")
        pending = dismissed
        driver.scheme = .light
        await fulfillment(of: [dismissed], timeout: 5)

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
        let rendered: () -> Void

        var body: some View {
            AccessiblePaletteDemoView(export: export)
                .environment(\.colorScheme, driver.scheme)
                .onAppear(perform: rendered)
                .onChange(of: driver.scheme) { _ in rendered() }
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

        private let window: UIWindow
        #endif
    }
}
