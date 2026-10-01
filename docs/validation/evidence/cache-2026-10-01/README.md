# Cache investigation evidence — 2026-10-01

These archives preserve the evidence for the
[all-cache comparison](../../cache-ownership-performance-2026-10-01.md) and
[HSL-only comparison](../../hsl-cache-performance-2026-10-01.md):

- [All-cache evidence](cache-ownership-2026-10-01.zip)
- [HSL-only evidence](hsl-cache-2026-10-01.zip)

Each includes ordered samples, output diagnostics, environment/toolchain metadata,
analysis, source hashes, the experimental patch, comparison driver, preflight,
test logs, and compiler-verification notes with selected disassembly. The first
also preserves the failed one-iteration preflight. The second includes the shared
diagnostic harness patch and compiler-inspection script.

`export-manifest.json` records original and exported file hashes. Only the unrelated
desktop process inventory was removed from `raw.json`; all samples, diagnostics,
and other metadata are unchanged. Full source/build trees, binaries, full
disassembly, and unredacted originals remain in the local directories identified
by the reports. Those larger artifacts are not included here.

The patches and scripts are historical experiment artifacts, outside production
targets. They are not a supported alternate implementation or benchmark framework.

## Reconstruct the compared sources

Use a fresh directory outside the checkout. Extract one evidence archive into an
`evidence` subdirectory. Create a separate `run` directory so the preserved
`preflight.json` and `raw.json` cannot be overwritten by a new measurement.

From the ColorKit checkout, export the pinned revision to that run directory:

```sh
git archive --format=tar 1f9ddf0687bcac52afae60b4a1cc8dfa06168d42 \
  > /absolute/path/to/run/source.tar
```

Inside `run`, extract that archive into `baseline` and `direct` for the all-cache
comparison, or `baseline` and `hsl-direct` for the HSL-only comparison. Apply
`candidate.patch` only to the candidate with `patch -p1`. For HSL-only, also apply
`harness.patch` to both copies. Copy `compare.py`, `candidate.patch`, and
`source-manifest.json` from `evidence` into `run`; for HSL-only also copy
`harness.patch` and `inspect_compiler.py`.

Before building, verify every reconstructed source hash from `run`:

```sh
python3 -c 'import compare; compare.verify_sources()'
```

Follow the corresponding report's build, test, preflight, and sample commands
with the recorded toolchain and preparation. Inspect newly generated Release
code again; retained instruction addresses describe only the measured binaries.
New timings describe a new experiment, not a replacement for these samples.
