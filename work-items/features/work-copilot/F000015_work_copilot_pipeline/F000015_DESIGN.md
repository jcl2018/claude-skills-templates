---
type: design
parent: F000015
title: "work-copilot pipeline — Feature Design"
version: 1
status: Draft
date: 2026-05-11
author: chjiang
reviewers: []
---

<!-- A feature's cross-story design doc. Captures the PROBLEM, the SHAPE of
     the solution, the BIG DECISIONS with rationale, the RISKS, the
     DEFINITION OF DONE, and out-of-scope boundaries. Story-scope detail
     (SPEC/TEST-SPEC) lives on the nested user-stories — do
     not duplicate it here. For a filled-in example, see
     `work-items/features/F000004_work_copilot/F000004_DESIGN.md`. -->

## Problem

The `work-copilot/` bundle today ships exactly one Copilot slash command — `/validate` — plus an always-on `.github/copilot-instructions.md` and a templates+manifest mirror of `deprecated/CJ_company-workflow/`. It validates structure but does nothing to chunk the workflow into bite-sized, validated phases. As a result, company-side work items drift in four ways simultaneously:

1. **Long templates rot.** Company templates total ~1118 lines across 17 files; you fill 30%, ship, the rest becomes stale boilerplate that lies about what shipped.
2. **Code/doc desync.** PRD/ARCHITECTURE were valid at scaffold time; code evolved, docs didn't.
3. **Skipped phases.** Scaffold, write PRD, jump straight to coding. Tracker gates stay unchecked but the work proceeds anyway.
4. **Cognitive load: too many artifacts.** A user-story = 5 artifacts (tracker + PRD + ARCHITECTURE + TEST-SPEC + milestones), each with their own sections; it's easy to lose track of which doc covers what.

`/CJ_personal-pipeline` solved the analogous problem on the Claude side by orchestrating scaffold → implement → QA via fresh-context `Agent` subagents with file-only handoff, pre-collected AskUserQuestions, and inter-phase quality gates. We want the same chunking discipline on the Copilot side — but adapted to Copilot's constraints (no `Agent` subagent dispatch, no `AskUserQuestion`, just plain chat + repo file access).

## Shape of the solution

Six new Copilot slash commands under `work-copilot/prompts/` (deployed by `copilot-deploy.py` to `.github/prompts/` in the target repo), all carrying the `wc-` namespace prefix:

- `/wc-qa` (build #1 — locks the receipt schema)
- `/wc-implement` (build #2 — per-type dispatch over 5 work-item types)
- `/wc-scaffold` (build #3 — design-doc → work-item directory tree)
- `/wc-investigate` (build #4 — scoping conversation → design doc)
- `/wc-ship` (build #5 — PR description synthesis)
- `/wc-pipeline` (build #6 — status compiler / drift math over all receipts)

Each phase command (other than `/wc-pipeline`) writes a structured **receipt** block into the tracker's YAML frontmatter under a top-level `receipts:` key. `/wc-investigate` writes its receipt into the design-doc frontmatter (since no tracker exists yet); `/wc-scaffold` copies it into the new tracker at scaffold time.

`/wc-pipeline` is a **status compiler** — it reads receipts plus `.git/HEAD` (via the `codebase` tool, a file read; no shell access available) and prints drift math: "phase N not yet run," "HEAD has moved past `receipts.implement.latest_sha_at_implement`" (binary, no commit count), "AC-3 has no test row," etc. It performs zero mutations.

Three new domain skeleton templates (per-target-repo user data, NOT byte-mirrored): `domain-knowledge.template.md`, `coding-conventions.template.md`, `architecture-overview.template.md`. `copilot-deploy install` writes skeletons on first install and never overwrites filled content.

| Concern | User-story | Artifact |
|---------|-----------|----------|
| QA walkthrough + receipt-schema lock | S000030 | [S000030_wc_qa/S000030_TRACKER.md](S000030_wc_qa/S000030_TRACKER.md) |
| Implement from spec (per-type) | S000031 | [S000031_wc_implement/S000031_TRACKER.md](S000031_wc_implement/S000031_TRACKER.md) |
| Scaffold work-item from design | S000032 | [S000032_wc_scaffold/S000032_TRACKER.md](S000032_wc_scaffold/S000032_TRACKER.md) |
| Scoping conversation + design doc | S000033 | [S000033_wc_investigate/S000033_TRACKER.md](S000033_wc_investigate/S000033_TRACKER.md) |
| PR description synthesis | S000034 | [S000034_wc_ship/S000034_TRACKER.md](S000034_wc_ship/S000034_TRACKER.md) |
| Status compiler / drift math | S000035 | [S000035_wc_pipeline/S000035_TRACKER.md](S000035_wc_pipeline/S000035_TRACKER.md) |

## Big decisions

| # | Decision | Why |
|---|----------|-----|
| 1 | Approach C (all 6 prompts, /qa-first bottom-up) over Approach B (forward top-down) or Approach A (minimal v1, no /investigate) | C builds /wc-qa first to lock the receipt schema; B builds /qa late so /scaffold and /implement guess at receipts and rework follows. A is genuinely smaller but the user explicitly asked for the investigate-equivalent (Copilot has no /office-hours). Full scope from v1 is the right call when build order is reliable. |
| 2 | Receipts in YAML frontmatter, not a separate file | Receipts are tracker state, not artifacts. Keeping them in tracker frontmatter under `receipts:` makes them version-controlled with the tracker, diffable in PRs, and discoverable without a separate manifest. The existing `validate.prompt.md` "read whole file, parse YAML, merge, write whole file back" pattern is the implementation contract. |
| 3 | `/wc-pipeline` as **status compiler** (read-only), not macro | Codex's reframe — Copilot's no-subagent constraint becomes a feature when the orchestrator is a printer over an explicit state machine. Every handoff is explicit, resumable, diffable, PR-reviewable. Future single-keystroke UX = thin printer over the same 5 leaves, not refactor. Revises original P4. |
| 4 | User-paste pattern for git access (no `runCommands` MCP dep) | None of the standard Copilot `tools:` values expose a shell. Every git command in the design is asked of the user via a paste pattern ("please run `git rev-parse HEAD` and paste the output"). The bundle stays portable; advanced users with `runCommands` MCP can substitute later. `.git/HEAD` is read via the `codebase` tool (file read, no shell needed) for the binary stale check. |
| 5 | Working-Tree Rule UX: hard-stop for /wc-implement and /wc-qa, warn-and-write for /wc-ship | Hard-stop keeps drift math honest for the phases that write code/test receipts; /wc-ship's synthesized PR description is useful even with an unpushed working tree (the warning surfaces the risk). /wc-scaffold is the exception — receipt writes despite uncommitted work-item dir because the dir is fresh; a `pending_commit: true` flag in `receipts.scaffold` flips to false on first /wc-implement. |
| 6 | No new `MIRROR_SPECS` entries; separate existence check instead | The 6 new prompts and 3 domain skeletons are `work-copilot/`-only (no `deprecated/CJ_company-workflow/` counterpart). Adding them to `MIRROR_SPECS` would require fabricating mirror paths — wrong shape. A lighter-weight existence check inside `validate.sh` enforces presence without faking byte-identity. |
| 7 | `/wc-scaffold` requires a design-doc input (P5 implicit) | Hand-written tracker without a `receipts.investigate` root would break `/wc-pipeline`'s drift math chain. If the user wants to scaffold without /wc-investigate, they hand-author a stub `.github/work-copilot/designs/<slug>.md` with the required frontmatter and a minimal `receipts.investigate` block. |

## Risks & open questions

| Risk / Question | Next check |
|-----------------|-----------|
| YAML-frontmatter surgical edits from a Copilot prompt are unreliable. Mitigation: every prompt's receipt-write contract is "read whole file, parse YAML, merge, write whole file back." Will this hold across all 5 receipt-writing prompts in practice? | Verify after build #1 (S000030 /wc-qa) ships and is tested against a fixture work item. |
| Recipe UX (5 clicks) may not feel light enough in practice. P1 says future single-keystroke = thin printer over the same 5 leaves. If a user runs the full chain ≥5 times and pushes for single-key, build that thin printer in v2. | Track adoption after S000035 ships; if friction shows up, file follow-up. |
| Domain folder discoverability across N target repos at the same company. V1 says re-author per repo; V2 could add env-var override for shared path. | Track after S000033 ships; file follow-up if multiple repos at the same company show same-content drift. |
| Receipts append-only vs overwrite-per-phase. Spec says overwrite-per-phase (re-running /wc-qa replaces old `receipts.qa`; prior phases preserved). Confirm this matches drift-math intent in practice. | Verify on a re-run scenario after S000030 and S000035 ship. |
| Pipeline alone won't fix template length (drift symptom a) or artifact count (drift symptom d). Per P2, a parallel `T0NNNNN_template_trim` follow-up is required. | File as a parallel follow-up at any point; not a build prerequisite. |

## Definition of done

<!-- Objective, measurable criteria for "shipped." Not aspirations. A
     reviewer should be able to verify each item without asking the
     author. -->

- [ ] All 6 prompts under `work-copilot/prompts/` and installed to `.github/prompts/` of a test target repo via `copilot-deploy install`.
- [ ] 3 domain skeletons under `work-copilot/domain/*.template.md` and installed to `.github/work-copilot/domain/` on first install; filled-in `.md` content survives re-installs.
- [ ] `.github/work-copilot/designs/` folder created via `.gitkeep` on first install.
- [ ] One full end-to-end walkthrough (investigate → scaffold → implement → qa → ship → pipeline) completed in Copilot Chat against a real target repo work-item, with each phase's receipt visible in tracker frontmatter (or design-doc frontmatter for /wc-investigate).
- [ ] `/wc-pipeline` exercise against a "drifted" fixture work-item prints accurate drift math (missing receipts, HEAD-moved stale flag, uncovered ACs, changed-files-without-tests).
- [ ] `validate.sh` existence check added; `tracker-*.md` `receipts: {}` stub propagates from `deprecated/CJ_company-workflow/templates/` to `work-copilot/templates/` via existing MIRROR_SPECS.
- [ ] `.github/copilot-instructions.md` updated with a "Pipeline commands" section enumerating all 6 commands and the recommended invocation order.

## Not in scope

<!-- Explicit non-goals. Prevents scope creep and gives reviewers an
     unambiguous boundary. -->

- Template-trim follow-up (`T0NNNNN_template_trim`) — per P2, deferred to a parallel work item; orchestrator alone won't shrink artifact count. Trimmed templates can drop in later as a non-breaking template change.
- `Agent` subagent dispatch / RESULT-line parsing pattern from `/CJ_personal-pipeline` — Copilot has no equivalent; the user-paste pattern is the explicit substitution.
- `AskUserQuestion` flows — Copilot has no AUQ; phase commands prompt in plain chat.
- Auto-pushing or auto-opening PRs from `/wc-ship` — the prompt synthesizes the description and writes the receipt; the user opens the PR manually on GitHub and edits `receipts.ship.pr_opened` / `pr_url` afterwards.
- Cross-repo shared domain folder (V2 candidate, not V1).
- An MCP `runCommands` shell tool — the bundle does not depend on it; user-paste pattern is the portable default.
- Trimmed `work-copilot/` templates — handled by the parallel template-trim work item, NOT this feature.

## Pointers

<!-- Cross-links to related artifacts: parent tracker, roadmap,
     upstream sources, related features/defects. Use relative paths
     from the feature directory. -->

- Parent tracker: [F000015_TRACKER.md](F000015_TRACKER.md)
- Roadmap: [F000015_ROADMAP.md](F000015_ROADMAP.md)
- Source /office-hours design doc: `/Users/chjiang/.gstack/projects/jcl2018-claude-skills-templates/chjiang-claude-zealous-antonelli-5f8036-design-20260511-095218.md`
- Mental model reference: `skills/CJ_personal-pipeline/SKILL.md` (the Claude-side orchestrator whose pattern this adapts)
- Existing bundle: `work-copilot/` (under repo root)
- Existing validate prompt (precedent for the "read whole file, write whole file back" pattern): `work-copilot/prompts/validate.prompt.md`
- Upstream mirror source for `tracker-*.md` template edits: `deprecated/CJ_company-workflow/templates/`
- Related feature: [F000004_work_copilot](../F000004_work_copilot/F000004_TRACKER.md) (the original bundle work)
