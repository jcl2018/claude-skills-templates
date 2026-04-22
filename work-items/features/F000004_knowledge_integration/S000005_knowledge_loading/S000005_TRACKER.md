---
name: "knowledge-loading"
type: user-story
id: "S000005"
status: shipped
created: "2026-04-16"
updated: "2026-04-21"
parent: "F000004"
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
- [x] Tasks broken down (if needed)

### Phase 2: Implement

1. Child tasks drive implementation (user-story tracker coordinates)
2. Monitor child progress — update this tracker when children complete phases
3. Update Todos section — check off completed children, add discoveries
4. Update Files section with changed file paths

**Gates:**
- [x] All child tasks have entered Phase 2+
- [x] Acceptance criteria verified met (all 14 ACs below)
- [x] Todos section reflects remaining work (no stale items)
- [x] Files section updated with changed files

### Phase 3: Ship

1. Run `/personal-workflow check` — verify all validation passes
   → should show PASS for template, lifecycle, traceability, structure badges
2. Run `/personal-workflow tree` — verify hierarchy and structural completeness
3. Verify TEST-SPEC alignment: do test cases cover all P0 acceptance criteria?
4. Ensure all child tasks have shipped
5. Run `/ship` — creates PR, bumps version, updates changelog (includes pre-landing code review)
6. Run `/land-and-deploy` — merges PR and verifies deployment

❌ If `/personal-workflow check` finds issues: fix findings, re-run until clean
❌ If CI fails: fix, push, re-run `/ship`

**Gates:**
- [x] `/personal-workflow check` — validation passed
- [x] `/personal-workflow tree` — structure verified
- [x] TEST-SPEC covers all P0 acceptance criteria
- [x] All children shipped (T000006 shipped in PRs #40 + #41)
- [x] `/ship` — PRs created (#40 always-on + gate; #41 on-demand)
- [x] `/land-and-deploy` — merged and deployed (v0.12.0 + v0.13.0)

## Acceptance Criteria

<!-- What "done" looks like for this story. Both surfacing modes (always-on
     loading + on-demand matching) ship in this single story since they share
     yml parsing, file enumeration, the per-repo opt-in gate, and the test
     fixture builder. The split into two stories was vertical-slicing
     bookkeeping; the impl is one PR. -->

### Always-on loading

- [x] Given `$_KNOWLEDGE_DIR` is a valid directory (from S000004), skill enumerates top-level subdirectories as categories — shipped via `list_categories()` in #40
- [x] For each category with `.knowledge.yml { surface: always }`: all nested `*.md` files are loaded into Claude's context (Claude Reads emitted paths)
- [x] Load order is deterministic: `LC_ALL=C` lex-sort of categories and md files
- [x] A category with no `.knowledge.yml`, or with `surface: on-demand`, contributes zero content via always-on

### On-demand matching

- [x] Categories with `surface: on-demand` emit triggers + category root under `## On-Demand Knowledge Candidates` — shipped in #41
- [x] Claude matches user's latest prompt (case-insensitive whole-word; quoted multi-word phrases at token boundaries)
- [x] Matched categories: Claude Reads every `*.md` under each match (recursive, same enumeration rules)
- [x] Multiple matches: content from all matched categories is loaded
- [x] Empty `triggers: []` never match; inert category until user adds triggers
- [x] `surface: always` never considered by on-demand matching logic

### Common gating + resilience

- [x] **Per-repo opt-in gate** (`.claude/knowledge-enabled`, regular file only; symlinks fail closed; helpful diagnostic if absent + always-on present) — Codex F2 finding, shipped in #40
- [x] Malformed `.knowledge.yml` → one-line stderr warning naming the file, skip the category, siblings continue, exit 0
- [x] `$_KNOWLEDGE_DIR` empty → no loading, no matching, no additional warning (S000004's warning already emitted)
- [x] `validate` output byte-identical with and without knowledge (zero regression)
- [x] **Bonus hardening beyond original AC:** log-injection sanitization on env-var display; 500-path / 100KB hard-fail cap; `AI_KNOWLEDGE_DISABLE` one-shot escape hatch; `knowledge-doctor` diagnostic; helpers-drift tripwire test

## Todos

<!-- Actionable items for this story. Implementation lives in T000006. -->

- [x] Decide injection mechanism — **Claude Reads listed paths** (keeps preamble small, uses native Read tool, pagination free)
- [x] Decide `.knowledge.yml` parser — **native bash + awk** (zero deps; supports `surface` + `triggers` flat keys; tolerates CRLF/BOM/comments/quotes)
- [x] Define malformed-file warning text — `[knowledge] malformed .knowledge.yml at <path> — skipping category.`
- [x] ~~Soft size cap at 50KB~~ — SUPERSEDED: **hard-fail at 500 paths / 100KB** (loud refusal over silent partial load, per dual-voice review)
- [x] Tokenize prompt for on-demand — **Claude does both tokenization + match** (bash can't see the prompt)
- [x] Diagnostic surfacing — yes, `[knowledge] matched: <cat> via <trigger>` per matched category (stderr)
- [x] "Prompt tokens" scope — **latest user message only** (prevents runaway loading from long conversation history)
- [x] Common-word triggers — **no skill-side filtering**; user's responsibility to pick specific triggers (documented in WORKFLOW.md trigger-authoring guidance)
- [x] Per-repo opt-in marker — **`.claude/knowledge-enabled`** (regular file only; symlinks fail closed; `.claude/` parent symlink also fails closed)
- [x] `scripts/test-helpers/knowledge.sh` with `build_knowledge_fixture()` — shipped in #40
- [x] Tier 1 smoke tests — structural greps for all sections, fixture layouts, instruction text
- [x] Tier 2 E2E tests — ~35 cases covering always-on, on-demand match/non-match/multi/case-variants/empty, malformed yml, opt-in gate + hardening, path cap, AI_KNOWLEDGE_DISABLE, yml edge cases, doctor
- [x] WORKFLOW.md updates — `## Knowledge Configuration` with quick-start + troubleshooting + escape hatches + schema + trigger-authoring + security + caps + doctor

## Log

<!-- Chronological entries with dates and commit SHAs. -->

- 2026-04-16: Created. Second vertical slice of F000004: always-on category loading. Blocked by S000004 (resolution). On-demand matching ships in S000006.
- 2026-04-17: Decomposed into tasks: T000005 (build fixtures), T000006 (Knowledge Loading block in SKILL.md + WORKFLOW.md schema docs, blocked by T000005), T000007 (Tier 1 + Tier 2 + regression tests, blocked by T000006).
- 2026-04-17: Converted to personal-workflow structure (3-phase lifecycle; simplified frontmatter with `parent: F000004`; story-level milestones.md dropped — now only at feature level).
- 2026-04-18: Added P0 Todo: per-repo opt-in gate (Codex outside-voice finding F2 via /plan-eng-review). S000004 resolves the env var globally; S000005 must gate on a repo-level marker before actually loading content, else users leak Company A knowledge into Company B / OSS repos.
- 2026-04-19: Fixture scope change. Rejected committing static fixtures under `skills/company-workflow/fixtures/` — conflates skill source with user-owned `$AI_KNOWLEDGE_DIR` (which is external to the skill by design). Revised to build a shared bash helper (`scripts/test-helpers/knowledge.sh`) that synthesizes fixtures in `mktemp -d` per test case, matching the T000003 pattern.
- 2026-04-19: Task consolidation. Collapsed T000005 (fixtures) + T000006 (impl) + T000007 (tests) → single T000006_implement_loading_block. Convention change per F000001/F000003 precedent (impl + test-helper + tests ship as one unit). Removes bookkeeping overhead for what will be a single ~200-line PR.
- 2026-04-19: **Story consolidation.** Merged former S000006 (on-demand matching) into this story. Renamed from `always-on-loading` to `knowledge-loading`. Rationale: both surfacing paths share the yml parser, file enumeration, per-repo opt-in gate, and fixture builder. T000009 (S000006's task) was already blocked on T000006 to extract a shared helper — that refactor lived inside the second slice, exposing the slice boundary as artificial. One PR is honest. Trade-off accepted: bigger review surface, lose option to ship always-on alone if on-demand stalls. Absorbs S000006's 8 AC + Todos + Journal into the sections above; S000006 dir + T000009 dir deleted.
- 2026-04-20: **c3 shipped.** On-Demand Matching implemented on branch `feat/s000005-c3-on-demand-matching`. Adds `parse_knowledge_triggers` helper + `## On-Demand Matching` SKILL.md section that enumerates on-demand categories with non-empty triggers and emits `## On-Demand Knowledge Candidates` block. Claude-facing matching rules specified in prose: case-insensitive whole-word for single-word triggers, phrase match at token boundaries for quoted multi-word triggers, scope pinned to latest user message, match log format `[knowledge] matched: <cat> via <trigger>`. knowledge-doctor updated to distinguish loadable (`loads=on-match (triggers: …)`) vs inert (`loads=no (empty triggers)`) on-demand categories. WORKFLOW.md updated: trigger-authoring guidance, removed "v1 deferred" language, updated security section. Skipped the 50KB on-demand byte cap (dual-voice review: "theater", no real protection). 25 new c3 test cases added to scripts/test.sh; c2 extraction bounds updated to new section layout (Loading now bounded at `## On-Demand Matching` not `## Diagnostic`). All tests pass.
- 2026-04-20: **PR #40 merged (v0.12.0, commit 5919369)** — c2 always-on loading + per-repo opt-in gate + knowledge-doctor.
- 2026-04-20: **PR #41 merged (v0.13.0, commit b27946f)** — c3 on-demand matching.
- 2026-04-21: Story closed — all 14 AC verified met. Tracker reconciled during F000004 closure audit.

## PRs

<!-- PR links with status (open/merged/closed). -->

- [#40](https://github.com/jcl2018/claude-skills-templates/pull/40) — merged 2026-04-20 (v0.12.0, commit 5919369). Always-on loading + per-repo opt-in gate + knowledge-doctor.
- [#41](https://github.com/jcl2018/claude-skills-templates/pull/41) — merged 2026-04-20 (v0.13.0, commit b27946f). On-demand matching.

## Files

<!-- Affected file paths. -->

- skills/company-workflow/SKILL.md (modified — `## Knowledge Helpers` + `## Knowledge Loading` + `## On-Demand Matching` + `## Diagnostic: knowledge-doctor` sections; per-repo opt-in gate; symlink hardening; 500-path / 100KB hard-fail cap)
- skills/company-workflow/WORKFLOW.md (modified — `## Knowledge Configuration` expanded with quick-start + troubleshooting + escape hatches + schema + trigger-authoring + security + caps + doctor docs)
- scripts/test-helpers/knowledge.sh (new, 96 lines — shared fixture builder)
- scripts/test.sh (modified — ~35 F000004 test cases across tier-1 structural + tier-2 behavioral; full suite passes)

## Insights

<!-- Non-obvious findings worth remembering. -->

- The split between always-on loading and on-demand matching is conceptual, not architectural: both walk the same category tree, both parse the same `.knowledge.yml`, both honor the same opt-in gate. The only real difference is whether bash decides to load (always) or Claude decides (on-demand match). One shared helper covers both.

## Journal

<!-- Structured entries from the work-track journal command. Each entry has a type
     (decision, finding, blocker) and a Summary field. -->

### 2026-04-19 — decision: consolidate S000005 + S000006 into one story

**Summary:** S000006 (on-demand matching) absorbed into S000005 (always-on loading); story renamed to `knowledge-loading`.

**Rationale:**
- Both surfacing modes share four things: the `.knowledge.yml` parser, the category-and-md-file enumeration, the per-repo opt-in gate, and the test fixture builder.
- T000009's first task was already "extract shared helper from T000006's Loading block" — meaning the refactor that should have lived in a shared layer was being performed inside the second slice. The slice boundary was artificial.
- Task consolidation already happened on 2026-04-19 (8 → 3 tasks per F000001/F000003 precedent). Story consolidation is the same move one level up.
- Single-PR shipping matches the rest of F000004 (S000004 shipped in PR #38 as one unit).

**Trade-offs accepted:**
- Bigger PR review surface (~400 lines bash + tests vs. two ~200-line PRs).
- Cannot ship always-on alone if on-demand stalls. Mitigation: the implementation can be sequenced within T000006 (always-on first, then on-demand) so always-on is committable independently if needed; only the PR boundary collapses.

**Consequences:**
- T000009 (matching block task) absorbed into T000006 (renamed `implement-loading-and-matching`).
- F000004 now has 2 stories instead of 3.
- Follow-up TODO "Port to /personal-workflow" updated to block on this merged S000005 instead of the deleted S000006.
