---
name: "implement-loading-and-matching"
type: task
id: "T000006"
status: active
created: "2026-04-16"
updated: "2026-04-19"
parent: "S000005"
repo: "claude-skills-templates"
branch: "claude/heuristic-almeida-2f246d"
blocked_by: ""
---

## Lifecycle

### Phase 1: Track

1. Read parent tracker to understand scope and acceptance criteria
2. Create working branch: `git checkout -b feat/{slug}`
   (use parent's branch if the task ships in the same PR; create a new branch if it warrants its own PR)
3. Scaffold required docs:
   - `test-plan.md` (test scenarios for this task) — from `templates/doc-test-plan.md`
4. Populate Files section with expected changed files
5. Write initial Todos from parent's acceptance criteria

**Gates:**
- [x] Parent scope read (parent tracker reviewed)
- [x] Working branch created (`branch` field populated)
- [x] Required docs scaffolded (test-plan)
- [x] Files section populated

### Phase 2: Implement

1. Work from `/office-hours` design doc + parent's acceptance criteria + your Todos
   → design doc at `~/.gstack/projects/{slug}/`
2. Commit changes incrementally with descriptive messages
3. Update Todos section — check off completed items, add discoveries
4. Update Files section with actual changed files

**Gates:**
- [ ] Core changes committed (>=1 commit SHA in Log)
- [ ] Todos section reflects remaining work (no stale items)
- [ ] Files section updated with changed files

### Phase 3: Ship

1. Run `/personal-workflow check` — verify no regressions
2. Verify test-plan: all test scenarios passing
3. Run `/ship` — creates PR, bumps version, updates changelog (includes pre-landing code review)
4. Run `/land-and-deploy` — merges PR and verifies deployment

❌ If tests fail: fix, re-run
❌ If CI fails: fix, push, re-run `/ship`

**Gates:**
- [ ] `/personal-workflow check` — validation passed
- [ ] Test-plan verified (all scenarios passing)
- [ ] `/ship` — PR created
- [ ] `/land-and-deploy` — merged and deployed

## Todos

<!-- Implementation + test-helper + tests, shipped together. Covers BOTH always-on
     loading and on-demand matching paths in one PR. Implementation order matters:
     shared helpers first (factor once, use twice), always-on second (simpler;
     deterministic emit), on-demand third (depends on always-on's enumerator). -->

### Test helper (materializes fixtures in `mktemp -d`; no committed fixtures under `skills/`)

- [ ] Create `scripts/test-helpers/knowledge.sh` with `build_knowledge_fixture()` function
- [ ] Helper accepts root path + category specs (e.g. `"coding:always"`, `'runbooks:on-demand:pricing,"pricing engine"'`) and materializes the tree
- [ ] Support every category state downstream tests need: always-on (nested md allowed), on-demand with triggers, on-demand with empty triggers, no `.knowledge.yml`, malformed `.knowledge.yml`
- [ ] Each md file gets a unique canary string (format `CANARY_<category>_<file>`) for unambiguous assertions
- [ ] Helper documents spec grammar in header comment
- [ ] Helper prints fixture root on stdout; idempotent on repeat calls within a test run

### Shared helpers (SKILL.md `## Knowledge Helpers` section — used by both Loading and Matching)

- [ ] Add `## Knowledge Helpers` section to SKILL.md after `## Knowledge Resolution`
- [ ] `parse_knowledge_yml(path)` — minimal bash parser for the supported subset (`surface`, `triggers` flat keys; list via `[a, b]` or `- a\n- b`); returns `surface,triggers_csv` or empty on missing/malformed
- [ ] `list_categories(root)` — top-level subdirs of `$_KNOWLEDGE_DIR`, skip hidden, lex-sorted
- [ ] `list_md_files(category)` — recursive `*.md` discovery, lex-sorted by relative path
- [ ] Document helper contract in WORKFLOW.md so refactors don't drift from the docs

### Always-on loading block (SKILL.md + WORKFLOW.md)

- [ ] Add `## Knowledge Loading` section to SKILL.md after `## Knowledge Helpers`
- [ ] Use `list_categories` + `parse_knowledge_yml` + `list_md_files` to enumerate always-on categories
- [ ] For each category with `surface: always`: emit absolute paths under `## Always-On Knowledge` (lex-sorted)
- [ ] Add Claude-facing instruction block: "Before answering, Read every path listed under Always-On Knowledge"
- [ ] Handle malformed yml: one warning line naming the file + reason; skip the category; continue
- [ ] Treat missing `.knowledge.yml` as on-demand + empty-triggers (silent, no warning)
- [ ] Soft-warn when total always-on bytes exceed 50 KB
- [ ] Update WORKFLOW.md: `.knowledge.yml` schema (`surface`, `triggers`) with worked example; malformed-file behavior; supported bash-parser subset (flat keys only, list via `[a, b]` or `- a\n- b`)

### On-demand matching block (SKILL.md + WORKFLOW.md)

- [ ] Add `## On-Demand Matching` section to SKILL.md after `## Knowledge Loading`
- [ ] Reuse the shared helpers to enumerate categories with `surface: on-demand` and non-empty triggers
- [ ] Emit `## On-Demand Knowledge Candidates` block: per-category entries with category root + triggers list + markdown file paths
- [ ] Add Claude-facing instruction block specifying: tokenization rule (whitespace + punctuation; case-fold), single-word trigger = whole-word match on prompt tokens, multi-word trigger = case-insensitive phrase at token boundaries, match on any trigger, load all matched categories
- [ ] Specify the match log format: `[knowledge] matched: <cat> via <trigger>; <cat2> via <trigger>` — one line, stderr
- [ ] Update WORKFLOW.md: on-demand worked example, trigger-authoring guidance, security callout (knowledge file content is trusted by Claude via Read)
- [ ] Document the "latest user message only, not prior turns" scope decision in SKILL.md

### Per-repo opt-in gate (cross-cutting, Codex outside-voice finding F2)

- [ ] Decide marker filename and placement (e.g. `.claude/knowledge-enabled` in repo root) — design call up front, applies to BOTH loading paths
- [ ] Add gate check at the top of the `## Knowledge Loading` and `## On-Demand Matching` sections: if marker absent, emit nothing for both paths
- [ ] Document marker requirement in WORKFLOW.md (rationale: prevents cross-context contamination)
- [ ] Test: marker absent → both `## Always-On Knowledge` and `## On-Demand Knowledge Candidates` sections absent (per E13/E14)

### Tests (scripts/test.sh)

- [ ] Implement S000005 TEST-SPEC Tier 1 checks S1–S17 as shell assertions in `scripts/test.sh`
- [ ] Implement S000005 TEST-SPEC Tier 2 scenarios E1–E14 (canary-based: always-on canaries reach Claude; on-demand match/non-match/multi-match/case-variants/empty-triggers; malformed-yml resilience; env-unset silence; opt-in gate behavior)
- [ ] Add regression diff: validate output on `fixtures/valid-feature-dir/` with env=empty dir vs. env=valid-knowledge-dir, assert stdout byte-identical
- [ ] Extend E2E runner to inject canary strings and verify Claude's replies quote them (reuse the extract-and-exec pattern from T000003's tests)
- [ ] Wire new tests into `./scripts/test.sh` so pre-commit + CI runs them
- [ ] Document how to add a new E2E trigger scenario for future categories (lowers maintenance burden)

## Log

- 2026-04-16: Created. Implements SKILL.md Knowledge Loading section + WORKFLOW.md schema docs for S000005.
- 2026-04-17: Converted to personal-workflow structure (3-phase lifecycle; simplified frontmatter; PR-DESCRIPTION.md dropped).
- 2026-04-18: /plan-eng-review + Codex outside-voice surfaced per-repo opt-in gate (F2) — critical security control to prevent cross-context contamination. Added to Todos as P0.
- 2026-04-19: Scope change. Original plan committed a static fixture tree at `skills/company-workflow/fixtures/valid-knowledge-dir/`. Rejected — conflates skill source with the user-owned knowledge dir (`$AI_KNOWLEDGE_DIR` is supposed to live outside the skill). Revised to a shared bash helper (`scripts/test-helpers/knowledge.sh`) that synthesizes fixtures in `mktemp -d` per test case, matching the T000003 pattern (`scripts/test.sh:509-514`).
- 2026-04-19: Absorbed former T000005_build_fixtures and T000007_tests tasks into this task. Convention change per F000001/F000003 precedent (impl + test-helper + tests ship as one unit; separate tasks were bookkeeping overhead for a single-PR slice).
- 2026-04-19: **Absorbed T000009_implement_matching_block into this task.** Renamed from `implement-loading-block` → `implement-loading-and-matching`. Parent S000005 was merged with former S000006 (see S000005 TRACKER Journal 2026-04-19). The on-demand matching impl was already going to consume a helper extracted from this task's loading block — that boundary was a refactor inside the next slice, not a real PR boundary. Now: shared `## Knowledge Helpers` section emerges naturally; both `## Knowledge Loading` and `## On-Demand Matching` consume it; per-repo opt-in gate covers both. Estimated PR size: ~400 lines bash + tests (vs. two ~200-line PRs before).

## PRs

## Files

- skills/company-workflow/SKILL.md (modified — `## Knowledge Helpers` + `## Knowledge Loading` + `## On-Demand Matching` sections + per-repo opt-in gate)
- skills/company-workflow/WORKFLOW.md (modified — `.knowledge.yml` schema + always-on + on-demand worked examples + trigger-authoring guidance + security callout + opt-in marker docs + helper contract)
- scripts/test-helpers/knowledge.sh (new — shared fixture builder used by both loading paths' tests)
- scripts/test.sh (modified — Tier 1 (S1–S17) + Tier 2 (E1–E14) + regression assertions covering both loading paths and the opt-in gate)

## Insights

<!-- Non-obvious findings worth remembering. -->

- The shared `## Knowledge Helpers` section is the load-bearing design move. Once the yml parser, category enumerator, and md file lister live in one place, the Always-On Loading and On-Demand Matching sections become thin shells — each ~20 lines of "iterate over categories, filter by surface, emit appropriate block." The story consolidation works because this helper layer is real, not invented for the merge.

## Journal
