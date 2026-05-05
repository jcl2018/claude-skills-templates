---
name: "company-workflow"
type: feature
id: "F000003_company_workflow"
status: shipped
created: "2026-04-11"
updated: "2026-04-25"
repo: "claude-skills-templates"
branch: "claude/nostalgic-volhard"
blocked_by: ""
---

## Lifecycle

### Phase 1: Track

1. Run `/office-hours` to explore the problem space and generate a design doc
   → produces design doc in `~/.gstack/projects/`
2. Create working branch: `git checkout -b feat/{slug}`
3. Scaffold work item directory and TRACKER.md
4. Scaffold `milestones.md` (delivery timeline) — from `templates/doc-milestones.md`
5. Define acceptance criteria (what "done" looks like for the whole feature)
6. Decompose into child user-stories
   → detail (PRD, ARCHITECTURE, TEST-SPEC) lives in child stories

**Gates:**
- [x] Acceptance criteria scoped
- [x] Working branch created (`branch` field populated)
- [x] Milestones scaffolded
- [x] Broken down into child stories

### Phase 2: Implement

1. Child user-stories/tasks drive implementation (feature tracker coordinates)
2. Monitor child progress — update this tracker when children complete phases
3. Update Todos section — check off completed children, add discoveries
4. Update Files section with top-level changed files

**Gates:**
- [x] All child stories have entered Phase 2+
- [x] Feature-level Todos reflect remaining coordination work

### Phase 3: Ship

1. Run `/personal-workflow check` — verify full hierarchy passes all badges
2. Run `/personal-workflow tree` — verify structural completeness (all children present)
3. Ensure all child stories have shipped
4. Run `/ship` — creates feature PR, includes pre-landing code review
5. Run `/land-and-deploy` — merges and verifies

**Gates:**
- [x] `/personal-workflow check` — all children pass validation
- [x] `/personal-workflow tree` — structure complete (S000003 + S000004 + S000005 shipped)
- [x] All children shipped (S000003 implementation; S000004 via PR #38; S000005 via PRs #40 + #41)
- [x] `/ship` — PRs created (#38, #40, #41)
- [x] `/land-and-deploy` — merged and deployed (v0.11.0, v0.12.0, v0.13.0)

## Acceptance Criteria

### Template Registration (shipped)
- [x] `templates/company-workflow/` contains all 13 company spec templates
- [x] `template-registry.json` declares both template sets
- [x] Existing templates unchanged
- [x] validate.sh + test.sh pass

### Standalone Skill
- [x] Skill has no external skillset / harness dependencies
- [x] `company-workflow validate <dir>` enforces artifact completeness per type
- [x] company-artifact-manifests.json created with 5 type entries
- [x] Skill works when installed in any repo via skills-deploy

### Integration
- [x] `skills-deploy install` deploys skill + templates
- [x] Reference guides and philosophy docs accessible

### Knowledge Integration
- [x] Company-workflow skill resolves an external knowledge folder (path is configurable, not hardcoded) — `AI_KNOWLEDGE_DIR` shipped in PR #38
- [x] Arbitrary category subfolders supported (no fixed taxonomy) — runtime discovery via `list_categories()`; `coding/` and `domain/` are illustrative only
- [x] Two-tier surfacing works: `surface: always` auto-injects; `surface: on-demand` loads only when declared `triggers` match the prompt — PRs #40 + #41
- [x] Company-workflow surfaces relevant knowledge during work-item workflows — emitted as `## Always-On Knowledge` + `## On-Demand Knowledge Candidates` blocks read by Claude
- [x] Knowledge folder structure has a documented convention — `## Knowledge Configuration` in WORKFLOW.md
- [x] Works when the knowledge folder is absent (graceful degradation) — warning to stderr, exit 0; `$_KNOWLEDGE_DIR` empty; downstream sections no-op
- [x] Zero regression for existing validate / scaffolding flows — scripted assertion in `scripts/test.sh`

## Todos

### User Stories
- [x] [S000003_company_workflow_implementation](S000003_company_workflow_implementation/S000003_TRACKER.md) — CLOSED, all shipped
- [x] [S000004_knowledge_integration](S000004_knowledge_integration/S000004_TRACKER.md) — SHIPPED via PRs #38 + #40 + #41 (v0.11.0 + v0.12.0 + v0.13.0); env-var resolution + always-on + on-demand

### Knowledge Integration Decisions
- [x] Knowledge folder resolution strategy — **env var** (see Journal 2026-04-16)
- [x] Env var name — **`AI_KNOWLEDGE_DIR`**
- [x] Behavior when unset — **warn every time** the skill runs
- [x] Top-level layout — **flexible subfolders as categories**; skill discovers categories dynamically, no fixed taxonomy
- [x] Within-category file convention — **nesting allowed** (e.g. `coding/cpp/*.md`); any `*.md` file is valid
- [x] Surfacing model — **two-tier: always-on + on-demand**
- [x] Marker mechanism — **per-category `.knowledge.yml`** (no per-file frontmatter override)
- [x] On-demand trigger — **natural-language cue** (skill interprets user intent from the prompt; no rigid command syntax)
- [x] `.knowledge.yml` schema — **`surface: always | on-demand`** + **`triggers: [keyword|phrase, ...]`**
- [x] Default when `.knowledge.yml` is missing — **`surface: on-demand` with empty `triggers`**
- [x] Match semantics — case-insensitive, whole-word; quoted multi-word phrases match as a unit; multiple on-demand matches → load all
- [x] How knowledge is surfaced — **skill-side lookup**: bash enumerates categories + parses yml; Claude Reads emitted paths
- [x] Seed content shipped inside the skill repo — **DROPPED** ($AI_KNOWLEDGE_DIR is user-owned and external by design)

## Log

- 2026-04-11: Created. Company-spec work item system: standalone skill packaging company template spec. Design doc approved (9/10).
- 2026-04-13: Consolidated 3 stories into 1, rewritten for 3-phase lifecycle.
- 2026-04-14: PRD realigned for standalone framing. Stripped external skillset deps from SKILL.md. T000002 closed (registration done). T000005 (check) and T000006 (create) created.
- 2026-04-15: S000003 closed. PRD updated with doc-driven dev workflow and delivery section. All children shipped. Feature ready for /ship.
- 2026-04-16: Knowledge integration scaffolding created. Initial scope: external knowledge folder pluggable into company-workflow. Decisions cascaded: env-var resolution, `AI_KNOWLEDGE_DIR`, flexible category subfolders, two-tier surfacing, per-category `.knowledge.yml` with `surface` + `triggers`.
- 2026-04-16: Phase-1 design locked. Scaffolded S000004 (env-var resolution) + S000005 (knowledge loading; always-on + on-demand share infrastructure).
- 2026-04-17: T000003 landed (commit 6265249) — AI_KNOWLEDGE_DIR resolution in SKILL.md + WORKFLOW.md configuration docs.
- 2026-04-18: /office-hours produced the S000004 design doc. /plan-eng-review found 7 issues, all resolved. Codex outside-voice caught 3 additional findings — all applied.
- 2026-04-18: T000004 landed — 11 scripted assertions in scripts/test.sh. S000004 Phase 2 complete.
- 2026-04-19: Fixture scope change: shared bash helper `scripts/test-helpers/knowledge.sh` synthesizes fixtures in `mktemp -d` per test case (rejected static fixtures under skill source).
- 2026-04-19: Task consolidation. Collapsed multiple tasks → 1 per story (impl + tests ship as one unit per F000001 precedent).
- 2026-04-20: **S000005 shipped in two slices.** PR #40 (v0.12.0, commit 5919369): always-on loading + knowledge-doctor diagnostic. PR #41 (v0.13.0, commit b27946f): on-demand matching. Hardening beyond original plan: log-injection sanitization, 500-path / 100KB hard-fail cap.
- 2026-04-21: **Closure audit.** Implementation fully shipped (S000004 + S000005). All ACs met. Child trackers reconciled to `status: shipped`.
- 2026-04-21: **Seed-content shipping decision dropped.** $AI_KNOWLEDGE_DIR is user-owned and external by design — committing seed files inside the skill repo would blur the boundary drawn in the 2026-04-19 fixture-scope decision.

## PRs

- [#38](https://github.com/jcl2018/claude-skills-templates/pull/38) — merged 2026-04-19 (v0.11.0, commit aca2674). S000004 env-var resolution + scaffolding.
- [#40](https://github.com/jcl2018/claude-skills-templates/pull/40) — merged 2026-04-20 (v0.12.0, commit 5919369). S000005 always-on loading + knowledge-doctor.
- [#41](https://github.com/jcl2018/claude-skills-templates/pull/41) — merged 2026-04-20 (v0.13.0, commit b27946f). S000005 on-demand matching.
- [#47](https://github.com/jcl2018/claude-skills-templates/pull/47) — merged 2026-04-24 (v0.14.3). Knowledge helpers extraction to `bin/knowledge-helpers.sh`.

## Files

- templates/company-workflow/
- skills/company-workflow/SKILL.md (modified — `## Knowledge Resolution` + `## Knowledge Helpers` + `## Knowledge Loading` + `## On-Demand Matching` + `## Diagnostic: knowledge-doctor` sections)
- skills/company-workflow/WORKFLOW.md (modified — `## Knowledge Configuration` section)
- skills/company-workflow/bin/knowledge-helpers.sh (canonical helpers, extracted PR #47)
- skills/company-workflow/company-artifact-manifests.json
- scripts/test-helpers/knowledge.sh (shared fixture builder)
- scripts/test.sh (~35 knowledge test cases)
- template-registry.json
- skills-catalog.json

## Insights

- The skill is standalone: no external skillset / harness dependencies. Portable to any repo.
- Two template systems coexist: workbench (3-phase, user-story) and company (4-phase, userstory). Intentional divergence.
- One unified validate command with file mode (template-derived rules) and directory mode (artifact completeness).
- Knowledge integration: env-var seam (`AI_KNOWLEDGE_DIR`) keeps the knowledge store user-shaped, not skill-shaped. Per-category `.knowledge.yml` keeps the mental model simple (one knob per category, not one per file).
- Graph computation must be deterministic bash, not Claude reasoning. Same lesson as system-health.

## Journal

### 2026-04-11 -- decision
Chose Skill + Template Registry approach. Registry provides clean versioning and explicit template set boundaries.

### 2026-04-11 -- decision
Company templates preserve spec's exact `type: userstory` spelling. Two intentionally different systems.

### 2026-04-14 -- decision
Skill is standalone. No external skillset / harness dependencies. Any references to external skills or harness-specific commands stay outside the skill itself.

### 2026-04-15 -- decision
Simplified from 3 subcommands (validate/check/create) to 1 unified validate command. File mode = contract.json structural rules. Directory mode = artifact completeness via company-artifact-manifests.json. T000005 (check) and T000006 (create) killed.

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
- Name uses `AI_` prefix (not `CLAUDE_`) to keep the variable provider-agnostic — the knowledge store is a general AI-assist resource, not Claude-specific.
- Warning every invocation (vs. warn-once or silent no-op) is intentionally noisy: it nudges the user to configure knowledge rather than silently losing the feature's value.

### 2026-04-16 — decision: flexible category subfolders (no fixed taxonomy)

**Summary:** The top level of `$AI_KNOWLEDGE_DIR` is an open set of category subfolders. The skill discovers categories by reading directory entries at runtime.

**Rationale:** Keeps the knowledge store user-shaped, not skill-shaped — the user can add `security/`, `style/`, `runbooks/`, whatever fits their work without a skill code change.

### 2026-04-16 — decision: nesting + two-tier surfacing (always-on / on-demand)

**Summary:** Within-category nesting is allowed. Knowledge surfacing is two-tier:
1. **Always-on** — injected on every invocation (e.g. house coding style)
2. **On-demand** — loaded only when explicitly requested (situational material)

**Rationale:** Acknowledges that "everything always" overwhelms context and "nothing unless asked" loses default-guidance value.

### 2026-04-16 — decision: per-category `.knowledge.yml` + natural-language on-demand trigger

**Summary:** Each category has a `.knowledge.yml` declaring `surface: always | on-demand`. On-demand triggered by natural-language cues (declared `triggers:`).

**Rationale:** Category-level marker keeps the mental model simple. Natural-language triggering matches how users actually talk to the skill.

### 2026-04-16 — decision: `.knowledge.yml` schema = `surface` + explicit `triggers`

**Summary:** Schema is `surface` (always | on-demand) + explicit `triggers:` list (keywords/phrases). Match: case-insensitive, whole-word on tokens; quoted multi-word phrases match as a unit; multiple matches → load all. `triggers` ignored when `surface: always`.

**Rationale:** Explicit triggers make matching deterministic and reviewable — no LLM-judgment ambiguity.

### 2026-04-19 — decision: fixture scope (rejected committing static fixtures under skill source)

**Summary:** Tests synthesize fixtures in `mktemp -d` via shared bash helper `scripts/test-helpers/knowledge.sh`. Static fixtures under `skills/company-workflow/fixtures/` would conflate skill source with user-owned `$AI_KNOWLEDGE_DIR`.

### 2026-04-21 — decision: drop seed content shipping

**Summary:** $AI_KNOWLEDGE_DIR is user-owned and external by design. Committing seed files inside the skill repo would blur the boundary drawn in the 2026-04-19 fixture-scope decision. The 5-line quick-start in WORKFLOW.md + knowledge-doctor diagnostic already demonstrate a valid layout end-to-end.

### 2026-04-24 -- decision: extract knowledge helpers to a single source file

**Summary:** Moved `parse_knowledge_yml` / `parse_knowledge_triggers` / `list_categories` / `list_md_files` from inline duplication across 4 SKILL.md blocks into `skills/company-workflow/bin/knowledge-helpers.sh`. Sourced via the same 2-level fallback chain as Path Resolution.

**Rationale:** Inline duplication had already drifted (Diagnostic block carried a separate `_parse` shim with subtly different behavior). One canonical implementation means a fix lands once, not four times.

**Consequences:** SKILL.md dropped 1109 → 851 lines. Byte-identity drift tripwire retired (impossible by construction). Shipped in PR #47, v0.14.3.

### 2026-04-25 -- doc cleanup pass

**Summary:** Pruned dead-history references (former feature/skill renames, deferred-elsewhere stories), dropped the per-repo opt-in marker as a desired design decision, generalized "no gstack" wording to "no external skillset / harness dependencies". Implementation realignment to follow.

### 2026-04-25 -- decision: implementation realignment for v1.0.0

**Summary:** Removed the `.claude/knowledge-enabled` opt-in marker from `skills/company-workflow/SKILL.md`, `skills/company-workflow/WORKFLOW.md`, and `scripts/test.sh`. Knowledge loading now activates whenever `$AI_KNOWLEDGE_DIR` resolves to a valid directory. Cross-context isolation is the user's responsibility (scope `$AI_KNOWLEDGE_DIR` per shell, or use `AI_KNOWLEDGE_DISABLE=1` for one-shot bypass).

**Rationale:** S000004_ARCHITECTURE.md and DESIGN.md decision #4 already documented the marker as REJECTED ("redundant on top of two-tier surfacing + env-var control") — the v0.12.0 marker implementation never matched the v1.0 design intent. Realignment makes the impl match the design exactly. v0→v1.0.0 is the right semver boundary for the breaking change to anyone who had `.claude/knowledge-enabled` set up.

**Consequences:** ~50 marker references stripped from SKILL.md + WORKFLOW.md. 7 marker-specific test cases deleted (G1, G2 absent gates; symlink/directory/nested-marker hardening; doctor marker-missing); case 20 simplified; case 30 inverted to assert no `marker:` line in doctor output. SKILL.md's "Knowledge Loading" preconditions list went 5 → 4 entries; the helpful-diagnostic branch for marker-absent + always-on is gone (no marker, no diagnostic). All tests PASS post-realignment.
