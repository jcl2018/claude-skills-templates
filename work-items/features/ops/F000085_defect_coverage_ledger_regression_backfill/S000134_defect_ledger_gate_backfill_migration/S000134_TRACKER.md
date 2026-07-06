---
name: "Defect-coverage ledger (axis + Check 32 + 38-dir backfill) + regression migration, ledger-first"
type: user-story
id: "S000134"
status: active
created: "2026-07-06"
updated: "2026-07-06"
parent: "F000085"
repo: "E:/projects/claude-skills-templates/.claude/worktrees/affectionate-villani-b5b6f4"
branch: "claude/affectionate-villani-b5b6f4"
blocked_by: ""
---

<!-- Prerequisite: Before scaffolding this work item, run /office-hours to
     produce a design plan in ~/.gstack/projects/. Distill that plan into
     DESIGN.md during Phase 1 below. (For atomic stories that derive directly
     from the parent feature's /office-hours session, the parent's design is
     sufficient context — DESIGN.md may be a brief stub linking to the parent.) -->

## Lifecycle

### Phase 1: Track

1. Read parent tracker to understand scope
2. Create working branch: `git checkout -b feat/{slug}` (or use parent's branch if shipping in same PR)
3. Scaffold work item directory and TRACKER.md
4. Distill `DESIGN.md` from the /office-hours output (own session or parent's) — from `templates/doc-DESIGN.md`
5. Scaffold `SPEC.md` (requirements, acceptance criteria, architecture, tradeoffs) — from `templates/doc-SPEC.md`
6. Scaffold `TEST-SPEC.md` (smoke + E2E test scenarios) — from `templates/doc-TEST-SPEC.md`
7. Break into child tasks if scope warrants decomposition (per WORKFLOW.md, tasks are optional for atomic stories)

**Gates:**
- [x] /office-hours design referenced (own or parent's, captured in DESIGN.md)
- [x] Working branch created (`branch` field populated)
- [x] DESIGN + SPEC + TEST-SPEC scaffolded
- [x] Acceptance criteria defined
- [x] Tasks broken down (N/A — atomic story; the six-commit ordering inside one story IS the decomposition)

### Phase 2: Implement

1. Read DESIGN + SPEC for context
2. Implement according to architecture decisions in SPEC
3. Run smoke tests as you go (TEST-SPEC `## Smoke Tests` table)
4. Run `/CJ_personal-workflow check` on modified docs after updates
5. Update tracker: move through lifecycle phases, add journal entries
6. Update Files section with changed file paths

**Gates:**
- [ ] Acceptance criteria verified met
- [ ] Smoke tests pass
- [x] Todos section reflects remaining work (no stale items)
- [x] Files section updated with changed files

### Phase 3: Ship

1. Run `/CJ_personal-workflow check` — verify all validation passes
   → should show PASS for template, lifecycle, traceability badges
2. Verify smoke tests pass in CI (automated regression)
3. Walk E2E manually — drive the feature as a user would (TEST-SPEC `## E2E Tests` table)
4. Ensure all child tasks (if any) have shipped
5. Run `/ship` — creates PR, bumps version, updates changelog (includes pre-landing code review)
6. Run `/land-and-deploy` — merges PR and verifies deployment

❌ If `/CJ_personal-workflow check` finds issues: fix findings, re-run until clean
❌ If smoke or E2E fails: fix, re-run

**Gates:**
- [ ] `/CJ_personal-workflow check` — validation passed
- [ ] Smoke tests pass in CI
- [ ] E2E walked manually
- [ ] All children shipped (if any)
- [ ] `/ship` — PR created (with pre-landing review)
- [ ] `/land-and-deploy` — merged and deployed

## Acceptance Criteria

<!-- What "done" looks like for this story. -->

- [ ] AC-1: `defect_coverage:` overlay axis parses — `--validate` passes with the new block (disposition closed-enum + duplicate-`defect:`-key checks); `--list-defect-coverage` echoes parsed rows; block placed LAST in the overlay yaml and added to the eight block-close regexes
- [ ] AC-2: `--check-defect-coverage` runs forward (every `work-items/defects/**/D??????_*` dir has exactly one row) + reverse (dir exists; `covered-by` resolves to a live deterministic `categories:` row; `covered-by-anchor` greps live; `waived` has non-empty reason); named vacuous SKIP (exit 0) when registry/axis/`work-items/defects/` absent; prints the machine-classifiable summary/inactive lines
- [ ] AC-3: `validate.sh` Check 32 (HARD, registry-gated) wired with its `validate-check-32` `units:` row; `/CJ_test_audit` Stage 1 surfaces the check via the `--help` capability-probe idiom
- [ ] AC-4: hermetic `scripts/test.sh` negative test with TWO plants — unmapped defect dir → forward FINDING; `covered-by` citing a `mode: agentic` row → mode FINDING — each restore → pass, engine-only
- [ ] AC-5: full 38-row verified backfill (verify-before-declare; every verification failure defaults to `waived: "gap — …"` + TODOS row; in-PR gap drills only if ≤30-line shape-guard, cap 3); TODOS rows filed for waived-gaps + the Check-30/agentic-purge collision
- [ ] AC-6: reverse-sweep token grammar moved to full relative-path tokens at both sites, glob recursed (`tests/*.test.sh` + `tests/*/*/*.test.sh`), `$5 == "scripts/test.sh"` pin preserved; `tests/workflow/local-hook/doc-sync.test.sh` orphan wired into `scripts/test.sh` + owned by a `units:` row; Check 24 green
- [ ] AC-7: 4 pure drills `git mv`'d to `tests/regression/CI-push/` with same-commit `scripts/test.sh` invocation-line + owning-units-row `anchor:` updates (`source:` stays `scripts/test.sh`); ledger rows re-anchored at the move commit, flipped to `covered-by` at the rows commit (intermediate-state rule — every commit green under Check 32)
- [ ] AC-8: one regression `categories:` row per migrated drill (`category: regression`, `layer: CI-push`, `mode: deterministic`, `tier: free`); front-door docs seeded + filled in words (no D-IDs) + declared in `spec/doc-spec-custom.md`; stale ~:1580 comment rewritten; catalogs regenerated; `--list-categories --category regression` ≥4 rows; `/CJ_test_run --category regression` green, zero model spend

## Todos

<!-- Actionable items for this story. -->

- [x] Commit 1: grammar + parser (`defect_coverage:` axis, block-close regexes, `--list-defect-coverage`, `--validate` enums + duplicate guard) — `a6ffcd6`
- [x] Commit 2: `--check-defect-coverage` engine check (forward/reverse + mode gate + vacuous skips + summary/inactive output strings) — `35c87f9`
- [x] Commit 3: Check 32 wiring + `validate-check-32` units row + hermetic negative test (two plants) + verified 38-row backfill (MIGRATE rows as `covered-by-anchor` against current flat proof) + `/CJ_test_audit` Stage-1 wiring + TODOS rows — `b752856`
- [x] Commit 4: sweep token grammar (both sites, recursed glob) + doc-sync orphan wired + its units row — `64776e1`
- [x] Commit 5: `git mv` the 4 pure drills → `tests/regression/CI-push/` + same-commit invocation-line + anchor + ledger re-anchor updates — `434c3f7`
- [x] Commit 6: regression `categories:` rows + `--seed-docs` + front-door sections + doc-spec declarations + stale-prose fix + `--render-docs` regen + flip MIGRATE rows to `covered-by` — `cabacea`
- [ ] Run full `scripts/test.sh` + shellcheck locally before push (QA owns the full-suite run; validate.sh + CI-set shellcheck + every touched/moved sub-suite already ran green during implementation)

## Log

<!-- Chronological entries with dates and commit SHAs. -->

- 2026-07-06: Created. Defect-coverage ledger + gate + verified backfill plus scoped regression migration, one PR, ledger-first commits. Scaffolded from the parent feature's APPROVED /office-hours design.
- 2026-07-06: Implemented — six ledger-first commits `a6ffcd6` → `35c87f9` → `b752856` (Stage 1: ledger complete, descope point) → `64776e1` → `434c3f7` → `cabacea` (Stage 2: migration). Live verification at HEAD: `--check-defect-coverage` dirs=38 rows=38 findings=0; `--check-coverage` findings=0 (73 reverse tokens, recursed); `--check-structure` a–f findings=0; full `validate.sh` PASS incl. new Check 32; `test-run.sh --category regression` aggregate pass (4/4 green, zero model spend); the 4 moved drills + the newly wired doc-sync test pass standalone; CI-set shellcheck clean.

## PRs

<!-- PR links with status (open/merged/closed). -->

## Files

<!-- Affected file paths. -->

- `spec/test-spec-custom.md` — modified: `defect_coverage:` axis (38 rows, LAST block) + schema prose section + `validate-check-32` and `test-doc-sync-workflow` units rows + 4 regression `categories:` rows + 4 moved-drill anchor updates + stale-prose rewrite
- `scripts/test-spec.sh` — modified: `_parse_defect_coverage` + 8 block-close regex updates + `--list-defect-coverage` + `--validate` disposition-enum/dup-key gates + `_run_defect_coverage`/`--check-defect-coverage` + reverse-sweep token grammar (full rel-path tokens, recursed glob, both sites)
- `scripts/validate.sh` — modified: Check 32 (HARD, registry-gated)
- `scripts/test.sh` — modified: Step 3k hermetic negative test (two plants + restore-pass) + D000018/D000025 in-PR shape-guard drills + doc-sync front-door invocation + 4 moved-drill invocation-line rewrites
- `tests/regression/CI-push/{tag-release,cj-goal-jq-crlf,drain-one-todo-helper-unavailable,drain-one-todo-worktree-resolve}.test.sh` — moved (`git mv`) from flat `tests/`, header path + `REPO_ROOT` depth fixed
- `tests/workflow/local-hook/doc-sync.test.sh` — wired into `scripts/test.sh` (not moved; owned by the new `test-doc-sync-workflow` units row)
- `docs/tests/regression/CI-push/*.md` — NEW (4): seeded front doors, Explanation filled in words (ID-free)
- `docs/tests/index.md`, `docs/test-catalog.md`, `docs/tests/validate.md`, `docs/tests/test.md` — regenerated
- `spec/doc-spec-custom.md` — modified: 4 new per-test doc declarations
- `skills/CJ_test_audit/SKILL.md` + `USAGE.md` — modified: Stage-1 `--check-defect-coverage` capability-probe block
- `TODOS.md` — modified: agentic-purge/Check-30 sequencing row + D000019 gap-drill row

## Insights

<!-- Non-obvious findings worth remembering. -->

- The ledger keys on full dir paths relative to `work-items/defects/` because D000021 is a genuinely duplicated bare ID across two component dirs.
- A `units:` row pointing `source:` at its own test file would self-satisfy the forward grep — moved files keep `source: scripts/test.sh` and update only `anchor:`.
- The intermediate-state rule (anchor → re-anchor → flip) is what makes descope-on-red real: every commit and the descoped ledger-only end state stay green under Check 32.

## Journal

<!-- Structured entries from the work-track journal command. Each entry has a type
     (decision, finding, blocker) and a Summary field. -->

- [decision] 2026-07-06 — Summary: atomic story (no task children) — the six-commit ledger-first ordering inside one story is the decomposition; splitting stages into separate stories would break the Single-PR Full wedge.
- [impl-finding] 2026-07-06 — Summary: --auto demoted to orchestrator-approved run: the change touches sensitive surfaces (scripts/validate.sh, scripts/test.sh) and far exceeds 2 files, so per-invocation auto could not apply; the sensitive-surface approval is carried from the operator's APPROVED design doc + the /CJ_goal_feature design gate (subagent context has no AUQ tool — the orchestrator directive documented this mechanical default).
- [impl-decision] 2026-07-06 — Summary: --validate enforces ONLY the disposition closed-enum + duplicate-defect-key (the design's exact wording, the categories: precedent); the per-disposition proof-field/liveness requirements are --check-defect-coverage FINDINGs, so a mid-backfill overlay still validates while the check names the gaps.
- [impl-decision] 2026-07-06 — Summary: spent 2 of the 3 in-PR gap-drill budget on ≤30-line no-fixture shape-guards in scripts/test.sh — the QA-E2E-execution-contract guard (leaf-node defer directive + parent-inline execution path in qa.md) and the D-ID-allocator depth-cap guard (find over DEFECTS_ROOT exists + carries no -maxdepth) — flipping both defects to covered-by-anchor; the remaining true gap (type-aware QA pipeline gates) needs more than a prose grep, so it stays waived with a filed TODOS row.
- [impl-finding] 2026-07-06 — Summary: verify-before-declare shifted several provisional dispositions: the two nonexistent-file citations resolved to REAL live proofs elsewhere (doc-audit remediation → the overlay suite's 8b-2 case; the reverse-floor namespaces → the test-spec suite's surface-gating case); the copilot pair verified as covered (the path-traversal doctor test; the bundle-existence validate check); five provisional covered/VERIFY rows became waived on retired/removed surfaces (investigate reshape, preamble-AUQ retirement, portability-audit verb retirement, milestones→ROADMAP migration, agent-judged promotion gate). Final: 24 covered-by-anchor, 4 covered-by, 10 waived (1 gap + todo).
- [impl-finding] 2026-07-06 — Summary: the negative test's REPO_ROOT override goes through `env` (not subshell `export`) — exporting REPO_ROOT inside a $( ) subshell in scripts/test.sh trips SC2030/2031, the same class the Check-30 drill's comment warns about; `env VAR=... bash ...` sidesteps shellcheck's subshell-modification analysis entirely.
- [impl-finding] 2026-07-06 — Summary: the 4 moved drills all resolved REPO_ROOT as SCRIPT_DIR/.. — moving them 2 levels deeper required the same-commit ../../.. fix (the doc-sync nested test's existing idiom); a move without it would have passed the sweep but failed at runtime.
- [impl] 2026-07-06 — Summary: wrote 4 new files (front-door docs), moved 4 (git mv → tests/regression/CI-push/), modified 10 (test-spec.sh, validate.sh, test.sh, both overlays, CJ_test_audit SKILL+USAGE, TODOS.md, S000134/F000085 trackers) + 4 regenerated catalogs, across 6 ledger-first commits a6ffcd6/35c87f9/b752856/64776e1/434c3f7/cabacea; every commit verified green (validate + engine checks) before the next.
- [impl-pass] 2026-07-06 — Summary: S000134: implementation complete. Phase 2 implementer-owned gates transitioned.
