---
type: test-plan
parent: T000006
title: "implement-loading-and-matching — Test Plan"
date: 2026-04-19
author: chjiang
status: Draft
---

<!-- Scope: ONE fix (defect) or ONE task. Cases must be concrete and reproducible. -->

## Scope

Implementation + test-helper + scripted tests for S000005 (knowledge-loading: always-on + on-demand). Five artifacts:

1. SKILL.md `## Knowledge Helpers` section (shared bash: yml parser + category enumerator + md file lister)
2. SKILL.md `## Knowledge Loading` section (always-on emit, consumes helpers)
3. SKILL.md `## On-Demand Matching` section (candidates emit + Claude instructions, consumes helpers)
4. WORKFLOW.md updates (`.knowledge.yml` schema + always-on + on-demand worked examples + trigger-authoring guidance + security callout + opt-in marker docs + helper contract)
5. `scripts/test-helpers/knowledge.sh` (shared fixture builder) + `scripts/test.sh` assertions

Fixture strategy (T000003 pattern): tests materialize knowledge directories in `mktemp -d` using the shared `build_knowledge_fixture()` helper; no fixtures committed under `skills/company-workflow/`.

Spec grammar for the helper (illustrative):
```
build_knowledge_fixture <root> <spec> [<spec> ...]

spec        := <category>:<surface>[:<triggers>]
surface     := always | on-demand | none | malformed
triggers    := comma-separated; quote phrase triggers with embedded commas/spaces

# Examples
build_knowledge_fixture "$root" "coding:always"
build_knowledge_fixture "$root" 'runbooks:on-demand:pricing,"pricing engine"'
build_knowledge_fixture "$root" "notes:none" "broken:malformed" "empty-triggers:on-demand"
```

## Regression Test Cases

### Helper self-tests (scripts/test-helpers/knowledge.sh)

| # | Test Case | Steps | Expected Result | Status |
|---|-----------|-------|-----------------|--------|
| H1 | Helper sourceable, exports the function | `source scripts/test-helpers/knowledge.sh && declare -F build_knowledge_fixture` | Function declared | Pending |
| H2 | Always-on spec builds category with nested md | `root=$(mktemp -d); build_knowledge_fixture "$root" "coding:always"; test -f "$root/coding/.knowledge.yml" && test -f "$root/coding/cpp/errors.md"` | Both present | Pending |
| H3 | Always-on yml declares `surface: always` | `grep -q "^surface: always" "$root/coding/.knowledge.yml"` | Match | Pending |
| H4 | On-demand spec emits phrase trigger verbatim | `build_knowledge_fixture "$root" 'runbooks:on-demand:pricing,"pricing engine"'; grep -Fq '"pricing engine"' "$root/runbooks/.knowledge.yml"` | Match | Pending |
| H5 | `none` surface creates category dir without `.knowledge.yml` | `build_knowledge_fixture "$root" "notes:none"; test -d "$root/notes" && test ! -f "$root/notes/.knowledge.yml"` | Assertion true | Pending |
| H6 | `malformed` surface produces unparseable `.knowledge.yml` | `build_knowledge_fixture "$root" "broken:malformed"; ! awk '/^surface: (always\|on-demand)$/{f=1} END{exit !f}' "$root/broken/.knowledge.yml"` | No valid `surface:` line | Pending |
| H7 | On-demand with no trigger list emits `triggers: []` | `build_knowledge_fixture "$root" "empty-triggers:on-demand"; grep -q "^triggers: \[\]" "$root/empty-triggers/.knowledge.yml"` | Match | Pending |
| H8 | Each md contains a unique canary `CANARY_<category>_<file>` | `grep -r "^CANARY_" "$root" \| wc -l` ≥ total md files; all canaries distinct | One unique canary per md | Pending |
| H9 | Helper is idempotent within one test invocation | Call twice against same root + same spec; final state matches spec | Second call succeeds, no partial state | Pending |

### Tier 1: structural (scripts/test.sh grep assertions) — covers BOTH loading paths

| # | Test Case | Steps | Expected Result | Status |
|---|-----------|-------|-----------------|--------|
| S1 | SKILL.md has `## Knowledge Helpers` section | `grep -q "^## Knowledge Helpers" skills/company-workflow/SKILL.md` | Match | Pending |
| S2 | SKILL.md has `## Knowledge Loading` section | `grep -q "^## Knowledge Loading" skills/company-workflow/SKILL.md` | Match | Pending |
| S3 | SKILL.md emits `## Always-On Knowledge` block | grep output contract | Match | Pending |
| S4 | SKILL.md instructs Claude to Read listed always-on paths | case-insensitive grep | Match | Pending |
| S5 | SKILL.md has `## On-Demand Matching` section | `grep -q "^## On-Demand Matching" skills/company-workflow/SKILL.md` | Match | Pending |
| S6 | SKILL.md emits `## On-Demand Knowledge Candidates` block | grep output contract | Match | Pending |
| S7 | SKILL.md instructs Claude on matching + Read | `grep -qi "match.*trigger.*read" skills/company-workflow/SKILL.md` | Match | Pending |
| S8 | SKILL.md specifies case-insensitive + phrase semantics | `grep -qi "case-insensitive" skills/company-workflow/SKILL.md` | Match | Pending |
| S9 | SKILL.md specifies the match log format | `grep -q "\\[knowledge\\] matched" skills/company-workflow/SKILL.md` | Match | Pending |
| S10 | SKILL.md documents "latest user message only" scope | grep | Match | Pending |
| S11 | SKILL.md references the per-repo opt-in marker | `grep -q "knowledge-enabled\|opt-in" skills/company-workflow/SKILL.md` | Match | Pending |
| S12 | WORKFLOW.md documents `.knowledge.yml` schema (`surface`, `triggers`) | grep | Match | Pending |
| S13 | WORKFLOW.md has on-demand worked example + trigger guidance | grep | Match | Pending |
| S14 | WORKFLOW.md has security callout | grep `trust boundary\|prompt injection\|Read` | Match | Pending |
| S15 | WORKFLOW.md documents per-repo opt-in gate | grep | Match | Pending |
| S16 | WORKFLOW.md documents helper contract | grep | Match | Pending |
| S17 | `./scripts/validate.sh` passes | Run validator | Exit 0 | Pending |

### Tier 2: E2E via extract-and-exec + canary assertions

#### Always-on path

| # | Test Case | Steps | Expected Result | Status |
|---|-----------|-------|-----------------|--------|
| E1 | Always-on canary reaches loading block | Build fixture with `coding:always` + `CANARY_CODING_STYLE` + opt-in marker; extract Knowledge Loading block; exec with env pointed at fixture root | `CANARY_CODING_STYLE`-bearing path listed under `## Always-On Knowledge` | Pending |
| E2 | On-demand NOT in always-on block | Fixture `runbooks:on-demand:pricing`; exec loading block | `runbooks/` paths absent from always-on section | Pending |
| E3 | Malformed yml → warn + skip; siblings unaffected | Fixture `coding:always` + `broken:malformed` | Warning names `broken/.knowledge.yml`; `coding/` paths still listed | Pending |
| E4 | Missing `.knowledge.yml` silently skipped | Fixture `notes:none` | `notes/` paths absent; zero warnings | Pending |
| E5 | Env unset → no `## Always-On Knowledge` block | `unset AI_KNOWLEDGE_DIR`; extract + exec | Section absent from output | Pending |
| E6 | Determinism: same input → byte-identical output | Exec twice, diff stdout | Empty diff | Pending |
| E7 | Soft size warning above 50 KB | Fixture with >50KB always-on content | Warning mentions total size; paths still listed | Pending |

#### On-demand path

| # | Test Case | Steps | Expected Result | Status |
|---|-----------|-------|-----------------|--------|
| E8 | Single-word trigger pulls category | Fixture `runbooks:on-demand:pricing` + canary; extract matching block; exec with prompt "explain pricing flow" | `runbooks/` file paths emitted under Candidates; canary path matched | Pending |
| E9 | Phrase trigger matches phrase | Fixture with `triggers: ["pricing engine"]`; prompt "how does the pricing engine handle rounding?" | Category loaded | Pending |
| E10 | Phrase non-match on substring | Same fixture; prompt "what is pricing?" (no "pricing engine") | Category NOT loaded | Pending |
| E11 | No trigger in prompt → nothing loaded | Several on-demand categories; prompt "what time is it?" | Zero on-demand canaries emitted | Pending |
| E12 | Multi-match loads all matched | Categories A (triggers: [pricing]) + B (triggers: [auth]); prompt "audit pricing auth" | Both categories emitted | Pending |
| E13 | Case-insensitive match | Trigger `[cpp]`; prompts with `CPP`, `Cpp`, `cpp` | All three trigger loading | Pending |
| E14 | Empty triggers never load | Category `empty-triggers:on-demand`; any prompt | Category never emitted | Pending |
| E15 | Match log emitted on matches | Matching scenario | stderr contains `[knowledge] matched: runbooks via pricing` | Pending |
| E16 | `surface: always` NOT considered by matching | Fixture mixes always-on + on-demand; matching prompt | Always-on paths absent from Candidates block (they're in Always-On Knowledge) | Pending |
| E17 | Env unset → no Candidates block | `unset AI_KNOWLEDGE_DIR`; exec | Section absent | Pending |
| E18 | Malformed yml in on-demand category skipped + warn | Mixed: valid on-demand + malformed | Valid category loads; warning emitted; exit 0 | Pending |

#### Per-repo opt-in gate (cross-cutting)

| # | Test Case | Steps | Expected Result | Status |
|---|-----------|-------|-----------------|--------|
| E19 | Opt-in gate absent → both loading paths inactive | `$AI_KNOWLEDGE_DIR` valid, mixed categories, NO `.claude/knowledge-enabled` marker. Extract + exec | No `## Always-On Knowledge` and no `## On-Demand Knowledge Candidates` section in output; zero warnings | Pending |
| E20 | Opt-in gate present → both paths activate | Same fixture, marker present | Both sections emitted as appropriate | Pending |

### Regression

| # | Test Case | Steps | Expected Result | Status |
|---|-----------|-------|-----------------|--------|
| R1 | Existing validate output unchanged | `./scripts/test.sh` full suite pre- and post-change on fixtures/valid-feature-dir | Byte-identical matrix | Pending |
| R2 | T000003's 11 assertions still pass | Run existing T000003 regression block | All pass | Pending |

## Verification Steps

- [ ] Manual diff of SKILL.md — section order: Knowledge Resolution → Knowledge Helpers → Knowledge Loading → On-Demand Matching, before Template Registry
- [ ] Claude-facing always-on instruction is explicit enough that the E2E canary test can actually trigger Reads
- [ ] Claude-facing on-demand instruction explicit on tokenization + match + Read sequence; verifiable by canary E2E
- [ ] Candidates block is machine-readable (stable per-category key/value layout for test assertions)
- [ ] Manual E2E in a real Claude Code session: prompts containing triggers cause Claude to Read matched paths (verifiable by asking Claude to cite canary strings)
- [ ] Prior-turns scope decision documented in SKILL.md (Claude should only tokenize the latest user message)
- [ ] Security callout explicit about knowledge file content being trusted input (same as any Read)
- [ ] WORKFLOW.md schema example is copy-pasteable (no stray placeholders)
- [ ] Bash parser rejects obviously invalid yml without crashing
- [ ] Implementation keeps the resolution block untouched (T000003's change is not reverted or reshaped)
- [ ] Helper spec grammar documented in header comment
- [ ] Canary string format documented and shared between always-on and on-demand tests (single source: the `CANARY_<category>_<file>` format from the shared fixture builder)
- [ ] No files committed under `skills/company-workflow/fixtures/`
- [ ] All new Tier 1 assertions run under 5 seconds (pre-commit hook viable)
- [ ] Match log text captured as a test fixture so regressions are loud
- [ ] Helper contract doc in WORKFLOW.md matches the actual bash (no drift)

## Environments Tested

| Environment | Build | Result |
|------------|-------|--------|
| macOS (dev) | local | Pending |
| Linux CI | branch build | Pending |
