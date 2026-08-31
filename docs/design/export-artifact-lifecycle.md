# F13 · S13 — Prepare export artifacts before presentation

Status: implemented; validation results are recorded in `docs/screenshots/f13/README.md`.

## Agreed scope

- Limit changes to the accessible palette demo's export sections.
- Preserve palette and theme export buttons, all existing formats, `ShareSheet`, and macOS save behavior.
- Capture entries, export name, and format in one palette export snapshot at the button action.
- Prepare synchronously from that snapshot, once per accepted export action. Do not add background preparation tasks or a preparing state in this change. Preparation can briefly block interaction, especially for PNG.
- On iOS, finish serialization and writing a file before assigning an optional identified share item. The sheet builder only presents that prepared item; it performs no serialization, file I/O, or error-state mutation.
- Use separate temporary storage for each export request so subsequent exports cannot overwrite a presented file.
- Preparation failure reports the error without presenting a share sheet.
- Result presentation observes the export helper and reads its current message when presenting an alert, so success and failure feedback does not use an outdated message value.

## Temporary artifact lifetime

- On iOS, give each request its own directory within a demo-owned temporary export directory, keeping the existing human-readable filename and extension inside it.
- Retain successfully prepared files for the current app run, including after share cancellation, sheet dismissal, or the demo view disappearing. Clearing the share item does not delete its file.
- On the first export in a later app run, attempt to remove this demo's export directories from earlier runs. Do not remove current-run directories or unrelated temporary files. Run identity spans all instances of the demo in the process.
- Immediately attempt to remove files and directories belonging to a failed preparation, since they were never presented.
- Keep `ShareSheet` unchanged. This conservative retention policy avoids relying on presentation state to determine when a share consumer has finished reading the file.
- Accept temporary disk accumulation during a long app run. Temporary artifacts have no persistence guarantee between app runs; the system may also purge them while the app is not running.

## Active share and repeated exports

- Allow one active share item per demo instance. Guard both export actions while it exists; additional actions do not prepare an artifact, queue a request, or replace the active item.
- After dismissal clears the active share item, another export action prepares a fresh artifact with a new identity and request directory, even if its inputs are identical.
- Palette generation may finish while a share item is active. Its completion and later input changes do not alter that item's payload.

## Validation approach

- Add focused automated lifecycle tests through an internal helper scoped to this demo's export flow. Keep the public API and `ShareSheet` unchanged.
- Verify preparation counts, ignored actions while sharing is active, failure without a share item, snapshot stability, fresh identities and file paths for repeated exports, and cleanup across simulated app runs.
- Use isolated temporary roots and controllable run identities so tests exercise retention and cleanup without touching actual app artifacts or depending on process restarts.
- Add a hosted-view check that redraws do not trigger preparation. Inspect the sheet builder to confirm it only presents the prepared item.
- Manually check native iOS sharing and cancellation, including repeated sharing and generation completing while sharing is active.
- Manually check macOS saving and cancellation, preserving the selected filename, format, successful-save feedback, and error reporting.
- Run the existing export-byte tests on iOS and macOS alongside the new lifecycle coverage.
- Record actual validation results during implementation; agreement on this approach does not establish that the checks have passed.

## Required validation

- One preparation per accepted action, none for actions ignored while sharing is active, and no rendering I/O.
- No sheet after preparation failure.
- Stable payload when generation completes or the selected format changes.
- Repeated sharing does not overwrite a previous artifact.
- Cancellation does not delete an artifact still needed by sharing.
- macOS save cancellation produces no write or result alert.
