---
type: roadmap
parent: F000015
title: "work-copilot pipeline — Roadmap"
date: 2026-05-11
author: chjiang
status: Draft
---

<!-- A feature's roll-up roadmap — merges what was previously in feature-summary
     + milestones. Captures scope/non-goals (the feature's identity), decomposition
     (which user-stories carry the work), and delivery timeline (when each piece
     ships). The /CJ_personal-workflow templates step produces this. -->

## Scope

Ship 6 new Copilot slash commands (`/wc-qa`, `/wc-implement`, `/wc-scaffold`, `/wc-investigate`, `/wc-ship`, `/wc-pipeline`) plus 3 per-target-repo domain skeleton templates under the existing `work-copilot/` bundle. Each phase command writes a structured receipt block in tracker YAML frontmatter; `/wc-pipeline` reads those receipts plus `.git/HEAD` and prints drift math. Together they turn the work-item folder into a visible, diff-reviewable state machine — the Copilot-side analog of `/CJ_personal-pipeline`, adapted to Copilot's constraints (no Agent subagents, no AskUserQuestion, no shell access).

## Non-Goals

- Template-trim work — defer per P2 to a parallel `T0NNNNN_template_trim` follow-up. Pipeline alone won't shrink artifact count or template length.
- Auto-push or auto-open PRs from `/wc-ship` — synthesis + receipt only; user opens PR manually on GitHub.
- Cross-repo shared domain folder — V2 candidate; V1 says re-author per target repo.
- An MCP `runCommands` shell dependency — bundle stays portable; user-paste pattern is the default.
- Trimmed `work-copilot/` templates — handled by the parallel template-trim work item.

## Success Criteria

<!-- Bulleted, measurable outcomes. Each criterion should be observable from
     the outside (a user, an SLO, a stakeholder report) — not internal code
     state. If you can't measure it, it's not a success criterion; it's
     an aspiration. -->

- [ ] All 6 prompts present at `work-copilot/prompts/*.prompt.md`.
- [ ] All 3 domain skeletons present at `work-copilot/domain/*.template.md`.
- [ ] `copilot-deploy.py install <target-repo>` writes the prompts, skeletons, and an empty `designs/` folder (`.gitkeep` pattern) into the target repo's `.github/work-copilot/`; re-install never overwrites filled-in domain `.md` content.
- [ ] One end-to-end walkthrough in Copilot Chat against a real target repo produces valid receipts at every phase.
- [ ] `/wc-pipeline` against a hand-crafted drifted fixture prints accurate drift math (Missing / Stale / Coverage holes / Diff audit / Ship-not-opened / Next legal).
- [ ] `validate.sh` existence check fails fast if any prompt or skeleton file is missing.
- [ ] `.github/copilot-instructions.md` includes a "Pipeline commands" section listing all 6 commands in invocation order.

## Decomposition

<!-- The user-stories that decompose this feature, with current status. The
     validator does not enforce this list, but it's the canonical map for human
     readers. Status values: Open, In Progress, Closed. -->

| User-Story | Title | Status |
|-----------|-------|--------|
| [S000030](S000030_wc_qa/S000030_TRACKER.md) | /wc-qa — QA walkthrough + receipt-schema lock | Open |
| [S000031](S000031_wc_implement/S000031_TRACKER.md) | /wc-implement — implement from spec (per-type dispatch) | Open |
| [S000032](S000032_wc_scaffold/S000032_TRACKER.md) | /wc-scaffold — design-doc → work-item directory tree | Open |
| [S000033](S000033_wc_investigate/S000033_TRACKER.md) | /wc-investigate — scoping conversation + design doc + domain skeletons | Open |
| [S000034](S000034_wc_ship/S000034_TRACKER.md) | /wc-ship — PR description synthesis | Open |
| [S000035](S000035_wc_pipeline/S000035_TRACKER.md) | /wc-pipeline — status compiler / drift math | Open |

## Delivery Timeline

<!-- Forward-looking milestones for this feature. Owner = primary person responsible.
     Status: Done, In Progress, Not Started, At Risk, Deferred.
     Blocked By = milestone number(s) that must complete first, or "—" if none.
     Forward roadmap entries go here; historical entries (PR links, merge dates
     after ship) move to the ### Delivery History sub-section below. -->

| # | Milestone | Target Date | Status | Owner | Notes | Blocked By |
|---|-----------|-------------|--------|-------|-------|------------|
| 1 | Schema prerequisite — add `receipts: {}` stub to `deprecated/CJ_company-workflow/templates/tracker-*.md` (MIRROR_SPECS propagates to `work-copilot/templates/`) | — | Not Started | chjiang | Touches 4 tracker template files (feature, user-story, task, defect). Also update `work-copilot/fixtures/valid-feature-dir/` so /wc-qa has a real day-1 test target. | — |
| 2 | Add existence check to `validate.sh` for `work-copilot/prompts/*.prompt.md` and `work-copilot/domain/*.template.md` | — | Not Started | chjiang | Separate from MIRROR_SPECS; lighter-weight presence assertion. | #1 |
| 3 | Ship S000030 — `/wc-qa` (build #1, schema-locking) | — | Not Started | chjiang | Locks receipt schema. Tests against existing fixture work item. | #2 |
| 4 | Ship S000031 — `/wc-implement` (build #2) | — | Not Started | chjiang | Per-type dispatch for 5 work-item types (feature/user-story/task/defect/review). Writes `receipts.implement`. | #3 |
| 5 | Ship S000032 — `/wc-scaffold` (build #3) | — | Not Started | chjiang | Idempotency check from design-doc YAML frontmatter; writes receipts.scaffold; updates design-doc `status:` and `scaffolded_to:`. | #4 |
| 6 | Ship S000033 — `/wc-investigate` (build #4) + 3 domain skeleton templates + `copilot-deploy.py` first-install-only rule + `designs/.gitkeep` creation | — | Not Started | chjiang | Largest story by scope (touches copilot-deploy.py). | #5 |
| 7 | Ship S000034 — `/wc-ship` (build #5) | — | Not Started | chjiang | PR description synthesis; `receipts.ship` with `pr_opened: false`. | #6 |
| 8 | Ship S000035 — `/wc-pipeline` (build #6, status compiler) | — | Not Started | chjiang | Read-only diagnostic. Test against a deliberately drifted fixture. | #7 |
| 9 | End-to-end pipeline run — one work-item walked through all 6 phases in Copilot Chat against a real target repo | — | Not Started | chjiang | Success-criteria validation. | #8 |
| 10 | Update `.github/copilot-instructions.md` "Pipeline commands" section | — | Not Started | chjiang | Mirrors existing /validate documentation. | #8 |

### Delivery History

<!-- Backward-looking record: PR links, merge dates, version bumps after ship.
     Append-only. Don't edit historical entries — they're the durable record
     of what shipped when. Use this section to absorb any pre-existing
     milestones content during a feature-summary+milestones → ROADMAP migration. -->

- 2026-05-11: Feature scaffolded from /office-hours design.

## Dependency Graph

<!-- Visual representation of milestone ordering. Format: #N description --> #M
     description (arrow = "blocks"). Keep in sync with the Blocked By column. -->

```
#1 (receipts: {} stub) --> #2 (validate.sh existence check) --> #3 (S000030 /wc-qa, schema lock)
                                                                       |
                                                                       v
                                              #4 (S000031 /wc-implement) --> #5 (S000032 /wc-scaffold)
                                                                                       |
                                                                                       v
                                              #6 (S000033 /wc-investigate + domain skeletons + copilot-deploy.py)
                                                                                       |
                                                                                       v
                                              #7 (S000034 /wc-ship) --> #8 (S000035 /wc-pipeline)
                                                                                       |
                                                                                       v
                                              #9 (end-to-end walkthrough) --- #10 (copilot-instructions.md update)
```

## Open Questions

<!-- Questions still being decided. -->

| Question | Next check |
|----------|-----------|
| Will YAML-frontmatter surgical edits via the "read whole, parse, merge, write whole" pattern hold across all 5 receipt-writing prompts? | Verify after S000030 (/wc-qa) ships and is exercised against a fixture work item. |
| Will Recipe UX (5 clicks) feel light enough in practice, or push hard for a single-keystroke v2 printer? | Track adoption after S000035 ships. If friction shows up after ≥5 full-chain runs, file a v2 printer follow-up. |
| Domain folder discoverability across N target repos at the same company — re-author per repo (V1) or env-var override (V2)? | Track after S000033 ships; file V2 follow-up if multiple repos at the same company show same-content drift. |
| Receipts append-only vs overwrite-per-phase — spec says overwrite-per-phase; confirm this matches drift-math intent in practice. | Verify on a re-run scenario after S000030 and S000035 ship. |
