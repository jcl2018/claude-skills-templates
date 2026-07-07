---
type: design
parent: F000087
title: "Retire the paid run-eval harness — keep the eval cases as in-session verify specs + the Check 28 gate (Testing roadmap Phase 0) — Feature Design"
version: 1
status: Draft
date: 2026-07-06
author: chang
reviewers: []
---

<!-- A feature's cross-story design doc. Captures the PROBLEM, the SHAPE of
     the solution, the BIG DECISIONS with rationale, the RISKS, the
     DEFINITION OF DONE, and out-of-scope boundaries. Story-scope detail
     (SPEC/TEST-SPEC) lives on the nested user-stories. Distilled from
     the /office-hours design doc
     ~/.gstack/projects/jcl2018-claude-skills-templates/chang-claude-vigorous-mcclintock-e72fcb-design-20260706-165302.md
     (Status: APPROVED, Mode: Builder). -->

## Problem

Phase 0 of the "Testing roadmap → dream test suite" saga (top of TODOS.md). The
`run-eval` runner (`scripts/eval.sh`, `tier: paid`, spawns a headless
`claude --print` per eval case) is metered model spend the operator wants gone.
The replacement is in-session Claude verification — "ask Claude to drive the
cases under `tests/eval/<skill>/` and report pass/fail vs their expected
outcomes" — which is $0 marginal on the subscription and richer than headless
`--print`.

The catch: the `tests/eval/<skill>/<case>/` dirs are ALSO the anchors
`validate.sh` Check 28 (`--check-workflow-coverage`) greps, so they must be KEPT
as durable, honest verification specs; deleting them would un-guard `CJ_goal_*`
drift on every push. So the feature is a subtraction with a preservation
constraint: delete the paid harness, keep (and clean up) the specs, keep the free
structural gate.

## Shape of the solution

One user-story carries the whole implementation (script deletion + overlay edits
+ doc-spec edits + prompt de-leak + catalog regen — one coherent PR). The
implementation order: delete `scripts/eval.sh` + sweep callers → edit
`spec/test-spec-custom.md` (remove the `run-eval` `runners:` row, re-anchor
`suite-eval` onto the `tests/eval/` specs, reframe `run-test-sh`'s `covers:`
note, remove the two `goal-*-eval` `categories:` rows, drop `cj-goal-eval` from
the unenrolled-topics prose) → edit `spec/doc-spec-custom.md` + delete the two
front-door docs + reconcile `docs/tests/index.md` → de-leak the eval prompts
(preserve the anchors) → regenerate the catalogs.

| Concern | User-story | Artifact |
|---------|-----------|----------|
| Delete the paid harness, re-anchor `suite-eval`, remove the two `goal-*-eval` categories rows + front-door docs, de-leak the eval prompts, regenerate catalogs | S000136 | [S000136_retire_eval_runner_keep_specs/S000136_TRACKER.md](S000136_retire_eval_runner_keep_specs/S000136_TRACKER.md) |

## Big decisions

| # | Decision | Why |
|---|----------|-----|
| 1 | Approach C — REMOVE the `goal-task-eval` + `goal-feature-eval` `categories:` rows + their front-door docs; keep ONLY the `behaviors:`/`behavior_coverage:` axis + the `tests/eval/` dirs + Check 28 | Operator-selected at the 2026-07-06 AUQ. Least surface; nothing to break; no doc-string-as-command awkwardness. Rejected A (inline self-skip `echo` command, re-tier paid→local-only — the "command" would be a doc-string, not an executable) and B (a tiny shared `tests/eval/verify.sh` helper — adds new machinery, in tension with "retiring the harness is the feature"). Accepts the tradeoff that C regresses the roadmap's "feature+task are first-class `categories: workflow` rows" state; the `level: workflow` behaviors + Check 28 are the real workflow gate, and the eval `categories: workflow` rows were thin wrappers around the paid harness. |
| 2 | `suite-eval` MUST re-anchor off `source: scripts/eval.sh` onto the durable `tests/eval/` specs | Its `source: scripts/eval.sh` anchor would go dangling under Check 24's forward anchor-grep once the script is deleted → red. Re-anchor to a stable `source` + `anchor` that exists live (a representative `tests/eval/<skill>/<case>/prompt.md` + a literal in it, or the `tests/eval/` dir with a greppable anchor), and reframe its `label`/`purpose` as "the durable eval-case verification specs Claude drives in-session," not "the runner." |
| 3 | The eval family stays DECLARED, so it is NOT orphaned | `run-test-sh` keeps `eval` in its `covers:` list (test.sh never invoked eval.sh anyway); the `suite-eval` unit keeps `family: eval` alive; the note is reframed to "specs-only, verified in-session." `/CJ_test_audit` must report NO orphaned eval family. |
| 4 | Do NOT add a new `/CJ_verify` skill | Verification is an in-session ask; the durable value lives in the specs, not a wrapper. Adding a skill contradicts the "retiring machinery is the feature" thesis. |
| 5 | Removing the two `categories:` rows does NOT break Check 28 | Check 28 is driven by the `behaviors:`/`behavior_coverage:` axis (each `level: workflow` behavior → its `workflow:` orchestrator + its `tests/eval/<skill>/<case>/prompt.md` anchor), which is INDEPENDENT of the `categories:` rows. Those `tests/eval/` dirs are kept. |
| 6 | The portability un-enroll prerequisite is MOOT for this build | F000086 demoted the enrolled-topic `local-hook`+agentic point to ADVISORY (a missing agentic row prints a per-topic `note:`, never a Check-30 finding); portability keeps its deterministic + CI-push + CI-nightly rows. Phase 0 removes the eval-family harness, NOT portability's agentic test (`portability-version-agentic`, a different topic). Verify empirically: `test-spec.sh --check-topic-contract` after removal → exit 0 + only the expected advisory notes. |
| 7 | Mirror `spec/test-spec.md` seed ONLY if a general-file line changed (the dual-write footgun) | The general file's topic-axis prose must stay byte-identical to `test-spec.sh --seed`. Expected: no general-file change — all edits are overlay. |

## Risks & open questions

| Risk / Question | Next check |
|-----------------|-----------|
| Phase 2 ripple: the roadmap's "promote `defect` + `todo_fix` to first-class `categories: workflow` rows" now conflicts with removing `feature`+`task`'s rows | Flag in TODOS; Phase 2 should be revisited to decide whether ANY `cj-goal` `categories: workflow` rows are wanted, or whether the `behaviors:`/Check 28 axis is the sole workflow gate. Do NOT expand this build. |
| `--check-structure` (b): removing the two rows could leave a required `tests/workflow/local-hook/` subfolder empty | Verify via `test-spec.sh --check-structure` in QA — doc-sync + e2e-local remain in that category/layer pair (none are `tests/*.test.sh` file-backed), so the pair should stay satisfied. |
| A dangling `eval.sh` reference left behind after the delete | Grep for `eval.sh` across `scripts/`, `tests/`, `.github/workflows/`, the `spec/test-spec.md` seed, and the `test-run.sh`/`test.sh` engines before considering the delete complete (the `eval-nightly.yml` CI workflow was already removed by F000080). |
| The eval prompts leak expected output (`tests/eval/CJ_goal_feature/dry-run-plan/prompt.md:12` leaks "emits `dry_run_preview`") | De-leak each `prompt.md` to state scenario + fixture but NOT expected output; PRESERVE the `behavior_coverage` anchor strings Check 28/Check-5 grep live `-F` (they describe the scenario/chain, not the expected output — verify each anchor still matches post-edit). |
| CLAUDE.md / CHANGELOG.md prose mention `cj-goal-eval` / the eval rows | CLAUDE.md prose freshness is advisory (deferred to the on-demand audit; inline Step 5.5 is deterministic-only). CHANGELOG history is not edited. |

## Definition of done

- [ ] `scripts/eval.sh` + the `run-eval` `runners:` row are GONE; no dangling reference to `eval.sh` remains in scripts/tests/workflows/spec engines
- [ ] `./scripts/validate.sh` is GREEN, specifically Check 24 (coverage cross-check — `suite-eval` re-anchored, no dangling), Check 28 (workflow coverage — 4/4 still wired), Check 30 (`--check-topic-contract` — exit 0, only advisory notes), Checks 26/27 (catalogs fresh)
- [ ] `/CJ_test_audit` reports NO orphaned eval family
- [ ] The `tests/eval/<skill>/<case>/` specs remain honest, non-leaking in-session verification specs (no expected-output in any `prompt.md`)
- [ ] The full `./scripts/test.sh` suite passes

## Not in scope

- Adding a new `/CJ_verify` skill or any wrapper — verification is an in-session ask; the durable value lives in the specs
- Phase 2 of the roadmap (promoting `defect` + `todo_fix` to first-class `categories: workflow` rows) — deferred; flagged in TODOS as a follow-up
- Editing CHANGELOG.md history — not edited; CLAUDE.md prose freshness is advisory (on-demand audit)
- Any change to the `behaviors:`/`behavior_coverage:` axis, the `suite-eval` family membership, the `tests/eval/<skill>/<case>/{prompt.md,expected.schema.json,fixture}` dirs (beyond de-leaking prompts), or `validate.sh` Check 28 — all KEPT
- Portability's agentic test (`portability-version-agentic`) or any portability un-enroll — out of scope; the un-enroll prerequisite is moot (F000086)

## Pointers

- Parent tracker: [F000087_TRACKER.md](F000087_TRACKER.md)
- Roadmap: [F000087_ROADMAP.md](F000087_ROADMAP.md)
- Child story: [S000136_retire_eval_runner_keep_specs/S000136_TRACKER.md](S000136_retire_eval_runner_keep_specs/S000136_TRACKER.md)
- Source design doc: `~/.gstack/projects/jcl2018-claude-skills-templates/chang-claude-vigorous-mcclintock-e72fcb-design-20260706-165302.md` (APPROVED)
- Related features: `work-items/features/ops/F000086_topic_contract_agentic_advisory/` (the ADVISORY demotion that makes the portability prerequisite moot), `work-items/features/ops/F000080_ci_nightly_deterministic/` (removed the `eval-nightly.yml` CI job + re-homed the eval harness on-demand), `work-items/features/ops/F000070_workflow_coverage_axis/` (Check 28 + the `level: workflow` behaviors this feature relies on as the sole workflow gate)
