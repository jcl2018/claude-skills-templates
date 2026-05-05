---
name: "implement-loading-and-matching"
type: task
id: "T000006"
status: shipped
created: "2026-04-16"
updated: "2026-04-21"
parent: "S000004"
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
- [x] Core changes committed (shipped in PRs #40 + #41)
- [x] Todos section reflects remaining work (no stale items)
- [x] Files section updated with changed files

### Phase 3: Ship

1. Run `/personal-workflow check` — verify no regressions
2. Verify test-plan: all test scenarios passing
3. Run `/ship` — creates PR, bumps version, updates changelog (includes pre-landing code review)
4. Run `/land-and-deploy` — merges PR and verifies deployment

❌ If tests fail: fix, re-run
❌ If CI fails: fix, push, re-run `/ship`

**Gates:**
- [x] `/personal-workflow check` — validation passed
- [x] Test-plan verified (~35 test cases across tier-1 structural + tier-2 behavioral; full suite passes)
- [x] `/ship` — PRs created (#40 always-on + opt-in gate; #41 on-demand matching)
- [x] `/land-and-deploy` — merged and deployed (v0.12.0 + v0.13.0)

## Todos

<!-- Implementation + test-helper + tests, shipped together. Covers BOTH always-on
     loading and on-demand matching paths in one PR. Implementation order matters:
     shared helpers first (factor once, use twice), always-on second (simpler;
     deterministic emit), on-demand third (depends on always-on's enumerator). -->

### Test helper (materializes fixtures in `mktemp -d`; no committed fixtures under `skills/`)

- [x] Create `scripts/test-helpers/knowledge.sh` with `build_knowledge_fixture()` function (shipped in #40, 96 lines)
- [x] Helper accepts root path + category specs (e.g. `"coding:always"`, `'runbooks:on-demand:pricing,"pricing engine"'`)
- [x] Support every category state downstream tests need (always-on nested, on-demand with triggers, empty triggers, missing yml, malformed yml)
- [x] Each md file gets a unique canary string
- [x] Helper documents spec grammar in header comment
- [x] Helper prints fixture root on stdout; idempotent on repeat calls

### Shared helpers (SKILL.md `## Knowledge Helpers` section — used by both Loading and Matching)

- [x] Add `## Knowledge Helpers` section to SKILL.md after `## Knowledge Resolution` (shipped in #40)
- [x] `parse_knowledge_yml(path)` — minimal bash parser (awk-based, tolerates CRLF/BOM/comments/quotes)
- [x] `list_categories(root)` — top-level subdirs, skip hidden, lex-sorted under `LC_ALL=C`
- [x] `list_md_files(category)` — recursive `*.md`, lex-sorted
- [x] `parse_knowledge_triggers(path)` — added in #41 for on-demand matching (not in original plan; emerged from implementation)
- [x] Document helper contract in WORKFLOW.md + SKILL.md (contract table in `## Knowledge Helpers`)

### Always-on loading block (SKILL.md + WORKFLOW.md)

- [x] Add `## Knowledge Loading` section to SKILL.md (shipped in #40)
- [x] Enumerate always-on categories via shared helpers
- [x] Emit absolute paths under `## Always-On Knowledge` (lex-sorted)
- [x] Claude-facing instruction: "Read each of them before answering the user's request"
- [x] Malformed yml handling: one warning line + skip category + siblings continue
- [x] Missing `.knowledge.yml`: silent skip
- [ ] ~~Soft-warn at 50 KB~~ — SUPERSEDED: shipped as 500-path / 100KB **hard-fail** cap instead (loud refusal > silent partial load; per dual-voice review)
- [x] Update WORKFLOW.md: `.knowledge.yml` schema + worked example + malformed behavior + parser subset

### On-demand matching block (SKILL.md + WORKFLOW.md)

- [x] Add `## On-Demand Matching` section to SKILL.md (shipped in #41)
- [x] Reuse shared helpers; enumerate on-demand categories with non-empty triggers
- [x] Emit `## On-Demand Knowledge Candidates` block with category root + triggers + md paths
- [x] Claude-facing instruction block: tokenization + whole-word single-token + phrase-at-boundary for multi-word
- [x] Match log format: `[knowledge] matched: <cat> via <trigger>`
- [x] Update WORKFLOW.md: on-demand worked example + trigger-authoring + security callout
- [x] Document "latest user message only, not prior turns" scope in SKILL.md

### Per-repo opt-in gate (cross-cutting, Codex outside-voice finding F2)

- [x] Marker filename: `.claude/knowledge-enabled` (regular file only; symlinks fail closed)
- [x] Gate check at top of both loading + matching sections
- [x] WORKFLOW.md documents rationale (cross-context contamination prevention)
- [x] Test: marker absent → no emission (plus helpful diagnostic when always-on categories exist)

### Tests (scripts/test.sh)

- [x] Tier 1 structural greps (SKILL.md sections, fixture layouts, instruction text)
- [x] Tier 2 behavioral tests (~35 cases): always-on emission, on-demand empty-triggers, missing/malformed yml, env-unset, marker absent/symlink/dir hardening, AI_KNOWLEDGE_DISABLE, path cap, yml edge cases (CRLF/BOM/quoted/comment), path with spaces, invalid env, knowledge-doctor
- [x] Regression assertion: existing validate output byte-identical with/without knowledge configured
- [x] Extract-and-exec pattern reused from T000003
- [x] Wired into `./scripts/test.sh`
- [x] Add-new-trigger documentation implicit in helper spec + worked examples

## Log

- 2026-04-16: Created. Implements SKILL.md Knowledge Loading section + WORKFLOW.md schema docs for S000005.
- 2026-04-17: Converted to personal-workflow structure (3-phase lifecycle; simplified frontmatter; PR-DESCRIPTION.md dropped).
- 2026-04-18: /plan-eng-review + Codex outside-voice surfaced per-repo opt-in gate (F2) — critical security control to prevent cross-context contamination. Added to Todos as P0.
- 2026-04-19: Scope change. Original plan committed a static fixture tree at `skills/company-workflow/fixtures/valid-knowledge-dir/`. Rejected — conflates skill source with the user-owned knowledge dir (`$AI_KNOWLEDGE_DIR` is supposed to live outside the skill). Revised to a shared bash helper (`scripts/test-helpers/knowledge.sh`) that synthesizes fixtures in `mktemp -d` per test case, matching the T000003 pattern (`scripts/test.sh:509-514`).
- 2026-04-19: Absorbed former T000005_build_fixtures and T000007_tests tasks into this task. Convention change per F000001/F000003 precedent (impl + test-helper + tests ship as one unit; separate tasks were bookkeeping overhead for a single-PR slice).
- 2026-04-19: **Absorbed T000009_implement_matching_block into this task.** Renamed from `implement-loading-block` → `implement-loading-and-matching`. Parent S000005 was merged with former S000006 (see S000005 TRACKER Journal 2026-04-19). The on-demand matching impl was already going to consume a helper extracted from this task's loading block — that boundary was a refactor inside the next slice, not a real PR boundary. Now: shared `## Knowledge Helpers` section emerges naturally; both `## Knowledge Loading` and `## On-Demand Matching` consume it; per-repo opt-in gate covers both. Estimated PR size: ~400 lines bash + tests (vs. two ~200-line PRs before).
- 2026-04-20: **c2 shipped (PR #40, v0.12.0, commit 5919369).** `## Knowledge Helpers` + `## Knowledge Loading` + per-repo opt-in gate (`.claude/knowledge-enabled`) + `knowledge-doctor` diagnostic. Hardening added beyond original plan: log-injection sanitization (strip control chars, 200-char truncate); symlink fails closed on both `.claude/` parent and marker file; 500-path / 100KB **hard-fail** cap (replaces original 50KB soft-warn — loud refusal > silent partial load).
- 2026-04-20: **c3 shipped (PR #41, v0.13.0, commit b27946f).** `## On-Demand Matching` + `parse_knowledge_triggers` helper + Claude-facing match rules (case-insensitive whole-word, quoted-phrase at token boundaries, scope pinned to latest user message, log format `[knowledge] matched: <cat> via <trigger>`). knowledge-doctor updated to distinguish loadable (`loads=on-match`) vs inert (`loads=no (empty triggers)`). WORKFLOW.md: trigger-authoring guidance + security callout. Skipped the on-demand byte cap (dual-voice: "theater"). 25 new c3 test cases; all pass.

## PRs

- [#40](https://github.com/jcl2018/claude-skills-templates/pull/40) — merged 2026-04-20 (v0.12.0, commit 5919369). Always-on loading + per-repo opt-in gate + knowledge-doctor.
- [#41](https://github.com/jcl2018/claude-skills-templates/pull/41) — merged 2026-04-20 (v0.13.0, commit b27946f). On-demand matching.

## Files

- skills/company-workflow/SKILL.md (modified — `## Knowledge Helpers` + `## Knowledge Loading` + `## On-Demand Matching` + `## Diagnostic: knowledge-doctor` sections; per-repo opt-in gate; symlink hardening; 500-path / 100KB hard-fail cap)
- skills/company-workflow/WORKFLOW.md (modified — `## Knowledge Configuration` expanded with quick-start, troubleshooting, escape hatches, schema, trigger-authoring, security, caps, doctor docs)
- scripts/test-helpers/knowledge.sh (new, 96 lines — shared fixture builder)
- scripts/test.sh (modified — ~35 knowledge test cases across tier-1 structural + tier-2 behavioral; full suite passes)

## Insights

<!-- Non-obvious findings worth remembering. -->

- The shared `## Knowledge Helpers` section is the load-bearing design move. Once the yml parser, category enumerator, and md file lister live in one place, the Always-On Loading and On-Demand Matching sections become thin shells — each ~20 lines of "iterate over categories, filter by surface, emit appropriate block." The story consolidation works because this helper layer is real, not invented for the merge.

## Journal
