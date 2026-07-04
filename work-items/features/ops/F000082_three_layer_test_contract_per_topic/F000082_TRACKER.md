---
name: "Three-layer test contract per topic — local deterministic+agentic, enforced by the two cj_test_ skills"
type: feature
id: "F000082"
status: active
created: "2026-07-04"
updated: "2026-07-04"
repo: "E:/projects/claude-skills-templates/.claude/worktrees/inspiring-keller-69636a"
branch: "claude/inspiring-keller-69636a"
blocked_by: ""
---

<!-- Prerequisite: Before scaffolding this work item, run /office-hours to
     produce a design plan in ~/.gstack/projects/. Distill that plan into
     DESIGN.md during Phase 1 below. -->

## Lifecycle

### Phase 1: Track

1. Create working branch: `git checkout -b feat/three_layer_test_contract_per_topic`
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
- [ ] All child stories have entered Phase 2+
- [ ] Feature-level Todos reflect remaining coordination work

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

- [ ] AC1 — `topic:` parses + validates; all 12 existing `categories:` rows carry a topic; `--list-categories` shows it.
- [ ] AC2 — `topic_contracts: [portability]` parses; portability is enrolled.
- [ ] AC3 — `test-spec.sh --check-topic-contract` HARD-fails when portability is missing its agentic row/test/doc, PASSES once present; a `scripts/test.sh` negative test plants the fault (remove the agentic row) → expect fail → restore → pass, invoking ONLY the targeted engine (no whole-`validate.sh` re-run).
- [ ] AC4 — `validate.sh` gains the new hard Check; green on this repo; CI-safe (declaration-only, zero model spend).
- [ ] AC5 — `scripts/lib/agentic-sandbox.sh` exists (POSIX+LF); its deterministic helpers (neutral sandbox creation, `git init --bare` tagged upstream via `SKILLS_UPDATE_REMOTE_URL` — NO `git` shim) are unit-smoked with no model spend.
- [ ] AC6 — `tests/portability-version-agentic.test.sh` SKIPs cleanly without the local-only gate (so `test.sh`/CI never spend a model); when run locally with a login it drives `claude --print` (budget cap `$0.50`) and PASSES iff its `{surfaced_nudge, evidence}` verdict JSON shows the agent relayed the nudge.
- [ ] AC7 — `/CJ_test_run portability-version-agentic` (with `--e2e`/`--all`) runs it; a default `free` run SKIPs it; `/CJ_test_audit` Stage 1 reports it wired.
- [ ] AC8 — docs green: front-door doc has the three sections, `docs/tests/index.md` + `spec/doc-spec-custom.md` updated, `validate.sh` Checks 24/26/27/28 + `doc-spec --check-on-disk` pass.
- [ ] AC9 — CLAUDE.md + `spec/test-spec.md`/`--seed` + overlay prose updated; the grandfathered topics + follow-up TODOs recorded.

## Todos

<!-- Actionable items for this feature. Break into child tasks for
     large features. -->

- [ ] S000132 — implement the topic contract + portability agentic proof end-to-end (AC1–AC9)
- [ ] Schema + parser: add `topic:` (9th column) + `topic_contracts:` to `test-spec.sh` (parse/validate/list); backfill the 12 existing `categories:` rows across all six consumer sites.
- [ ] Engine: `test-spec.sh --check-topic-contract` + `validate.sh` Check + the targeted negative test in `scripts/test.sh`.
- [ ] Lib: `scripts/lib/agentic-sandbox.sh` (3 helpers) + its deterministic-helper smoke test.
- [ ] Proof: `tests/portability-version-agentic.test.sh` + the new `categories:` row + front-door doc + `docs/tests/index.md` + `spec/doc-spec-custom.md` declaration.
- [ ] Wiring: `/CJ_test_run` `--topic` selector; confirm `/CJ_test_audit` surfaces the new check.
- [ ] Docs: general seed + overlay + CLAUDE.md; file grandfather follow-up TODOs (cj-goal-eval / doc-sync / validator topics).

## Log

<!-- Chronological entries with dates and commit SHAs. -->

- 2026-07-04: Created. Three-layer test contract per topic — first-class `topic:` axis + per-topic enrollment + a hard declaration-only Check, with a reusable repo-neutral agentic-sandbox lib and portability enrolled as the first proof.

## PRs

<!-- PR links with status (open/merged/closed). -->

## Files

<!-- Affected file paths. Populated during Track phase, updated during Implement. -->

- `scripts/test-spec.sh` — `topic:` + `topic_contracts:` parse/validate/list + `--check-topic-contract`
- `scripts/test-run.sh` — `--topic` selector + category-mode slicer field widening
- `scripts/lib/agentic-sandbox.sh` — new reusable repo-neutral sandbox lib
- `scripts/validate.sh` — new hard Check (topic-contract)
- `scripts/test.sh` — paired negative test
- `tests/portability-version-agentic.test.sh` — the agentic proof (local-only)
- `spec/test-spec.md` + `spec/test-spec-custom.md` — general prose + overlay backfill/enrollment/row
- `docs/tests/index.md` + `spec/doc-spec-custom.md` — front-door doc + declaration
- `CLAUDE.md` — verification-contract + test-contract sections

## Insights

<!-- Non-obvious findings worth remembering. Design decisions,
     trade-offs, patterns discovered. -->

- The agentic layer is the one that catches green-but-inert bugs the deterministic layer structurally cannot: a stubbed test can pass green while the real preamble never surfaces the nudge to a human. The motivating hole is F000081's `portability-version-check` — deterministic-green, agentic-deferred.
- Enrollment (`topic_contracts:`) is the grandfather seam that makes a HARD Check safe to land: the workflow topics (`goal-*-eval`, `doc-sync`, `e2e-local`) are all local-hook *agentic-only* today, so a naive "every local-hook topic needs both modes" would red the build immediately. Portability enrolls first; the rest are labeled + deferred.
- The line between deterministic and agentic is drawn by *where it can run*: agentic lives at local-hook because that machine has Claude installed, which is exactly the constraint that keeps model spend out of CI (F000080 already moved all agentic tests local).
- Reuse the existing `SKILLS_UPDATE_REMOTE_URL` test seam (a `git init --bare` tagged upstream) instead of PATH-prepending a `git` shim — a `.sh` shim is fragile on Windows Git Bash where `git.exe` may not be intercepted, and the env-var seam is the same mechanism `e2e-local` already uses.
- Dual-write footgun: any edit to `spec/test-spec.md` requires the byte-identical edit to the `_emit_seed` heredoc in `test-spec.sh` (guarded by the seed-identity test). The `topic:`/`categories:` axes are overlay-only, so the general machine `yaml` block (rules + layers) does NOT change — only prose does.

## Journal

<!-- Structured entries from the work-track journal command. Each entry has a type
     (decision, finding, blocker) and a Summary field. -->

- [decision] 2026-07-04 — Chose Approach B (full topic contract + hard enforcement) over Approach A (advisory mode-aware NOTE) and Approach C (harness-first). Summary: the operator wants the contract to bite (a first-class `topic:` field + a hard Check), not to emit another advisory NOTE; the lib alone doesn't make any topic provably covered.
- [decision] 2026-07-04 — OQ2 RESOLVED: enrolled topics require all three layers (CI-push + CI-nightly + local-hook) AND the local both-modes pair (deterministic + agentic). Summary: portability already satisfies CI-push + CI-nightly, so requiring all three costs nothing and gives the stronger guarantee.
- [decision] 2026-07-04 — Reuse the `SKILLS_UPDATE_REMOTE_URL` remote seam; NO `git` PATH-shim. Summary: a `.sh` git shim is fragile on Windows Git Bash and reinvents an existing hook; the tagged-bare-upstream env seam is portable and already proven by `e2e-local`.
- [decision] 2026-07-04 — Landing sequence is atomic: build schema + lib + agentic test + row + doc FIRST, enroll `topic_contracts: [portability]` + wire the Check LAST. Summary: enrolling portability before its agentic row exists would make `validate.sh` fail on its own landing commit.
- [decision] 2026-07-04 — YAGNI on the lib: ship only the 3 helpers the first consumer (portability) uses (`mk_neutral_sandbox`, `mk_tagged_bare_upstream`, `run_preamble_via_claude`); no speculative 4th helper. Summary: refactoring `e2e-local`'s `sandbox.sh` onto it and the `eval.sh` migration are noted fast-follows, not this PR.
