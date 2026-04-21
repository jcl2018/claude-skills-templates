---
name: "knowledge-integration"
type: feature
id: "F000004"
status: active
created: "2026-04-16"
updated: "2026-04-20"
repo: "claude-skills-templates"
branch: "claude/heuristic-almeida-2f246d"
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
- [ ] All child stories have entered Phase 2+
- [ ] Feature-level Todos reflect remaining coordination work

### Phase 3: Ship

1. Run `/personal-workflow check` — verify full hierarchy passes all badges
2. Run `/personal-workflow tree` — verify structural completeness (all children present)
3. Ensure all child stories have shipped
4. Run `/ship` — creates feature PR, includes pre-landing code review
5. Run `/land-and-deploy` — merges and verifies

**Gates:**
- [ ] `/personal-workflow check` — all children pass validation
- [ ] `/personal-workflow tree` — structure complete
- [ ] All children shipped
- [ ] `/ship` — PR created
- [ ] `/land-and-deploy` — merged and deployed

## Acceptance Criteria

<!-- What "done" looks like for this feature. Each criterion should be
     testable and specific. -->

- [ ] Company-workflow skill resolves an external knowledge folder (path is configurable, not hardcoded)
- [ ] ~~Personal-workflow skill resolves the same external knowledge folder with identical semantics (S000006 parity port)~~ **DEFERRED 2026-04-20** — evidence-gated (see Log)
- [ ] Arbitrary category subfolders supported (no fixed taxonomy); `coding/` and `domain/` are illustrative, not required
- [ ] Two-tier surfacing works: `surface: always` categories auto-inject; `surface: on-demand` load only when a declared `triggers` keyword/phrase appears in the prompt
- [ ] Company-workflow surfaces relevant knowledge during work-item workflows (Track / Implement / Ship phases) without the user having to copy-paste
- [ ] Knowledge folder structure has a documented convention (directory layout, file naming, frontmatter if any) — documented in company-workflow's WORKFLOW.md
- [ ] Per-repo opt-in marker (`.claude/knowledge-enabled`) is honored by company-workflow
- [ ] Works when the knowledge folder is absent (graceful degradation, not an error)
- [ ] Zero regression for existing company-workflow validate / scaffolding flows

## Todos

<!-- Actionable items for this feature. Break into child tasks for
     large features. -->

- [x] Decide knowledge folder resolution strategy — **env var** (see Journal 2026-04-16)
- [x] Name the env var — **`AI_KNOWLEDGE_DIR`**
- [x] Decide behavior when unset — **warn every time** the skill runs
- [x] Define knowledge folder top-level layout — **flexible subfolders as categories** (e.g. `coding/`, `domain/`, or any other name); skill discovers categories dynamically, no fixed taxonomy
- [x] Decide within-category file convention — **nesting allowed** (e.g. `coding/cpp/*.md`); any `*.md` file is valid
- [x] Decide surfacing model — **two-tier: always-on + on-demand** (see Journal 2026-04-16)
- [x] Decide marker mechanism — **per-category `.knowledge.yml`** (no per-file frontmatter override)
- [x] Decide on-demand trigger — **natural-language cue** (skill interprets user intent from the prompt; no rigid command syntax)
- [x] Define `.knowledge.yml` schema — **`surface: always | on-demand`** + **`triggers: [keyword|phrase, ...]`** (explicit declared triggers; no inference from folder name)
- [x] Decide default when `.knowledge.yml` is missing — **`surface: on-demand` with empty `triggers`** (category stays dark until user writes the file)
- [x] Match semantics — **case-insensitive, whole-word on prompt tokens; quoted multi-word phrases match as a unit; multiple on-demand matches → load all**
- [x] `triggers` on `surface: always` — **ignored** (always-on loads unconditionally)
- [ ] Decide how knowledge is surfaced: skill-side lookup, slash-command, or template placeholder expansion
- [ ] Draft a child user-story for the resolution + surfacing mechanism
- [ ] Draft a child user-story for the knowledge folder convention + seed content (cpp guide, one domain stub)
- [x] Sync with `/personal-workflow`: does personal-dev need parallel knowledge support? — **Yes, eventually.** Decision: port after S000006 lands. Cheapest path is lift-and-shift of the three bash sections (Resolution, Loading, Matching) from `skills/company-workflow/SKILL.md` into `skills/personal-workflow/SKILL.md`. Same env var (`AI_KNOWLEDGE_DIR`), same conventions, zero new design. User will tackle later.
- [x] Port knowledge feature to `/personal-workflow` — scoped into `S000006_personal_workflow_port` (2026-04-20), then **DEFERRED 2026-04-20** after /autoplan dual-voice CEO review. Evidence gate: reopen when a specific personal-repo task where missing knowledge-loading is an observed blocker surfaces. Artifacts retained (see S000006_* and T000007_* directories + design doc at `~/.gstack/projects/jcl2018-claude-skills-templates/chjiang-main-design-20260420-203757.md`).
- [ ] Ship S000004 (landed via PR #38)
- [ ] Ship S000005 (knowledge-loading — in flight)
- [ ] ~~Ship S000006 (personal-workflow port)~~ **DEFERRED** — evidence-gated unblock

## Log

<!-- Chronological entries with dates and commit SHAs. -->

- 2026-04-16: Created. Initial scaffolding for knowledge integration feature: external knowledge folder (coding guidance + company domain knowledge) pluggable into company-workflow.
- 2026-04-16: Decision — knowledge folder resolved via env var (not fixed path, not per-repo).
- 2026-04-16: Decision — env var is `AI_KNOWLEDGE_DIR`; when unset, skill emits a warning every invocation.
- 2026-04-16: Decision — top-level layout uses flexible category subfolders; skill discovers them at runtime (no fixed taxonomy).
- 2026-04-16: Decision — within-category nesting allowed (e.g. `coding/cpp/*.md`); surfacing is two-tier (always-on + on-demand).
- 2026-04-16: Decision — per-category `.knowledge.yml` marker (no per-file override); on-demand triggered by natural-language cue in the user prompt.
- 2026-04-16: Decision — `.knowledge.yml` schema is `surface` + explicit `triggers` list (no inference from folder name).
- 2026-04-16: Phase-1 design locked. Missing-file default = on-demand+empty triggers. Match = case-insensitive whole-word + quoted phrases, multi-match loads all. `triggers` ignored for always-on.
- 2026-04-16: Scaffolded S000004 (env-var resolution + missing-folder warning) — first of 3 planned vertical slices. Two more stories (always-on loading, on-demand matching) still to scaffold.
- 2026-04-16: Scaffolded S000005 (always-on loading) and S000006 (on-demand matching). Phase-1 decomposition complete (all 3 vertical slices scaffolded). Ready to move to Phase-2 Implement once S000004 lands.
- 2026-04-17: Full task decomposition complete. 8 tasks scaffolded across the 3 stories (T000003/T000004 under S000004; T000005/T000006/T000007 under S000005; T000008/T000009/T000010 under S000006). Each task has TRACKER + test-plan + PR-DESCRIPTION (24 artifacts). 42 artifacts total for F000004.
- 2026-04-17: T000003 landed (commit 6265249) — AI_KNOWLEDGE_DIR resolution in SKILL.md + WORKFLOW.md configuration docs.
- 2026-04-17: Converted F000004 scaffolding to personal-workflow structure. Dropped: feature-summary.md, per-story milestones.md, per-task PR-DESCRIPTION.md (12 files). Rewrote all TRACKERs to 3-phase lifecycle (Track/Implement/Ship — no Review) and simplified frontmatter (no workflow_type, no url). Content (AC, Todos, Log, Journal, design decisions) preserved in full. 42 → 30 artifacts.
- 2026-04-18: /office-hours produced the S000004 design doc (alternatives audit). /plan-eng-review ran on it: 7 issues found, all resolved. Codex outside-voice caught 3 additional findings (fake CI coverage, cross-context contamination, log injection) — all applied. Sanitization patch to SKILL.md committed (a46efa9). Per-repo opt-in gate added to S000005 TRACKER as P0.
- 2026-04-18: T000004 landed — 11 scripted assertions in scripts/test.sh, full suite passes. S000004 Phase 2 complete; child-story ready to ship whenever user runs /ship. S000005 and S000006 unblock next.
- 2026-04-19: Decided to also port the knowledge feature to `/personal-workflow` after S000006 lands in company-workflow. Captured as a follow-up TODO in this tracker. User will tackle later; not part of the original F000004 vertical slicing.
- 2026-04-19: Fixture scope change for S000005/S000006. Rejected committing static fixtures under `skills/company-workflow/fixtures/` — conflates skill source with user-owned `$AI_KNOWLEDGE_DIR`. Revised to shared bash helper `scripts/test-helpers/knowledge.sh` that synthesizes fixtures in `mktemp -d` per test case.
- 2026-04-19: Task consolidation across all three stories. Collapsed 8 tasks → 3 (one task per story) per F000001/F000003 precedent. S000004: T000004_tests absorbed into T000003. S000005: T000005_build_fixtures + T000007_tests absorbed into T000006. S000006: T000008_refactor_shared_helper + T000010_tests absorbed into T000009. Separate tests/refactor/fixture tasks were bookkeeping overhead — each story fits in one PR. Artifact count dropped 30 → 18.
- 2026-04-19: **Story consolidation: S000005 + S000006 → single S000005.** Merged former S000006 (on-demand matching) into S000005, renamed `always-on-loading` → `knowledge-loading`. Both surfacing paths share the `.knowledge.yml` parser, file enumeration, per-repo opt-in gate, and fixture builder; T000009 was already blocked on T000006 to extract a shared helper, exposing the slice boundary as a refactor inside the next slice (i.e. not a real PR boundary). T000009 absorbed into T000006 (renamed `implement-loading-and-matching`). Trade-off accepted: one bigger PR (~400 lines bash + tests) vs. two smaller; lose option to ship always-on alone if on-demand stalls, mitigated by sequencing impl within T000006 (always-on first, then on-demand). Stories: 3 → 2. Tasks: 3 → 2. Artifacts: 18 → 12. Follow-up "port to /personal-workflow" rebased from "blocked by S000006" → "blocked by S000005" (the merged story).
- 2026-04-20: **Scope extension: `/personal-workflow` parity port scoped into S000006.** Promoted the "port to /personal-workflow" follow-up TODO into a proper user-story (S000006_personal_workflow_port) with full artifact set (TRACKER + PRD + ARCHITECTURE + TEST-SPEC) and a single task child T000007. Single-story approach (not split by resolution/loading) to avoid a half-ported cutover where personal-workflow resolves the env var but doesn't load content. Blocked by S000005 landing. No new design, env var, schema, or opt-in marker — everything mirrors what S000004+S000005 ship for company-workflow. Feature AC + milestones updated to reflect both skills. Stories: 2 → 3. Tasks: 2 → 3. Artifacts: 12 → 18.
- 2026-04-20: **S000006 DEFERRED after /autoplan dual-voice CEO review.** Ran /autoplan on the S000006 execution-plan design doc. Codex (CEO voice) and an independent Claude subagent both returned NO-GO independently. CEO dual-voice consensus table: 5/6 dimensions CONFIRMED-NO, 0 DISAGREE. Key findings both voices raised: (1) plan depends on S000005 being on `main` and on `scripts/test-helpers/knowledge.sh` existing — neither is true yet; (2) no documented personal-repo user task that knowledge loading would unlock — this is symmetry work, not product work, for a single-user workbench; (3) the "~20 line drift tripwire" is a shared abstraction smeared across `scripts/test.sh` instead of a shared helper file — Approach B (extract `scripts/knowledge.sh`) is the cleaner form of the same idea; (4) premises asserted not verified. User chose at premise gate to defer rather than override dual-voice signal. Scope reverts: F000004 stories back to 2 active (S000004 + S000005) + 1 deferred (S000006). Artifacts retained (not deleted) so the work is resumable; design doc at `~/.gstack/projects/jcl2018-claude-skills-templates/chjiang-main-design-20260420-203757.md` has the full review report appended. Evidence gate to reopen: a specific personal-repo task where missing knowledge-loading is an observed blocker.

## PRs

<!-- PR links with status (open/merged/closed). -->

## Files

<!-- Affected file paths. Populated during Track phase, updated during Implement. -->

## Insights

<!-- Non-obvious findings worth remembering. Design decisions,
     trade-offs, patterns discovered. -->

## Journal

<!-- Structured entries from the work-track journal command. Each entry has a type
     (decision, finding, blocker) and a Summary field. -->

### 2026-04-16 — decision: env-var resolution for knowledge folder

**Summary:** Knowledge folder location is resolved via an environment variable.

**Alternatives considered:**
- Fixed path (e.g. `~/.claude/knowledge/`) — rejected: no way to relocate without symlinks; couples knowledge to home dir layout
- Per-repo `.knowledge/` — rejected: forces duplication across repos; defeats the purpose of a cross-project knowledge store
- Multi-source (env var + per-repo overlay) — deferred as potential follow-up; ship single-source first

**Rationale:** Env var gives the user a single knob, works across repos, is testable (override in CI / fixtures), and degrades cleanly when unset (skill operates as today).

**Open follow-ups:** whether to also accept `$XDG_CONFIG_HOME/claude/knowledge` as a fallback (deferred).

### 2026-04-16 — decision: env var name and unset behavior

**Summary:** Env var is named `AI_KNOWLEDGE_DIR`. When unset, the skill emits a warning on every invocation.

**Rationale:**
- Name uses `AI_` prefix (not `CLAUDE_`) to keep the variable provider-agnostic — the knowledge store is a general AI-assist resource, not Claude-specific.
- Warning every invocation (vs. warn-once or silent no-op) is intentionally noisy: it nudges the user to configure knowledge rather than silently losing the feature's value. Revisit if the warning becomes annoying in practice.

**Implementation notes (for the child user-story):**
- Warning text should name the variable, point to setup docs, and be one line.
- Warning channel: stderr (company-workflow already writes validate output to stderr on failure).
- The warning is advisory — exit code must remain 0 so CI / scripting that invokes the skill doesn't break.
- Confirm casing with user: normalized from the literal `AI_Knowledge_DIr` they typed to conventional uppercase `AI_KNOWLEDGE_DIR`.

### 2026-04-16 — decision: flexible category subfolders (no fixed taxonomy)

**Summary:** The top level of `$AI_KNOWLEDGE_DIR` is an open set of category subfolders. `coding/` and `domain/` are illustrative examples, not required names. The skill discovers categories by reading directory entries at runtime.

**Rationale:**
- Keeps the knowledge store user-shaped, not skill-shaped — the user can add `security/`, `style/`, `runbooks/`, whatever fits their work without a skill code change.
- Avoids a validation rule that would reject legitimate user organizations.
- Ships faster: no upfront taxonomy negotiation.

**Consequences:**
- The skill cannot assume any category exists (no special-casing `coding/` or `domain/`).
- Category-to-context matching cannot be hardcoded by folder name; it has to be derived (e.g. filename match, frontmatter tags, or user-invoked selection). See open follow-up.
- Docs and examples should present `coding/` and `domain/` as illustrative, with language like "for example" or "typical categories include..."

**Open follow-ups (now elevated to Todos):**
- Within-category structure: flat `<category>/*.md` only, or nested like `coding/cpp/*.md`?
- Matching rule: how does the skill decide which category/file is relevant to the current work item?

### 2026-04-16 — decision: nesting + two-tier surfacing (always-on / on-demand)

**Summary:**
- Within-category nesting is allowed. A category can be flat (`domain/foo.md`) or nested (`coding/cpp/errors.md`). Any `.md` file under a category is a valid knowledge file.
- Knowledge surfacing is two-tier:
  1. **Always-on** — injected into the skill's context on every invocation. Used for guidance the user wants Claude to apply by default (e.g. house coding style).
  2. **On-demand** — loaded only when the user explicitly asks for a specific category/file. Used for situational material (domain deep-dives, runbooks).

**Rationale:**
- Nesting allowed because users already organize by language/subsystem; forbidding it would force workarounds.
- The two-tier split is the key user-surfaced knob: it acknowledges that "everything always" overwhelms context and "nothing unless asked" loses the default-guidance value. The user controls which knowledge is which.

**Consequences:**
- Each knowledge file (or each category) needs a marker that says "always-on" vs. "on-demand". Frontmatter flag is the likely mechanism — keeps the marker local to the file and works with nesting. A category-level default (`.knowledge.yml` or similar) could reduce per-file boilerplate.
- The skill needs a deterministic load order when multiple always-on files exist (suggest: sorted by category, then path).
- On-demand needs a user-facing trigger. Candidates: `/company-workflow knowledge <category>`, natural-language mention in the prompt that the skill scans for, or a dedicated slash command.
- Context-budget implications: always-on knowledge stacks on every invocation. Consider a soft cap or a warning when total always-on bytes exceed a threshold.

**Open follow-ups (now Todos):**
- Marker mechanism (frontmatter per file, category default file, or both).
- On-demand trigger syntax.

### 2026-04-16 — decision: per-category `.knowledge.yml` + natural-language on-demand trigger

**Summary:**
- Each category directory has a `.knowledge.yml` file that declares the surfacing mode (`always` or `on-demand`). No per-file override — a whole category is one or the other.
- On-demand knowledge is triggered by a natural-language cue in the user's prompt (the skill interprets intent). No rigid command syntax like `/knowledge load <category>`.

**Rationale:**
- Category-level marker keeps the mental model simple: one knob per category, not one per file. Users organize by splitting into categories, not by tagging individual files.
- Natural-language triggering matches how users actually talk to the skill ("help me with cpp error handling") vs. forcing a command grammar. Preserves the skill's conversational ergonomics.

**Consequences:**
- To mix always-on and on-demand material, the user must split into two categories (e.g. `coding-style/` always-on + `coding-reference/` on-demand). This is the intended constraint.
- The skill needs an intent-extraction step before running the workflow: scan the prompt, match against discovered category names (or keywords declared in each category's `.knowledge.yml`), and load matching on-demand categories.
- Natural-language matching will be fuzzy; false positives (loading unneeded knowledge) and false negatives (missing a needed category) are both possible. Needs a spec.
- Missing `.knowledge.yml` needs a default — on-demand is safer (doesn't auto-inject content the user may not have reviewed).

**Open follow-ups (now Todos):**
- `.knowledge.yml` schema — minimum `surface: always | on-demand`; may also want a `triggers:` list (keywords/phrases that count as on-demand cues).
- Default when `.knowledge.yml` missing (proposal: `on-demand`, zero triggers → effectively dark until the user writes the file).
- Natural-language trigger heuristic specification (category-name mention vs. declared trigger keywords vs. LLM judgment; ambiguity handling when multiple categories match).

### 2026-04-16 — decision: `.knowledge.yml` schema = `surface` + explicit `triggers`

**Summary:** Each category's `.knowledge.yml` declares both the surfacing mode and an explicit list of trigger keywords/phrases. Example:

```yaml
# $AI_KNOWLEDGE_DIR/coding/.knowledge.yml
surface: always
triggers: []   # not used when surface: always

# $AI_KNOWLEDGE_DIR/domain/.knowledge.yml
surface: on-demand
triggers:
  - pricing engine
  - billing
  - PE   # internal acronym
```

**Rationale:**
- Explicit triggers make matching deterministic and reviewable — the user sees exactly which words will pull a category into context. No LLM-judgment ambiguity.
- Also handles the "category name is a poor keyword" case (e.g. a `domain/` folder about a specific product — the folder name `domain` tells Claude nothing; the triggers do).
- Keeps the schema minimal (two keys) while leaving room to extend later without breaking existing files.

**Match semantics (to be finalized — see Todos):**
- Proposed: case-insensitive, whole-word match on tokens from the prompt. Substring within a quoted phrase treated as a single unit. Multiple matches → load all matched categories.
- `triggers` ignored when `surface: always` (always-on loads unconditionally).

**Consequences:**
- Bad `triggers` lists will cause false positives (too-generic keywords like "code") or false negatives (missing synonyms). Quality of knowledge surfacing is bounded by the quality of the trigger lists. That's the user's responsibility, not the skill's — but the skill should document the trade-off.
- `.knowledge.yml` becomes a small but real file users must write. The missing-file default (see Todos) must be sensible so categories without a `.knowledge.yml` don't break the skill.
