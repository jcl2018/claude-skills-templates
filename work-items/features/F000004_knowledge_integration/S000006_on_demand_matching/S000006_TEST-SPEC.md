---
type: test-spec
parent: S000006
feature: F000004
title: "on-demand-matching — Test Specification"
version: 1
status: Draft
date: 2026-04-16
author: chjiang
prd: PRD.md
architecture: ARCHITECTURE.md
reviewers: []
---

## Test Matrix

| # | Tag | Test Case | AC | Precondition | Steps | Expected Result | Priority | Type |
|---|-----|-----------|-----|-------------|-------|-----------------|----------|------|
| 1 | core | Single-word trigger matches | AC-1 | Category `runbooks/` triggers: [pricing]; file contains `CANARY_RB_1` | Ask "explain the pricing flow" | Claude reads the file and can cite the canary | P0 | E2E |
| 2 | core | Phrase trigger matches only the phrase | AC-2 | Category triggers: ["pricing engine"] | Ask "how does the pricing engine work?" | Category loads | P0 | E2E |
| 3 | core | Phrase trigger does NOT match substring fragments | AC-2 | Same category | Ask "what is pricing?" | Category does NOT load | P0 | E2E |
| 4 | resilience | No trigger in prompt → no loading | AC-3 | Several on-demand categories | Ask an unrelated question | No on-demand categories load | P0 | E2E |
| 5 | core | Multi-match loads all matched | AC-4 | Category A triggers: [pricing]; Category B triggers: [auth] | Ask about "pricing auth" | Both A and B files read | P0 | E2E |
| 6 | usability | Case-insensitive match | AC-6 | Trigger: [cpp] | Ask "how do I handle CPP errors?" | Category loads | P0 | E2E |
| 7 | core | Empty triggers list never matches | AC | Category with `triggers: []` | Any prompt | Category never loads | P0 | E2E |
| 8 | core | `surface: always` NOT considered by this story | AC | Category with `surface: always` | Invoke | Loaded by S000005, NOT emitted as on-demand candidate | P0 | Integration |
| 9 | core | `$_KNOWLEDGE_DIR` empty → no matching | AC | Env var unset | Invoke | No on-demand candidates emitted | P0 | Integration |
| 10 | observability | Match log names matched categories and triggers | AC (P1) | Matching scenario | Invoke | stderr contains `[knowledge] matched: ...` line | P1 | E2E |
| 11 | resilience | Zero regression | AC | Existing fixtures | Diff validate output | Byte-identical | P0 | Integration |
| 12 | resilience | Malformed yml in on-demand category doesn't break others | AC | Mixed: one valid on-demand, one malformed | Invoke with a matching trigger for the valid one | Valid category loads; warning emitted; exit 0 | P0 | Integration |

## Test Tiers

### Tier 1: Smoke Tests (automated, no live execution)

| # | Tag | Check | What It Validates | Script/Command |
|---|-----|-------|-------------------|---------------|
| S1 | core | SKILL.md has On-Demand Matching section | Implementation block exists | `grep -q "^## On-Demand Matching" skills/company-workflow/SKILL.md` |
| S2 | core | SKILL.md emits `## On-Demand Knowledge Candidates` | Output contract stable | `grep -q "## On-Demand Knowledge Candidates" skills/company-workflow/SKILL.md` |
| S3 | core | SKILL.md instructs Claude on matching + Read | Contract with Claude explicit | `grep -qi "match.*trigger.*read" skills/company-workflow/SKILL.md` |
| S4 | core | SKILL.md specifies case-insensitive + phrase semantics | Spec is testable | `grep -qi "case-insensitive" skills/company-workflow/SKILL.md` |
| S5 | observability | SKILL.md specifies the match log format | Observability contract | `grep -q "\\[knowledge\\] matched" skills/company-workflow/SKILL.md` |
| S6 | core | Fixtures include on-demand categories | Test infra present | `test -f skills/company-workflow/fixtures/valid-knowledge-dir/runbooks/.knowledge.yml` |
| S7 | core | WORKFLOW.md documents on-demand + triggers | Docs current | `grep -qi "on-demand\|triggers" skills/company-workflow/WORKFLOW.md` |
| S8 | core | Repo validate passes | No catalog drift | `./scripts/validate.sh` |

### Tier 2: E2E Tests (real end-to-end execution)

| # | Tag | Scenario | Steps | Expected Outcome | Rubric |
|---|-----|----------|-------|-----------------|--------|
| E1 | core | Single-word trigger match | Fixture with `runbooks/` triggers [pricing], file contains `PE_CANARY_A`. Ask "explain the pricing flow" | Claude quotes PE_CANARY_A | Pass iff: canary in reply |
| E2 | core | Phrase trigger match | Fixture triggers: `["pricing engine"]`. Ask "how does the pricing engine handle rounding?" | Category loaded | Pass iff: category's canary in reply |
| E3 | core | Phrase non-match on substring | Same fixture. Ask "what is pricing?" | Category NOT loaded | Pass iff: category's canary NOT in reply |
| E4 | resilience | No trigger in prompt | Several on-demand categories defined. Ask an unrelated question ("what time is it?") | No canaries from any on-demand category in the reply | Pass iff: zero on-demand canaries appear |
| E5 | core | Multi-match | Categories A (triggers: [pricing]) and B (triggers: [auth]). Ask "help me audit pricing auth" | Both canaries in reply | Pass iff: both canaries appear |
| E6 | usability | Case variations | Trigger: [cpp]. Ask with "CPP", "Cpp", "cpp" | Each triggers loading | Pass iff: canary appears in all three cases |
| E7 | core | Empty triggers never match | Category with `triggers: []`. Any prompt mentioning the folder name | Category does not load | Pass iff: canary absent |
| E8 | observability | Match log surfaced | Matching scenario | stderr includes `[knowledge] matched: runbooks via pricing` | Pass iff: line present + correct format |

## Coverage Gaps

| Gap | Why Not Tested | Risk Accepted |
|-----|---------------|---------------|
| Overlapping triggers across categories | Both load per AC; scoring is P2 | None for v1; revisit if user complains |
| Unicode triggers (non-ASCII) | Claude's tokenizer handles Unicode by default; no special skill logic | Edge cases emerge in practice → add case if observed |
| Regex / glob in triggers | Not a supported feature | Documented; user uses explicit phrases |
| Matching across prior turns | Explicitly scoped to latest message | Documented trade-off |
| Prompt-injection inside knowledge files | Out of story scope; same trust boundary as any Read call | Noted in WORKFLOW.md security callout |
| Very large trigger lists (>100) | Not a target use case | Performance acceptable up to ~20 categories × ~20 triggers each |
