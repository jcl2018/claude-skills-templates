---
type: roadmap
parent: F000004
title: "work-copilot — Roadmap"
date: 2026-04-26
author: chjiang
status: Draft
---

<!-- Migrated from F000004_feature-summary.md + F000004_milestones.md during
     F000008 v1.5.0 sweep. Section content preserved verbatim from the
     two source files for historical fidelity. The new doc-ROADMAP.md
     template suggests Scope / Non-Goals / Success Criteria / Decomposition
     / Delivery Timeline (with Delivery History sub-section) / Dependency
     Graph / Open Questions; refine over time as needed. -->

<!-- ===== From F000004_feature-summary.md ===== -->

## Scope

`work-copilot/` is a portable GitHub Copilot bundle that mirrors the intent of
`skills/company-workflow/` for users on a Windows work machine where Claude Code
isn't available. **v1 (shipped v0.14.0, PR #43)** delivered the validator core:
templates, an artifact manifest, validation instructions, and `.prompt.md`-style
slash-command equivalents, packaged into a `.github/`-installable bundle composed
of `copilot-instructions.md` (always-on context) plus `.prompt.md` files. Zero
dependency on Claude Code, gstack, or any Anthropic-specific tooling. Installation
handled by `scripts/copilot-deploy.py` (Python 3 stdlib only — no bash assumption).

**v2 (in flight, per design doc 2026-04-26)** closes the artifact-completeness
gap between the bundle and the upstream skill: `WORKFLOW.md` (procedural backbone),
`reference/` (7 how-to guides), `philosophy/` (3 rationale notes), `examples/`
(14 example artifacts), and the missing fixtures (5 changes, verified `cmp -s`)
all get mirrored byte-identically into `work-copilot/`. `scripts/validate.sh`
Error check 10 is extended from a single template-sync check to a config-driven
`MIRROR_SPECS` array enforcing byte-identity on every mirror entry. Knowledge
integration (`$AI_KNOWLEDGE_DIR`, two-tier surfacing, `bin/knowledge-helpers.sh`)
is explicitly deferred to a follow-up feature where it gets a real Copilot-native
design pass.

## Success Criteria

### v1 — validator core (shipped v0.14.0)

- [x] `work-copilot/` directory contains a portable bundle that mirrors the intent of `skills/company-workflow/`: templates, artifact manifest, validation instructions, reference guides
- [x] The bundle installs into a target repo's `.github/` directory as a `copilot-instructions.md` file plus `.prompt.md` prompt files
- [ ] A GitHub Copilot user in the target repo can invoke the equivalent of `/company-workflow check` via a Copilot prompt/chat mode and get [PASS]/[MISSING]/[DRIFT] output on work items — pending live E2E on the Windows work box (S000009)
- [ ] Installation works on a Windows work machine with Copilot — pending Windows-box install (S000009)
- [x] Zero dependency on Claude Code, gstack, or any Anthropic-specific tooling — the bundle is Copilot-native
- [x] `scripts/copilot-deploy.py install <target-repo>` copies the bundle into `<target-repo>/.github/` idempotently

### v2 — bundle artifact completeness (in flight)

- [ ] `work-copilot/WORKFLOW.md` exists, byte-identical to `skills/company-workflow/WORKFLOW.md`
- [ ] `work-copilot/reference/guide-*.md` exists with 7 files, byte-identical to upstream
- [ ] `work-copilot/philosophy/rationale-*.md` exists with 3 files, byte-identical to upstream
- [ ] `work-copilot/examples/example-*.md` exists with 14 files, byte-identical to upstream
- [ ] `work-copilot/fixtures/` has all 5 missing/drifted entries closed
- [ ] `scripts/validate.sh` Error check 10 enforces byte-identity sync on every entry of a config-driven mirror list; CI fails on drift
- [ ] `work-copilot/instructions/copilot-instructions.md` references the new artifacts within the 8 KB budget
- [ ] `bin/` is intentionally absent from `work-copilot/` (Decision #10)

## Decomposition

- [S000007 — Copilot Prompt Packaging](S000007_copilot_prompt_packaging/S000007_TRACKER.md) — port the validator as a Copilot prompt file (shipped v0.14.0)
- [S000008 — Template Delivery & Install](S000008_template_delivery_and_install/S000008_TRACKER.md) — deliver templates + install into target repo's `.github/` (shipped v0.14.0)
- [S000009 — Always-On Instructions](S000009_always_on_instructions/S000009_TRACKER.md) — author `copilot-instructions.md` for always-on workflow context (file shipped v0.14.0; Windows-box live E2E pending)
- [S000010 — Bundle Artifact Completeness](S000010_bundle_artifact_completeness/S000010_TRACKER.md) — mirror `WORKFLOW.md` + `reference/` + `philosophy/` + `examples/` + missing fixtures (v2 realignment)
- [T000011 — Validate Sync-Check Extension](S000010_bundle_artifact_completeness/T000011_validate_sync_check_extension/T000011_TRACKER.md) — extend `validate.sh` Error check 10 to a config-driven `MIRROR_SPECS` array

## Non-Goals

- A `.chatmode.md`-only delivery — chat modes require manual mode-switching by the user. Always-on instructions plus prompt files keeps parity with Claude Code UX.
- A bash-based installer — work-machine constraint is Windows. Installer is Python 3 stdlib (`scripts/copilot-deploy.py`) for cross-platform.
- Maintaining a separate template fork — `work-copilot/templates/` and the new mirror dirs (`WORKFLOW.md`, `reference/`, `philosophy/`, `examples/`, `fixtures/`) must stay byte-for-byte identical to upstream. Sync enforced by `validate.sh` Error check 10's `MIRROR_SPECS` array.
- Shell execution at prompt time — Copilot has none. Validator logic is expressed as instructions + checklists Copilot follows, not bash. Consequently `bin/` is not mirrored.
- **Knowledge integration follow-up.** The `$AI_KNOWLEDGE_DIR` env-var seam, two-tier surfacing (always-on / on-demand), and `knowledge-doctor` diagnostic are explicitly deferred to a follow-up feature. Copilot has no shell and no env-var resolution at prompt time, so the helpers as currently implemented (`skills/company-workflow/bin/knowledge-helpers.sh`) cannot be ported as-is. The follow-up feature gets its own Copilot-native design pass (instruction-only, static `.github/knowledge-index.md`, pre-built per-category READMEs — TBD).
- A GitHub Action that runs `/validate` in CI — nice-to-have; file as a follow-up feature if the Copilot-chat experience proves the value.
- Windows installer bootstrapping (MSI, Chocolatey, etc.) — plain `python scripts/copilot-deploy.py ...` is sufficient for v1 and v2.

<!-- ===== From F000004_milestones.md ===== -->

## Delivery Timeline
<!-- Canonical milestone tracker for this feature. Scrum docs snapshot this table.
     Owner = primary person responsible. Status values: Done, In Progress, Not Started, At Risk, Deferred.
     Blocked By = milestone number(s) that must complete first, or "—" if none.
     This file is the SINGLE SOURCE OF TRUTH. Edit milestones here. -->

| # | Milestone | Target Date | Status | Owner | Notes | Blocked By |
|---|-----------|-------------|--------|-------|-------|------------|
| 1 | Design approved (office-hours + PRDs for 3 stories) | 2026-04-25 | Done | chjiang | v1 design approved; child PRDs in S000007/S000008/S000009. Reconciled 2026-04-26 — was stale "Not Started" before v0.14.0 ship | — |
| 2 | Prompt packaging shipped (S000007) | 2026-05-02 | Done | chjiang | `validate.prompt.md` mirrors `/company-workflow check`; reads templates + manifest. Shipped v0.14.0 (PR #43). Reconciled 2026-04-26 | #1 |
| 3 | Template delivery + install (S000008) | 2026-05-06 | Done | chjiang | Templates land in target repo's `.github/`; installer works cross-platform (Python 3 stdlib). Shipped v0.14.0 (PR #43). Reconciled 2026-04-26 | #1 |
| 4 | Always-on instructions (S000009) | 2026-05-06 | Done | chjiang | `copilot-instructions.md` shipped v0.14.0 (PR #43). Live Windows-box E2E AC tracked separately under S000009 — does not block this milestone. Reconciled 2026-04-26 | #1 |
| 5 | End-to-end verification on work machine | 2026-05-08 | Done | chjiang | Cross-platform install + smoke tests verified in CI on macOS + Linux. Live Windows-box Copilot-chat verification continues under S000009 in parallel. Reconciled 2026-04-26 | #2, #3, #4 |
| 6 | Feature shipped (`/ship` + `/land-and-deploy`) | 2026-05-10 | Done | chjiang | Merged to main and tagged v0.14.0 via PR #43 on 2026-04-23. Reconciled 2026-04-26 | #5 |
| 7 | Symlink setup docs in the bundle | 2026-05-12 | Not Started | chjiang | Add a "Setting up on a new machine" section to `work-copilot/instructions/copilot-instructions.md` (or a sibling `SETUP.md`) documenting the symlink approach: clone `claude-skills-templates` once, then `ln -s` the three artifacts into each target repo's `.github/`. Single source of truth, update-once-apply-everywhere. Optional stretch: add `--symlink` mode to `scripts/copilot-deploy.py` that writes symlinks instead of copies (~30 LOC). | #6 |
| 8 | Document (or unify) the Claude+Copilot install story | 2026-05-14 | Not Started | chjiang | Confirm and document that `skills-deploy` (Claude → `~/.claude/`) and `scripts/copilot-deploy.py` (Copilot → `<target>/.github/`) write to disjoint paths and can coexist in the same repo without conflict. Decide whether to leave them as two separate tools (clearer blast radius) or unify behind a single `deploy.py --target claude\|copilot\|both` entry point (one command, two modes). Ship: a short section in README or CLAUDE.md naming the guarantee, plus the decision. | #6 |
| 9 | Bundle artifact completeness shipped (S000010) | 2026-05-13 | Not Started | chjiang | Mirror `WORKFLOW.md` + `reference/` + `philosophy/` + `examples/` from `skills/company-workflow/` into `work-copilot/`; complete the 5-file fixtures gap. v2 realignment per design doc 2026-04-26 | #6 |
| 10 | Sync-check extension shipped (T000011) | 2026-05-13 | Not Started | chjiang | Extend `scripts/validate.sh` Error check 10 to a config-driven `MIRROR_SPECS` array enforcing byte-identity sync on every mirror entry. Adds 9 negative-path synthetic test cases plus 1 happy-path case in `scripts/test.sh` | #6 |
| 11 | Realignment v0.15.0 release | 2026-05-15 | Not Started | chjiang | `/ship` + `/land-and-deploy` for the v2 realignment. Tag v0.15.0, update catalog | #9, #10 |

### Delivery History

<!-- Backward-looking record: PR links, merge dates, version bumps after ship.
     Append-only. Don't edit historical entries — they're the durable record
     of what shipped when. Migrated content has no recorded delivery history
     entries; left empty. -->

- _none recorded at migration time_

## Dependency Graph
<!-- Visual representation of milestone ordering and blocking relationships.
     Update when milestones or dependencies change.
     Format: #N description --> #M description (arrow = "blocks")
     Keep in sync with the Blocked By column above. -->

```
#1 design approved
      |
      +--> #2 prompt packaging (S000007) ---+
      |                                      |
      +--> #3 template delivery (S000008) ---+--> #5 work-machine verify --> #6 ship v0.14.0 --+--> #7 symlink setup docs
      |                                      |                                                 |
      +--> #4 always-on instructions (S000009)                                                  +--> #8 two-install story / unification
                                                                                                |
                                                                                                +--> #9 bundle artifact completeness (S000010) --+
                                                                                                |                                                |
                                                                                                +--> #10 sync-check extension (T000011) --------+--> #11 realignment v0.15.0 release
```

## Open Questions

<!-- Questions still being decided. Migrated content has no recorded open
     questions; left empty intentionally. -->

| Question | Next check |
|----------|-----------|
| _none recorded at migration time_ | _N/A_ |
