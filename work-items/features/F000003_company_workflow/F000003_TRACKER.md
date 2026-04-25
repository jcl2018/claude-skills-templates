---
name: "company-workflow"
type: feature
id: "F000003_company_workflow"
status: shipped
created: "2026-04-11"
updated: "2026-04-24"
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
- [x] Skill has zero gstack dependencies
- [x] `company-workflow validate <dir>` enforces artifact completeness per type
- [x] company-artifact-manifests.json created with 5 type entries
- [x] Skill works when installed in any repo via skills-deploy

### Integration
- [x] `skills-deploy install` deploys skill + templates
- [x] Reference guides and philosophy docs accessible

### Knowledge Integration (absorbed from former F000004 on 2026-04-24)
- [x] Company-workflow skill resolves an external knowledge folder (path is configurable, not hardcoded) — `AI_KNOWLEDGE_DIR` shipped in PR #38
- [x] Arbitrary category subfolders supported (no fixed taxonomy) — runtime discovery via `list_categories()`; `coding/` and `domain/` are illustrative only
- [x] Two-tier surfacing works: `surface: always` auto-injects; `surface: on-demand` loads only when declared `triggers` match the prompt — PRs #40 + #41
- [x] Company-workflow surfaces relevant knowledge during work-item workflows — emitted as `## Always-On Knowledge` + `## On-Demand Knowledge Candidates` blocks read by Claude
- [x] Knowledge folder structure has a documented convention — `## Knowledge Configuration` in WORKFLOW.md
- [x] Per-repo opt-in marker (`.claude/knowledge-enabled`) honored by company-workflow — regular file only; symlinks fail closed
- [x] Works when the knowledge folder is absent (graceful degradation) — warning to stderr, exit 0; `$_KNOWLEDGE_DIR` empty; downstream sections no-op
- [x] Zero regression for existing validate / scaffolding flows — scripted assertion in `scripts/test.sh`

## Todos

### User Stories
- [x] [S000003_company_workflow_implementation](S000003_company_workflow_implementation/S000003_TRACKER.md) — CLOSED, all shipped
- [x] [S000004_env_var_resolution](S000004_env_var_resolution/S000004_TRACKER.md) — SHIPPED via PR #38 (v0.11.0)
- [x] [S000005_knowledge_loading](S000005_knowledge_loading/S000005_TRACKER.md) — SHIPPED via PRs #40 + #41 (v0.12.0 + v0.13.0)

### Knowledge Integration Decisions (absorbed from former F000004)
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
- [x] Milestone #5 (seed content) — **DROPPED 2026-04-21** ($AI_KNOWLEDGE_DIR is user-owned and external by design)

> The personal-workflow port (former S000006) was DEFERRED on 2026-04-20 after /autoplan dual-voice CEO review and now lives under [F000001_personal_workflow](../F000001_personal_workflow/F000001_TRACKER.md) as a deferred child.

## Log

- 2026-04-11: Created. Company-spec work item system: standalone skill packaging company template spec. Design doc approved (9/10).
- 2026-04-13: Consolidated 3 stories into 1, rewritten for 3-phase lifecycle.
- 2026-04-14: PRD realigned for standalone framing. Stripped gstack deps from SKILL.md. T000002 closed (registration done). T000005 (check) and T000006 (create) created.
- 2026-04-15: S000003 closed. PRD updated with doc-driven dev workflow and delivery section. All children shipped. Feature ready for /ship.

### Knowledge Integration Log (absorbed from former F000004 on 2026-04-24)

- 2026-04-16: Knowledge integration scaffolding created. Initial scope: external knowledge folder pluggable into company-workflow. Decisions cascaded: env-var resolution, `AI_KNOWLEDGE_DIR`, flexible category subfolders, two-tier surfacing, per-category `.knowledge.yml` with `surface` + `triggers`.
- 2026-04-16: Phase-1 design locked. Scaffolded S000004 (env-var resolution), S000005 (always-on loading), S000006 (on-demand matching).
- 2026-04-17: Full task decomposition complete. 8 tasks across 3 stories (T000003/T000004 under S000004; T000005/T000006/T000007 under S000005; T000008/T000009/T000010 under S000006). 42 artifacts total.
- 2026-04-17: T000003 landed (commit 6265249) — AI_KNOWLEDGE_DIR resolution in SKILL.md + WORKFLOW.md configuration docs.
- 2026-04-17: Converted F000004 scaffolding to personal-workflow structure. Dropped per-task PR-DESCRIPTION.md and per-story milestones. 42 → 30 artifacts.
- 2026-04-18: /office-hours produced the S000004 design doc. /plan-eng-review found 7 issues, all resolved. Codex outside-voice caught 3 additional findings — all applied.
- 2026-04-18: T000004 landed — 11 scripted assertions in scripts/test.sh. S000004 Phase 2 complete.
- 2026-04-19: Fixture scope change: shared bash helper `scripts/test-helpers/knowledge.sh` synthesizes fixtures in `mktemp -d` per test case (rejected static fixtures under skill source).
- 2026-04-19: Task consolidation. Collapsed 8 tasks → 3 (one per story). Artifact count 30 → 18.
- 2026-04-19: **Story consolidation: S000005 + S000006 → single S000005** (knowledge-loading). Both surfacing paths share infrastructure. Stories 3 → 2. Artifacts 18 → 12.
- 2026-04-20: **S000006 slot repurposed** for personal-workflow parity port (was on-demand-matching). Promoted from a follow-up TODO. Artifacts 12 → 18.
- 2026-04-20: **S000006 DEFERRED** after /autoplan dual-voice CEO review. Codex (CEO voice) and an independent Claude subagent both returned NO-GO independently. 5/6 dimensions CONFIRMED-NO. Rationale: depends on S000005 being on `main`; no documented personal-repo user task that knowledge loading would unlock; symmetry work, not product work, for a single-user workbench. Artifacts retained.
- 2026-04-20: **S000005 shipped in two slices.** PR #40 (v0.12.0, commit 5919369): always-on loading + per-repo opt-in gate + knowledge-doctor diagnostic. PR #41 (v0.13.0, commit b27946f): on-demand matching. Hardening beyond original plan: log-injection sanitization, symlink fails-closed, 500-path / 100KB hard-fail cap.
- 2026-04-21: **Closure audit.** Implementation fully shipped (S000004 + S000005). 8/9 ACs met (the 9th was the deferred S000006 port). Child trackers reconciled to `status: shipped`.
- 2026-04-21: **Milestone #5 dropped; F000004 closed.** $AI_KNOWLEDGE_DIR is user-owned and external by design — committing seed files inside the skill repo would blur the boundary drawn in the 2026-04-19 fixture-scope decision. F000004 flipped to `status: shipped`.
- 2026-04-24: **Consolidation. F000004 merged into F000003 + renamed F000003 from `company_spec_system` → `company_workflow`** so each skill maps to exactly one feature. S000004 + S000005 (both shipped) reparented to F000003. S000006 (deferred personal-workflow port) reparented to F000001_personal_workflow — the canonical home for personal-workflow work. F000003 status flipped from `active` → `shipped` to reflect the absorbed shipped work.

## PRs

- [#38](https://github.com/jcl2018/claude-skills-templates/pull/38) — merged 2026-04-19 (v0.11.0, commit aca2674). F000004 scaffolding + S000004 env-var resolution.
- [#40](https://github.com/jcl2018/claude-skills-templates/pull/40) — merged 2026-04-20 (v0.12.0, commit 5919369). S000005 c2 always-on loading + per-repo opt-in gate + knowledge-doctor.
- [#41](https://github.com/jcl2018/claude-skills-templates/pull/41) — merged 2026-04-20 (v0.13.0, commit b27946f). S000005 c3 on-demand matching.

## Files

- templates/company-workflow/
- skills/company-workflow/SKILL.md (modified — `## Knowledge Resolution` + `## Knowledge Helpers` + `## Knowledge Loading` + `## On-Demand Matching` + `## Diagnostic: knowledge-doctor` sections)
- skills/company-workflow/WORKFLOW.md (modified — `## Knowledge Configuration` section)
- skills/company-workflow/company-artifact-manifests.json
- scripts/test-helpers/knowledge.sh (shared fixture builder)
- scripts/test.sh (~35 F000003-knowledge test cases)
- template-registry.json
- skills-catalog.json

## Insights

- The skill is standalone: zero gstack dependencies. Portable to any repo.
- Two template systems coexist: workbench (3-phase, user-story) and company (4-phase, userstory). Intentional divergence.
- One unified validate command with file mode (contract.json) and directory mode (artifact completeness).
- Knowledge integration: env-var seam (`AI_KNOWLEDGE_DIR`) keeps the knowledge store user-shaped, not skill-shaped. Per-category `.knowledge.yml` keeps the mental model simple (one knob per category, not one per file).
- Graph computation must be deterministic bash, not Claude reasoning. Same lesson as system-health.
- Half-deferred S000006 (personal-workflow port): the right call when /autoplan dual-voice CEO review converged that v1 had 60% of the complexity for 30% of the value without documented user demand. Boiling the lake means deciding what NOT to boil.

## Journal

### 2026-04-11 -- decision
Chose Skill + Template Registry approach. Registry provides clean versioning and explicit template set boundaries.

### 2026-04-11 -- decision
Company templates preserve spec's exact `type: userstory` spelling. Two intentionally different systems.

### 2026-04-14 -- decision
Skill is standalone. Zero gstack dependencies. No analytics, no /review, no /ship, no /docs check references.

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

### 2026-04-19 — decision: story consolidation (S000005 + S000006 → S000005)

**Summary:** Merged former S000006 (on-demand matching) into S000005 (renamed knowledge-loading). Both surfacing paths share `.knowledge.yml` parser, file enumeration, opt-in gate, fixture builder. Original separate stories were bookkeeping overhead.

### 2026-04-20 — decision: S000006 (personal-workflow port) DEFERRED via dual-voice CEO review

**Summary:** /autoplan dual-voice CEO review converged NO-GO. 5/6 dimensions CONFIRMED-NO. Symmetry work, not product work, for a single-user workbench. Evidence gate to reopen: a specific personal-repo task where missing knowledge-loading is an observed blocker.

### 2026-04-21 — decision: drop seed content (Milestone #5)

**Summary:** $AI_KNOWLEDGE_DIR is user-owned and external by design. Committing seed files inside the skill repo would blur the boundary drawn in the 2026-04-19 fixture-scope decision. The 5-line quick-start in WORKFLOW.md + knowledge-doctor diagnostic already demonstrate a valid layout end-to-end.

### 2026-04-24 -- decision: consolidation to one-feature-per-skill

**Summary:** Merged former F000004_knowledge_integration into F000003 and renamed F000003 from `company_spec_system` to `company_workflow`. Each skill now has exactly one canonical feature.

**Rationale:** F000004's S000004 + S000005 shipped to company-workflow; the work was scoped under "knowledge integration" rather than "company-workflow", which split the skill's history across two features. Co-locating under F000003 surfaces the full skill arc (templates → standalone packaging → knowledge integration) in one tracker. The deferred S000006 (personal-workflow port) lives under F000001_personal_workflow now since that's the skill it would touch.

**Consequences:** F000003's `active` status flipped to `shipped` since the absorbed work is in production (PRs #38, #40, #41). The Phase 3 gates (formerly all unchecked) are now checked because the merged shipped work satisfies them.
