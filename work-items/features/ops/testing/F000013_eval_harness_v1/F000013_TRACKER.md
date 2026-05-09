---
name: "Behavioral eval harness V1"
type: feature
id: "F000013"
status: active
created: "2026-05-09"
updated: "2026-05-09"
repo: "/Users/chjiang/Documents/projects/claude-skills-templates"
branch: "main"
blocked_by: ""
---

<!-- Prerequisite: Before scaffolding this work item, run /office-hours to
     produce a design plan in ~/.gstack/projects/. Distill that plan into
     DESIGN.md during Phase 1 below. -->

## Lifecycle

### Phase 1: Track

1. Create working branch: `git checkout -b feat/eval_harness_v1`
2. Scaffold work item directory and TRACKER.md
3. Distill `DESIGN.md` from the /office-hours output (problem shape, big decisions, risks) — from `templates/doc-DESIGN.md`
4. Scaffold `ROADMAP.md` (scope, non-goals, decomposition, delivery timeline) — from `templates/doc-ROADMAP.md`
5. Define acceptance criteria (what "done" looks like for the whole feature)
6. Decompose into child user-stories
   → detail (DESIGN, SPEC, TEST-SPEC) lives in child stories

**Gates:**
- [x] /office-hours design produced (in `~/.gstack/projects/`)
- [ ] Working branch created (`branch` field populated)
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

1. Run `/personal-workflow check` — verify all children pass validation
2. Verify smoke tests pass in CI (automated regression)
3. Walk E2E manually — run user-scenario verification before ship
4. Run `/ship` — creates feature PR (includes pre-landing code review)
5. Run `/land-and-deploy` — merges and verifies deployment
6. Run `/document-release` — post-ship doc audit; fix drifts inline or spawn D-tickets

**Gates:**
- [ ] `/personal-workflow check` — all children pass validation
- [x] Smoke tests pass in CI
- [ ] E2E walked manually
- [x] `/ship` — PR created (with pre-landing review)
- [x] `/land-and-deploy` — merged and deployed
- [ ] `/document-release` — post-ship doc audit done; drifts fixed inline or spawned as D-tickets

## Acceptance Criteria

<!-- What "done" looks like for this feature. Each criterion should be
     testable and specific. -->

- [ ] `bash scripts/eval.sh` runs end-to-end on a clean checkout against `personal-workflow` + `system-health`, reporting PASS/FAIL per case
- [ ] The S000022 Step 18 traceability regression case fails when the parser fix is reverted on a test branch (proves the harness catches real regressions)
- [ ] `.github/workflows/eval-nightly.yml` runs nightly on `main` and surfaces failures via the existing notification surface
- [ ] V1 case count is 6–10 cases across the 2 in-scope skills
- [ ] Observed cost per nightly run is under $1.50 USD (success criterion from design)
- [ ] Observed wall-clock per nightly run is under 12 minutes
- [ ] TODOS.md "Behavioral eval harness (P1, M)" entry is marked DONE-V1 with pointer to this work item and V2 trajectory note

## Todos

<!-- Actionable items for this feature. Break into child tasks for
     large features. -->

- [ ] S000023 — Spike 0 (CLI flag verification) + skeleton (eval.sh, run-case.sh, lib, README, first passing case)
- [ ] S000024 — V1 case coverage (personal-workflow regression + reasoning + baseline cases; system-health cases)
- [ ] S000025 — Nightly CI workflow + first real CI run + cost/time validation + TODOS.md update

## Log

<!-- Chronological entries with dates and commit SHAs. -->

- 2026-05-09: Created. Behavioral eval harness V1 — bash + jq runner spawning headless `claude` CLI against scratch worktrees, structured JSON output validated via JSON schema. Source: ~/.gstack/projects/jcl2018-claude-skills-templates/chjiang-main-design-20260509-110013.md.

## PRs

<!-- PR links with status (open/merged/closed). -->

- [PR #72: v1.12.0 feat: F000013 V1 eval harness — S000023 runner + first case](https://github.com/jcl2018/claude-skills-templates/pull/72) — MERGED

## Files

<!-- Affected file paths. Populated during Track phase, updated during Implement. -->

- `scripts/eval.sh` (new)
- `tests/eval/lib/run-case.sh` (new)
- `tests/eval/lib/seed-fixture.sh` (new)
- `tests/eval/README.md` (new)
- `tests/eval/schemas/common-frags.json` (new)
- `tests/eval/personal-workflow/**` (new — per-case dirs)
- `tests/eval/system-health/**` (new — per-case dirs)
- `.github/workflows/eval-nightly.yml` (new)
- `TODOS.md` (modified)

## Insights

<!-- Non-obvious findings worth remembering. Design decisions,
     trade-offs, patterns discovered. -->

- The 2026 `claude` CLI exposes `--print`, `--output-format json`, `--json-schema`, `--plugin-dir`, `--max-budget-usd`, `--bare`, `--no-session-persistence` — a stack purpose-built for evals. The "uncharted in Claude Code" framing from the 2026-04-10 doc is no longer accurate.
- Testing skills via real CLI invocation (not script-level extraction or raw API call) is high-fidelity but premature without first-class CLI flags. Now that those flags exist, V1 picks the high-fidelity path without paying the custom-runner tax.
- LLM variance is sidestepped by structured-JSON output validated against schema, not prose golden-diff. Eval prompts mandate `/skill-name` invocation + JSON-only output trailing instruction; schema asserts shape.
- Path resolution in scratch worktrees is the load-bearing concern. The skill resolves `_REPO_ROOT` via `git rev-parse`; in a tmpdir without `git init`, resolution falls through to `~/.claude/skills/` — directly contradicting the "test in-repo source" premise. Fix: `git init` the tmpdir AND fake `$HOME` so the eval cannot accidentally test the deployed skill.

## Journal

<!-- Structured entries from the work-track journal command. Each entry has a type
     (decision, finding, blocker) and a Summary field. -->

- 2026-05-09 [decision] **Eval target = real CLI invocation, not script extraction** — Summary: D4 of /office-hours session locked the eval to spawn `claude` against fixtures via `--print --output-format json --json-schema`, rejecting the script-level alternative. Reasoning: testing the artifact the user actually invokes (vs. the deterministic core that backs it) catches SKILL.md prose drift that script tests miss. Tradeoff: API cost + wall-clock; mitigated by `--max-budget-usd` cap and nightly cadence.
- 2026-05-09 [decision] **V1 runner = bash + jq, V2 considered** — Summary: D8 chose bash over Bun/TypeScript runner. Reasoning: matches existing `scripts/` conventions; ships faster; eval cases are runner-agnostic so migration to Bun later only swaps `eval.sh` and `run-case.sh`. Tradeoff: bash debugging UX is rough.
- 2026-05-09 [decision] **V1 scope = personal-workflow + system-health only** — Summary: P2 of premise check restricted V1 to skills whose primary user-facing output is a structured report. Filesystem-mutating skills (`scaffold-work-item`, `implement-from-spec`, `qa-work-item`) defer to V2 with structural-assertion helpers. `deprecated/company-workflow` is permanently out of scope.
- 2026-05-09 [decision] **Cadence = nightly on main, not per-PR** — Summary: P3 of premise check picked nightly cron over per-PR. Reasoning: per-PR adds 30–90s + token cost to every CI run, dominated by lint-only/docs-only PRs. `paths: ['skills/**', 'templates/**']` filter can be added later if signal/cost ratio justifies.
- 2026-05-09 [gates-update] Phase 3: /ship — PR #72,/land-and-deploy — PR merged,Smoke tests pass — all checks green on PR #72,PRs section: linked PR #72 (MERGED).
