---
name: "Personal-pipeline orchestrator"
type: feature
id: "F000014"
status: active
created: "2026-05-09"
updated: "2026-05-09"
repo: "/Users/chjiang/Documents/projects/claude-skills-templates"
branch: "feat/personal-pipeline"
blocked_by: ""
---

<!-- Source design: ~/.gstack/projects/jcl2018-claude-skills-templates/chjiang-main-design-20260509-135305.md
     (3-iteration spec review; quality 9/10; closes the deferred /personal-pipeline TODO from F000010's 2026-05-08 office-hours session) -->

## Lifecycle

### Phase 1: Track

1. Create working branch: `git checkout -b feat/personal-pipeline`
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

- [ ] `skills/personal-pipeline/SKILL.md` exists with valid frontmatter, cataloged in `skills-catalog.json`, validated by `validate.sh`, deployed by `skills-deploy install`
- [ ] A new work item can be created end-to-end via `/personal-pipeline <design-doc>` with no inline scaffolding instructions to Claude
- [ ] Each Agent subagent prompt is under 500 tokens; each subagent return is under 200 tokens (verified by inspection on the first real run)
- [ ] Pre-scaffold gate catches the Step 5 idempotency hole on the F000010 design doc (regression case)
- [ ] Post-implement gate catches a deliberately broken `validate.sh` invocation
- [ ] Post-QA gate halts with AskUserQuestion when smoke is red
- [ ] After 5 runs, `~/.gstack/analytics/personal-pipeline.jsonl` reports usage and the user makes the sunset decision via AskUserQuestion
- [ ] Orchestrator skill markdown total under 800 lines
- [ ] Subagent feasibility spike (S000026) completed and findings documented BEFORE pipeline.md is written

## Todos

- [x] Create `feat/personal-pipeline` branch (Phase 1 gate)
- [ ] **Step 0:** Pre-authoring 60-second check — confirm exact `Agent` vs `Task` allowed-tools identifier in `~/.claude/settings.json` schema
- [ ] S000026 subagent feasibility spike — AUQ bubble + RESULT-line reliability (both legs blocking)
- [ ] S000027 personal-pipeline skill — SKILL.md + pipeline.md + fixtures
- [ ] First real run: pipe a fresh small TODO from TODOS.md (e.g., Fork-aware update detection P3) through the orchestrator; compare to manual three-step
- [ ] After 5 real runs: review telemetry, AUQ sunset decision

## Log

- 2026-05-09: Created. Single `/personal-pipeline` skill orchestrating the 3 pipeline skills (scaffold/implement/qa) via Agent-tool subagent dispatch with fresh-context file-only handoff and independent inter-step quality gates. Closes the deferred orchestrator TODO from F000010's 2026-05-08 office-hours session.

## PRs

<!-- PR links with status (open/merged/closed). -->

- [PR #73: v1.13.0 feat: F000014 /personal-pipeline orchestrator + T000015 fork-aware update detection](https://github.com/jcl2018/claude-skills-templates/pull/73) — MERGED

## Files

- `skills/personal-pipeline/SKILL.md` (NEW, S000027)
- `skills/personal-pipeline/pipeline.md` (NEW, S000027)
- `skills/personal-pipeline/fixtures/` (NEW, S000027)
- `skills-catalog.json` (1 new entry)
- `tests/spike/subagent-capabilities/` (NEW, S000026 — feasibility harness + findings report)
- `~/.gstack/analytics/personal-pipeline.jsonl` (runtime telemetry surface; not committed)
- `TODOS.md` (close the orchestrator entry once shipped)

## Insights

- **Orchestrator-as-broker distinction.** Premise 2 was reworded mid-session from "no in-memory state crossing phases" to "no in-memory state crossing between subagents." The orchestrator IS the broker — it must hold file paths between phases as Bash args. Stating this carve-out explicitly avoided a self-contradictory premise (per spec-review iteration 1, Specific Challenge 1).
- **Spike-before-build.** Two unverified premises gate pipeline.md: (a) AskUserQuestion calls inside Agent subagents bubble to the human, and (b) subagents reliably emit a parseable `RESULT: <key>=<value>` final line. Both must be verified in S000026 before any orchestrator code is written. Either outcome is workable; the design just changes shape.
- **Decoupled from TODOS.md:26.** The orchestrator's pre-scaffold idempotency check uses the `**Status: SCAFFOLDED → <path>**` footer that scaffold's Step 12 ALREADY writes, so no upstream scaffold-skill change is required as a prereq. TODOS.md:26 (Step 5 hole) stays open as defense-in-depth for direct (non-orchestrator) scaffold invocations.
- **Sunset criterion mechanically defined.** Trip-wire for delete recommendation: ≥3 of 5 invocations end in `halted_at_gate` (parseable from `~/.gstack/analytics/personal-pipeline.jsonl`). No qualitative leg — user keeps or deletes at the AUQ based on what they see, recommendation is not gated on a self-report memory test (per spec-review iteration 2).
- **PHILOSOPHY override is structural.** PHILOSOPHY.md:11/:61 warns against orchestration skills (5 of 7 deleted historically). The override holds because the orchestrator's value-add is `Agent` tool dispatch with `subagent_type` per phase — fresh-context file-only handoff plumbing, not prose composition. If implemented as inline prose, it IS the /workflow anti-pattern.

## Journal

- 2026-05-09 [decision] Approach A (full Agent-tool orchestrator) chosen over B (inline prose; violates PHILOSOPHY) and C (shell harness via `claude -p`; trades P4 interactive gates for marginal isolation gain over Agent subagents).
- 2026-05-09 [decision] User-added constraints (mid-session): file-only boundary between subagents AND independent inter-step quality gates. Reshaped the design from "wrap the 3 skills" to "wrap them with file-only isolation and independent gates" — structurally different and PHILOSOPHY-defensible.
- 2026-05-09 [decision] Premise 2 reworded after spec-review iteration 1: "no in-memory state crossing between subagents; orchestrator-as-broker." Closes Specific Challenge 1 from the reviewer.
- 2026-05-09 [decision] Sunset criterion finalized after spec-review iteration 2: trip-wire = ≥3 of 5 `halted_at_gate`, no qualitative leg. Telemetry write in pipeline.md Step 9; AUQ on 6th invocation.
- 2026-05-09 [decision] Step 2 of orchestration (pre-scaffold idempotency check) gets a fourth branch (footer-absent-but-tracker-references-design-doc) to handle the Step 9/Step 12 ordering hole in scaffold-work-item. Cheap grep, halt-on-detect, no auto-recover.
- 2026-05-09 [finding] Spec review across 3 iterations caught 13 issues; quality went 6/10 → 7/10 → 9/10. Iteration 2 surfaced new issues introduced by iteration 1 fixes — typical convergence pattern, not a sign the doc was wrong.
- 2026-05-09 [decision] Source design approved via /office-hours; will pass through /plan-eng-review before pipeline.md is written (catches architecture gaps the spec-review subagent doesn't, e.g., concurrent-invocation races on `work-items/` ID generation).
- 2026-05-09 [decision] **F000014_DESIGN big-decisions table extended with rows 2.1 + 2.2 after S000026 spike findings.** Spike found AUQ is unreachable inside Agent subagents (not just hang/auto-cancel) → Phase 2 dispatch model SUPERSEDED: orchestrator pre-collects AUQs at parent layer, subagents run without AUQ. Spike also found RESULT-line formatting non-deterministic (2/5 strict hits, content always present) → parser leniency required (strip `>` blockquote prefixes + code fences). Both adjustments cascade into S000027_SPEC.md and the eventual pipeline.md.
- 2026-05-09 [gates-update] Phase 3: /ship — PR #73,/land-and-deploy — PR merged,Smoke tests pass — all checks green on PR #73,PRs section: linked PR #73 (MERGED).
