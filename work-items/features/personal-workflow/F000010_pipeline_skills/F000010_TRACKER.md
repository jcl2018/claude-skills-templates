---
name: "Personal-workflow pipeline skills"
type: feature
id: "F000010"
status: active
created: "2026-05-08"
updated: "2026-05-08"
repo: "/Users/chjiang/Documents/projects/claude-skills-templates"
branch: "feat/pipeline-skills"
blocked_by: ""
---

<!-- Source design: ~/.gstack/projects/jcl2018-claude-skills-templates/chjiang-main-design-20260508-102829.md
     (refined by /plan-eng-review 2026-05-08; 4 issues addressed, 0 critical gaps) -->

## Lifecycle

### Phase 1: Track

1. Create working branch: `git checkout -b feat/pipeline-skills`
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
- [ ] Smoke tests pass in CI
- [ ] E2E walked manually
- [ ] `/ship` — PR created (with pre-landing review)
- [ ] `/land-and-deploy` — merged and deployed
- [ ] `/document-release` — post-ship doc audit done; drifts fixed inline or spawned as D-tickets

## Acceptance Criteria

- [ ] `/scaffold-work-item` exists, takes a design-doc-path, produces a work-item directory tree that passes `/personal-workflow check` on first run
- [ ] `/implement-from-spec` exists, takes a user-story dir, writes code per SPEC architecture decisions, updates tracker journal and lifecycle gates
- [ ] `/qa-work-item` exists, takes a user-story dir, runs smoke (script-driven) + E2E (QA engineer subagent), writes results to tracker
- [ ] Each skill is idempotent: re-running on already-completed input is a NO-OP (Premise 1.1)
- [ ] Each skill calls `/personal-workflow check <work-item-dir>` at start AND end (Premise 1.3)
- [ ] Each skill ships with one golden fixture in `skills/{name}/fixtures/` (manual snapshot diff per 3.1A)
- [ ] Manual end-to-end pipeline run on a real new work item completes (scaffold → implement → qa green)
- [ ] `/personal-pipeline` orchestrator follow-up captured in TODOS.md (P3, M)

## Todos

- [x] Create feat/pipeline-skills branch (Phase 1 gate)
- [ ] S000017 scaffold-work-item — scaffold + ship
- [ ] S000018 implement-from-spec — scaffold + ship
- [ ] S000019 qa-work-item — scaffold + ship
- [ ] Bootstrap: re-scaffold this F000010 work item using /scaffold-work-item once it ships, verify output matches hand-scaffolded baseline
- [ ] After 2-week soak: revisit `/personal-pipeline` orchestrator decision (TODOS.md P3 entry)

## Log

- 2026-05-08: Created. Three new LLM-driven skills automating the personal-workflow gap between /office-hours and /ship: scaffold (design-doc → work-item tree), implement (SPEC → code), qa (TEST-SPEC → smoke + E2E via QA engineer subagent). Hand-scaffolded as bootstrap; will be re-scaffolded by /scaffold-work-item once it ships.

## PRs

<!-- PR links with status (open/merged/closed). -->

## Files

- `skills/scaffold-work-item/SKILL.md` (NEW, S000017)
- `skills/implement-from-spec/SKILL.md` (NEW, S000018)
- `skills/qa-work-item/SKILL.md` (NEW, S000019)
- `skills-catalog.json` (3 new entries)
- `skills/scaffold-work-item/fixtures/` (NEW, S000017 — golden fixture)
- `skills/implement-from-spec/fixtures/` (NEW, S000018 — golden fixture)
- `skills/qa-work-item/fixtures/` (NEW, S000019 — golden fixture)
- `TODOS.md` (orchestrator follow-up entry, already added during /plan-eng-review)

## Insights

- **Three skills, not one orchestrator.** Office-hours session debated 4 approaches; chose A (three independent skills) over B (orchestrator). Validates the handoff-doc thesis cheap; orchestrator becomes a follow-up decision after the per-skill pattern proves itself in real use.
- **QA engineer subagent pattern.** User invented this during office-hours: a subagent prompted "you are a QA engineer, read TEST-SPEC, verify acceptance criteria" generalizes E2E testing beyond pre-scripted harnesses. Logged as a project learning (`qa-engineer-subagent`, confidence 8/10).
- **Idempotency over rollback.** Failure-state contract (Premise 1.1) chose idempotency over `.in-progress` markers. Each skill checks "already done" on entry; abort writes are durable; re-run is safe and resumes from first incomplete step.
- **Boundary validation via /personal-workflow check.** Premise 1.3 has every skill invoke check at start AND end. Drift detection at runtime; load-bearing for v1's manual-tests-only choice.
- **Bootstrap chicken-and-egg.** /scaffold-work-item can't scaffold its own work item. F000010 is hand-scaffolded; once /scaffold-work-item ships, re-scaffold F000010 via the new skill and diff against the baseline as the first golden fixture.

## Journal

- 2026-05-08 [decision] Source design approved via /office-hours; refined by /plan-eng-review. 4 architecture/test issues resolved: 1.1A (idempotency premise), 1.2A (work-item granularity — scaffold full tree, implement/QA at user-story level), 1.3A (boundary validation premise), 3.1A (one golden fixture per skill).
- 2026-05-08 [decision] Step 0A — manual tests only in v1. Behavioral eval harness (TODOS.md P1) deferred. Automated regression detection lands in a future PR after the eval harness ships.
- 2026-05-08 [decision] Build order: S000017 (scaffold) → S000019 (qa) → S000018 (implement). Scaffold is the gating skill (others depend on its output); QA validates the QA-engineer-subagent pattern early; implement is the riskiest and benefits from the validated handoff pattern.
