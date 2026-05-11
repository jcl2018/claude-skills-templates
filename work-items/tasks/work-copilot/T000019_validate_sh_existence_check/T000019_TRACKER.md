---
name: "scripts/validate.sh existence check for work-copilot/prompts + work-copilot/domain"
type: task
id: "T000019"
status: active
created: "2026-05-11"
updated: "2026-05-11"
parent: "F000015"
repo: "/Users/chjiang/Documents/projects/claude-skills-templates"
branch: "claude/zealous-antonelli-5f8036"
blocked_by: ""
---

<!-- This task originates from F000015_work_copilot_pipeline design doc § Next Steps #2.
     S000030's QA smoke S5 caught the gap (validate.sh exit 0 when qa.prompt.md removed).
     Skipping a separate /office-hours session per the "skip-design-for-small-todos" convention. -->

## Lifecycle

### Phase 1: Track

1. Read parent F000015 design doc § Bundle / Deploy Changes → "Changes to scripts/validate.sh"
2. Working branch: use parent's `claude/zealous-antonelli-5f8036` (ships in same PR as F000015)
3. Scaffold: test-plan.md from `templates/CJ_personal-workflow/doc-test-plan.md`
4. Files section populated (scripts/validate.sh)
5. Todos derived from parent design doc's existence-check spec

**Gates:**
- [x] Parent scope read (F000015 design doc Next Steps #2 + S000030 QA finding)
- [x] Working branch (parent's branch — shipping in same PR)
- [x] Required docs scaffolded (test-plan)
- [x] Files section populated

### Phase 2: Implement

1. Add an existence check block to `scripts/validate.sh` that asserts:
   - `work-copilot/prompts/*.prompt.md` is present (expected set: validate, qa, implement, scaffold, investigate, ship, pipeline — 7 files when F000015 ships fully; for now, gate only on files that are KNOWN to exist after their child story ships)
   - `work-copilot/domain/*.template.md` is present (expected set: domain-knowledge, coding-conventions, architecture-overview — 3 files; gates only after S000033 ships)
2. The check is independent of `MIRROR_SPECS` byte-mirror — these files are work-copilot/-only.
3. Commit incrementally with descriptive messages.

**Gates:**
- [ ] Core changes committed (>=1 commit SHA in Log)
- [x] Todos section reflects remaining work (no stale items)
- [x] Files section updated with changed files

### Phase 3: Ship

1. Run `/CJ_personal-workflow check` — verify no regressions
2. Verify test-plan: all test scenarios passing
3. Run `/ship` — creates PR, bumps version, updates changelog
4. Run `/land-and-deploy` — merges PR and verifies deployment

❌ If tests fail: fix, re-run
❌ If CI fails: fix, push, re-run `/ship`

**Gates:**
- [ ] `/CJ_personal-workflow check` — validation passed
- [ ] Test-plan verified (all scenarios passing)
- [ ] `/ship` — PR created
- [ ] `/land-and-deploy` — merged and deployed

## Todos

- [x] Add existence-check block to `scripts/validate.sh` after the existing MIRROR_SPECS Error check 10 section, scoped to `work-copilot/prompts/*.prompt.md` and `work-copilot/domain/*.template.md`.
- [x] Gate the check progressively: only require files whose owning child story has shipped. Hardcode current ship state (qa.prompt.md present; others optional until their stories ship).
- [x] Verify the check fires red when a known-shipped file is removed (synthetic test).
- [x] Verify the check stays green for the current bundle state.
- [ ] Update F000015 design doc's "Next Steps #2" line to reference T000019 as the owner. (Deferred to /ship-time doc-sync.)

## Log

- 2026-05-11: Created. Originated from F000015 design doc Next Steps #2 + S000030 post-QA halt-at-gate. Hand-scaffolded (skip-design-for-small-todos convention).

## PRs

## Files

- `scripts/validate.sh` (modified — new existence-check block after MIRROR_SPECS Error check 10)

## Insights

- The existence check is structurally distinct from `MIRROR_SPECS` byte-identity. MIRROR_SPECS asserts "bundle file is byte-identical to upstream source"; this check asserts "bundle file simply EXISTS." Both have to pass for a fully-shipped bundle, but they catch different drift modes.
- Progressive gating (require qa.prompt.md but not the others yet) keeps the check honest during the F000015 build-out. When S000031–S000035 ship, the expected-set list expands.

## Journal

- 2026-05-11 [scaffold] Hand-scaffolded; TRACKER + test-plan only (per personal-workflow task manifest: 2 artifacts).
- 2026-05-11 [impl-decision] Placed the new check as "Error check 10b" immediately after the MIRROR_SPECS loop (line 446) and before Error check 11 (manifest reconciliation). Rationale: structurally adjacent to MIRROR_SPECS (both check work-copilot/ bundle state) but operationally distinct (existence vs byte-identity). Keeps the validate.sh narrative flow logical.
- 2026-05-11 [impl-decision] EXPECTED_BUNDLE_FILES is a flat array hardcoded with the currently-shipped subset (validate.prompt.md, qa.prompt.md). Extension model: when each F000015 child user-story ships its prompt, append one line to the array. Documented in the inline comment block above the array so future-me sees the extension pattern.
- 2026-05-11 [impl] Added 28-line "Error check 10b" block to scripts/validate.sh (lines 447-474 after the MIRROR_SPECS loop). Wrote 2 new files: T000019_TRACKER.md + T000019_test-plan.md.
- 2026-05-11 [impl-finding] Test plan cases 1-4 all pass: (1) current state PASS for both validate.prompt.md + qa.prompt.md; (2) synthetic-delete of qa.prompt.md fires `FAIL: ... required but not present`, restore brings PASS; (3) existing MIRROR_SPECS Error check 10 behavior preserved (no overlap or shadow); (4) unshipped prompts (implement, scaffold, investigate, ship, pipeline) don't trigger because they're not in EXPECTED_BUNDLE_FILES.
- 2026-05-11 [impl-pass] T000019 implementation complete. Phase 2 implementer-owned gates (Todos / Files) transitioned. Core-changes-committed gate awaits /ship.
