---
type: architecture
parent: S000005
feature: F000004
title: "knowledge-loading — Architecture"
version: 2
status: Draft
date: 2026-04-19
author: chjiang
prd: PRD.md
reviewers: []
---

## Overview

<!-- One paragraph: what this design achieves and why this approach was chosen.
     Link back to the PRD for requirements context.
     If there are multiple related components (e.g., a main skill and its test harness),
     introduce all of them here so readers see the full picture upfront. -->

Add two sibling sections to SKILL.md after Knowledge Resolution (S000004): `## Knowledge Loading` (always-on) and `## On-Demand Matching`. Both run after a per-repo opt-in gate check, both share a `## Knowledge Helpers` block (yml parser + category enumerator + md file lister) so the bash logic exists in one place. When `$_KNOWLEDGE_DIR` is populated AND the opt-in marker exists, the gates open: always-on categories emit absolute paths under `## Always-On Knowledge`; on-demand categories emit candidates (root + triggers + paths) under `## On-Demand Knowledge Candidates`. Claude is instructed to (a) Read every always-on path before answering, and (b) for each on-demand candidate, tokenize the user's latest message and Read all paths if any trigger matches. This keeps the skill shell-local (no bash-side file concatenation, no prompt-length blowup in the preamble) while ensuring relevant content is factored into Claude's reasoning every turn.

## Architecture

```
┌─────────────────────────────────────────────────────────────────────────┐
│  Preamble chain (after S000004's Knowledge Resolution sets $_KNOWLEDGE_DIR)│
│                                                                          │
│   ┌───────────────────────────────┐                                     │
│   │  0. Per-repo opt-in gate       │                                     │
│   │     test -f .claude/knowledge-enabled                               │
│   │     - missing → STOP (emit nothing for the rest of this story)      │
│   │     - present → proceed                                              │
│   └────────────────┬──────────────┘                                     │
│                    │                                                     │
│                    ▼                                                     │
│   ┌───────────────────────────────┐                                     │
│   │  Knowledge Helpers (shared)    │                                     │
│   │  - parse_knowledge_yml(path)   │ → returns "surface,triggers"       │
│   │  - list_categories(root)       │ → top-level subdirs                │
│   │  - list_md_files(category)     │ → recursive, lex-sorted            │
│   └────────────────┬──────────────┘                                     │
│                    │                                                     │
│       ┌────────────┴────────────┐                                       │
│       ▼                         ▼                                       │
│  ┌─────────────┐        ┌────────────────────┐                          │
│  │ Always-On   │        │ On-Demand          │                          │
│  │ Loading     │        │ Matching           │                          │
│  │ (bash)      │        │ (bash + Claude)    │                          │
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
| skills/company-workflow/SKILL.md | claude-skills-templates | Modified | Add `## Knowledge Helpers` (shared bash) + `## Knowledge Loading` (always-on emit) + `## On-Demand Matching` (candidates emit + Claude instructions) sections + per-repo opt-in gate |
| skills/company-workflow/WORKFLOW.md | claude-skills-templates | Modified | Document `.knowledge.yml` schema, opt-in marker, supported bash-parser subset, on-demand worked example, trigger-authoring guidance, security callout |
| scripts/test-helpers/knowledge.sh | claude-skills-templates | New | Shared fixture builder: `build_knowledge_fixture()` synthesizes knowledge dirs in `mktemp -d` per test case (pattern matches T000003). Supports always-on + on-demand specs. No fixtures committed under `skills/` |
| scripts/test.sh | claude-skills-templates | Modified | Tier 1 smoke + Tier 2 extract-and-exec + canary-based E2E + regression assertions, covering both loading paths |

### Data Flow

1. S000004 sets `$_KNOWLEDGE_DIR` (or empty on failure)
2. **Opt-in gate**: if `.claude/knowledge-enabled` is missing in repo root, emit nothing and stop
3. If `$_KNOWLEDGE_DIR` is empty, emit nothing and stop
4. `list_categories "$_KNOWLEDGE_DIR"` → top-level subdir list (skip hidden, skip non-dirs)
5. For each category: `parse_knowledge_yml "$category/.knowledge.yml"` (minimal bash parser: `grep -E '^surface:'`, normalize)
   - missing → skip (treat as on-demand w/ empty triggers; silent)
   - malformed → warn (one line naming the file) + skip
   - `surface: always` → add to always-on list
   - `surface: on-demand` → add to on-demand list (with triggers)
6. **Always-on emit**: for each always-on category, `list_md_files` → emit absolute paths under `## Always-On Knowledge`. Claude instruction: Read every listed path before answering.
7. **On-demand emit**: for each on-demand category with non-empty triggers, emit a candidates block:
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
| `## Always-On Knowledge` section in skill output | plain-text list of absolute paths | Contract between the skill's bash preamble and Claude's loading step |
| `## On-Demand Knowledge Candidates` section | text block per category (see Data Flow) | Contract between bash (producer) and Claude (consumer) |
| Malformed-yml warning format | `Warning: malformed .knowledge.yml at <path>: <reason>. Skipping category.` | Stable format for test assertions |
| Claude-emitted match log | `[knowledge] matched: <cat> via <trigger>; <cat2> via <trigger>` | Observability (P1 Stories #10, #12) |
| Per-repo opt-in marker | file at `<repo-root>/.claude/knowledge-enabled` (path TBD in T000006 design) | Cross-context contamination prevention |

### Modified APIs

| API | Before | After | Reason |
|-----|--------|-------|--------|
| SKILL.md Preamble | Git check + Path Resolution + Knowledge Resolution (S000004) | ... + opt-in gate + Knowledge Helpers + Knowledge Loading + On-Demand Matching | Add Layers 2 + 3 to the preamble chain |

## Dependencies

| Dependency | Type | Status | Notes |
|-----------|------|--------|-------|
| S000004 (env-var resolution) | Story | Landed (PR #38) | Provides `$_KNOWLEDGE_DIR` |
| Bash + coreutils (`ls`, `find`, `sort`, `grep`) | Infra | Available | No new system deps |
| Minimal yaml parser | Code | New | Inline bash `grep`-based; full yaml parser (e.g. `yq`) deferred |
| Claude's tokenization of the latest user message | Platform | Available | Claude routinely tokenizes text; formal spec not required, but test evidence (E2E) must back it |

## Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| Large always-on corpus blows up context | Med | High | Emit a warning above a soft threshold (e.g. 50KB total); document the trade-off; hard cap deferred pending real-world signal |
| Naive yml parser mis-parses edge cases | High | Low | Document the supported subset (flat keys + list values only); malformed → warn + skip; full yaml support deferred |
| Claude doesn't read listed always-on paths | Low | High | Skill instructions explicitly state "before answering, Read every path listed under Always-On Knowledge"; verified by E2E canary test |
| Claude misses an on-demand match (false negative) | Med | Med | P1 observability surfaces misses; user can iterate on triggers; E2E suite pins ≥95% hit rate on author-specified cases |
| Claude over-matches on-demand (false positive) | Med | Low | User's responsibility to pick specific triggers; observability helps them notice; document in WORKFLOW.md |
| Trigger is a common English word, loads every time | Med | Low | Documented trade-off; no skill-side filtering; revisit if observed in practice |
| Knowledge files contain sensitive data user didn't mean to expose | Low | Med | Documented: "files in always-on categories are included in every Claude invocation"; user is responsible |
| Cross-context contamination (Company A knowledge in Company B repo) | Med | High | Per-repo opt-in marker (P0 Story #9) blocks all loading without explicit consent in the current repo |
| Prompt-injection inside knowledge files manipulating matching | Low | Med | Knowledge files are Read into Claude's context, not executed; same trust boundary as any Read call; note in WORKFLOW.md security callout |
| Context pressure when many categories match at once | Low | High | User has some control (specific triggers); consider a match cap (e.g. top N) as a follow-up if observed |

## Design Decisions

| Decision | Chosen | Rejected Alternative | Why |
|----------|--------|---------------------|-----|
| Story shape | One story covering both surfacing modes | Two stories (former S000005 + S000006) | Both modes share the yml parser, file enumeration, opt-in gate, and fixture builder; the slice boundary was bookkeeping (see TRACKER Journal 2026-04-19) |
| Content delivery mechanism | Skill emits paths; Claude Reads them | Skill bash `cat`s files inline into preamble | Keeps preamble output small; uses Claude's native Read tool; lets Claude paginate huge files if needed |
| Matching engine (on-demand) | Claude (consumes candidates block) | bash (regex over `$USER_MESSAGE` env var) | Bash doesn't have access to the user's current message; Claude does. Claude-Code-skill-specific constraint |
| yml parser | Minimal bash `grep` for the 2 fields we support | Require `yq` as a dependency | Zero new deps; supported subset is tiny and stable; document the limits |
| Load order | Categories lex-sorted, files within lex-sorted by relative path | Load order = filesystem order | Determinism matters for reproducible context and test assertions |
| Missing yml behavior | Skip silently (treat as on-demand w/ empty triggers) | Warn | Missing is a legitimate state (category in progress); warnings are for broken states, not unconfigured ones |
| Error isolation per category | One bad yml doesn't block others | Fail fast on first error | Per PRD Story #3; single typo shouldn't disable the feature |
| Size cap (always-on) | Soft warn ≥ 50KB total always-on | Hard cap / no cap | Warn gives observability without enforcement; user opted into always-on so they bear the cost |
| Tokenization rule (on-demand) | Whitespace + punctuation split, case-folded | Full Unicode-aware tokenization | Claude already handles this naturally; formal spec would be over-engineering |
| Phrase match (on-demand) | Case-insensitive substring at token boundaries | Strict equality of the phrase | Lets "the pricing engine is fast" match `"pricing engine"` while still preventing "price" alone from matching |
| Latest message only (on-demand) | Yes | Full conversation history | Prevents runaway loading; user's intent is in their most recent ask |
| Match log (on-demand) | One line per invocation when any match occurs | Verbose debug block / silent | Observable without noise; empty on zero matches |
| Scoring / priority (on-demand) | Uniform (load all matched) | Rank by specificity | Out of scope per PRD P2 Story #15; revisit after real-world use |
| Activation gate | Per-repo opt-in marker (`.claude/knowledge-enabled`) required for ANY loading | Activate whenever `$_KNOWLEDGE_DIR` is valid | Codex outside-voice finding F2: prevents cross-context contamination when a global env var points at one company's folder while working in another's repo |
