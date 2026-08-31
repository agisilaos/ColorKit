# Domain docs

ColorKit uses a single-context layout. This file tells engineering skills how to consume its domain documentation.

## Before exploring

- Read `CONTEXT.md` at the repository root for domain terminology.
- Read relevant architectural decision records (ADRs) under root `docs/adr/` before working in the affected area.

If either is missing, proceed silently. Do not flag the absence or suggest creating placeholder documents. The `domain-modeling` skill, also used by `grill-with-docs` and `improve-codebase-architecture`, creates them when terminology or architectural decisions are resolved.

## File structure

- `CONTEXT.md`: shared domain language for the repository.
- `docs/adr/`: repository-wide architectural decisions, with numbered Markdown records.
- `Sources/`: Swift package source code using this shared context.

Do not create separate contexts for the library, examples, or demo app as part of this setup. If the repository later adopts multiple contexts, update these instructions to use a root `CONTEXT-MAP.md` pointing to the relevant context files and ADR directories.

## Use the glossary's vocabulary

Use the terms defined in `CONTEXT.md` in issue titles, refactor proposals, hypotheses, and test names. Avoid synonyms the glossary rejects. If a concept is missing, reconsider whether the project uses it or note the gap for `domain-modeling`.

## Flag ADR conflicts

Explicitly identify any existing ADR your proposal contradicts and explain why reopening the decision is warranted. Do not silently override recorded decisions.
