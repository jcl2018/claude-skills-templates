---
name: "Demote the topic contract's agentic coverage point to ADVISORY (global) + enroll validator and full-suite as deterministic three-layer topics"
type: feature
id: "F000086"
status: active
created: "2026-07-06"
updated: "2026-07-06"
repo: "E:/projects/claude-skills-templates/.claude/worktrees/practical-kilby-0ee2a8"
branch: "claude/practical-kilby-0ee2a8"
blocked_by: ""
---

<!-- Prerequisite: Before scaffolding this work item, run /office-hours to
     produce a design plan in ~/.gstack/projects/. Distill that plan into
     DESIGN.md during Phase 1 below. -->

## Lifecycle

### Phase 1: Track

1. Working branch: `claude/practical-kilby-0ee2a8` (orchestrator worktree)
2. Scaffold work item directory and TRACKER.md
3. Distill `DESIGN.md` from the /office-hours output (problem shape, big decisions, risks) — from `templates/doc-DESIGN.md`
4. Scaffold `ROADMAP.md` (scope, non-goals, decomposition, delivery timeline) — from `templates/doc-ROADMAP.md`
5. Define acceptance criteria (what "done" looks like for the whole feature)
6. Decompose into child user-stories
   → detail (DESIGN, SPEC, TEST-SPEC) lives in child stories

**Gates:**
- [x] /office-hours design produced (in `~/.gstack/projects/jcl2018-claude-skills-templates/chang-claude-practical-kilby-0ee2a8-design-20260706-021054.md`)
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

- [ ] `bash scripts/test-spec.sh --check-topic-contract` exits 0 with `topic_contracts: [portability, validator, full-suite]` and prints exactly TWO advisory agentic notes (validator + full-suite; portability HAS an agentic row, so no note for it)
- [ ] Temp-registry drill: removing portability's agentic row → exit 0, advisory note present, `findings=0`; removing validator's CI-push row → exit 1, `FINDING:` line present
- [ ] `bash scripts/test-spec.sh --check-topic-docs` exits 0 (dream docs + topic subdirs present for all three enrolled topics)
- [ ] Seed identity holds: `test-spec.sh --seed` byte-identical to `spec/test-spec.md` (and `templates/` copy if applicable)
- [ ] `bash scripts/validate.sh` fully green (Checks 15/15a/17/19/24/26/27/30/31)
- [ ] `bash scripts/test.sh` green including the rewritten Check 30 negative drill; shellcheck green
- [ ] `bash scripts/test-run.sh --topic validator` and `--topic full-suite` resolve the new rows (free-tier rows run; nothing agentic executes by default)
- [ ] `skills/CJ_test_audit/SKILL.md` Stage 1 names `--check-topic-contract` + `--check-topic-docs` among its engine calls (the inherited-drift fix), and the advisory agentic notes appear in a Stage-1 report run against this repo

## Todos

<!-- Actionable items for this feature. Break into child tasks for
     large features. -->

- [x] Engine loop change: `scripts/test-spec.sh` `_run_topic_contract` — move the local-hook+agentic entry out of the FINDING path onto an advisory `note:` line (S000135)
- [x] General contract prose rewrite (`spec/test-spec.md` whole `## The topic axis` section + adjacent local-hook description) + byte-identical `_emit_seed` heredoc mirror (S000135)
- [x] Overlay: enroll `validator` + `full-suite`; rewrite the enrollment comment block (deploy-harness deferral + corrected unenrolled count of 5); reword the `validate-check-30` units row; add the FOUR new `categories:` rows (validate-hook, validate-nightly, suite-nightly, suite-local) (S000135)
- [x] Front-door docs: four `docs/tests/infra/<layer>/<name>.md` pages + `docs/tests/index.md` rows + per-file `spec/doc-spec-custom.md` declarations (S000135)
- [x] Check 31 topic docs: dream docs `docs/goals/validator.md` + `docs/goals/full-suite.md` + topic subdirs `docs/tests/topics/{validator,full-suite}/` (index + CI-push/CI-nightly/local-hook pages), all declared in `spec/doc-spec-custom.md` (S000135)
- [x] /CJ_test_audit Stage-1 wiring: add `--check-topic-contract` + `--check-topic-docs` to the engine-call list + the conditional Stage-2 agentic-row judgment clause; USAGE.md freshness rides along (S000135)
- [x] Tests: rewrite the Check 30 negative drill in `scripts/test.sh` (deterministic-point removal → FINDING; agentic-row removal → NO finding + advisory note); sweep `tests/test-spec.test.sh` (expected no-op — confirmed) (S000135)
- [x] Prose sweep: `scripts/validate.sh` Check 30 header/banner/pass-message (preserve the literal `"=== Check 30:"` anchor), stale "portability today" strings, CLAUDE.md sections, `docs/goals/portability.md` + topic subdir both-modes mentions, TODOS.md PARTIAL annotation (S000135)

## Log

<!-- Chronological entries with dates and commit SHAs. -->

- 2026-07-06: Created. Demote the topic contract's local-hook+agentic coverage point to ADVISORY for all enrolled topics and enroll validator + full-suite as deterministic three-layer topics.

## PRs

<!-- PR links with status (open/merged/closed). -->

## Files

<!-- Affected file paths. Populated during Track phase, updated during Implement. -->

- `scripts/test-spec.sh` (engine `_run_topic_contract` + `_emit_seed` heredoc)
- `spec/test-spec.md` (topic-axis prose)
- `spec/test-spec-custom.md` (enrollment + 4 categories rows + units-row rewording)
- `spec/doc-spec-custom.md` (~14 new declaring rows)
- `docs/tests/infra/<layer>/*.md`, `docs/tests/index.md`, `docs/goals/{validator,full-suite}.md`, `docs/tests/topics/{validator,full-suite}/`
- `skills/CJ_test_audit/SKILL.md` (+ USAGE.md freshness)
- `scripts/validate.sh` (Check 30 prose), `scripts/test.sh` (Check 30 drill + Step 3j comment)
- `CLAUDE.md`, `TODOS.md`

## Insights

<!-- Non-obvious findings worth remembering. Design decisions,
     trade-offs, patterns discovered. -->

- Enrollment stops being gated on the hardest-to-build test mode: the deterministic three-layer skeleton (per-PR, nightly, local hook) is what actually stops rot; the agentic point stays visible as a per-topic advisory note wherever the contract is READ, without ever redding a build.
- The advisory demotion is a global simplification chosen over a per-topic deterministic-only flavor (informed reversal at D4): the operator's standing posture is "agentic proofs run on-demand / via another agent — never a requirement," so machinery preserving the distinction would be maintained for nothing.
- Honest coverage beats complete-looking coverage: `deploy-harness` deliberately stays UNENROLLED because its missing CI-push point is an F000081 speed decision, and claiming windows-smoke (labeled `portability`) as its CI-push row would double-count.
- This change formalizes a multi-agent split already in practice: deterministic proofs enforced by the repo, agentic proofs delegated to whoever (or whatever) can run them.
- Re-hardening is cheap if agentic proofs ever become cheap here: a one-line reversal (move the agentic entry back into the FINDING loop) plus the same prose/seed mirror.

## Journal

<!-- Structured entries from the work-track journal command. Each entry has a type
     (decision, finding, blocker) and a Summary field. -->

- [decision] 2026-07-06 — Summary: Premise 1 REVISED at D4 (informed reversal): the agentic coverage point demotes to ADVISORY for ALL enrolled topics — no new enrollment syntax, no per-topic flavor; portability's agentic test stays in the repo, declared and runnable via `/CJ_test_run --topic portability --e2e`, but is no longer REQUIRED by Check 30. Approach C chosen over the session-recommended Approach A.
- [decision] 2026-07-06 — Summary: `deploy-harness` stays unenrolled (F000081 speed decision; windows-smoke is labeled `portability` and must not be double-counted); documented in the overlay comment + a TODOS note.
- [finding] 2026-07-06 — Summary: inherited drift — CLAUDE.md + the spec have claimed `/CJ_test_audit` Stage-1 surfacing of `--check-topic-contract` / `--check-topic-docs` (plus a Stage-2 agentic-row judgment) since F000082, but the skill never invokes either engine call; this feature wires both.
- 2026-07-06 [impl] Implementation complete via child S000135 (all 8 feature todos closed): engine advisory demotion + prose/seed mirror + validator/full-suite enrollment (4 new deterministic rows) + front-door/dream/topic docs (14 new doc-spec rows) + /CJ_test_audit Stage-1/Stage-2 wiring + both-direction Check 30 drill + full prose sweep. Verified: topic contract exit 0 with exactly two advisory notes + findings=0, topic docs enrolled=3 findings=0, seed byte-identity, render-docs --check clean, both drill arms, --topic dry-runs resolve, shellcheck clean. See S000135_TRACKER.md journal for the detailed [impl] trail.
