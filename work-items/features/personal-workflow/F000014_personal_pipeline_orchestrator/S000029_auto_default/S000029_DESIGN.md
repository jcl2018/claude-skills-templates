---
type: design
parent: S000029
title: "/personal-pipeline auto-default — Design"
version: 1
status: Draft
date: 2026-05-09
author: chjiang
reviewers: []
---

<!-- Brief stub — see source design at
     ~/.gstack/projects/jcl2018-claude-skills-templates/chjiang-claude-vigilant-ride-11f98a-design-20260509-221215.md
     and parent F000014's design context. This story flips /personal-pipeline's
     polarity: auto becomes the only mode; --auto and --manual flags become
     silent no-op for backwards compat. Reverses S000028 premise 1. -->

## Problem

`/personal-pipeline --auto` shipped in v1.14.0 (commit 4ba2ddb) as an opt-in
flag on top of v1.13.0's manual default. The conservative posture ("preserve
manual as the default; auto is opt-in") served its purpose — auto mode soaked
in production, the user trusts it, and the manual path is now dead-by-policy.
Keeping both modes maintained costs ~40-50 lines of conditional gating in
pipeline.md (`$AUTO_MODE` checks, "Skip if $AUTO_MODE=false" guards, "Manual
mode: …" / "Auto mode (Step N): …" parity prose at ~7 sites), the entire
50-line `## Auto Mode` section in SKILL.md, and a "two ways to do the same
thing" UX that the `/autoplan` precedent (single mode, no toggle) has already
proved unnecessary.

## Shape of the solution

```
skills/personal-pipeline/
├── SKILL.md          # delete ## Auto Mode (~50 lines), drop [--auto] from Usage, collapse dual-example
└── pipeline.md       # promote Auto Mode Overlay → main flow, collapse per-step "Manual / Auto" pairs, parser accept-and-discard --auto/--manual
```

Plus: `skills-catalog.json` description bump (sensitive surface), README.md
regeneration via `./scripts/generate-readme.sh`, CHANGELOG.md v1.16.0 entry
(release-coupled sensitive surface), VERSION bump to 1.16.0, TODOS.md follow-up
("v1.17.0: drop telemetry `mode` field"). No new files; no new skill.

| Concern | User-story | Artifact |
|---------|-----------|----------|
| Flag parser accept-and-discard for `--auto` and `--manual` | S000029 | `pipeline.md` (Step 1) |
| Promote Auto Mode Overlay → main pipeline behavior | S000029 | `pipeline.md` (lines 48-144 → unconditional) |
| Collapse per-step "Manual / Auto" prose pairs | S000029 | `pipeline.md` (7 sites: 224, 255, 310, 372, 409, 434, 485) |
| Step 8.5 always-fire (subject to existing carve-outs) | S000029 | `pipeline.md` (Step 8.5, line 489) |
| Telemetry `_MODE="auto"` literal | S000029 | `pipeline.md` (lines 589, 605) |
| Delete `## Auto Mode` SKILL.md section + Usage cleanup | S000029 | `SKILL.md` |
| Catalog description update (drop "auto vs manual" duality) | S000029 | `skills-catalog.json` |
| CHANGELOG reversal note + VERSION bump + TODOS follow-up | S000029 | `CHANGELOG.md`, `VERSION`, `TODOS.md` |

## Big decisions

| # | Decision | Why |
|---|----------|-----|
| 1 | Approach B: flag accept-and-discard + auto promoted to only path + CHANGELOG reversal | Single PR ships the polarity flip, manual code deletion, docs, and reversal note in one coherent change. Matches the user's D2.A intent ("flag disappears entirely"). Sub-skills are the manual escape hatch; rollback = `git revert`. |
| 2 | Both `--auto` and `--manual` are silent no-op (P4 errata) | Symmetric accept-and-discard so existing scripts, design-doc footers, and muscle memory keep working without raising errors. Verified by Success Criteria #6 and #7. |
| 3 | Telemetry `mode` field stays in v1.16.0 emitting `"auto"` literal | Easier than changing the JSONL schema mid-flight. Field deletion deferred to v1.17.0 (TODOS.md follow-up). Pre-v1.16.0 history rows stay readable; the trip-wire (≥3 of 5 `halted_at_gate`) just stops slicing by mode. |
| 4 | MINOR version bump (1.16.0), not MAJOR | Removed flag is accept-and-discard (zero break for existing invocations). Default behavior changed but the result envelope (pipeline runs through, Step 8.5 surfaces decisions, sub-skills callable individually) is preserved. Mirrors the v1.13.x → v1.14.x precedent. |
| 5 | Auto Mode Overlay substance promoted (not deleted) into main flow | The 6 principles + decision classification + $DECISION_LOG schema + Step 8.5 logic (~200 lines) are valuable and must persist. Promotion preserves them; conditional framing (~10-15 lines of "Active when `$AUTO_MODE=true`…") is what gets deleted. A future revert restores conditionals (~1 hour rewrap), not re-authored substance. |
| 6 | Document this as a deliberate reversal, not "evolution" | Premise 5: CHANGELOG entry must contain the explicit phrase "reverses S000028 premise 1." Creates an auditable paper trail of "I changed my mind, here's why" — higher discipline bar than "ship and forget." |

## Risks & open questions

| Risk / Question | Next check |
|-----------------|-----------|
| Auto-mode surprise discovered post-ship; user wants manual back | Rollback = `git revert` of the v1.16.0 PR. Sub-skills (`/scaffold-work-item`, `/implement-from-spec`, `/qa-work-item`) remain individually callable as the manual workflow with no orchestrator-level changes needed. |
| External JSONL reader breaks on unexpected `mode: "auto"` literal in v1.16.0 | Telemetry field stays for one release as no-op; deletion is a separate v1.17.0 change. No external readers known at scale=1, but the deferral is the safe path. |
| Q2 (deferred): extract the 6 principles + decision classification into a shared fragment for `/autoplan` + `/personal-pipeline` | Tabled — `/autoplan` lives in gstack (not workbench-owned). Re-open if a third auto-decision skill emerges. |

## Definition of done

<!-- Mirrors the design doc's Success Criteria block. -->

- [ ] `grep -nE '(\$AUTO_MODE|^AUTO_MODE=|[^=]AUTO_MODE=)' skills/personal-pipeline/pipeline.md` returns zero matches
- [ ] `grep -n -- '--auto)' skills/personal-pipeline/pipeline.md` shows the case branch collapsed into a `--auto|--manual)` accept-and-discard arm
- [ ] `grep -n 'Auto mode (Step' skills/personal-pipeline/pipeline.md` returns zero matches
- [ ] `grep -n '^## Auto Mode' skills/personal-pipeline/SKILL.md` returns zero matches
- [ ] SKILL.md Usage line shows `/personal-pipeline <design-doc-path>` only (no `[--auto]`)
- [ ] `/personal-pipeline --auto <doc>` and `/personal-pipeline --manual <doc>` both succeed silently (smoke test)
- [ ] CHANGELOG v1.16.0 entry contains the explicit phrase "reverses S000028 premise 1"
- [ ] VERSION file shows `1.16.0`
- [ ] `./scripts/validate.sh` and `./scripts/test.sh` pass
- [ ] `/personal-workflow check` passes on this work item

## Not in scope

- Sub-skill behaviors (`/scaffold-work-item`, `/implement-from-spec`, `/qa-work-item`) — unchanged; they remain individually callable as the manual escape hatch
- Telemetry JSONL schema deletion of the `mode` field — stays in v1.16.0 as `"auto"` literal; deletion deferred to v1.17.0 (TODOS.md follow-up)
- DECISION_LOG schema — stays as-is; classification field semantics unchanged; path unchanged (`~/.gstack/analytics/personal-pipeline-auto-decisions.jsonl`)
- Sunset criterion logic — unchanged; the trip-wire (≥3 of 5 `halted_at_gate`) still applies; the `mode` dimension drops out naturally as all future runs emit `"auto"`
- `/autoplan` (separate skill in gstack, not workbench-owned)
- `work-copilot/` Copilot bundle — no orchestrator there; nothing to mirror

## Pointers

- Source /office-hours design: `~/.gstack/projects/jcl2018-claude-skills-templates/chjiang-claude-vigilant-ride-11f98a-design-20260509-221215.md`
- Parent feature DESIGN: [../F000014_DESIGN.md](../F000014_DESIGN.md)
- Parent feature TRACKER: [../F000014_TRACKER.md](../F000014_TRACKER.md)
- Parent feature ROADMAP: [../F000014_ROADMAP.md](../F000014_ROADMAP.md)
- Sibling S000028 (the premise being reversed): [../S000028_auto_mode/S000028_DESIGN.md](../S000028_auto_mode/S000028_DESIGN.md)
- v1.14.0 source design (the original `--auto` flag): `~/.gstack/projects/jcl2018-claude-skills-templates/chjiang-claude-elegant-ptolemy-c264a2-design-20260509-184827.md`
- Current SKILL.md: `skills/personal-pipeline/SKILL.md`
- Current pipeline.md: `skills/personal-pipeline/pipeline.md`
- /autoplan reference (single-mode precedent): `~/.claude/skills/gstack/autoplan/SKILL.md`
