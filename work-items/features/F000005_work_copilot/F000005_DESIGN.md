---
type: design
parent: F000005_work_copilot
title: "work-copilot — Feature Design (Plan)"
version: 1
status: Draft
date: 2026-04-22
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

## Shape of the solution

A single bundle — `work-copilot/` — that mirrors `skills/company-workflow/`
in intent and gets stamped into target repos. Three Copilot surfaces carry
the behavior:

| Claude Code analog | Copilot surface | Artifact |
|--------------------|-----------------|----------|
| `/company-workflow check` slash command | `.github/prompts/*.prompt.md` | `validate.prompt.md` |
| Always-on SKILL.md context | `.github/copilot-instructions.md` | `copilot-instructions.md` |
| Manifest + templates | `.github/work-copilot/` (bundle dir) | manifest + templates |

Three child stories decompose the work:

- **[S000007](S000007_copilot_prompt_packaging/S000007_TRACKER.md)** —
  author `validate.prompt.md` so `/validate <path>` in Copilot chat returns
  the same output contract as `/company-workflow check`
- **[S000008](S000008_template_delivery_and_install/S000008_TRACKER.md)** —
  Python 3 stdlib installer (`scripts/copilot-deploy.py`) that drops the
  bundle into `<target>/.github/` with drift detection + doctor
- **[S000009](S000009_always_on_instructions/S000009_TRACKER.md)** —
  `copilot-instructions.md` that gives Copilot ambient awareness of work
  item conventions and points to `/validate` for compliance

They converge at milestone #5 (end-to-end verification on the Windows work
box). See [milestones](F000005_milestones.md) for the dependency graph.

## Big decisions (already made)

| # | Decision | Why |
|---|----------|-----|
| 1 | Copilot surfaces = `prompts/` + `copilot-instructions.md` + bundle dir | `.chatmode.md` requires the user to switch modes manually — kills the "just type `/validate`" UX parity |
| 2 | Installer in Python 3 stdlib, not bash or PowerShell | Python runs on Windows + macOS without branches; stdlib avoids pip (corporate proxies block it) |
| 3 | Binary-mode file reads for SHA256 | Re-runs D000005 otherwise — CRLF conversion on Windows makes checksums flap |
| 4 | Reuse `company-workflow` manifest schema 1:1 | One spec, two runtimes. Inventing a Copilot-specific schema guarantees drift |
| 5 | `copilot-instructions.md` is an *index*, not a full spec | Manifest + templates remain source of truth; instructions point at `/validate` for enforcement (≤8 KB budget) |
| 6 | Source of truth lives in `work-copilot/instructions/`, copied on install | Simpler + reviewable. Can generate from `WORKFLOW.md` later if drift becomes real |
| 7 | `validate.sh` gets a template-sync check | Prevents `work-copilot/templates/` from silently diverging from `templates/company-workflow/` |

## Risks & open questions

| Risk | Next check |
|------|-----------|
| Copilot model *recalls* manifest contents instead of reading the file | S000007 prompt explicitly says "read the file, do not recall"; verify in E2E |
| Python 3.10+ actually on the work box | First Phase-2 action in S000008 — if missing, fall back to PowerShell port |
| Output format parity between Claude Code and Copilot runtimes | Ship fixtures in the bundle; manually diff outputs in E2E before declaring done |
| Pre-existing `.github/copilot-instructions.md` in target repos | Installer refuses to overwrite non-bundle files without `--overwrite` |
| `.prompt.md` format churn in future Copilot releases | Pin docs link + smoke test in installer; low likelihood but non-zero |

Open questions (track in the Insights section of the parent tracker as they
resolve):

- Do we want `skills-deploy` to gain a `--copilot` flag, or keep
  `copilot-deploy.py` entirely separate? (Leaning: separate. Different
  distribution surface, different target shape.)
- Where do reference guides live — inside the bundle or linked out?
  (Leaning: inside, for offline work-machine use.)

## Sequencing

Milestones (from [F000005_milestones.md](F000005_milestones.md)):

```
#1 Design approved (this doc + PRDs) — target 2026-04-25
      |
      +--> #2 Prompt packaging (S000007)      — target 2026-05-02
      |
      +--> #3 Template delivery (S000008)     — target 2026-05-06
      |
      +--> #4 Always-on instructions (S000009)— target 2026-05-06
                  |
                  v
            #5 E2E on Windows work box         — target 2026-05-08
                  |
                  v
            #6 Ship (`/ship` + `/land-and-deploy`) — target 2026-05-10
```

Critical path: #1 → #2/#3 (parallel) → #5 → #6. #4 is parallel with #2/#3
and doesn't block #5 on its own — but a half-done #4 would make the E2E
feel cheap, so hold #5 until all three stories are green.

## Definition of done

The feature is shipped when **all** of the following hold on the Windows
work box:

1. `python scripts/copilot-deploy.py install <target>` drops the bundle
   into `<target>/.github/` idempotently (exit 0, summary shows
   `installed=N skipped=0` on fresh install, `installed=0 skipped=N` on
   re-install)
2. In Copilot Chat inside `<target>`, typing `/validate work-items/...` on
   a known-good work item returns `[PASS]` for every artifact
3. Typing `/validate` on a known-bad work item returns `[MISSING]` /
   `[DRIFT]` lines that match what `/company-workflow check` prints on
   the same item in Claude Code
4. Copilot Chat can answer "how do I add a new feature in this repo?" with
   guidance sourced from `copilot-instructions.md` (ID regex, phase names,
   manifest pointer) — no hallucination
5. `scripts/validate.sh` in `claude-skills-templates` passes, including
   the new template-sync check

## Not in scope

- Porting `/personal-workflow` (lower priority — work tracking uses
  company workflow)
- Porting `/ship`, `/investigate`, `/qa`, or any other gstack skill —
  validator only
- A GitHub Action that runs `/validate` in CI (nice-to-have; file as a
  follow-up feature if the Copilot-chat experience proves the value)
- Windows installer bootstrapping (MSI, Chocolatey, etc.) — plain
  `python scripts/copilot-deploy.py ...` is enough for v1

## Pointers

- Parent tracker: [F000005_TRACKER.md](F000005_TRACKER.md)
- Milestones: [F000005_milestones.md](F000005_milestones.md)
- Upstream source: [skills/company-workflow/](../../../skills/company-workflow/)
- Manifest schema: [skills/company-workflow/company-artifact-manifests.json](../../../skills/company-workflow/company-artifact-manifests.json)
