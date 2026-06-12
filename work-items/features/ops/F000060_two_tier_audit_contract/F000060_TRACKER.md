---
name: "Two-tier audit contract — /CJ_doc_audit + /CJ_test_audit, skill-delivered spec seeds + custom overlays, QA-wired audit checkpoint"
type: feature
id: "F000060"
status: active
created: "2026-06-12"
updated: "2026-06-12"
repo: "/Users/chjiang/Documents/projects/claude-skills-templates/.claude/worktrees/unruffled-kalam-e25974"
branch: "claude/unruffled-kalam-e25974"
blocked_by: ""
---

<!-- Prerequisite: Before scaffolding this work item, run /office-hours to
     produce a design plan in ~/.gstack/projects/. Distill that plan into
     DESIGN.md during Phase 1 below. -->

## Lifecycle

### Phase 1: Track

1. Create working branch: `git checkout -b feat/two_tier_audit_contract`
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
- [x] All child stories have entered Phase 2+
- [x] Feature-level Todos reflect remaining coordination work

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

- [ ] **Standalone, any repo:** in a bare temp git repo, `/CJ_doc_audit` creates `spec/doc-spec.md` from the seed and reports `seeded: yes` + a verdict; `/CJ_test_audit` does the same for `spec/test-spec.md`; second runs are idempotent (`seeded: no`). In this workbench both run green (FINDINGS=0).
- [ ] **Two-tier files:** `spec/doc-spec.md` == `doc-spec.sh --seed` output byte-for-byte; this repo's custom entries live in `spec/doc-spec-custom.md` (3 migrated rows + 2 new self-declared rows); merged lists drive Checks 15/17/19/20 + document-release unchanged at their call sites; generated views regenerate cleanly (Check 23 green).
- [ ] **Demolition complete:** `spec/test-pipeline.md`, `scripts/test-pipeline.sh`, `tests/test-pipeline-spec.test.sh`, and `docs/test-pipeline.md` are gone; no grep hit for `test-pipeline` remains outside CHANGELOG, work-items history, and TODOS.md (struck rows + new deferred rows); Check 24 now runs `test-spec.sh --check-coverage` and is green on the migrated registry.
- [ ] **Coverage parity:** deleting a unit row for an existing test, or adding an unregistered `tests/*.test.sh`, flips Check 24 red (ported forward + reverse checks demonstrably alive).
- [ ] **QA wiring:** `/CJ_qa-work-item` on this feature's own story executes Steps 8.6a–d and returns the extended RESULT + AUDIT_FINDINGS block; all four pipelines carry the checkpoint AUQ + the literal `[qa-audit-declined]` marker; gate-spec `qa-audit` row present (order 45); Check 22 green.
- [ ] **This run itself** pauses at the new checkpoint (the feature's own QA prompts the operator with its own audit findings) — the feature ships through its own gate.
- [ ] `./scripts/validate.sh` + `./scripts/test.sh` green; README regenerated; catalog entries valid; portability audit green (FINDINGS=0).

## Todos

<!-- Actionable items for this feature. Break into child tasks for
     large features. -->

- [x] S000102: full build — doc-spec general/custom file split (general == `--seed` byte-identical, `front_table` promoted into the portable seed schema, overlay carries 3 migrated + 2 self-declared rows), `doc-spec.sh` overlay merge, NEW `spec/test-spec.md` seed (5 portable rules) + `spec/test-spec-custom.md` overlay (66-row migration in the old row shape, verbatim, + portability unit + new-test rows), NEW `scripts/test-spec.sh` (full parser parity: --validate/--list-rules/--list-units/--check-coverage/--seed, `REGISTRY=absent` exit-0 path, units-gated reverse floor), `/CJ_doc_audit` + `/CJ_test_audit` skills (SKILL.md + USAGE.md + catalog entries + routing lines), QA Steps 8.6a–d + extended RESULT + AUDIT_FINDINGS block, checkpoint AUQ in all four pipelines + gate-spec `qa-audit` row, validate.sh Check 23/24 surgery, the F000059 demolition + enumerated reference sweep, document-release seeding-path updates, zero-AUQ wording sweep, three new test suites + test.sh integration blocks + self-registration as `units:` rows
- [ ] Coordinate: single-commit atomicity — seed copies (general file + `doc-spec.sh` heredoc + `templates/doc-spec-common.md`) + registry files + regenerated views land together (Checks 15a/16/23 fail half-states at the pre-commit hook)
- [ ] Coordinate: no tree mutations while `scripts/test.sh` runs (its EXIT restore-trap clobbers concurrent edits)
- [ ] Coordinate: new `scripts/test-spec.sh` + modified `doc-spec.sh` pass the stricter apt shellcheck in CI (SC2015/SC2016 class), not just local 0.11
- [ ] Coordinate: the zero-AUQ wording sweep MUST land in the same PR (Step 8.6d self-application would otherwise flag the four orchestrators stale on this feature's own run)
- [ ] Post-land assignment: run `/CJ_doc_audit` + `/CJ_test_audit` in the portfolio consumer repo — both seeds delivered (`seeded: yes`), non-crashing verdicts, second run `seeded: no`

## Log

<!-- Chronological entries with dates and commit SHAs. -->

- 2026-06-12: Created. Two-tier audit contract: two operator-facing audit skills (/CJ_doc_audit, /CJ_test_audit) runnable in any repo, doc/test contracts split into skill-delivered general seeds (`spec/doc-spec.md`, `spec/test-spec.md`) + optional repo-custom overlays (`spec/doc-spec-custom.md`, `spec/test-spec-custom.md`), a new full-parity `scripts/test-spec.sh` parser/coverage engine, four new QA steps (8.6a–d) + an always-prompt findings checkpoint in all four cj_goal pipelines — retiring the F000059 test-pipeline registry machinery wholesale. Supersedes the earlier same-day orchestrator-gate design (operator redo).
- 2026-06-12: S000102 implementation complete ([impl-pass] in the child tracker). All deliverables built + verified: validate.sh fully green (Check 24 = test-spec coverage, rows=69 reverse_tokens=49 findings=0; Check 22 green with the qa-audit row; Check 18 FINDINGS=0), three new test suites PASS, seed copies 3-way byte-identical, demolition sweep clean (zero `test-pipeline` hits outside CHANGELOG/work-items/TODOS). Awaiting QA phase (the run's own Step 8.6 + checkpoint — success criterion 6).

## PRs

<!-- PR links with status (open/merged/closed). -->

## Files

<!-- Affected file paths. Populated during Track phase, updated during Implement. -->

- spec/doc-spec.md (rewritten — general contract only; byte-identical to `doc-spec.sh --seed`; `front_table` promoted into the seed schema)
- spec/doc-spec-custom.md (new — this repo's overlay: 3 migrated entries + 2 self-declared rows)
- spec/test-spec.md (new — general test contract seed: 5 portable rules)
- spec/test-spec-custom.md (new — this repo's unit enumeration in the old row shape + portability unit)
- scripts/doc-spec.sh (modified — overlay merge for all list subcommands + --validate; duplicate-path error; heredoc seed lockstep)
- scripts/test-spec.sh (new — full parser parity: --validate / --list-rules / --list-units / --check-coverage / --seed)
- spec/test-pipeline.md, scripts/test-pipeline.sh, tests/test-pipeline-spec.test.sh, docs/test-pipeline.md (DELETED — F000059 demolition)
- scripts/validate.sh (modified — Check 24 body swap, Check 23 test-pipeline branch removed, test-spec.sh --validate added)
- scripts/generate-doc-views.sh (modified — test-pipeline render branch removed)
- scripts/generate-readme.sh (modified — folder-structure heredoc test-pipeline refs removed)
- scripts/test.sh (modified — three F000059 blocks removed/swapped; new suites' integration blocks)
- skills/CJ_doc_audit/SKILL.md + USAGE.md (new), skills/CJ_test_audit/SKILL.md + USAGE.md (new)
- skills/CJ_qa-work-item/qa.md (modified — Step 8.6 audit block + extended RESULT)
- skills/CJ_goal_feature/pipeline.md, skills/cj_goal_defect/pipeline.md, skills/CJ_goal_task/pipeline.md, skills/CJ_goal_todo_fix/SKILL.md (modified — checkpoint AUQ + halt taxonomy)
- skills/CJ_document-release/SKILL.md + USAGE.md (modified — spec/-style seeding, test-spec stub special-case, front_table stub shape, third-view render logic removed)
- spec/gate-spec.md (modified — qa-audit gates[] row, order 45, + division-of-labor row)
- rules/skill-routing.md (modified — two routing lines)
- skills-catalog.json (modified — 2 new entries + 4 orchestrator description updates), README.md (regenerated)
- docs/workflow.md, docs/philosophy.md, docs/architecture.md (modified — utilities entries, decision tree, test-pipeline section rewrite)
- templates/doc-spec-common.md (modified — seed lockstep)
- CLAUDE.md, TODOS.md (modified — scripts table + sections sweep; row 12 struck; deferred rows added)
- tests/doc-spec-overlay.test.sh, tests/test-spec.test.sh, tests/cj-audit-skills.test.sh (new)

## Insights

<!-- Non-obvious findings worth remembering. Design decisions,
     trade-offs, patterns discovered. -->

- One format, fully enforced — never two formats, half enforced: given the option to preserve the 2-day-old test-pipeline registry as a compatibility layer, demolition was chosen over coexistence (D5.2), and the deterministic Check-24 coverage engine is PORTED, not dropped (D6) — the demolition does not net-reduce determinism.
- The contract is refreshed first, then verified: the four QA steps deliberately order "update the custom specs" (8.6a/8.6b) BEFORE "run the audits" (8.6c/8.6d) — the feedback-loop shape that keeps living registries from rotting.
- Audit findings ride a GREEN QA RESULT (`AUDITS=` field) instead of flipping it red — that is what makes the checkpoint reachable at all: a red RESULT would halt at the existing qa gate and the operator would never see the findings prompt. The checkpoint owns the findings decision; waivers are auditable (`[qa-audit-waived]` journal line).
- Seed byte-identity has no legal home for workbench-only fields on common docs, so `front_table` is PROMOTED into the portable seed schema as an optional field (enforced only when present) — the old "workbench-local extension … NOT in the portable Common seed" wording is retired as no longer true.
- The old unit row shape is kept verbatim in `spec/test-spec-custom.md` so the 66-row migration is a literal row copy (no field mapping, no synthesized values) and the coverage engine ports with its extraction grammar and reverse-sweep id conventions intact.
- In subagent context (inside QA, inside cj_goal) the audit skills' logic executes INLINE by the QA agent reading the skill files — a subagent cannot spawn subagents (the nested-subagent wall); standalone invocations may use the Skill tool directly. Both skills document this dual posture.

## Journal

<!-- Structured entries from the work-track journal command. Each entry has a type
     (decision, finding, blocker) and a Summary field. -->

- 2026-06-12 [decision] D5.1 — canonical home for all four spec files is `spec/` only; `doc-spec.sh`'s spec/-then-root read fallback stays for back-compat, but delivery + documentation standardize on `spec/`.
- 2026-06-12 [decision] D5.2 — the old test-pipeline machinery is REMOVED, not wrapped ("remove the old ones use the new format"); full reference sweep in the same PR.
- 2026-06-12 [decision] D5.3 — this repo's custom doc entries migrate OUT of `spec/doc-spec.md` into `spec/doc-spec-custom.md`; `doc-spec.sh` merges general + overlay internally so existing consumers are untouched at their call sites (amended: document-release IS touched by the demolition + spec/-path standardization).
- 2026-06-12 [decision] D5.4 — the post-audit checkpoint ALWAYS prompts in interactive cj_goal runs; `/CJ_goal_todo_fix --quiet` auto-continues on green and halts on red.
- 2026-06-12 [decision] D6 — full parser parity (Approach A): `scripts/test-spec.sh` carries a deterministic Check-24-equivalent coverage cross-check re-targeted at the merged two-tier registry; agent-judged alignment layers on top in the skills.
- 2026-06-12 [decision] Supersession — this design replaces the earlier same-day orchestrator-gate design (chjiang-claude-unruffled-kalam-e25974-design-20260612-124229.md); the earlier scaffold was deleted and this scaffold is fresh (IDs F000060/S000102 reclaimed via cj-id-claim.sh same-branch reuse).
- 2026-06-12T23:28:06Z [feature-pr-opened] F000060 v6.0.65 PR #261
  pr_url=https://github.com/jcl2018/claude-skills-templates/pull/261
