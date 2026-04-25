---
type: architecture
parent: S000004
feature: F000003_company_workflow
title: "knowledge-integration — Architecture"
version: 3
status: Draft
date: 2026-04-25
author: chjiang
prd: PRD.md
reviewers: []
---

## Overview

Three preamble sections in `skills/company-workflow/SKILL.md` form the knowledge integration pipeline:

1. **`## Knowledge Resolution`** — resolves `$AI_KNOWLEDGE_DIR` to a skill-internal `$_KNOWLEDGE_DIR` and emits warnings for unset / invalid paths.
2. **`## Knowledge Loading`** (always-on) — for each category with `surface: always`, emits absolute paths under `## Always-On Knowledge`. Claude is instructed to Read every path before answering.
3. **`## On-Demand Matching`** — for each category with `surface: on-demand` and non-empty triggers, emits a candidates block (root + triggers + paths) under `## On-Demand Knowledge Candidates`. Claude tokenizes the latest user message and Reads paths from any matched category.

A shared `## Knowledge Helpers` block (and the canonical `bin/knowledge-helpers.sh` since PR #47) provides one yml parser + one category enumerator + one md-file lister. This keeps the bash logic in one place — a fix lands once, not three times.

The skill stays shell-local (no bash-side file concatenation, no prompt-length blowup in the preamble) while ensuring relevant content is factored into Claude's reasoning every turn.

## Architecture

```
┌─────────────────────────────────────────────────────────────────────────┐
│  Preamble chain                                                          │
│                                                                          │
│   ┌───────────────────────────────┐                                     │
│   │  1. Knowledge Resolution       │                                     │
│   │     resolve $AI_KNOWLEDGE_DIR  │                                     │
│   │     - unset/empty → warn, exit 0, $_KNOWLEDGE_DIR empty             │
│   │     - invalid path → warn, exit 0, $_KNOWLEDGE_DIR empty            │
│   │     - valid → $_KNOWLEDGE_DIR = resolved path                       │
│   └────────────────┬──────────────┘                                     │
│                    │                                                     │
│                    ▼                                                     │
│   ┌───────────────────────────────┐                                     │
│   │  Knowledge Helpers (shared)    │                                     │
│   │  source bin/knowledge-helpers.sh                                    │
│   │  - parse_knowledge_yml(path)   │ → returns "surface,triggers"       │
│   │  - parse_knowledge_triggers    │ → returns trigger list            │
│   │  - list_categories(root)       │ → top-level subdirs                │
│   │  - list_md_files(category)     │ → recursive, lex-sorted            │
│   └────────────────┬──────────────┘                                     │
│                    │                                                     │
│       ┌────────────┴────────────┐                                       │
│       ▼                         ▼                                       │
│  ┌─────────────┐        ┌────────────────────┐                          │
│  │ 2. Knowledge│        │ 3. On-Demand       │                          │
│  │    Loading  │        │    Matching        │                          │
│  │ (always-on; │        │ (bash + Claude)    │                          │
│  │  bash)      │        │                    │                          │
│  └─────┬───────┘        └─────┬──────────────┘                          │
│        │                      │                                          │
│        ▼                      ▼                                          │
│  emit `## Always-On     emit `## On-Demand                              │
│  Knowledge` block       Knowledge Candidates` block                     │
│  (absolute paths,       (per category: root + triggers + file paths)    │
│  lex-sorted)                                                            │
│        │                      │                                          │
│        ▼                      ▼                                          │
│  Claude: Read each      Claude: tokenize latest user message,           │
│  path before            for each candidate check triggers,              │
│  answering              Read all files if any trigger matches.          │
│                         Log `[knowledge] matched: <cat> via <trig>`     │
│                         on stderr.                                       │
└─────────────────────────────────────────────────────────────────────────┘

Match semantics (on-demand):
- Tokenize prompt: split on whitespace + punctuation
- For each trigger:
   * single word: case-insensitive token match
   * multi-word phrase: case-insensitive substring on the prompt AT TOKEN BOUNDARIES
- A category matches if ANY trigger matches
- Empty triggers list → category never matches
- `surface: always` categories are never considered (already loaded)
```

### Components Affected

| Component | Repo | Change Type | Description |
|-----------|------|------------|-------------|
| skills/company-workflow/SKILL.md | claude-skills-templates | Modified | `## Knowledge Resolution` (Layer 1) + `## Knowledge Helpers` (shared bash) + `## Knowledge Loading` (Layer 2) + `## On-Demand Matching` (Layer 3) + `## Diagnostic: knowledge-doctor` sections |
| skills/company-workflow/WORKFLOW.md | claude-skills-templates | Modified | Document `.knowledge.yml` schema, supported bash-parser subset, on-demand worked example, trigger-authoring guidance, security callout, escape hatches |
| skills/company-workflow/bin/knowledge-helpers.sh | claude-skills-templates | New (PR #47) | Canonical helper functions sourced by every `## Knowledge ...` block via the same 2-level fallback chain as Path Resolution |
| scripts/test-helpers/knowledge.sh | claude-skills-templates | New | Shared fixture builder: `build_knowledge_fixture()` synthesizes knowledge dirs in `mktemp -d` per test case. Supports always-on + on-demand specs |
| scripts/test.sh | claude-skills-templates | Modified | Tier 1 smoke + Tier 2 extract-and-exec + canary-based E2E + regression assertions, covering all three layers |

### Data Flow

1. **Layer 1**: read `$AI_KNOWLEDGE_DIR`. If unset / empty / invalid → warn on stderr, set `$_KNOWLEDGE_DIR=""`. Else `$_KNOWLEDGE_DIR=<resolved path>`.
2. If `$_KNOWLEDGE_DIR` is empty, emit nothing for Layers 2 + 3 and stop.
3. `list_categories "$_KNOWLEDGE_DIR"` → top-level subdir list (skip hidden, skip non-dirs).
4. For each category: `parse_knowledge_yml "$category/.knowledge.yml"` (minimal bash parser).
   - missing → skip (treat as on-demand w/ empty triggers; silent)
   - malformed → warn (one line naming the file) + skip
   - `surface: always` → add to always-on list
   - `surface: on-demand` → add to on-demand list (with triggers)
5. **Layer 2 emit**: for each always-on category, `list_md_files` → emit absolute paths under `## Always-On Knowledge`. Claude instruction: Read every listed path before answering.
6. **Layer 3 emit**: for each on-demand category with non-empty triggers, emit a candidates block:
   ```
   category: <absolute path>
   triggers: [<trigger1>, <trigger2>, ...]
   files:
     - <absolute path>
     - <absolute path>
   ```
   Claude instruction: tokenize latest user message; for each entry that matches, Read every listed file; log `[knowledge] matched: <cat> via <trigger>` on stderr.

## API Changes

### New APIs

| API | Signature | Description |
|-----|-----------|-------------|
| `$AI_KNOWLEDGE_DIR` env var | shell env var | User-supplied path to the knowledge folder root. Resolved per invocation |
| `## Always-On Knowledge` section | plain-text list of absolute paths | Contract between the skill's bash preamble and Claude's loading step |
| `## On-Demand Knowledge Candidates` section | text block per category (see Data Flow) | Contract between bash (producer) and Claude (consumer) |
| Resolution warning formats | 3 variants (unset/empty, path-not-found, path-is-file) | Stable text for test assertions |
| Malformed-yml warning format | `[knowledge] malformed .knowledge.yml at <path> — skipping category.` | Stable format for test assertions |
| Claude-emitted match log | `[knowledge] matched: <cat> via <trigger>; <cat2> via <trigger>` | Observability (PRD Stories #13, #15) |
| `bin/knowledge-helpers.sh` | sourced bash file | Canonical `parse_knowledge_yml`, `parse_knowledge_triggers`, `list_categories`, `list_md_files` |
| `knowledge-doctor` subcommand | skill subcommand | Diagnostic: shows resolved path, per-category surface mode + triggers, configured caps |
| `AI_KNOWLEDGE_DISABLE` env var | shell env var | One-shot escape hatch: when set, skip all knowledge loading regardless of `$AI_KNOWLEDGE_DIR` |

### Modified APIs

| API | Before | After | Reason |
|-----|--------|-------|--------|
| SKILL.md Preamble | Git check + Path Resolution | ... + Knowledge Resolution + Knowledge Helpers + Knowledge Loading + On-Demand Matching + Diagnostic: knowledge-doctor | Add the 3-layer knowledge pipeline |

## Dependencies

| Dependency | Type | Status | Notes |
|-----------|------|--------|-------|
| Bash + coreutils (`ls`, `find`, `sort`, `grep`, `awk`) | Infra | Available | No new system deps |
| Minimal yaml parser | Code | New (bin/knowledge-helpers.sh) | bash + awk; full yaml parser (e.g. `yq`) deferred |
| Claude's tokenization of the latest user message | Platform | Available | Claude routinely tokenizes text; test evidence (E2E) backs the contract |

## Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| Large always-on corpus blows up context | Med | High | 500-path / 100KB hard-fail cap (loud refusal over silent partial load); soft warning above threshold; documented trade-off |
| Naive yml parser mis-parses edge cases | High | Low | Document the supported subset (flat keys + list values only); malformed → warn + skip; full yaml support deferred |
| Claude doesn't read listed always-on paths | Low | High | Skill instructions explicitly state "before answering, Read every path listed under Always-On Knowledge"; verified by E2E canary test |
| Claude misses an on-demand match (false negative) | Med | Med | Observability surfaces misses (`[knowledge] matched:` log); user can iterate on triggers; E2E suite pins ≥95% hit rate |
| Claude over-matches on-demand (false positive) | Med | Low | User's responsibility to pick specific triggers; observability helps them notice; documented in WORKFLOW.md |
| Trigger is a common English word, loads every time | Med | Low | Documented trade-off; no skill-side filtering |
| Knowledge files contain sensitive data user didn't mean to expose | Low | Med | Documented: "files in always-on categories are included in every Claude invocation"; user is responsible |
| Cross-context contamination (Company A knowledge in Company B repo) | Med | Med | User's responsibility — control which categories are `surface: always`, which carry triggers, or unset `$AI_KNOWLEDGE_DIR` per shell. `AI_KNOWLEDGE_DISABLE` escape hatch for one-off bypass |
| Prompt-injection inside knowledge files manipulating matching | Low | Med | Knowledge files are Read into Claude's context, not executed; same trust boundary as any Read call; noted in WORKFLOW.md security callout |
| Log injection via env-var display in warnings | Low | Low | Sanitized output (printable + safe chars only) |

## Design Decisions

| Decision | Chosen | Rejected Alternative | Why |
|----------|--------|---------------------|-----|
| Resolution mechanism | `$AI_KNOWLEDGE_DIR` env var | Fixed path / per-repo `.knowledge/` / multi-source overlay | One knob, cross-repo, testable, degrades cleanly |
| Env var prefix | `AI_` (not `CLAUDE_`) | `CLAUDE_KNOWLEDGE_DIR` | Provider-agnostic; the knowledge store is a general AI-assist resource |
| Unset behavior | Warn every invocation | Warn-once / silent no-op | Intentionally noisy: nudges configuration over silent value loss |
| Story shape | One unified story across 3 layers | Three separate stories | All three layers share the category tree, yml parser, fixture builder; the slice boundary was bookkeeping |
| Content delivery mechanism | Skill emits paths; Claude Reads them | Skill bash `cat`s files inline into preamble | Keeps preamble output small; uses Claude's native Read tool; lets Claude paginate huge files if needed |
| Matching engine (on-demand) | Claude (consumes candidates block) | bash (regex over `$USER_MESSAGE` env var) | Bash doesn't have access to the user's current message; Claude does |
| yml parser | Minimal bash + awk for the 2 fields we support | Require `yq` as a dependency | Zero new deps; supported subset is tiny and stable |
| Helpers location | `bin/knowledge-helpers.sh`, sourced via 2-level fallback | Inline in each `## Knowledge ...` block | One canonical file means a fix lands once, not four times. Inline duplication had already drifted (Diagnostic block carried a separate `_parse` shim) |
| Load order | Categories lex-sorted, files within lex-sorted by relative path | Load order = filesystem order | Determinism matters for reproducible context and test assertions |
| Missing yml behavior | Skip silently (treat as on-demand w/ empty triggers) | Warn | Missing is a legitimate state (category in progress); warnings are for broken states, not unconfigured ones |
| Error isolation per category | One bad yml doesn't block others | Fail fast on first error | Per PRD Story #6; single typo shouldn't disable the feature |
| Size cap (always-on) | Hard-fail at 500 paths / 100KB | Soft warn / no cap | Loud refusal over silent partial load (dual-voice review: a soft cap is theater) |
| Tokenization rule (on-demand) | Whitespace + punctuation split, case-folded | Full Unicode-aware tokenization | Claude already handles this naturally; formal spec would be over-engineering |
| Phrase match (on-demand) | Case-insensitive substring at token boundaries | Strict equality of the phrase | Lets "the pricing engine is fast" match `"pricing engine"` while still preventing "price" alone from matching |
| Latest message only (on-demand) | Yes | Full conversation history | Prevents runaway loading; user's intent is in their most recent ask |
| Match log (on-demand) | One line per invocation when any match occurs | Verbose debug block / silent | Observable without noise; empty on zero matches |
| Scoring / priority (on-demand) | Uniform (load all matched) | Rank by specificity | Out of scope; revisit after real-world use |
| Cross-context isolation | User-side: pick triggers carefully or unset env per shell. `AI_KNOWLEDGE_DISABLE` for one-off bypass | Per-repo opt-in marker requiring `.claude/knowledge-enabled` | Marker is redundant on top of two-tier surfacing + env-var control. Adds complexity without proportional safety; cross-context isolation is the user's responsibility |
