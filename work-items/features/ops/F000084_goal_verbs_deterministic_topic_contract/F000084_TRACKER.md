---
name: "Backfill the three-layer topic contract for the three cj_goal verbs — goal-feature / goal-task / goal-defect as separately-enrolled DETERMINISTIC-ONLY workflow topics"
type: feature
id: "F000084"
status: active
created: "2026-07-06"
updated: "2026-07-06"
repo: "E:/projects/claude-skills-templates/.claude/worktrees/festive-margulis-b0841b"
branch: "claude/festive-margulis-b0841b"
blocked_by: ""
---

<!-- Prerequisite: Before scaffolding this work item, run /office-hours to
     produce a design plan in ~/.gstack/projects/. Distill that plan into
     DESIGN.md during Phase 1 below. -->

## Lifecycle

### Phase 1: Track

1. Create working branch: `git checkout -b feat/goal_verbs_deterministic_topic_contract`
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

- [ ] AC1 — `spec/test-spec-custom.md` gains the `topic_contracts_deterministic:` overlay key (same slug grammar as `topic_contracts:`); `test-spec.sh --validate` enforces slug validity + a CROSS-LIST duplicate guard (a topic may appear in only one enrollment list).
- [ ] AC2 — `test-spec.sh --check-topic-contract` gains the deterministic-only arm: for a det-enrolled topic it HARD-requires exactly three coverage points (≥1 `CI-push` + ≥1 `CI-nightly` + ≥1 `local-hook`+`deterministic`, each with its front-door doc) and does NOT require (but tolerates) agentic rows; the existing `topic_contracts:` four-point both-modes rule is unchanged (`portability` untouched).
- [ ] AC3 — BOTH `_run_topic_contract` AND `_run_topic_docs` iterate the UNION of the two enrollment lists ("either list non-empty" = active; each topic checked under its own list's rule), keeping the `topic contract: enrolled=N findings=M` summary format (`enrolled=` counts the union) and the `^(REGISTRY=absent|topic contract inactive)` grep contracts that `validate.sh` Checks 30/31 + `scripts/test.sh` parse.
- [ ] AC4 — the `spec/test-spec.md` topic-axis prose gains the deterministic-only flavor, mirrored byte-identically into the `_emit_seed` heredoc (seed-identity test green).
- [ ] AC5 — a targeted `scripts/test.sh` negative drill with THREE arms (engine-only, temp registry/docs copies): (1) remove a det-enrolled topic's CI-nightly row → finding; (2) remove a re-topic'd agentic eval row → det-enrolled topics still green; (3) hide a det-enrolled topic's dream doc via `TESTDOC_OUT` → topic-docs finding.
- [ ] AC6 — 4 new test scripts pass locally: `tests/cj-goal-defect-smoke.test.sh` (CI-push) + `tests/goal-feature-chain.test.sh` + `tests/goal-task-chain.test.sh` + `tests/goal-defect-chain.test.sh` (CI-nightly chain drills); the 3 chain drills register in `scripts/test.sh` under the `TEST_FAST=1` guard (`TEST_FAST=1 bash scripts/test.sh` SKIPs them; a full `test.sh` runs them).
- [ ] AC7 — 11 `categories:` rows land (9 NEW `workflow`/`deterministic`/`free` rows + 2 re-topic'd eval rows) + a `units:` row per NEW test script; the `cj-goal-eval` topic label no longer appears in the registry; `--check-structure` green (folders + front-door docs + INDEX + three sections per doc).
- [ ] AC8 — Check-31 doc surfaces land: 3 dream docs (`docs/goals/goal-{feature,task,defect}.md`) + 3 topic subdirs (`docs/tests/topics/goal-{feature,task,defect}/` each with `index.md` + `CI-push.md` + `CI-nightly.md` + `local-hook.md`) + 9 front-door docs; all declared in `spec/doc-spec-custom.md` (human-docs, no work-item IDs).
- [ ] AC9 — prose truthfulness sweeps land in the same PR: the `TEST_FAST` guard comment + overlay prose + `test-deploy` row `purpose:` name the chain drills; the `topic_contracts:` header comment reflects the two enrollment lists + the retired `cj-goal-eval` label; the Check 30/31 `units:` purposes + `validate.sh` Check 30 banner state the two-list model.
- [ ] AC10 — enrollment lands LAST: `topic_contracts_deterministic: [goal-feature, goal-task, goal-defect]`; `bash scripts/test-spec.sh --check-topic-contract` reports the three det topics green + portability unchanged; `validate.sh` fully green (incl. Checks 24/26/30/31).
- [ ] AC11 — CLAUDE.md gains one line on the deterministic-only enrollment flavor; TODOS.md hygiene: "Enroll the grandfathered test topics" row marked PARTIAL + a `/CJ_goal_todo_fix` det-only enrollment follow-up row + an agentic-removal row enumerating the uncleared blockers (Check 28 workflow behaviors, Check 24 eval-unit anchors, portability's both-modes enrollment).

## Todos

<!-- Actionable items for this feature. Break into child tasks for
     large features. -->

- [ ] S000133 — implement the deterministic-only enrollment seam + per-verb goal topics end-to-end (AC1–AC11)
- [ ] Engine seam FIRST: `topic_contracts_deterministic:` parser + cross-list duplicate guard + det-only Check-30 arm + union iteration in `_run_topic_contract`/`_run_topic_docs` + seed dual-write + the 3-arm negative drill.
- [ ] 4 new test scripts (defect smoke first, then the 3 chain drills) + `scripts/test.sh` registration (chains under `TEST_FAST=1`).
- [ ] 11 `categories:` rows (9 new + 2 re-topic'd) + `units:` rows + 9 front-door docs.
- [ ] 3 dream docs + 3 topic subdirs; declare all new docs in `spec/doc-spec-custom.md`.
- [ ] Prose sweeps: TEST_FAST guard/overlay/test-deploy purpose; `topic_contracts:` header comment; Check 30/31 self-describing surfaces (units purposes + validate banner).
- [ ] Enroll `topic_contracts_deterministic: [goal-feature, goal-task, goal-defect]` LAST; regenerate catalogs (`test-spec.sh --render-docs`, `workflow-spec.sh --render-docs`); README regen if counts change.
- [ ] CLAUDE.md one-liner + TODOS.md hygiene (PARTIAL mark + todo_fix follow-up + agentic-removal blockers row).

## Log

<!-- Chronological entries with dates and commit SHAs. -->

- 2026-07-06: Created. Backfill the three-layer topic contract for the three cj_goal verbs as separately-enrolled deterministic-only workflow topics — adds a `topic_contracts_deterministic:` enrollment seam to the contract engine, 4 new deterministic tests (1 CI-push defect smoke + 3 CI-nightly per-verb chain drills), 11 categories rows, and the full Check-31 doc surface per topic.

## PRs

<!-- PR links with status (open/merged/closed). -->

## Files

<!-- Affected file paths. Populated during Track phase, updated during Implement. -->

- `scripts/test-spec.sh` — `topic_contracts_deterministic:` parser + cross-list duplicate guard + det-only `--check-topic-contract` arm + union iteration in `_run_topic_contract`/`_run_topic_docs` + `_emit_seed` dual-write
- `spec/test-spec.md` — topic-axis prose: deterministic-only enrollment flavor (byte-identical to seed)
- `spec/test-spec-custom.md` — 9 new + 2 re-topic'd `categories:` rows, `units:` rows for the 4 new scripts, `topic_contracts_deterministic:` enrollment (LAST), header-comment rewrite, Check 30/31 units-purpose updates, TEST_FAST prose
- `scripts/validate.sh` — Check 30 banner text (two-list model)
- `scripts/test.sh` — 3-arm negative drill; chain-drill registration under `TEST_FAST=1`; guard-comment update
- `tests/cj-goal-defect-smoke.test.sh` — NEW (CI-push defect shape smoke)
- `tests/goal-feature-chain.test.sh` — NEW (CI-nightly feature helper-chain drill)
- `tests/goal-task-chain.test.sh` — NEW (CI-nightly task helper-chain drill)
- `tests/goal-defect-chain.test.sh` — NEW (CI-nightly defect helper-chain drill)
- `docs/goals/goal-feature.md` + `docs/goals/goal-task.md` + `docs/goals/goal-defect.md` — NEW dream docs
- `docs/tests/topics/goal-{feature,task,defect}/` — NEW topic subdirs (index + 3 layer pages each)
- `docs/tests/workflow/<layer>/<name>.md` — 9 NEW front-door docs (+ 2 re-topic'd eval docs verified/edited)
- `spec/doc-spec-custom.md` — declarations for all new docs
- `CLAUDE.md` — deterministic-only enrollment flavor line
- `TODOS.md` — PARTIAL mark + follow-up rows

## Insights

<!-- Non-obvious findings worth remembering. Design decisions,
     trade-offs, patterns discovered. -->

- The operator's deterministic-only directive reshaped the contract ENGINE, not just this enrollment: the F000082 both-modes-at-local rule would chain the three topics to agentic rows already scheduled for removal, so the honest fix is a second enrollment flavor — a topic can be held to all three LAYERS without being chained to a MODE.
- The union-iteration rework is the load-bearing subtlety: `_run_topic_contract` AND `_run_topic_docs` today iterate ONLY `$_TOPIC_CONTRACTS` and report "topic contract inactive" when that one list is empty — without the rework, Check 31 (and a det-only consumer's Check 30) stays GREEN vacuously for the three new topics. The existing summary-line format + inactive-grep contracts must keep matching (`validate.sh` + `scripts/test.sh` parse them).
- The CI-nightly layer is REAL new coverage (the reason Approach B won over the lint-grade fills of A/C): each verb's full deterministic helper chain driven end to end in a throwaway sandbox, so a regression in worktree entry / phase dispatch / scaffolder / land tail / janitor surfaces nightly even when nobody runs that verb for a week.
- Consciously accepted: the verbs' glue logic lives in agent-executed `pipeline.md` prose a deterministic drill can never reach — with deterministic-only enrollment, the agent-driven path has NO required proof (the F000082 green-but-inert blind spot re-opens for these topics by operator choice; the evals stay runnable on demand while they live).
- Agentic-removal robustness of the local-det fills: feature's and task's fills are deterministic tests OF agentic-harness plumbing (`cj-e2e-gate.test.sh`, `e2e-local.test.sh`) — zero model spend today, but IF the later removal also deletes those harnesses, the documented fallback is re-declaring the verb's chain drill at `local-hook` (two rows sharing one command — the `test-deploy`/`portability-deploy` precedent). Defect's `post-land-sync.test.sh` has no agentic coupling.
- The later agentic-removal is NOT unblocked by this feature alone: deterministic-only enrollment clears Check 30 ONLY — Check 28 hard-requires a `level: workflow` behavior per orchestrator backed by the eval `units:`, Check 24 forward-anchors those units, and portability's own both-modes enrollment would need migrating. The TODOS removal row must enumerate these.

## Journal

<!-- Structured entries from the work-track journal command. Each entry has a type
     (decision, finding, blocker) and a Summary field. -->

- [decision] 2026-07-06 — Settled backlog Open-Question-1 as PER-VERB topics (`goal-feature` / `goal-task` / `goal-defect`), retiring the bundled `cj-goal-eval` label by re-topicing its two rows. Summary: the operator named the scope precisely — three separate workflow testings — before the session asked; `cj-goal-gate-shape` keeps its own shared `cj-goal-gate` topic, untouched.
- [decision] 2026-07-06 — Premise 2 REVISED mid-session by the operator's deterministic-only directive: enrollment must not depend on any agentic row (the operator plans to remove the agentic tests later). Summary: this adds the `topic_contracts_deterministic:` seam to the contract engine itself rather than baking in a dependency already scheduled for deletion; existing eval rows are re-topic'd but required by nothing; no NEW agentic row anywhere (defect's on-disk eval case stays undeclared).
- [decision] 2026-07-06 — Chose Approach B (per-verb deterministic chain drills, Effort L / Risk Med) over A (reuse + attribute — nightly adds NO new coverage) and C (wired-vs-passes symmetry — lint-grade fills guarding assets scheduled for removal would age badly). Summary: the operator explicitly preferred real new chain coverage; B keeps A's local-det fills with named per-verb ownership justifications.
- [decision] 2026-07-06 — CI-push stays fast (operator directive): the 3 chain drills are NIGHTLY — registered in `scripts/test.sh` under the `TEST_FAST=1` guard (the `test-deploy` pattern) so the per-PR gate never runs them; `nightly.yml` runs the full `test.sh` that picks them up. No workflow-file changes.
- [decision] 2026-07-06 — Landing order: engine seam + tests + docs FIRST, enrollment LAST — enrolling before the coverage points exist would red Check 30/31 on the landing commit itself.
- [finding] 2026-07-06 — `scripts/cj-id-claim.sh` usage-errors without `--floor`; the defect chain drill must call it as `--prefix D --floor <N> --dry-run`. `POST_LAND_SYNC_MANIFEST=<path>` (`scripts/post-land-sync.sh:40,48`) is the documented override that makes the land-tail preview hermetic (resolved open question).
