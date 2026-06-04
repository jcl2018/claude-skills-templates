---
type: design
parent: F000040
title: "Retire the F000028/F000029 doc-sync marker + preamble-AUQ mechanism — Feature Design"
version: 1
status: Draft
date: 2026-06-03
author: chjiang
reviewers: []
---

<!-- A feature's cross-story design doc. Captures the PROBLEM, the SHAPE of
     the solution, the BIG DECISIONS with rationale, the RISKS, the
     DEFINITION OF DONE, and out-of-scope boundaries. Story-scope detail
     (SPEC/TEST-SPEC) lives on the nested user-stories — do
     not duplicate it here. -->

## Problem

F000028 (a post-merge/post-rewrite git hook that drops a doc-sync marker when
`main` moves) + F000029 (the `DOC_SYNC_PENDING` marker-pickup AUQ embedded in the
`CJ_goal_feature` + `CJ_goal_defect` orchestrator preambles, backed by
`scripts/skills-doc-sync-check` and the `~/.gstack/doc-sync-pending/` +
`~/.gstack/doc-sync-cache.json` state files) were built before F000036 made
doc-sync run INLINE at Step 5.5 of every cj_goal orchestrator. The marker→AUQ
loop now fires asking the operator to run `/document-release` for drift that has
already been folded into the same PR. The operator flagged the AUQ as obsolete
during a v6.0.8 run. The mechanism must be retired — without leaving a real
doc-drift hole.

**Critical framing — "doc-sync" names TWO mechanisms, one dies and one lives.**
This is the load-bearing distinction for the whole retirement (an adversarial
review caught a delete conflating them):

- **DIES (the retirement target):** the post-merge + post-rewrite hooks that
  *write markers*, `scripts/skills-doc-sync-check`, the `DOC_SYNC_PENDING`
  preamble AUQ blocks, and the marker/cache state files.
- **LIVES (F000036 inline Step 5.5 — must NOT be touched):** `/CJ_document-release`,
  the `### Step 5.5: Doc-sync` prose in the 3 `pipeline.md` files, the
  `[doc-sync-red]` / `[doc-sync-non-doc-write]` halt rows, `cj-document-release.json`
  (F000037), `scripts/cj-document-release-config.sh` (F000037 parser), and
  `tests/cj-goal-doc-sync-wiring.test.sh`.

## Shape of the solution

Full delete of the F000028/F000029 marker-AUQ surface plus a one-line
accepted-gap note, executed as a single child user-story (S000073). The
retirement surface is enumerated file-by-file in the user-story SPEC's
`## Architecture → Components Affected` table; the success criteria are the
TEST-SPEC. This is a multi-file internal-tooling retirement with no new runtime
behavior — the work is deletion + de-referencing, gated by two completeness
greps and the existing test suite.

| Concern | User-story | Artifact |
|---------|-----------|----------|
| Execute the full marker-AUQ retirement surface (delete files, edit 2 preambles, strike ~9 fallback-language locations, surgical hook + test edits, doc deletes, comment cleanup, regenerate README, accepted-gap note) | S000073 | [S000073_retire_doc_sync_marker_mechanism/S000073_TRACKER.md](S000073_retire_doc_sync_marker_mechanism/S000073_TRACKER.md) |

## Big decisions

| # | Decision | Why |
|---|----------|-----|
| 1 | Approach A: full delete + document the narrow gap (over B: lightweight post-merge reminder; over C: drop only the AUQ) | Complete retirement, no dead code or orphaned state-file writers; kills the operator-flagged AUQ; matches real coverage. B keeps a hook alive for a rare path (a stateless echo is easy to ignore); C leaves dead code + orphaned state files + markers still written every merge. |
| 2 | Treat the TODO's stated risk as a false premise and verify it | `/ship` already runs `/document-release` on every invocation (ship/SKILL.md:2873), so docs land in the PR; orchestrators run it at Step 5.5. The only uncovered path is a main-move bypassing BOTH — rare and manually recoverable. |
| 3 | KEEP `scripts/cj-document-release-config.sh`; only fix two stale comments | It is the F000037 `cj-document-release.json` parser, unrelated to the deleted script except for two "mirrors skills-doc-sync-check" comments that become dangling references. |
| 4 | Single child user-story, not multiple | The retirement is one cohesive de-referencing change across many files; it does not decompose into independent parallel sub-units. |

## Risks & open questions

| Risk / Question | Next check |
|-----------------|-----------|
| Deleting survivor coverage by conflating the two "doc-sync" mechanisms | SPEC Components Affected splits DIES vs PRESERVE explicitly; TEST-SPEC asserts `tests/cj-goal-doc-sync-wiring.test.sh` still passes. Resolved at S000073 QA. |
| Incomplete retirement leaves dangling references to the deleted script / preamble blocks / "F000029 fallback" claim | Two completeness greps in TEST-SPEC (4-token + fallback-language) must both return ZERO live references. Resolved at S000073 QA. |
| Breaking the other hooks `setup-hooks.sh` installs (pre-commit validate, F000009 post-merge Sections 1+2) | TEST-SPEC asserts those survive after the surgical hook edit. Resolved at S000073 QA. |
| README hand-edited instead of regenerated drifts from the catalog | SPEC mandates `scripts/generate-readme.sh` after the catalog edit; TEST-SPEC checks consistency. Resolved at S000073 QA. |

## Definition of done

<!-- Objective, measurable criteria for "shipped." -->

- [ ] `./scripts/validate.sh` exits 0, 0 errors / 0 warnings.
- [ ] `./scripts/test.sh` exits 0.
- [ ] `tests/cj-goal-doc-sync-wiring.test.sh` still passes (survivor coverage intact).
- [ ] Completeness grep #1 (`skills-doc-sync-check|DOC_SYNC_PENDING|doc-sync-pending|doc-sync-cache`), excluding `work-items/`, `CHANGELOG.md`, `.gstack/` → ZERO live references.
- [ ] Completeness grep #2 (`marker-AUQ|F000029.*fallback|Coexistence with F000029|F000028.*F000029`) across `skills/ doc/ README.md CLAUDE.md skills-catalog.json` → ZERO live references describing it as current behavior.
- [ ] Both orchestrator preambles no longer contain the doc-sync block.
- [ ] `setup-hooks.sh` still installs pre-commit validate + F000009 post-merge auto-sync (Sections 1+2); post-merge Section 3 + post-rewrite hook gone.
- [ ] `README.md` regenerated from the catalog and consistent.
- [ ] Accepted-gap note exists in `CLAUDE.md`.

## Not in scope

<!-- Explicit non-goals. -->

- Touching the surviving F000036 Step 5.5 mechanism (`/CJ_document-release`, the `### Step 5.5: Doc-sync` prose, `[doc-sync-red]` halt rows, `cj-document-release.json`, `cj-document-release-config.sh`, `cj-goal-doc-sync-wiring.test.sh`) — these LIVE.
- Deleting F000028/F000029 work-item history dirs — preserved as archival record (one-line RETIRED note only).
- Editing `CHANGELOG.md` directly — `/ship` + `/document-release` own the entry.
- Building a replacement reminder for the rare non-/ship, non-orchestrator main-move path — that gap is documented, not re-tooled (Approach B rejected).
- Removing runtime state files `~/.gstack/doc-sync-pending/*.json` + `~/.gstack/doc-sync-cache.json` — documented as safe-to-`rm` for the operator, not a repo change.

## Pointers

<!-- Cross-links to related artifacts. -->

- Parent tracker: [F000040_TRACKER.md](F000040_TRACKER.md)
- Roadmap: [F000040_ROADMAP.md](F000040_ROADMAP.md)
- Source design doc: `~/.gstack/projects/jcl2018-claude-skills-templates/chjiang-cj-feat-20260603-140631-39060-design-20260603-141622.md`
- Retired predecessors: F000028 (doc-sync hooks), F000029 (marker-pickup AUQ); survivor: F000036 (inline Step 5.5), F000037 (cj-document-release.json config).
