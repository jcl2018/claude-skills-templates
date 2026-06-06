---
name: "Lock in Windows copy-mode parity for the in-place install==clone model (F000049 closer)"
type: user-story
id: "S000089"
status: active
created: "2026-06-06"
updated: "2026-06-06"
parent: "F000049"
repo: "/Users/chjiang/Documents/projects/claude-skills-templates"
branch: "cj-feat-20260606-002034-59468"
blocked_by: ""
---

## Lifecycle

### Phase 1: Track

1. Read parent tracker (F000049) + S000088 (the in-place model this verifies)
2. Use this story's working branch: `cj-feat-20260606-002034-59468`
3. Scaffold work item directory and TRACKER.md
4. Distill `DESIGN.md` from the /office-hours S5 design (`.gstack/gstack-s5-windows-parity-design-20260606.md`)
5. Scaffold `SPEC.md` (requirements, acceptance criteria, architecture, tradeoffs)
6. Scaffold `TEST-SPEC.md` (smoke + E2E test scenarios)
7. Atomic story — no child-task decomposition

**Gates:**
- [x] /office-hours design referenced (the S5 design doc, with the de-risking finding)
- [x] Working branch created (`branch` field populated)
- [x] DESIGN + SPEC + TEST-SPEC scaffolded
- [x] Acceptance criteria defined
- [x] Tasks broken down (N/A — atomic story)

### Phase 2: Implement

1. Read DESIGN + SPEC for context
2. Add the S5 assertion to `scripts/windows-smoke.sh`; docs note; close the epic
3. Run smoke tests as you go (TEST-SPEC `## Smoke Tests`)
4. Run `/CJ_personal-workflow check` on modified docs after updates
5. Update tracker: move through lifecycle phases, add journal entries
6. Update Files section with changed file paths

**Gates:**
- [ ] Acceptance criteria verified met
- [ ] Smoke tests pass
- [ ] Todos section reflects remaining work (no stale items)
- [ ] Files section updated with changed files

### Phase 3: Ship

1. Run `/CJ_personal-workflow check` — verify all validation passes
2. Verify smoke tests pass in CI (windows-latest + ubuntu)
3. Walk E2E manually — a copy-mode default install stamps in-place + resolves _cj-shared
4. Ensure all child tasks (if any) have shipped — N/A (atomic)
5. Run `/ship` — creates PR, bumps version, updates changelog (includes pre-landing code review)
6. STOP at PR (operator lands to close F000049)

❌ If `/CJ_personal-workflow check` finds issues: fix findings, re-run until clean
❌ If smoke or E2E fails: fix, re-run

**Gates:**
- [ ] `/CJ_personal-workflow check` — validation passed
- [ ] Smoke tests pass in CI
- [ ] E2E walked manually
- [ ] All children shipped (N/A — atomic)
- [ ] `/ship` — PR created (with pre-landing review)
- [ ] STOP at PR (operator reviews + lands → epic closed)

## Acceptance Criteria

- [ ] `scripts/windows-smoke.sh` asserts a copy-mode DEFAULT install stamps `install_mode: in-place` + `bundle_path == source`
- [ ] `scripts/windows-smoke.sh` asserts a copy-installed orchestrator resolves update-check from the `_cj-shared` deployed home with NO `.source` read
- [ ] The assertion runs green on BOTH lanes — windows-latest (`.github/workflows/windows.yml`) and ubuntu (`scripts/test.sh:506` via the `FORCE_COPY` override) — and on a symlink-capable host
- [ ] `CLAUDE.md` notes the in-place install==clone model holds under Windows copy-mode (the de-risking finding) AND records that the dir-symlink reinstall-free refinement was dropped (POSIX-only asymmetry, non-criterion, drift-detection cost)
- [ ] F000049 marked DONE in the parent TRACKER/ROADMAP; `validate.sh` + `scripts/test.sh` green; shellcheck clean; portability audit `FINDINGS=0`

## Todos

- [ ] Add the S5 in-place + `_cj-shared`-resolution assertion block to `scripts/windows-smoke.sh`
- [ ] CLAUDE.md Running-on-Windows note (parity holds; dir-symlink dropped + rationale)
- [ ] Close F000049 (parent ROADMAP/TRACKER) + VERSION 6.0.46 + CHANGELOG
- [ ] Green gate (validate + test + windows-smoke local + shellcheck + audit) + /ship

## Log

- 2026-06-06: Created. S5 of F000049 — the epic closer. De-risking finding: S4's install==clone-in-place + `.source` de-coupling ALREADY works under Windows copy-mode (the changes were platform-neutral by construction) — verified via a hermetic `FORCE_COPY` default install (in-place stamp + `_cj-shared` deposit + de-coupled orchestrators all hold). So S5 is a LOCK-IN story (windows-smoke assertion) + docs + epic close, NOT new parity code. Operator chose "Verify + close epic" (Approach A); the POSIX-only dir-symlink reinstall-free refinement is DROPPED (asymmetry + non-criterion + drift-detection cost), not deferred.

## PRs

<!-- PR links with status (open/merged/closed). -->

## Files

- `scripts/windows-smoke.sh` — the S5 assertion block (in-place stamp + `_cj-shared` update-check resolution under copy-mode); runs on both lanes
- `CLAUDE.md` — Running-on-Windows note (parity holds; dir-symlink dropped)
- `work-items/features/ops/F000049_*` — parent ROADMAP/TRACKER (epic DONE) + this story
- `VERSION` / `CHANGELOG.md` — 6.0.46
- `.gstack/gstack-s5-windows-parity-design-20260606.md` — the S5 /office-hours design

## Insights

The cleanest stories in this epic were the ones where the prior story's design was platform-neutral by construction — S5's whole "Windows parity" criterion was satisfied the moment S4 chose a manifest-stamp + `_cj-shared`-deposit + `_cj-shared`-resolution design that doesn't branch on symlink-vs-copy. The remaining work is to PROVE it with a CI assertion so a future change can't regress it silently. The dir-symlink reinstall-free idea is the one place where "more gstack" would have hurt: it trades a small convenience for a real POSIX/Windows asymmetry — exactly the opposite of parity.

## Journal

- 2026-06-06T00:20:00Z [decision] Operator chose "Verify + close epic" at the S5 design-gate AUQ after the de-risking finding showed S4's model already holds under copy-mode. Scope: a windows-smoke.sh lock-in assertion (both lanes) + docs + epic close. The dir-symlink reinstall-free refinement is DROPPED with rationale recorded in the design + CLAUDE.md (POSIX-only asymmetry, non-criterion, drift-detection cost) — not deferred.
