---
type: architecture
parent: S000005
feature: F000004
title: "always-on-loading — Architecture"
version: 1
status: Draft
date: 2026-04-16
author: chjiang
prd: PRD.md
reviewers: []
---

## Overview

<!-- One paragraph: what this design achieves and why this approach was chosen.
     Link back to the PRD for requirements context.
     If there are multiple related components (e.g., a main skill and its test harness),
     introduce all of them here so readers see the full picture upfront. -->

Add a Knowledge Loading section to SKILL.md that runs after Knowledge Resolution (S000004). When `$_KNOWLEDGE_DIR` is populated, the block enumerates top-level subdirectories, reads each category's `.knowledge.yml`, and for categories marked `surface: always` emits their markdown file paths in a deterministic, machine-readable block. Claude is instructed to read those files (via the Read tool) before answering the user's request. This keeps the skill shell-local (no bash-side file concatenation, no prompt-length blowup in the preamble) while ensuring the content is factored into Claude's reasoning every turn.

## Architecture

```
┌────────────────────────────────────────────────────────────────────────┐
│  Knowledge Loading (NEW; runs after Knowledge Resolution)              │
│                                                                        │
│   $_KNOWLEDGE_DIR (from S000004)                                       │
│        │                                                               │
│        ▼                                                               │
│   ┌────────────────────────────────────────┐                           │
│   │  1. List top-level subdirs as categories│                          │
│   │     (skip hidden, skip non-dirs)        │                          │
│   └────────────────────┬───────────────────┘                           │
│                        │                                               │
│                        ▼                                               │
│   ┌────────────────────────────────────────┐                           │
│   │  2. For each category: read             │                          │
│   │     `<cat>/.knowledge.yml`              │                          │
│   │     - missing → skip (treat as on-demand│                          │
│   │                  w/ empty triggers)     │                          │
│   │     - malformed → warn + skip           │                          │
│   │     - surface: on-demand → skip (S000006│                          │
│   │                           handles)      │                          │
│   │     - surface: always → include         │                          │
│   └────────────────────┬───────────────────┘                           │
│                        │                                               │
│                        ▼                                               │
│   ┌────────────────────────────────────────┐                           │
│   │  3. For each always-on category:        │                          │
│   │     enumerate *.md files (recursive)    │                          │
│   │     sort by relative path               │                          │
│   └────────────────────┬───────────────────┘                           │
│                        │                                               │
│                        ▼                                               │
│   ┌────────────────────────────────────────┐                           │
│   │  4. Emit a `## Always-On Knowledge`     │                          │
│   │     section listing absolute paths.     │                          │
│   │     SKILL.md instructs Claude to Read   │                          │
│   │     each path before answering.         │                          │
│   └────────────────────────────────────────┘                           │
└────────────────────────────────────────────────────────────────────────┘
```

### Components Affected

| Component | Repo | Change Type | Description |
|-----------|------|------------|-------------|
| skills/company-workflow/SKILL.md | claude-skills-templates | Modified | Add Knowledge Loading section; add "Read each Always-On Knowledge path" instruction |
| skills/company-workflow/fixtures/ | claude-skills-templates | New | Add `valid-knowledge-dir/` with mixed always-on + on-demand + missing-yml + malformed-yml categories |
| scripts/test.sh | claude-skills-templates | Modified | Run new Tier 1 smoke checks |

### Data Flow

1. S000004 sets `$_KNOWLEDGE_DIR` (or empty on failure)
2. This story's bash block: if empty, emit nothing and stop
3. Otherwise: `ls -d "$_KNOWLEDGE_DIR"/*/` → category list
4. For each category: parse `.knowledge.yml` with a minimal bash parser (`grep -E '^surface:'`, normalize)
5. For `surface: always`: `find "$category" -name '*.md' | sort`
6. Emit paths under a labeled section
7. Claude (reading the skill instructions) calls Read on each listed path before producing its response

## API Changes

### New APIs

| API | Signature | Description |
|-----|-----------|-------------|
| `## Always-On Knowledge` section in skill output | plain-text list of absolute paths | Contract between the skill's bash preamble and Claude's loading step |
| Malformed-yml warning format | `Warning: malformed .knowledge.yml at <path>: <reason>. Skipping category.` | Stable format for test assertions |

### Modified APIs

| API | Before | After | Reason |
|-----|--------|-------|--------|
| SKILL.md Preamble | Git check + Path Resolution + Knowledge Resolution (S000004) | ... + Knowledge Loading (this story) | Add Layer 2 to the preamble chain |

## Dependencies

| Dependency | Type | Status | Notes |
|-----------|------|--------|-------|
| S000004 (env-var resolution) | Feature | Pending (sibling story) | Must land first; this story consumes `$_KNOWLEDGE_DIR` |
| Bash + coreutils (`ls`, `find`, `sort`, `grep`) | Infra | Available | No new system deps |
| Minimal yaml parser | Code | New | Inline bash `grep`-based; full yaml parser (e.g. `yq`) deferred |

## Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| Large always-on corpus blows up context | Med | High | Emit a warning above a soft threshold (e.g. 50KB total); document the trade-off; hard cap deferred pending real-world signal |
| Naive yml parser mis-parses edge cases | High | Low | Document the supported subset (flat keys + list values only); malformed → warn + skip; full yaml support deferred |
| Claude doesn't read listed paths | Low | High | Skill instructions explicitly state "before answering, Read every path listed under Always-On Knowledge"; verified by E2E test (inject canary string) |
| Knowledge files contain sensitive data user didn't mean to expose | Low | Med | Documented: "files in always-on categories are included in every Claude invocation"; user is responsible |

## Design Decisions

| Decision | Chosen | Rejected Alternative | Why |
|----------|--------|---------------------|-----|
| Content delivery mechanism | Skill emits paths; Claude Reads them | Skill bash `cat`s files inline into preamble | Keeps preamble output small; uses Claude's native Read tool; lets Claude paginate huge files if needed |
| yml parser | Minimal bash `grep` for the 2 fields we support | Require `yq` as a dependency | Zero new deps; supported subset is tiny and stable; document the limits |
| Load order | Categories lex-sorted, files within lex-sorted by relative path | Load order = filesystem order | Determinism matters for reproducible context and test assertions |
| Missing yml behavior | Skip silently (treat as on-demand w/ empty triggers) | Warn | Missing is a legitimate state (category in progress); warnings are for broken states, not unconfigured ones |
| Error isolation per category | One bad yml doesn't block others | Fail fast on first error | Per PRD Story #3; single typo shouldn't disable the feature |
| Size cap | Soft warn ≥ 50KB total always-on | Hard cap / no cap | Warn gives observability without enforcement; user opted into always-on so they bear the cost |
