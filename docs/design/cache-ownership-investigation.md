# Cache ownership investigation — 2026-10-01

Decision: retain the current implementation, including HSL caching in 3.x, and
clarify the public documentation. The measured costs and benefits depend on the
workload; no replacement has demonstrated simpler implementation with preserved
behavior and performance. This decision does not supersede the
[cache identity design](cache-identity.md) or
[3.x compatibility policy](release-client-compatibility.md).

## Scope and provenance

Question: what caching, if any, should ColorKit own, and can its implementation
become simpler without weakening correctness, compatibility, or performance?

The investigation used revision `1f9ddf0687bcac52afae60b4a1cc8dfa06168d42`, then
`origin/main`, and the published `v3.0.0` and `v3.2.0` contracts. It followed the
[north star](../NORTH_STAR.md), contributor guidance, domain documentation, and
existing cache and assessed-palette investigations. At the initial overlap check,
PR #86's assessed-palette investigation was merged at `64695f1`; the only open PR
was #82 for parallel CI validation. No duplicate cache investigation was found in
the inspected open issues, PRs, and recent chats.

Both experiments were agreed before execution and used isolated source copies.
Their reports preserve the protocols, results, validation, and limitations:

- [All-cache comparison](../validation/cache-ownership-performance-2026-10-01.md)
- [HSL-only comparison](../validation/hsl-cache-performance-2026-10-01.md)
- [Review evidence and reproduction](../validation/evidence/cache-2026-10-01/README.md)

## Shipped interface and terminology

`ColorCache.swift` is identical between `v3.0.0`, `v3.2.0`, and the inspected
revision. The five source files containing its six direct consumers are also
unchanged since `v3.2.0`.

The public class is final and `@unchecked Sendable`. It exposes `shared`, four
getter/insertion pairs (luminance, contrast, blended color, interpolated color),
six store-specific clears, and `clearCache()`. The initializer and HSL/LAB
getter/insertion pairs are internal. Ordinary clients cannot construct independent
instances. Public operations are synchronous and usable from nonisolated contexts.

**Automatic reuse** means storing and reusing ColorKit's computed results.
**Explicit insertion** means a caller supplying values through the public cache
writers. These use the same stores and keys; entries carry no provenance.
Replacing lookups with direct computation changes observable insertion behavior,
even if every declaration remains. Automatic population is also observable through
public getters, so removing automatic writes needs a behavioral review too.

An insertion is not a durable override: key eligibility, operation input
requirements, and eviction still apply. Deliberately ignoring an accepted,
still-present entry is nevertheless different from ordinary eviction. Existing
injection tests verify retrieval before checking consumers. Supplied values are
not authoritative color measurements.

**Candidate generation** selects or constructs colors, potentially using cached
values. **Authoritative measurement** independently assesses the resulting colors.
Independence of measurement does not imply independence of candidate selection.
These distinctions belong here; they introduce no new color-domain terminology
for the root glossary.

## Consumers and measurement

| Store | Direct read/write consumer | Observable propagation |
| --- | --- | --- |
| HSL | `Color+HSL.hslComponents()` | HSL conversion, adjustments, suggestions, generation, HSL interpolation, legacy comparison fallback |
| LAB | `Color+LAB.labComponents()` | Legacy LAB conversion, legacy perceptual distance, enhancement candidates, LAB interpolation |
| Luminance | `Color+WCAGCompliance.wcagRelativeLuminance()` | `relativeLuminance`, darkness/endpoint choices, `contrastRatio`, enhancement direction and theme/generation decisions |
| Contrast | `Color+WCAGCompliance.wcagContrastRatio(with:)` | Legacy compliance, endpoints, enhancement, suggestions, palette acceptance, unavailable-input legacy comparison fallback |
| Blended color | `Color+Blending.blended` | Full-strength blends and convenience methods; zero/partial amounts bypass this store |
| Interpolated color | `Color+Gradient.interpolated` | Interpolation and gradient construction; the operation clamps before cache access |

These are source traces, supported by the
[cache-boundary audit](../audits/cache-boundary-audit.md) and existing
`ColorCacheIntegrationTests`, not freshly executed tests of every wrapper.

`wcagContrastRatio` resolves both RGBA inputs and declines translucent pairs before
lookup. On a miss it computes directly from RGB without consuming the luminance
store. Conversely, `contrastRatio` uses the luminance store rather than the
contrast store. Accepted contrast insertion cannot bypass the opacity guard.

Strict contrast/luminance, authoritative comparison, component conversion results,
and `blendResult` compute independently of these stores. Budgeted enhancement uses
cache-influenced candidate search but independently checks strict contrast and
distance. `generateAssessedPalette` generates through the legacy generator and
then strictly assesses each returned color.

## Required behavior and implementation choices

Required identity behavior is specified in the cache identity design: original
supported space, complete finite component bits including alpha and signed zero,
exact finite interpolation amount, contrast symmetry, ordered blend/interpolation
operands, and exact operation-name strings. Unsupported, unresolved, or nonfinite
key inputs miss and skip insertion. Recognition covers five named RGB and four
named grayscale spaces, checking actual space equality and component layout.
Identity construction performs no color conversion.

Implementation choices include hexadecimal string keys, temporary arrays and
joined strings, pair sorting for contrast, and six separate `NSCache` stores.
A miss followed by insertion reconstructs the key. LAB/HSL values use `NSArray`,
scalars use `NSNumber`, and colors use `NSColor` or `UIColor` created from a result
CGColor. Color insertion can fail if that representation is unavailable. Scalar
payloads are not range/finite validated; key validation is a separate concern.

Each store sets `countLimit = 100`, with no cost accounting, TTL, custom eviction,
or public tuning. Apple's [countLimit documentation](https://developer.apple.com/documentation/foundation/nscache/countlimit)
makes this advisory, not a strict 600-entry or byte-budget promise.
[NSCache](https://developer.apple.com/documentation/foundation/nscache) provides
concurrent add/remove/query without caller locking and automatic eviction.

Lookup–compute–insert is not a transaction: concurrent misses can recompute, and
an in-flight operation can insert after a clear. Global clear visits six stores
sequentially, not atomically. Store-specific clears preserve other stores in
sequential use. Thread safety does not promise deterministic concurrent write
ordering or a barrier that leaves the cache empty after ongoing work finishes.
No race, contention cost, or memory-pressure defect was demonstrated here.

## Evidence and remaining uncertainty

The [September 30 report](../validation/assessed-palette-performance-2026-09-30.md)
showed lower complete assessed-palette request costs with primed caches. Both
empty and primed modes still construct keys, look up and write entries, and can
reuse values within a request. That comparison could not establish the total
benefit of caching versus direct computation.

The first controlled comparison added that baseline. Across 24,000 requests,
all-cache bypass lowered medians for the selected five- and eight-entry palettes
in both preparations, with matching ordered outputs, assessments, and final RNG
state. It intentionally broke public insertion/population behavior and was not a
compatible implementation proposal. It did not attribute costs to specific stores.

### HSL-only reuse

The follow-up isolated HSL because `hslComponents()` is its sole production reader
and writer, with internal cache accessors. Its public conversion and shipped
`clearHSLCache()` still constrain policy changes. Internal injection/population
assertions through `@testable` observe additional implementation details; they
must not be edited merely to make a diagnostic prototype appear release-ready.

Across 36,000 requests, HSL bypass improved empty five-entry palettes by 8.876
microseconds and eight-entry palettes by approximately 128–134 microseconds.
It slowed primed five-entry palettes by 2.539 microseconds (8.5%) and primed
fixed-red HSL conversion by 0.269 microseconds (27.1%). All three run medians
agreed on each direction. The report gives sample ranges, overlapping cases,
correctness checks, and compiler differences. The small absolute conversion cost
does not establish an application problem.

The results support retaining HSL reuse: removal is not a uniform performance
improvement, and no caller workload or budget justifies the measured trade-off.
They do not justify adding a hybrid policy to capture both outcomes.

Key allocation, repeated identity construction, bridging, and synchronization
remain plausible costs, not individually measured bottlenecks. No allocation,
retained-memory, CPU-time, contention, iOS, or UI-responsiveness measurements were
collected. Selected fixed inputs and seeds do not establish performance across
all consumers. No application invocation rate or latency requirement was provided.

## Alternatives and decision

| Direction | Benefit | Constraint or unresolved cost |
| --- | --- | --- |
| Retain current implementation — selected | Preserves shipped behavior; zero configuration; exact identity; platform-managed storage; measured repeated-HSL benefit | Public insertion adds behavioral complexity; performance depends on workload |
| Simplify internals within 3.x | Could remove demonstrated overhead without migration | Must preserve getters, writes, eligibility, clears, identity, and synchronous access; no specific rewrite justified yet |
| Make reuse internal in a deliberate major release | Could reduce caller knowledge and remove insertion as a customization mechanism | Requires source and behavioral migration; global, request-local, selective, and absent reuse remain unselected |

The current implementation centralizes identity and storage and keeps strict
measurement independent. Its demonstrated weaknesses are the behavioral
complexity of public insertion, shared state requiring serialized integration
tests, and overhead in the measured palette workloads. The earlier opacity bypass
was a real defect already corrected before this investigation.

The smallest change is documentation: qualify numerical equivalence as applying
to ordinary automatic reuse, distinguish explicit insertion from measurement,
and explain advisory retention and concurrent clearing. Preserve the implementation
and all shipped 3.x behavior. No new settings, replacement API, or ADR is needed.

The agreed future ownership direction is that callers request color operations
and ColorKit manages reuse where evidence justifies it. Public insertion that
influences operations is not part of that intended future interface. This is not
a scheduled major release or an approved removal. Whether explicit clearing is
needed in that interface also remains unresolved.

## Follow-ups and verification

No further benchmark campaign or cache rewrite is scheduled. Reopen a narrow
internal improvement only for a concrete caller workload or budget, agreeing on
the smallest complete-operation experiment before running it.

Any implementation proposal must preserve exact identity, public insertion and
getter observations, clearing, and synchronous use. Verification must cover both
platform storage paths, serialized insertion/clear integration tests, strict
measurement and palette replay, release-client/API checks, and affected complete
operations. Current frozen client fixtures do not explicitly exercise ColorCache;
API comparison and behavioral tests protect different parts of its contract.

If a substantial need justifies a deliberate major release, revisit insertion and
clearing with migration guidance. General cache simplification alone does not
justify a breaking release.

For this documentation delivery, macOS DocC built with warnings as errors;
the generated cache section and anchor were checked. The documentation checker
passed 17 executed public examples, palette replay across two processes, and
generated theme compilation. SwiftLint, local-link/resource, and whitespace
checks passed. Evidence archive hashes, the sole metadata redaction, reconstructed
source hashes, cross-variant diagnostics, and reported medians were verified
without rerunning measurements. Full behavioral and compatibility suites were
not rerun locally for the documentation changes.

Compact review archives include samples, prototype patches, reproduction scripts,
hashes, and compiler excerpts. Only the unrelated desktop process inventory is
redacted. Full original artifacts and build products remain outside the checkout;
archived prototypes are outside production targets. Production Swift source,
release metadata, and frozen fixtures remain unchanged.
