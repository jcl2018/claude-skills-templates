---
type: feature-summary
parent: F000004_work_copilot
title: "work-copilot — Feature Summary"
date: 2026-04-24
author: chjiang
status: Backfill
---

<!-- Retroactive backfill: F000004 was scaffolded before feature-summary.md was a
     required feature artifact for personal-workflow (added in this PR's
     manifest update). The original roll-up identity for this feature lives
     in F000004_TRACKER.md (Acceptance Criteria, Insights, Journal) and in
     F000004_DESIGN.md. This file exists for manifest compliance. -->

## Scope

`work-copilot/` is a portable GitHub Copilot bundle that mirrors the intent of
`skills/company-workflow/` for users on a Windows work machine where Claude Code
isn't available. It packages templates, an artifact manifest, validation
instructions, and reference guides into a `.github/`-installable bundle composed
of `copilot-instructions.md` (always-on context) plus `.prompt.md` files
(slash-command equivalents). Zero dependency on Claude Code, gstack, or any
Anthropic-specific tooling. Installation handled by `scripts/copilot-deploy.py`
(Python 3 stdlib only — no bash assumption).

## Success Criteria

- [ ] `work-copilot/` directory contains a portable bundle that mirrors the intent of `skills/company-workflow/`: templates, artifact manifest, validation instructions, reference guides
- [ ] The bundle installs into a target repo's `.github/` directory as a `copilot-instructions.md` file plus `.prompt.md` prompt files
- [ ] A GitHub Copilot user in the target repo can invoke the equivalent of `/company-workflow check` via a Copilot prompt/chat mode and get [PASS]/[MISSING]/[DRIFT] output on work items
- [ ] Installation works on a Windows work machine with Copilot (matches the "work machine" delivery constraint)
- [ ] Zero dependency on Claude Code, gstack, or any Anthropic-specific tooling — the bundle is Copilot-native
- [ ] `skills-deploy install work-copilot <target-repo>` (or equivalent) copies the bundle into `<target-repo>/.github/` idempotently

## Constituent User-Stories

- [S000007 — Copilot Prompt Packaging](S000007_copilot_prompt_packaging/S000007_TRACKER.md) — port the validator as a Copilot prompt file
- [S000008 — Template Delivery & Install](S000008_template_delivery_and_install/S000008_TRACKER.md) — deliver templates + install into target repo's `.github/`
- [S000009 — Always-On Instructions](S000009_always_on_instructions/S000009_TRACKER.md) — author `copilot-instructions.md` for always-on workflow context

## Out-of-Scope

- A `.chatmode.md`-only delivery — chat modes require manual mode-switching by the user. Always-on instructions plus prompt files keeps parity with Claude Code UX.
- A bash-based installer — work-machine constraint is Windows. Installer is Python 3 stdlib (`scripts/copilot-deploy.py`) for cross-platform.
- Maintaining a separate template fork — `work-copilot/templates/` must stay byte-for-byte identical to `templates/company-workflow/*.md`. Sync enforced by `validate.sh` Error check 10.
- Shell execution at prompt time — Copilot has none. Validator logic is expressed as instructions + checklists Copilot follows, not bash.
