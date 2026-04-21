---
type: test-plan
parent: T000007
title: "port-skill-and-workflow — Test Plan"
date: 2026-04-20
author: chjiang
status: Draft
---

<!-- Scope: T000007 is one task — the parity port. Cases must be concrete and
     reproducible. Broader matrix coverage lives in the parent story's TEST-SPEC;
     this plan lists the specific assertions T000007 adds to scripts/test.sh. -->

## Scope

T000007 touches three files:

- `skills/personal-workflow/SKILL.md` — adds `## Knowledge Resolution` and `## Knowledge Loading` blocks copied from company-workflow (modulo skill-name adaptations).
- `skills/personal-workflow/WORKFLOW.md` — adds `## Knowledge Configuration` section copied from company-workflow.
- `scripts/test.sh` — adds a T000007 assertion block mirroring T000003's cases against the new personal-workflow SKILL.md.

The test plan below is the set of scripted assertions this task introduces.
Every case is runnable as part of `./scripts/test.sh` with no interactive input.

## Regression Test Cases

| # | Test Case | Steps | Expected Result | Status |
|---|-----------|-------|-----------------|--------|
| 1 | personal-workflow SKILL.md has a `## Knowledge Resolution` section | `grep -Fq '## Knowledge Resolution' skills/personal-workflow/SKILL.md` | exit 0 | Pending |
| 2 | personal-workflow SKILL.md has a `## Knowledge Loading` section | `grep -Fq '## Knowledge Loading' skills/personal-workflow/SKILL.md` | exit 0 | Pending |
| 3 | Resolution block references `AI_KNOWLEDGE_DIR` env var at least once | `grep -c 'AI_KNOWLEDGE_DIR' skills/personal-workflow/SKILL.md` ≥ 1 | ≥ 1 | Pending |
| 4 | Resolution warning writes to stderr (has `>&2`) | Section-scoped grep for `>&2` inside the Knowledge Resolution fenced code block | ≥ 1 | Pending |
| 5 | Unset env var → one stderr warning, exit 0, empty `$_KNOWLEDGE_DIR` | Source the Resolution block in a subshell with `unset AI_KNOWLEDGE_DIR`; capture stderr line count + `$_KNOWLEDGE_DIR` | 1 line; exit 0; `$_KNOWLEDGE_DIR == ""` | Pending |
| 6 | Valid env var → no warning, `$_KNOWLEDGE_DIR` populated | `AI_KNOWLEDGE_DIR=$(mktemp -d)` then source Resolution block | 0 stderr lines; `$_KNOWLEDGE_DIR == $AI_KNOWLEDGE_DIR` | Pending |
| 7 | Missing path → one warning naming the path | `AI_KNOWLEDGE_DIR=/nonexistent-$RANDOM` then source Resolution block | 1 stderr line containing the path; exit 0; `$_KNOWLEDGE_DIR == ""` | Pending |
| 8 | Path is a file, not dir → one warning mentioning "not a directory" | `AI_KNOWLEDGE_DIR=$(mktemp)` (regular file) then source Resolution block | 1 stderr line; exit 0; `$_KNOWLEDGE_DIR == ""` | Pending |
| 9 | Empty env var → one warning (same as unset) | `AI_KNOWLEDGE_DIR=""` then source Resolution block | 1 stderr line; exit 0 | Pending |
| 10 | Hostile env var (control chars + >200 chars) → warning sanitized + truncated | `AI_KNOWLEDGE_DIR=$(printf '/bad\n\e[31m%0.s' {1..50})` then source block | stderr line has no control chars, ≤200-char path prefix + `...` | Pending |
| 11 | Zero regression — existing `/personal-workflow check` stdout unchanged | Run `/personal-workflow check work-items/` with `unset AI_KNOWLEDGE_DIR` against the pre-T000007 baseline | stdout byte-identical to baseline; stderr differs only by the new AI_KNOWLEDGE_DIR warning | Pending |
| 12 | Loading: marker absent → no loading sections emitted | Fixture with categories; `rm -f .claude/knowledge-enabled`; run SKILL.md Loading block | No `## Always-On Knowledge` or `## On-Demand Knowledge Candidates` output | Pending |
| 13 | Loading: marker present + always-on category → Always-On section emitted | Fixture with `surface: always` + files; opt-in marker present | `## Always-On Knowledge` emitted listing files in lexical path order | Pending |
| 14 | Loading: marker present + on-demand category → Candidates section emitted | Fixture with `surface: on-demand, triggers: [pricing]` + files; opt-in marker present | `## On-Demand Knowledge Candidates` emitted naming category + triggers + paths | Pending |
| 15 | Loading: malformed yml → sibling categories still load | Two categories, one with broken `.knowledge.yml`; opt-in marker present | Valid category loads; one warning names the broken file; exit 0 | Pending |
| 16 | WORKFLOW.md has `## Knowledge Configuration` section | `grep -Fq '## Knowledge Configuration' skills/personal-workflow/WORKFLOW.md` | exit 0 | Pending |
| 17 | WORKFLOW.md section has zero `/company-workflow` references inside it | Extract the section between `## Knowledge Configuration` and the next `## ` header; grep for `/company-workflow` | 0 matches | Pending |
| 18 | `scripts/test.sh` contains a T000007 header comment | `grep -Fq 'T000007' scripts/test.sh` | exit 0 | Pending |
| 19 | T000007 block sources the shared helper | `grep -c 'scripts/test-helpers/knowledge.sh' scripts/test.sh` ≥ 2 | ≥ 2 (one for T000006, one for T000007) | Pending |
| 20 | No change to `personal-artifact-manifests.json` | `git diff main -- skills/personal-workflow/personal-artifact-manifests.json` | empty | Pending |
| 21 | No change to `skills/company-workflow/SKILL.md` | `git diff main -- skills/company-workflow/SKILL.md` | empty | Pending |
| 22 | `./scripts/test.sh` full run passes | `./scripts/test.sh` | exit 0 | Pending |

## Verification Steps

- [ ] Local build succeeds (macOS + Linux)
- [ ] `./scripts/test.sh` passes end-to-end with all 22 new cases green
- [ ] `/personal-workflow check` on `work-items/features/F000004_knowledge_integration/` returns clean validation
- [ ] Manual spot-check: set `AI_KNOWLEDGE_DIR` + drop `.claude/knowledge-enabled` in a fixture repo; invoke `/personal-workflow` and `/company-workflow` back-to-back; confirm they emit equivalent Always-On / On-Demand content
- [ ] Diff the final `skills/personal-workflow/SKILL.md` Resolution + Loading blocks against `skills/company-workflow/SKILL.md` — the only delta should be the `/company-workflow` → `/personal-workflow` skill-name strings
- [ ] Code review checklist item: flag any attempt to rename the section headers (`## Knowledge Resolution`, `## Knowledge Loading`) — they must match across skills

## Environments Tested

| Environment | Build | Result |
|------------|-------|--------|
| macOS (zsh) | local branch | Pending |
| Linux CI | GitHub Actions on PR | Pending |
