# ColorKit north star

Help SwiftUI developers understand, assess, and improve color accessibility and expression through focused, simple, dependable APIs.

## Focus is a hard constraint

Every addition must answer:

- **Why now?** Which concrete developer problem does it solve?
- **Why ColorKit?** How does it serve color understanding, assessment, transformation, or accessible choices?
- **Why new API?** Why are existing capabilities or a checked example insufficient?
- **What is the smallest solution?** What stays out, and when is the work done?
- **How will we verify it?** Show clear call sites, discoverable guidance, correctness and compatibility checks, and performance evidence where relevant.

If those answers are weak, defer the proposal. A release does not need more features merely because it has room. Avoid speculative abstractions, redundant convenience APIs, and optimizations without evidence.

## Help developers make informed choices

Color accessibility is central: contrast assessment, explicit foreground/background context, bounded adjustments, palette assessment, color-vision deficiency simulation, and useful explanations.

Assessments explain rather than silently change colors. Explicitly requested adjustments suggest candidates; developers decide what to apply. Best effort is not a guaranteed pass, and unavailable measurements are not fabricated values. Correctness and honest limitations take priority over convenience or speed; optimize within the contract.

For now, general VoiceOver tooling, focus management, Dynamic Type systems, and whole-app accessibility certification are outside the library's scope. ColorKit's own controls and examples must still be accessible. Revisit this boundary only for a concrete, justified need.

Themes, previews, and export support the core color workflows. They are not a mandate to build a full design-system framework, graphics editor, general export platform, or professional print color-management engine. Existing shipped features remain supported.

## Stability is part of simplicity

Minor and patch releases should require no migration by default. Preserve existing calls, defaults, and documented behavior; avoid routine deprecation warnings and replacement APIs introduced merely for stylistic consistency.

Breaking changes must solve a substantial problem that cannot reasonably be addressed compatibly. Consolidate necessary migrations into deliberate major releases with clear guidance. Document justified corrections to documented behavior and their observable effects; this is not permission to silently change contracts. Follow [ADR 0013](adr/0013-preserve-shipped-3x-client-contracts.md) and the [compatibility policy](design/release-client-compatibility.md).

Good Swift API design, discoverability, and measured performance are part of the feature—not optional cleanup after it ships.
