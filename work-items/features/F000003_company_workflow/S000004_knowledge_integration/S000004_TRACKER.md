---
name: "knowledge-integration"
type: user-story
id: "S000004"
status: shipped
created: "2026-04-16"
updated: "2026-04-25"
parent: "F000003_company_workflow"
repo: "claude-skills-templates"
branch: "claude/heuristic-almeida-2f246d"
blocked_by: ""
---

## Lifecycle

### Phase 1: Track

1. Read parent tracker to understand scope
2. Run `/office-hours` with your idea
   → produces design doc in `~/.gstack/projects/`
3. Create working branch: `git checkout -b feat/{slug}`
4. Scaffold work item directory and TRACKER.md
5. Scaffold required docs from design doc:
   - `PRD.md` (requirements) — from `templates/doc-PRD.md`
   - `ARCHITECTURE.md` (architecture decisions) — from `templates/doc-ARCHITECTURE.md`
   - `TEST-SPEC.md` (test scenarios) — from `templates/doc-TEST-SPEC.md`
6. Break into child tasks if scope warrants decomposition

**Gates:**
- [x] Acceptance criteria defined
- [x] Working branch created (`branch` field populated)
- [x] Required docs scaffolded (PRD + ARCHITECTURE + TEST-SPEC)
- [x] Tasks broken down (T000003 + T000006)

### Phase 2: Implement

1. Child tasks drive implementation (user-story tracker coordinates)
2. Monitor child progress — update this tracker when children complete phases
3. Update Todos section — check off completed children, add discoveries
4. Update Files section with changed file paths

**Gates:**
- [x] All child tasks have entered Phase 2+
- [x] Acceptance criteria verified met
- [x] Todos section reflects remaining work (no stale items)
- [x] Files section updated with changed files

### Phase 3: Ship

1. Run `/personal-workflow check` — verify all validation passes
2. Run `/personal-workflow tree` — verify hierarchy and structural completeness
3. Verify TEST-SPEC alignment: do test cases cover all P0 acceptance criteria?
4. Ensure all child tasks have shipped
5. Run `/ship` — creates PR, bumps version, updates changelog (includes pre-landing code review)
6. Run `/land-and-deploy` — merges PR and verifies deployment

**Gates:**
- [x] `/personal-workflow check` — validation passed
- [x] `/personal-workflow tree` — structure verified
- [x] TEST-SPEC covers all P0 acceptance criteria
- [x] All children shipped (T000003 in PR #38; T000006 in PRs #40 + #41)
- [x] `/ship` — PRs created (#38, #40, #41)
- [x] `/land-and-deploy` — merged and deployed (v0.11.0, v0.12.0, v0.13.0)

## Acceptance Criteria

<!-- One unified story covering env-var resolution + always-on loading + on-demand
     matching. Single shared infrastructure: yml parser, file enumeration, fixture
     builder. Three slices for shipping convenience (T000003 = resolution; T000006 =
     loading + matching split into PRs #40 and #41). -->

### Layer 1: Env-var resolution (T000003 / PR #38)

- [x] `company-workflow` skill reads `AI_KNOWLEDGE_DIR` on every invocation and exposes the resolved path as a skill-internal variable for downstream layers
- [x] When `AI_KNOWLEDGE_DIR` is unset OR empty: skill emits exactly one warning line on stderr naming the variable and pointing to docs, exit code remains 0
- [x] When `AI_KNOWLEDGE_DIR` is set but the path does not exist or is not a directory: skill emits a warning mentioning the configured path, exit code remains 0
- [x] When `AI_KNOWLEDGE_DIR` is set and points to a valid directory: no warning emitted
- [x] No knowledge files are read or loaded by Layer 1 (resolution only)

### Layer 2: Always-on loading (T000006 / PR #40)

- [x] Given `$_KNOWLEDGE_DIR` is a valid directory, skill enumerates top-level subdirectories as categories — `list_categories()`
- [x] For each category with `.knowledge.yml { surface: always }`: all nested `*.md` files are loaded into Claude's context (Claude Reads emitted paths)
- [x] Load order is deterministic: `LC_ALL=C` lex-sort of categories and md files
- [x] A category with no `.knowledge.yml`, or with `surface: on-demand`, contributes zero content via always-on

### Layer 3: On-demand matching (T000006 / PR #41)

- [x] Categories with `surface: on-demand` emit triggers + category root under `## On-Demand Knowledge Candidates`
- [x] Claude matches user's latest prompt (case-insensitive whole-word; quoted multi-word phrases at token boundaries)
- [x] Matched categories: Claude Reads every `*.md` under each match (recursive, same enumeration rules)
- [x] Multiple matches: content from all matched categories is loaded
- [x] Empty `triggers: []` never match; inert category until user adds triggers
- [x] `surface: always` never considered by on-demand matching logic

### Resilience + zero regression

- [x] Malformed `.knowledge.yml` → one-line stderr warning naming the file, skip the category, siblings continue, exit 0
- [x] `$_KNOWLEDGE_DIR` empty → no loading, no matching, no additional warning (Layer 1's warning already emitted)
- [x] `validate` output byte-identical with and without knowledge (zero regression)
- [x] **Bonus hardening:** log-injection sanitization on env-var display; 500-path / 100KB hard-fail cap; `AI_KNOWLEDGE_DISABLE` one-shot escape hatch; `knowledge-doctor` diagnostic; helpers extracted to `bin/knowledge-helpers.sh` (PR #47)

## Todos

<!-- Actionable items for this story; all shipped. -->

### Layer 1 (env-var resolution)

- [x] Draft warning text variants (3: unset/empty, path-not-found, path-is-file)
- [x] Add `## Knowledge Resolution` block to SKILL.md
- [x] Decide warning emission point — skill preamble, every invocation
- [x] Tier 1 + Tier 2 tests in scripts/test.sh
- [x] WORKFLOW.md `## Knowledge Configuration` setup instructions
- [x] Confirm zero regression against existing fixtures

### Layers 2 + 3 (loading + matching)

- [x] Decide injection mechanism — **Claude Reads listed paths** (keeps preamble small, native Read tool)
- [x] Decide `.knowledge.yml` parser — **native bash + awk** (zero deps; supports `surface` + `triggers` flat keys)
- [x] Define malformed-file warning text — `[knowledge] malformed .knowledge.yml at <path> — skipping category.`
- [x] Hard-fail at 500 paths / 100KB (loud refusal over silent partial load)
- [x] Tokenize prompt for on-demand — **Claude does both tokenization + match**
- [x] Diagnostic surfacing — `[knowledge] matched: <cat> via <trigger>` per matched category (stderr)
- [x] "Prompt tokens" scope — **latest user message only**
- [x] Common-word triggers — **no skill-side filtering**; user's responsibility
- [x] `scripts/test-helpers/knowledge.sh` shared fixture builder
- [x] Tier 1 + Tier 2 E2E tests (~35 cases)
- [x] WORKFLOW.md `## Knowledge Configuration` expanded (quick-start + troubleshooting + escape hatches + schema + trigger-authoring + caps + doctor)

## Log

- 2026-04-16: Created. First slice (Layer 1, env-var resolution) scaffolded as Story 1 of knowledge integration.
- 2026-04-17: Decomposed Layer 1 → T000003 (resolution + warning impl) and T000004 (tests). T000004 blocked by T000003.
- 2026-04-17: T000003 landed (commit 6265249).
- 2026-04-18: T000004 (tests) landed. scripts/test.sh has 11 new assertions; all Layer 1 ACs verified or explicitly deferred to Layer 2/3. Phase 2 gates satisfied for Layer 1.
- 2026-04-18: /office-hours produced the Layer 1 design doc. /plan-eng-review found 7 issues, all resolved. Codex outside-voice caught 3 additional findings — all applied.
- 2026-04-19: Fixture scope: shared bash helper `scripts/test-helpers/knowledge.sh` synthesizes fixtures in `mktemp -d` per test case (rejected static fixtures under skill source).
- 2026-04-19: Task consolidation. Layer-1 T000004 absorbed into T000003 (impl + tests ship as one unit per F000001 precedent). PR #38 already squashed both.
- 2026-04-19: Layers 2+3 design locked. Both surfacing paths share infrastructure (yml parser, file enumeration, fixture builder); decided to ship them under one task (T000006).
- 2026-04-20: **Layer 2 shipped** in PR #40 (v0.12.0, commit 5919369): always-on loading + knowledge-doctor diagnostic.
- 2026-04-20: **Layer 3 shipped** in PR #41 (v0.13.0, commit b27946f): on-demand matching. Hardening beyond original plan: log-injection sanitization, 500-path / 100KB hard-fail cap.
- 2026-04-21: Story closed — all ACs verified met across Layers 1 + 2 + 3.
- 2026-04-24: Knowledge helpers extracted to `bin/knowledge-helpers.sh` (PR #47, v0.14.3). Single canonical implementation sourced by every `## Knowledge ...` block.
- 2026-04-25: **Doc consolidation.** Former env-var-resolution + knowledge-loading user-stories merged into one directory `S000004_knowledge_integration/`. Both shipped slices were always conceptually one story; the split was vertical-slicing bookkeeping. Per-repo opt-in marker dropped from desired design (impl realignment to follow).

## PRs

- [#38](https://github.com/jcl2018/claude-skills-templates/pull/38) — merged 2026-04-19 (v0.11.0, commit aca2674). Layer 1: env-var resolution + scaffolding.
- [#40](https://github.com/jcl2018/claude-skills-templates/pull/40) — merged 2026-04-20 (v0.12.0, commit 5919369). Layer 2: always-on loading + knowledge-doctor.
- [#41](https://github.com/jcl2018/claude-skills-templates/pull/41) — merged 2026-04-20 (v0.13.0, commit b27946f). Layer 3: on-demand matching.
- [#47](https://github.com/jcl2018/claude-skills-templates/pull/47) — merged 2026-04-24 (v0.14.3). Knowledge helpers extraction to `bin/knowledge-helpers.sh`.

## Files

- skills/company-workflow/SKILL.md (modified — `## Knowledge Resolution` + `## Knowledge Helpers` + `## Knowledge Loading` + `## On-Demand Matching` + `## Diagnostic: knowledge-doctor` sections)
- skills/company-workflow/WORKFLOW.md (modified — `## Knowledge Configuration` section)
- skills/company-workflow/bin/knowledge-helpers.sh (canonical helpers, extracted PR #47)
- scripts/test-helpers/knowledge.sh (shared fixture builder)
- scripts/test.sh (modified — ~35 knowledge test cases across tier-1 structural + tier-2 behavioral)

## Insights

- The split between Layer 1 (resolution), Layer 2 (always-on), and Layer 3 (on-demand) is conceptual, not architectural: Layers 2 + 3 walk the same category tree, parse the same `.knowledge.yml`, share the same enumeration helpers. The slice boundary was bookkeeping for shipping; the real implementation is one cohesive feature.
- Claude-as-matching-engine for on-demand is a Claude-Code-skill-specific pattern: bash can't see the user's prompt, so the skill emits candidates + rules and Claude does the match. Generalizes to any future "skill emits structured options, Claude picks based on prompt" interaction.

## Journal

### 2026-04-16 — decision: env-var resolution for knowledge folder

**Summary:** Knowledge folder location is resolved via an environment variable.

**Alternatives considered:**
- Fixed path (e.g. `~/.claude/knowledge/`) — rejected: no way to relocate without symlinks; couples knowledge to home dir layout
- Per-repo `.knowledge/` — rejected: forces duplication across repos; defeats the purpose of a cross-project knowledge store
- Multi-source (env var + per-repo overlay) — deferred as potential follow-up; ship single-source first

**Rationale:** Env var gives the user a single knob, works across repos, is testable (override in CI / fixtures), and degrades cleanly when unset (skill operates as today).

### 2026-04-16 — decision: env var name and unset behavior

**Summary:** Env var is named `AI_KNOWLEDGE_DIR`. When unset, the skill emits a warning on every invocation.

**Rationale:**
- Name uses `AI_` prefix (not `CLAUDE_`) to keep the variable provider-agnostic — the knowledge store is a general AI-assist resource.
- Warning every invocation (vs. warn-once or silent no-op) is intentionally noisy: it nudges the user to configure knowledge rather than silently losing the feature's value.

### 2026-04-19 — decision: fixture scope (rejected committing static fixtures under skill source)

**Summary:** Tests synthesize fixtures in `mktemp -d` via shared bash helper. Static fixtures under `skills/company-workflow/fixtures/` would conflate skill source with user-owned `$AI_KNOWLEDGE_DIR`.

### 2026-04-19 — decision: bundle Layers 2 + 3 under one task

**Summary:** T000006 (`implement_loading_and_matching`) covers both always-on loading and on-demand matching. Both share the `.knowledge.yml` parser, file enumeration, and fixture builder; splitting them across two tasks would have meant duplicating the helpers or introducing an artificial sequencing dependency.

**Trade-offs accepted:**
- Bigger PR review surface. Mitigated by sequencing: always-on shipped first (PR #40), on-demand next (PR #41), so review surface stayed manageable per slice.

### 2026-04-25 — decision: drop per-repo opt-in marker from desired design

**Summary:** The two-tier surfacing model (`surface: always` vs `surface: on-demand` + triggers) is the only context-scoping knob in the desired design. Per-repo `.claude/knowledge-enabled` marker is removed from the target architecture.

**Rationale:** Adding a per-repo gate on top of the two-tier model is redundant complexity. Cross-context isolation is the user's responsibility — control which categories are `surface: always`, which carry triggers, or unset `$AI_KNOWLEDGE_DIR` per shell. Implementation realignment to follow.
