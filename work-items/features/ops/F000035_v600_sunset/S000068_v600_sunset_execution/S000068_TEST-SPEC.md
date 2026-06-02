---
type: test-spec
parent: S000068
feature: F000035
title: "v6.0.0 sunset execution — Test Specification"
version: 1
status: Draft
date: 2026-06-02
author: chjiang
spec: SPEC.md
reviewers: []
---

<!-- Scope: ENTIRE user story. Smoke + E2E together must cover every SPEC P0
     acceptance criterion. -->

## Smoke Tests

<!-- Automated regression. Fast, deterministic, runnable from a script or CI. -->

| # | Tag | AC | Check | What It Validates | Script/Command |
|---|-----|-----|-------|-------------------|----------------|
| S1 | core | AC-1 | 5 deprecated skill dirs absent | Layer-1 deletion landed | `! ls skills/CJ_goal_run skills/CJ_goal_auto deprecated/CJ_goal_investigate deprecated/cj_goal_feature deprecated/cj_goal_defect 2>/dev/null` |
| S2 | core | AC-2, AC-9 | `deprecated/` + dead test files gone | Trees deleted in their entirety | `! ls -d deprecated tests/cj-goal-investigate-shim.test.sh tests/cj-goal-investigate-did-allocator.test.sh tests/eval/CJ_goal_run 2>/dev/null` |
| S3 | core | AC-3, AC-4 | Catalog filtered + enum closed | Catalog has only `active`+`experimental`; validate.sh enum closed | `[ "$(jq -r '.[] | .status' skills-catalog.json | sort -u | tr '\n' ',' )" = "active,experimental," ] && ! grep -E 'active\|experimental\|deprecated' scripts/validate.sh` |
| S4 | core | AC-5, AC-6 | skills-deploy + generate-readme stripped | Both scripts no longer mention deprecated/DEPRECATED_COUNT | `[ "$(grep -c 'deprecat' scripts/skills-deploy)" = "0" ] && [ "$(grep -c 'DEPRECATED_COUNT' scripts/generate-readme.sh)" = "0" ]` |
| S5 | core | AC-13, AC-15 | VERSION + validate.sh + test.sh green | End-state contract holds | `[ "$(cat VERSION)" = "6.0.0" ] && grep -q '## \[6.0.0\]' CHANGELOG.md && ./scripts/validate.sh && ./scripts/test.sh` |

<!-- Tag vocabulary: core, resilience, observability, usability, security, integration. -->

## E2E Tests

<!-- Manual end-to-end verification, run after implementing and before /ship. -->

| # | Tag | AC | Scenario | Steps (as a real user would) | Expected Outcome | Rubric |
|---|-----|-----|----------|------------------------------|------------------|--------|
| E1 | usability | AC-7, AC-8 | Doc surfaces consistent with live skill surface | (1) Open CLAUDE.md and scroll the `## Skill routing` section. (2) Open `doc/PHILOSOPHY.md`, `doc/ARCHITECTURE.md`, `rules/skill-routing.md`. (3) Search each for the strings `Deprecated front doors`, `Retired skills`, `Deprecation tombstones`, `Deprecated skills convention`, `Retired-skill drift check`. | None of the search terms have any hits except inside the prose of THIS work-item's own files (work-items/features/ops/F000035_v600_sunset/*) | PASS if zero hits in CLAUDE.md/doc/*.md/rules/*.md; FAIL if any tombstone or convention reference remains |
| E2 | core | AC-1 post-ship | Retired skill names error out | After PR merges to main and skills-deploy syncs (operator action, post-ship), invoke `/cj_goal_feature` (lowercase) and `/CJ_goal_investigate D000001` in a fresh Claude session | Both error with "skill not found" or equivalent | PASS if both error; FAIL if either still routes anywhere |
| E3 | usability | AC-14 | README regen has no Deprecated table | Run `./scripts/generate-readme.sh` and open the resulting README.md. Scroll to where the `### Deprecated` table used to live. | The `### Deprecated` table does not appear anywhere in the regenerated README | PASS if no `### Deprecated` heading; FAIL if the heading or table content lingers |
| E4 | core post-ship | AC-16, AC-17 | Single squash-merge commit on origin/main | After PR merges, `git log origin/main --oneline -1` | One commit titled like `v6.0.0 feat: F000035 sunset deprecated shims + deprecation infrastructure (full nuke) (#NNN)` | PASS if single squash; FAIL if two commits land or title is malformed |
| E5 | usability | AC-11, AC-12 | TODOS + memory hygiene | (1) Open TODOS.md and search for v6.0.0 sunset rows — they should be strikethrough-annotated. (2) Open `~/.claude/projects/.../memory/MEMORY.md` and confirm the index line for `project_investigate_retire_candidate` is gone; confirm the memory file itself is absent. | Sunset rows in TODOS.md are strikethrough'd; the memory file + index line are both gone | PASS if both checks hold; FAIL otherwise |

<!-- E2 + E4 are post-ship by structural necessity: skills-deploy sync + git history both require the PR to merge first. The `post-ship` tag in column Tag tells /CJ_qa-work-item Step 4 to defer those rows to a [qa-e2e-deferred] journal entry instead of forcing a pre-ship adjudication. -->

## Coverage Gaps

| Gap | Why Not Tested | Risk Accepted |
|-----|----------------|---------------|
| Memory file deletion verification | Filesystem state on the host machine is outside the repo; smoke can't grep `~/.claude/` reliably | Operator visually confirms in E5; low risk because the design instruction is explicit and the index-line removal in MEMORY.md is self-evident |
| Cron / `/schedule` entry dependency on `--include-deprecated` | Solo project; no scheduled tasks reference the flag per design Open Q #5 | If a hidden caller exists, it errors out post-ship and operator fixes it — low blast radius |
| `tests/eval/` parent dir cleanup outcome | P2 nice-to-have; depends on what other eval children exist post-Phase 2 | Empty `tests/eval/` lingering is cosmetic only; cleanup follow-up trivial |
| `tests/cj-worktree-init.test.sh` + `tests/cj-goal-doc-sync-auq-recommendation.test.sh` update verification | These edits are conditional on what `grep` finds during Phase 2; smoke S5 (`./scripts/test.sh`) implicitly covers them by passing | If grep finds nothing to update, "no edit" is the correct outcome; smoke catches any regression from a wrong edit |
| Backward-compat / muscle-memory fallback verification | Intentionally not tested — the whole point of the sunset is that there's no fallback | Documented as breaking change in CHANGELOG; operator self-noted in design "The Assignment" section |
