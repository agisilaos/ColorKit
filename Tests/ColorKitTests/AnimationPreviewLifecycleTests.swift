import SwiftUI
import XCTest

@testable import ColorKit

@MainActor
final class AnimationPreviewLifecycleTests: XCTestCase {
    func testAppearanceRedrawDisappearanceAndReentryUseOneTimerPerVisit() async throws {
        let monitor = AnimationPerformanceMonitor()
        let state = AnimationPreviewLifecycleState()
        let appeared = expectation(description: "Preview appeared")
        state.onAppear = { appeared.fulfill() }
        let host = ThemeTestHost(rootView: AnimationPreviewLifecycleHarness(monitor: monitor, state: state))
        defer {
            host.close()
            monitor.stop()
        }
        await fulfillment(of: [appeared], timeout: 3)
        let firstTimer = try XCTUnwrap(monitor.timer)
        let firstSession = try XCTUnwrap(monitor.sessionID)
        await monitor.enqueueTick(for: firstSession, isAnimating: { true }).value
        XCTAssertEqual(monitor.frameCount, 1)

        let redrawn = expectation(description: "Preview redrawn")
        state.onRedraw = { redrawn.fulfill() }
        state.redraw += 1
        await fulfillment(of: [redrawn], timeout: 3)
        XCTAssertTrue(monitor.timer === firstTimer)
        XCTAssertEqual(monitor.sessionID, firstSession)
        XCTAssertEqual(monitor.frameCount, 1)

        let disappeared = expectation(description: "Preview disappeared")
        state.onDisappear = { disappeared.fulfill() }
        state.isVisible = false
        await fulfillment(of: [disappeared], timeout: 3)
        XCTAssertFalse(firstTimer.isValid)
        XCTAssertNil(monitor.timer)
        XCTAssertNil(monitor.sessionID)

        let reappeared = expectation(description: "Preview reappeared")
        state.onAppear = { reappeared.fulfill() }
        state.isVisible = true
        await fulfillment(of: [reappeared], timeout: 3)
        XCTAssertNotEqual(monitor.sessionID, firstSession)
        XCTAssertFalse(monitor.timer === firstTimer)
        XCTAssertTrue(try XCTUnwrap(monitor.timer).isValid)
        XCTAssertEqual(monitor.frameCount, 0)
        XCTAssertEqual(monitor.fps, 0)
    }
}

@MainActor
private final class AnimationPreviewLifecycleState: ObservableObject {
    @Published var isVisible = true
    @Published var redraw = 0
    // Observe each transition once, even if SwiftUI repeats a lifecycle callback.
    var onAppear: (() -> Void)?
    var onDisappear: (() -> Void)?
    var onRedraw: (() -> Void)?
}

private struct AnimationPreviewLifecycleHarness: View {
    let monitor: AnimationPerformanceMonitor
    @ObservedObject var state: AnimationPreviewLifecycleState

    var body: some View {
        if state.isVisible {
            ColorAnimationPreview(monitor: monitor)
                .padding(CGFloat(state.redraw))
                .onAppear {
                    state.onAppear?()
                    state.onAppear = nil
                }
                .onDisappear {
                    state.onDisappear?()
                    state.onDisappear = nil
                }
                .onChange(of: state.redraw) { _ in
                    state.onRedraw?()
                    state.onRedraw = nil
                }
        }
    }
}
