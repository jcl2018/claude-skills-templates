---
type: roadmap
parent: F000033
title: "USAGE.md drift detection (validate.sh Check 14) — Roadmap"
date: 2026-06-01
author: chjiang
status: Draft
---

<!-- A feature's roll-up roadmap — merges what was previously in feature-summary
     + milestones. Captures scope/non-goals (the feature's identity), decomposition
     (which user-stories carry the work), and delivery timeline (when each piece
     ships). -->

## Scope

Add `scripts/validate.sh` Check 14 enforcing that every routable non-deprecated skill's `skills/{name}/USAGE.md` is at least as recent (by `git log -1 --format=%ct`) as its sibling `skills/{name}/SKILL.md`. Document the convention + the documented operator override in `CLAUDE.md ## Conventions` and `doc/PHILOSOPHY.md ## Documentation surfaces`. Add a `scripts/test.sh` smoke proving Check 14 fires on drift and the documented override clears it. Workbench-internal — no upstream skill changes, no deployment surface, no catalog edits. Stacks on PR #186 (F000032); merge order: #186 first, then this PR.

## Non-Goals

- README.md per-skill drift-status column — deferred (catalog + generator change required).
- work-copilot/ analog drift check — workbench-only scope.
- Surfacing drift via F000028's post-merge doc-sync hook — Open Question 5, deferred.
- Distinguishing "real" SKILL.md changes from cosmetic edits — would require heuristic (Approach B); the documented override is the intentional audit trail.
- Upstream gstack `/document-release` modification — not ours.
- Per-skill or per-marker snooze — single global ERROR is sufficient.
- Filesystem-mtime-based check — explicitly rejected (non-deterministic across worktrees).

## Success Criteria

- [ ] `scripts/validate.sh` Check 14 ERRORs when SKILL.md's `%ct` > USAGE.md's `%ct` for any routable non-deprecated skill; passes when `%ct`s are equal or USAGE.md is newer.
- [ ] Check 14 ERROR message embeds the documented operator override (one-liner `sed` to bump `last-updated:` + `git add` + `git commit`).
- [ ] Check 14 SKIPs (with visible one-line note) when `git log` returns empty (untracked / staged-only / never committed).
- [ ] `./scripts/validate.sh` exits 0 with 0 errors / 0 warnings on this PR's HEAD.
- [ ] `./scripts/test.sh` exits 0 on this PR's HEAD.
- [ ] `CLAUDE.md ## Conventions` gains `### USAGE.md drift detection` documenting the override (and explicitly noting that `git commit --allow-empty` does NOT work).
- [ ] `doc/PHILOSOPHY.md ## Documentation surfaces` gains a drift-rule paragraph.
- [ ] `scripts/test.sh` has a new test (after the existing manual-skill-creation integration test, around line 215) exercising the full drift → override → clean cycle.
- [ ] CHANGELOG entry in user-forward voice; VERSION PATCH-bumped.
- [ ] PR opened against `cj-feat-20260601-152835-3769` (PR #186's branch), NOT main; PR body notes the stacking + merge order.
- [ ] After both PRs merge: touching `CJ_system-health/SKILL.md` (one-char edit) + running `./scripts/validate.sh` fires Check 14 with override in the message; copy-paste of the override + re-run clears it. Full loop < 60 sec ("The Assignment").

## Decomposition

| User-Story | Title | Status |
|-----------|-------|--------|
| [S000066](S000066_usage_drift_check_impl/S000066_TRACKER.md) | USAGE.md drift detection — implementation (validate.sh Check 14 + CLAUDE.md + PHILOSOPHY.md + test.sh smoke) | Open |

## Delivery Timeline

| # | Milestone | Target Date | Status | Owner | Notes | Blocked By |
|---|-----------|-------------|--------|-------|-------|------------|
| 1 | Ship S000066 (Check 14 + CLAUDE.md + PHILOSOPHY.md + test.sh smoke) | 2026-06-01 | Not Started | chjiang | One atomic PR via /ship against PR #186's branch | F000032 / PR #186 |
| 2 | After PR #186 merges: rebase + re-test before /land-and-deploy | 2026-06-01 | Not Started | chjiang | Verify Check 14 still PASS on main's HEAD post-#186-merge | #1 + PR #186 merged |
| 3 | The Assignment: touch SKILL.md, confirm Check 14 fires, run override, confirm clears | 2026-06-01 | Not Started | chjiang | 60-sec manual smoke; file follow-up if override shape feels wrong | #2 |

### Delivery History

<!-- Backward-looking record: PR links, merge dates, version bumps after ship.
     Append-only. -->

- 2026-06-01: Created — F000033 scaffolded from /office-hours design doc (`chjiang-cj-feat-20260601-162235-stack186-design-20260601-162450.md`).

## Dependency Graph

<!-- Visual representation of milestone ordering. Format: #N description --> #M
     description (arrow = "blocks"). Keep in sync with the Blocked By column. -->

```
PR #186 (F000032) --> #1 Ship S000066 (Check 14 + CLAUDE.md + PHILOSOPHY.md + test.sh)
#1 --> #2 Rebase + re-test post-#186-merge --> #3 The Assignment
```

## Open Questions

<!-- Questions still being decided. -->

| Question | Next check |
|----------|-----------|
| Should the override commit message follow a parseable convention (e.g. `docs: verify USAGE.md current for <name>`)? | Recommend, not enforce. Future-us could parse it if a "how many verifies in the last 30 days?" audit ever wants the data; v1 doesn't need it. |
| Should the F000028 post-merge AUQ hook also surface this drift signal? | Deferred. The validate-time signal is the primary surface; revisit only if operators report the validate-time signal feels too late. |
| Brand-new skill creation — does CLAUDE.md "Creating a new skill" need an explicit note that SKILL.md + USAGE.md ship in one PR? | The existing scripts/test.sh `manual-skill-creation` integration test already proves Check 14 doesn't fire on the atomic-commit case. CLAUDE.md change deferred unless someone hits the trap. |
