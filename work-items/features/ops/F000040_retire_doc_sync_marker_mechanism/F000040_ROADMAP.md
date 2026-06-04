---
type: roadmap
parent: F000040
title: "Retire the F000028/F000029 doc-sync marker + preamble-AUQ mechanism — Roadmap"
date: 2026-06-03
author: chjiang
status: Draft
---

<!-- A feature's roll-up roadmap. Scope/non-goals (the feature's identity),
     decomposition (which user-stories carry the work), and delivery timeline
     (when each piece ships). -->

## Scope

Retire the obsolete F000028/F000029 doc-sync marker + preamble-AUQ mechanism in
full: delete the detection script and its two tests, strip the `DOC_SYNC_PENDING`
preamble AUQ block from the two orchestrators that carry it, strike the stale
"F000029 stays as fallback" language wherever it claims current behavior (~9
locations), surgically remove the post-merge Section 3 doc-sync trigger + the
post-rewrite hook from `setup-hooks.sh` (keeping pre-commit validate + F000009
post-merge Sections 1+2), delete the F000028/F000029 doc sections from
`doc/ARCHITECTURE.md` / `doc/PHILOSOPHY.md` / `doc/SKILL-CATALOG.md`, delete the
doc-sync-check mechanism section from `CLAUDE.md` and replace it with a short
accepted-gap note, fix the two dangling comments in the F000037 config parser,
and regenerate `README.md` from the catalog. The surviving F000036 inline Step
5.5 doc-sync mechanism is left untouched.

## Non-Goals

- Touching the surviving F000036 Step 5.5 doc-sync (`/CJ_document-release`, Step 5.5 prose, `[doc-sync-red]` halt rows, `cj-document-release.json`, `cj-document-release-config.sh`, `cj-goal-doc-sync-wiring.test.sh`) — these LIVE and must not regress.
- Building a replacement for the rare non-/ship, non-orchestrator main-move path — the gap is documented, not re-tooled.
- Deleting F000028/F000029 work-item history — preserved with a one-line RETIRED note.

## Success Criteria

<!-- Bulleted, measurable outcomes observable from the outside. -->

- [ ] `./scripts/validate.sh` exits 0 with 0 errors / 0 warnings.
- [ ] `./scripts/test.sh` exits 0 with no orphaned assertions or references to deleted test files.
- [ ] `tests/cj-goal-doc-sync-wiring.test.sh` still passes (F000036 Step 5.5 survivor coverage intact).
- [ ] Completeness grep #1 (`skills-doc-sync-check|DOC_SYNC_PENDING|doc-sync-pending|doc-sync-cache`), excluding `work-items/`, `CHANGELOG.md`, `.gstack/` → ZERO live references.
- [ ] Completeness grep #2 (`marker-AUQ|F000029.*fallback|Coexistence with F000029|F000028.*F000029`) across `skills/ doc/ README.md CLAUDE.md skills-catalog.json` → ZERO live references describing it as current behavior.
- [ ] Both orchestrator preambles no longer contain the doc-sync block; `setup-hooks.sh` still installs pre-commit validate + F000009 post-merge Sections 1+2 (post-merge Section 3 + post-rewrite hook gone); `README.md` regenerated and consistent; accepted-gap note exists in `CLAUDE.md`.

## Decomposition

<!-- The user-stories that decompose this feature. Status: Open, In Progress, Closed. -->

| User-Story | Title | Status |
|-----------|-------|--------|
| [S000073](S000073_retire_doc_sync_marker_mechanism/S000073_TRACKER.md) | Retire the doc-sync marker + preamble-AUQ retirement surface | Open |

## Delivery Timeline

<!-- Owner = primary person responsible. Status: Done, In Progress, Not Started, At Risk, Deferred. -->

| # | Milestone | Target Date | Status | Owner | Notes | Blocked By |
|---|-----------|-------------|--------|-------|-------|------------|
| 1 | Ship S000073 (execute the full retirement surface) | — | Not Started | chjiang | Delete files + edit preambles + strike fallback language + surgical hook/test edits + doc deletes + comment cleanup + README regen | — |
| 2 | End-to-end pipeline run (validate + test green, both completeness greps zero, survivor test passes) | — | Not Started | chjiang | Gate before /ship | #1 |

### Delivery History

<!-- Backward-looking record: PR links, merge dates, version bumps after ship. Append-only. -->

- 2026-06-03: F000040 scaffolded from /office-hours design doc.

## Dependency Graph

<!-- Format: #N description --> #M description (arrow = "blocks"). -->

```
#1 Ship S000073 (full retirement surface) --> #2 End-to-end pipeline run (validate/test green + greps zero + survivor test passes)
```

## Open Questions

<!-- Questions still being decided. -->

| Question | Next check |
|----------|-----------|
| Add the one-line "RETIRED by F000040" note to F000028/F000029 TRACKERs? | Default-yes per design Open Questions; confirm during S000073 implement |
