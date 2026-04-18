---
type: architecture
parent: S000006
feature: F000004
title: "on-demand-matching — Architecture"
version: 1
status: Draft
date: 2026-04-16
author: chjiang
prd: PRD.md
reviewers: []
---

## Overview

Add an On-Demand Matching section to SKILL.md that runs after Knowledge Loading (S000005). For each category with `.knowledge.yml { surface: on-demand, triggers: [...] }`, the skill's bash block emits a machine-readable "candidates" block containing the trigger list and the category's markdown file paths. SKILL.md then instructs Claude to tokenize the user's latest message, match against each candidate's triggers (case-insensitive whole-word + quoted-phrase match), and Read every file under each matched category before producing the response.

The split is deliberate: bash handles discovery + file enumeration (deterministic, testable), Claude handles prompt matching (the prompt is only visible to Claude). This mirrors the S000005 design for always-on, differing only in the gating step.

## Architecture

```
┌────────────────────────────────────────────────────────────────────────┐
│  On-Demand Matching (NEW; runs after Knowledge Loading)                │
│                                                                        │
│   Per on-demand category under $_KNOWLEDGE_DIR:                        │
│                                                                        │
│   ┌─────────────────────────┐       ┌──────────────────────────────┐   │
│   │  bash: emit candidates  │──────▶│  Claude: match + Read        │   │
│   │  - category root path    │       │  - tokenize latest user msg │   │
│   │  - triggers list         │       │  - for each candidate:       │   │
│   │  - *.md file paths       │       │      match? → Read all files│   │
│   └─────────────────────────┘       │  - log matched categories    │   │
│                                      └──────────────────────────────┘   │
│                                                                        │
│   Match semantics:                                                     │
│   - Tokenize prompt: split on whitespace + punctuation                 │
│   - For each trigger:                                                  │
│      * if trigger is a single word: case-insensitive token match      │
│      * if trigger is a multi-word phrase: case-insensitive substring  │
│        on the prompt AT TOKEN BOUNDARIES                              │
│   - A category matches if ANY trigger matches                         │
│   - Empty triggers list → category never matches                      │
└────────────────────────────────────────────────────────────────────────┘
```

### Components Affected

| Component | Repo | Change Type | Description |
|-----------|------|------------|-------------|
| skills/company-workflow/SKILL.md | claude-skills-templates | Modified | Add On-Demand Matching section + Claude-facing instruction block |
| skills/company-workflow/fixtures/valid-knowledge-dir/ | claude-skills-templates | Modified | Extend with on-demand categories (single-word, multi-word, empty-triggers) |
| scripts/test.sh | claude-skills-templates | Modified | Run new Tier 1 smoke checks |

### Data Flow

1. S000004 sets `$_KNOWLEDGE_DIR`; S000005 already emitted `## Always-On Knowledge`
2. This story's bash block: for each category with `surface: on-demand`:
   - Read `triggers:` list from yml (same minimal parser as S000005)
   - Enumerate `*.md` files (recursive, lex-sorted)
   - Emit under `## On-Demand Knowledge Candidates`:
     ```
     category: <absolute path>
     triggers: [<trigger1>, <trigger2>, ...]
     files:
       - <absolute path>
       - <absolute path>
     ```
3. SKILL.md instructions tell Claude:
   > Before answering, for each entry under `## On-Demand Knowledge Candidates`,
   > check if any listed trigger appears in the user's latest message as a
   > case-insensitive whole-word match (single-word) or quoted-phrase match
   > (multi-word). For each entry that matches, Read every listed file.
   > Log a one-line summary naming matched categories and their matched
   > triggers.

## API Changes

### New APIs

| API | Signature | Description |
|-----|-----------|-------------|
| `## On-Demand Knowledge Candidates` section | text block per category (see Data Flow) | Contract between bash (producer) and Claude (consumer) |
| Claude-emitted match log | `[knowledge] matched: <cat> via <trigger>; <cat2> via <trigger>` | Observability (P1 Story #5) |

### Modified APIs

| API | Before | After | Reason |
|-----|--------|-------|--------|
| SKILL.md Preamble chain | Git → Path Resolution → Knowledge Resolution (S000004) → Always-On Loading (S000005) | ... → On-Demand Matching (this story) | Final layer of F000004 |

## Dependencies

| Dependency | Type | Status | Notes |
|-----------|------|--------|-------|
| S000004 (resolution) | Feature | Pending sibling | Consumes `$_KNOWLEDGE_DIR` |
| S000005 (always-on) | Feature | Parallel sibling | Shares the yml parser and file-enumeration logic; refactor into a shared helper in SKILL.md if duplicated |
| Claude's tokenization of the latest user message | Platform | Available | Claude routinely tokenizes text; formal spec not required, but test evidence (E2E) must back it |

## Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| Claude misses a match (false negative) | Med | Med | P1 observability surfaces misses; user can iterate on triggers; E2E suite pins ≥95% hit rate on author-specified cases |
| Claude over-matches (false positive) | Med | Low | User's responsibility to pick specific triggers; observability helps them notice; document in WORKFLOW.md |
| Trigger is a common English word, loads every time | Med | Low | Documented trade-off; no skill-side filtering; revisit if observed in practice |
| Prompt-injection via knowledge file content tries to manipulate matching | Low | Med | Knowledge files are Read into Claude's context, not executed; same trust boundary as any Read call; note in security section of WORKFLOW.md |
| Context pressure when many categories match at once | Low | High | User has some control (specific triggers); consider a match cap (e.g. top N) as a follow-up if observed |

## Design Decisions

| Decision | Chosen | Rejected Alternative | Why |
|----------|--------|---------------------|-----|
| Matching engine | Claude (consumes candidates block) | bash (regex over `$USER_MESSAGE` env var) | Bash doesn't have access to the user's current message; Claude does. This is a Claude-Code-skill-specific constraint |
| Tokenization rule | Whitespace + punctuation split, case-folded | Full Unicode-aware tokenization | Claude already handles this naturally; formal spec would be over-engineering |
| Phrase match | Case-insensitive substring at token boundaries | Strict equality of the phrase | Lets "the pricing engine is fast" match `"pricing engine"` while still preventing "price" alone from matching |
| Latest message only | Yes | Full conversation history | Prevents runaway loading; user's intent is in their most recent ask |
| Match log | One line per invocation when any match occurs | Verbose debug block / silent | Observable without noise; empty on zero matches |
| Content delivery | Same as S000005: Claude Reads the paths | bash `cat`s files into preamble | Consistency with S000005; avoids preamble bloat |
| Scoring / priority | Uniform (load all matched) | Rank by specificity | Out of scope per PRD P2 Story #7; revisit after real-world use |
