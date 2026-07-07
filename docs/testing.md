# Testing

<!-- GENERATED FILE — do not edit by hand.
     Rendered from the merged test-spec registry (spec/test-spec.md +
     spec/test-spec-custom.md) by: scripts/test-spec.sh --render-docs
     Re-run that command to regenerate; validate.sh Check 26 enforces freshness. -->

The single front door to this repo's test suite: what testing here proves,
how to run it, how to audit it, and how to verify it. The narrative is fixed;
the behaviors / category-test / enrolled-topic indexes below are rendered
live from the merged test-spec registry (`spec/test-spec.md` +
`spec/test-spec-custom.md`), so they track every add and remove automatically.

## 1. What testing here proves

Every change passes through a **continuous verification gate** — a quality
check at each step of the pipeline, with the verifier kept independent of the
doer. Tests are classified on two orthogonal axes (a **category** —
`{workflow, regression, infra}` — and a **layer** — `{CI-push, CI-nightly,
pipeline-gate, local-hook}`), so a green suite is a specific, owned set of
guarantees rather than a vague reassurance.

For the underlying principle and the full category×layer model, see
[docs/philosophy.md](philosophy.md) §"Verification is a continuous gate" and
its "Topic: CI/CD" section. This page does not duplicate that prose — it is
the operational front door to the surface those principles describe.

## 2. The model at a glance

- **Category** (the *kind* of proof): `workflow` (a whole workflow runs end
  to end — features earn these), `regression` (a past defect stays fixed —
  defects earn these), `infra` (the standing verification surface — the
  validator, the full suite, the deploy harness).
- **Layer** (*where/when* it runs): `CI-push` (green per-PR to ship),
  `CI-nightly` (the slower cadence off the PR path), `pipeline-gate` (inline
  orchestrator halts), `local-hook` (pre-commit + local-only harnesses).
- **Mode**: `deterministic` or `agentic` (an agentic test spends model
  tokens, so `agentic ⇒ tier ≠ free` — it is declared in CI but only executed
  on-demand).
- **Topic contract**: a whole test *topic* (e.g. `portability`) can be held to
  all three deterministic layers at once — see the enrolled topics below.

The canonical map — the portable rules, the four-layer table, and the
machine-readable registry — is [spec/test-spec.md](../spec/test-spec.md).

## 3. How to run the tests

`/CJ_test_run` executes the repo's test contract and reports
evidence-derived pass/fail. Selectors:

- `/CJ_test_run` — run the whole tiered runner suite (default tier: `free`).
- `/CJ_test_run --category <workflow|regression|infra>` — run one category.
- `/CJ_test_run --layer <CI-push|CI-nightly|pipeline-gate|local-hook>` — run one layer.
- `/CJ_test_run --topic <topic>` — run one enrolled topic's tests.
- `/CJ_test_run <name>` — run a single named category test.

**Cost tiers** keep model spend explicit: a default run touches only `free`
tests; add `--evals` for the paid eval tier, `--e2e` for local-only tests, or
`--all` for everything. A default run never spends model tokens.

## 4. How to audit the tests

Where `/CJ_test_run` answers "do the tests PASS?", the audit verbs answer
"are the declared tests WIRED and truthful?" — each a three-stage audit
runnable standalone in any repo:

- `/CJ_test_audit` — Stage 1 (deterministic engine checks: validate,
  coverage cross-check, catalog freshness, workflow + topic contracts),
  Stage 2 (requirement compliance — agent-judged), Stage 3 (implementation
  drift — agent-judged).
- `/CJ_doc_audit` — the doc-contract companion (the same three-stage shape
  against `spec/doc-spec.md`).

The deterministic per-PR gate (`scripts/validate.sh` / the pre-commit hook /
CI) is what still stops a broken change on every PR; the agent-judged stages
run on-demand, off the build path.

## 5. How to verify (agentic, $0)

Some proofs need a real agent, not a runner. The behavioral eval cases under
`tests/eval/<skill>/<case>/` are driven **in-session**: ask Claude to walk the
case against the repo and judge the structured outcome — no CI runner, no
surprise model spend. This is the on-demand "verify" surface that complements
the deterministic "run" and "audit" surfaces above; an agentic test lives at
the `local-hook` layer precisely so its model spend stays out of CI.

## 6. Behaviors index

Every `behaviors:` statement in the registry — the open-world claims the
suite must prove, each with its verification `level` (and, for a
`workflow`-level behavior, the `CJ_goal_*` orchestrator it covers).

| Behavior | Level | Workflow |
|----------|-------|----------|
| seed-byte-identical | contract |  |
| absent-registry-is-distinct | contract |  |
| present-invalid-registry-halts | contract |  |
| overlay-merge-produces-one-registry | integration |  |
| coverage-inactive-without-units | contract |  |
| forward-anchor-drift-detected | unit |  |
| reverse-orphan-test-surface-detected | unit |  |
| reverse-floor-prevents-vacuous-pass | property |  |
| workflow-cj-goal-task-runs | workflow | CJ_goal_task |
| workflow-cj-goal-feature-runs | workflow | CJ_goal_feature |
| workflow-cj-goal-defect-runs | workflow | CJ_goal_defect |
| workflow-cj-goal-todo-fix-runs | workflow | CJ_goal_todo_fix |
| workflow-doc-audit-runs | integration |  |
| runners-axis-optional-registry-gated | contract |  |
| test-run-aggregate-evidence-derived | integration |  |
| test-run-registry-edges-honest | contract |  |
| build-gate-no-inline-slow-sync | integration |  |

## 7. Category-test index

Every named test in the `categories:` axis — its category, layer, mode, cost
tier, topic, and its front-door doc. Run any row by name with
`/CJ_test_run <name>`.

| Test | Category | Layer | Mode | Tier | Topic | Doc |
|------|----------|-------|------|------|-------|-----|
| validate | infra | CI-push | deterministic | free | validator | `docs/tests/infra/CI-push/validate.md` |
| suite | infra | CI-push | deterministic | free | full-suite | `docs/tests/infra/CI-push/suite.md` |
| test-deploy | infra | CI-nightly | deterministic | free | deploy-harness | `docs/tests/infra/CI-nightly/test-deploy.md` |
| test-run-self | infra | CI-push | deterministic | free |  | `docs/tests/infra/CI-push/test-run-self.md` |
| test-spec-self | infra | CI-push | deterministic | free |  | `docs/tests/infra/CI-push/test-spec-self.md` |
| cj-audit-self | infra | CI-push | deterministic | free |  | `docs/tests/infra/CI-push/cj-audit-self.md` |
| validate-hook | infra | local-hook | deterministic | free | validator | `docs/tests/infra/local-hook/validate-hook.md` |
| validate-nightly | infra | CI-nightly | deterministic | free | validator | `docs/tests/infra/CI-nightly/validate-nightly.md` |
| suite-nightly | infra | CI-nightly | deterministic | free | full-suite | `docs/tests/infra/CI-nightly/suite-nightly.md` |
| suite-local | infra | local-hook | deterministic | free | full-suite | `docs/tests/infra/local-hook/suite-local.md` |
| portability-check18-lint | infra | CI-push | deterministic | free | portability | `docs/tests/infra/CI-push/portability-check18-lint.md` |
| portability-smoke | infra | CI-push | deterministic | free | portability | `docs/tests/infra/CI-push/portability-smoke.md` |
| portability-deploy | infra | CI-nightly | deterministic | free | portability | `docs/tests/infra/CI-nightly/portability-deploy.md` |
| portability-version-check | infra | local-hook | deterministic | free | portability | `docs/tests/infra/local-hook/portability-version-check.md` |
| portability-version-agentic | infra | local-hook | agentic | local-only | portability | `docs/tests/infra/local-hook/portability-version-agentic.md` |
| doc-sync | workflow | local-hook | agentic | paid | doc-sync | `docs/tests/workflow/local-hook/doc-sync.md` |
| e2e-local | workflow | local-hook | agentic | local-only | e2e | `docs/tests/workflow/local-hook/e2e-local.md` |
| cj-goal-gate-shape | workflow | CI-push | deterministic | free | cj-goal-gate | `docs/tests/workflow/CI-push/cj-goal-gate-shape.md` |
| goal-feature-smoke | workflow | CI-push | deterministic | free | goal-feature | `docs/tests/workflow/CI-push/goal-feature-smoke.md` |
| goal-feature-chain | workflow | CI-nightly | deterministic | free | goal-feature | `docs/tests/workflow/CI-nightly/goal-feature-chain.md` |
| goal-feature-gate-seam | workflow | local-hook | deterministic | free | goal-feature | `docs/tests/workflow/local-hook/goal-feature-gate-seam.md` |
| goal-task-scaffold | workflow | CI-push | deterministic | free | goal-task | `docs/tests/workflow/CI-push/goal-task-scaffold.md` |
| goal-task-chain | workflow | CI-nightly | deterministic | free | goal-task | `docs/tests/workflow/CI-nightly/goal-task-chain.md` |
| goal-task-e2e-det | workflow | local-hook | deterministic | free | goal-task | `docs/tests/workflow/local-hook/goal-task-e2e-det.md` |
| goal-defect-smoke | workflow | CI-push | deterministic | free | goal-defect | `docs/tests/workflow/CI-push/goal-defect-smoke.md` |
| goal-defect-chain | workflow | CI-nightly | deterministic | free | goal-defect | `docs/tests/workflow/CI-nightly/goal-defect-chain.md` |
| goal-defect-land-sync | workflow | local-hook | deterministic | free | goal-defect | `docs/tests/workflow/local-hook/goal-defect-land-sync.md` |
| tag-release | regression | CI-push | deterministic | free |  | `docs/tests/regression/CI-push/tag-release.md` |
| cj-goal-jq-crlf | regression | CI-push | deterministic | free |  | `docs/tests/regression/CI-push/cj-goal-jq-crlf.md` |
| drain-one-todo-helper-unavailable | regression | CI-push | deterministic | free |  | `docs/tests/regression/CI-push/drain-one-todo-helper-unavailable.md` |
| drain-one-todo-worktree-resolve | regression | CI-push | deterministic | free |  | `docs/tests/regression/CI-push/drain-one-todo-worktree-resolve.md` |

## 8. Enrolled topics

Topics enrolled in the three-layer topic contract (`topic_contracts:`): each
is held to at least one `CI-push` + one `CI-nightly` + one
`local-hook`+`deterministic` test, and is documented end to end by a dream doc
(the end goal) plus a per-layer topic subdir (how it's tested).

- **portability** — [end goal](goals/portability.md) · [how it's tested](tests/topics/portability/)
- **validator** — [end goal](goals/validator.md) · [how it's tested](tests/topics/validator/)
- **full-suite** — [end goal](goals/full-suite.md) · [how it's tested](tests/topics/full-suite/)
- **goal-feature** — [end goal](goals/goal-feature.md) · [how it's tested](tests/topics/goal-feature/)
- **goal-task** — [end goal](goals/goal-task.md) · [how it's tested](tests/topics/goal-task/)
- **goal-defect** — [end goal](goals/goal-defect.md) · [how it's tested](tests/topics/goal-defect/)

## 9. Drill down

- [docs/test-catalog.md](test-catalog.md) — the verification surface grouped
  by family, with per-family unit counts and per-family pages.
- [docs/tests/index.md](tests/index.md) — the category-test list, grouped by
  category, each linking its per-test front-door doc.
