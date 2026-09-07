# Consumer build tooling

SwiftLint runs as an explicit contributor command and CI check. The package has
no external dependencies or build-tool plugins.

On 2026-09-07, an isolated comparison of ColorKit `b54ca5a` with SwiftLintPlugins
0.65.1 against the same source without plugins produced these wall-clock timings:

| Workload | Samples per variant | With plugins, median (range) | Without plugins, median (range) |
| --- | ---: | ---: | ---: |
| Empty-cache resolution | 3 | 29.178s (23.951–29.780) | 1.612s (1.546–1.717) |
| Clean Debug build | 3 | 10.575s (10.533–11.156) | 7.182s (7.055–7.205) |
| Unchanged rebuild | 5 | 0.523s (0.353–0.542) | 0.369s (0.329–0.381) |
| Consumer edit rebuild | 5 | 0.796s (0.793–0.853) | 0.803s (0.795–0.812) |

The macOS SwiftPM consumer used Xcode 26.5, Swift 6.3.2, macOS 26.6.2, an M4 Pro
with 48 GiB RAM, and four compiler jobs. Three alternating pairs used isolated
package and build caches; two extra incremental pairs reused the third builds.
ColorKit came from local Git fixtures; SwiftLint's 76 MB download came from GitHub.
OS and network caches were uncontrolled. Resolution and clean-build savings were
clear; incremental ranges overlapped, so no steady-state speedup is established.

Xcode requested reapproval of the updated plugin. The plugin-free iOS consumer
built with validation enabled. First-install prompts on a clean account remain
unverified.

Validation passed: 652 iOS/macOS test executions, 13 tooling tests, strict lint
across 110 files, DocC with warnings as errors, 28 compiled public examples, and
six README runtime checks. Library sources, tests, and lint rules are unchanged.

The harness, raw samples, and detailed report are retained locally under
`.build/consumer-tooling-experiment`; validation logs are under
`.build/consumer-tooling-validation`. These are disposable experiment artifacts.
