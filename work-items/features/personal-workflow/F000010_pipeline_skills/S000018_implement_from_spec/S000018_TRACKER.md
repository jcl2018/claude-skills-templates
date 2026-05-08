---
name: "implement-from-spec skill"
type: user-story
id: "S000018"
status: active
created: "2026-05-08"
updated: "2026-05-08"
parent: "F000010"
repo: "/Users/chjiang/Documents/projects/claude-skills-templates"
branch: "feat/pipeline-skills"
blocked_by: "S000017"
---

<!-- Source design (parent): ../F000010_DESIGN.md
     Office-hours doc: ~/.gstack/projects/jcl2018-claude-skills-templates/chjiang-main-design-20260508-102829.md
     Build order: shipped LAST (after S000017 scaffold + S000019 qa). Riskiest skill (LLM
     non-determinism on code writes); benefits from validated handoff pattern. -->

## Lifecycle

### Phase 1: Track

1. Read parent tracker to understand scope
2. Create working branch: `git checkout -b feat/implement-from-spec` (or use parent's branch if shipping in same PR)
3. Scaffold work item directory and TRACKER.md
4. Distill `DESIGN.md` from the /office-hours output (own session or parent's) — from `templates/doc-DESIGN.md`
5. Scaffold `SPEC.md` (requirements, acceptance criteria, architecture, tradeoffs) — from `templates/doc-SPEC.md`
6. Scaffold `TEST-SPEC.md` (smoke + E2E test scenarios) — from `templates/doc-TEST-SPEC.md`
7. Break into child tasks if scope warrants decomposition (per WORKFLOW.md, tasks are optional for atomic stories)

**Gates:**
- [x] /office-hours design referenced (parent F000010_DESIGN.md links to source)
- [x] Working branch created (`branch` field populated)
- [x] DESIGN + SPEC + TEST-SPEC scaffolded
- [x] Acceptance criteria defined
- [x] Tasks broken down (N/A — atomic story)

### Phase 2: Implement

1. Read DESIGN + SPEC for context
2. Implement according to architecture decisions in SPEC
3. Run smoke tests as you go (TEST-SPEC `## Smoke Tests` table)
4. Run `/personal-workflow check` on modified docs after updates
5. Update tracker: move through lifecycle phases, add journal entries
6. Update Files section with changed file paths

**Gates:**
- [ ] Acceptance criteria verified met
- [ ] Smoke tests pass
- [ ] Todos section reflects remaining work (no stale items)
- [ ] Files section updated with changed files

### Phase 3: Ship

1. Run `/personal-workflow check` — verify all validation passes
2. Verify smoke tests pass in CI
3. Walk E2E manually
4. Ensure all child tasks (if any) have shipped
5. Run `/ship`
6. Run `/land-and-deploy`

**Gates:**
- [ ] `/personal-workflow check` — validation passed
- [ ] Smoke tests pass in CI
- [ ] E2E walked manually
- [ ] All children shipped (if any)
- [ ] `/ship` — PR created (with pre-landing review)
- [ ] `/land-and-deploy` — merged and deployed

## Acceptance Criteria

- [ ] `/implement-from-spec <user-story-dir>` exists, registered in `skills-catalog.json`, validated by `validate.sh`
- [ ] On a user-story dir with valid SPEC + DESIGN: skill writes code per SPEC architecture decisions, updates tracker journal with category-grouped entries (decision/finding/implementation), transitions Phase 1 gates → Phase 2 gates as they're met
- [ ] On a feature dir (wrong granularity): skill prints child user-stories and AskUserQuestion which one (per Issue 1.2A)
- [ ] Idempotent (Premise 1.1): re-running on a user-story whose SPEC is already implemented is a NO-OP with clear message
- [ ] Boundary check (Premise 1.3): runs `/personal-workflow check <user-story-dir>` at start (refuses if SPEC/DESIGN missing or invalid) AND end (errors if writes broke compliance)
- [ ] Sensitive surface change protection: AskUserQuestion before committing changes that touch `skills-catalog.json`, `personal-artifact-manifests.json`, or any `validate.sh`-related infra
- [ ] SPEC gap handling: if SPEC has missing sections or `{placeholder}` values, AskUserQuestion to fill before proceeding
- [ ] Propose-vs-write default: propose-and-confirm by default; user can toggle "just do it" via skill argument (e.g., `--auto`)
- [ ] One golden fixture in `skills/implement-from-spec/fixtures/`: a small SPEC + expected code output snapshot

## Todos

- [ ] Author `skills/implement-from-spec/SKILL.md`
- [ ] Add `skills-catalog.json` entry (status: experimental for v1)
- [ ] Decide propose-vs-write heuristic for default behavior (Open Q2 from source design)
- [ ] Decide whether to invoke a code-reviewer subagent for taste decisions, or rely on /qa for catching
- [ ] Author golden fixture: small SPEC.md + expected file changes
- [ ] Manual end-to-end run: implement S000017 (the scaffold-work-item skill itself) using this skill, after S000017 ships

## Log

- 2026-05-08: Created. New `/implement-from-spec` skill that takes a user-story directory, reads SPEC + DESIGN, writes code per architecture decisions, and updates the tracker journal. Riskiest of the three pipeline skills (LLM non-determinism on code writes); ships LAST in the build order.

## PRs

<!-- PR links with status (open/merged/closed). -->

## Files

- `skills/implement-from-spec/SKILL.md` (NEW)
- `skills/implement-from-spec/fixtures/` (NEW — small SPEC + expected output)
- `skills-catalog.json` (new entry, status: experimental)

## Insights

- **Riskiest skill in the pipeline.** Scaffolding is deterministic-ish (templates + placeholders); QA is judgment-driven but read-only; implement actually writes code, where LLM non-determinism bites hardest. Good reason to ship last, with the most validation infrastructure in place.
- **Propose-vs-write is a load-bearing UX decision.** Default propose-and-confirm protects against bad writes; default "just do it" is faster for trivial changes. Need a heuristic — likely "propose if changes touch >2 files OR sensitive surface, else write directly."
- **Code reviewer subagent is OPTIONAL.** Source design has it "for taste decisions." Empty in v1 if /qa-work-item catches issues post-implementation. Reconsider if /qa misses things.

## Journal

- 2026-05-08 [decision] Skill takes a user-story-level dir argument (per Issue 1.2A); on feature dir, lists children and AskUserQuestion which one.
- 2026-05-08 [decision] Code reviewer subagent: NOT in v1. Defer until concrete failures motivate it. /qa-work-item is the safety net.
- 2026-05-08 [decision] Propose-vs-write default: propose-and-confirm (open question Q2 from source). Heuristic to be pinned during implementation.
