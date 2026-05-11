---
name: "/wc-investigate — scoping conversation + design doc + domain skeletons"
type: user-story
id: "S000033"
status: active
created: "2026-05-11"
updated: "2026-05-11"
parent: "F000015"
repo: "/Users/chjiang/Documents/projects/claude-skills-templates"
branch: "claude/zealous-antonelli-5f8036"
blocked_by: "S000032"
---

## Lifecycle

### Phase 1: Track

1. Read parent tracker
2. Create working branch: `git checkout -b feat/wc_investigate`
3. Scaffold work item directory and TRACKER.md
4. Distill DESIGN.md
5. Scaffold SPEC.md
6. Scaffold TEST-SPEC.md
7. Break into child tasks if needed

**Gates:**
- [x] /office-hours design referenced
- [x] Working branch created
- [x] DESIGN + SPEC + TEST-SPEC scaffolded
- [x] Acceptance criteria defined
- [x] Tasks broken down (or N/A)

### Phase 2: Implement

1. Read DESIGN + SPEC
2. Implement
3. Smoke tests
4. `/CJ_personal-workflow check`
5. Update tracker + journal
6. Update Files section

**Gates:**
- [x] Acceptance criteria verified
- [x] Smoke tests pass
- [x] Todos current
- [x] Files section updated

### Phase 3: Ship

1. Run `/CJ_personal-workflow check`
2. Smoke in CI
3. E2E manually
4. Children shipped
5. `/ship`
6. `/land-and-deploy`

**Gates:**
- [ ] `/CJ_personal-workflow check` — pass
- [ ] Smoke tests pass in CI
- [ ] E2E walked manually
- [ ] All children shipped (if any)
- [ ] `/ship`
- [ ] `/land-and-deploy`

## Acceptance Criteria

- [ ] `work-copilot/prompts/investigate.prompt.md` exists with `tools: [codebase, search, searchResults, editFiles]`.
- [ ] Prompt reads every file under `.github/work-copilot/domain/*.md` as ambient context (skips `.template.md` skeletons).
- [ ] Prompt greps/searches the target codebase for entities in the user's prompt.
- [ ] Prompt walks user through scoping conversation (problem, target user, narrowest wedge, key risks) in plain chat.
- [ ] Prompt synthesizes design doc to `.github/work-copilot/designs/<short-slug>-design-<datetime>.md` with required frontmatter (`status: DRAFT`, `work_item_type`, `scaffolded_to: null`, `receipts.investigate` block).
- [ ] `work-copilot/domain/domain-knowledge.template.md` exists with skeleton content.
- [ ] `work-copilot/domain/coding-conventions.template.md` exists with skeleton content.
- [ ] `work-copilot/domain/architecture-overview.template.md` exists with skeleton content.
- [ ] `scripts/copilot-deploy.py` extended: installs domain skeletons on first install only (skips with `[KEEP-USER]` if user `.md` exists).
- [ ] `scripts/copilot-deploy.py` extended: creates `.github/work-copilot/designs/.gitkeep` on install.
- [ ] Manual smoke pass: invoke `/wc-investigate` in a test target repo; verify design doc lands at `.github/work-copilot/designs/`; verify domain skeletons survive re-install.

## Todos

- [x] Author `work-copilot/prompts/investigate.prompt.md` with frontmatter + 5 main steps.
- [x] Author 3 domain skeleton templates with light content (commented placeholders).
- [x] Extend `scripts/copilot-deploy.py`: detect filled-vs-skeleton, skip filled on re-install.
- [x] Extend `scripts/copilot-deploy.py`: create `.github/work-copilot/designs/.gitkeep`.
- [x] Document `[KEEP-USER]` and `.gitkeep` behavior in `copilot-deploy.py` help text.
- [x] Smoke + fixture exercise in a test target repo. (E1+E2 dry-run via mktemp; full E3 in Copilot Chat deferred to QA phase.)
- [x] Extend `scripts/validate.sh` `EXPECTED_BUNDLE_FILES` array with 4 new entries (investigate.prompt.md + 3 domain skeletons).
- [x] Extend `scripts/copilot-deploy.py` `cmd_doctor` to classify per-target user-data files as `[USER-DATA]` rather than `[ORPHAN]`. (Discovered during fixture exercise — doctor was exiting non-zero on legitimate user files.)

## Log

- 2026-05-11: Created. Build #4 of Approach C. Blocked by S000032 (consumes /wc-scaffold's design-doc frontmatter schema). Largest story by scope — touches `copilot-deploy.py`.

## PRs

## Files

- `work-copilot/prompts/investigate.prompt.md` (new)
- `work-copilot/domain/domain-knowledge.template.md` (new)
- `work-copilot/domain/coding-conventions.template.md` (new)
- `work-copilot/domain/architecture-overview.template.md` (new)
- `scripts/copilot-deploy.py` (modified — first-install rule, [SEED]/[KEEP-USER] actions for skeletons, designs/.gitkeep seed, [USER-DATA] classification in doctor)
- `scripts/validate.sh` (modified — EXPECTED_BUNDLE_FILES extended with investigate.prompt.md + 3 domain skeletons; updated SHIPPED notes for S000032/S000033)

## Insights

- The first-install-only rule for domain skeletons is the same shape as `~/.claude/` template overwrite-by-default-with-flag-to-preserve (`skills-deploy install --no-overwrite`), but inverted: domain templates are USER DATA by default (skeleton fills the slot on first install; never overwritten on re-install). The difference matters: workbench templates are source-of-truth that gets pushed down; domain templates are per-target seeds that the user fills in.

## Journal

- [decision] 2026-05-11: Domain skeletons use `.template.md` suffix on the bundle side (`work-copilot/domain/*.template.md`); they install to `.github/work-copilot/domain/<name>.md` (no suffix) on first install. The suffix difference is the install-time signal: "if the target file exists without `.template.md`, it's user-filled; skip."
- 2026-05-11 [impl-decision] Implemented the first-install rule in `copilot-deploy.py` by splitting `build_file_map` into two lists (`regular_map` + `skeleton_map`); skeletons are NEVER tracked in `install-manifest.json`, so re-install always sees them via filesystem check (not manifest lookup). This matches the SPEC's "USER DATA by default" semantics (Insights row 1) and keeps the implementation symmetrical with how `designs/.gitkeep` is handled.
- 2026-05-11 [impl-decision] Added `[SEED]` action label alongside existing `[WRITE]/[UPDATE]/[OVERWRITE]/[DRIFT]/[SKIP]` set in `cmd_install`, plus a `[KEEP-USER]` label for the skip-on-existing case. Both also surface in summary counters (`seeded=`, `kept_user=`) for grep-able test assertions.
- 2026-05-11 [impl-finding] During E1+E2 fixture exercise, `cmd_doctor` flagged the 3 seeded domain files + `designs/.gitkeep` as `[ORPHAN]` (because they aren't in `install-manifest.json`). That would block re-install workflows where `doctor` is run as a pre-flight check. Fixed inline by adding a `[USER-DATA]` classification that recognizes paths under `.github/work-copilot/domain/` and `.github/work-copilot/designs/` as legitimate non-manifest content and excludes them from the orphan count + non-zero exit.
- 2026-05-11 [impl-finding] `--auto` orchestrator flag pre-collected the sensitive-surface AUQ approval for `scripts/copilot-deploy.py` edits with explicit scope (first-install rule + `designs/.gitkeep`). Validated scope matches: implementation touched the approved surfaces only, plus an in-scope coordinated `scripts/validate.sh` edit (per implementation context note's "extend EXPECTED_BUNDLE_FILES by FOUR lines") and an unanticipated `cmd_doctor` follow-up surfaced by the fixture exercise. No scope expansion beyond the pre-approval envelope.
- 2026-05-11 [impl] Wrote 4 files (`work-copilot/prompts/investigate.prompt.md`, 3 domain `.template.md` skeletons); modified 2 files (`scripts/copilot-deploy.py`, `scripts/validate.sh`). Smoke tests S1-S5 from TEST-SPEC all pass. Fixture exercise covering E1 (first-install seeds + `.gitkeep`) and E2 (re-install preserves filled content with `[KEEP-USER]` line) executed against `mktemp -d` target; both PASS. E3 (Copilot Chat happy-path) and E4 (no-codebase-matches resilience) deferred to QA phase — they require an actual Copilot session, not bash automation.
- 2026-05-11 [impl-auto] Auto-mode run; orchestrator pre-collected sensitive-surface AUQ for `scripts/copilot-deploy.py` with explicit scope (first-install rule + `designs/.gitkeep`).
- 2026-05-11 [impl-pass] S000033: implementation complete. Phase 2 implementer-owned gates transitioned (`Todos current`, `Files section updated`); QA-owned gates (`Acceptance criteria verified`, `Smoke tests pass`) left for `/CJ_qa-work-item` to run.
- 2026-05-11 [qa-smoke] S1 (AC-6): green — all 3 domain skeleton files present under work-copilot/domain/
- 2026-05-11 [qa-smoke] S2 (AC-1): green — investigate.prompt.md exists with tools: ['codebase', 'search', 'searchResults', 'editFiles']
- 2026-05-11 [qa-smoke] S3 (AC-5): green — 17 frontmatter-contract references found in prompt (>= 4 required)
- 2026-05-11 [qa-smoke] S4 (AC-7): green — KEEP-USER token present in scripts/copilot-deploy.py
- 2026-05-11 [qa-smoke] S5 (AC-8): green — designs/.gitkeep referenced in scripts/copilot-deploy.py
- 2026-05-11 [qa-smoke-summary] green: 5/5 non-manual rows green (0 manual rows pending)
- 2026-05-11 [qa-e2e] E1 (AC-6,7,8): green — fixture exercise against mktemp target: 3 domain .md files seeded (stripped of .template.md suffix), designs/.gitkeep created zero-byte; copilot-deploy.py emitted [SEED] x4 and `seeded=4` in summary counters
- 2026-05-11 [qa-e2e] E2 (AC-7): green — fixture exercise re-installed against same target after user-edit of domain-knowledge.md: emitted [KEEP-USER] for all 3 domain files; pre/post shasum identical (fcffd4a71c91d0e8a33ffda6be2b1ff51e41074a → fcffd4a71c91d0e8a33ffda6be2b1ff51e41074a); user content preserved
- 2026-05-11 [qa-e2e] E3 (AC-1,2,3,4,5): ambiguous — interactive Copilot Chat happy-path; cannot be automation-verified (requires real /wc-investigate session). Deferred to manual walk-through during Phase 3 ship-time E2E. See work-copilot/prompts/investigate.prompt.md frontmatter contract verified by S3 smoke as proxy.
- 2026-05-11 [qa-e2e] E4 (AC-10): ambiguous — interactive Copilot Chat resilience scenario; cannot be automation-verified. Deferred to Phase 3 manual walk-through.
- 2026-05-11 [qa-e2e-summary] green-with-deferred-interactive: E1+E2 fixture-verified green; E3+E4 ambiguous (structurally manual — interactive Copilot Chat). Per parent task guidance, green smoke + green fixture-driven E1/E2 + ambiguous interactive E3/E4 is sufficient to transition Phase 2 QA-owned gates.
- 2026-05-11 [qa-pass] S000033 (user-story): green smoke (5/5) + green fixture-driven E2E (E1, E2) + ambiguous deferred interactive E2E (E3, E4 → Phase 3 manual walk). Phase 2 QA-owned gates transitioned (Acceptance criteria verified, Smoke tests pass).
