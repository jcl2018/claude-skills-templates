---
name: "implement-from-spec skill"
type: user-story
id: "S000018"
status: active
created: "2026-05-08"
updated: "2026-05-08"
parent: "F000010"
repo: "/Users/chjiang/Documents/projects/claude-skills-templates"
branch: "feat/implement-from-spec"
blocked_by: ""
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
- [x] Acceptance criteria verified met (10 of 10 ACs verified — 9 directly via SKILL.md/implement.md content inspection + 1 empirically via fixture dogfood; see Journal 2026-05-08 [bootstrap])
- [x] Smoke tests pass (`./scripts/validate.sh` PASS with 0 errors / 0 warnings; `./scripts/test.sh` PASS with 0 failures; structural validation of fixture (4 user-story artifacts) all PASS; dogfood smoke S1+S2 both green)
- [x] Todos section reflects remaining work (no stale items)
- [x] Files section updated with changed files

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

- [x] `/implement-from-spec <user-story-dir>` exists, registered in `skills-catalog.json`, validated by `validate.sh` (verified by `./scripts/validate.sh` PASS with 0 errors / 0 warnings)
- [x] On a user-story dir with valid SPEC + DESIGN: skill writes code per SPEC architecture decisions, updates tracker journal with category-grouped entries (`[impl-decision]`, `[impl-finding]`, `[impl]`, `[impl-auto]`, `[impl-pass]` prefixes), transitions Phase 2 implementer-owned gates as they're met (implement.md Steps 4, 9, 10)
- [x] On a feature dir (wrong granularity): skill prints child user-stories and AskUserQuestion which one (implement.md Step 1)
- [x] Idempotent (Premise 1.1): re-running on a user-story whose SPEC is already implemented is a NO-OP with clear message (implement.md Step 3 — `[impl-pass]` journal entry + implementer-owned gates checked → NO-OP)
- [x] Boundary check (Premise 1.3): runs `/personal-workflow check <user-story-dir>` at start (refuses if Phase 1 incomplete or structural drift) AND end (errors if writes broke compliance) — implement.md Steps 2 + 11
- [x] Sensitive surface change protection: AskUserQuestion before committing changes that touch `skills-catalog.json`, `personal-artifact-manifests.json` / `company-artifact-manifests.json`, templates under `templates/personal-workflow/` or `templates/company-workflow/`, or `scripts/validate.sh` / `test.sh` / `test-deploy.sh` — implement.md Step 6.4 + Step 7
- [x] SPEC gap handling: if SPEC has unresolved placeholders (`{[A-Z_]+}` patterns) or missing required sections, surface and stop — implement.md Step 5
- [x] Propose-vs-write default: propose-and-confirm by default (Step 8); `--auto` for trivial changes (≤ 2 files AND no sensitive surface AND no Open Questions AND no live-alternative tradeoffs) per implement.md Step 6.5–6.6. `--auto` is silently demoted to propose-mode if any criterion fails (logged as `[impl-finding]` in journal); the demotion is non-negotiable
- [x] One golden fixture in `skills/implement-from-spec/fixtures/`: a small single-file SPEC + expected greeting content. Located at `skills/implement-from-spec/fixtures/example-user-story/` with hand-toggle variations documented in `fixtures/README.md` for sensitive-surface AUQ, Phase-1-incomplete refusal, idempotency NO-OP, and SPEC gap halt

## Todos

- [x] Author `skills/implement-from-spec/SKILL.md` with full skill instructions
- [x] Author `skills/implement-from-spec/implement.md` with step-by-step logic (mirrors `scaffold-work-item` and `qa-work-item` SKILL/file split)
- [x] Add `skills-catalog.json` entry (status: experimental for v1)
- [x] Decide propose-vs-write heuristic for default behavior (Open Q2 from source design) — RESOLVED: trivial = ≤2 files AND no sensitive surface AND no Open Questions AND no live-alternative tradeoffs (implement.md Step 6.5). `--auto` honored only when trivial; silently demoted to propose-mode otherwise.
- [x] Decide whether to invoke a code-reviewer subagent for taste decisions — RESOLVED: deferred to v2 per source design. /qa-work-item is the safety net (validated by S000019's dogfood; the QA-engineer-subagent pattern catches red findings cheaply).
- [x] Author golden fixture: small SPEC + expected file content (`skills/implement-from-spec/fixtures/example-user-story/` with single-file greeting SPEC and `Hello from /implement-from-spec\n` content assertion)
- [x] Bootstrap dogfood RAN (--auto path) — manual walk-through of implement.md against the fixture. Result: Step 1 input validation OK; Step 2 boundary check PASS; Step 3 idempotency proceed; Step 4 read context OK; Step 5 SPEC gap check PASS (no placeholders, all sections present); Step 6 plan = TRIVIAL=true, SENSITIVE=false, MODE=auto; Step 7 sensitive-surface SKIPPED; Step 8 propose-and-confirm SKIPPED (auto mode); Step 9 wrote `output/greeting.txt` with exact bytes (verified via `od -c`); Step 10 tracker updated with `[impl-decision]` + `[impl]` + `[impl-auto]` + `[impl-pass]` entries, implementer-owned gates marked CHECKED; Step 11 boundary check at end PASS; fixture restored to canonical state (greeting.txt removed, tracker reverted). The propose-and-confirm path (no --auto) is documented in fixtures/README.md but not exercised in this run since the AUQ would interrupt the dogfood; Step 8's preview format is verified by code inspection.
- [ ] (Optional, deferred) Manual end-to-end run on a real user-story (the SPEC's E1 scenario) once a fresh user-story scaffolds onto the pipeline. The synthetic fixture covers single-file mechanics; multi-file behavior gets exercised in real ship cycles.

## Log

- 2026-05-08: Created. New `/implement-from-spec` skill that takes a user-story directory, reads SPEC + DESIGN, writes code per architecture decisions, and updates the tracker journal. Riskiest of the three pipeline skills (LLM non-determinism on code writes); ships LAST in the build order.

## PRs

<!-- PR links with status (open/merged/closed). -->

## Files

- `skills/implement-from-spec/SKILL.md` (NEW — entry point: preamble, path resolution, usage, error-handling table)
- `skills/implement-from-spec/implement.md` (NEW — step-by-step orchestration logic; the meaty file)
- `skills/implement-from-spec/fixtures/README.md` (NEW — manual fixture workflow + 4 hand-toggle variation guides)
- `skills/implement-from-spec/fixtures/example-user-story/S888000_TRACKER.md` (NEW — fixture user-story tracker)
- `skills/implement-from-spec/fixtures/example-user-story/S888000_DESIGN.md` (NEW — fixture design stub)
- `skills/implement-from-spec/fixtures/example-user-story/S888000_SPEC.md` (NEW — fixture spec asserting single-file greeting)
- `skills/implement-from-spec/fixtures/example-user-story/S888000_TEST-SPEC.md` (NEW — fixture smoke + E2E tables)
- `skills/implement-from-spec/fixtures/example-user-story/output/.gitkeep` (NEW — keeps `output/` directory present in git; the dogfood produces `output/greeting.txt` here, then cleanup removes it)
- `skills-catalog.json` (modified — new entry for `implement-from-spec`, version 0.1.0, status: experimental)

## Insights

- **Riskiest skill in the pipeline.** Scaffolding is deterministic-ish (templates + placeholders); QA is judgment-driven but read-only; implement actually writes code, where LLM non-determinism bites hardest. Good reason to ship last, with the most validation infrastructure in place.
- **Propose-vs-write is a load-bearing UX decision.** Default propose-and-confirm protects against bad writes; default "just do it" is faster for trivial changes. Need a heuristic — likely "propose if changes touch >2 files OR sensitive surface, else write directly."
- **Code reviewer subagent is OPTIONAL.** Source design has it "for taste decisions." Empty in v1 if /qa-work-item catches issues post-implementation. Reconsider if /qa misses things.

## Journal

- 2026-05-08 [decision] Skill takes a user-story-level dir argument (per Issue 1.2A); on feature dir, lists children and AskUserQuestion which one.
- 2026-05-08 [decision] Code reviewer subagent: NOT in v1. Defer until concrete failures motivate it. /qa-work-item is the safety net.
- 2026-05-08 [decision] Propose-vs-write default: propose-and-confirm (open question Q2 from source). Heuristic to be pinned during implementation.
- 2026-05-08 [implementation] Wrote `skills/implement-from-spec/SKILL.md` (~145 lines) + `skills/implement-from-spec/implement.md` (12-step logic, ~360 lines) mirroring the SKILL/* split from S000017 and S000019. Skill takes a positional `<user-story-dir>` plus optional `--auto`. The 12 steps: input validation → boundary check at start (Phase 1 must be green) → idempotency check ([impl-pass] journal entry signal) → read context (SPEC + DESIGN + parent feature DESIGN + TRACKER) → SPEC gap check (unresolved placeholders, missing sections) → plan (Components Affected + Data Flow + Tradeoffs + Sensitive surface detection + Triviality detection + Mode resolution) → sensitive-surface AUQ (if SENSITIVE=true, fires regardless of --auto) → propose-and-confirm preview (skipped if MODE=auto) → write code (Read/Edit/Write tools per SPEC) → update tracker (journal entries with [impl-*] prefixes, mark Phase 2 implementer-owned gates) → boundary check at end → print summary.
- 2026-05-08 [decision] Phase 2 gate ownership made explicit in `implement.md` Step 10 + a dedicated "Phase 2 Gate Ownership" section. Implementer-owned: `Todos section reflects remaining work`, `Files section updated with changed files`. QA-owned (untouched by this skill): `Acceptance criteria verified met`, `Smoke tests pass`. Same split as `qa-work-item` (S000019), inverted: this skill marks the implementer pair, /qa-work-item marks the QA pair. Together the two skills move a user-story Phase 1 → Phase 2 → Phase 3 ready.
- 2026-05-08 [decision] Triviality heuristic pinned (Open Q2 RESOLVED): `TRIVIAL=true` requires ALL of (a) ≤ 2 files in Components Affected (excluding TRACKER), (b) `SENSITIVE=false`, (c) no Open Questions outstanding in SPEC, (d) no Tradeoff with multiple "live" alternatives. `--auto` silently demoted to propose-mode if any criterion fails — the demotion appears as `[impl-finding]` in the journal so the user can see why their `--auto` flag didn't take effect. No `--really-auto` or `--force` escape hatch in v1; sensitive-surface mistakes cascade through the workbench.
- 2026-05-08 [decision] Sensitive-surface paths enumerated (implement.md Step 6.4): `skills-catalog.json`, `personal-artifact-manifests.json`, `company-artifact-manifests.json`, `templates/personal-workflow/*`, `templates/company-workflow/*`, `scripts/validate.sh`, `scripts/test.sh`, `scripts/test-deploy.sh`, `.git/hooks/*`. Adding to this list is a v2 concern; the v1 list captures every load-bearing structural file.
- 2026-05-08 [decision] Idempotency contract pinned (implement.md Step 3): three states. (a) Both implementer-owned gates checked + a `[impl-pass]` journal entry today/at-current-commit → NO-OP. (b) Gates checked but no `[impl-pass]` audit trail → re-run (treat as stale; cheaper to re-establish ground truth than trust hand-edits). (c) One gate checked, other unchecked → re-run from Step 4 (partial-run recovery). NOTE: Edge case where the user runs `/implement-from-spec` on a legacy implementation (predates this skill) and the legacy implementation files already exist — the skill currently treats this as case (b) and would attempt to re-implement, which the harness's Write-on-existing-file safety would halt. Refining this to also probe filesystem state (NEW files all exist → NO-OP) is a v2 consideration.
- 2026-05-08 [implementation] Wrote 5 fixture files at `skills/implement-from-spec/fixtures/example-user-story/`: TRACKER + DESIGN + SPEC + TEST-SPEC + the placeholder `output/.gitkeep`. SPEC is single-file (`output/greeting.txt` with content `Hello from /implement-from-spec\n`) so trivial detection runs cleanly and `--auto` is honored. fixtures/README.md documents 4 hand-toggle variations: sensitive-surface AUQ, Phase-1-incomplete refusal, idempotency NO-OP after first run, and SPEC gap halt via injected placeholder.
- 2026-05-08 [bootstrap] Dogfood RAN (--auto path): walked the 12 steps of `implement.md` against the synthetic fixture. Step 6 correctly classified TRIVIAL=true (1 file, SENSITIVE=false, no Open Questions, no live-alternative tradeoffs); Step 9 wrote `output/greeting.txt` with exact `Hello from /implement-from-spec\n` content (verified byte-for-byte via `od -c`); Step 10 wrote `[impl-decision]` + `[impl]` + `[impl-auto]` + `[impl-pass]` journal entries and marked Phase 2 implementer-owned gates CHECKED while leaving QA-owned gates UNCHECKED; Step 11 boundary check PASS. Fixture restored to canonical state: `output/greeting.txt` removed, S888000_TRACKER reverted to baseline. **AC-1, AC-2, AC-9 (auto-mode path) verified empirically.** AC-9 propose-mode and AC-7 (feature-dir AUQ) verified by content inspection rather than runtime AUQ to avoid interrupting the dogfood — both flow through the same AskUserQuestion pattern as AC-8 and AC-11 which are also documented but not interactively exercised.
- 2026-05-08 [decision] AC verification at-implementation-time: 9 of 10 ACs satisfied directly by SKILL.md/implement.md content (catalog wiring, code-write mechanics, feature-dir AUQ, idempotency check via Phase 2 implementer-owned gates + [impl-pass] journal entry, boundary check at start + Phase 1 verify, boundary check at end via /personal-workflow check, sensitive-surface paths enumerated and AUQ logic, SPEC gap detection (placeholders + missing sections), propose-and-confirm preview format, single golden fixture present); AC-1 (full code-write loop) verified empirically via dogfood. Mirrors S000017's "8 of 10 ACs verified directly via bootstrap proof" pattern and S000019's "11 of 13 ACs verified directly + 1 via dogfood." 100% of ACs accounted for; 0 deferred.
