# Test list — by category × layer

<!-- SEEDED / REFRESHED by /CJ_test_audit from the spec/test-spec-custom.md
     categories: axis. The index references every declared category test by
     name; each name links to its docs/tests/<category>/<layer>/<name>.md page.
     The Topic column is a hand-maintained grouping annotation (NOT sourced from
     the categories: axis) — kept in sync by hand when tests are added/removed. -->

The **Topic** column groups tests that together fully cover one concern, so you
can see at a glance which set to run to exercise a topic end to end. For example,
the `portability` topic is fully covered by five tests spanning all three layers:
the Git-Bash smoke + the declared-vs-actual lint (`CI-push`), the Windows-native
deploy suite (`CI-nightly`), and — at `local-hook` — BOTH the deterministic
version-notification check AND the agentic version-notification proof (the
`claude --print` sandbox that asserts an agent actually surfaces the nudge) —
run all five to fully test portability.

For an enrolled topic, the end goal and the "how it is achieved" breakdown live in
a dedicated topic subdir. For `portability`: the
[topic overview](topics/portability/index.md) (property → test → layer map + the
coverage matrix, organized by layer) is anchored to its
[dream doc](../goals/portability.md) (the end goal + the three properties). The
topic subdir + dream doc are required for every enrolled topic by
`test-spec.sh --check-topic-docs` (`validate.sh` Check 31).

| Name | Category | Layer | Mode | Tier | Topic | Doc |
|------|----------|-------|------|------|-------|-----|
| `portability-deploy` | `infra` | `CI-nightly` | deterministic | free | portability | [docs/tests/infra/CI-nightly/portability-deploy.md](tests/infra/CI-nightly/portability-deploy.md) |
| `portability-check18-lint` | `infra` | `CI-push` | deterministic | free | portability | [docs/tests/infra/CI-push/portability-check18-lint.md](tests/infra/CI-push/portability-check18-lint.md) |
| `portability-smoke` | `infra` | `CI-push` | deterministic | free | portability | [docs/tests/infra/CI-push/portability-smoke.md](tests/infra/CI-push/portability-smoke.md) |
| `portability-version-check` | `infra` | `local-hook` | deterministic | free | portability | [docs/tests/infra/local-hook/portability-version-check.md](tests/infra/local-hook/portability-version-check.md) |
| `portability-version-agentic` | `infra` | `local-hook` | agentic | local-only | portability | [docs/tests/infra/local-hook/portability-version-agentic.md](tests/infra/local-hook/portability-version-agentic.md) |
| `validate` | `infra` | `CI-push` | deterministic | free | core-suite | [docs/tests/infra/CI-push/validate.md](tests/infra/CI-push/validate.md) |
| `suite` | `infra` | `CI-push` | deterministic | free | core-suite | [docs/tests/infra/CI-push/suite.md](tests/infra/CI-push/suite.md) |
| `test-deploy` | `infra` | `CI-nightly` | deterministic | free | core-suite | [docs/tests/infra/CI-nightly/test-deploy.md](tests/infra/CI-nightly/test-deploy.md) |
| `cj-goal-gate-shape` | `workflow` | `CI-push` | deterministic | free | cj-goal-workflows | [docs/tests/workflow/CI-push/cj-goal-gate-shape.md](tests/workflow/CI-push/cj-goal-gate-shape.md) |
| `doc-sync` | `workflow` | `local-hook` | agentic | paid | cj-goal-workflows | [docs/tests/workflow/local-hook/doc-sync.md](tests/workflow/local-hook/doc-sync.md) |
| `e2e-local` | `workflow` | `local-hook` | agentic | local-only | cj-goal-workflows | [docs/tests/workflow/local-hook/e2e-local.md](tests/workflow/local-hook/e2e-local.md) |
| `goal-feature-eval` | `workflow` | `local-hook` | agentic | paid | cj-goal-workflows | [docs/tests/workflow/local-hook/goal-feature-eval.md](tests/workflow/local-hook/goal-feature-eval.md) |
| `goal-task-eval` | `workflow` | `local-hook` | agentic | paid | cj-goal-workflows | [docs/tests/workflow/local-hook/goal-task-eval.md](tests/workflow/local-hook/goal-task-eval.md) |
