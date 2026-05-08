---
name: "skills-deploy: make `--overwrite` the default behavior for install"
type: defect
id: "D000015"
status: active
created: "2026-05-07"
updated: "2026-05-07"
repo: "jcl2018/claude-skills-templates"
branch: "fix/skills-deploy-overwrite-default"
blocked_by: ""
---

## Lifecycle

### Phase 1: Track

1. Document reproduction steps in the Log section
2. Create working branch: `git checkout -b fix/skills-deploy-overwrite-default`
3. Scaffold required docs:
   - `D000015_RCA.md` (root cause analysis) — from `templates/personal-workflow/doc-RCA.md`
   - `D000015_test-plan.md` (regression test plan) — from `templates/personal-workflow/doc-test-plan.md`
4. Run `/investigate` to diagnose root cause
   → produces investigation findings in Log + Insights
5. Log initial symptoms and hypotheses

**Gates:**
- [x] Reproduction steps documented
- [x] Working branch created (`branch` field populated)
- [x] Required docs scaffolded (RCA + test-plan)
- [x] Root cause identified (default `overwrite=false` in [scripts/skills-deploy:149](scripts/skills-deploy:149); warn-and-skip flow at lines 386 and 421 skips the realistic case; `--overwrite` opt-in inverts the user's actual mental model)

### Phase 2: Implement

1. Work from `/office-hours` design doc (if applicable) + root cause analysis
   → design doc at `~/.gstack/projects/{slug}/`
2. Implement fix based on root cause analysis
3. Write regression test covering the defect scenario
4. Commit fix and test together
5. Update RCA doc with final root cause

**Gates:**
- [x] Fix committed
- [x] RCA doc updated
- [x] Todos section reflects remaining work (no stale items)

### Phase 3: Ship

1. Run `/personal-workflow check` — verify no regressions
2. Verify test-plan: regression test scenarios passing
3. Run `/ship` — creates fix PR (includes pre-landing code review)
4. Run `/land-and-deploy` — merges and verifies fix in production

❌ If regression test fails: investigate further
❌ If CI fails: fix, push, re-run `/ship`

**Gates:**
- [ ] `/personal-workflow check` — validation passed
- [ ] Test-plan verified (regression scenarios passing)
- [ ] `/ship` — PR created
- [ ] `/land-and-deploy` — merged and deployed

## Reproduction Steps

1. On a fresh checkout where `~/.claude/templates/personal-workflow/` already exists (deployed previously), edit a workbench template — e.g. add a comment to `templates/personal-workflow/tracker-defect.md`.
2. From the workbench root: `scripts/skills-deploy install`.
3. **Pre-fix observation:** the script logs `WARN: tracker-defect.md — exists with different content (use --overwrite to replace)` and exits without updating the deployed copy. The deployed templates remain stale.
4. To actually deploy: `scripts/skills-deploy install --overwrite`. Templates update.
5. **Post-fix expectation:** the unflagged invocation (`scripts/skills-deploy install`) should overwrite drifted templates by default. An explicit opt-out flag (e.g. `--no-overwrite` or `--preserve-drift`) — or no flag at all — exposes the safe-by-default path for the rare case where drift is intentional.

**Environment:** workbench at v1.5.1 on `main`. Affects `scripts/skills-deploy` (the unified installer for both templates and rules).

## Todos

**In scope (this PR — narrow):**

- [x] Decide escape-hatch shape — chose `--no-overwrite` opt-out + keep `--overwrite` as a tolerated no-op so D000013's post-merge hook keeps working unchanged
- [x] Decide overwrite logging — kept per-file logging; renamed `OVERWRITE: ... (--overwrite used)` → `UPDATE: ... (checksum differs)`. New PRESERVE message replaces WARN under `--no-overwrite`
- [x] Flip default at [scripts/skills-deploy:149](scripts/skills-deploy:149) (`overwrite=true`) and add `--no-overwrite` parsing at line 154
- [x] Update WARN-and-skip branches at [scripts/skills-deploy:386](scripts/skills-deploy:386) (templates) and [scripts/skills-deploy:421](scripts/skills-deploy:421) (rules) — now emit PRESERVE under `--no-overwrite`
- [x] Update reset-hint message at [scripts/skills-deploy:664](scripts/skills-deploy:664) (`doctor` output) — now references `skills-deploy install` (no flag) plus `--no-overwrite` to keep
- [x] Update help text at [scripts/skills-deploy:881](scripts/skills-deploy:881)
- [x] Update [CLAUDE.md](CLAUDE.md) "Template deployment" section
- [x] WORKFLOW.md reference at [skills/personal-workflow/WORKFLOW.md:208](skills/personal-workflow/WORKFLOW.md:208) — N/A (no `--overwrite` mention there; the line points at `scripts/skills-deploy install` only)
- [x] Audit `setup-hooks.sh` post-merge hook + D000013 regression block — both keep `--overwrite` (now no-op). No change needed; leaving the hook alone preserves backwards compat and avoids coupling D000015 to D000013's tests
- [x] Add D000015 regression block to `scripts/test.sh` (6 checks: default value, `--no-overwrite` handler, legacy `--overwrite` tolerance, removed warn-text, help-text update, CLAUDE.md sync)

**Out of scope (follow-up if still needed):**

- [ ] **Backup-before-overwrite** — drop a `.bak` next to overwritten files. Only worth it if users start losing work. Defer until evidence.
- [ ] **Deployed-extra cleanup** — D000013's "Out of scope" already covers this; not in this fix.
- [ ] **Drop `--overwrite` flag entirely (one release later)** — the no-op tolerance can stay forever (harmless) or get retired in a future cleanup. No urgency.

## Log

- 2026-05-07: Created. The realistic mode of operation is "deploy = sync workbench source → `~/.claude/`." Safe-by-default (`overwrite=false`) was a defensive choice that doesn't match how the tool is actually used; users hit the WARN line, retry with `--overwrite`, and learn to always pass it. D000013's post-merge hook already passes `--overwrite` unconditionally, which is the same pattern showing up at the system level. Time to make the default match reality.
- 2026-05-07: Implemented. Flipped default in `scripts/skills-deploy`; added `--no-overwrite` opt-out; kept `--overwrite` as a tolerated no-op so D000013's post-merge hook (and any other caller still passing the flag) works unchanged. Renamed log line `OVERWRITE: ... (--overwrite used)` → `UPDATE: ... (checksum differs)`. Renamed the WARN-and-skip branch to `PRESERVE: ...` (only fires under `--no-overwrite`). Live smoke test on `~/.claude/templates/personal-workflow/tracker-defect.md`: drift → default install → UPDATE; drift → `--no-overwrite` → PRESERVE; drift → legacy `--overwrite` → UPDATE. All three paths verified. `scripts/validate.sh` clean; `scripts/test.sh` clean (6 D000015 checks pass; D000012 + D000013 still pass).

## PRs

## Files

- `scripts/skills-deploy` — flipped default at line 149 (`overwrite=true`); added `--no-overwrite) overwrite=false ;;` at line 154; renamed `OVERWRITE:` → `UPDATE:` at line 381; renamed WARN branch to PRESERVE at lines 386 + 421; updated reset hint at line 664; expanded help text at line 881
- `CLAUDE.md` — "Template deployment" bullet rewritten to document the new default and the `--no-overwrite` opt-out
- `scripts/test.sh` — added D000015 regression block (6 checks). D000013 block left unchanged (still grep-matches; the post-merge hook still passes `--overwrite` as a no-op)
- `scripts/setup-hooks.sh` — audited, left unchanged (intentional: post-merge hook keeps passing `--overwrite` for backwards compat with pre-fix machines mid-pull)

## Insights

<!-- Initial framing: this is the third defect in the skills-deploy "templates drift between workbench source and deployed copy" arc. D000012 added drift detection. D000013 added a post-merge hook to auto-sync. D000015 closes the loop by making sync the default at the command level — so the manual case (someone runs `skills-deploy install` directly) matches the automated case (the hook). The mental-model question is whether `skills-deploy install` is a "deploy" verb or a "merge" verb. The repo treats it as deploy. Make the default match. -->

## Journal
