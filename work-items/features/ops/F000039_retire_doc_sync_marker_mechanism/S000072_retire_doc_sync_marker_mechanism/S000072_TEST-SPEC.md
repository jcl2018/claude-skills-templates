---
type: test-spec
parent: S000072
feature: F000039
title: "Retire the doc-sync marker + preamble-AUQ retirement surface — Test Specification"
version: 1
status: Draft
date: 2026-06-03
author: chjiang
spec: SPEC.md
reviewers: []
---

<!-- Scope: ENTIRE user story. Smoke + E2E together must cover every SPEC P0
     acceptance criterion. The design's Success Criteria map directly to these rows. -->

## Smoke Tests

<!-- Automated regression. Fast, deterministic, runnable from a script or CI.
     AC column maps each row to a SPEC acceptance criterion. -->

| # | Tag | AC | Check | What It Validates | Script/Command |
|---|-----|-----|-------|-------------------|----------------|
| S1 | core | AC-8 | Repo health passes | `validate.sh` exits 0 with 0 errors / 0 warnings | `./scripts/validate.sh` |
| S2 | resilience | AC-8 | Full suite passes | `test.sh` exits 0; no references to deleted test files; no orphaned assertions | `./scripts/test.sh` |
| S3 | integration | AC-5 | Survivor coverage intact | The F000036 Step 5.5 wiring test still passes (NOT deleted) | `bash tests/cj-goal-doc-sync-wiring.test.sh` |
| S4 | usability | AC-1, AC-2 | Retired-mechanism tokens gone | Completeness grep #1 returns ZERO live references | `grep -rE 'skills-doc-sync-check\|DOC_SYNC_PENDING\|doc-sync-pending\|doc-sync-cache' --include='*' . \| grep -vE 'work-items/\|CHANGELOG.md\|\.gstack/'` (expect empty) |
| S5 | usability | AC-3 | Stale fallback language gone | Completeness grep #2 returns ZERO live references describing it as current behavior | `grep -rE 'marker-AUQ\|F000029.*fallback\|Coexistence with F000029\|F000028.*F000029' skills/ doc/ README.md CLAUDE.md skills-catalog.json` (expect empty) |

<!-- Tag vocabulary: core, resilience, observability, usability, security, integration. -->

## E2E Tests

<!-- Manual end-to-end verification, run after implementing and before /ship.
     AC column maps each row to a SPEC acceptance criterion. -->

| # | Tag | AC | Scenario | Steps (as a real user would) | Expected Outcome | Rubric |
|---|-----|-----|----------|------------------------------|------------------|--------|
| E1 | core | AC-1 | Dead files removed | `ls scripts/skills-doc-sync-check tests/skills-doc-sync-check.test.sh tests/cj-goal-doc-sync-auq-recommendation.test.sh` | All three report "No such file or directory" | PASS iff none of the three exist |
| E2 | core | AC-2 | Both preambles clean | Open `skills/CJ_goal_feature/SKILL.md` + `skills/CJ_goal_defect/SKILL.md`; search for `skills-doc-sync-check` and `DOC_SYNC_PENDING` | Neither file contains the bash fence or the AUQ prose block | PASS iff zero hits in both files |
| E3 | resilience | AC-4 | Surviving hooks still install | Run `./scripts/setup-hooks.sh` in a scratch checkout; inspect `.git/hooks/` | pre-commit (validate) + post-merge (Sections 1+2) installed; no post-rewrite hook; post-merge has no Section 3 doc-sync block | PASS iff pre-commit + post-merge present, post-rewrite absent, no doc-sync trigger in post-merge |
| E4 | integration | AC-5 | F000037 survivor untouched | Confirm `cj-document-release.json`, `scripts/cj-document-release-config.sh`, the `### Step 5.5: Doc-sync` prose + `[doc-sync-red]` rows still exist; the parser's 2 comments no longer name the deleted script | Survivor files present; comments updated; Step 5.5 prose intact (only fallback parenthetical struck) | PASS iff all survivor surfaces present + comments fixed |
| E5 | observability | AC-6, AC-7 | Accepted-gap note + README regen | Open `CLAUDE.md` for the accepted-gap note; diff `README.md` against `scripts/generate-readme.sh` output | CLAUDE.md states doc-sync = Step 5.5 + /ship Step 18 (manual non-/ship → run `/document-release` by hand); README matches generator output (no hand-edit drift) | PASS iff note present AND `generate-readme.sh` produces no diff |

<!-- No dedicated E2E test skill for this feature; the smoke rows + manual checks above cover it. -->

## Coverage Gaps

<!-- What is explicitly NOT tested and why. -->

| Gap | Why Not Tested | Risk Accepted |
|-----|----------------|---------------|
| The narrow non-/ship, non-orchestrator main-move path (manual `gh pr merge` or direct push to main moving docs out of sync) | This is the deliberately-accepted gap from Approach A — there is no longer any automated flag for it by design | Docs could drift on a manual merge that bypasses both orchestrators AND `/ship`; manually recoverable by running `/document-release` from a feature branch (documented in CLAUDE.md). |
| Runtime cleanup of orphaned `~/.gstack/doc-sync-pending/*.json` + `~/.gstack/doc-sync-cache.json` | These are machine-local runtime state, not a repo artifact; documented as safe-to-`rm` for the operator | Stale files linger harmlessly until the operator removes them; nothing reads them after the script is deleted. |
| Behavior of the post-merge/post-rewrite hooks at actual git-merge time | The hook installer edit is verified structurally (E3); exercising a real merge is covered transitively by the surviving `setup-hooks.test.sh` cases | A subtle interaction in the retained Sections 1+2 could regress; mitigated by keeping those cases green in `test.sh`. |
