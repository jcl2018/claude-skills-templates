---
type: design
parent: S000066
title: "USAGE.md drift detection — implementation design"
version: 1
status: Draft
date: 2026-06-01
author: chjiang
reviewers: []
---

<!-- A feature's cross-story design doc. (For an atomic user-story, this is a
     brief link-to-parent stub — the parent F000033_DESIGN.md owns the full
     problem-framing + alternative analysis.) -->

## Problem

F000032 ships per-skill `USAGE.md` + Check 13 (presence + structure). What Check 13 doesn't catch: SKILL.md changing without USAGE.md being updated. Need a drift check that's cheap, deterministic, and repo-internal. See parent `F000033_DESIGN.md` for the full Approach A/B/C/D analysis.

## Shape of the solution

Atomic implementation in one PR (one commit, staged together for the pre-commit hook):

1. `scripts/validate.sh` — new Check 14 block (~20 lines) after Check 13. Same audit predicate. `git log -1 --format=%ct` comparison per skill. ERROR on `SKILL_CT > USAGE_CT`; embed the override one-liner in the ERROR message. SKIP with one-line note when `git log` returns empty (untracked / staged-only).
2. `CLAUDE.md` — new `### USAGE.md drift detection` subsection under `## Conventions` documenting the convention + the override + the warning about `git commit --allow-empty`.
3. `doc/PHILOSOPHY.md` — extend the F000032-added `## Documentation surfaces` section with a drift-rule paragraph + the role of `last-updated:` as audit trail.
4. `scripts/test.sh` — new smoke test after the manual-skill-creation integration test exercising the full drift → override → green cycle with `git reset --hard` cleanup.
5. VERSION + CHANGELOG bumped PATCH, user-forward voice naming F000033.

## Big decisions

| # | Decision | Why |
|---|----------|-----|
| 1 | Single user-story (no sub-tasks) | Atomic under the pre-commit hook. Same shape as F000032 (single S000065 child). Splitting adds bookkeeping without splitting risk. |
| 2 | Override = `sed` on `last-updated:` frontmatter, NOT `git commit --allow-empty` | Empty commits don't advance `%ct` for a specific path; `git log -1 -- <path>` only returns commits that touched the path. One-line frontmatter bump produces a real commit + audit trail. |
| 3 | Strict `>` comparison (not `>=`) | Atomic commits share `%ct`; `>=` false-fires on every F000032-backfilled USAGE.md the day this PR ships. Brand-new skills also work naturally. |
| 4 | Stacked PR against PR #186's branch | Check 14 references USAGE.md paths only present in PR #186. Stacked PR is the correct merge shape; fail-loud if #186 closes. |
| 5 | SKIP (visible note) when `git log -1` returns empty | Check 13 owns presence; Check 14 owns freshness. Freshness of an uncommitted file is meaningless. |

## Risks & open questions

| Risk / Question | Next check |
|-----------------|-----------|
| Cosmetic SKILL.md edits fire Check 14 | Mitigation accepted — operator runs the documented `last-updated:` bump (one `sed` + commit, ~5 sec). Acknowledgment IS the audit trail. |
| Pre-commit hook + atomic ordering | Same as F000032 — stage everything once. Only failure mode is mid-implement `git commit` on partial state. |
| macOS BSD sed compatibility | Override uses `sed -i.bak ... && rm <file>.bak` shape — works on both BSD and GNU. Validated in the scripts/test.sh smoke. |
| PR #186 closes without merging | This PR rebases onto main and Check 14 fails to find USAGE.md (which don't exist on main) — fail-loud, not silent-pass. |

## Definition of done

- [ ] All acceptance criteria from this story's TRACKER.md verified.
- [ ] `./scripts/validate.sh` + `./scripts/test.sh` both exit 0.
- [ ] PR opened against `cj-feat-20260601-152835-3769` via /ship.

## Not in scope

- README.md per-skill drift column — deferred (catalog field + generator change required).
- work-copilot/ analog drift check — workbench-only scope.
- USAGE.md deployment to `~/.claude/` — irrelevant for a validate-time check.
- F000028 post-merge AUQ coupling — Open Question 5, deferred.
- Distinguishing real vs cosmetic SKILL.md changes — would require heuristic.

## Pointers

- Parent feature design: [../F000033_DESIGN.md](../F000033_DESIGN.md)
- Parent feature tracker: [../F000033_TRACKER.md](../F000033_TRACKER.md)
- SPEC: [S000066_SPEC.md](S000066_SPEC.md)
- TEST-SPEC: [S000066_TEST-SPEC.md](S000066_TEST-SPEC.md)
- Source design doc: `~/.gstack/projects/jcl2018-claude-skills-templates/chjiang-cj-feat-20260601-162235-stack186-design-20260601-162450.md`
- Stacked on: PR #186 (F000032 / S000065 / branch `cj-feat-20260601-152835-3769`).
