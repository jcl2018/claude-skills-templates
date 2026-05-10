# /autoplan Restore Point
Captured: 2026-04-26T22:22:46Z | Branch: feat/v1-cut | Commit: f2c759b

## Re-run Instructions
1. Plan packet for review consists of (uncommitted at restore time):
   - work-items/features/F000004_work_copilot/F000004_DESIGN.md (v2)
   - work-items/features/F000004_work_copilot/F000004_TRACKER.md (updated)
   - work-items/features/F000004_work_copilot/F000004_milestones.md (updated)
   - work-items/features/F000004_work_copilot/F000004_feature-summary.md (updated)
   - work-items/features/F000004_work_copilot/S000010_bundle_artifact_completeness/* (new)
2. Originating office-hours design (frozen, APPROVED 2026-04-26):
   ~/.gstack/projects/jcl2018-claude-skills-templates/chjiang-feat-v1-cut-design-20260426-024148.md
3. Re-run: invoke /autoplan after restoring plan packet to working tree state

## Original Plan State (Snapshot)

### F000004_DESIGN.md (v2)
```markdown
---
type: design
parent: F000004_work_copilot
title: "work-copilot — Feature Design (Plan)"
version: 2
status: Approved
date: 2026-04-26
author: chjiang
reviewers: []
---

## Problem

I live in Claude Code at home, but my work machine is Windows + VS Code +
GitHub Copilot. The `company-workflow` skill — which scaffolds, validates,
and ships work items — doesn't exist there. Today I either (a) don't track
work items at work, or (b) track them by hand with no validator, which means
they drift from the template and the manifest within a week.

The fix is a Copilot-native port of `company-workflow`: same templates, same
artifact manifest, same `[PASS]/[MISSING]/[DRIFT]` output, delivered as a
bundle that installs into the work repo's `.github/`.

**v1 (shipped v0.14.0, PR #43)** covered the validator core — templates +
manifest + `validate.prompt.md` + `copilot-instructions.md` +
`scripts/copilot-deploy.py` — but stopped short of full bundle parity. The
bundle is missing:

- `WORKFLOW.md` — 21 KB procedural backbone of the skill (phase guidance,
  scaffolding rules); the bundle has no analog
- `reference/` — 7 guides (`guide-architecture.md`, `guide-general.md`,
  `guide-prd.md`, `guide-rca.md`, `guide-review-notes.md`, `guide-task.md`,
  `guide-test-spec.md`)
- `philosophy/` — 3 rationale notes (`rationale-ARCHITECTURE.md`,
  `rationale-PRD.md`, `rationale-TEST-SPEC.md`)
- `examples/` — 14 example artifacts (5 trackers + 9 doc types)
- Test fixtures, 5 changes total (verified by `cmp -s`): 3 missing flat
  files (`invalid-bad-frontmatter.md`, `invalid-missing-lifecycle.md`,
  `invalid-wrong-order.md`); 1 missing nested file
  (`valid-feature-dir/DESIGN.md`); 1 currently-drifted file
  (`valid-feature-dir/TRACKER.md`)
- The entire knowledge-integration subsystem (`$AI_KNOWLEDGE_DIR` env-var
  seam, two-tier surfacing, `bin/knowledge-helpers.sh`, `knowledge-doctor`)

Work-box users get a narrower workflow than home-box users, and v1 of this
doc didn't document the gap. **v2 closes the easy gaps — bundle artifact
completeness — and explicitly defers knowledge integration to a follow-up
feature** where it can get a real Copilot-native design pass (no shell
execution, no env-var resolution at prompt time, helpers redesigned as
instructions or static indexes).

## Shape of the solution

A single bundle — `work-copilot/` — that mirrors `skills/company-workflow/`
in intent and gets stamped into target repos. The bundle behavior is
carried by Copilot surfaces:

| Claude Code analog | Copilot surface | Artifact |
|--------------------|-----------------|----------|
| `/company-workflow check` slash command | `.github/prompts/*.prompt.md` | `validate.prompt.md` |
| Always-on SKILL.md context | `.github/copilot-instructions.md` | `copilot-instructions.md` |
| Manifest + templates | `.github/work-copilot/templates/` | manifest + templates |
| `skills/company-workflow/WORKFLOW.md` (procedural backbone) | `.github/work-copilot/WORKFLOW.md` (top-level, on-demand read) | `WORKFLOW.md` |
| `skills/company-workflow/reference/` (how-to guides) | `.github/work-copilot/reference/` | `guide-*.md` |
| `skills/company-workflow/philosophy/` (rationale notes) | `.github/work-copilot/philosophy/` | `rationale-*.md` |
| `skills/company-workflow/examples/` (example artifacts) | `.github/work-copilot/examples/` | `example-*.md` |
| `skills/company-workflow/fixtures/` (validator self-tests) | `.github/work-copilot/fixtures/` | flat + nested fixtures |

Mirror artifacts beyond `templates/` are accessed by Copilot via direct
file references in prompts (no slash-command needed; Copilot reads them on
demand when answering procedural / rationale / example questions).

Children of F000004:

- **[S000007](S000007_copilot_prompt_packaging/S000007_TRACKER.md)** —
  validator prompt (`/validate`) — shipped v0.14.0
- **[S000008](S000008_template_delivery_and_install/S000008_TRACKER.md)** —
  Python 3 stdlib installer (`scripts/copilot-deploy.py`) — shipped v0.14.0
- **[S000009](S000009_always_on_instructions/S000009_TRACKER.md)** —
  `copilot-instructions.md` always-on context — file shipped v0.14.0; live
  E2E on Windows box outstanding
- **[S000010](S000010_bundle_artifact_completeness/S000010_TRACKER.md)** —
  bundle artifact completeness (v2 realignment): mirror `WORKFLOW.md`,
  `reference/`, `philosophy/`, `examples/`, missing fixtures
- **[T000011](S000010_bundle_artifact_completeness/T000011_validate_sync_check_extension/T000011_TRACKER.md)** —
  extend `validate.sh` Error check 10 to a config-driven `MIRROR_SPECS`
  array enforcing byte-identity sync on every mirror entry

They converge at milestone #11 (realignment v0.15.0 release). See
[milestones](F000004_milestones.md) for the dependency graph.

## Big decisions

The full chronological Journal lives in `F000004_TRACKER.md`. The decisions
below are the architectural through-line — the ones a future maintainer
needs to understand the shape of the bundle without reading the whole
Journal.

| # | Decision | Why |
|---|----------|-----|
| 1 | Copilot surfaces = `prompts/` + `copilot-instructions.md` + bundle dir | `.chatmode.md` requires the user to switch modes manually — kills the "just type `/validate`" UX parity |
| 2 | Installer in Python 3 stdlib, not bash or PowerShell | Python runs on Windows + macOS without branches; stdlib avoids pip (corporate proxies block it) |
| 3 | Binary-mode file reads for SHA256 | Re-runs D000005 otherwise — CRLF conversion on Windows makes checksums flap |
| 4 | Reuse `company-workflow` manifest schema 1:1 | One spec, two runtimes. Inventing a Copilot-specific schema guarantees drift |
| 5 | `copilot-instructions.md` is an *index*, not a full spec | Manifest + templates remain source of truth; instructions point at `/validate` for enforcement (≤8 KB budget) |
| 6 | Source of truth lives in `work-copilot/instructions/`, copied on install | Simpler + reviewable. Can generate from `WORKFLOW.md` later if drift becomes real |
| 7 | `validate.sh` gets a template-sync check | Prevents `work-copilot/templates/` from silently diverging from `templates/company-workflow/` |
| 8 | Mirror `WORKFLOW.md` + `reference/` + `philosophy/` + `examples/` byte-identically (and complete the partial fixtures mirror) rather than fork any of them — sync check enforces it | Matches Decision #7's template-sync rationale: one spec, two runtimes; inventing parallel content guarantees drift. v2 extends the existing sync check from one mirror dir to a config-driven list |
| 9 | Knowledge integration deferred to a follow-up feature | Copilot has no shell, no env-var seam at prompt time — needs a new design pass (instruction-only? `.github/knowledge-index.md`? pre-built per-category READMEs?) that this realignment is too narrow to settle |
| 10 | `bin/` is not mirrored — Copilot has no shell execution; `bin/knowledge-helpers.sh` goes away when knowledge integration ships its Copilot-native redesign | A mirrored `bin/` would carry shell scripts no Copilot prompt can ever call |
| 11 | Decompose v2 realignment as 1 story + 1 task (Approach B) rather than 4 sibling stories or 1 task-only unit | Mirror operation is structurally one design (copy + register in sync check), so per-artifact PRDs would multiply scaffolding without signal. Task-only loses the PRD/ARCHITECTURE Copilot itself reads on the work box. Mirrors F000003's actual decomposition shape (2 stories, not one per template dir) |

## Risks & open questions

| Risk | Next check |
|------|-----------|
| Copilot model *recalls* manifest contents instead of reading the file | S000007 prompt explicitly says "read the file, do not recall"; verify in E2E |
| Python 3.10+ actually on the work box | First Phase-2 action in S000008 — if missing, fall back to PowerShell port |
| Output format parity between Claude Code and Copilot runtimes | Ship fixtures in the bundle; manually diff outputs in E2E before declaring done |
| Pre-existing `.github/copilot-instructions.md` in target repos | Installer refuses to overwrite non-bundle files without `--overwrite` |
| `.prompt.md` format churn in future Copilot releases | Pin docs link + smoke test in installer; low likelihood but non-zero |
| 8 KB budget overrun on `copilot-instructions.md` after v2 pointer additions (current 5158 bytes; pointer paragraphs ~500 bytes) | Comfortable headroom (~3 KB). S000010 PRD settles whether budget enforcement lives in `scripts/test.sh` today or a new guard is added |
| Pre-existing files in target repo's `.github/reference/`, `.github/philosophy/`, `.github/examples/` when installer runs | Extend Risks-row 4's policy — refuse to clobber non-bundle files without `--overwrite` — to cover the new mirror dirs the same way (document in S000010 ARCHITECTURE) |
| Copilot fails to *cite* the new mirror artifacts in chat (e.g., still answers procedural questions from training, not from `WORKFLOW.md`) | S000010 TEST-SPEC manual E2E — one Copilot-cites query per new dir on the Windows box |

Open questions (track in F000004 Journal as they resolve):

1. **Where is the `copilot-instructions.md` 8 KB budget enforced today?**
   Settle in S000010 PRD authoring by either pointing at the existing
   check or adding one. If absent, S000010 adds a simple `wc -c` gate to
   `validate.sh` or `test.sh`.
2. **Does `work-copilot/copilot-artifact-manifests.json` need new entries
   for the mirror dirs?** Likely no — the manifest indexes work-item
   artifact types (feature, defect, task, user-story, review), not
   bundle-internal directories. Confirm by reading the schema once during
   S000010 PRD authoring; document in S000010_ARCHITECTURE.md.
3. **Knowledge-integration follow-up scheduling — when to spawn F000005?**
   Roadmap question, not a design question for this realignment. Track as
   a Journal entry in F000004 post-merge.

## Sequencing

Milestones (from [F000004_milestones.md](F000004_milestones.md)):

```
#1 design approved (v1, validator-only scope)
      |
      +--> #2 prompt packaging (S000007) ---+
      |                                      |
      +--> #3 template delivery (S000008) ---+--> #5 work-machine verify --> #6 ship v0.14.0 --+--> #7 symlink setup docs
      |                                      |                                                 |
      +--> #4 always-on instructions (S000009)                                                  +--> #8 two-install story / unification
                                                                                                |
                                                                                                v
                                                  +-> #9 bundle artifact completeness (S000010) -+
                                                  |                                              |
                                                  +-> #10 sync-check extension (T000011)        -+--> #11 realignment v0.15.0 release
```

Critical path for the v2 realignment: #6 (already shipped) → #9, #10
(parallel) → #11. #7 and #8 stay where they were and are independent of
the v2 realignment.

## Definition of done

The realignment is shipped when **all** of the following hold:

- [ ] `work-copilot/WORKFLOW.md` exists, byte-identical to `skills/company-workflow/WORKFLOW.md`.
- [ ] `work-copilot/reference/guide-*.md` exists with 7 files, byte-identical to `skills/company-workflow/reference/guide-*.md`.
- [ ] `work-copilot/philosophy/rationale-*.md` exists with 3 files, byte-identical to `skills/company-workflow/philosophy/rationale-*.md`.
- [ ] `work-copilot/examples/example-*.md` exists with 14 files, byte-identical to `skills/company-workflow/examples/example-*.md`.
- [ ] `work-copilot/fixtures/` contains all 5 fixtures (`invalid-bad-frontmatter.md`, `invalid-missing-lifecycle.md`, `invalid-wrong-order.md` added to existing `invalid-missing-artifact-dir/` and `valid-feature-dir/`); the drifted `valid-feature-dir/TRACKER.md` resolved.
- [ ] `scripts/validate.sh` Error check 10 iterates a config-driven list of mirror artifacts (single composite check) and enforces byte-identity sync on every entry plus the counterpart-warning loop; CI fails on drift.
- [ ] `scripts/copilot-deploy.py install` walks the new artifacts and lays them down idempotently; `doctor` reports them; `remove` cleans them up. (No code change required — installer already routes everything not in `prompts/` or `instructions/` by default; smoke test verifies this.)
- [ ] `work-copilot/instructions/copilot-instructions.md` references the new artifacts without exceeding the 8 KB budget; budget enforcement location is documented (existing `scripts/test.sh` check, or a new guard added in S000010).
- [ ] `bin/` is **not** present in `work-copilot/`; absence is intentional per Decision #10 (no Copilot shell execution).
- [ ] `S000010_bundle_artifact_completeness/` and `T000011_validate_sync_check_extension/` scaffolded with full personal-workflow artifact set; `/personal-workflow check work-items/features/F000004_work_copilot/` passes.
- [ ] The S000009 Windows-E2E acceptance criterion remains tracked separately and continues progressing (independent of v2 realignment).

The original v1 acceptance criteria (validator round-trip, install
idempotence, output parity, instruction citations) remain in force —
v2 expands the bundle, it does not loosen v1 ACs.

## Not in scope

- Porting `/personal-workflow` (lower priority — work tracking uses
  company workflow).
- Porting `/ship`, `/investigate`, `/qa`, or any other gstack skill —
  validator only.
- A GitHub Action that runs `/validate` in CI (nice-to-have; file as a
  follow-up feature if the Copilot-chat experience proves the value).
- Windows installer bootstrapping (MSI, Chocolatey, etc.) — plain
  `python scripts/copilot-deploy.py ...` is enough for v1 + v2.
- **Knowledge integration follow-up.** The `$AI_KNOWLEDGE_DIR` env-var
  seam, two-tier surfacing (always-on / on-demand), and `knowledge-doctor`
  diagnostic are explicitly deferred to a follow-up feature (likely
  F000005 — to be scheduled). Copilot has no shell and no env-var
  resolution at prompt time, so the helpers as currently implemented in
  `skills/company-workflow/bin/knowledge-helpers.sh` cannot be ported
  as-is. The follow-up feature gets its own Copilot-native design pass
  (instruction-only, static `.github/knowledge-index.md`, pre-built
  per-category READMEs — TBD).
- **`bin/` mirroring.** Follows from the knowledge-integration deferral.
  No Copilot prompt can call shell scripts at prompt time, so a mirrored
  `bin/` would be dead weight. `bin/knowledge-helpers.sh` goes away when
  the knowledge-integration follow-up ships its Copilot-native redesign;
  there is no separate decision to make for `bin/` in this realignment.

## Pointers

- Parent tracker: [F000004_TRACKER.md](F000004_TRACKER.md)
- Milestones: [F000004_milestones.md](F000004_milestones.md)
- Feature summary: [F000004_feature-summary.md](F000004_feature-summary.md)
- Source of truth (parity target): [F000003_DESIGN.md](../F000003_company_workflow/F000003_DESIGN.md), [skills/company-workflow/](../../../skills/company-workflow/)
- Bundle root: [work-copilot/](../../../work-copilot/)
- Sync-check anchor: [scripts/validate.sh](../../../scripts/validate.sh) — Error check 10
- Personal-workflow templates (used for v2 scaffolding): [templates/personal-workflow/](../../../templates/personal-workflow/)
- Manifest schema (Copilot side): [work-copilot/copilot-artifact-manifests.json](../../../work-copilot/copilot-artifact-manifests.json)
- v2 originating office-hours design (APPROVED 2026-04-26): `~/.gstack/projects/jcl2018-claude-skills-templates/chjiang-feat-v1-cut-design-20260426-024148.md`
```

### S000010 docs included by reference (see plan packet paths above)
