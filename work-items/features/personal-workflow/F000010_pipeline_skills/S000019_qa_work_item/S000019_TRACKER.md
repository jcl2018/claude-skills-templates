---
name: "qa-work-item skill"
type: user-story
id: "S000019"
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
     Build order: ships SECOND (after S000017 scaffold, before S000018 implement). The
     QA engineer subagent pattern is novel; validate it early before /implement-from-spec
     bets on it. -->

## Lifecycle

### Phase 1: Track

1. Read parent tracker to understand scope
2. Create working branch: `git checkout -b feat/qa-work-item` (or use parent's branch if shipping in same PR)
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

- [ ] `/qa-work-item <user-story-dir>` exists, registered in `skills-catalog.json`, validated by `validate.sh`
- [ ] Reads TEST-SPEC.md from the user-story dir; runs every Smoke Test row's Script/Command
- [ ] Delegates E2E to a "QA engineer" subagent via Agent tool with prompt: "you are a QA engineer, read TEST-SPEC.md at <path>, verify the E2E acceptance criteria, report findings"
- [ ] Subagent returns 1-2 sentences + file pointers (per Premise 1 — short reports keep orchestrator context small)
- [ ] Writes structured findings to tracker as journal entries (decision/finding/blocker categorization) AND a dedicated `## QA Run` section
- [ ] Updates Phase 2 lifecycle gates: `[ ] Acceptance criteria verified met` and `[ ] Smoke tests pass` checked off when both are green
- [ ] AskUserQuestion only on red or ambiguous QA results; green path is silent
- [ ] On feature dir (wrong granularity): list child user-stories and AskUserQuestion which one (Issue 1.2A)
- [ ] Idempotent (Premise 1.1): re-running on a user-story already QA'd green is a NO-OP
- [ ] Boundary check (Premise 1.3): runs `/personal-workflow check <user-story-dir>` at start (refuses if Phase 2 implementation gates not met) AND end (errors if QA write broke compliance)
- [ ] Subagent timeout: hard 5-minute cap; on timeout, writes timeout entry to tracker + AskUserQuestion to re-run
- [ ] Prompt cache friendliness: subagent prompt template structured with stable preamble first, variable work-item data after
- [ ] One golden fixture in `skills/qa-work-item/fixtures/`: a small TEST-SPEC + small implementation + expected QA findings

## Todos

- [ ] Author `skills/qa-work-item/SKILL.md` with full skill instructions
- [ ] Decide where the QA engineer prompt template lives (Open Q1 from source design): SKILL.md hardcoded vs `prompts/qa-engineer.md` separate file vs TEST-SPEC frontmatter override
- [ ] Add `skills-catalog.json` entry (status: experimental for v1)
- [ ] Author golden fixture: small TEST-SPEC + small implementation + expected findings
- [ ] Validate QA engineer subagent pattern on a controlled test (e.g., a TEST-SPEC verifying a known bug)
- [ ] Confirm subagent prompt is cache-friendly (stable preamble first); inspect token cost on second run vs first

## Log

- 2026-05-08: Created. New `/qa-work-item` skill running smoke (script-driven) + E2E (QA engineer subagent). The subagent pattern is the user's invention from /office-hours: a fresh-context subagent prompted as a QA engineer reads TEST-SPEC and verifies acceptance criteria using whatever tools it needs (Bash, Read, Diff). Generalizes E2E beyond pre-scripted harnesses. Ships SECOND in build order to validate the pattern before /implement-from-spec depends on it.

## PRs

<!-- PR links with status (open/merged/closed). -->

## Files

- `skills/qa-work-item/SKILL.md` (NEW)
- `skills/qa-work-item/fixtures/` (NEW — golden TEST-SPEC + impl + findings)
- `skills-catalog.json` (new entry, status: experimental)

## Insights

- **The QA engineer subagent is the most novel pattern in this feature.** Worth shipping second so its real-world behavior shapes /implement-from-spec's design.
- **Prompt cache friendliness matters.** The subagent's stable preamble (role, generic instructions) should come BEFORE variable work-item-specific content so Claude Code's prompt cache amortizes the preamble across runs. ~2x cost reduction over time.
- **Subagent reports must stay short** (Premise 1 conditional). Subagent returns 1-2 sentences + file pointers, not "here's everything I checked." If the parent skill ever asks the subagent to "describe what you did," token savings collapse.

## Journal

- 2026-05-08 [decision] QA engineer subagent prompt: "You are a QA engineer. Read TEST-SPEC.md at <path>. Verify smoke + E2E acceptance criteria. Use whatever tools you need — run scripts, read code, diff outputs. Report findings green/red/ambiguous, 1-2 sentences each. Write detailed findings to <tracker-path>." Stable preamble first; variable data (paths) after.
- 2026-05-08 [decision] Smoke test runs first (script-driven, deterministic); E2E (subagent) runs only if smoke is green. On smoke red: short-circuit, write smoke failures to tracker, abort QA before E2E.
- 2026-05-08 [decision] Subagent timeout hard-capped at 5 minutes. Beyond that, write timeout entry, AskUserQuestion to re-run. No retries inside the skill; user decides.
- 2026-05-08 [decision] Decision gate: AskUserQuestion only on red or ambiguous results. Green is silent.
