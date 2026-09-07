# Release client compatibility

Status: implemented; see [the checker and coverage guide](../../Compatibility/README.md).

## Problem

`scripts/check_documentation.py` extracts examples from the current checkout and typechecks them against the current ColorKit module on macOS. API declarations and examples can change together while an older client stops compiling. Before this change, CI ran iOS and macOS tests but had no release-baseline API comparison.

The initial release baseline is `v3.0.0`, commit `b54ca5adfc80290003c543a23483503d1c5f4d4b`. Its migration guide records concrete source breaks from earlier releases: changes to full enhancement method references and additions to exhaustively switched result statuses.

## Accepted decisions

### Compatibility promise

Existing clients must continue to compile and retain documented behavior throughout ColorKit 3.x. Incompatible API or documented-behavior changes require a new major release. This work covers source and behavioral compatibility; binary compatibility requires a separate commitment.

### Public surface

Protect every shipped public API, including deprecated declarations, previews, and theming. Combine representative client fixtures with API comparison across the module. The release's actual public surface governs protection: `compare(with:)` shipped in 3.0.0 and remains protected through 3.x, as recorded in [ADR 0013](../adr/0013-preserve-shipped-3x-client-contracts.md).

### Preserved client source

First prove that the original client fixture compiles against the exact 3.0.0 release. Preserve that client source unchanged when compiling it against future ColorKit revisions; changing a failing client to match a changed API would erase the evidence this check exists to retain.

Extend coverage with separate fixtures that also compile against their claimed release. Later releases add protection for newly introduced APIs. Initial coverage includes method references, exhaustive switches, public initializers, and representative workflows.

### Initial toolchain and platforms

Use the existing pinned CI toolchain, Xcode 26.5, for the first milestone on iOS and macOS. Compile clients at the package's declared minimum deployment targets, iOS 14 and macOS 12. The package declares Swift tools 6.0; the local Xcode 26.5 installation reports Swift 6.3.2.

An oldest-supported-compiler matrix remains a separate scope decision. Compiling at a minimum deployment target does not establish runtime coverage on that OS version.

### API baseline generation

Build the exact release baseline and the candidate revision using the same compiler, platform SDK, and build settings, then compare their generated public API inventories. Keep the release commit and preserved client source fixed. When the CI toolchain changes, regenerate both inventories with that toolchain.

Rebuild release inventories on every run. The initial cache design was removed to simplify the implementation; no cache validation or invalidation machinery is needed. This comparison controls for tooling differences when checking ColorKit changes; verification with older compilers remains separate. If a future toolchain cannot build the original release, the check fails and the failure must be investigated before accepting that toolchain upgrade.

### Behavioral corrections

A numerical bug fix may change a released result in a patch release when evidence establishes that it restores the documented contract. Preserve observable promises, including unavailable outcomes, fallback semantics, distance limits, and ordering, using focused assertions and justified numerical tolerances. Review and document each correction; updating an expected value alone does not justify a changed result.

### CI and release enforcement

Compatibility checks must block every non-draft PR and release preflight when client compilation fails, behavioral contracts regress, an API break is detected, or the checks cannot complete. Compatible additions and deprecation warnings remain allowed.

### Diagnostic exceptions

A checker false positive may receive a narrowly documented exception only with a reproducer demonstrating that the client remains compatible, an exact diagnostic match, and a written reason. Genuine source breaks require a major release.

### Client contexts

Use public imports and cover ordinary nonisolated color operations alongside appropriately isolated theme and UI workflows. Preserve typed and inferred method references. The existing documentation checker wraps all examples in `@MainActor`; the release fixtures must retain the distinct caller contexts needed to expose newly imposed actor requirements.

### Behavioral coverage and detection evidence

Map existing behavioral tests to the protected promises and add assertions for concrete gaps. Before delivery, temporarily introduce representative method-signature, enum-case, initializer, and behavioral regressions to establish that the checks detect them. Keep this a bounded verification exercise.
