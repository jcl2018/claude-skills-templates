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
a dedicated topic subdir anchored to a dream doc, both required for every enrolled
topic by `test-spec.sh --check-topic-docs` (`validate.sh` Check 31). Three topics
are enrolled today:
[`portability`](topics/portability/index.md) ([dream](../goals/portability.md)),
[`validator`](topics/validator/index.md) ([dream](../goals/validator.md)), and
[`full-suite`](topics/full-suite/index.md) ([dream](../goals/full-suite.md)).
Each topic overview is the property → test → layer map + the coverage matrix,
organized by layer.

| Name | Category | Layer | Mode | Tier | Topic | Doc |
|------|----------|-------|------|------|-------|-----|
| `portability-deploy` | `infra` | `CI-nightly` | deterministic | free | portability | [docs/tests/infra/CI-nightly/portability-deploy.md](tests/infra/CI-nightly/portability-deploy.md) |
| `portability-check18-lint` | `infra` | `CI-push` | deterministic | free | portability | [docs/tests/infra/CI-push/portability-check18-lint.md](tests/infra/CI-push/portability-check18-lint.md) |
| `portability-smoke` | `infra` | `CI-push` | deterministic | free | portability | [docs/tests/infra/CI-push/portability-smoke.md](tests/infra/CI-push/portability-smoke.md) |
| `portability-version-check` | `infra` | `local-hook` | deterministic | free | portability | [docs/tests/infra/local-hook/portability-version-check.md](tests/infra/local-hook/portability-version-check.md) |
| `portability-version-agentic` | `infra` | `local-hook` | agentic | local-only | portability | [docs/tests/infra/local-hook/portability-version-agentic.md](tests/infra/local-hook/portability-version-agentic.md) |
| `validate` | `infra` | `CI-push` | deterministic | free | validator | [docs/tests/infra/CI-push/validate.md](tests/infra/CI-push/validate.md) |
| `validate-nightly` | `infra` | `CI-nightly` | deterministic | free | validator | [docs/tests/infra/CI-nightly/validate-nightly.md](tests/infra/CI-nightly/validate-nightly.md) |
| `validate-hook` | `infra` | `local-hook` | deterministic | free | validator | [docs/tests/infra/local-hook/validate-hook.md](tests/infra/local-hook/validate-hook.md) |
| `suite` | `infra` | `CI-push` | deterministic | free | full-suite | [docs/tests/infra/CI-push/suite.md](tests/infra/CI-push/suite.md) |
| `suite-nightly` | `infra` | `CI-nightly` | deterministic | free | full-suite | [docs/tests/infra/CI-nightly/suite-nightly.md](tests/infra/CI-nightly/suite-nightly.md) |
| `suite-local` | `infra` | `local-hook` | deterministic | free | full-suite | [docs/tests/infra/local-hook/suite-local.md](tests/infra/local-hook/suite-local.md) |
| `test-deploy` | `infra` | `CI-nightly` | deterministic | free | deploy-harness | [docs/tests/infra/CI-nightly/test-deploy.md](tests/infra/CI-nightly/test-deploy.md) |
| `cj-goal-gate-shape` | `workflow` | `CI-push` | deterministic | free | cj-goal-workflows | [docs/tests/workflow/CI-push/cj-goal-gate-shape.md](tests/workflow/CI-push/cj-goal-gate-shape.md) |
| `doc-sync` | `workflow` | `local-hook` | agentic | paid | cj-goal-workflows | [docs/tests/workflow/local-hook/doc-sync.md](tests/workflow/local-hook/doc-sync.md) |
| `e2e-local` | `workflow` | `local-hook` | agentic | local-only | cj-goal-workflows | [docs/tests/workflow/local-hook/e2e-local.md](tests/workflow/local-hook/e2e-local.md) |
