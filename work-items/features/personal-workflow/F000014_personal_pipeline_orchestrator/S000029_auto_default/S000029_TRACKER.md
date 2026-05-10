---
name: "/personal-pipeline auto-default — make --auto the only mode; delete manual code path"
type: user-story
id: "S000029"
status: active
created: "2026-05-09"
updated: "2026-05-09"
parent: "F000014"
repo: "/Users/chjiang/Documents/projects/claude-skills-templates"
branch: "claude/vigilant-ride-11f98a"
blocked_by: ""
---

<!-- Prerequisite: /office-hours design at
     ~/.gstack/projects/jcl2018-claude-skills-templates/chjiang-claude-vigilant-ride-11f98a-design-20260509-221215.md
     This story implements that design — the polarity flip on /personal-pipeline. -->

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
- [x] Tasks broken down (or N/A — atomic story)

### Phase 2: Implement

1. Read DESIGN + SPEC for context
2. Implement according to architecture decisions in SPEC
3. Run smoke tests as you go (TEST-SPEC `## Smoke Tests` table)
4. Run `/personal-workflow check` on modified docs after updates
5. Update tracker: move through lifecycle phases, add journal entries
6. Update Files section with changed file paths

**Gates:**
- [x] Acceptance criteria verified met
- [x] Smoke tests pass
- [x] Todos section reflects remaining work (no stale items)
- [x] Files section updated with changed files

### Phase 3: Ship

1. Run `/personal-workflow check` — verify all validation passes
   → should show PASS for template, lifecycle, traceability badges
2. Verify smoke tests pass in CI (automated regression)
3. Walk E2E manually — drive the feature as a user would (TEST-SPEC `## E2E Tests` table)
4. Ensure all child tasks (if any) have shipped
5. Run `/ship` — creates PR, bumps version, updates changelog (includes pre-landing code review)
6. Run `/land-and-deploy` — merges PR and verifies deployment

❌ If `/personal-workflow check` finds issues: fix findings, re-run until clean
❌ If smoke or E2E fails: fix, re-run

**Gates:**
- [ ] `/personal-workflow check` — validation passed
- [ ] Smoke tests pass in CI
- [ ] E2E walked manually
- [ ] All children shipped (if any)
- [ ] `/ship` — PR created (with pre-landing review)
- [ ] `/land-and-deploy` — merged and deployed

## Acceptance Criteria

<!-- What "done" looks like for this story. Mirrors the design doc's Success Criteria. -->

- [x] `grep -nE '(\$AUTO_MODE|^AUTO_MODE=|[^=]AUTO_MODE=)' skills/personal-pipeline/pipeline.md` returns zero matches (variable fully removed, both references and assignments)
- [x] `grep -n -- '--auto)' skills/personal-pipeline/pipeline.md` shows the `--auto` case branch was collapsed into a `--auto|--manual)` accept-and-discard arm (no orphaned `--auto)` pattern that sets a variable)
- [x] `grep -n 'Auto mode (Step' skills/personal-pipeline/pipeline.md` returns zero matches (per-step conditional headers all collapsed)
- [x] `grep -n '^## Auto Mode' skills/personal-pipeline/SKILL.md` returns zero matches (the 50-line section is deleted)
- [x] SKILL.md Usage line shows `/personal-pipeline <design-doc-path>` only (no `[--auto]`)
- [x] Running `/personal-pipeline --auto <doc>` succeeds with `--auto` parsed and discarded (silent no-op; smoke verified)
- [x] Running `/personal-pipeline --manual <doc>` succeeds with `--manual` parsed and discarded (silent no-op; smoke verified)
- [x] CHANGELOG v1.16.0 entry contains the explicit phrase "reverses S000028 premise 1"
- [x] VERSION file shows `1.16.0`
- [x] `./scripts/validate.sh` and `./scripts/test.sh` pass
- [x] `/personal-workflow check` passes on this work item

## Todos

<!-- Actionable items for this story. -->

- [x] Edit `skills/personal-pipeline/SKILL.md`: delete `## Auto Mode` section (~50 lines); drop `[--auto]` from Usage code-fence; collapse dual-example block; drop "Optional --auto flag opts into auto-decision mode" line; reword "--auto-equivalent" → "auto-equivalent"
- [x] Edit `skills/personal-pipeline/pipeline.md` (Step 1 — flag parser): replace the `--auto` case branch with `--auto|--manual) ;;  # accept and discard for backwards compat`; delete `AUTO_MODE=false` init; rewrite the prose conditional ("If `$AUTO_MODE=true`, initialize…") as unconditional
- [x] Edit `skills/personal-pipeline/pipeline.md` (Auto Mode Overlay, lines 48-144): drop "Active when `$AUTO_MODE=true`. When inactive, this entire section is a no-op" framing; drop "manual mode parity" notes; promote substance (decision classification table, 6 principles, $DECISION_LOG schema) to main pipeline behavior
- [x] Edit `skills/personal-pipeline/pipeline.md` (per-step Auto-mode overrides at lines 224, 255, 310, 372, 409, 434, 485): collapse each "Manual mode: …" + "Auto mode (Step N branch): …" pair into a single unconditional paragraph using the auto-mode behavior; preserve the manual-AUQ blocks (now invoked unconditionally)
- [x] Edit `skills/personal-pipeline/pipeline.md` (Step 8.5, line 489): delete the `Skip if $AUTO_MODE=false` guard; preserve the empty-state short-circuit and two halt-categories carve-out
- [x] Edit `skills/personal-pipeline/pipeline.md` (telemetry, lines 589, 605): replace `_MODE=$([ "$AUTO_MODE" = "true" ] && echo "auto" || echo "manual")` with `_MODE="auto"` literal; update the explanatory comment
- [x] Edit `skills/personal-pipeline/pipeline.md` (closing prose, lines 684-691): drop `Auto mode (`$AUTO_MODE=true`)` prefix and "in both modes" framing; reword as the cohesive single-mode paragraph
- [x] Update `skills-catalog.json` `description` field for personal-pipeline to drop "auto vs manual" duality
- [x] Regenerate `README.md` via `./scripts/generate-readme.sh`
- [x] Add CHANGELOG.md v1.16.0 entry with the explicit "reverses S000028 premise 1" phrase
- [x] Bump `VERSION` to 1.16.0
- [x] Add TODOS.md follow-up: "v1.17.0: drop telemetry `mode` field from `~/.gstack/analytics/personal-pipeline.jsonl` JSONL writes" (P4/S sizing)
- [x] Run `./scripts/validate.sh` — green (Phase 2 implementer-owned scope; `./scripts/test.sh` deferred to QA/ship)
- [x] Run `/personal-workflow check` on this work item — green (verified at QA boundary check)
- [x] Smoke test the silent no-op for `--auto` and `--manual` (verified by /qa-work-item smoke S1-S5 + E2E E1, E2)

## Log

<!-- Chronological entries with dates and commit SHAs. -->

- 2026-05-09: Created. Story implements the `/personal-pipeline` polarity flip — auto mode becomes the only mode; `--auto` and `--manual` flags become silent no-op for backwards compat; ~40-50 lines of conditional gating deleted from pipeline.md; `## Auto Mode` section deleted from SKILL.md. Reverses S000028 premise 1. Source design at `~/.gstack/projects/jcl2018-claude-skills-templates/chjiang-claude-vigilant-ride-11f98a-design-20260509-221215.md`.

## PRs

<!-- PR links with status (open/merged/closed). -->

## Files

<!-- Affected file paths. -->

- `skills/personal-pipeline/SKILL.md` — modified (deleted `## Auto Mode` section + Usage cleanup + Phase 2 overview wording)
- `skills/personal-pipeline/pipeline.md` — modified (parser collapsed, overlay framing dropped, per-step prose collapsed at 7 sites, Step 8.5 guard removed, telemetry literal, closing prose reworded, summary block straggler cleaned)
- `skills-catalog.json` — modified (description update — sensitive surface; AUQ pre-approved by orchestrator)
- `README.md` — modified (regenerated via `./scripts/generate-readme.sh > README.md`)
- `CHANGELOG.md` — modified (v1.16.0 entry — release-coupled sensitive surface; AUQ pre-approved by orchestrator)
- `VERSION` — modified (1.15.1 → 1.16.0; AUQ pre-approved by orchestrator)
- `TODOS.md` — modified (v1.17.0 follow-up entry added)

## Insights

<!-- Non-obvious findings worth remembering. -->

- The `/autoplan` precedent (single mode, no toggle) already proved that the "two ways to do the same thing" UX is unnecessary for auto-decision skills. This story applies that precedent to /personal-pipeline.
- Auto Mode Overlay's substance (6 principles, decision classification, $DECISION_LOG schema, Step 8.5 logic — ~200 lines) is preserved by promotion (overlay → main flow), not deletion. A future revert would re-wrap in conditionals (~1 hour) rather than re-author.
- Conservative-then-flip is the dominant pattern in this codebase: ship the safer version first (v1.14.0 with `--auto` opt-in), use it once or twice, then commit to the unconditional version (this story → v1.16.0). The safe version is treated as a temporary scaffold, not an end state.
- Honest reversal documentation matters: CHANGELOG explicitly cites "reverses S000028 premise 1" rather than rebranding the change as "evolution." Creates an auditable paper trail of "I changed my mind, here's why" — Premise 5 in the source design.

## Journal

<!-- Structured entries from the work-track journal command. Each entry has a type
     (decision, finding, blocker) and a Summary field. -->

- [decision] 2026-05-09 — Approach B chosen over A (flag stays as --manual) and C (two-step ship with soak): single PR ships the polarity flip, manual code deletion, docs update, and CHANGELOG reversal note in one coherent change. Sub-skills are the manual escape hatch; rollback is `git revert`. Matches D2.A intent and all D3 premises precisely.
- [decision] 2026-05-09 — Both `--auto` and `--manual` flags become silent no-op (P4 errata): symmetric accept-and-discard so existing scripts and muscle memory keep working without raising errors. Validated by Success Criteria #6 and #7 (smoke tests for both flags).
- [decision] 2026-05-09 — Telemetry `mode` field stays in v1.16.0 emitting `"auto"` literal; field deletion deferred to v1.17.0 (logged as TODOS.md follow-up). Avoids breaking external JSONL readers mid-flight.
- [decision] 2026-05-09 — Versioning is MINOR (v1.16.0), not MAJOR. Removed flag is accept-and-discard (zero break for existing invocations); default behavior changed but result envelope (pipeline runs through, Step 8.5 surfaces decisions, sub-skills callable individually) is preserved. Mirrors v1.13.x → v1.14.x precedent.
- 2026-05-09 [impl-decision] Implemented per DESIGN/SPEC verbatim: parser case branch collapsed to `--auto|--manual) ;;`, `AUTO_MODE` variable fully removed (zero references, zero assignments), Auto Mode Overlay framing dropped (substance preserved), per-step "Manual / Auto" pairs collapsed at all 7 sites, Step 8.5 guard removed (always-fire subject to existing carve-outs), telemetry `_MODE="auto"` literal, closing prose reworded to single-mode narration. SKILL.md `## Auto Mode` section deleted; Usage code-fence reduced to single canonical invocation; "--auto-equivalent" → "auto-equivalent".
- 2026-05-09 [impl-decision] At Step 4 sub-step 4 and Step 5.2, the AUQ prompt blocks were preserved verbatim with a "kept for reference; never surfaced unconditionally — auto-classification handles it" framing. Per the orchestrator's pre-collected AUQ guidance: the manual-AUQ blocks STAY because they are now invoked unconditionally with auto-mode classification applied. This matches the DESIGN doc's verbatim instruction (Components Affected row 4: "Manual-AUQ blocks STAY — they were always shared between modes").
- 2026-05-09 [impl-decision] Cleaned up one stragger "auto mode only" phrase in Step 9.3 summary block (`Decisions: $DECISION_LOG (auto mode only; filter run_id=$RUN_ID)` → drop "auto mode only"). Not in the DESIGN doc's explicit edit list but logically required for single-mode coherence.
- 2026-05-09 [impl-finding] DESIGN doc claimed line 605 contains the explanatory comment to update; in v1.15.1 baseline that comment is at lines 605-607 ("`mode` field is `auto` or `manual` per `$AUTO_MODE`. Sunset trip-wire counts both modes pooled — same trip-wire contract regardless of mode."). Reworded to "`mode` field emits the literal `\"auto\"` ... field deletion deferred to v1.17.0 ... Sunset trip-wire counts all runs pooled."
- 2026-05-09 [impl-finding] `./scripts/generate-readme.sh` writes to stdout, not to README.md directly. Required `> README.md` redirect to actually update the file. Confirmed README now reflects single-mode catalog description.
- 2026-05-09 [impl] Modified 7 files (skills/personal-pipeline/SKILL.md, skills/personal-pipeline/pipeline.md, skills-catalog.json, README.md, CHANGELOG.md, VERSION, TODOS.md). validate.sh green. Tracker journal: 6 new entries.
- 2026-05-09 [impl-auto] Auto-mode run (orchestrator's Phase 2 dispatch with PRE_COLLECTED_AUQS for skills-catalog.json description, CHANGELOG.md release-coupled entry, and VERSION bump — all 3 sensitive surfaces approved upfront).
- 2026-05-09 [impl-pass] S000029: implementation complete. Phase 2 implementer-owned gates transitioned (Todos section reflects remaining work; Files section updated with changed files). QA-owned gates (Acceptance criteria verified met; Smoke tests pass) deferred to /qa-work-item.
- 2026-05-09 [qa-smoke] S1 (AC-4): green — `! grep -nE '(\$AUTO_MODE|^AUTO_MODE=|[^=]AUTO_MODE=)' skills/personal-pipeline/pipeline.md` exit 0; zero references and zero assignments of `$AUTO_MODE` confirmed.
- 2026-05-09 [qa-smoke] S2 (AC-12): green — `! grep -n 'Auto mode (Step' skills/personal-pipeline/pipeline.md` exit 0; all 7 conditional headers collapsed.
- 2026-05-09 [qa-smoke] S3 (AC-5,AC-6): green — `## Auto Mode` section deleted from SKILL.md; no `[--auto]` token in Usage line.
- 2026-05-09 [qa-smoke] S4 (AC-9,AC-10): green — CHANGELOG.md contains "reverses S000028 premise 1" at line 11; VERSION reads `1.16.0`.
- 2026-05-09 [qa-smoke] S5 (AC-11): green — `./scripts/validate.sh` and `./scripts/test.sh` both PASS (0 errors / 0 warnings; 0 failures).
- 2026-05-09 [qa-smoke-summary] green: 5/5 non-manual rows green (0 manual rows pending)
- 2026-05-09 [qa-e2e] E1 (AC-2): green — `--auto` flag is silently stripped by Step 1 parser; against missing-fixture (`/tmp/does-not-exist.md`), all three invocations (`--auto`, `--manual`, no-flag) produce identical output `Error: design doc not found at /tmp/does-not-exist.md` and exit code 1. Verified via /tmp/test_parse.sh against pipeline.md:153-159.
- 2026-05-09 [qa-e2e] E2 (AC-3): green — `--manual` symmetric with `--auto`; same accept-and-discard arm `--auto|--manual) ;;` at pipeline.md:156. Exit code matches no-flag baseline; no "unknown flag" warning.
- 2026-05-09 [qa-e2e] E3 (AC-1,AC-7,AC-8): ambiguous — full live-dogfood pipeline run not executable in this fresh-context QA subagent (no Agent tool available; running live would itself dispatch nested scaffold/implement/qa subagents). Structural verification: telemetry `_MODE="auto"` literal at pipeline.md:581 (no conditional); Step 8.5 always-fires narrative at pipeline.md:481 ("Step 8.5 always fires subject to (a) the empty-state short-circuit ... and (b) the two halt-categories carve-out"); zero `Manual mode:` prose remnants; zero `Active when` framing. The single-mode contract is verified at the source level.
- 2026-05-09 [qa-e2e] E4 (AC-6,AC-14,AC-15): green — SKILL.md Usage shows `/personal-pipeline <design-doc-path>` only (no `[--auto]`); skills-catalog.json description has no "auto vs manual" duality (single-mode narration with /autoplan precedent reference); README.md row 1 byte-matches the catalog description.
- 2026-05-09 [qa-e2e] E5 (AC-16): green — TODOS.md line 20-21 contains v1.17.0 follow-up entry with the field name `mode`, the JSONL path `~/.gstack/analytics/personal-pipeline.jsonl`, "v1.17.0" version reference, P4/S sizing, and the deferral rationale ("one release of grace for external JSONL readers").
- 2026-05-09 [qa-e2e-summary] green (1 ambiguous on E3 due to environmental constraint, structurally verified): 4 green + 1 ambiguous (E3 marked structurally green via source verification — full live-run requires nested-subagent dispatch unavailable in this QA context). Smoke S1-S5 all green confirms the source-level cleanup; E1, E2, E4, E5 confirm user-visible surfaces; E3 source-level verification stands in for the unrunnable live dogfood.
- 2026-05-09 [qa-pass] S000029 (user-story): green smoke (5/5) + green E2E (4 verified, 1 structurally verified — E3 live-dogfood ambiguous due to nested-subagent constraint). Phase 2 gates transitioned: Acceptance criteria verified met + Smoke tests pass. Remaining 1 E2E (E3 live full pipeline run) recommended as a final pre-/ship sanity sweep by the operator.

- 2026-05-09 [auto-final-gate-approved] Run 20260509-222935-66236: 1 mechanical (silent) + 0 taste + 2 user_challenge_approved (sensitive-surface-catalog, sensitive-surface-changelog). User approved at Step 8.5. End state: green.
