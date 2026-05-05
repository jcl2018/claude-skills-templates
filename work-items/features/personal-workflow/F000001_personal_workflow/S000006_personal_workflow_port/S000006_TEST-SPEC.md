---
type: test-spec
parent: S000006
feature: F000001_personal_workflow
title: "personal-workflow-port — Test Specification"
version: 1
status: Draft
date: 2026-04-20
author: chjiang
prd: PRD.md
architecture: ARCHITECTURE.md
reviewers: []
---

<!-- Scope: ENTIRE S000006 user story. Because this is a parity port, most test cases
     are "same as T000003/T000006 but pointed at personal-workflow/SKILL.md" — the
     matrix below maps each AC to the parallel company-workflow case to make the
     mirroring explicit. -->

## Test Matrix

| # | Tag | Test Case | AC | Precondition | Steps | Expected Result | Priority | Type |
|---|-----|-----------|-----|-------------|-------|-----------------|----------|------|
| 1 | core | Resolution: valid env var sets `$_KNOWLEDGE_DIR` | Story #1 | `AI_KNOWLEDGE_DIR=/tmp/k` (existing dir) | Source personal-workflow/SKILL.md resolution block | `$_KNOWLEDGE_DIR == /tmp/k`; no stderr; exit 0 | P0 | Unit |
| 2 | core | Resolution: unset env var → one warning | Story #2 | `unset AI_KNOWLEDGE_DIR` | Source resolution block | Exactly one stderr line naming `AI_KNOWLEDGE_DIR`; exit 0; `$_KNOWLEDGE_DIR == ""` | P0 | Unit |
| 3 | core | Resolution: empty env var → one warning | Story #2 | `AI_KNOWLEDGE_DIR=""` | Source resolution block | Same as case 2 | P0 | Unit |
| 4 | core | Resolution: missing path → one warning with sanitized path | Story #2 | `AI_KNOWLEDGE_DIR=/nonexistent` | Source resolution block | One stderr line mentioning `/nonexistent`; exit 0; `$_KNOWLEDGE_DIR == ""` | P0 | Unit |
| 5 | core | Resolution: path is a file, not a directory → warning | Story #2 | `AI_KNOWLEDGE_DIR=/tmp/f` where `/tmp/f` is a regular file | Source resolution block | One stderr line mentioning "not a directory"; exit 0 | P0 | Unit |
| 6 | security | Resolution: control chars + >200-char path sanitized in warning | Story #2 | `AI_KNOWLEDGE_DIR=$(printf '/bad\n\e[31mpath')` | Source resolution block | Warning contains no control chars; if >200 chars, truncated with `...`; exactly one line | P0 | Unit |
| 7 | core | Loading: always-on category injected | Story #3 | Fixture: `$k/coding/.knowledge.yml {surface: always}` + `$k/coding/a.md` + `$k/coding/sub/b.md`; opt-in marker present | Run loading block | Emits `## Always-On Knowledge` section listing a.md then sub/b.md (lexical order) | P0 | Integration |
| 8 | core | Loading: on-demand category appears in candidates block | Story #4 | Fixture: category with `surface: on-demand, triggers: ["pricing engine"]`; opt-in marker present | Run loading block | Emits `## On-Demand Knowledge Candidates` block listing the category, its triggers, and its files | P0 | Integration |
| 9 | core | Loading: category with no `.knowledge.yml` is dark | Story #3 | Category dir exists; no `.knowledge.yml`; opt-in marker present | Run loading block | Category not listed in always-on nor on-demand candidates; no warning | P0 | Integration |
| 10 | resilience | Loading: malformed `.knowledge.yml` skipped with warning | PRD AC line (resilience) | Two categories — one valid, one malformed yml; opt-in marker present | Run loading block | Valid category loads as declared; one stderr warning names the bad file; exit 0; sibling unaffected | P0 | Integration |
| 11 | security | Opt-in gate: marker absent → no loading | Story #5 | `$_KNOWLEDGE_DIR` valid + categories configured; NO `.claude/knowledge-enabled` | Run loading block | Neither `## Always-On Knowledge` nor `## On-Demand Knowledge Candidates` emitted; S000004 resolution warning still fires if env var misconfigured | P0 | Integration |
| 12 | resilience | Zero regression: `/personal-workflow check` output unchanged | Story #6 | Unset env var; no opt-in marker; existing work-items/ tree | Run `/personal-workflow check` against the pre-port baseline | stdout byte-identical; stderr contains only the AI_KNOWLEDGE_DIR warning; exit code unchanged | P0 | E2E |
| 13 | observability | Diagnostic line naming matched categories and triggers | Story #7 | On-demand category loaded via trigger match | Run loading block with matching prompt | Diagnostic line like `[knowledge] matched: <category> via <trigger>` emitted (format matches company-workflow) | P1 | Integration |
| 14 | usability | WORKFLOW.md §Knowledge Configuration reads correctly for personal-only users | Story #8 | Fresh read of `skills/personal-workflow/WORKFLOW.md` | grep for `/company-workflow` in the Knowledge Configuration section | Zero matches (all command refs say `/personal-workflow`); F000004 backlink present | P1 | Unit |

## Test Tiers

### Tier 1: Smoke Tests (automated, no live execution)

| # | Tag | Check | What It Validates | Script/Command |
|---|-----|-------|-------------------|---------------|
| S1 | core | `skills/personal-workflow/SKILL.md` contains `## Knowledge Resolution` header | Block was actually copied | `grep -Fq '## Knowledge Resolution' skills/personal-workflow/SKILL.md` |
| S2 | core | `skills/personal-workflow/SKILL.md` contains `## Knowledge Loading` header | Loading block copied | `grep -Fq '## Knowledge Loading' skills/personal-workflow/SKILL.md` |
| S3 | core | Resolution block references `AI_KNOWLEDGE_DIR` (not some renamed variable) | No accidental renames | `grep -c 'AI_KNOWLEDGE_DIR' skills/personal-workflow/SKILL.md` >= 1 |
| S4 | security | Warning text in personal-workflow's block writes to stderr (`>&2`) | Doesn't pollute stdout | Static grep for `>&2` inside the Knowledge Resolution fenced block |
| S5 | usability | Command-name references inside the two new blocks say `/personal-workflow` (not `/company-workflow`) | Skill-name strings adapted | grep-based assertion: no `/company-workflow` string inside the Knowledge Resolution + Knowledge Loading sections |
| S6 | core | `skills/personal-workflow/WORKFLOW.md` contains `## Knowledge Configuration` header | Docs section added | `grep -Fq '## Knowledge Configuration' skills/personal-workflow/WORKFLOW.md` |
| S7 | usability | WORKFLOW.md Knowledge Configuration section references `/personal-workflow` in prose | Docs adapted, not copy-paste | grep for `/company-workflow` inside the section → zero hits |
| S8 | core | `scripts/test.sh` contains a T000007 test block header | Test block added | `grep -Fq 'T000007' scripts/test.sh` |
| S9 | core | T000007 test block sources `scripts/test-helpers/knowledge.sh` | Reuses shared fixture builder | `grep -c 'scripts/test-helpers/knowledge.sh' scripts/test.sh` >= 2 (T000006 + T000007) |
| S10 | resilience | `personal-artifact-manifests.json` unchanged by this port | Runtime concern didn't leak into scaffolding | `git diff main -- skills/personal-workflow/personal-artifact-manifests.json` is empty |
| S11 | resilience | `skills/company-workflow/SKILL.md` unchanged by this port | Port is additive | `git diff main -- skills/company-workflow/SKILL.md` is empty |
| S12 | core | Block ordering in `skills/personal-workflow/SKILL.md` is: Path Resolution → Stale Rules Detection → Knowledge Resolution → Knowledge Loading → Overview | Section order pinned | Parse headers and assert sequence |

### Tier 2: E2E Tests (real end-to-end execution)

| # | Tag | Scenario | Steps (as a real user would) | Expected Outcome | Rubric |
|---|-----|----------|----------------------------|-----------------|--------|
| E1 | core | User sets env var and invokes /personal-workflow in an opted-in repo | 1. `export AI_KNOWLEDGE_DIR=/tmp/k` with a fixture<br>2. `touch $repo/.claude/knowledge-enabled`<br>3. Run `/personal-workflow check`<br>4. Inspect what Claude "sees" via a canary string in the fixture | Claude's context includes the canary string (proves always-on loading reached the model) | Pass if canary retrievable; fail if missing |
| E2 | security | User has global env var pointing at work knowledge, opens a personal repo with no opt-in marker | 1. `export AI_KNOWLEDGE_DIR=/work-knowledge`<br>2. Open a repo with NO `.claude/knowledge-enabled`<br>3. Run `/personal-workflow check`<br>4. Try to prompt Claude about a work-knowledge canary | Canary NOT accessible to Claude; no always-on section emitted; no on-demand candidates | Pass if canary unreachable |
| E3 | core | User declares on-demand triggers, prompt matches | 1. Fixture with `surface: on-demand, triggers: [pricing engine]` + canary<br>2. Opt-in marker present<br>3. Ask Claude "walk me through the pricing engine" | Claude can cite the canary from the on-demand file | Pass if canary surfaced |
| E4 | core | Same setup as E3 but prompt does NOT match triggers | 1. Same fixture as E3<br>2. Ask Claude an unrelated question | Canary NOT surfaced | Pass if canary absent |
| E5 | resilience | Zero-regression check | 1. Fresh clone; no env var; no marker<br>2. Run `/personal-workflow check` on the repo's existing work-items/<br>3. Compare output vs. a baseline file captured before the port | stdout byte-identical; stderr only differs by the new AI_KNOWLEDGE_DIR warning line | Pass if diff is only the expected warning delta |
| E6 | integration | Both skills honor the same marker in the same repo | 1. Opt-in marker present<br>2. Same env var, same fixtures<br>3. Run `/company-workflow validate` and `/personal-workflow check` back-to-back | Both emit equivalent Always-On / On-Demand sections (content parity) | Pass if both load the same files |

<!-- E2E test skill: none yet — this story reuses the company-workflow E2E harness
     built in S000005's T000006 with the SKILL variable flipped to personal-workflow. -->

## Coverage Gaps

| Gap | Why Not Tested | Risk Accepted |
|-----|---------------|---------------|
| Interactive "skill invocation" test that proves Claude Reads the emitted paths | Requires a live LLM run — gated to manual/rubric-scored per company-workflow's T000006 convention | Static + bash-layer tests give high confidence; Claude-layer behavior is the same as company-workflow's (same bash output → same Claude behavior) |
| Drift detection between the two skills' duplicated bash | v1 explicitly accepts drift (P2 Story #9 defers the extraction refactor) | If bash drifts, first user report surfaces it; low-traffic enough that the cost of a helper refactor is not yet worth paying |
| Performance: total skill bootstrap time with knowledge loading on both skills | Orthogonal to this port — S000005 covers always-on byte cap; personal-workflow inherits it | If the cap is wrong, it's wrong in both skills and S000005 fixes it once |
| Localization / non-UTF-8 knowledge file names | Out of scope for F000004 as a whole | Matches company-workflow's coverage |
| Windows path handling in the opt-in marker lookup | Out of scope for F000004 as a whole | Shell assumptions match company-workflow's |
