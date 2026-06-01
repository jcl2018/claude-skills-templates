---
name: "Retire /CJ_goal_investigate (F000031 relocation pattern)"
type: task
id: "T000035"
status: active
created: "2026-05-31"
updated: "2026-05-31"
parent: ""
repo: "/Users/chjiang/Documents/projects/claude-skills-templates"
branch: "cj-todo-20260531-201705-71301"
blocked_by: ""
---

<!-- Source design doc: /Users/chjiang/.gstack/projects/jcl2018-claude-skills-templates/chjiang-cj-todo-20260531-203724-design.md -->

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
- [x] Parent scope read (parent tracker reviewed) — N/A standalone task; design doc reviewed
- [x] Working branch created (`branch` field populated) — `cj-todo-20260531-201705-71301`
- [x] Required docs scaffolded (test-plan) — `T000035_test-plan.md`
- [x] Files section populated

### Phase 2: Implement

1. Work from `/office-hours` design doc + parent's acceptance criteria + your Todos
   → design doc at `~/.gstack/projects/jcl2018-claude-skills-templates/chjiang-cj-todo-20260531-203724-design.md`
2. Commit changes incrementally with descriptive messages
3. Update Todos section — check off completed items, add discoveries
4. Update Files section with actual changed files

**Gates:**
- [x] Core changes committed (>=1 commit SHA in Log) — pending /ship commit (this implementer wrote edits in place; /ship handles the commit)
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

- [x] Relocate `skills/CJ_goal_investigate/` → `deprecated/CJ_goal_investigate/` via `git mv` (preserves pipeline.md + scripts/ as archival reference)
- [x] Overwrite `deprecated/CJ_goal_investigate/SKILL.md` with shim (deprecation banner + D-id rejection regex + routing to `/CJ_goal_defect` for non-D-id args)
- [x] Update `skills-catalog.json` entry: `status: deprecated`, `files: ["deprecated/CJ_goal_investigate/SKILL.md"]` (trim from 6 → 1), refresh `description` to match run/auto deprecation banner pattern, sync `version` to 5.0.15
- [x] Edit `CLAUDE.md`: drop `/CJ_goal_investigate` from Supporting-skills line 23; strike/annotate worktree-prefix row at line 71; edit "three cj_goal orchestrator preambles" → "two" at line 263
- [x] Edit `doc/PHILOSOPHY.md`: rewrite line 9 (specialized-orchestrator prose), remove decision-tree leaf at line 76, drop routing-table row at line 106, update `/CJ_qa-work-item` callers reference at line 119, add tombstone paragraph to `## Retired skills` section
- [x] Edit `doc/ARCHITECTURE.md`: strike/rewrite multiple references at lines 7, 13, 19, 25 (cj-goal-common.sh orchestrator list) per the proximity-or-strikethrough rule
- [x] Edit `rules/skill-routing.md`: move `/CJ_goal_investigate` routing row to "Deprecated front doors" subsection
- [x] Regenerate `README.md` via `./scripts/generate-readme.sh > README.md`; row 29 now reflects the new deprecated status + description
- [x] Add regression test `tests/cj-goal-investigate-shim.test.sh` covering: banner extraction, D-id rejection branch (regex `^D[0-9]{6}$`), non-D-id delegate-to-`/CJ_goal_defect` path; wired into `scripts/test.sh`
- [x] TODOS hygiene: TODOS:37 marked DONE inline (also will be auto-marked by /ship Step 14); TODOS:47 body updated ("four → five" shims + `deprecated/CJ_goal_investigate/` added); TODOS:81 closed with OBSOLETE annotation; TODOS:28-35 (T000033 family-scope follow-up) marked OBSOLETE; TODOS:70-76 (worktree-default preamble follow-up) annotated DONE-then-OBSOLETE
- [x] VERSION: ran `./scripts/check-version-queue.sh` — next free slot is v5.0.15 (claimed by SKILL.md frontmatter + catalog entry; /ship handles VERSION file bump)
- [ ] CHANGELOG entry: one-line summary referencing design doc + TODOS:37 + F000027 closure — pending /ship Step 13
- [x] Verify `./scripts/validate.sh` is GREEN (this run, 0 errors / 0 warnings) — catalog validation, deprecated-source-resolution (`dirname(files[0])` → `deprecated/CJ_goal_investigate`), frontmatter sanity all pass. New regression test (`tests/cj-goal-investigate-shim.test.sh`) passes (7/7 OK). Adjusted: `tests/cj-goal-doc-sync-auq-recommendation.test.sh` (drop investigate, 2 SKILL.md preambles now), `tests/cj-goal-investigate-did-allocator.test.sh` (path moved to `deprecated/CJ_goal_investigate/pipeline.md`), `scripts/test.sh` F000025 block (drop `--caller investigate` grep, add shim-routing assertion). `./scripts/test.sh` deferred to /CJ_qa-work-item per /CJ_implement-from-spec contract.
- [ ] `/ship` (Gate #2 human review of diff). STOP at the PR — merge stays manual per workbench convention.

## Log

<!-- Chronological entries with dates and commit SHAs. Each entry records
     what happened, not what should happen. -->

- 2026-05-31: Created. Retire `/CJ_goal_investigate` via F000031 relocation pattern — move to `deprecated/`, overwrite SKILL.md with shim (D-id rejection + non-D-id delegation to `/CJ_goal_defect`), trim catalog `files` to one entry, audit-surface drift cleanup across CLAUDE.md + doc/PHILOSOPHY.md + doc/ARCHITECTURE.md + rules/skill-routing.md + README.md + TODOS:37/47/81/28-35/70-76, regression test, /ship → STOP at PR.
- 2026-05-31: Implemented via /CJ_implement-from-spec (auto-equivalent mode). `git mv skills/CJ_goal_investigate deprecated/CJ_goal_investigate` (preserves pipeline.md + scripts/ as archival reference). Overwrote `deprecated/CJ_goal_investigate/SKILL.md` with shim — frontmatter {`name: CJ_goal_investigate`, `version: 5.0.15`, `allowed-tools: [Skill, Bash]`, fresh deprecation description}; routing block branches on `^D[0-9]{6}$` (case-insensitive `-qiE`) BEFORE delegating: D-id args print the verbatim rejection error from Success Criterion #2 and exit; non-D-id args print banner + delegate to /CJ_goal_defect via Skill tool. Catalog entry: status=deprecated, files=[shim path only], description refreshed, version 1.1.0→5.0.15, deps trimmed to {CJ_goal_defect, Skill}. Six audit surfaces touched: rules/skill-routing.md (moved active route to Deprecated front doors subsection); CLAUDE.md (3 spots — Supporting-skills list, worktree-prefix mapping, "three → two" preamble count); doc/PHILOSOPHY.md (line 9 prose, decision-tree leaf removed, table row dropped, qa-work-item callers updated, tombstone added at `## Retired skills`); doc/ARCHITECTURE.md (4 spots — section opener annotated, telemetry stream marked DEPRECATED, mode struck, consumer struck — all use the proximity-or-strikethrough rule); TODOS.md (TODOS:37 marked DONE inline with closure summary, TODOS:47 updated four→five with new shim path, TODOS:81 closed OBSOLETE, TODOS:28-35 + TODOS:70-76 audited as OBSOLETE / DONE-then-OBSOLETE per investigate retirement). README.md regenerated via `./scripts/generate-readme.sh > README.md` (row 29 now in Deprecated section). New regression test `tests/cj-goal-investigate-shim.test.sh` (7 assertions: banner, D-id regex, recovery path, rejection text, delegation line, name preservation, allowed-tools) passes 7/7. Test rewires: `tests/cj-goal-doc-sync-auq-recommendation.test.sh` dropped investigate (was 3 preambles, now 2); `tests/cj-goal-investigate-did-allocator.test.sh` path moved to `deprecated/CJ_goal_investigate/pipeline.md`; `scripts/test.sh` F000025 block dropped `--caller investigate` grep + added shim-routing assertion against `deprecated/CJ_goal_investigate/SKILL.md`. Wired new test into scripts/test.sh after cj-goal-doc-sync-auq-recommendation block. check-version-queue.sh reports next free slot v5.0.15 (used in SKILL.md frontmatter + catalog version; /ship handles VERSION file bump). `./scripts/validate.sh` GREEN (0 errors / 0 warnings).

## PRs

<!-- PR links with status (open/merged/closed). -->

## Files

<!-- Affected file paths. Populated during Track phase, updated during Implement. -->

- `skills/CJ_goal_investigate/` → `deprecated/CJ_goal_investigate/` (git mv; pipeline.md + scripts/ archived)
- `deprecated/CJ_goal_investigate/SKILL.md` (overwritten with shim — banner + D-id rejection + non-D-id delegate)
- `skills-catalog.json` (status flip, files trim, description refresh, version sync)
- `CLAUDE.md` (lines 23, 71, 263 — Supporting-skills, worktree-prefix table, preamble-count prose)
- `doc/PHILOSOPHY.md` (lines 9, 76, 106, 119 + new tombstone in `## Retired skills`)
- `doc/ARCHITECTURE.md` (lines 7, 13, 19, 25 + retired-section relocation/annotation)
- `rules/skill-routing.md` (move/drop investigate routing row)
- `README.md` (regenerated via `./scripts/generate-readme.sh`)
- `TODOS.md` (rows 37 DONE, 47 update, 81 close, 28-35/70-76 audit)
- `tests/cj-goal-investigate-shim.test.sh` (new regression test)
- `scripts/test.sh` (wire new test)
- `VERSION` (next slot per check-version-queue.sh)
- `CHANGELOG.md` (entry)

## Insights

<!-- Non-obvious findings worth remembering. Things that surprised you,
     patterns discovered, or context that future readers will need. -->

- Gate met (P1): /CJ_goal_defect has 5 telemetry runs + 1 green ship (D000026 / v5.0.14 / PR #184); /CJ_goal_investigate stuck at 4 runs for 9 days. TODOS:37 retirement gate ("defect earns ≥1-2 real green ships first") is satisfied.
- D-id rejection contract is the load-bearing constraint (P2): bare `D-id` forwarding to `/CJ_goal_defect` would slug it as a description and mint a new D-id — corrupting work-item tracking. Shim MUST regex-match `^D[0-9]{6}$` and STOP before delegating.
- F000031 relocation pattern (Approach A) chosen over in-place S000060 pattern (Approach B): preserves the CLAUDE.md "Deprecated skills convention" (deprecated lives at `deprecated/`), no precedent ambiguity for future maintainers, archival pipeline.md + scripts/ available for downstream-consumer rescue (e.g. portfolio repo).
- v6.0.0 sunset wave grows from 4 → 5 shims (P3): `CJ_goal_run`, `CJ_goal_auto`, `cj_goal_feature`, `cj_goal_defect`, + `CJ_goal_investigate`. TODOS:47 body needs updating to reflect the new count and include `deprecated/CJ_goal_investigate/` in the removal list.
- Two NAMED audit surfaces under `doc/` (workbench convention): `doc/PHILOSOPHY.md` AND `doc/ARCHITECTURE.md`. Both must be audited for `/CJ_goal_investigate` drift. `/document-release` Step 2 reads the audit conventions section in CLAUDE.md and will flag any leak — better to catch in this PR.
- F000031 case-collision is OUT OF SCOPE (P4) — separate defect, separate scope. Filed as a follow-up TODOS row, not folded into this PR.
- PR-stop semantics required (workbench convention) — sensitive-surface change touching catalog + manifest + multiple SKILL.md files. /ship Gate #2 stays human.
- Sensitive-surface AUQ at /CJ_implement-from-spec is expected disposition (NOT a halt) — propose-and-confirm.

## Journal

<!-- Structured entries from the work-track journal command. Each entry has a type
     (decision, finding, blocker) and a Summary field. -->

- 2026-05-31 [decision] Summary: Chose Approach A (F000031 relocation + archive) over Approach B (S000060 in-place) and Approach C (relocation + aggressive strip). Rationale: matches current workbench Deprecated convention (no precedent ambiguity for future maintainers); preserves pipeline.md + scripts/ as archival reference (quick restore if downstream consumer surfaces a need); diff is structural moves (cheap to review) + standard catalog/doc edits.
- 2026-05-31 [decision] Summary: D-id rejection is non-negotiable (P2). Shim regex `^D[0-9]{6}$` (case-insensitive) intercepts bare D-id args before they reach `/CJ_goal_defect`. Rejection error message points users to two recovery paths: `skills-deploy install --include-deprecated && /CJ_goal_investigate <D-id>` for existing D-ids, or `/CJ_goal_defect "<bug description>"` for new bugs.
- 2026-05-31 [finding] Summary: TODOS:37 retirement gate met. /CJ_goal_defect telemetry: 5 runs, 1 green ship (D000026 / v5.0.14 / PR #184). /CJ_goal_investigate: 4 runs, last on 2026-05-21, no activity since. The 9-day quiescence + defect's proven green ship satisfies the "≥1-2 real green ships first" gate.

- 2026-06-01T04:12:48Z [qa-reverify] qa subagent returned red (tests/cj-worktree-init.test.sh:398 hardcoded stale path skills/CJ_goal_investigate/pipeline.md, missed by impl-subagent's path-relocation sweep). Orchestrator applied one-line fix (skills/ → deprecated/) at line 398. Re-ran ./scripts/test.sh → RESULT: PASS (Failures: 0). The new tests/cj-goal-investigate-shim.test.sh 7/7 OK. Validate.sh GREEN. did-allocator.test.sh:4 historical comment kept (describes original D000022 defect location; non-functional).
