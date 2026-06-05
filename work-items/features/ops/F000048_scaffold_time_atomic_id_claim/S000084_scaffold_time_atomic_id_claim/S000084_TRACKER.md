---
name: "Scaffold-time atomic ID claim — helper + Step 5.1 wiring + tests"
type: user-story
id: "S000084"
status: active
created: "2026-06-04"
updated: "2026-06-04"
parent: "F000048"
repo: "/Users/chjiang/Documents/projects/claude-skills-templates"
branch: "cj-feat-20260604-225454-7907"
blocked_by: ""
# pr: ""  # optional; populate with PR URL (e.g. https://github.com/org/repo/pull/123) for explicit PR-state lookups. The `## PRs` section below is the canonical home for PR links; this frontmatter field is a machine-readable shortcut consumed by /CJ_goal_run Branch(f)/(g) gh pr view dedup. Either convention is accepted.
---

<!-- Prerequisite: Before scaffolding this work item, run /office-hours to
     produce a design plan in ~/.gstack/projects/. Distill that plan into
     DESIGN.md during Phase 1 below. (For atomic stories that derive directly
     from the parent feature's /office-hours session, the parent's design is
     sufficient context — DESIGN.md may be a brief stub linking to the parent.) -->

## Lifecycle

### Phase 1: Track

1. Read parent tracker to understand scope
2. Create working branch: `git checkout -b feat/scaffold_time_atomic_id_claim` (or use parent's branch if shipping in same PR)
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
4. Run `/CJ_personal-workflow check` on modified docs after updates
5. Update tracker: move through lifecycle phases, add journal entries
6. Update Files section with changed file paths

**Gates:**
- [x] Acceptance criteria verified met (all 7 smoke ACs pass; E2E rows are Phase-3 manual)
- [x] Smoke tests pass (`tests/cj-id-claim.test.sh` 7/7; 25-round race 0 dupes; `validate.sh` PASS 0/0)
- [x] Todos section reflects remaining work (no stale items)
- [x] Files section updated with changed files

### Phase 3: Ship

1. Run `/CJ_personal-workflow check` — verify all validation passes
   → should show PASS for template, lifecycle, traceability badges
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

- [x] Two concurrent `cj-id-claim.sh` invocations with the same `--floor` return distinct IDs every round of a 20+ round loop (no duplicate). — Case 2, 25 rounds, 0 dupes (stable across 4 reruns).
- [x] A claim whose ID is already on origin/main, or older than `--ttl-hours`, is reaped and not counted toward the next ID. — Cases 3 (on-origin) + 4 (TTL).
- [x] A re-run with a live same-branch claim and no work-item dir yet reuses the same ID (idempotent). — Case 6 (reuse holds; advances once work-item dir materializes).
- [x] When the helper is absent/non-executable, scaffold Step 5.1 falls back to the 3-source `printf` and still mints an ID. — fail-soft wiring in scaffold.md Step 5.1 (`[ -x "$_CLAIM" ]` guard + `[ -n "$NEW_ID" ] ||` fallback); E1 is the Phase-3 manual walk.
- [x] Prefix isolation: an F-claim does not advance an S-claim and vice versa. — Case 5.
- [x] `git-common-dir` resolves to an absolute path so a linked worktree and the root checkout share one claim root. — Case 7 (linked worktree + nested subdir, one shared root, no stray root).
- [x] `tests/cj-id-claim.test.sh` is registered in `scripts/test.sh` and observably executed (its name appears in suite output); validate.sh + test.sh green. — S7 PASS (`bash scripts/test.sh 2>&1 | grep -q cj-id-claim`); validate.sh Errors 0 / Warnings 0.

## Todos

<!-- Actionable items for this story. -->

- [x] Write `scripts/cj-id-claim.sh` (`--prefix/--floor/--ttl-hours/--dry-run`; reap → idempotent-reuse → atomic claim loop; absolute CLAIM_ROOT; octal-safe parse). chmod +x.
- [x] Wire `skills/CJ_scaffold-work-item/scaffold.md` Step 5.1 to call the helper with fail-soft fallback + update the Source-4 prose.
- [x] Write `tests/cj-id-claim.test.sh` (7 cases incl. the looped concurrent race).
- [x] Register `tests/cj-id-claim.test.sh` in `scripts/test.sh` (added after the `cj-goal-common-sync.test.sh` block, matching the existing invocation pattern) — verified via grep + S7 suite-output check.
- [x] Bump `CJ_scaffold-work-item` version in `skills-catalog.json` (1.0.0 → 1.0.1; + SKILL.md + USAGE.md frontmatter kept in sync). **Did NOT add `portability_requires`** — see Journal: the portability audit (Check 18) classifies the `_CLAIM="$(git rev-parse --show-toplevel)/scripts/cj-id-claim.sh"` line as a non-executed reference (its `is_exec` heuristic only flags `bash X`/`"X"`/`[ -f X ]`/`$VAR/scripts/` positions), so scaffold is already `portable` with FINDINGS=0; an unreferenced `portability_requires` entry would REGRESS it to a `portable-with-notes` stale-note (verified empirically). The conditional "if declared" was not met.
- [x] Update `skills/CJ_scaffold-work-item/USAGE.md` — added a Source-4/claim paragraph to Mental model AND bumped `last-updated:` to a second-resolution ISO-8601 timestamp (Check-14 clean).
- [ ] Doc-sync (DEFERRED to the pipeline's later doc-sync step — NOT this implement run): `CLAUDE.md` Scripts reference table (+ `cj-id-claim.sh`), `doc/WORKFLOWS.md` CJ_scaffold-work-item Touches, `doc/ARCHITECTURE.md` ID-minting. Intentionally not touched here (editing non-doc + doc together trips the doc-sync gate).

## Log

<!-- Chronological entries with dates and commit SHAs. -->

- 2026-06-04: Created. Atomic mkdir-CAS claim dir in the shared `.git` common-dir as a 4th ID source that closes the scaffold-before-push race; helper-owned engine + fail-soft Step 5.1 wiring + looped race test.
- 2026-06-04: Implemented (Phase 2, auto mode). Wrote `scripts/cj-id-claim.sh` (engine: arg-parse → absolute CLAIM_ROOT under git-common-dir → reap [on-origin + TTL, portable `stat` probe] → same-branch reuse → bounded atomic mkdir-CAS loop with octal-safe parse + meta write; `--dry-run` read-only). Wired scaffold.md Step 5.1 (helper call + fail-soft fallback + Source-4 prose). Wrote `tests/cj-id-claim.test.sh` (7 cases) and registered it in `scripts/test.sh`. Bumped CJ_scaffold-work-item 1.0.0→1.0.1 (catalog + SKILL.md + USAGE.md), USAGE.md Mental-model now documents Source 4. Smoke green: new test 7/7 (25-round race 0 dupes, stable over 4 reruns), `validate.sh` Errors 0/Warnings 0 (Check 18 portability FINDINGS=0), test.sh S7 suite-output check PASS. No commit (later pipeline step).

## PRs

<!-- PR links with status (open/merged/closed). -->

## Files

<!-- Affected file paths. -->

- `scripts/cj-id-claim.sh` (NEW, chmod +x) — the claim engine.
- `skills/CJ_scaffold-work-item/scaffold.md` (Step 5.1 — helper call + fail-soft fallback + Source-4 prose)
- `tests/cj-id-claim.test.sh` (NEW, chmod +x) — 7 cases incl. the 25-round race.
- `scripts/test.sh` (registered the new test, after the cj-goal-common-sync block)
- `skills-catalog.json` (version bump 1.0.0→1.0.1; NO portability_requires — see Journal/Todos rationale)
- `skills/CJ_scaffold-work-item/SKILL.md` (frontmatter version 1.0.0→1.0.1)
- `skills/CJ_scaffold-work-item/USAGE.md` (version 1.0.0→1.0.1; last-updated bumped; Mental-model Source-4 paragraph)
- `CLAUDE.md`, `doc/WORKFLOWS.md`, `doc/ARCHITECTURE.md` — NOT touched here; deferred to the pipeline's doc-sync step.

## Insights

<!-- Non-obvious findings worth remembering. -->

- `mkdir` is the CAS: it fails atomically if the directory exists. Combined with the shared-`.git`-common-dir visibility across sibling worktrees, that is the entire lock — no lockfile, no daemon, no network.
- REAP INVARIANT: a claim is removed only if its ID is already on origin/main (merged → permanently taken) OR it is older than the TTL (>> any real build). A freshly-created competing claim is never within reap range, so reaping can never delete a live winner — concurrent-distinct-IDs holds even with reap interleaved.
- `--floor` is a point-in-time snapshot of Sources 1-3 captured by the caller; the helper adds Source-4 (claim-dir) protection on top and does NOT re-poll open-PRs/origin inside the loop. The claim dir is the continuously-atomic source; Sources 2+3 stay the cross-clone backstop.

## Journal

<!-- Structured entries from the work-track journal command. Each entry has a type
     (decision, finding, blocker) and a Summary field. -->

- [decision] 2026-06-04 — Helper located via `git rev-parse --show-toplevel` (worktree's own `scripts/`) but the claim dir lives under `git rev-parse --git-common-dir` (the SHARED `.git`); CLAIM_ROOT normalized to absolute (`cd "$(...)" && pwd`). Summary: a relative common-dir would give two agents with different cwd different claim roots and silently break the CAS — absolute is load-bearing.
- [decision] 2026-06-04 — Did NOT add `scripts/cj-id-claim.sh` to `CJ_scaffold-work-item`'s `portability_requires` (the SPEC made this conditional on "if declared / to keep the audit clean"). Summary: the portability audit's `is_exec` heuristic (scripts/cj-portability-audit.sh ~L299-308) only treats a `scripts/*.sh` token as an EXECUTED dependency when it sits in a runnable position (`bash X` / `"X" …` / `[ -f X ]` / `$VAR/scripts/…`). The wired line is `_CLAIM="$(git rev-parse --show-toplevel)/scripts/cj-id-claim.sh"` — an ASSIGNMENT whose token is preceded by `)/`, not a runnable cue — so the engine classifies it DOCUMENTED (dropped silently) and scaffold stays `portable` with FINDINGS=0. Verified empirically: adding the entry regresses scaffold to `portable-with-notes` with a `'scripts/cj-id-claim.sh' no longer referenced` stale note. So the goal ("audit clean") is BEST served by NOT adding it. Tier unchanged (`standalone`) because the fail-soft fallback keeps scaffold runnable with zero workbench.
- [finding] 2026-06-04 — Portable claim-dir mtime→epoch via a `stat` probe (GNU `stat -c %Y` vs BSD/macOS `stat -f %m`), mirroring the repo's `date_to_epoch` probe-then-branch idiom; no GNU-only `date -d`/`date -r`. An unreadable dir returns epoch 0 (treated as "very old" → reapable), which is conservative and never reaps a live claim (a freshly-mkdir'd dir is always stat-able). Test backdates via POSIX `touch -t 200001010000` (macOS-safe; `touch -d "2 days ago"` is GNU-only and absent here).
- [finding] 2026-06-04 — Same-branch reuse + dry-run interaction: because reuse (Phase 2) runs BEFORE the atomic loop and returns the existing live same-branch claim, a `--dry-run` re-run on the same branch with a live claim correctly prints that SAME id (not floor+1). The dry-run "would-be id = floor+1" path is only reached when no reusable same-branch claim exists. Both behaviors are correct per the idempotency contract and are exercised by Cases 1/6.
- [qa] 2026-06-04 — QA pass GREEN (independent re-run, working tree uncommitted as expected for the cj_goal_feature pipeline). All 7 ACs verified against S000084_TEST-SPEC.md rows. `bash tests/cj-id-claim.test.sh` → 7/7, RESULT: PASS. Race-loop (Case 2 / AC-2): 25 rounds, 0 duplicate IDs, 0 failed invocations — re-run 4× total (1 in-suite + 3 standalone), stable, no flake. `bash scripts/validate.sh` → Errors 0 / Warnings 0 / RESULT: PASS, incl. Check 18 portability FINDINGS=0 (`CJ_scaffold-work-item | standalone | portable` — the no-`portability_requires` decision verified clean). `scripts/test.sh` registration confirmed EXECUTED not silent: a real `bash scripts/test.sh` run emits `Running tests/cj-id-claim.test.sh…` + `OK: …all 7 cases pass` (suite lines 1073-1074), and the invocation block (test.sh L1424-1430) is an unconditional `bash …` with pass/fail accounting. AC-6 fail-soft wiring present in scaffold.md Step 5.1 (L233-237: `_CLAIM=…/scripts/cj-id-claim.sh`, `[ -x "$_CLAIM" ]` guard, `[ -n "$NEW_ID" ] ||` 3-source printf fallback); E1 is a Phase-3 manual walk per TEST-SPEC. Both new files executable (`-rwxr-xr-x`). Per-AC: AC-1 Case1 CLAIMED_ID=F000048; AC-2 Case2 25rds/0dup; AC-3 Case3 on-origin reap+re-mint; AC-4 Case4 TTL reap (year-2000 → F000001); AC-5 Case6 same-branch reuse holds then advances; AC-7 Case5 (F/S isolation) + Case7 (worktree+subdir shared root); AC-6 static wiring verified. No code changes made by QA (observe-only); no commit (orchestrator commits post-QA).
