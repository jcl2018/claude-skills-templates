---
type: test-plan
parent: T000040
title: "WORKFLOWS granular skill/step/tool/shell enumeration rule + Check 15b structural sub-check — Test Plan"
date: 2026-06-04
author: chjiang
status: Draft
---

<!-- Scope: ONE task — tighten doc/WORKFLOWS.md's requirement to mandate granular
     skill/step/tool/shell enumeration per CJ_goal_* section, enforce the STRUCTURE via a
     validate.sh Check 15b sub-check (4 anchored Touches bullets) + a standalone test.sh smoke
     check, and bring the 3 existing sections to bar. The DETERMINISTIC guarantee is STRUCTURE
     (the 4 anchored bullets are present — T1/T2/T6/T7); completeness is AGENT-judged (Step 6.7 +
     the rewritten requirement), so the live dogfood (T8) is best-effort, not a gate. -->

## Scope

This task refines the existing doc/WORKFLOWS.md surface — no new artifact, no new audit class.
It (a) tightens the governing requirement to mandate a 4-dimension granular enumeration per
`CJ_goal_*` section, (b) adds a STRUCTURAL hard check (validate.sh Check 15b sub-check + a
standalone test.sh smoke check) that asserts the 4 anchored Touches bullets are present, and
(c) brings the 3 existing sections up to bar. Completeness stays agent-judged (Step 6.7
registered-doc audit + the rewritten requirement string). Files modified:

- `doc/WORKFLOWS.md` — §1: intro L3 rewritten to the 4 dimensions + the granular-enumeration
  rule + the granularity ceiling; each of the 3 `CJ_goal_*` sections' `**Touches:**` rewritten
  to the canonical 4-bullet shape (**Skills dispatched** / **Steps · phases** / **Scripts ·
  tools · shell** / **Docs touched**) with the per-section gaps filled — `--phase sync` (F000045
  Fork 2) + Fork-1 base-freshness in ALL THREE; the isolation gate + worktree-cleanup
  (`--phase cleanup`) in CJ_goal_feature; `check-version-queue.sh` + (for todo) `cj-goal-common.sh`
  in defect/todo. Charts MAY gain the omitted sync/cleanup nodes for parity.
- `CLAUDE.md` — §2: the `doc/WORKFLOWS.md` `requirement:` VALUE inside `### Tracked doc/ files
  manifest` rewritten in place to mandate the 4-dimension granular enumeration (single
  double-quoted YAML scalar; block shape untouched). §7: the "Creating a new skill" step 6
  `**Touches:**`-block line names the 4 dimensions.
- `templates/doc-WORKFLOWS-section.md` — §3: Touches block rewritten from 3 bullets to the
  4-bullet shape; the "Keep it to the three bullets above" authoring comment rewritten to
  "all four bullets required; enumerate to the named-helper + named-step level".
- `scripts/validate.sh` — §4: Check 15b keeps the chart/tag check + ADDS the 4 anchored
  sub-checks (`^- \*\*Skills`, `^- \*\*Steps`, `^- \*\*Scripts`, `^- \*\*Docs`) per `CJ_goal_*`
  section, ERROR-per-missing-bullet with a precise message; the section-parse awk otherwise untouched.
- `scripts/test.sh` — §5: a STANDALONE hermetic smoke check (mirrors the F000045/S000081 block)
  asserting each of the 3 real sections carries all 4 anchored Touches bullets; the
  zzz-test-scaffold fixture is UNTOUCHED + re-verified unaffected.
- `CJ-DOC-RELEASE.md` — §6: one-line reference to the WORKFLOWS granular-enumeration rule.
- `CHANGELOG.md` / `VERSION` — §8: at `/ship` (version reconciled per the version queue).

Posture: Advisory + a STRUCTURAL hard check; the structural sub-check NEVER asserts completeness;
NO upstream gstack `/document-release` or `/ship` modification (only workbench-owned docs/scripts/templates).

## Regression Test Cases

| # | Test Case | Steps | Expected Result | Status |
|---|-----------|-------|-----------------|--------|
| 1 | §4 Check 15b anchored sub-check present + green for all 3 sections (DETERMINISTIC — primary proof) | `./scripts/validate.sh; echo "exit=$?"` after the 3 sections are rewritten | `exit=0`, RESULT: PASS, 0 errors; Check 15b reports each `CJ_goal_*` section's Touches block carries all 4 anchored bullets (`^- \*\*Skills`/`^- \*\*Steps`/`^- \*\*Scripts`/`^- \*\*Docs`); the chart/tag half of Check 15b still green | Pending |
| 2 | §5 standalone test.sh smoke check present + green (DETERMINISTIC — primary proof) | `./scripts/test.sh; echo "exit=$?"` | `exit=0`, RESULT: PASS, 0 failures; the new standalone smoke check (mirrors F000045/S000081) asserts each of the 3 real `CJ_goal_*` sections in `doc/WORKFLOWS.md` contains all 4 anchored Touches bullets; the check emits an OK line per section | Pending |
| 3 | §4 NEGATIVE — Check 15b deterministically FAILS a section missing one anchored bullet (manual, not committed) | Temporarily delete the `**Steps · phases**` bullet from one section in `doc/WORKFLOWS.md`; run `./scripts/validate.sh; echo "exit=$?"`; then restore | Non-zero exit; a precise ERROR naming the section + the missing bullet (e.g. "section '<name>' Touches block missing the 'Steps · phases' bullet") — NOT a whole-body false-positive (the anchored pattern does not match a chart node like `Step 5.5`); after restore, validate.sh PASS again | Pending |
| 4 | §1 ALL THREE sections list the pre-build `--phase sync` + Fork-1 base-freshness (the confirmed gap) | `grep -n -- '--phase sync' doc/WORKFLOWS.md` and confirm each of the 3 sections' Touches enumerates the pre-build skills-sync + Fork-1 base-freshness (ff local main in `cj-worktree-init.sh`) | All 3 sections name `cj-goal-common.sh --phase sync` (F000045 Fork 2) + Fork-1 base-freshness in their Steps · phases / Scripts · tools · shell bullets — they were ABSENT from every section before this task | Pending |
| 5 | §1 per-section gaps filled (feature isolation gate + worktree-cleanup; defect/todo check-version-queue + cj-goal-common.sh) | In `doc/WORKFLOWS.md` confirm: CJ_goal_feature names the Step 1.9 isolation gate (`--assert-isolated`) + Step 6.5 worktree-cleanup (`--phase cleanup`); CJ_goal_defect names the isolation gate (Step 5.0) + `check-version-queue.sh`; CJ_goal_todo_fix names `cj-goal-common.sh` (was entirely absent) + `check-version-queue.sh` | Each section's Touches reflects its real chain at the named-helper + named-step level; charts MAY also carry the omitted sync/cleanup nodes for parity | Pending |
| 6 | §1 granularity ceiling honored — `post-land-sync.sh` is NOT listed as a touch | `grep -n 'post-land-sync' doc/WORKFLOWS.md` | `post-land-sync.sh` does NOT appear as an orchestrator-step touch in any `CJ_goal_*` Touches block (it is the internal core `--phase sync` reuses + a manual operator step — listing it as a touch would be factually wrong); raw `git`/`gh` calls likewise not enumerated | Pending |
| 7 | §2 CLAUDE.md requirement rewritten in place + Check 15a still parses the manifest | `grep -n 'doc/WORKFLOWS.md' CLAUDE.md` (the tracked-doc manifest entry) AND `./scripts/validate.sh` Check 15a | The `doc/WORKFLOWS.md` `requirement:` value now mandates the 4-dimension granular enumeration as a SINGLE double-quoted YAML scalar (no bare `#`, no unquoted `:`); the `- path:`/`audit_class:`/`owner:`/`requirement:` block shape is intact; Check 15a still reads the manifest cleanly (no orphan/FAIL) — the requirement edit stays in-block | Pending |
| 8 | §3 templates/doc-WORKFLOWS-section.md → 4-bullet shape + contradicting comment fixed | `grep -n 'Steps · phases' templates/doc-WORKFLOWS-section.md` AND `grep -n 'three bullets' templates/doc-WORKFLOWS-section.md` | The template's Touches block shows all 4 bullets (Skills dispatched / Steps · phases / Scripts · tools · shell / Docs touched); the "Keep it to the three bullets above" comment is GONE — rewritten to "all four bullets required; enumerate to the named-helper + named-step level" (zero matches for the old "three bullets" instruction) | Pending |
| 9 | §6/§7 one-liner + authoring-instruction fixes | `grep -n 'WORKFLOWS' CJ-DOC-RELEASE.md` (the granular-enumeration reference) AND confirm `CLAUDE.md` "Creating a new skill" step 6 `**Touches:**`-block line names the 4 dimensions | CJ-DOC-RELEASE.md carries a one-line reference to the WORKFLOWS granular-enumeration rule; CLAUDE.md step 6 names the 4 dimensions so the authoring instruction matches the rule | Pending |
| 10 | zzz-test-scaffold fixture UNAFFECTED (`project_implement_subagent_blind_spot_test_sh` re-verify) | Confirm no edit to the zzz-test-scaffold fixture; `./scripts/test.sh` exercises it unchanged; confirm Check 15b's loop `select(.name | startswith("CJ_goal_"))` does not iterate the non-`CJ_goal_*` fixture | The fixture is untouched and still passes validate; the new Check 15b sub-check never iterates it (a Check 15b SUB-check, not a new top-level check needing a parallel fixture edit), so the blind spot does not fire — but it is explicitly re-verified | Pending |
| 11 | Dogfood — THIS PR's body carries the verdict section, all current incl. doc/WORKFLOWS.md (BEST-EFFORT, not a pass/fail gate) | After `/ship` opens the PR, `gh pr view <PR#> --json body -q .body \| grep -F '### Registered-doc requirements'`; confirm `doc/WORKFLOWS.md` reads `up-to-date` against the NEW requirement | The PR body's `## Documentation` section contains a real `### Registered-doc requirements` block; `doc/WORKFLOWS.md`'s verdict is `up-to-date` (the §1 rewrite makes the 3 sections satisfy the new requirement). NON-BLOCKING: realized at `/ship`/Step 4.6 time; the deterministic proof is T1+T2 | Pending |

## Verification Steps

<!-- How was the fix verified beyond the test cases above? -->

- [ ] `./scripts/validate.sh` exits 0 (no new ERROR; Check 15b's anchored sub-check GREEN for all 3 `CJ_goal_*` sections; Check 15a still parses the CLAUDE.md tracked-doc manifest)
- [ ] `./scripts/test.sh` exits 0 (RESULT: PASS; the new standalone smoke check green for all 3 sections; zzz-test-scaffold fixture UNAFFECTED — explicitly verified)
- [ ] T1 + T2 (the two DETERMINISTIC structural checks — validate.sh Check 15b sub-check + the test.sh smoke check) both green — the primary proof the 4 anchored Touches bullets are present in all 3 sections
- [ ] NEGATIVE spot-check (T3) confirmed manually (not committed): dropping one anchored Touches bullet makes Check 15b ERROR with the precise per-bullet message (no whole-body false-positive); restored after
- [ ] CONFIRMED gap filled: `--phase sync` (F000045 Fork 2) + Fork-1 base-freshness now listed in ALL THREE sections (were absent from every section + chart before)
- [ ] Granularity ceiling honored: `post-land-sync.sh` is NOT listed as a touch in any `CJ_goal_*` Touches block; raw `git`/`gh` calls not enumerated (named helpers + steps only)
- [ ] Contradiction removed: the templates/doc-WORKFLOWS-section.md "Keep it to the three bullets above" comment is rewritten to require all four bullets (zero matches for the old "three bullets" instruction)
- [ ] No upstream modification: `git diff` touches only workbench-owned files (doc/WORKFLOWS.md, CLAUDE.md, templates/doc-WORKFLOWS-section.md, scripts/validate.sh, scripts/test.sh, CJ-DOC-RELEASE.md, CHANGELOG.md) — no upstream gstack `/document-release` or `/ship` files; no drift in doc/ARCHITECTURE.md / doc/PHILOSOPHY.md (grepped — zero Touches-shape references)
- [ ] Best-effort dogfood (T11): THIS PR's body carries a real `### Registered-doc requirements` section with `doc/WORKFLOWS.md` `up-to-date` against the NEW requirement (non-blocking)

## Environments Tested

| Environment | Build | Result |
|------------|-------|--------|
| macOS (workbench, zsh) | branch cj-feat-20260604-140658-97792 | Pending |
