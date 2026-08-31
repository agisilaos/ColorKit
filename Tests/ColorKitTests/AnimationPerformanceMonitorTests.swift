import Combine
import XCTest

@testable import ColorKit

@MainActor
final class AnimationPerformanceMonitorTests: XCTestCase {
    // Keep real timers for invalidation checks, but deliver ticks explicitly.
    // Moving fireDate prevents automatic firings from racing async assertions.
    func testStartAndStopAreIdempotentAndInvalidateTheOwnedTimer() async throws {
        var now = Date(timeIntervalSinceReferenceDate: 100)
        let monitor = AnimationPerformanceMonitor(now: { now })
        XCTAssertNil(monitor.timer)
        XCTAssertNil(monitor.sessionID)

        monitor.start { true }
        monitor.timer?.fireDate = .distantFuture
        defer { monitor.stop() }
        let timer = try XCTUnwrap(monitor.timer)
        let session = try XCTUnwrap(monitor.sessionID)
        XCTAssertTrue(timer.isValid)
        XCTAssertEqual(timer.timeInterval, 0.1)

        now.addTimeInterval(0.25)
        await monitor.enqueueTick(for: session, isAnimating: { true }).value
        monitor.start { false }
        monitor.timer?.fireDate = .distantFuture
        XCTAssertTrue(monitor.timer === timer)
        XCTAssertEqual(monitor.sessionID, session)
        assertMetrics(monitor, count: 1, fps: 4, time: now)

        monitor.stop()
        monitor.stop()
        XCTAssertFalse(timer.isValid)
        XCTAssertNil(monitor.timer)
        XCTAssertNil(monitor.sessionID)
        assertMetrics(monitor, count: 1, fps: 4, time: now)
    }

    func testRestartResetsMetricsAndExcludesTimeAway() async throws {
        var now = Date(timeIntervalSinceReferenceDate: 100)
        let monitor = AnimationPerformanceMonitor(now: { now })
        monitor.start { true }
        monitor.timer?.fireDate = .distantFuture
        defer { monitor.stop() }
        let oldTimer = try XCTUnwrap(monitor.timer)
        let oldSession = try XCTUnwrap(monitor.sessionID)
        now.addTimeInterval(0.5)
        await monitor.enqueueTick(for: oldSession, isAnimating: { true }).value
        assertMetrics(monitor, count: 1, fps: 2, time: now)
        monitor.stop()

        now.addTimeInterval(100)
        monitor.start { true }
        monitor.timer?.fireDate = .distantFuture
        let session = try XCTUnwrap(monitor.sessionID)
        XCTAssertNotEqual(session, oldSession)
        XCTAssertFalse(monitor.timer === oldTimer)
        XCTAssertFalse(oldTimer.isValid)
        assertMetrics(monitor, count: 0, fps: 0, time: now)

        now.addTimeInterval(0.25)
        await monitor.enqueueTick(for: session, isAnimating: { true }).value
        assertMetrics(monitor, count: 1, fps: 4, time: now)
    }

    func testQueuedTickAfterStopCannotChangeAnyMetric() async throws {
        var now = Date(timeIntervalSinceReferenceDate: 100)
        let monitor = AnimationPerformanceMonitor(now: { now })
        monitor.start { true }
        monitor.timer?.fireDate = .distantFuture
        let session = try XCTUnwrap(monitor.sessionID)
        let baseline = now

        // This task cannot reach the main actor until the test suspends below.
        let queuedTick = monitor.enqueueTick(for: session, isAnimating: { true })
        monitor.stop()
        now.addTimeInterval(5)
        await queuedTick.value
        assertMetrics(monitor, count: 0, fps: 0, time: baseline)
    }

    func testQueuedTickFromOldSessionCannotChangeRestartedSession() async throws {
        var now = Date(timeIntervalSinceReferenceDate: 100)
        let monitor = AnimationPerformanceMonitor(now: { now })
        monitor.start { true }
        monitor.timer?.fireDate = .distantFuture
        defer { monitor.stop() }
        let oldSession = try XCTUnwrap(monitor.sessionID)
        let queuedTick = monitor.enqueueTick(for: oldSession, isAnimating: { true })
        monitor.stop()
        now.addTimeInterval(10)
        monitor.start { true }
        monitor.timer?.fireDate = .distantFuture
        let baseline = now
        now.addTimeInterval(0.5)

        await queuedTick.value
        assertMetrics(monitor, count: 0, fps: 0, time: baseline)
        let session = try XCTUnwrap(monitor.sessionID)
        await monitor.enqueueTick(for: session, isAnimating: { true }).value
        assertMetrics(monitor, count: 1, fps: 2, time: now)
    }

    func testAnimationGateIsReadAfterQueueingAndPreservesIdleTime() async throws {
        var now = Date(timeIntervalSinceReferenceDate: 100)
        let animation = AnimationGate()
        let monitor = AnimationPerformanceMonitor(now: { now })
        monitor.start { animation.isAnimating }
        monitor.timer?.fireDate = .distantFuture
        defer { monitor.stop() }
        let session = try XCTUnwrap(monitor.sessionID)
        let baseline = now
        let queuedTick = monitor.enqueueTick(for: session, isAnimating: { animation.isAnimating })
        animation.isAnimating = false
        now.addTimeInterval(2)
        await queuedTick.value
        assertMetrics(monitor, count: 0, fps: 0, time: baseline)

        animation.isAnimating = true
        now.addTimeInterval(2)
        await monitor.enqueueTick(for: session, isAnimating: { animation.isAnimating }).value
        assertMetrics(monitor, count: 1, fps: 0.25, time: now)
        XCTAssertEqual(monitor.sessionID, session)
    }

    func testStoppingOneMonitorDoesNotAffectAnother() async throws {
        var now = Date(timeIntervalSinceReferenceDate: 100)
        let first = AnimationPerformanceMonitor(now: { now })
        let second = AnimationPerformanceMonitor(now: { now })
        first.start { true }
        first.timer?.fireDate = .distantFuture
        second.start { true }
        second.timer?.fireDate = .distantFuture
        defer {
            first.stop()
            second.stop()
        }
        let secondTimer = try XCTUnwrap(second.timer)
        let secondSession = try XCTUnwrap(second.sessionID)

        first.stop()
        first.start { true }
        first.timer?.fireDate = .distantFuture
        now.addTimeInterval(0.5)
        await second.enqueueTick(for: secondSession, isAnimating: { true }).value
        XCTAssertTrue(second.timer === secondTimer)
        XCTAssertTrue(secondTimer.isValid)
        XCTAssertEqual(second.sessionID, secondSession)
        assertMetrics(first, count: 0, fps: 0, time: now.addingTimeInterval(-0.5))
        assertMetrics(second, count: 1, fps: 2, time: now)
    }

    func testTimerCallbackPublishesMetricsUsingCurrentAnimationState() async throws {
        var now = Date(timeIntervalSinceReferenceDate: 100)
        let animation = AnimationGate()
        animation.isAnimating = false
        let monitor = AnimationPerformanceMonitor(now: { now })
        monitor.start { animation.isAnimating }
        monitor.timer?.fireDate = .distantFuture
        defer { monitor.stop() }
        let timer = try XCTUnwrap(monitor.timer)
        let published = expectation(description: "Timer callback publishes FPS")
        let subscription = monitor.$fps.dropFirst().sink { fps in
            if fps == 4 { published.fulfill() }
        }
        defer { subscription.cancel() }

        animation.isAnimating = true
        now.addTimeInterval(0.25)
        timer.fire()
        await fulfillment(of: [published], timeout: 3)
        assertMetrics(monitor, count: 1, fps: 4, time: now)
    }

    func testStoppedMonitorIsReleasedEvenWithQueuedWorkAndRetainedTimer() async throws {
        var monitor: AnimationPerformanceMonitor? = AnimationPerformanceMonitor()
        monitorUnderLifetimeTest = monitor
        monitor?.start { true }
        monitor?.timer?.fireDate = .distantFuture
        let timer = try XCTUnwrap(monitor?.timer)
        let session = try XCTUnwrap(monitor?.sessionID)
        let queuedTick = monitor?.enqueueTick(for: session, isAnimating: { true })

        monitor?.stop()
        monitor = nil
        XCTAssertNil(monitorUnderLifetimeTest)
        XCTAssertFalse(timer.isValid)
        await queuedTick?.value
        XCTAssertNil(monitorUnderLifetimeTest)
    }

    private weak var monitorUnderLifetimeTest: AnimationPerformanceMonitor?

    @MainActor
    private final class AnimationGate {
        var isAnimating = true
    }

    private func assertMetrics(
        _ monitor: AnimationPerformanceMonitor,
        count: Int,
        fps: Double,
        time: Date,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        XCTAssertEqual(monitor.frameCount, count, file: file, line: line)
        XCTAssertEqual(monitor.fps, fps, accuracy: 1e-12, file: file, line: line)
        XCTAssertEqual(monitor.lastFrameTime, time, file: file, line: line)
    }
}
