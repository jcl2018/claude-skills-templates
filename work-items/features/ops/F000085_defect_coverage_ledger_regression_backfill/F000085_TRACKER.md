---
name: "Defect-coverage ledger + regression-category materialization (backfill all defects as regression tests)"
type: feature
id: "F000085"
status: active
created: "2026-07-06"
updated: "2026-07-06"
repo: "E:/projects/claude-skills-templates/.claude/worktrees/affectionate-villani-b5b6f4"
branch: "claude/affectionate-villani-b5b6f4"
blocked_by: ""
---

<!-- Prerequisite: Before scaffolding this work item, run /office-hours to
     produce a design plan in ~/.gstack/projects/. Distill that plan into
     DESIGN.md during Phase 1 below. -->

## Lifecycle

### Phase 1: Track

1. Create working branch: `git checkout -b feat/{slug}`
2. Scaffold work item directory and TRACKER.md
3. Distill `DESIGN.md` from the /office-hours output (problem shape, big decisions, risks) — from `templates/doc-DESIGN.md`
4. Scaffold `ROADMAP.md` (scope, non-goals, decomposition, delivery timeline) — from `templates/doc-ROADMAP.md`
5. Define acceptance criteria (what "done" looks like for the whole feature)
6. Decompose into child user-stories
   → detail (DESIGN, SPEC, TEST-SPEC) lives in child stories

**Gates:**
- [x] /office-hours design produced (in `~/.gstack/projects/`)
- [x] Working branch created (`branch` field populated)
- [x] DESIGN + ROADMAP scaffolded
- [x] Acceptance criteria scoped
- [x] Broken down into child stories

### Phase 2: Implement

1. Child user-stories drive implementation (feature tracker coordinates)
2. Monitor child progress — update this tracker when children complete phases
3. Update Todos section — check off completed children, add discoveries
4. Update Files section with top-level changed files

**Gates:**
- [x] All child stories have entered Phase 2+
- [x] Feature-level Todos reflect remaining coordination work

### Phase 3: Ship

1. Run `/CJ_personal-workflow check` — verify all children pass validation
2. Verify smoke tests pass in CI (automated regression)
3. Walk E2E manually — run user-scenario verification before ship
4. Run `/ship` — creates feature PR (includes pre-landing code review)
5. Run `/land-and-deploy` — merges and verifies deployment
6. Run `/document-release` — post-ship doc audit; fix drifts inline or spawn D-tickets

**Gates:**
- [ ] `/CJ_personal-workflow check` — all children pass validation
- [ ] Smoke tests pass in CI
- [ ] E2E walked manually
- [ ] `/ship` — PR created (with pre-landing review)
- [ ] `/land-and-deploy` — merged and deployed
- [ ] `/document-release` — post-ship doc audit done; drifts fixed inline or spawned as D-tickets

## Acceptance Criteria

<!-- What "done" looks like for this feature. Each criterion should be
     testable and specific. -->

- [ ] `bash scripts/test-spec.sh --check-defect-coverage` reports 38/38 defect dirs dispositioned with 0 findings on this repo, and a NAMED vacuous SKIP (exit 0) in a bare consumer repo (no registry / no axis / no `work-items/defects/`)
- [ ] `validate.sh` is green including the new HARD, registry-gated Check 32; the hermetic `scripts/test.sh` negative test proves the gate fires (plant → finding → restore → pass) with TWO plants: an unmapped defect dir (forward FINDING) and a `covered-by` row citing a `mode: agentic` categories row (mode FINDING)
- [ ] `bash scripts/test-spec.sh --list-categories --category regression` returns ≥4 rows, ALL `mode: deterministic` + `tier: free`; `/CJ_test_run --category regression` runs them green with zero model spend
- [ ] Check 24 is green after the reverse-sweep token-grammar change; the `tests/workflow/local-hook/doc-sync.test.sh` orphan is wired (invoked by `scripts/test.sh` + owned by a `units:` row)
- [ ] Structure checks (a–f) are green with `tests/regression/CI-push/` + `docs/tests/regression/CI-push/*.md` (three front-door sections, described in words — no D-IDs, per Check 19)
- [ ] Full `scripts/test.sh` + shellcheck green locally before push (the CI gate runs all three)
- [ ] The stale "29 flat tests" migration comment in `spec/test-spec-custom.md` (~line 1580) is rewritten to the scoped truth; every waived-gap disposition has a TODOS.md row; the Check-30/agentic-purge collision TODOS row is filed

## Todos

<!-- Actionable items for this feature. Break into child tasks for
     large features. -->

- [x] S000134 Stage 1 (ledger, commits 1–3): `defect_coverage:` grammar + parser + `--list-defect-coverage`; `--check-defect-coverage` engine check; Check 32 wiring + `validate-check-32` units row + hermetic negative test (two plants) + verified 38-row backfill + `/CJ_test_audit` Stage-1 wiring + TODOS rows — commits `a6ffcd6` / `35c87f9` / `b752856`
- [x] S000134 Stage 2 (migration, commits 4–6): reverse-sweep token grammar (full relative-path tokens, recursed glob) + doc-sync orphan resolution; `git mv` the 4 pure drills → `tests/regression/CI-push/` with same-commit invocation-line + anchor updates; regression `categories:` rows + front-door docs + doc-spec declarations + stale-prose fix + catalog regen — commits `64776e1` / `434c3f7` / `cabacea`
- [x] Keep commits ordered LEDGER-FIRST so a migration red at QA descopes to ledger-only without losing the ledger (intermediate-state rule: MIGRATE rows land as `covered-by-anchor` at commit 3, re-anchor at commit 5, flip to `covered-by` at commit 6) — held: every commit verified green under Checks 24 + 32 before the next
- [x] File TODOS.md rows: remaining waived-gap drills (D-ID-gates drill row); portability topic un-enrollment before the agentic-test purge (Check 30 collision)
- [ ] QA (/CJ_qa-work-item) + full `scripts/test.sh` + shellcheck before /ship; post-land assignment: run `/CJ_test_run --category regression` on BOTH machines

## Log

<!-- Chronological entries with dates and commit SHAs. -->

- 2026-07-06: Created. Defect-coverage ledger (`defect_coverage:` overlay axis + Check 32 + verified 38-dir backfill) plus scoped migration of pure defect drills into `tests/regression/<layer>/`, one PR, ledger-first commits. Scaffolded from the APPROVED /office-hours design.
- 2026-07-06: S000134 implemented — six ledger-first commits (`a6ffcd6` grammar+parser, `35c87f9` engine check, `b752856` Check 32 + negative test + verified 38-row backfill [Stage-1/descope point], `64776e1` sweep token grammar + doc-sync orphan wired, `434c3f7` the 4 `git mv` moves, `cabacea` regression rows + docs + flip). Live at HEAD: 38/38 dispositioned findings=0 (24 covered-by-anchor / 4 covered-by / 10 waived, 1 gap+todo); `validate.sh` PASS incl. Check 32; regression category 4/4 green model-free; Check 24 + structure a–f green.

## PRs

<!-- PR links with status (open/merged/closed). -->

## Files

<!-- Affected file paths. Populated during Track phase, updated during Implement. -->

- `spec/test-spec-custom.md` — new `defect_coverage:` overlay axis + regression `categories:` rows + stale-prose fix
- `scripts/test-spec.sh` — parser + `--list-defect-coverage` + `--check-defect-coverage` + reverse-sweep token grammar
- `scripts/validate.sh` — new Check 32 (HARD, registry-gated)
- `scripts/test.sh` — hermetic negative test; doc-sync orphan wiring; migrated-drill invocation-line updates
- `tests/regression/CI-push/` — migrated pure defect drills (4 files)
- `docs/tests/regression/CI-push/*.md` + `docs/tests/index.md` + `docs/test-catalog.md` — front-door docs + regenerated catalogs
- `spec/doc-spec-custom.md` — declarations for the new per-test docs
- `skills/CJ_test_audit/` — Stage-1 wiring for `--check-defect-coverage` (capability-probe idiom)
- `TODOS.md` — waived-gap follow-ups + agentic-purge prep row

## Insights

<!-- Non-obvious findings worth remembering. Design decisions,
     trade-offs, patterns discovered. -->

- "The product is the ledger, not the tests" — the axis + gate is ~90% of the value at ~20% of the risk; migration is cosmetic legibility on load-bearing machinery (cross-model cold read, adopted).
- Without a declared ledger, proof is indistinguishable from folklore: an in-session inventory agent confidently cited two nonexistent test files — the exact failure a machine-checked ledger makes structurally impossible.
- Deterministic-only regression rows (engine-enforced: `covered-by` citing an agentic row is a FINDING) design today's contract around tomorrow's planned agentic-test purge.
- The reverse-sweep recursion is a TOKEN GRAMMAR change, not glob surgery: basename tokens + the `scripts/test.sh` source pin + the live doc-sync orphan mean naive recursion breaks token matching.
- Ledger-first commit ordering inside one PR preserves the descope-on-red property the two-PR packaging would have given (chosen Single-PR Full anyway — complete end state over comfortable increment).
- The ledger MUST key on full dir paths relative to `work-items/defects/` — D000021 is a genuinely duplicated bare ID across two component dirs.

## Journal

<!-- Structured entries from the work-track journal command. Each entry has a type
     (decision, finding, blocker) and a Summary field. -->

- [decision] 2026-07-06 — Summary: Single-PR Full (Approach B) chosen over ledger-only (A) and inline extraction (C); ledger-first commit ordering is the descope-on-red escape hatch at QA.
- [decision] 2026-07-06 — Summary: Deterministic-only constraint (P6) engine-enforced — a `covered-by` citing a `mode: agentic` categories row is a FINDING, so the planned agentic-test purge cannot orphan the ledger.
- [decision] 2026-07-06 — Summary: Three closed dispositions (`covered-by`, `covered-by-anchor`, `waived`) — the inline `scripts/test.sh` D-block battery keeps its single coarse units row and is referenced via `covered-by-anchor`, never split (rejected Approach C).
