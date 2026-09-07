---
status: accepted
---

# Preserve shipped client contracts through ColorKit 3.x

ColorKit 3.x preserves the source compatibility and documented behavior of its shipped public APIs, including deprecated declarations, previews, and theming; incompatible changes require a new major release. Although [ADR 0001](0001-preserve-legacy-color-comparison-through-2x.md) scheduled removal of `compare(with:)` for 3.0, that release shipped it, so the released contract takes precedence and the adapter remains protected through 3.x. A preserved 3.0.0 client fixture, supplemented by later release fixtures, API comparison, and behavioral contract tests, will provide evidence independent of examples that evolve with the current code; this decision makes no binary compatibility commitment.
