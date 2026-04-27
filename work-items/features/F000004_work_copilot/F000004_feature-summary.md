---
type: feature-summary
parent: F000004_work_copilot
title: "work-copilot — Feature Summary"
date: 2026-04-26
author: chjiang
status: Active
---

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

## Constituent User-Stories

- [S000007 — Copilot Prompt Packaging](S000007_copilot_prompt_packaging/S000007_TRACKER.md) — port the validator as a Copilot prompt file (shipped v0.14.0)
- [S000008 — Template Delivery & Install](S000008_template_delivery_and_install/S000008_TRACKER.md) — deliver templates + install into target repo's `.github/` (shipped v0.14.0)
- [S000009 — Always-On Instructions](S000009_always_on_instructions/S000009_TRACKER.md) — author `copilot-instructions.md` for always-on workflow context (file shipped v0.14.0; Windows-box live E2E pending)
- [S000010 — Bundle Artifact Completeness](S000010_bundle_artifact_completeness/S000010_TRACKER.md) — mirror `WORKFLOW.md` + `reference/` + `philosophy/` + `examples/` + missing fixtures (v2 realignment)
- [T000011 — Validate Sync-Check Extension](S000010_bundle_artifact_completeness/T000011_validate_sync_check_extension/T000011_TRACKER.md) — extend `validate.sh` Error check 10 to a config-driven `MIRROR_SPECS` array

## Out-of-Scope

- A `.chatmode.md`-only delivery — chat modes require manual mode-switching by the user. Always-on instructions plus prompt files keeps parity with Claude Code UX.
- A bash-based installer — work-machine constraint is Windows. Installer is Python 3 stdlib (`scripts/copilot-deploy.py`) for cross-platform.
- Maintaining a separate template fork — `work-copilot/templates/` and the new mirror dirs (`WORKFLOW.md`, `reference/`, `philosophy/`, `examples/`, `fixtures/`) must stay byte-for-byte identical to upstream. Sync enforced by `validate.sh` Error check 10's `MIRROR_SPECS` array.
- Shell execution at prompt time — Copilot has none. Validator logic is expressed as instructions + checklists Copilot follows, not bash. Consequently `bin/` is not mirrored.
- **Knowledge integration follow-up.** The `$AI_KNOWLEDGE_DIR` env-var seam, two-tier surfacing (always-on / on-demand), and `knowledge-doctor` diagnostic are explicitly deferred to a follow-up feature. Copilot has no shell and no env-var resolution at prompt time, so the helpers as currently implemented (`skills/company-workflow/bin/knowledge-helpers.sh`) cannot be ported as-is. The follow-up feature gets its own Copilot-native design pass (instruction-only, static `.github/knowledge-index.md`, pre-built per-category READMEs — TBD).
- A GitHub Action that runs `/validate` in CI — nice-to-have; file as a follow-up feature if the Copilot-chat experience proves the value.
- Windows installer bootstrapping (MSI, Chocolatey, etc.) — plain `python scripts/copilot-deploy.py ...` is sufficient for v1 and v2.
