---
name: "knowledge-loading"
type: user-story
id: "S000005"
status: active
created: "2026-04-16"
updated: "2026-04-19"
parent: "F000004"
repo: "claude-skills-templates"
branch: "claude/heuristic-almeida-2f246d"
blocked_by: "S000004"
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
- [ ] All child tasks have entered Phase 2+
- [ ] Acceptance criteria verified met
- [ ] Todos section reflects remaining work (no stale items)
- [ ] Files section updated with changed files

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
- [ ] `/personal-workflow check` — validation passed
- [ ] `/personal-workflow tree` — structure verified
- [ ] TEST-SPEC covers all P0 acceptance criteria
- [ ] All children shipped
- [ ] `/ship` — PR created
- [ ] `/land-and-deploy` — merged and deployed

## Acceptance Criteria

<!-- What "done" looks like for this story. Both surfacing modes (always-on
     loading + on-demand matching) ship in this single story since they share
     yml parsing, file enumeration, the per-repo opt-in gate, and the test
     fixture builder. The split into two stories was vertical-slicing
     bookkeeping; the impl is one PR. -->

### Always-on loading

- [ ] Given `$_KNOWLEDGE_DIR` is a valid directory (from S000004), skill enumerates top-level subdirectories as categories
- [ ] For each category with `.knowledge.yml { surface: always }`: all nested `*.md` files under that category are loaded into Claude's context (via Claude Read on emitted paths)
- [ ] Load order is deterministic: categories sorted by name, files within each category sorted by relative path
- [ ] A category with no `.knowledge.yml`, or with `surface: on-demand`, contributes zero content via the always-on path

### On-demand matching

- [ ] For each category with `.knowledge.yml { surface: on-demand }`, the skill emits its declared `triggers` list and category root path under a `## On-Demand Knowledge Candidates` block
- [ ] Claude matches the user's latest prompt against every on-demand category's triggers (case-insensitive whole-word match on prompt tokens; quoted multi-word trigger phrases matched as a unit at token boundaries)
- [ ] When one or more categories match, Claude Reads every `*.md` file under each matched category (recursive, same enumeration rules as always-on)
- [ ] When multiple categories match, content from all matched categories is loaded
- [ ] Categories with empty `triggers: []` never match; they remain dark until the user adds triggers
- [ ] A `surface: always` category is never considered by the on-demand matching logic (it's already loaded)

### Common gating + resilience

- [ ] **Per-repo opt-in gate** (Codex outside-voice finding F2, 2026-04-18): a marker file (e.g. `.claude/knowledge-enabled`) in the repo root is required before activating either loading path. Without the marker, `$_KNOWLEDGE_DIR` is resolved (S000004) but no content loads. Prevents cross-context contamination where a user with a global env var pointed at Company A's knowledge folder auto-injects Company A guidance while working in Company B or OSS repos
- [ ] A category with malformed `.knowledge.yml` triggers a one-line warning naming the file and skip; sibling categories continue loading; exit 0
- [ ] When `$_KNOWLEDGE_DIR` is empty (S000004 emitted the unset warning): nothing is loaded, no matching, no additional warning
- [ ] Existing `validate` command produces byte-identical output with and without any configured knowledge categories (zero regression)

## Todos

<!-- Actionable items for this story. Implementation lives in T000006. -->

- [ ] Decide exact injection mechanism: how does loaded content reach Claude's context? Options: skill preamble inlines via `cat`, skill preamble lists paths for Claude to read with the Read tool, or skill emits a reserved `## Knowledge Context` section. (Leaning: Claude Reads the listed paths — keeps preamble small, uses Claude's native tool, lets Claude paginate huge files)
- [ ] Decide `.knowledge.yml` parser: native bash + `grep` (tiny and no deps) for the supported subset (`surface`, `triggers` flat keys), or invoke `yq` if available (clean but adds a dependency)
- [ ] Define malformed-file warning text
- [ ] Add a soft size cap for total always-on bytes and decide behavior when exceeded (warn? truncate? hard fail?) — leaning: soft warn at 50KB
- [ ] Decide who tokenizes the prompt for on-demand matching: skill emits a "matching spec" and Claude does the match, or skill emits triggers and Claude handles both tokenization and match. (Leaning: Claude does both — bash can't see the prompt)
- [ ] Decide diagnostic surfacing: should Claude log which triggers matched, to help users tune? (Proposal: yes, one line per matched category, format `[knowledge] matched: <cat> via <trigger>`)
- [ ] Disambiguate "prompt tokens" — does that include prior turns in the conversation or only the latest user message? (Proposal: only the latest user message to avoid runaway loading)
- [ ] Decide behavior when a trigger is a single very-common word like "the" or "code". (Proposal: no skill-side filtering; user's responsibility to pick specific triggers)
- [ ] Decide marker filename and placement for the per-repo opt-in gate (`.claude/knowledge-enabled` is the leading candidate)
- [ ] Build `scripts/test-helpers/knowledge.sh` with `build_knowledge_fixture()` — synthesizes knowledge dirs in `mktemp -d` per test case. No fixtures committed under `skills/company-workflow/` (the knowledge dir is user-owned, external by design)
- [ ] Write Tier 1 smoke tests for both loading paths (structural: sections, fixture layouts, instruction text)
- [ ] Write Tier 2 E2E tests covering both paths (always-on canary visibility; on-demand match/non-match/multi-match/case-variants/empty-triggers; malformed-yml resilience; opt-in gate behavior)
- [ ] Update WORKFLOW.md with `.knowledge.yml` schema, on-demand worked example, trigger-authoring guidance, security callout (knowledge file content is trusted by Claude via Read), opt-in marker docs

## Log

<!-- Chronological entries with dates and commit SHAs. -->

- 2026-04-16: Created. Second vertical slice of F000004: always-on category loading. Blocked by S000004 (resolution). On-demand matching ships in S000006.
- 2026-04-17: Decomposed into tasks: T000005 (build fixtures), T000006 (Knowledge Loading block in SKILL.md + WORKFLOW.md schema docs, blocked by T000005), T000007 (Tier 1 + Tier 2 + regression tests, blocked by T000006).
- 2026-04-17: Converted to personal-workflow structure (3-phase lifecycle; simplified frontmatter with `parent: F000004`; story-level milestones.md dropped — now only at feature level).
- 2026-04-18: Added P0 Todo: per-repo opt-in gate (Codex outside-voice finding F2 via /plan-eng-review). S000004 resolves the env var globally; S000005 must gate on a repo-level marker before actually loading content, else users leak Company A knowledge into Company B / OSS repos.
- 2026-04-19: Fixture scope change. Rejected committing static fixtures under `skills/company-workflow/fixtures/` — conflates skill source with user-owned `$AI_KNOWLEDGE_DIR` (which is external to the skill by design). Revised to build a shared bash helper (`scripts/test-helpers/knowledge.sh`) that synthesizes fixtures in `mktemp -d` per test case, matching the T000003 pattern.
- 2026-04-19: Task consolidation. Collapsed T000005 (fixtures) + T000006 (impl) + T000007 (tests) → single T000006_implement_loading_block. Convention change per F000001/F000003 precedent (impl + test-helper + tests ship as one unit). Removes bookkeeping overhead for what will be a single ~200-line PR.
- 2026-04-19: **Story consolidation.** Merged former S000006 (on-demand matching) into this story. Renamed from `always-on-loading` to `knowledge-loading`. Rationale: both surfacing paths share the yml parser, file enumeration, per-repo opt-in gate, and fixture builder. T000009 (S000006's task) was already blocked on T000006 to extract a shared helper — that refactor lived inside the second slice, exposing the slice boundary as artificial. One PR is honest. Trade-off accepted: bigger review surface, lose option to ship always-on alone if on-demand stalls. Absorbs S000006's 8 AC + Todos + Journal into the sections above; S000006 dir + T000009 dir deleted.

## PRs

<!-- PR links with status (open/merged/closed). -->

## Files

<!-- Affected file paths. -->

- skills/company-workflow/SKILL.md (to be modified — `## Knowledge Loading` + `## On-Demand Matching` sections + Claude-facing instructions + per-repo opt-in gate)
- skills/company-workflow/WORKFLOW.md (to be modified — `.knowledge.yml` schema + always-on + on-demand worked examples + trigger-authoring guidance + security callout + opt-in marker docs)
- scripts/test-helpers/knowledge.sh (to be created — shared fixture builder used by both loading paths' tests)
- scripts/test.sh (to be modified — Tier 1 + Tier 2 + regression assertions for both paths)

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
