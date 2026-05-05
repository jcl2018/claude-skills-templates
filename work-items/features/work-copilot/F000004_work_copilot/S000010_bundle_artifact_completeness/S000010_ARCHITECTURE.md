---
type: architecture
parent: S000010_bundle_artifact_completeness
feature: F000004_work_copilot
title: "Bundle Artifact Completeness — Architecture"
version: 1
status: Draft
date: 2026-04-26
author: chjiang
prd: PRD.md
reviewers: []
---

## Overview

This story closes the artifact-completeness gap between `work-copilot/`
and `skills/company-workflow/` by mirroring one top-level file
(`WORKFLOW.md`) plus four directory trees (`reference/`, `philosophy/`,
`examples/`, `fixtures/`) byte-identically into the bundle. The mirror is
enforced by `scripts/validate.sh` Error check 10 (extended to a
config-driven `MIRROR_SPECS` array in T000011 — sibling task, not part of
this story's code).

The architectural through-line: **the mirror operation is structurally one
design, not five.** Every mirror entry is the same operation (copy from
source, verify with `cmp -s`, register in sync check). What differs is the
glob shape (single file, flat-glob, recursive-glob) and the source/dest
paths. T000011 owns the sync-check generalization; this story owns the
content the check runs against.

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│              skills/company-workflow/                    │
│  (source of truth — Claude Code skill)                  │
│                                                          │
│   WORKFLOW.md ───────────────┐                           │
│   reference/guide-*.md ──────┤                           │
│   philosophy/rationale-*.md ─┤                           │
│   examples/example-*.md ─────┤                           │
│   fixtures/(flat + nested) ──┤                           │
│                              │                           │
└──────────────────────────────┼───────────────────────────┘
                               │ scripts/validate.sh
                               │ Error check 10 (extended in T000011):
                               │  for spec in MIRROR_SPECS:
                               │    cmp -s src dst  → fail on drift
                               ▼
┌─────────────────────────────────────────────────────────┐
│                    work-copilot/                         │
│  (Copilot-side mirror — bundle root)                    │
│                                                          │
│   WORKFLOW.md ◄──────────────┐                           │
│   reference/guide-*.md ◄─────┤                           │
│   philosophy/rationale-*.md ◄┤                           │
│   examples/example-*.md ◄────┤                           │
│   fixtures/(flat + nested) ◄─┤  byte-identical           │
│   instructions/copilot-     │                            │
│     instructions.md         │  (points at bundle paths)  │
│                              │                           │
└──────────────────────────────┼───────────────────────────┘
                               │ scripts/copilot-deploy.py install
                               │  bundle_dir.rglob("*")
                               │  → routes to <target>/.github/work-copilot/
                               ▼
┌─────────────────────────────────────────────────────────┐
│           <target>/.github/work-copilot/                 │
│  (installed bundle — what Copilot reads)                │
│   (mirrors work-copilot/ structure)                     │
└─────────────────────────────────────────────────────────┘
```

### Components Affected

| Component | Repo | Change Type | Description |
|-----------|------|------------|-------------|
| `work-copilot/WORKFLOW.md` | claude-skills-templates | New | Top-level mirror of `skills/company-workflow/WORKFLOW.md` |
| `work-copilot/reference/` | claude-skills-templates | New | Directory mirror of `skills/company-workflow/reference/` (7 `guide-*.md` files) |
| `work-copilot/philosophy/` | claude-skills-templates | New | Directory mirror of `skills/company-workflow/philosophy/` (3 `rationale-*.md` files) |
| `work-copilot/examples/` | claude-skills-templates | New | Directory mirror of `skills/company-workflow/examples/` (14 `example-*.md` files) |
| `work-copilot/fixtures/` | claude-skills-templates | Modified | Add 3 missing flat files + 1 missing nested file; resolve drift on 1 nested file |
| `work-copilot/instructions/copilot-instructions.md` | claude-skills-templates | Modified | Add "Bundle layout" pointer section listing the new artifact paths; stays ≤8192 bytes |
| `scripts/copilot-deploy.py` | claude-skills-templates | None | No change required (auto-pickup via `rglob("*")` — verified plan-eng-review D1) |
| `scripts/test.sh` | claude-skills-templates | Modified | Extend round-trip test with new install spot-checks (5 files, 1 per new bundle dir) + 1 DRIFT-detection negative case + budget guard |
| `scripts/validate.sh` Error check 10 | claude-skills-templates | Modified | Owned by **T000011**, not this story. Extended to a config-driven `MIRROR_SPECS` array iterating all mirror entries |
| `work-copilot/copilot-artifact-manifests.json` | claude-skills-templates | None | No change required — manifest indexes work-item artifact types, not bundle-internal directories (verified in PRD authoring per Open Question #2) |
| `skills/company-workflow/company-artifact-manifests.json` | claude-skills-templates | Modified | Description field updated to name both audiences (Claude Code + Copilot); content stays byte-identical to `work-copilot/copilot-artifact-manifests.json` after the description unification (per design D4) |

### Data Flow

The data flow is the same for every mirror entry (1 → 4):

1. **Author**: maintainer edits `skills/company-workflow/<artifact>` (the source of truth).
2. **Mirror**: maintainer copies the change to `work-copilot/<artifact>` (manual `cp` until automation is added — out of scope).
3. **Verify**: `scripts/validate.sh` Error check 10 runs `cmp -s` on each pair in `MIRROR_SPECS`. Exits non-zero on any drift, naming the diverged pair.
4. **Install**: `python scripts/copilot-deploy.py install <target>` copies the bundle (including all mirror artifacts) into `<target>/.github/work-copilot/`. New artifacts are picked up automatically by `bundle_dir.rglob("*")`.
5. **Read**: Copilot Chat in the target repo reads `.github/copilot-instructions.md` as ambient context; when prompted with a procedural / how-to / rationale / example question, it follows the path references in the "Bundle layout" section to `.github/work-copilot/<artifact>` and cites that file in its answer.

## API Changes

### New APIs

None at the code level. The new "API surface" is the file-path contract:
each mirror artifact's bundle-relative path is part of the bundle's
contract with installed targets and with the sync check.

| API | Signature | Description |
|-----|-----------|-------------|
| `work-copilot/WORKFLOW.md` | (file path) | Top-level procedural backbone, on-demand read by Copilot |
| `work-copilot/reference/guide-{topic}.md` | (file path pattern) | How-to guides per artifact type |
| `work-copilot/philosophy/rationale-{topic}.md` | (file path pattern) | Rationale notes per design surface |
| `work-copilot/examples/example-{type}.md` | (file path pattern) | Reference example artifacts |

### Modified APIs

None. `scripts/copilot-deploy.py` install/doctor/remove signatures are
unchanged; behavior expands automatically because `rglob("*")` walks the
new artifacts.

## Dependencies

| Dependency | Type | Status | Notes |
|-----------|------|--------|-------|
| `scripts/validate.sh` Error check 10 (existing) | Code | Available | Owns the single-mirror-dir check today; extended by T000011 |
| `scripts/copilot-deploy.py` (existing) | Code | Available | Routes via `rglob("*")` — no change required |
| `skills/company-workflow/WORKFLOW.md` | Content | Available | Source of truth for the top-level mirror |
| `skills/company-workflow/{reference,philosophy,examples,fixtures}/*.md` | Content | Available | Source of truth for the directory mirrors |
| T000011_validate_sync_check_extension | Feature | Pending (sibling task) | The extended `MIRROR_SPECS` array enforcing byte-identity on every mirror entry. **Story #5 acceptance depends on T000011 landing.** |
| Copilot 8 KB context budget for `copilot-instructions.md` | Platform | Fixed | Treat as a hard constraint; current size 5158 bytes; expected post-v2 ~5658 bytes |

## Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| Copilot doesn't follow path references in `copilot-instructions.md` and answers from training instead | Med | High | S000010 manual E2E (4 queries, one per new dir) on the Windows work box. If citations don't land, fall back to inlining critical pointers within the 8 KB budget; if even that fails, file as a follow-up risk on the knowledge-integration design |
| 8 KB budget overrun on `copilot-instructions.md` after pointer additions | Low | Med | Comfortable headroom (~3 KB); add `wc -c` CI guard if not already present (PRD Story #10) |
| Pre-existing files in `<target>/.github/reference/`, `.github/philosophy/`, `.github/examples/` collide with installer | Low | Med | Extend F000004 v1 risks-row 4 policy ("refuse to clobber non-bundle files without `--overwrite`") to the new mirror dirs. **Note:** the bundle installs under `.github/work-copilot/`, not `.github/<dir>` directly, so collision risk is lower than v1's at-the-root collision risk. Document in installer behavior |
| Mirror drift goes unnoticed because T000011 lands late | Low | High | Story #5 acceptance is gated on T000011; the two land together in v0.15.0 |
| Sync check gets accidentally weakened during T000011 generalization (e.g., recursive glob skips `.gitkeep` files in fixtures and false-passes) | Med | Med | T000011's TEST-SPEC carries 9 negative-path synthetic cases (3 shapes × 3 failure modes) plus 1 happy-path case; TDD-style |

## Design Decisions

| Decision | Chosen | Rejected Alternative | Why |
|----------|--------|---------------------|-----|
| Mirror byte-identically vs. fork content per runtime | Mirror byte-identically (sync check enforced) | Maintain Copilot-flavored copies that diverge over time | Same rationale as F000004 v1 Decision #7 (templates): one spec, two runtimes; inventing parallel content guarantees drift. Maintenance cost of one source < two |
| Decompose by concern (1 story + 1 task — Approach B) | 1 story for bundle expansion, 1 task for sync-check extension | Approach A (4 stories, one per artifact category) | Mirror operation is structurally one design; 4 near-identical PRDs would multiply scaffolding without signal. Mirrors F000003's actual decomposition (2 stories, not one per template dir) |
| Decompose by concern (1 story + 1 task — Approach B) | 1 story for bundle expansion, 1 task for sync-check extension | Approach C (single task, no story scaffolding) | Tasks don't carry PRD/ARCHITECTURE in the personal-workflow manifest. The bundle would lose the structural "why these dirs exist" docs Copilot itself reads on the work box, defeating part of the realignment's purpose |
| Sync-check pattern locked to `src-pattern:dst-pattern` config-driven array (`MIRROR_SPECS`) | Single composite check iterating an array | 4 sibling checks (one per mirror dir) | Single check = one place to fix bugs; future mirror dirs (e.g., when knowledge integration ships) get added as one new line, no other changes |
| Manifest pair: same description, different filenames | `company-artifact-manifests.json` + `copilot-artifact-manifests.json` with byte-identical content after a unified description naming both audiences | Rename one to match the other | Filenames are part of each runtime's contract: `company-workflow validate` reads `company-artifact-manifests.json`; `validate.prompt.md` reads `copilot-artifact-manifests.json`. Renaming would break one runtime |
| `bin/` not mirrored | Absent from `work-copilot/`; no Copilot-side analog | Mirror as inert reference | Copilot has no shell execution at prompt time; mirrored shell scripts would be dead weight. `bin/knowledge-helpers.sh` is part of the deferred knowledge-integration redesign — no port path that lives outside that follow-up |
| Knowledge integration deferred | Out of scope for v2; follow-up feature | Bundle a Copilot-native knowledge port into v2 | Needs a real design pass (instruction-only? `.github/knowledge-index.md`? per-category READMEs?); v2 is too narrow to settle. Carving it out keeps v2 shippable on the realignment timeline |
| Source of truth stays in `work-copilot/instructions/` for `copilot-instructions.md` | Copy on install (current v1 model) | Auto-generate from `WORKFLOW.md` | Simpler + reviewable. Auto-generation can come later if drift becomes real (v1 Decision #6) |
| `scripts/copilot-deploy.py` requires no code change | Verified `rglob("*")` already routes new artifacts | Add per-dir routing rules | Auto-pickup via `rglob("*")` is the simplest correct behavior; per-dir rules would be a regression toward fragility (verified plan-eng-review D1, 2026-04-26) |
