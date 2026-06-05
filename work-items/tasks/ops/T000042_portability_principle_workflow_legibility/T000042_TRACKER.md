---
name: "Document the portability principle (PHILOSOPHY) + workflow legibility (WORKFLOWS) + honest Category badges via catalog relabel"
type: task
id: "T000042"
status: active
created: "2026-06-04"
updated: "2026-06-04"
parent: ""
repo: "/Users/chjiang/Documents/projects/claude-skills-templates"
branch: "cj-feat-20260604-165723-57005"
blocked_by: ""
---

<!-- Source design doc (/office-hours, APPROVED — two design gates with the operator):
     ~/.gstack/projects/jcl2018-claude-skills-templates/chjiang-cj-feat-20260604-165723-57005-design-20260604-170343.md
     A doc + small-catalog change (no DESIGN.md; the design context is distilled into
     ## Insights below, per the skip-design-for-small-todos convention in WORKFLOW.md). -->

## Lifecycle

### Phase 1: Track

1. Read parent tracker to understand scope and acceptance criteria
2. Create working branch: `git checkout -b feat/{slug}`
   (use parent's branch if the task ships in the same PR; create a new branch if it warrants its own PR)
3. Scaffold required docs:
   - `test-plan.md` (test scenarios for this task) — from `templates/doc-test-plan.md`
4. Populate Files section with expected changed files
5. Write initial Todos from parent's acceptance criteria

**Gates:**
- [x] Parent scope read (N/A — standalone ops task; scope is the APPROVED design doc)
- [x] Working branch created (`branch` field populated — cj-feat-20260604-165723-57005, auto-worktree)
- [x] Required docs scaffolded (test-plan)
- [x] Files section populated

### Phase 2: Implement

1. Work from `/office-hours` design doc + parent's acceptance criteria + your Todos
   → design doc at `~/.gstack/projects/{slug}/`
2. Commit changes incrementally with descriptive messages
3. Update Todos section — check off completed items, add discoveries
4. Update Files section with actual changed files

**Gates:**
- [ ] Core changes committed (>=1 commit SHA in Log)
- [x] Todos section reflects remaining work (no stale items)
- [x] Files section updated with changed files

### Phase 3: Ship

1. Run `/CJ_personal-workflow check` — verify no regressions
2. Verify test-plan: all test scenarios passing
3. Run `/ship` — creates PR, bumps version, updates changelog (includes pre-landing code review)
4. Run `/land-and-deploy` — merges PR and verifies deployment

❌ If tests fail: fix, re-run
❌ If CI fails: fix, push, re-run `/ship`

**Gates:**
- [ ] `/CJ_personal-workflow check` — validation passed
- [ ] Test-plan verified (all scenarios passing)
- [ ] `/ship` — PR created
- [ ] `/land-and-deploy` — merged and deployed

## Todos

<!-- Actionable items for this task. Not lifecycle duplicates — these are
     the actual things to build, fix, or investigate. -->

- [x] **Part 1 — `doc/PHILOSOPHY.md`:** add the portability principle (a new `### ` subsection under `## Key patterns and conventions`, or a short dedicated `## ` section — implementer picks the cleaner fit). Cover: producer (`/CJ_repo-init` verifies a consumer repo) vs consumer; the strict `standalone < local-only < workbench` tier ladder ("standalone" = works in a repo that has never seen this workbench); the honesty / verified-invariant framing (a self-declared label nobody verifies is a lie waiting to happen — the audit turns the field into a verified invariant: advisory Check 18 today, `PORTABILITY_STRICT=1` hard-gate later). Reference `/CJ_portability-audit` + `/CJ_repo-init`. Do NOT add it to the `## Decision tree` (principle, not a routing rule). — DONE: added a dedicated `## The portability principle` section (cleaner fit than a `###` under Key patterns) between `## Key patterns and conventions` and `## Documentation surfaces`; decision tree untouched.
- [x] **Part 2 — `doc/WORKFLOWS.md` Category badges:** add a `**Category:**` line (the portability tier) beside the existing `**Status:**` on every orchestrator section (`## Orchestrators`) AND every entry under `## Utilities & phase-step skills`. Use the honest post-relabel values (see Insights table). — DONE: 14 `**Category:**` lines (one per section, incl. both `CJ_portability-audit` entries) — Status/Category parity 14/14; values match the post-relabel catalog.
- [x] **Part 3 — `doc/WORKFLOWS.md` walkthrough:** add a new `## How the machinery works` glossary (placed after the orchestrator charts) with a per-helper explainer for `cj-goal-common.sh` (phases: sync / worktree / pr-check / ship / cleanup / telemetry), `cj-worktree-init.sh` (create-or-detect + Fork-1 base-freshness ff + `--assert-isolated` verdict), `cj-worktree-cleanup.sh` (PR-state-gated janitor), `/CJ_document-release` (Step 5.5 doc-sync wrapper folding doc updates into the same PR), and the resume state file (`last_completed_phase` + per-phase HEAD SHA + PR# with validate-before-skip). PLUS a short 2-3 sentence per-workflow narrative under each orchestrator chart that references the glossary for the shared pieces. — DONE: `## How the machinery works` added after `## Orchestrators`; 5 helper explainers; an **In words** narrative under each of the 3 charts linking the glossary. (Verified the real `cj-goal-common.sh` phases = `worktree|telemetry|pr-check|ship→pr-check|cleanup|sync`.)
- [x] **Catalog relabel — `skills-catalog.json`:** set `portability: workbench` and `del .portability_requires` for `CJ_goal_feature`, `CJ_goal_defect`, `CJ_goal_todo_fix`, `CJ_personal-workflow`. Leave `CJ_repo-init` unchanged (`standalone` + `portability_requires` — documented debt). The Category badges in Part 2 must show these honest post-relabel values. — DONE via atomic jq write; 4 relabeled to `workbench` + `portability_requires` removed; `CJ_repo-init` untouched.
- [x] **Verify (test surface):** `./scripts/validate.sh` green (incl. Check 15/15a/15b + Check 18); `./scripts/test.sh` green; `./scripts/cj-portability-audit.sh` FINDINGS=0; `./scripts/cj-portability-audit.sh --no-adjudication` now lists ONLY `CJ_repo-init`; registered-doc audit clean (WORKFLOWS + PHILOSOPHY `requirement:` strings still satisfied); read-through of the new prose for accuracy. — DONE: validate.sh exit 0 (0 errors/0 warnings); test.sh exit 0 (Failures: 0); audit FINDINGS=0; `--no-adjudication` FINDINGS=1 = only `CJ_repo-init`.
- [x] **Follow-up TODO (Open Question 1 — do NOT build here):** append a TODOS.md row for a doc-vs-catalog `Category` drift check (a future `validate.sh` check or `/CJ_portability-audit` extension asserting `doc category == catalog portability`). — DONE: filed as the topmost `## Active work` row in TODOS.md (P3, S); no check implemented.

## Log

<!-- Chronological entries with dates and commit SHAs. Each entry records
     what happened, not what should happen. -->

- 2026-06-04: Created. Document the portability principle in doc/PHILOSOPHY.md, add Category badges + a `## How the machinery works` glossary + per-workflow narratives to doc/WORKFLOWS.md, and relabel 4 skills to `portability: workbench` in skills-catalog.json so the badges are honest. Scaffolded from the APPROVED /office-hours design doc.

## PRs

<!-- PR links with status (open/merged/closed). -->

## Files

<!-- Affected file paths. Populated during Track phase, updated during Implement. -->

- `doc/PHILOSOPHY.md` — add the portability principle (Part 1)
- `doc/WORKFLOWS.md` — Category badges on every skill section + `## How the machinery works` glossary + per-workflow narratives (Parts 2 & 3)
- `skills-catalog.json` — relabel `CJ_goal_feature` / `CJ_goal_defect` / `CJ_goal_todo_fix` / `CJ_personal-workflow` to `portability: workbench`, drop their `portability_requires` (catalog relabel)
- `TODOS.md` — append the deferred doc-vs-catalog Category drift-check follow-up row (Open Question 1)

## Insights

<!-- Non-obvious findings worth remembering. Things that surprised you,
     patterns discovered, or context that future readers will need. -->

- **The doc change and the catalog truth are the same fact.** "Show a Category badge" lands directly on the relabel that was already analyzed: the 3 orchestrators + `CJ_personal-workflow` currently declare `standalone` but really execute root-local helpers (within-tier for `workbench`), so simply surfacing the *current* catalog value would document a known falsehood. The relabel is folded in so the badges are honest (design D1 → C, chosen over doc-only options A/B).
- **Honest post-relabel Category values (the badge source of truth):**
  | Skill | Category (post-relabel) |
  |---|---|
  | `CJ_goal_feature` / `CJ_goal_defect` / `CJ_goal_todo_fix` | workbench |
  | `CJ_personal-workflow` | workbench |
  | `CJ_document-release` | workbench |
  | `CJ_portability-audit` | workbench |
  | `CJ_suggest` | local-only |
  | `CJ_system-health` / `CJ_scaffold-work-item` / `CJ_implement-from-spec` / `CJ_qa-work-item` / `CJ_improve-queue` | standalone |
  | `CJ_repo-init` | standalone *(known debt — bundle its engine to make it truly standalone)* |
- **The relabel keeps `/CJ_portability-audit` GREEN by construction.** Moving the 4 skills to `workbench` makes their root-script deps within-tier, so their `portability_requires` accepted-deps lists are dropped. `CJ_repo-init` deliberately stays `standalone` + `portability_requires` (the documented debt) — so after the relabel `--no-adjudication` shows ONLY `CJ_repo-init`.
- **Producer vs consumer is the framing.** `/CJ_repo-init` is the *consumer*-side check (does a target repo have the prerequisites?); `/CJ_portability-audit` (F000047) is the *producer*-side mirror (do the workbench's own skills secretly depend on repo-local things a fresh target repo won't have?). PHILOSOPHY states this pairing.
- **Two deferrals carried as Open Questions, NOT built here:** (1) a doc-vs-catalog `Category` drift check — file a follow-up TODOS row only; (2) making `CJ_repo-init` truly standalone by bundling `cj-repo-init.sh` under `skills/CJ_repo-init/scripts/` — referenced by the `standalone (debt)` note, separate follow-up.
- **Direct precedent for the taxonomy choice:** the three most recent doc/catalog changes to `doc/WORKFLOWS.md` (`T000037` workflows-doc-reorg, `T000040` granular-enumeration-rule, `T000041` utilities-roster-repartition) all shipped as **tasks** under `work-items/tasks/ops/`. This is the same shape — one coherent doc + small-catalog change — so it is scaffolded as a task (TRACKER + test-plan), not a feature-with-child-user-story (which would trigger a child-select AUQ the silent orchestrator can't answer).

## Journal

<!-- Structured entries from the work-track journal command. Each entry has a type
     (decision, finding, blocker) and a Summary field. -->

- [decision] 2026-06-04 — Scaffolded as a **task** (not a user-story). Summary: the design doc proposes "a single user-story," but a standalone user-story must nest under a feature (WORKFLOW.md placement rule + scaffold.md Step 8), which a doc/chore change doesn't have. The taxonomy fit for a one-shot doc + small-catalog change with a `validate.sh`/`test.sh`/audit test surface is a task (TRACKER + test-plan) — matching the T000037/T000040/T000041 doc-reorg precedent. The implementable scope is identical; only the artifact shape differs.
- [decision] 2026-06-04 — Category badges are **hardcoded with honest (post-relabel) values**; the doc-vs-catalog drift CHECK is deferred (design Open Question 1) to a follow-up TODOS row. Summary: building the drift check in this PR would expand scope past the doc + relabel; the design settled it as out-of-scope.
- 2026-06-04 [impl-decision] PHILOSOPHY: added the portability principle as a **dedicated `## The portability principle` section** (between `## Key patterns and conventions` and `## Documentation surfaces`) rather than a `###` subsection. Rationale: the content is substantial (producer/consumer pairing + the 3-rung tier ladder + the honesty/advisory-now-gate-later framing) and is a first-class workbench *value*, so a top-level `##` reads more prominently — the design doc left the choice to the implementer. Deliberately NOT added to `## Decision tree` (it is a principle, not a routing rule; keeps the F000030 New-skills check satisfied — no routable skill added/removed).
- 2026-06-04 [impl-decision] Relabel done via `jq '... |= (.portability="workbench" | del(.portability_requires))' > tmp && mv` (atomic temp-file write) to preserve catalog formatting, over a hand-Edit of 4 separate entries — jq guarantees consistent 2-space indentation and can't drift field order. `del(.portability_requires)` cleanly removed the field for all 4 while leaving `CJ_repo-init`'s intact.
- 2026-06-04 [impl-finding] Verified the real `scripts/cj-goal-common.sh` `--phase` set BEFORE writing the glossary (the task flagged this): the usage banner + dispatch declare `worktree | telemetry | pr-check | ship | cleanup | sync`, where `--phase ship` is an accepted ALIAS that maps to `pr-check` (line 108). Documented that alias explicitly in the `## How the machinery works` glossary so the prose matches the script, not the chart's looser labels.
- 2026-06-04 [impl-finding] The relabel makes the audit green **by tier, not by adjudication**: a `workbench`-declared skill whose deps are root scripts/`.source`/`CLAUDE.md` lands `portable-with-notes` (within-tier), so dropping `portability_requires` is safe — confirmed against the pre-existing `CJ_document-release` (already `workbench`, already `portable-with-notes`). `--no-adjudication` after the relabel drops from 5 findings to exactly 1 (`CJ_repo-init`), proving the 4 relabels are honest-by-tier and the audit is non-no-op.
- 2026-06-04 [impl] Wrote 0 new files; modified 4 — `doc/PHILOSOPHY.md` (portability principle section), `doc/WORKFLOWS.md` (14 Category badges + `## How the machinery works` glossary with 5 helper explainers + 3 per-workflow "In words" narratives), `skills-catalog.json` (relabel 4 → `workbench`, drop `portability_requires`), `TODOS.md` (1 follow-up row, Open Question 1). Verification: `validate.sh` exit 0 (0 errors / 0 warnings; Check 15 + Check 18 PASS), `test.sh` exit 0 (Failures: 0; T000040 Check-15b 4-bullet Touches intact; 8/8 S000083 audit fixtures pass), `cj-portability-audit.sh` FINDINGS=0, `--no-adjudication` FINDINGS=1 (only `CJ_repo-init`).
- 2026-06-04 [impl-pass] T000042: implementation complete. Phase 2 implementer-owned gates transitioned (`Todos section reflects remaining work`, `Files section updated with changed files`). Commit gate `Core changes committed` left for `/ship`.
- 2026-06-04 [qa-smoke] 1 (validate.sh): green — `./scripts/validate.sh` exit 0; Errors:0 Warnings:0; Check 15/15a/15b PASS (doc/ manifest + WORKFLOWS completeness, registered-doc); Check 18 portability advisory FINDINGS=0 exit 0.
- 2026-06-04 [qa-smoke] 2 (test.sh): green — `./scripts/test.sh` exit 0; Failures:0; T000040 Check-15b 4-bullet Touches OK on all 3 orchestrators; S000083 audit fixtures a–h all OK.
- 2026-06-04 [qa-smoke] 3 (cj-portability-audit): green — `./scripts/cj-portability-audit.sh` exit 0; FINDINGS=0; SKILLS_AUDITED=13; every verdict portable/portable-with-notes.
- 2026-06-04 [qa-smoke] 4 (audit --no-adjudication): green — `--no-adjudication` FINDINGS=1; the only finding-bearing skill is `CJ_repo-init` (the relabeled 4 are now within-tier `workbench`).
- 2026-06-04 [qa-smoke] 5 (catalog relabel): green — jq confirms CJ_goal_feature/defect/todo_fix + CJ_personal-workflow all `portability=workbench` with `portability_requires` ABSENT.
- 2026-06-04 [qa-smoke] 6 (CJ_repo-init unchanged): green — jq confirms `standalone` with `portability_requires=["scripts/cj-repo-init.sh"]` (untouched).
- 2026-06-04 [qa-smoke] 7 (PHILOSOPHY principle + decision-tree purity): green — `## The portability principle` present (producer/consumer pairing, strict standalone⊂local-only⊂workbench ladder, honesty/verified-invariant framing, advisory-now/gate-later, refs `/CJ_portability-audit` + `/CJ_repo-init`); `git diff doc/PHILOSOPHY.md` shows NO `## Decision tree` change (the 2 grep hits are pre-existing F000047 audit routes) — New-skills check intact.
- 2026-06-04 [qa-smoke] 8 (WORKFLOWS Category badges honest): green — 14 `**Status:**` / 14 `**Category:**` parity; every Category value matches `skills-catalog.json` portability (orchestrators + CJ_personal-workflow + CJ_document-release + CJ_portability-audit = workbench; CJ_suggest = local-only; rest standalone; CJ_repo-init standalone w/ debt note).
- 2026-06-04 [qa-smoke] 9 (WORKFLOWS glossary + narratives): green — `## How the machinery works` present after the charts with 5 helper explainers (cj-goal-common.sh phases incl. `--phase ship`→pr-check alias, cj-worktree-init.sh, cj-worktree-cleanup.sh, /CJ_document-release, resume state file); each of the 3 orchestrator charts has an `**In words:**` narrative linking the glossary. Prose accurate vs current scripts.
- 2026-06-04 [qa-smoke] 10 (registered-doc audit clean): green — PHILOSOPHY + WORKFLOWS `requirement:` strings still satisfied by the edited docs (Check 15 PASS; no `stale:` introduced); change is additive prose + honest catalog relabel.
- 2026-06-04 [qa-smoke] 11 (follow-up TODO filed not built): green — TODOS.md carries the deferred doc-vs-catalog `Category` drift-check row (topmost `## Active work`); `git diff --name-only -- scripts/` is EMPTY (no new validate.sh/audit check implemented). Only 4 files changed: TODOS.md, doc/PHILOSOPHY.md, doc/WORKFLOWS.md, skills-catalog.json.
- 2026-06-04 [qa-smoke-summary] green: 11/11 non-manual rows green (0 manual rows pending). commit=9c7e427.
- 2026-06-04 [qa-pass] T000042 (task): green smoke from test-plan rows (11 rows). No qa-owned Phase 2 gates per template; Phase 3 `Test-plan verified` gate awaits /ship-time inference. (Implementation uncommitted by design — orchestrator commits after this QA pass; not a refusal condition.)
