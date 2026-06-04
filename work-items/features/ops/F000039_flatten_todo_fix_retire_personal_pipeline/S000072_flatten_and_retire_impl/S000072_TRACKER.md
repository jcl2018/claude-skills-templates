---
name: "Flatten todo_fix + retire /CJ_personal-pipeline (implementation)"
type: user-story
id: "S000072"
status: active
created: "2026-06-03"
updated: "2026-06-03"
parent: "F000039"
repo: "/Users/chjiang/Documents/projects/claude-skills-templates"
branch: "cj-feat-20260603-132322-16015"
blocked_by: ""
# pr: ""  # optional; populate with PR URL for explicit PR-state lookups.
---

<!-- Atomic implementation story: derives directly from the parent feature's
     /office-hours session. The parent's design is sufficient context; this
     story's DESIGN.md is a brief stub linking to the parent. -->

## Lifecycle

### Phase 1: Track

1. Read parent tracker to understand scope
2. Create working branch: `git checkout -b feat/{slug}` (or use parent's branch if shipping in same PR)
3. Scaffold work item directory and TRACKER.md
4. Distill `DESIGN.md` from the /office-hours output (own session or parent's) — from `templates/doc-DESIGN.md`
5. Scaffold `SPEC.md` (requirements, acceptance criteria, architecture, tradeoffs) — from `templates/doc-SPEC.md`
6. Scaffold `TEST-SPEC.md` (smoke + E2E test scenarios) — from `templates/doc-TEST-SPEC.md`
7. Break into child tasks if scope warrants decomposition (per WORKFLOW.md, tasks are optional for atomic stories)

**Gates:**
- [x] /office-hours design referenced (own or parent's, captured in DESIGN.md)
- [x] Working branch created (`branch` field populated)
- [x] DESIGN + SPEC + TEST-SPEC scaffolded
- [x] Acceptance criteria defined
- [x] Tasks broken down (N/A — atomic story)

### Phase 2: Implement

1. Read DESIGN + SPEC for context
2. Implement according to architecture decisions in SPEC
3. Run smoke tests as you go (TEST-SPEC `## Smoke Tests` table)
4. Run `/CJ_personal-workflow check` on modified docs after updates
5. Update tracker: move through lifecycle phases, add journal entries
6. Update Files section with changed file paths

**Gates:**
- [x] Acceptance criteria verified met
- [x] Smoke tests pass
- [x] Todos section reflects remaining work (no stale items)
- [x] Files section updated with changed files

### Phase 3: Ship

1. Run `/CJ_personal-workflow check` — verify all validation passes
2. Verify smoke tests pass in CI (automated regression)
3. Walk E2E manually — drive the feature as a user would (TEST-SPEC `## E2E Tests` table)
4. Ensure all child tasks (if any) have shipped
5. Run `/ship` — creates PR, bumps version, updates changelog (includes pre-landing code review)
6. Run `/land-and-deploy` — merges PR and verifies deployment

❌ If `/CJ_personal-workflow check` finds issues: fix findings, re-run until clean
❌ If smoke or E2E fails: fix, re-run

**Gates:**
- [ ] `/CJ_personal-workflow check` — validation passed
- [ ] Smoke tests pass in CI
- [ ] E2E walked manually
- [ ] All children shipped (if any)
- [ ] `/ship` — PR created (with pre-landing review)
- [ ] `/land-and-deploy` — merged and deployed

## Acceptance Criteria

<!-- What "done" looks like for this story. -->

- [x] Single-TODO mode: `pipeline.md` + `SKILL.md` orchestration prose dispatches `/CJ_implement-from-spec` then `/CJ_qa-work-item` as leaf Agent subagents (halt-on-red between); all "drive /CJ_personal-pipeline" language removed.
- [x] `todo_fix.sh` DISPATCH_CHAIN echo (lines 678 dry-run + 870 live) changed to the flattened impl→qa chain; `--suppress-final-gate` dropped.
- [x] Drain mode: `drain-one-todo.sh` emitted handoff + comments (lines 14, 34, 321) dispatch impl→qa per TODO; the `--force-create` block (line 255) is UNCHANGED.
- [x] Halt taxonomy renamed `halted_at_pipeline_implement`/`halted_at_pipeline_qa` → `halted_at_impl`/`halted_at_qa` in SKILL.md + ASCII chart + any telemetry end-state strings.
- [x] `skills/CJ_personal-pipeline/` deleted; `skills-catalog.json` object removed; `CJ_goal_todo_fix.depends.skills` no longer names it and lists the real dispatch deps.
- [x] `validate.sh` Check 12 block (~514-535) removed AND `test.sh` (~line 1138 pipeline.md-guard reference) reconciled in the SAME change.
- [x] All live-surface references cleaned (doc/SKILL-CATALOG.md, doc/PHILOSOPHY.md, CLAUDE.md, rules/skill-routing.md, README.md regenerated via generate-readme.sh, CJ_suggest suggest.sh+SKILL.md, impl/qa/scaffold USAGE files, cj-handoff-gate.sh).
- [x] `./scripts/validate.sh` green; `./scripts/test.sh` green; `grep -rI "CJ_personal-pipeline" skills/ scripts/ doc/ rules/ CLAUDE.md README.md` returns nothing.

## Todos

<!-- Actionable items for this story. -->

- [x] Flatten single-TODO mode (pipeline.md + SKILL.md prose; todo_fix.sh lines 678, 870).
- [x] Flatten drain mode (drain-one-todo.sh lines 14, 34, 321; leave 255).
- [x] Rename halt taxonomy + update ASCII chart + telemetry end-states.
- [x] Update USAGE.md (drop personal-pipeline from Mental model / Related skills).
- [x] `rm -rf skills/CJ_personal-pipeline/` (via `git rm -rf`).
- [x] Edit skills-catalog.json (remove object; rewrite depends.skills).
- [x] Clean doc/SKILL-CATALOG.md, doc/PHILOSOPHY.md, CLAUDE.md. (rules/skill-routing.md had no personal-pipeline mention — the internal-steps note never named it; no edit needed.)
- [x] Clean CJ_suggest suggest.sh (INTERNAL_SKILL_RE line 90 + comment 468) + SKILL.md; impl/qa/scaffold USAGE; cj-handoff-gate.sh (lines 66, 81).
- [x] Remove validate.sh Check 12 block + reconcile test.sh ~line 1138 (SAME change).
- [x] Regenerate README.md via scripts/generate-readme.sh.
- [x] Verify: validate.sh green, test.sh green, grep sweep returns nothing.

## Log

<!-- Chronological entries with dates and commit SHAs. -->

- 2026-06-03: Created. Single implementation story for F000039 — flatten /CJ_goal_todo_fix off /CJ_personal-pipeline (dispatch impl→qa leaf subagents) and delete the skill + clean ~18 live-surface references.
- 2026-06-03 (HEAD 1f1b55f, uncommitted): Implemented via /CJ_implement-from-spec (silent /CJ_goal_feature build context). Flattened both modes to dispatch /CJ_implement-from-spec → /CJ_qa-work-item leaf Agent subagents; deleted skills/CJ_personal-pipeline/; swept all live-surface refs; removed validate.sh Check 12 + reconciled test.sh + tests/cj-worktree-init.test.sh in the SAME change. Gates: validate.sh PASS (0 err/0 warn), test.sh PASS (0 failures), grep sweep EMPTY. 20 files modified, 9 deleted.

## PRs

<!-- PR links with status (open/merged/closed). -->

## Files

<!-- Affected file paths. -->

Modified (flatten single-TODO + drain + halt taxonomy):
- `skills/CJ_goal_todo_fix/SKILL.md` — flatten chain ASCII, frontmatter desc, halt-taxonomy table rename, Notes
- `skills/CJ_goal_todo_fix/pipeline.md` — new Step 4 impl→qa dispatch section + Step 5.5 boundary rephrase
- `skills/CJ_goal_todo_fix/scripts/todo_fix.sh` — DISPATCH_CHAIN dry-run (678) + live handoff (870) flattened; comment cleanup
- `skills/CJ_goal_todo_fix/scripts/drain-one-todo.sh` — handoff + header comments (14, 30-35, 320-323); `--force-create` block (255) UNCHANGED
- `skills/CJ_goal_todo_fix/USAGE.md` — Mental model + Related skills

Deleted:
- `skills/CJ_personal-pipeline/` (SKILL.md, pipeline.md, USAGE.md, fixtures/) via `git rm -rf`

Catalog + dep graph:
- `skills-catalog.json` — removed CJ_personal-pipeline object; rewrote CJ_goal_todo_fix.depends.skills (+ CJ_implement-from-spec, CJ_qa-work-item); fixed CJ_suggest + CJ_goal_todo_fix descriptions

Reference sweep:
- `doc/SKILL-CATALOG.md` — removed section + workflow chart node; updated 3 phase-step Status lines
- `doc/PHILOSOPHY.md` — decision-tree table + anti-pattern prose exemplar
- `CLAUDE.md` — skill-routing paragraph
- `README.md` — regenerated via `scripts/generate-readme.sh` (catalog-driven)
- `skills/CJ_suggest/scripts/suggest.sh` — INTERNAL_SKILL_RE (90) + comments (89, 468)
- `skills/CJ_suggest/SKILL.md` — description + filter list + legacy-form example
- `skills/CJ_implement-from-spec/USAGE.md`, `skills/CJ_qa-work-item/{qa.md,USAGE.md}`, `skills/CJ_scaffold-work-item/USAGE.md`
- `scripts/cj-handoff-gate.sh` — denylist entry (81) + comment (66)

Blind-spot pairing (validate.sh ↔ test.sh, SAME change):
- `scripts/validate.sh` — removed entire Check 12 block (guard-token grep on deleted pipeline.md)
- `scripts/test.sh` — reconciled the ~line 1138 pipeline.md-guard comment (now names CJ_goal_feature/pipeline.md)
- `tests/cj-worktree-init.test.sh` — reconciled stale header comments describing the retired guard assertion

NB: `rules/skill-routing.md` — no edit (its internal-steps note never named personal-pipeline).

## Insights

<!-- Non-obvious findings worth remembering. -->

- The flattened chain is exactly `/CJ_implement-from-spec` → `/CJ_qa-work-item` (CJ_goal_feature Steps 3.2-3.3, both Agent-tool, silent/no-AUQ), minus the scaffold step — because todo_fix already scaffolds the T-task dir in pure bash (todo_fix.sh:608-693), mirroring personal-pipeline's `--work-item-dir` = "skip scaffold" mode (pipeline.md:158).
- validate.sh Check 12 is NOT a structural validator — it's a guard-token grep (`[ -x ./scripts/validate.sh ]`) on personal-pipeline's pipeline.md. Deleting the skill requires removing the whole Check 12 block AND reconciling test.sh's parallel reference (~line 1138) in the SAME change. This is the known implement-subagent blind spot (F000032/F000034/F000035 all hit the validate.sh↔test.sh pairing).
- `--suppress-final-gate` is dropped, not translated — it's a personal-pipeline-only AUQ-suppression flag; the leaf subagents have no gate.

## Journal

<!-- Structured entries from the work-track journal command. Each entry has a type
     (decision, finding, blocker) and a Summary field. -->

- [decision] 2026-06-03: Atomic story — no task children. The work is one cohesive change (flatten + delete + reference cleanup) shipping in a single PR; per WORKFLOW.md, tasks are optional and omitted for atomic stories. Phase 1 gate recorded as `[x] Tasks broken down (N/A — atomic story)`.
- [impl-decision] 2026-06-03: depends.skills final list resolved (SPEC Open Q) — kept CJ_scaffold-work-item (bash scaffold mirrors its role) + CJ_personal-workflow (boundary check run by impl/qa) + CJ_suggest (drain enumerate) and ADDED CJ_implement-from-spec + CJ_qa-work-item (the two now-dispatched leaf skills); dropped CJ_personal-pipeline. Default-to-listing-all-three per the SPEC's resolution.
- [impl-decision] 2026-06-03: validate.sh Check 12 — removed the ENTIRE block (header comment + PIPELINE_MD if/else + guard-token grep), not just the grep line, since the whole check existed only to guard the now-deleted pipeline.md. Replaced with a one-paragraph retirement note (no `CJ_personal-pipeline` literal, to keep the scripts/ grep sweep clean). Paired with test.sh + tests/cj-worktree-init.test.sh comment reconciliation in the SAME diff (the F000032/F000034/F000035 blind spot).
- [impl-finding] 2026-06-03: The test.sh ~line 1138 "pipeline.md static-grep guard" comment + the tests/cj-worktree-init.test.sh assertion (lines 387-407) reference CJ_goal_feature/pipeline.md Step 1.9, NOT the deleted CJ_personal-pipeline/pipeline.md — so test.sh stayed green on the deletion with no code-logic change needed; only stale comments were reconciled. The S4 smoke `! grep -nF 'CJ_personal-pipeline/pipeline.md' scripts/test.sh` was already passing (that literal was never in test.sh).
- [impl-finding] 2026-06-03: rules/skill-routing.md needed NO edit — its "internal pipeline steps … do not route directly" note lists steps generically (scaffold/implement/qa, *-workflow validators) and never named personal-pipeline. SPEC #7 / task #8 listed it defensively; grep confirmed zero hits.
- [impl-finding] 2026-06-03: generate-readme.sh prints to STDOUT (does not write README.md itself, despite the Scripts-reference "1 on write failure" wording); regenerated via `./scripts/generate-readme.sh > README.md`. Confirmed idempotent (E3) and catalog-driven (no hand-edit).
- [impl-finding] 2026-06-03: TEST-SPEC S7's literal `grep -qF 'cj-worktree-init.sh --caller todo --force-create'` does not match the actual code (the helper is invoked via `$_WT_HELPER`, a variable, on line 255: `"$_WT_HELPER" --caller todo --force-create --quiet`). The real acceptance criterion — line 255 byte-for-byte unchanged — IS satisfied, and the test.sh automated F000025 drain guard (two-grep form) passes. Pre-existing SPEC-vs-code literal mismatch; not introduced here.
- [impl] 2026-06-03: Modified 20 files, deleted 9 (skills/CJ_personal-pipeline/ tree). Flatten: SKILL.md + pipeline.md (new Step 4 impl→qa dispatch) + todo_fix.sh (678/870) + drain-one-todo.sh (14/30-35/320-323, line 255 untouched). Delete + catalog + ~18-ref sweep + validate.sh Check 12 removal + test.sh/tests reconciliation + README regen.
- [impl-auto] 2026-06-03: Ran in silent /CJ_goal_feature build context (no AUQ tool). Per the runner authorization, treated the SPEC as the sensitive-surface confirmation and proceeded on skills-catalog.json / validate.sh / test.sh / cj-handoff-gate.sh / suggest.sh / skills/*/ edits without halting for the sensitive-surface AUQ (the changes ARE the authorized work).
- [impl-pass] S000072: implementation complete. Phase 2 implementer-owned gates transitioned. Verify A (validate.sh PASS, 0 err/0 warn), Verify B (test.sh PASS, 0 failures), Verify C (grep sweep EMPTY); all 7 smoke rows + E1/E3 E2E rows PASS. QA-owned gates left for /CJ_qa-work-item.
- 2026-06-03 [qa-smoke] S1 (AC-5): green — `skills/CJ_personal-pipeline/` absent (test ! -e PASS).
- 2026-06-03 [qa-smoke] S2 (AC-7, AC-8): green — live-surface grep sweep returns nothing (skills/ scripts/ doc/ rules/ CLAUDE.md README.md).
- 2026-06-03 [qa-smoke] S3 (AC-6): green — validate.sh exit 0 AND Check-12 guard token `[ -x ./scripts/validate.sh ]` absent from validate.sh.
- 2026-06-03 [qa-smoke] S4 (AC-6): green — test.sh exit 0 (0 failures) AND no `CJ_personal-pipeline/pipeline.md` reference in test.sh (validate.sh↔test.sh blind-spot pairing reconciled).
- 2026-06-03 [qa-smoke] S5 (AC-3): green — catalog has no CJ_personal-pipeline object and CJ_goal_todo_fix.depends.skills omits it. QA-CORRECTED the TEST-SPEC command: the original `jq -e '(.[]|select(.name==...))|not'` exits 4 (not 0) when the object is correctly ABSENT — a self-defeating assertion; replaced with `jq -e 'any(.[]; .name==...)|not'`. Implementation unchanged.
- 2026-06-03 [qa-smoke] S6 (AC-4): green — no `halted_at_pipeline_(implement|qa)` anywhere in CJ_goal_todo_fix; `halted_at_(impl|qa)` present in SKILL.md.
- 2026-06-03 [qa-smoke] S7 (AC-2): green — drain per-TODO isolation invocation (`--caller todo --force-create`, drain-one-todo.sh:255) intact. QA-CORRECTED the TEST-SPEC command per the prior [impl-finding]: dropped the non-matching literal `cj-worktree-init.sh ` prefix (the helper is invoked via the `$_WT_HELPER` variable); now asserts `--caller todo --force-create`. Implementation unchanged.
- 2026-06-03 [qa-smoke-summary] green: 7/7 non-manual rows green (0 manual). 2 TEST-SPEC commands corrected (S5 jq, S7 grep) to assert the real criteria; no code change.
- 2026-06-03 [qa-e2e-run-start] RUN_ID=20260603-143515-92188 commit=1f1b55f
- 2026-06-03 [qa-e2e] E1 (AC-1): green — `/CJ_goal_todo_fix … --dry-run` preview chain reads `/CJ_implement-from-spec <dir> → /CJ_qa-work-item <dir> → /ship → /land-and-deploy`; no `/CJ_personal-pipeline`, no `--suppress-final-gate` (todo_fix.sh:678). [parent-inline]
- 2026-06-03 [qa-e2e] E2 (AC-6, AC-8): green — validate.sh exit 0, test.sh exit 0 (0 failures), live-surface grep sweep empty, run consecutively in one sitting (proves the Check 12 removal + test.sh reconciliation hold together). [parent-inline]
- 2026-06-03 [qa-e2e] E3 (AC-7): green — `generate-readme.sh` regen is idempotent (regenerated output == on-disk README.md) and README has 0 CJ_personal-pipeline mentions (catalog-driven, not hand-edited). [parent-inline]
- 2026-06-03 [qa-e2e-summary] green (0s subagent; 3 rows parent-inline; 0 deferred): all 3 E2E rows green. Ran parent-inline (top-level) so the per-row checks stay at depth-1 (no nested-subagent wall).
- 2026-06-03 [qa-pass] S000072 (user-story): green smoke + green E2E. Phase 2 qa-owned gates transitioned (Acceptance criteria verified met + Smoke tests pass). QA corrected 2 TEST-SPEC smoke commands (S5, S7) to assert real criteria; implementation verified correct and unchanged.
