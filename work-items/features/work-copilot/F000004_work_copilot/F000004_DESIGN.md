---
type: design
parent: F000004_work_copilot
title: "work-copilot — Feature Design (Plan)"
version: 2.1
status: Approved
date: 2026-04-26
author: chjiang
reviewers: ["autoplan-2026-04-26 (CEO + Eng + DX dual voices)"]
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
[roadmap](F000004_ROADMAP.md) for the delivery timeline + dependency graph.

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
| 12 | Recursive mirror shape uses `find -print0`, not bash `**/*.md` (autoplan D2, 2026-04-26) | Verified `bash --version` on dev box shows 3.2.57 — `**` expands as `*` (single level only) without `shopt -s globstar` (bash 4+). `find -name '*.md' -print0 \| while IFS= read -r -d ''` is portable to bash 3.2 + 4 + zsh, handles spaces/hidden/symlinks predictably, requires no platform gate |
| 13 | Mirror orphans FAIL (not WARN) for new authoritative mirrors (autoplan D3, 2026-04-26) | `reference/`, `philosophy/`, `examples/`, `fixtures/`, `WORKFLOW.md` are upstream-derived; stale bundle copies served to Copilot defeat v2's purpose. Templates retain WARN-only for v1 backward compatibility (existing pre-v2 behavior) |
| 14 | `copilot-deploy.py doctor`/`remove` get a `Path.resolve().is_relative_to(target.resolve())` check (autoplan D4, 2026-04-26) | Defense-in-depth on a file-deleting tool. Lines 183-191 (doctor) and 227-230 (remove) currently trust `install-manifest.json` `entry["dest"]` without normalization. v2 widens the mirror surface; ~10 lines of Python folds into v0.15.0. Supersedes "no installer code change required" assertion |
| 15 | Manifest pair sync exempts the `description` field, asserts schema parity instead of byte-identity (autoplan D5, 2026-04-26) | No code in repo grep-consumes the `description` field (verified by Codex). Forcing byte-identity is test-driven coupling, not product value. Sync check parses both manifests, diffs with `description` stripped (~15 lines bash + jq). Supersedes Decision #11's "manifest pair sync (locked in plan-eng-review D4): both manifests get the same `description` field" |

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

Milestones (from [F000004_ROADMAP.md](F000004_ROADMAP.md)):

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

### v2 gating preconditions (added by autoplan 2026-04-26 per CEO premise gate)

Both CEO dual voices (Claude subagent + Codex) independently flagged that the v2 plan rests on an unverified meta-premise: "Copilot follows path references in `copilot-instructions.md` to mirrored bundle files when prompted." User accepted **Option A**: gate v2 implementation on these two preconditions completing first.

- [ ] **Citation spike (30-min CC)** on the Windows work box: reference one mirrored file (e.g., `WORKFLOW.md`) inline in `copilot-instructions.md`, ask the 4 PRD acceptance questions (procedural / how-to-write-doc / rationale / example), record whether Copilot cites the bundle file by path or answers from training. Outcome decides whether the byte-mirror approach holds or whether to fall back to inlining critical content within the 8 KB budget (the Story #11 hedge per autoplan DX5 already inlines 1-2 quoted sentences as a partial fallback).
- [ ] **S000009 Windows-box live E2E completes** (the existing outstanding acceptance criterion). v2 expanded the bundle scope; v1 must be proven before v2 work begins.

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
- Roadmap: [F000004_ROADMAP.md](F000004_ROADMAP.md)
- Source of truth (parity target): [F000003_DESIGN.md](../F000003_company_workflow/F000003_DESIGN.md), [skills/company-workflow/](../../../skills/company-workflow/)
- Bundle root: [work-copilot/](../../../work-copilot/)
- Sync-check anchor: [scripts/validate.sh](../../../scripts/validate.sh) — Error check 10
- Personal-workflow templates (used for v2 scaffolding): [templates/personal-workflow/](../../../templates/personal-workflow/)
- Manifest schema (Copilot side): [work-copilot/copilot-artifact-manifests.json](../../../work-copilot/copilot-artifact-manifests.json)
- v2 originating office-hours design (APPROVED 2026-04-26): `~/.gstack/projects/jcl2018-claude-skills-templates/chjiang-feat-v1-cut-design-20260426-024148.md`
- v2.1 autoplan review test-plan addendum (Eng phase): `~/.gstack/projects/jcl2018-claude-skills-templates/feat-v1-cut-eng-review-test-plan-20260426-224201.md`
- v2.1 autoplan restore point: `~/.gstack/projects/jcl2018-claude-skills-templates/feat-v1-cut-autoplan-restore-20260426-182224.md`

## v2.1 Autoplan Amendments (2026-04-26)

`/autoplan` ran on the v2 plan packet on 2026-04-26 with dual voices (Claude
subagent + Codex) across CEO, Eng, and DX phases. Cross-phase themes:

- **Theme A — Citation premise unverified** (6/6 voices independently). Resolved
  via gating preconditions added to the v2 Definition of Done (citation spike +
  S000009 Windows E2E).
- **Theme B — bash 3.2 globstar broken on dev box** (Eng + DX, Codex verified
  bash 3.2.57 on dev box). Resolved via Decision #12 (`find -print0`).
- **Theme C — Knowledge integration is the high-leverage piece, deferred** (CEO
  only). Acknowledged; out of scope for v2 by Decision #9. Forward pointer to
  follow-up feature (F000005, TBD scheduled).
- **Theme D — Path traversal in `copilot-deploy.py`** (Eng + DX, Codex line
  refs). Resolved via Decision #14.
- **Theme E — Documentation IA gap** (DX only). Resolved via DX1-DX7
  implementation checklist added to S000010 scope.

Auto-approved DX scope expansions (each <30 min CC effort, in radius):

- DX1: Python 3.8 version guard at `copilot-deploy.py:main()`
- DX2: `work-copilot/README.md` quickstart (~30 lines: prereqs + install + use + troubleshoot + upgrade)
- DX3: `--dry-run` flag on `install` + `remove`
- DX4: `argparse.RawDescriptionHelpFormatter` + `description=__doc__`
- DX5: Inline 1-2 quoted sentences from `WORKFLOW.md` into "Bundle layout"
  section as citation-failure hedge (~200 bytes; within 8 KB budget)
- DX6: Troubleshooting docs for "Copilot doesn't recognize /validate" + "Copilot
  ignores bundle"
- DX7: v0.15.0 release note covering re-install drift on prior-experiment files

Eng test-plan addendum (10 gaps identified; G1-G4 must land in v0.15.0; G5-G10
should land in T000011/S000010; G11-G13 deferred). See Pointers for the file path.

`/autoplan` taste decisions (4) + user challenge (1) all resolved. Plan packet
locked at v2.1.
