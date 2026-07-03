---
type: roadmap
parent: F000075
title: "Split CI into push/nightly cadence categories; move slow Windows suite to nightly — Roadmap"
date: 2026-07-03
author: chang
status: Draft
---

<!-- A feature's roll-up roadmap. Captures scope/non-goals (the feature's identity),
     decomposition (which user-stories carry the work), and delivery timeline. -->

## Scope

Split the workbench's CI cadence into first-class categories and move the slow
Windows deploy suite off the PR path. The portable category taxonomy is bumped
from V1 `{workflow, CI}` to V2 `{workflow, CI-push, CI-nightly}` so the category
name carries the cadence; `--category CI-push`/`--category CI-nightly` becomes the
whole selection API. The real CI config changes too: `windows.yml` keeps only the
fast `windows-smoke.sh` on PR/push, and a new `windows-nightly.yml` runs the slow
`test-deploy.sh` on `windows-latest` nightly. Both consuming skills
(`/CJ_test_audit`, `/CJ_test_run`) and the convention docs are updated so the
cadence split is auditable, locally runnable, and documented.

## Non-Goals

- Physical relocation of test scripts into `tests/<category>/` — deferred by F000074, still deferred here.
- A `platform:` field on the `categories:` axis — the deferred refinement that would let `windows-deploy` self-skip off Windows.
- Moving `goal-task-eval` (or any `workflow`-kind test) into `CI-nightly` — cadence does not subsume kind.
- A backward-compat `CI` alias — the rename is hard; no deprecated alias is added.
- Upstream gstack edits — all changes are workbench-owned.

## Success Criteria

<!-- Bulleted, measurable outcomes observable from the outside. -->

- [ ] `test-spec.sh --validate` passes with the V2 taxonomy; `--seed` stays byte-identical to `spec/test-spec.md`.
- [ ] `test-spec.sh --list-categories` shows `CI-push` + `CI-nightly` rows.
- [ ] `test-spec.sh --check-structure` reports against the new folder/category set, deriving required folders from declared categories.
- [ ] `test-run.sh --category CI-push` and `--category CI-nightly` select correctly (verified via `--dry-run`).
- [ ] `validate.sh` green — esp. Check 15/15a (post `spec/doc-spec-custom.md` rewrite) and Checks 24/26/28; full `test.sh` green; shellcheck clean.
- [ ] `windows.yml` runs only `windows-smoke.sh` on PR; `windows-nightly.yml` runs `test-deploy.sh` on `windows-latest` on schedule + dispatch.
- [ ] Both cj_test skills' SKILL.md + USAGE.md document the cadence categories; `CLAUDE.md` taxonomy + Windows-CI references updated.

## Decomposition

<!-- The user-stories that decompose this feature, with current status. -->

| User-Story | Title | Status |
|-----------|-------|--------|
| [S000125](S000125_ci_cadence_taxonomy_split/S000125_TRACKER.md) | CI cadence taxonomy split (V2) + Windows nightly move | Open |

## Delivery Timeline

<!-- Forward-looking milestones. Status: Done, In Progress, Not Started, At Risk, Deferred. -->

| # | Milestone | Target Date | Status | Owner | Notes | Blocked By |
|---|-----------|-------------|--------|-------|-------|------------|
| 1 | Ship S000125 (taxonomy V2 + parser/runner + contract rows + folders/docs + both CI workflows + both cj_test skills + tests) | — | Not Started | chang | The single user-story carries all eight deliverables | — |
| 2 | End-to-end pipeline run (validate.sh + full test.sh + `--dry-run` category selection + shellcheck) green | — | Not Started | chang | Feature-level verification gate before /ship | #1 |

### Delivery History

<!-- Backward-looking record: PR links, merge dates, version bumps after ship. Append-only. -->

- 2026-07-03: Scaffolded from the APPROVED /office-hours design doc.

## Dependency Graph

<!-- Format: #N description --> #M description (arrow = "blocks"). -->

```
#1 Ship S000125 (taxonomy V2 + all 8 deliverables) --> #2 End-to-end pipeline run green
```

## Open Questions

<!-- Questions still being decided. -->

| Question | Next check |
|----------|-----------|
| Does `goal-task-eval` move to `CI-nightly`? | Recommend no — it is a `workflow`-kind test scheduled by `eval-nightly.yml`; revisit only if the operator wants cadence to subsume kind. |
| Backward-compat alias for `CI`? | Recommend no — flag before implement only if a consumer repo is known to declare `category: CI`. |
| Bare `push`/`nightly` names instead of the `CI-` prefix? | Chose `CI-` to preserve the "deploy-gate" semantic and keep `workflow` distinct; revisit at approval only if bare names are preferred. |
