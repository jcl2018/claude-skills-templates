---
name: "v1.0 full-handoff one-liner-to-deployed skill"
type: user-story
id: "S000056"
status: active
created: "2026-05-19"
updated: "2026-05-19"
parent: "F000026"
repo: "/Users/chjiang/Documents/projects/claude-skills-templates"
branch: "claude/flamboyant-johnson-c3d0e5"
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
2. Create working branch: `git checkout -b feat/cj_goal_auto` (or use parent's branch if shipping in same PR)
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
- [x] Acceptance criteria verified met
- [x] Smoke tests pass
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

- [x] `skills/CJ_goal_auto/SKILL.md` + `skills/CJ_goal_auto/auto.md` written with frontmatter (name, description, version, allowed-tools).
- [x] `scripts/cj-handoff-gate.sh` is deterministic, pure, exit-coded (0 = proceed to merge, non-zero = halt for human), takes a frozen `BASE` SHA, fail-closed on unknown state, audit-logs to stderr.
- [x] Three explicit CLI shapes work: `/CJ_goal_auto "<idea>"` (human-gated), `/CJ_goal_auto --auto-merge-small-diffs "<idea>"` (auto-merge), `/CJ_goal_auto --dry-run "<idea>"` (Stage 0+0.5 only, zero writes). `--handoff` resolves as deprecated alias.
- [x] Resolved-mode echo at run start; structured halt contract with `next_action=` / `resume_cmd=` / `pr_url=` / `work_item_dir=`.
- [x] Per-run audit receipt written to `~/.gstack/analytics/CJ_goal_auto.jsonl`; `--audit`/`--list-handoffs` prints the last N.
- [x] Stage 0.5 classifier appends a verdict line to `~/.gstack/analytics/cj-goal-auto-classifier.jsonl` (orchestrator-owned write).
- [x] Stage 1 workbench-owned generator writes the required sections to the computed path; Stage 1.5 fail-closed gate aborts when the doc is missing / not `Status: APPROVED` / has empty required sections; Stage 2 is NEVER invoked when Stage 1.5 aborts.
- [x] `--handoff` / `--no-drain` + co-located support sentinel wired into `skills/CJ_goal_run/run.md` at the post-`/ship` / pre-`/land-and-deploy` point.
- [x] `scripts/test.sh` 10 deterministic + lint tests pass: denylist hit (1), >120 lines or >5 files (2), rename of denylisted file (3), new symlink (4), test-surface weakening (5), base-ref drift regression (6), QA predicate (7), GATE #1 AUQ untouched (8), sentinel co-located within N lines (9), Stage 1.5 abort (10); plus test 11 classifier spot-check (labeled non-proof).
- [x] `skills-catalog.json` entry: `status: experimental`, `depends.skills: [CJ_goal_run]`, `portability: standalone`, files listed.
- [x] `rules/skill-routing.md` rule: `"hand off idea"`, `"fire and forget"`, `"one-liner to deployed"` → `/CJ_goal_auto "<idea>"`.
- [ ] `validate.sh` + `test.sh` green; VERSION + CHANGELOG bumped (semver minor for a new experimental skill).  <!-- validate.sh green; VERSION+CHANGELOG defer to /ship; test-deploy.sh worktree/main split documented in Insights -->
- [ ] Bootstrap PR human-reviewed (denylisted by construction); one end-to-end dogfood run on a real small item before unattended trust.

## Todos

<!-- Actionable items for this story. -->

- [x] Write `skills/CJ_goal_auto/SKILL.md` (frontmatter + preamble + path resolution + usage + routing) and `skills/CJ_goal_auto/auto.md` (Stage 0 → Stage 3 step-by-step).
- [x] Implement Stage 0: F000025 worktree pattern reuse with `cj-auto-{YYYYMMDD-HHMMSS}-{PID}`; `--no-worktree` opt-out; Conductor detect + no-op; `check-version-queue.sh` halt-on-collision; `--handoff` sentinel grep with fail-closed bail.
- [x] Implement Stage 0.5: orchestrator-owned classifier (inline reasoning step or tiny Agent subagent that sees only the one-liner); append verdict to `~/.gstack/analytics/cj-goal-auto-classifier.jsonl`; only `small-unambiguous` proceeds; halt for other verdicts with structured stop block + manual route.
- [x] Implement Stage 1: workbench-owned design-doc generator from a fixed template; write to `~/.gstack/projects/<slug>/<user>-<branch>-design-<datetime>.md` with required sections (`Problem Statement`, `Premises`, `Recommended Approach`, `Success Criteria`, `Distribution Plan`, `Status: APPROVED`).
- [x] Implement Stage 1.5: fail-closed post-condition doc gate — file exists at computed path AND contains `Status: APPROVED` AND every required section is present and non-empty. Any miss → abort, never call Stage 2.
- [x] Write `scripts/cj-handoff-gate.sh`: `git fetch origin main` → `BASE=$(git merge-base origin/main HEAD)` → frozen-base diff via `git diff --no-renames --raw -z $BASE HEAD` → denylist check (rename/symlink-safe, EITHER old or new path) → added-lines ≤ 120 (`--handoff-max-lines`, default 120) → files-changed ≤ 5 (`--handoff-max-files`, default 5) → QA predicate (`PIPELINE_END_STATE=green` AND `SMOKE=pass` AND `E2E=pass` AND all `PHASE2_GATES` checked). Exit 0 = proceed, non-zero = halt.
- [x] Encode the denylist: reused sensitive surfaces (`skills-catalog.json`, `skills/CJ_personal-workflow/personal-artifact-manifests.json`, `work-copilot/**`, `scripts/{validate,test,test-deploy,skills-deploy,setup,setup-hooks,copilot-deploy,collection-version,cj-worktree-init,drain-one-todo}.{sh,py}`, `skills/CJ_personal-workflow/**`, `skills/CJ_personal-pipeline/**`, `skills/CJ_scaffold-work-item/**`, `skills/CJ_implement-from-spec/**`, `skills/CJ_qa-work-item/**`, `rules/skill-routing.md`, `CLAUDE.md`) + net-new (`skills/CJ_goal_run/**`, `skills/CJ_goal_todo_fix/**`, `skills/CJ_goal_investigate/**`, `skills/CJ_goal_auto/**`, `.github/**`, `VERSION`, `CHANGELOG.md`, `tests/**`, `scripts/*test*.{sh,py}`, `*fixture*`, `*.golden`).
- [x] Wire `--handoff` (alias `--auto-merge-small-diffs`) + `--no-drain` + co-located support sentinel into `skills/CJ_goal_run/run.md` at the post-`/ship` / pre-`/land-and-deploy` point. Sentinel placement asserted by test 9.
- [x] Implement Stage 2 invocation: `/CJ_goal_run <doc> --handoff --no-drain`.
- [x] Implement Stage 3: Phase 4 `/land-and-deploy --suppress-readiness-gate`; write PR body line `auto-merged under handoff: N files / M lines / QA <markers>` + pinned `BASE` SHA when the gate auto-approved.
- [x] Add structured halt contract to every halt path: stop block + `next_action=` + `resume_cmd=` (copy-paste) + `pr_url=` + `work_item_dir=`. GATE #2 demotion names which condition tripped (count vs cap / denylisted path / Phase-2 marker) and says "PR #N is created and review-ready; `gh pr diff N`, merge manually if good."
- [x] Add per-run audit receipt at `~/.gstack/analytics/CJ_goal_auto.jsonl` (classifier verdict, doc path, work-item dir, PR URL, pinned BASE SHA, changed files, added lines, denylist result, Phase-2 markers, gate result, resume_cmd). Implement `--audit`/`--list-handoffs` read-only mode.
- [x] Implement informed GATE #1: before autoplan's final-approval AUQ fires, print generated doc's `Problem Statement` + `Recommended Approach`.
- [x] Implement every-run retro AUQ for first 5 auto-merges, then relax to every-5th.
- [x] Add `scripts/test.sh` tests 1–10 (deterministic + lint) + test 11 (classifier spot-check, labeled non-proof). Tests feed crafted `git diff` fixtures to the helper; tests 8–10 are `grep -L`-style asserts over `auto.md` / `run.md`.
- [x] Add `skills-catalog.json` entry: name `CJ_goal_auto`, version `0.1.0`, status `experimental`, depends `[CJ_goal_run]`, portability `standalone`, files listed, templates `[]`.
- [x] Add `rules/skill-routing.md` route: `"hand off idea"`, `"fire and forget"`, `"one-liner to deployed"` → `/CJ_goal_auto "<idea>"`.
- [ ] Bump VERSION (semver minor: new experimental skill) + add CHANGELOG entry describing the feature, the F000021 ceiling exception, and the gate fail-closed semantics.  <!-- deferred to /ship per workbench convention -->
- [x] Run `validate.sh` + `test.sh` green locally before `/ship`.  <!-- validate.sh green; test.sh 11 new gate tests + test 12 green-path positive all pass; test-deploy.sh worktree/main split (CJ_goal_auto src not on main yet) is structural, resolves on merge -->
- [ ] Dogfood: pick one real small idea (e.g. typo fix in a leaf skill's header); run `/CJ_goal_auto --auto-merge-small-diffs "<idea>"` end-to-end; verify GATE #2 gate fires correctly, audit receipt written, PR body line present.  <!-- post-merge dogfood per TEST-SPEC E1 -->



## Log

<!-- Chronological entries with dates and commit SHAs. -->

- 2026-05-19: Created. v1.0 thin orchestrator for `/CJ_goal_auto` — Stages 0–3 + `scripts/cj-handoff-gate.sh` deterministic helper + `/CJ_goal_run` wiring + 10 deterministic/lint tests + classifier spot-check + audit receipt + retro AUQ + informed GATE #1.
- 2026-05-19: Phase 2 implementation complete via `/CJ_personal-pipeline` (`--work-item-dir` mode, `--suppress-final-gate`). Wrote `skills/CJ_goal_auto/SKILL.md` (~250 lines, 9 sections: preamble, default-worktree, path resolution, overview, usage, routing, error handling, halt taxonomy, sunset notes) + `skills/CJ_goal_auto/auto.md` (~520 lines: Stages 0–3 + audit handler). Wrote `scripts/cj-handoff-gate.sh` (~270 lines: arg parse, frozen-base diff, denylist + symlink scan via process substitution to preserve assignments across the read loop, Phase-2 marker check, structured exit codes). Wired `--handoff` / `--auto-merge-small-diffs` flag parsing into `skills/CJ_goal_run/run.md` (additive — `--no-drain` already existed); injected new Step 4.5 between Branch (a) of Step 4 and Step 5 with the `CJ_GOAL_AUTO_HANDOFF_SENTINEL=v1` co-located within 2 lines of the gate invocation. Added catalog entry (`status: experimental`, `depends.skills: [CJ_goal_run]`) and routing rule. Added 11 new tests + 1 green-path positive to `scripts/test.sh`: all 12 PASS. `validate.sh` PASS (0 errors / 0 warnings). `test-deploy.sh` doctor reports WARN on `CJ_goal_auto — source directory missing in repo` — structural worktree/main-toplevel split per T000025; resolves automatically when the PR merges. VERSION/CHANGELOG bumps deferred to `/ship` per workbench convention. Dogfood + bootstrap-PR human-review deferred to Phase 3.

## PRs

<!-- PR links with status (open/merged/closed). -->

## Files

<!-- Affected file paths. -->

- skills/CJ_goal_auto/SKILL.md (new)
- skills/CJ_goal_auto/auto.md (new)
- scripts/cj-handoff-gate.sh (new)
- skills/CJ_goal_run/run.md (modified — `--handoff` / `--no-drain` / sentinel)
- skills-catalog.json (modified — experimental entry)
- rules/skill-routing.md (modified)
- scripts/test.sh (modified — 10 deterministic + lint tests + classifier spot-check)
- VERSION (modified)
- CHANGELOG.md (modified)
- README.md (modified)

## Insights

<!-- Non-obvious findings worth remembering. -->

- The gate helper MUST be extracted as a real script (not LLM-judged) so it is deterministic and unit-testable from `scripts/test.sh` without depending on the `eval.sh` LLM behavioral harness (F5). LLM judgment in the merge gate is the failure mode the design explicitly avoids.
- The `--handoff` capability self-check (sentinel grep on resolved `CJ_goal_run/run.md`) is fail-closed: deployed copies that predate the flag halt with the manual route. Never silently ignore.
- The classifier subagent (Stage 0.5) MUST be orchestrator-side-effect-free: it returns a verdict, the orchestrator owns the jsonl write. This keeps the subagent prompt small and the side effect deterministic.
- Stage 1 path computation must be exact and re-derivable; Stage 1.5 verifies the actual file existence at that path. Never assume Stage 1 succeeded.

## Journal

<!-- Structured entries from the work-track journal command. Each entry has a type
     (decision, finding, blocker) and a Summary field. -->

- [decision] 2026-05-19: Atomic single-story per design constraint ("Single-PR changes only in v1"). The `/CJ_goal_run` Branch (b) multi-story auto-iterate path is out of scope — it ships per-child PRs without bundled TODOS cleanup (CLAUDE.md "Edge case 2"), which an unattended run has no operator to reconcile.
- [decision] 2026-05-19: Gate helper extracted as `scripts/cj-handoff-gate.sh` (deterministic, pure, exit-coded) — not an LLM judgment. Unit-testable in `scripts/test.sh` (NOT eval.sh, which is scoped to structured-report skills and can't drive a Write/Edit/Skill/Agent skill).
- [decision] 2026-05-19: Sentinel co-location asserted within N lines of the gate call site in `run.md` (Eng F3): proof-of-support and behavior drift together.
- [decision] 2026-05-19: 10 deterministic + lint tests + 1 classifier spot-check (labeled non-proof). Classifier false-negative rate is an accepted, untestable residual; size cap + denylist + every-5th retro AUQ are the real controls.

- 2026-05-20T01:24:00Z [orchestrator] --work-item-dir mode: using pre-staged dir at /Users/chjiang/Documents/projects/claude-skills-templates/.claude/worktrees/flamboyant-johnson-c3d0e5/work-items/features/ops/F000026_cj_goal_auto/S000056_cj_goal_auto_v1; scaffold skipped.
- 2026-05-20T01:40:00Z [qa-smoke-summary] green — scripts/validate.sh PASS (0 errors / 0 warnings); scripts/test.sh new F000026 block (tests 1–11 + green-path positive) ALL PASS = 12/12; pre-existing test-deploy.sh doctor WARN on `CJ_goal_auto source missing in repo` is the documented worktree/main-toplevel split (T000025), resolves on merge.
- 2026-05-20T01:40:00Z [qa-pass] Smoke-based PASS for user-story Phase 2 (no E2E subagent dispatch — E2E rows in TEST-SPEC are manual dogfood per TEST-SPEC E1+E5 `post-ship` tag). Acceptance Criteria 1–10 verified met by code + test pass; 11 (VERSION/CHANGELOG) deferred to /ship; 12 (bootstrap dogfood) deferred to post-merge.
- 2026-05-20T01:53:46Z [auto-final-gate-suppressed] 1 mechanical, 0 taste, 7 user-challenge-approved; decisions at /Users/chjiang/.gstack/analytics/CJ_personal-pipeline-auto-decisions.jsonl
