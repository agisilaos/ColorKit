# Cache ownership investigation — 2026-10-01

Status: agreed direction after two approved bounded experiments: retain the current
implementation, including HSL caching in 3.x, and clarify the documentation. No
production implementation change is approved. This note records evidence and decisions;
it does not supersede the accepted cache identity design or ADR 0013.

## Scope and provenance

Question: what caching, if any, should ColorKit own, and can its implementation
become simpler without weakening correctness, compatibility, or performance?

Inspected revision: `1f9ddf0687bcac52afae60b4a1cc8dfa06168d42`, fetched
`origin/main`, on `chore/cache-design-investigation`. The checkout was clean before
this note. Read AGENTS.md, NORTH_STAR.md, CONTRIBUTING.md, the agent domain/tracker
guides, CONTEXT.md, ADR 0013, the release-client compatibility design and coverage,
the cache identity design, the cache audit, and the assessed-palette report.

Live overlap check: no open issues; open PR #82 concerns parallel CI validation.
PR #86 is merged at `64695f1`; its chat is preserving evidence and cleaning up.
No second palette investigation or production cache rewrite was found in the
inspected open PRs and recent chats. This is a bounded inventory, not a claim about
unobserved work.

## Shipped interface

The latest published release is `v3.2.0`. `ColorCache.swift` is identical between
`v3.0.0`, `v3.2.0`, and the inspected revision. The six direct consumer files
listed below are also unchanged since `v3.2.0`.

The public class is final and `@unchecked Sendable`. Its interface includes
`shared`, four getter/insertion pairs (luminance, contrast, blended color,
interpolated color), six store-specific clears, and `clearCache()`.
The initializer and HSL/LAB getter/insertion pairs are internal. Ordinary clients
cannot construct independent instances. Public operations remain synchronous and
usable from nonisolated contexts.

Automatic writes and explicit caller writes use the same stores and keys; entries
carry no provenance. Consequently, replacing every lookup with direct computation
would change observable behavior even if every declaration remained. Automatic
population is also observable through the public getters. Removing automatic
writes while retaining explicit reads therefore needs a behavioral review too.

An insertion is not a durable override: eligibility and eviction still apply.
Nevertheless, deliberately ignoring an accepted, still-present entry is not
equivalent to ordinary eviction. Existing injection tests verify direct retrieval
before checking consumers. Arbitrary supplied values are not authoritative color
measurements, and documented operation eligibility remains binding.

## Consumers and measurement

| Store | Direct read/write consumer | Observable propagation |
| --- | --- | --- |
| HSL | `Color+HSL.hslComponents()` | HSL conversion, adjustments, suggestions, generation, HSL interpolation, legacy comparison fallback |
| LAB | `Color+LAB.labComponents()` | Legacy LAB conversion, legacy perceptual distance, enhancement candidates, LAB interpolation |
| Luminance | `Color+WCAGCompliance.wcagRelativeLuminance()` | `relativeLuminance`, darkness/endpoint choices, `contrastRatio`, enhancement direction and theme/generation decisions |
| Contrast | `Color+WCAGCompliance.wcagContrastRatio(with:)` | Legacy compliance, endpoints, enhancement, suggestions, palette acceptance, unavailable-input legacy comparison fallback |
| Blended color | `Color+Blending.blended` | Full-strength blends and convenience methods; zero/partial amounts bypass this store |
| Interpolated color | `Color+Gradient.interpolated` | Interpolation and gradient construction; the operation clamps before cache access |

These are source traces, supported by the existing
[cache-boundary audit](../audits/cache-boundary-audit.md) and
`ColorCacheIntegrationTests`; they are not freshly executed test results.

`wcagContrastRatio` resolves both RGBA inputs and declines translucent pairs before
lookup. It computes directly from RGB on a miss, without consuming the luminance
store. Conversely, `contrastRatio` uses the luminance store rather than the
contrast store. Accepted contrast insertion cannot bypass the opacity guard.

Strict contrast/luminance, authoritative comparison, component conversion results,
and `blendResult` compute independently of these stores. Budgeted enhancement uses
cache-influenced candidate search but independently checks strict contrast and
distance. `generateAssessedPalette` generates through the legacy generator and
then strictly assesses each returned color. Independence of measurement does not
imply independence of candidate selection.

## Identity, storage, concurrency, and clearing

Required identity behavior is already specified in
[cache-identity.md](cache-identity.md): original supported space, complete finite
component bits including alpha and signed zero, exact finite interpolation amount,
contrast symmetry, ordered blend/interpolation operands, and exact operation-name
strings. Unsupported, unresolved, or nonfinite key inputs miss and skip insertion.
Supported spaces are five named RGB and four named grayscale spaces. Matching
also checks actual space equality and component layout; it does not merely trust
the name. Identity construction performs no color conversion.

Implementation choices currently include string keys containing hexadecimal
component bits, temporary arrays and joined strings, pair sorting for contrast,
and six separate `NSCache` stores. Each miss followed by insertion reconstructs
the key. LAB/HSL values use `NSArray`, scalars use `NSNumber`, and color results
use `NSColor` or `UIColor` created from a result CGColor. Color insertion can fail
if the result lacks that representation. Scalar payloads are not range/finite
validated; finite-key validation is a different concern.

Each store sets `countLimit = 100`, with no cost accounting, TTL, custom eviction,
or public tuning. Apple's [countLimit documentation](https://developer.apple.com/documentation/foundation/nscache/countlimit)
explicitly makes this advisory. There is no strict 600-entry or byte-budget promise.
Apple's [NSCache documentation](https://developer.apple.com/documentation/foundation/nscache)
allows concurrent add/remove/query without caller locking and describes automatic
eviction. The implementation delegates storage synchronization to NSCache.

There is no transaction around lookup–compute–insert, no single-computation
guarantee, and no lock spanning stores. Concurrent misses can recompute; an
in-flight operation can insert after a clear. Global clear sequentially clears
six stores, not an atomic snapshot across them. Store-specific clears preserve
other stores in sequential use. The public thread-safety statement should not be
expanded into deterministic concurrent write ordering or an empty-after-all-work
barrier. No race, contention cost, or memory-pressure defect was demonstrated here.

## Existing evidence and its limits

The [2026-09-30 report](../validation/assessed-palette-performance-2026-09-30.md)
measured complete deterministic assessed-palette requests on an M4 Pro in macOS
Release builds: 18 cases, two cache preparations, 30 sample means per case/state,
100 requests per sample. Five-entry medians were approximately 30–47 microseconds;
eight-entry medians were 2.03–2.47 milliseconds. Priming lowered matching medians
by 32.4–34.5% and 8.5–9.9%, respectively. Eight-entry cases reached the bounded
search limit. Ordered outputs, assessments, and final RNG state matched across
ordinary cache states in those fixtures.

Both modes retain cache lookup, construction, and insertion; the empty mode can
reuse values within the request. Neither is a direct-computation baseline.
No allocation, retained-memory, CPU, contention, or phase-profile evidence was
collected. No workload frequency or application latency requirement was established.
These imported results support no iOS or UI-responsiveness conclusion. The new
approved comparison below adds a direct-computation baseline for two cases.

## Initial assessment

Strengths: zero configuration for ordinary callers; conservative exact identity;
platform-managed eviction and concurrent storage; independent strict measurement;
existing tests for insertion effects, cache-state equivalence, and clear isolation.
The cache centralizes identity and storage instead of spreading those rules across
every consumer.

Demonstrated complexity: explicit insertion makes the shared cache part of the
behavioral interface, with different influence on generation and measurement.
The earlier opacity bypass was a real defect and has already been corrected.
Global test state requires serialized integration coverage. Current public prose
that misses/eviction do not change numerical results needs the qualifier
"under ordinary automatic reuse": caller-supplied values can differ from computed
ones. This is a documentation ambiguity, not permission to ignore inserted values.

Unproven costs: key allocation, repeated identity construction, value bridging,
and synchronization are plausible overheads visible in source, not measured
bottlenecks. There is no evidence yet that six stores, NSCache, or the entry count
should change, or that an alternative is simpler overall.

## Alternatives to discuss

| Direction | Possible benefit | Constraint or unresolved cost |
| --- | --- | --- |
| Retain current implementation | Least change; retains all observed behavior; repeated HSL reuse has measured benefit | Clarify ordinary reuse versus explicit insertion; measured costs and benefits depend on workload |
| Simplify internals while retaining the 3.x interface and behavior | Could improve locality or remove proven overhead without migration | Must preserve getters, writes, eligibility, clears, identity, and synchronous access; no specific rewrite justified yet |
| In a deliberate major release, make reuse internal and selective, request-local, or absent | Could reduce the facts callers must learn and remove mutation as a customization mechanism | Behavioral/source migration; direct-computation and representative request evidence needed before selecting a reuse policy |

Internal HSL/LAB access offers more implementation freedom than public stores,
but changing its policy still needs complete-operation correctness and performance
evidence. Splitting explicit values into another store would add implementation
complexity; it is not a default compatibility workaround.

The agreed near-term direction is to retain production behavior.

### Agreed direction: ownership

The user endorsed an intended future interface in which callers request color
operations and ColorKit owns automatic reuse where evidence justifies it. Public
insertion that influences operations is not part of that intended future
interface. Preserve the shipped insertion behavior throughout 3.x; changing it
belongs to a deliberate major-release decision with migration guidance.

This is a design direction, not approval to remove declarations or behavior,
deprecate them, implement a replacement, or schedule a major release. Global,
request-local, selective internal, and absent reuse remain open alternatives.
Whether a future interface needs explicit clearing is also unresolved.

No implementation architecture has been selected, so there is no new ADR yet.
General cache terminology belongs in this design note, not the domain-only glossary.

## Approved bounded experiment

Before running an experiment, agree on the decision it should inform. If the
question becomes the total value of automatic reuse for assessed palettes, a
small candidate is an isolated direct-computation variant compared against the
unchanged implementation using an existing five-entry fixture and an eight-entry
search-limit fixture. Bypass both reads and writes in the prototype; include all
generation and authoritative assessment in timing. No caller-inserted values
would be used in that performance comparison, and the prototype would explicitly
not qualify as a compatible production replacement.

### First comparison — approved and completed

The user approved this comparison on 2026-10-01. Its isolated prototype is
experimental only. See the [completed evidence report](../validation/cache-ownership-performance-2026-10-01.md)
for results, exact artifacts, checks, and the preflight clock failure.

Decision: does automatic reuse earn its cost in these complete palette requests,
enough to warrant examining selective or request-local reuse rather than simply
computing directly? This comparison cannot select the best cache policy or prove
an application need by itself.

- Baseline: the inspected production revision, unchanged. Candidate: an isolated
  temporary source copy of that revision with cache reads and writes bypassed in
  the computation paths, including key construction and stored-value bridging.
  The calculations, input resolution, candidate search, and assessment stay the
  same. Do not add a public cache toggle or a replacement interface.
- Reuse `palette-blue-white-5-seed-42` and
  `palette-blue-white-8-seed-42`: fixed opaque brand blue against white, AA,
  black/white inclusion. The first represents the small request and the second
  the previously observed bounded-search workload. One fixed seed is deliberately
  a bounded case comparison, not coverage of the distribution of possible seeds.
- Compare both variants under both existing preparations: cleared before the
  request, and cleared then preceded by an identical untimed request. Apply the
  preparation to the candidate too to match recent computation history; its
  preparation labels do not imply it stores or hits cache entries. Reset RNG
  outside each request as the harness already does.
- Use three process runs per variant/fixture/preparation, ten untimed warm-ups
  per process, ten samples of 100 requests: 24,000 timed complete operations.
  Alternate baseline/candidate process order and reverse fixture/preparation
  order on the second run. Build and validate both variants before sampling.
- Stop after this fixed count, or immediately on correctness failure. Retain
  incomplete evidence on failure; do not extend sampling to obtain a preferred
  result. Overlap/noise can yield an inconclusive result.
- Retain ordered raw samples, source revision and complete candidate patch,
  harness sources, executable hashes, environment/appearance, and commands.
  Report microseconds per complete request, median and range of sample means,
  and absolute/relative differences. Controls remain visible and unsubtracted.
- Compare ordered components, assessments, availability, and final RNG state
  across variants outside timing, not just against each variant's own reference.
  Keep the existing before/after validation and inspect Release code to confirm
  the calculation and result consumption survive optimization. A mismatch stops
  the performance interpretation rather than becoming an accepted behavior change.
- No injected values in timed fixtures. The candidate intentionally does not
  preserve insertion effects and must not be called a compatible 3.x change.
  Existing insertion tests remain requirements for any actual implementation,
  not pass criteria that this incompatible diagnostic prototype can satisfy.

Use matched macOS Release/toolchain conditions and avoid concurrent builds while
sampling. No new iOS/UI, memory, or contention claim follows from this comparison.
Profile allocations or contention only for a subsequent concrete hypothesis.
Evidence from palettes alone would not justify removing blend/interpolation stores.
If current caching wins clearly, keep it as the reference and discuss the narrowest
further comparison; if direct computation is comparable or faster, it becomes a
candidate for broader correctness/workload evaluation, not an automatic rewrite.

Any later implementation requires explicit agreement. Verification would include
the existing two-platform identity and serialized insertion/clear integration
tests, strict-measurement and palette replay coverage, release-client/API checks,
and the agreed complete-operation comparison. Current release-client fixtures do
not explicitly exercise ColorCache calls; API comparison and behavioral tests
cover different portions of the contract. Neither alone proves compatibility.

### Result and next decision

All 24,000 main-run requests completed, with matching ordered output diagnostics,
assessments, and final RNG state across variants and preparations. Direct
computation had lower medians: five-entry requests improved by 15.776 microseconds
empty and 1.695 microseconds primed; eight-entry requests improved by 574.609
microseconds empty and 363.725 microseconds primed. The five-entry primed ranges
overlap slightly. These are complete macOS requests for the two selected cases,
not application-level benefits or a per-store cost attribution.

Recommendation remains no production change yet. Direct computation now has
measured support as a simpler alternative for these paths. A 3.x investigation
could next isolate internal HSL reuse, while preserving public insertion and
automatic-population behavior in the four publicly writable stores. The user
agreed to focus on this question and then approved the specific follow-up
comparison below. It is complete; no production implementation is authorized.

### Next question: HSL-only reuse

Source inspection confirms that `hslComponents()` is the sole production reader
and writer of the HSL store. Both cache-access methods are internal. HSL conversion
feeds palette candidate construction and similarity checks, enhancement search,
HSL interpolation and gradient construction, adjustments, inspector presentation,
theme construction, and legacy comparison fallback. It is also a standalone
public conversion protected by the 3.0.0 client fixture.

The public `clearHSLCache()` method has shipped. It and the other stores must not
be removed or silently repurposed. Internal injection/population assertions in
`ColorCacheIntegrationTests` observe implementation choices through `@testable`;
they are distinct from ordinary public insertion contracts. Do not edit them to
make a diagnostic prototype appear release-ready. Any eventual HSL policy change
still needs explicit review of clearing behavior and the documented automatic
reuse promise, as well as preserved conversion results and failure behavior.

Approved comparison, completed on 2026-10-01:

- Compare the same pinned current implementation against an isolated copy that
  bypasses only the HSL lookup and insertion in `hslComponents()`. Keep the HSL
  calculation, appearance resolution, sRGB clamping, and optional return unchanged.
  Retain `ColorCache`, all clearing methods, and the other five stores as-is.
- Measure the same two blue/white palette cases plus existing `hsl-red`. The latter
  times a complete public conversion, including input resolution, and exposes
  repeated-conversion costs in the primed mode. It is not an isolated lookup and
  does not represent every HSL input or downstream workflow.
- Use both empty and primed preparations, matched across variants. Keep three
  process runs, ten warm-ups, ten samples of 100 requests, paired alternating
  variant order, and reverse case order on the second run: 36,000 timed requests.
  Run a new matched baseline rather than compare against yesterday's or the prior
  experiment's timings. Existing source/binaries may be reused only after hash
  verification; both variants must use the same source base and harness.
- Preserve cross-variant palette diagnostics and final RNG checks. For HSL, retain
  the fixture's expected result and capture/compare actual optional component
  values outside timing; the existing runner does not emit HSL diagnostics.
  Any needed diagnostic code must be identical in both variants and outside the
  timed interval. Preserve unavailable behavior with existing resolution coverage
  before drawing a production conclusion.
- Keep source patches, binaries, raw sample order, environment, correctness logs,
  controls, and failed attempts. Retain the fixed-count/stop-on-mismatch rule.
  Avoid single-iteration preflight probes given the earlier invalidClock failure.

This experiment asks whether HSL caching explains any of the full-bypass benefit
and whether removing it trades palette cost for repeated-conversion cost. It is
not proof that the rest of the cache is unnecessary. If outcomes conflict or
differences are small/noisy, discuss the observed absolute costs without inventing
a universal acceptance threshold. Two-platform behavioral and compatibility
verification would remain necessary before an implementation proposal is accepted.

### HSL-only result and recommendation

The [HSL evidence report](../validation/hsl-cache-performance-2026-10-01.md)
records 36,000 requests, 360 retained samples, matching cross-variant diagnostics,
six benchmark tests and 13 macOS HSL resolution tests passing in each variant.
No failure, excluded sample, or retry occurred in this experiment.

Bypassing only HSL reuse improved empty five-entry palettes by 8.876 microseconds
and eight-entry palettes by approximately 128–134 microseconds. It slowed primed
five-entry palettes by 2.539 microseconds (8.5%) and primed standalone HSL red
conversion by 0.269 microseconds (27.1%). All three run medians agree on those
directions. The report preserves ranges and the small absolute size of the
conversion regression rather than treating the percentage as an application issue.

The agreed direction is **retain HSL caching in 3.x**. Removing it is not a
uniform performance improvement, and no caller workload or budget justifies
accepting its measured regressions in exchange for reduced machinery. Do not add
a hybrid policy merely to chase both outcomes. The user accepted retaining the
implementation and clarifying its contract; this does not reverse the future direction of
internal automatic reuse without public insertion as a customization mechanism.

## Delivery scope and follow-ups

One documentation-only review should contain this design note, the two validation
reports, and narrow contract clarifications in the Utilities DocC article and
`PERFORMANCE_IMPROVEMENTS.md`. Keep the existing cache implementation and examples.
Clarify automatic reuse versus explicit insertion, independent strict measurement,
advisory retention limits, and clearing during concurrent operations. This does
not require a new ADR, domain glossary entry, release note, or migration guide.

Before submission, build DocC with warnings as errors, verify the generated cache
section, check documentation examples and local links, and review the prose against
the traced consumers. The experiment reports retain their actual validation scope;
documentation checks do not turn the prototypes into compatible production changes.
For this documentation pass on 2026-10-01, the macOS DocC build passed with
`--warnings-as-errors`; its generated Utilities JSON contains the updated cache
section and anchor. `scripts/check_documentation.py --derived-data
.build/documentation` passed, including 17 executed public examples, palette
replay across two processes, and generated theme compilation. Twenty relative
links and DocC resources resolved; SwiftLint and whitespace checks passed. Evidence
archive hashes, the sole metadata redaction, reconstructed source hashes,
cross-variant diagnostics, and reported medians were verified without rerunning
measurements. No production
behavioral or compatibility suite was rerun for these prose-only changes.

Compact [review evidence archives](../validation/evidence/cache-2026-10-01/README.md)
include samples, prototype patches, reproduction scripts, hashes, and verification
excerpts. Only the unrelated desktop process inventory is redacted; original and
exported hashes identify the difference. Full local artifacts remain preserved.
The archived prototypes are outside production targets, and build products are
not included in the review.

No further benchmark campaign or cache rewrite is scheduled. Reopen a narrowly
scoped internal improvement only when a concrete caller workload or budget makes
the decision useful. Agree on the smallest complete-operation experiment first;
preserve exact identity, public insertion and getter observations, clearing, and
synchronous use. Any implementation needs the two-platform behavioral and
compatibility checks described above, plus measurements of affected operations.

If a substantial need later justifies a deliberate major release, revisit public
insertion and explicit clearing together with migration guidance. The preferred
ownership direction is that callers request operations and ColorKit manages reuse
where justified. It does not yet select global, request-local, selective, or absent
reuse, and it is not a reason by itself to schedule a breaking release.

Isolated prototype source, builds, and original raw artifacts remain in separate
local evidence directories. Delivery changes documentation and evidence only;
production Swift source, release metadata, and frozen fixtures remain unchanged.
