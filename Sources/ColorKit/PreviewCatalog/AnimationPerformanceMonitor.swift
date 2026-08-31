import Combine
import Foundation

@MainActor
final class AnimationPerformanceMonitor: ObservableObject {
    @Published private(set) var frameCount = 0
    @Published private(set) var fps = 0.0
    private(set) var lastFrameTime = Date()
    private(set) var timer: Timer?
    private(set) var sessionID: UUID?

    init(now: @escaping () -> Date = Date.init) {
        self.now = now
    }

    func start(isAnimating: @escaping @MainActor () -> Bool) {
        guard timer == nil else { return }

        let sessionID = UUID()
        self.sessionID = sessionID
        frameCount = 0
        fps = 0
        lastFrameTime = now()
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] timer in
            guard let self else {
                timer.invalidate()
                return
            }
            self.enqueueTick(for: sessionID, isAnimating: isAnimating)
        }
    }

    func stop() {
        sessionID = nil
        timer?.invalidate()
        timer = nil
    }

    // Check the captured session after the actor hop: stop and restart may both
    // have happened since the timer fired. A Boolean would accept the old tick.
    @discardableResult
    nonisolated func enqueueTick(
        for sessionID: UUID,
        isAnimating: @escaping @MainActor () -> Bool
    ) -> Task<Void, Never> {
        Task { @MainActor [weak self] in
            guard let self, self.sessionID == sessionID, isAnimating() else { return }
            self.frameCount += 1
            let currentTime = self.now()
            self.fps = 1.0 / currentTime.timeIntervalSince(self.lastFrameTime)
            self.lastFrameTime = currentTime
        }
    }

    private let now: () -> Date
}
