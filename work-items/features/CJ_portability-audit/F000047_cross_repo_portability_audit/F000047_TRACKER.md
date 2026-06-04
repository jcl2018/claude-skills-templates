---
name: "Cross-repo portability audit for delivered skills"
type: feature
id: "F000047"
status: active
created: "2026-06-04"
updated: "2026-06-04"
repo: "/Users/chjiang/Documents/projects/claude-skills-templates"
branch: "cj-feat-20260604-140945-869"
blocked_by: ""
---

<!-- Prerequisite: Before scaffolding this work item, run /office-hours to
     produce a design plan in ~/.gstack/projects/. Distill that plan into
     DESIGN.md during Phase 1 below. -->

## Lifecycle

### Phase 1: Track

1. Create working branch: `git checkout -b feat/cross_repo_portability_audit`
2. Scaffold work item directory and TRACKER.md
3. Distill `DESIGN.md` from the /office-hours output (problem shape, big decisions, risks) — from `templates/doc-DESIGN.md`
4. Scaffold `ROADMAP.md` (scope, non-goals, decomposition, delivery timeline) — from `templates/doc-ROADMAP.md`
5. Define acceptance criteria (what "done" looks like for the whole feature)
6. Decompose into child user-stories
   → detail (DESIGN, SPEC, TEST-SPEC) lives in child stories

**Gates:**
- [x] /office-hours design produced (in `~/.gstack/projects/`)
- [x] Working branch created (`branch` field populated)
- [x] DESIGN + ROADMAP scaffolded
- [x] Acceptance criteria scoped
- [x] Broken down into child stories

### Phase 2: Implement

1. Child user-stories drive implementation (feature tracker coordinates)
2. Monitor child progress — update this tracker when children complete phases
3. Update Todos section — check off completed children, add discoveries
4. Update Files section with top-level changed files

**Gates:**
- [ ] All child stories have entered Phase 2+
- [ ] Feature-level Todos reflect remaining coordination work

### Phase 3: Ship

1. Run `/CJ_personal-workflow check` — verify all children pass validation
2. Verify smoke tests pass in CI (automated regression)
3. Walk E2E manually — run user-scenario verification before ship
4. Run `/ship` — creates feature PR (includes pre-landing code review)
5. Run `/land-and-deploy` — merges and verifies deployment
6. Run `/document-release` — post-ship doc audit; fix drifts inline or spawn D-tickets

**Gates:**
- [ ] `/CJ_personal-workflow check` — all children pass validation
- [ ] Smoke tests pass in CI
- [ ] E2E walked manually
- [ ] `/ship` — PR created (with pre-landing review)
- [ ] `/land-and-deploy` — merged and deployed
- [ ] `/document-release` — post-ship doc audit done; drifts fixed inline or spawned as D-tickets

## Acceptance Criteria

<!-- What "done" looks like for this feature. Each criterion should be
     testable and specific. -->

- [ ] A new `/CJ_portability-audit` skill prints a per-skill portability verdict table over the Check-14/15b selector set (`status != "deprecated"` + non-empty `files`, derived from the catalog at runtime — NOT hardcoded). Each finding names the skill, the executed repo-local dependency, and why it is a portability risk (declared level vs actual).
- [ ] The shared static-lint engine (`scripts/cj-portability-audit.sh`) runs as a new `validate.sh` advisory check — exit 0 in v1, findings visible in output.
- [ ] The audit surfaces at least one REAL finding on a workbench skill BEFORE adjudication (e.g. `CJ_qa-work-item → scripts/test.sh`), proving the check is not a no-op, then lands green via pre-seeded `portability_requires` adjudication.
- [ ] v1 ships the optional `portability_requires` catalog field and the engine honors it (listed dep → OK; stale listed dep → informational note, never a finding).
- [ ] The engine has integration coverage in `scripts/test.sh` (the `zzz-test-scaffold` pattern — the parallel test.sh edit every new validate.sh check needs).
- [ ] The new skill is documented: SKILL.md + USAGE.md (5 required H2 sections) + catalog entry + `doc/ARCHITECTURE.md` component roster line + `doc/PHILOSOPHY.md` decision-tree entry.
- [ ] The strict-tier correct-behavior spec is written verbatim into `doc/WORKFLOWS.md` (operator-requested, D4) — the tier ladder, the EXECUTED-vs-documented rule, the scoped carve-outs, and the expected-findings table — so the operator can confirm the implementation matches.
- [ ] The audit's first run flags the three `CJ_goal_*` orchestrators + `CJ_qa-work-item` + `CJ_implement-from-spec` as `standalone`-but-workbench-coupled (the D4 headline), then lands green via pre-seeded relabel/adjudication.
- [ ] `scripts/eval.sh --portability` mode + the new fixture-prep helper exist and run ONE leaf-skill case (`CJ_suggest`) locally green against a stripped + `.source`-neutralized scratch repo.

## Todos

<!-- Actionable items for this feature. Break into child tasks for
     large features. -->

- [ ] S000083 — Layer 1 static dependency lint engine + skill + validate.sh advisory check + test.sh fixture + catalog field + docs + one local Layer-2 case (the v1 must-ship scope).
- [ ] (Story 2 — DEFERRED follow-up, do NOT build this run) Layer 2 broad dynamic eval coverage across runnable leaf skills + orchestrator partial runs + nightly-CI job wiring in `eval-nightly.yml` + the advisory→hard-gate hardening (`PORTABILITY_STRICT=1`). Captured here as a thread, not an implementable artifact.

## Log

<!-- Chronological entries with dates and commit SHAs. -->

- 2026-06-04: Created. Cross-repo portability audit for delivered skills — a new `/CJ_portability-audit` skill (Approach B) that lints declared `portability` vs actual repo-local dependencies, advisory-first, sharing one engine between the skill and a validate.sh check. Splits into Story 1 (Layer 1 static lint, v1 must-ship) and Story 2 (Layer 2 dynamic eval, deferred).

## PRs

<!-- PR links with status (open/merged/closed). -->

## Files

<!-- Affected file paths. Populated during Track phase, updated during Implement. -->

- `scripts/cj-portability-audit.sh` (new — Layer 1 static-lint engine)
- `skills/CJ_portability-audit/SKILL.md` (new)
- `skills/CJ_portability-audit/USAGE.md` (new)
- `scripts/validate.sh` (new advisory check, shared engine)
- `scripts/test.sh` (new `zzz-test-scaffold` integration fixture)
- `skills-catalog.json` (new skill entry + `portability_requires` field + pre-seeded adjudicated deps)
- `scripts/eval.sh` (new `--portability` mode + fixture-prep helper)
- `doc/WORKFLOWS.md` (correct-behavior spec section — operator-requested)
- `doc/ARCHITECTURE.md` (component roster line)
- `doc/PHILOSOPHY.md` (decision-tree entry)

## Insights

<!-- Non-obvious findings worth remembering. Design decisions,
     trade-offs, patterns discovered. -->

- The self-declared `portability` field was an honor-system label; this feature turns it into a verified invariant. The headline finding is that the three `CJ_goal_*` orchestrators + `CJ_qa-work-item` + `CJ_implement-from-spec` are declared `standalone` but reach root workbench helpers — the audit makes the mislabel explicit.
- Producer-vs-consumer split: `/CJ_repo-init` is consumer-side (do the prereqs EXIST in a target repo); `/CJ_portability-audit` is producer-side (do the workbench's own skills reach for un-scaffoldable repo-local things). Related domain, different lifecycle — keep them separate (Approach C, unify-with-repo-init, was rejected as a confused-dual-audience smell).
- Advisory-first is mandatory, not timid: the workbench HAS real declared-vs-actual mismatches today, so v1 must surface findings WITHOUT hard-failing CI (mirrors the registered-doc requirements audit's "ADVISORY, agent-judged, NEVER a hard gate" posture). The `portability_requires` field is the reconciliation mechanism that lets v1 land green-by-adjudication while keeping each accepted dep visible.
- The `portability_requires` field is a v1 correctness prerequisite, NOT polish: without it the first run is all-red noise and the table is unusable. The workbench catalog is pre-seeded with the known-accepted deps so v1 lands green.
- Layer 2 is NOT a free reuse of `scripts/eval.sh` — three corrections are load-bearing: `.source` neutralization (else the stripped repo isn't stripped — the engine falls through to the real workbench clone), per-skill `--allowedTools` (the hardcoded `Bash,Read,Glob,Grep` blocks the risky skills), and new fixture-prep code. This is why broad Layer-2 coverage is deferred — it re-imports the parked-eval-harness cost/flake (D000023).

## Journal

<!-- Structured entries from the work-track journal command. Each entry has a type
     (decision, finding, blocker) and a Summary field. -->

- [decision] 2026-06-04 — Approach B (new `/CJ_portability-audit` skill, engine-in-script) chosen over Approach A (script + validate.sh only, no skill — under-delivers on the "new skill" intent) and Approach C (unify with `/CJ_repo-init` via `--mode consumer/producer` — confused-dual-audience, biggest blast radius). Summary: a dedicated skill that owns the static lint + orchestrates the dynamic eval, with the SAME static engine wired into validate.sh as the always-on advisory gate.
- [decision] 2026-06-04 (premise gate D2/D3 revision) — The Layer-2 dynamic pass drives the REAL skill via `claude --print` against a STRIPPED scratch repo, not just the preamble bash. Accepts cost + flake for genuine coverage. Orchestrators can't run headless end-to-end (they invoke `/ship`, `/office-hours`, subagents) — Layer 2's real coverage is leaf utilities + a partial orchestrator run.
- [decision] 2026-06-04 (premise gate D4) — Strict tier ladder: the bar is "works in a repo that has never seen this workbench." The self-resolution preamble (`.source` reach-back) is OK-with-note for `workbench`/`local-only` skills but a FINDING for `standalone` skills — this is the single most valuable finding class (it catches the mislabeled orchestrators).
- [decision] 2026-06-04 (premise gate D4) — The correct-behavior spec (tier ladder + EXECUTED-vs-documented rule + carve-outs + expected-findings table) is written verbatim into `doc/WORKFLOWS.md` per operator request, even though `/CJ_portability-audit` is a utility that by T000037 convention documents in `doc/ARCHITECTURE.md`. Adding a non-`CJ_goal_*` section to WORKFLOWS.md does NOT break Check 15b (it only ERRORs on a MISSING `CJ_goal_*` section). The standard ARCHITECTURE roster line + PHILOSOPHY decision-tree entry are ALSO added so the no-vanish checks pass.
- [decision] 2026-06-04 (spec review #6) — Layer 2's full reach (every runnable skill + nightly CI) is split out as Story 2; making a green nightly Layer-2 case a v1 gate re-imports the parked-eval-harness cost/flake (D000023). v1 Layer-2 deliverable is just the `--portability` mode + fixture-prep helper running ONE leaf-skill case locally green. Layer 1 is the sole v1 gate.
