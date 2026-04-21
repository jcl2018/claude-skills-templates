---
type: test-spec
parent: S000005
feature: F000004
title: "knowledge-loading — Test Specification"
version: 2
status: Draft
date: 2026-04-19
author: chjiang
prd: PRD.md
architecture: ARCHITECTURE.md
reviewers: []
---

## Test Matrix

### Always-on loading

| # | Tag | Test Case | AC | Precondition | Steps | Expected Result | Priority | Type |
|---|-----|-----------|-----|-------------|-------|-----------------|----------|------|
| A1 | core | Single always-on category loads | Stories 1,2 | Fixture with `coding/` + valid yml + 2 md files (one nested) + opt-in marker | Invoke validate | `## Always-On Knowledge` section lists both absolute paths, lex-sorted | P0 | Integration |
| A2 | core | On-demand category NOT in always-on block | Story 4 | Fixture category with `surface: on-demand` | Invoke validate | No paths from that category in Always-On Knowledge section | P0 | Integration |
| A3 | core | Missing yml = not loaded, no warning | Story 4 | Fixture category with no `.knowledge.yml` | Invoke validate | Zero paths from category; zero warnings | P0 | Integration |
| A4 | resilience | Malformed yml warns + continues | Story 3 | Two categories: one valid always-on, one yml with invalid syntax | Invoke validate | Valid category paths listed; single warning names the malformed yml; exit 0 | P0 | Integration |
| A5 | core | Load order is deterministic | Stories 1,2 | Fixture with 3 files unsorted on disk | Invoke validate twice | Path list identical across runs, lex-sorted | P0 | Integration |
| A6 | core | Empty `$_KNOWLEDGE_DIR` → no loading | All | `AI_KNOWLEDGE_DIR` unset | Invoke validate | No Always-On Knowledge section emitted; S000004 warning still present | P0 | E2E |
| A7 | core | Claude actually reads the listed paths | Story 1 | Fixture file contains unique canary string `CANARY_ALPHA_9283` + opt-in marker | User asks Claude a question; assert Claude can quote the canary | Claude produces the canary in its reply | P0 | E2E |
| A8 | resilience | Zero regression on existing fixtures | All | `fixtures/valid-feature-dir/` with env unset AND env set to empty dir | Diff validate output across the two runs | Byte-identical | P0 | Integration |
| A9 | observability | Loaded path list visible in diagnostic | Story 10 (P1) | Several always-on categories | Run a diagnostic command | All loaded paths visible | P1 | Integration |
| A10 | resilience | Soft warning above size threshold | Story 11 (P1) | Always-on fixture with >50KB total | Invoke validate | One warning noting total size; content still loaded | P1 | Integration |

### On-demand matching

| # | Tag | Test Case | AC | Precondition | Steps | Expected Result | Priority | Type |
|---|-----|-----------|-----|-------------|-------|-----------------|----------|------|
| O1 | core | Single-word trigger matches | Story 5 | Category `runbooks/` triggers: [pricing]; file contains `CANARY_RB_1` + opt-in marker | Ask "explain the pricing flow" | Claude reads the file and can cite the canary | P0 | E2E |
| O2 | core | Phrase trigger matches only the phrase | Story 6 | Category triggers: ["pricing engine"] | Ask "how does the pricing engine work?" | Category loads | P0 | E2E |
| O3 | core | Phrase trigger does NOT match substring fragments | Story 6 | Same category | Ask "what is pricing?" | Category does NOT load | P0 | E2E |
| O4 | resilience | No trigger in prompt → no loading | Story 7 | Several on-demand categories | Ask an unrelated question | No on-demand categories load | P0 | E2E |
| O5 | core | Multi-match loads all matched | Story 8 | Category A triggers: [pricing]; Category B triggers: [auth] | Ask about "pricing auth" | Both A and B files read | P0 | E2E |
| O6 | usability | Case-insensitive match | Story 13 | Trigger: [cpp] | Ask "how do I handle CPP errors?" | Category loads | P0 | E2E |
| O7 | core | Empty triggers list never matches | All | Category with `triggers: []` | Any prompt | Category never loads | P0 | E2E |
| O8 | core | `surface: always` NOT considered by on-demand | All | Category with `surface: always` | Invoke | Loaded by always-on path, NOT emitted as on-demand candidate | P0 | Integration |
| O9 | core | `$_KNOWLEDGE_DIR` empty → no matching | All | Env var unset | Invoke | No on-demand candidates emitted | P0 | Integration |
| O10 | observability | Match log names matched categories and triggers | Story 12 (P1) | Matching scenario | Invoke | stderr contains `[knowledge] matched: ...` line | P1 | E2E |
| O11 | resilience | Zero regression | All | Existing fixtures | Diff validate output | Byte-identical | P0 | Integration |
| O12 | resilience | Malformed yml in on-demand category doesn't break others | Story 3 | Mixed: one valid on-demand, one malformed | Invoke with a matching trigger for the valid one | Valid category loads; warning emitted; exit 0 | P0 | Integration |

### Per-repo opt-in gate (cross-cutting)

| # | Tag | Test Case | AC | Precondition | Steps | Expected Result | Priority | Type |
|---|-----|-----------|-----|-------------|-------|-----------------|----------|------|
| G1 | security | Marker absent → no always-on loading | Story 9 | `$_KNOWLEDGE_DIR` valid + always-on categories present + NO `.claude/knowledge-enabled` in repo root | Invoke | `## Always-On Knowledge` section absent; no warnings | P0 | E2E |
| G2 | security | Marker absent → no on-demand candidates | Story 9 | `$_KNOWLEDGE_DIR` valid + on-demand categories present + NO marker | Invoke matching prompt | `## On-Demand Knowledge Candidates` section absent; canaries absent from reply | P0 | E2E |
| G3 | security | Marker present → both paths activate | Story 9 | `$_KNOWLEDGE_DIR` valid + mixed categories + marker present | Invoke | Both `## Always-On Knowledge` and `## On-Demand Knowledge Candidates` blocks emitted as appropriate | P0 | E2E |

## Test Tiers

### Tier 1: Smoke Tests (automated, no live execution)

| # | Tag | Check | What It Validates | Script/Command |
|---|-----|-------|-------------------|---------------|
| S1 | always-on / core | SKILL.md has a `## Knowledge Loading` section | Always-on impl block exists | `grep -q "^## Knowledge Loading" skills/company-workflow/SKILL.md` |
| S2 | always-on / core | SKILL.md emits `## Always-On Knowledge` block | Output contract is stable | `grep -q "## Always-On Knowledge" skills/company-workflow/SKILL.md` |
| S3 | always-on / core | SKILL.md instructs Claude to Read listed paths | Contract between skill and Claude | `grep -qi "read.*always-on knowledge" skills/company-workflow/SKILL.md` |
| S4 | on-demand / core | SKILL.md has `## On-Demand Matching` section | On-demand impl block exists | `grep -q "^## On-Demand Matching" skills/company-workflow/SKILL.md` |
| S5 | on-demand / core | SKILL.md emits `## On-Demand Knowledge Candidates` | Output contract stable | `grep -q "## On-Demand Knowledge Candidates" skills/company-workflow/SKILL.md` |
| S6 | on-demand / core | SKILL.md instructs Claude on matching + Read | Contract with Claude explicit | `grep -qi "match.*trigger.*read" skills/company-workflow/SKILL.md` |
| S7 | on-demand / core | SKILL.md specifies case-insensitive + phrase semantics | Spec is testable | `grep -qi "case-insensitive" skills/company-workflow/SKILL.md` |
| S8 | on-demand / observability | SKILL.md specifies the match log format | Observability contract | `grep -q "\\[knowledge\\] matched" skills/company-workflow/SKILL.md` |
| S9 | on-demand / core | SKILL.md documents "latest user message only" scope | Scope decision pinned | `grep -q "latest user message" skills/company-workflow/SKILL.md` |
| S10 | gate / security | SKILL.md references the per-repo opt-in marker | Cross-context gate present | `grep -q "knowledge-enabled\|opt-in" skills/company-workflow/SKILL.md` |
| S11 | infra | Shared fixture helper exists | Test infra present | `test -f scripts/test-helpers/knowledge.sh && bash -c 'source scripts/test-helpers/knowledge.sh && declare -F build_knowledge_fixture'` |
| S12 | resilience | Helper supports malformed-yml spec | Error-path testable | `root=$(mktemp -d); source scripts/test-helpers/knowledge.sh; build_knowledge_fixture "$root" "broken:malformed"; test -f "$root/broken/.knowledge.yml"` |
| S13 | on-demand / core | Helper supports on-demand category specs with triggers | Test infra covers on-demand | `root=$(mktemp -d); source scripts/test-helpers/knowledge.sh; build_knowledge_fixture "$root" 'runbooks:on-demand:pricing,"pricing engine"'; test -f "$root/runbooks/.knowledge.yml" && grep -Fq '"pricing engine"' "$root/runbooks/.knowledge.yml"` |
| S14 | docs | WORKFLOW.md documents `.knowledge.yml` schema | Docs current | `grep -qE "surface:.*always.*on-demand\|always.*on-demand" skills/company-workflow/WORKFLOW.md` |
| S15 | docs | WORKFLOW.md documents on-demand + triggers + security | Full docs present | `grep -qi "on-demand" skills/company-workflow/WORKFLOW.md && grep -qi "triggers" skills/company-workflow/WORKFLOW.md && grep -qi "trust boundary\|prompt injection\|Read" skills/company-workflow/WORKFLOW.md` |
| S16 | docs | WORKFLOW.md documents per-repo opt-in gate | Gate documented | `grep -q "knowledge-enabled\|opt-in" skills/company-workflow/WORKFLOW.md` |
| S17 | infra | Repo validate passes | No catalog/manifest drift | `./scripts/validate.sh` |

### Tier 2: E2E Tests (real end-to-end execution)

| # | Tag | Scenario | Steps (as a real user would) | Expected Outcome | Rubric |
|---|-----|----------|----------------------------|-----------------|--------|
| E1 | always-on / core | Happy path: always-on content reaches Claude | Set AI_KNOWLEDGE_DIR to a dir with `coding/.knowledge.yml { surface: always }` and a md file containing `CANARY_ALPHA_9283`. Opt-in marker present. Ask Claude: "what canary strings have you seen?" | Claude quotes `CANARY_ALPHA_9283` | Pass iff: Claude's reply contains the canary verbatim |
| E2 | always-on / core | Mixed categories: only always-on is loaded by always-on path | Fixture has `alwayson/` (surface: always, contains `A_CANARY`) and `demand/` (surface: on-demand, contains `D_CANARY`, no matching trigger in prompt). User asks about canaries without mentioning on-demand triggers | Claude cites `A_CANARY` but not `D_CANARY` | Pass iff: only the always-on canary appears |
| E3 | resilience | Malformed yml in one category doesn't break others | Fixture has one valid always-on (`GOOD_CANARY`) and one with invalid yml | Claude sees GOOD_CANARY; stderr has one warning | Pass iff: canary visible, warning text matches documented format |
| E4 | always-on / core | Empty `AI_KNOWLEDGE_DIR` → no loading | `unset AI_KNOWLEDGE_DIR`; ask Claude about canaries | Claude reports it hasn't seen any | Pass iff: zero canary content in reply |
| E5 | on-demand / core | Single-word trigger match | Fixture with `runbooks/` triggers [pricing], file contains `PE_CANARY_A`. Ask "explain the pricing flow" | Claude quotes PE_CANARY_A | Pass iff: canary in reply |
| E6 | on-demand / core | Phrase trigger match | Fixture triggers: `["pricing engine"]`. Ask "how does the pricing engine handle rounding?" | Category loaded | Pass iff: category's canary in reply |
| E7 | on-demand / core | Phrase non-match on substring | Same fixture. Ask "what is pricing?" | Category NOT loaded | Pass iff: category's canary NOT in reply |
| E8 | on-demand / resilience | No trigger in prompt | Several on-demand categories defined. Ask an unrelated question ("what time is it?") | No canaries from any on-demand category in the reply | Pass iff: zero on-demand canaries appear |
| E9 | on-demand / core | Multi-match | Categories A (triggers: [pricing]) and B (triggers: [auth]). Ask "help me audit pricing auth" | Both canaries in reply | Pass iff: both canaries appear |
| E10 | on-demand / usability | Case variations | Trigger: [cpp]. Ask with "CPP", "Cpp", "cpp" | Each triggers loading | Pass iff: canary appears in all three cases |
| E11 | on-demand / core | Empty triggers never match | Category with `triggers: []`. Any prompt mentioning the folder name | Category does not load | Pass iff: canary absent |
| E12 | on-demand / observability | Match log surfaced | Matching scenario | stderr includes `[knowledge] matched: runbooks via pricing` | Pass iff: line present + correct format |
| E13 | gate / security | Opt-in gate absent → both loading paths inactive | `$AI_KNOWLEDGE_DIR` valid, mixed categories, NO `.claude/knowledge-enabled` marker. Ask matching prompt | No canaries in reply (always-on or on-demand); no `## Always-On Knowledge` or `## On-Demand Knowledge Candidates` sections in skill output | Pass iff: zero canaries + sections absent |
| E14 | gate / security | Opt-in gate present → both paths activate | Same fixture, marker present | Always-on canaries appear unconditionally; on-demand canaries appear when matched | Pass iff: both behaviors normal |

## Coverage Gaps

| Gap | Why Not Tested | Risk Accepted |
|-----|---------------|---------------|
| Hot reload when files change mid-session | Out of scope per PRD Assumptions | Engineer can restart session |
| Circular symlinks inside a category | Very unusual; `find` handles in default invocation | Would appear as duplicate paths; user would notice |
| Binary / non-markdown files in a category | Only `*.md` is enumerated; other files silently ignored | Documented behavior |
| Categories nested 3+ deep | `find` is recursive; no depth limit specified | If users hit performance issues, add a max-depth option |
| Line ending variants (CRLF) in `.knowledge.yml` | `grep` tolerant; minor parse risk | If users hit it on Windows-origin files, add a normalization step |
| Concurrent skill invocations reading the same knowledge | Read-only; no shared state | None |
| Overlapping triggers across categories | Both load per AC; scoring is P2 | None for v1; revisit if user complains |
| Unicode triggers (non-ASCII) | Claude's tokenizer handles Unicode by default; no special skill logic | Edge cases emerge in practice → add case if observed |
| Regex / glob in triggers | Not a supported feature | Documented; user uses explicit phrases |
| Matching across prior turns | Explicitly scoped to latest message | Documented trade-off |
| Prompt-injection inside knowledge files | Out of story scope; same trust boundary as any Read call | Noted in WORKFLOW.md security callout |
| Very large trigger lists (>100) | Not a target use case | Performance acceptable up to ~20 categories × ~20 triggers each |
