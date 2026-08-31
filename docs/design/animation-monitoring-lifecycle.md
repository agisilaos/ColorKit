# F14 — Animation preview monitoring lifecycle

Status: implemented. Focused automated checks pass on macOS and iOS; validation results and manual-check limits are recorded below.

## Agreed scope

- Give each `ColorAnimationPreview` instance ownership of zero or one repeating monitoring timer.
- Make startup idempotent and clean up monitoring on disappearance.
- Prevent callbacks queued before cancellation from changing metrics after cancellation, including after a subsequent appearance.
- Reset metrics for each new animation monitoring session; duplicate startup within a session does not reset anything.
- Preserve animation behavior, the iOS 14 and macOS 12 deployment targets, and the existing monitoring cadence and FPS calculation.
- Do not introduce a scheduler framework or redesign FPS measurement.
- Keep monitoring tied to appearance and disappearance. Animation activity gates metric updates; the metrics toggle controls display only.
- Keep app-background and scene-phase handling outside F14.

## Existing behavior being corrected

Before F14, `ColorAnimationPreview` started an unretained repeating timer on every appearance, with no disappearance cleanup. Each tick created a main-actor task that updated metrics only when `isAnimating` was true. The performance-metrics toggle controlled visibility only; that behavior is preserved.

The current 0.1-second timer increments `frameCount` once per accepted monitoring tick and computes `fps` as the reciprocal of the elapsed time since the previous accepted tick. These values are not measurements of rendered frames. F14 preserves this calculation and the existing labels.

## Ownership and isolation

- Use a small internal `@MainActor` monitoring object, conforming to `ObservableObject`, owned by each preview through `@StateObject`.
- The object owns the optional timer, current session identity, `frameCount`, `fps`, and timestamp baseline. Publish the displayed metrics so the performance section updates.
- A new owner is inactive. Constructing the owner or evaluating the view body does not schedule a timer; appearance calls start and disappearance calls stop.
- Each preview owns its own monitor. There is no singleton or shared timer, and repeated view evaluation preserves the owner for the same view identity.
- Start, stop, and metric mutations run on the main actor. Callback acceptance and its metric updates form one synchronous operation with no suspension between the checks and updates.
- Avoid strong retention cycles through timer callbacks, queued tasks, or callbacks that read animation state. Use weak owner captures where needed, and verify release after disappearance and teardown.
- Keep implementation details internal. Do not add a public lifecycle/testing API, a dependency, a scheduler framework, or unchecked concurrency annotations to silence diagnostics. Preserve the package's existing toolchain and deployment requirements.

## Lifecycle contract

At lifecycle method boundaries, an inactive monitor has no owned timer and no current session identity. An active monitor has exactly one timer and one session identity.

| Event | Required result |
| --- | --- |
| Start while inactive | Create a fresh session identity, reset `frameCount` and `fps` to zero, set the timestamp baseline to the start time, and retain one repeating timer. |
| Start while active | No operation: retain the same timer and session identity, without changing metrics or the timestamp baseline. |
| Stop while active | Clear the session identity, invalidate the timer, and release the timer reference before returning. Leave metric values frozen until the next accepted start. |
| Stop while inactive | No operation; do not reset metrics or change animation state. |
| Re-entry after stop | Start a fresh session and timer, regardless of whether SwiftUI retained the previous owner or created a new one. |

Clearing the session identity happens before invalidating and releasing the timer. Disappearance calls stop synchronously on the main actor; cleanup is not deferred to another task.

## Queued callbacks after cancellation

- Each timer's callback captures the identity of the session that created it. That captured identity must not be replaced by the latest identity when queued work eventually executes.
- After reaching the main actor, a callback may update metrics only if its captured identity is still the current active session and animation is currently running.
- A callback from session A must be ignored both after A stops and after session B starts. An `isMonitoring` Boolean alone cannot distinguish A from B.
- Rejected callbacks change nothing: no frame increment, FPS update, or timestamp update.
- Timer invalidation stops future timer activity; the session check protects against work already queued. Task cancellation alone is not the correctness mechanism, and F14 need not maintain a collection of per-tick task handles.
- A callback that completed before stop may have updated metrics; stop does not undo completed work. Once stop returns, work from that session cannot change metrics.

## Metrics and animation behavior

- Keep the repeating interval at 0.1 seconds and preserve the existing scheduled timer's run-loop behavior.
- For an accepted tick while animating, increment the count once, read the current time at processing, calculate `fps = 1.0 / elapsedTime`, and update the timestamp baseline.
- Ticks while animation is stopped leave all metrics, including the timestamp baseline, unchanged. Preserve the existing treatment of idle time within a visit; do not add resets on animation start, stop, or resume as part of F14.
- A new visit resets the timestamp baseline, so time spent away does not enter its first sample.
- The animation gate must reflect the view's current `isAnimating` value when queued work executes, rather than a snapshot taken when the timer was created.
- Keep animation state and actions in the view. Do not change color selection, interpolation choices, duration, easing, repeat/autoreverse behavior, or the stop animation action.
- Monitoring lifecycle methods do not change `isAnimating` or force animation to stop or restart. Preserve SwiftUI's existing view-identity behavior rather than adding persistence across destroyed views.
- Hiding or showing metrics does not start, stop, or reset monitoring. Preserve the displayed labels and formatting.

## Focused automated validation

Use the repository's XCTest conventions and fresh monitor instances. Exercise the production lifecycle and callback acceptance path through a narrow internal seam with explicit timestamps and controllable callback delivery. Do not build a general scheduler abstraction, use a separate test-only state machine, or rely on sleeps and exact wall-clock firing counts.

1. **Ownership and idempotency:** a new owner has no timer; start twice retains the same single valid timer and session. Deliver an accepted sample before the second start and verify that its count, FPS, and timestamp are not reset. Stop twice leaves no timer or active session. Retain a test reference to the original real timer and assert that it is invalidated, not merely discarded by the owner.
2. **Fresh metrics on re-entry:** accumulate metrics, stop, and start at a controlled later time. Assert a new timer and session, zero count/FPS, and a fresh baseline. Deliver a current-session sample and verify the unchanged reciprocal-elapsed-time calculation excludes the previous visit and time away.
3. **Cancellation before queued delivery:** retain work from session A, stop A, then deliver it. Assert that every metric and the baseline remain unchanged.
4. **Cancellation followed by restart:** retain work from A, stop A, start B, and then deliver A's work while animation is running. Assert that B's metrics and baseline remain unchanged. Deliver B's work and verify one accepted update. Exercise delayed delivery through the same main-actor boundary used by production, with explicit completion coordination instead of sleeps.
5. **Animation gating:** verify that a current-session callback does nothing while animation is stopped, including when animation stops after the callback is queued. Resume animation within the same session and confirm the existing count and timestamp behavior are preserved.
6. **Instance independence and release:** start two monitors; stopping or restarting one does not affect the other. After disappearance cleanup and release of the owner, verify no callback retention cycle keeps it alive and its real timer remains invalidated.

## Hosted-view and manual validation

- Add a hosted-view check using the actual preview and an internal observation/injection seam if needed. Mount it, cause an unrelated redraw, and remove it. Observe that appearance starts one timer, redraw preserves that timer and owner, and disappearance invalidates and clears it. Calling helper methods directly does not substitute for this wiring check.
- Exercise appearance again after disappearance, including a retained owner, to prove the reset policy is not merely a consequence of constructing a new object.
- Run the focused automated checks on macOS and iOS Simulator using the existing test tooling. Build with the unchanged iOS 14 and macOS 12 minimum targets; inspect availability and strict concurrency diagnostics without raising those targets or changing concurrency settings to make the build pass.
- On both platforms, manually enter and leave the preview repeatedly, including while animating. Show and hide metrics, start and stop animation, change duration, and exercise RGB/HSL/LAB choices. Verify the agreed lifecycle behavior and unchanged controls and visual behavior. Do not assert that this timer-derived FPS matches display refresh rate.
- Record actual test/build results, manual observations, and any unavailable environment during implementation. The accepted validation plan is not evidence that these checks have passed.

## Documentation boundary

The domain glossary defines an animation monitoring session. This note holds the lifecycle and implementation decisions. No ADR is needed for this localized, reversible change.

## Validation results — 2026-08-31

- Xcode 26.5: all nine focused tests passed on macOS 26.5.2 and an iPhone 17 simulator running iOS 26.5. Each run includes eight monitor tests and one hosted-view lifecycle test.
- `swiftlint lint --strict --quiet` and `git diff --check` passed. The hosted test uses the older `onChange` overload to retain minimum-OS compatibility; its deprecation warning does not require a deployment-target change. No new concurrency warnings remain.
- Temporary native harness apps outside the repository built successfully against this checkout with iOS 14 and macOS 12 minimum targets. These are compile/availability checks, not runs on those older OS versions.
- On both platforms, native checks confirmed that samples advance during animation even with metrics hidden, freeze after animation stops or the preview disappears, and reset to zero on re-entry with the same monitor retained. Timer invalidation itself is asserted by the automated tests, not inferred from frozen UI values.
- macOS checks also exercised RGB/HSL/LAB selection, animation start/stop, and duration changes. iOS checks exercised RGB animation and metrics visibility; HSL/LAB selection and duration behavior were not fully verified because the UI driver could not reliably target those controls. Source comparison confirms that the animation action and controls were left unchanged.
- Native lifecycle checks removed and restored the actual preview in a temporary host; catalog navigation was not independently exercised. The existing complete repository test suite was not rerun for this localized change.
- The first iOS hosted run exposed duplicate fulfillment of a lifecycle expectation. The test now consumes each pending observation once, tolerating repeated SwiftUI lifecycle callbacks. Both platform runs passed after that correction. Real timers in unit tests have automatic firing deferred; explicit callback delivery and task completion make the assertions independent of wall-clock scheduling.

Reproduce the focused runs from the repository root:

```sh
scripts/run_tests.sh --log-file /tmp/colorkit-f14-macos.log \
  macOS 'platform=macOS' \
  -only-testing:ColorKitTests/AnimationPerformanceMonitorTests \
  -only-testing:ColorKitTests/AnimationPreviewLifecycleTests \
  -parallel-testing-enabled NO -skipPackagePluginValidation -skipMacroValidation
scripts/run_tests.sh --log-file /tmp/colorkit-f14-ios.log \
  iOS 'platform=iOS Simulator,name=iPhone 17,OS=26.5' \
  -only-testing:ColorKitTests/AnimationPerformanceMonitorTests \
  -only-testing:ColorKitTests/AnimationPreviewLifecycleTests \
  -parallel-testing-enabled NO -skipPackagePluginValidation -skipMacroValidation
```
