---
name: "refine spec/test-spec-custom.md: add a human-readable section grouping the verification surface by which layer handles each kind of test (e.g. what kinds of tests CI handles) per the four layers in test-spec.md"
type: task
id: "T000047"
status: active
created: "2026-06-13"
updated: "2026-06-13"
parent: ""
repo: "/Users/chjiang/Documents/projects/claude-skills-templates/.claude/worktrees/cool-lichterman-cbb4b0"
branch: "claude/cool-lichterman-cbb4b0"
blocked_by: ""
---

<!-- Prerequisite (optional): If this task came from /office-hours, distill the
     design context into the ## Insights section below. Otherwise (per the
     skip-design-for-small-todos convention in WORKFLOW.md), proceed without
     a separate DESIGN.md — the parent user-story's DESIGN already covers it. -->

## Lifecycle

### Phase 1: Track

1. Read parent tracker to understand scope and acceptance criteria
2. Create working branch: `git checkout -b feat/refine_spec_test_spec_custom_md_add_a`
   (use parent's branch if the task ships in the same PR; create a new branch if it warrants its own PR)
3. Scaffold required docs:
   - `test-plan.md` (test scenarios for this task) — from `templates/doc-test-plan.md`
4. Populate Files section with expected changed files
5. Write initial Todos from parent's acceptance criteria

**Gates:**
- [ ] Parent scope read (parent tracker reviewed)
- [ ] Working branch created (`branch` field populated)
- [ ] Required docs scaffolded (test-plan)
- [ ] Files section populated

### Phase 2: Implement

1. Work from `/office-hours` design doc + parent's acceptance criteria + your Todos
   → design doc at `~/.gstack/projects/refine_spec_test_spec_custom_md_add_a/`
2. Commit changes incrementally with descriptive messages
3. Update Todos section — check off completed items, add discoveries
4. Update Files section with actual changed files

**Gates:**
- [x] Core changes committed (>=1 commit SHA in Log)
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

- [x] Add a new prose section `## The verification surface, grouped by layer` to `spec/test-spec-custom.md`, inserted AFTER the intro paragraph (after the `pipeline-gate` paragraph ending "...run in the `pipeline-gate` layer.") and BEFORE `## How the registry is enforced`.
- [x] The section groups this repo's actual verification surface under the four layers from `spec/test-spec.md` (local-hook / ci / pipeline-gate / ratchet), with `ci` (the bulk) broken down by family and the named units enumerated — "the details for each kind of test."
- [x] HARD CONSTRAINT: do NOT add a second fenced ```yaml block — the parser (`test-spec.sh`) requires the registry to be the ONLY fenced yaml block. Use markdown prose + a markdown `|` table only. (Verified: 1 yaml fence remains.)
- [x] Keep the new section ABOVE the existing `## Machine registry (overlay)` yaml fence; the registry stays the source of truth (frame the section as a derived reader's index, drift caught by the registered-doc audit).
- [x] Verify `scripts/test-spec.sh --validate` and `scripts/test-spec.sh --check-coverage` stay green, and the full `scripts/validate.sh` passes (Check 24 especially).

## Log

<!-- Chronological entries with dates and commit SHAs. Each entry records
     what happened, not what should happen. -->

- 2026-06-13: Created. Auto-scaffolded by /CJ_goal_task from topic: refine spec/test-spec-custom.md: add a human-readable section grouping the verification surface by which layer handles each kind of test (e.g. what kinds of tests CI handles) per the four layers in test-spec.md
- 2026-06-13: Core changes committed — feat: T000047 — add layer-grouped verification-surface section to spec/test-spec-custom.md (touches spec/test-spec-custom.md). QA green (smoke 3/3; Step 8.6 doc+test audits 0 findings). Squashed to one `v6.0.69` commit at ship.
- 2026-06-13: Shipped — opened PR #267 (v6.0.69); STOPPED at the PR for human review (PR-stop; no auto-merge).

## PRs

<!-- PR links with status (open/merged/closed). -->

- [#267](https://github.com/jcl2018/claude-skills-templates/pull/267) — open (v6.0.69) — add layer-grouped verification-surface section to `spec/test-spec-custom.md`.

## Files

<!-- Affected file paths. Populated during Track phase, updated during Implement. -->

- `spec/test-spec-custom.md` — add the `## The verification surface, grouped by layer` prose section (the only file changed by this task).

## Insights

<!-- Auto-injected from the /CJ_goal_task topic -->

Scope (from /CJ_goal_task topic): refine spec/test-spec-custom.md: add a human-readable section grouping the verification surface by which layer handles each kind of test (e.g. what kinds of tests CI handles) per the four layers in test-spec.md

### Canonical content to insert (verified against the live `units:` + `gates:` registry, 2026-06-13)

Insert this section in `spec/test-spec-custom.md` after the intro (after the `pipeline-gate` paragraph) and before `## How the registry is enforced`:

> ## The verification surface, grouped by layer
>
> The general contract ([`test-spec.md`](test-spec.md)) names the four
> verification layers in the abstract; this section is the reader's-eye index of
> which **kinds** of tests this repo actually runs in each one. The fenced `yaml`
> registry below stays the source of truth — this grouping is derived from it
> (prose drift is caught by the advisory registered-doc requirements audit, the
> same posture as the per-row `purpose` one-liners). Each `units:` row carries a
> `layer` (`local-hook | ci`) and a `family`; the `gates:` array is the
> `pipeline-gate` layer; the `ratchet: true` flag marks the cross-cutting ratchet
> layer (a ratchet unit also runs in `ci`).
>
> ### Handled by `ci` (every PR, on a clean runner — hard-fail)
>
> The bulk of the surface. Four kinds:
>
> - **Validator checks** — `scripts/validate.sh` (also run at `pre-commit`, below):
>   - *Error checks* (hard-fail, comment-anchored) — 1–11 plus 9b (12 checks):
>     catalog↔disk integrity, SKILL.md frontmatter, template existence, doc
>     triplets, dependency resolution, VERSION/semver, the Copilot bundle files,
>     manifest reconciliation.
>   - *Numbered checks* (banner-anchored) — 11, 13, 14, 15, 16, 17, 18, 19, 21, 24
>     (10 checks): rules deploy, USAGE presence + freshness, the doc-registry
>     contract, permission-policy drift, and the test-spec coverage cross-check
>     (24). ("Error check 11" and "Check 11" are two distinct live checks sharing
>     a numeral.)
>   - *Warning checks* (advisory) — orphan doc directories, orphan templates.
>   - *The portability-audit engine* (`cj-portability-audit.sh`) behind Check 18.
> - **Behavioral test suites** — `scripts/test.sh`:
>   - *Registered `tests/*.test.sh` sub-suites* (17) — the worktree init/cleanup
>     helpers, the task scaffolder, the doc-spec/test-spec parsers, the audit
>     skills, the goal-common phases, the id-claim race, doc-sync wiring, and more.
>   - *Inline `test.sh` families* (16) — the full validator re-run, the
>     harness-principle regression guards, the catalog/frontmatter smoke, the
>     handoff-gate suite, the install==clone battery, and the rest.
> - **Standalone suites** (also manually runnable; some also run on push-main or
>   nightly) — `skills-deploy` install/doctor/remove (`test-deploy`), the
>   behavioral `eval` harness (nightly), and the Windows Git-Bash `windows-smoke`.
> - **GitHub Actions workflows** — `validate.yml` (the PR gate: validator + suite +
>   shellcheck), `windows.yml` (Git Bash, on PR + push-main), `eval-nightly.yml`
>   (scheduled + manual dispatch).
>
> ### Handled by `local-hook` (at `git commit`, before code leaves the machine)
>
> - **pre-commit** (hard-fail) — runs the whole validator at commit time, so a
>   structurally-invalid commit never lands. (This is why the validator rows carry
>   the `pre-commit pr-ci` trigger — the same checks, two firing points.)
> - **post-merge** (advisory, best-effort) — re-deploys skills/templates/rules into
>   the local home after a pull touches them; never blocks git.
>
> ### Handled by `pipeline-gate` (during an orchestrated `CJ_goal_*` run)
>
> The `gates:` array — the inline halts a goal orchestrator runs before its PR, in
> `order`. Each mode runs its subset:
>
> | order | gate | runs in | halts on |
> |------:|------|---------|----------|
> | 10 | isolation | feature, defect, task | un-isolated / dirty checkout |
> | 20 | design-gate | feature | design not approved |
> | 25 | root-cause | defect | no populated root cause |
> | 30 | complexity | task | topic too big for a task |
> | 40 | qa | all four | failing test rows |
> | 45 | qa-audit | all four | operator declines the audit findings |
> | 50 | doc-sync | all four | doc drift can't fold into the PR |
> | 60 | portability | all four | a skill lies about its portability tier |
> | 70 | ship | all four | the human ship gate (PR-stop) |
>
> ### Ratchets (cross-cutting — monotonic guards that never regress)
>
> The `ratchet: true` units (each also runs in `ci`):
>
> - **VERSION never regresses** — Error check 8.
> - **USAGE.md freshness** — Check 14 (USAGE no older than its sibling SKILL.md).
> - **The portability baseline** — Check 18 + the portability-audit engine (the
>   clean zero-findings baseline is the ratchet).


<!-- Non-obvious findings worth remembering. Things that surprised you,
     patterns discovered, or context that future readers will need. -->

## Journal

<!-- Structured entries from the work-track journal command. Each entry has a type
     (decision, finding, blocker) and a Summary field. -->

<!-- Source: /CJ_goal_task: refine spec/test-spec-custom.md: add a human-readable section grouping the verification surface by which layer handles each kind of test (e.g. what kinds of tests CI handles) per the four layers in test-spec.md -->

- 2026-06-13 [impl-finding] Phase 1 gates were left unchecked by the lightweight /CJ_goal_task scaffold (no /office-hours; tracker populated directly). The task prompt designates the TRACKER as the authoritative spec, so implementation proceeded per the canonical content block; the unchecked Phase 1 gates are a scaffold artifact, not a blocker.
- 2026-06-13 [impl-decision] Inserted the section verbatim from the tracker's "Canonical content to insert" block, stripping the leading `> ` blockquote markers so it lands as plain markdown (prose + one `|` table), anchored between the intro paragraph and the `## How the registry is enforced` heading. No second yaml fence added — the single overlay registry fence stays the only one.
- 2026-06-13 [impl] Modified 1 file (spec/test-spec-custom.md) — added the `## The verification surface, grouped by layer` prose section above the registry fence. No code or registry rows changed.
- 2026-06-13 [impl-auto] Auto-mode run; --auto allowed (1 file touched, non-sensitive surface, no tradeoffs/open questions).
- 2026-06-13 [impl] Verified green: `test-spec.sh --validate` (OK schema_version=1), `test-spec.sh --check-coverage` (rows=66 reverse_tokens=46 findings=0), and full `scripts/validate.sh` (RESULT: PASS, 0 errors / 0 warnings; Check 24 clean). yaml fence count confirmed = 1.
- 2026-06-13 [impl-pass] T000047: implementation complete. Phase 2 implementer-owned gates transitioned.
- 2026-06-13 [qa-smoke] S1 (test-spec-validate): green — `bash scripts/test-spec.sh --validate` exit 0, `OK schema_version=1`.
- 2026-06-13 [qa-smoke] S2 (test-spec-coverage): green — `bash scripts/test-spec.sh --check-coverage` exit 0, `OK coverage rows=66 reverse_tokens=46 findings=0`.
- 2026-06-13 [qa-smoke] S3 (validate-suite): green — `bash scripts/validate.sh` exit 0, `RESULT: PASS` (0 errors / 0 warnings; Check 24 coverage + gate-marker-drift clean).
- 2026-06-13 [qa-smoke-summary] green: 3/3 non-manual rows green (0 manual rows pending). Test-plan's single prose row exercised smoke-equivalent via the task's three contract commands.
- 2026-06-13 [qa-audit] AUDITS=doc:ok,test:ok,spec_updates:test-spec-custom:none,doc-spec-custom:none (Step 8.6a-d; findings ride the green RESULT — checkpoint decision belongs to the orchestrator)
- 2026-06-13 [qa-pass] T000047 (task): green smoke from test-plan rows (3 rows). No qa-owned Phase 2 gates per template; Phase 3 `Test-plan verified` gate awaits /ship-time inference.
