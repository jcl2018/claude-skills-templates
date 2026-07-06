# Goal: goal-task — a small ad-hoc task becomes a reviewable PR

> **Dream docs** state *what the system should achieve* — the aspiration a family
> of tests exists to realize. They are the WHAT. The matching
> [`docs/tests/topics/<topic>/`](../tests/topics/goal-task/index.md) pages are
> the HOW: which tests, at which layer, prove each property. Read this first, then
> follow the links to see how it is achieved.

## The end goal

**When the operator types `/CJ_goal_task "<small task>"`, the workbench carries
that free-text line to a reviewable PR with no design ceremony** — a hard
complexity gate that refuses what isn't a small task (routing it to the right
verb instead), an isolated worktree, a bash-scaffolded `type: task` work-item,
an implementation, a QA pass, and a PR that stops for human review. The task
verb is the lightweight sibling of the feature verb; its promise is exactly
that lightness — and the gate that keeps oversized work out of it.

This is not one test — it is a **topic**. The goal decomposes into three
properties.

## The three properties

| Property | What it means (the aspiration) | Why it can fail |
|----------|-------------------------------|-----------------|
| **Gate + scaffold correctness** | The complexity gate HARD-refuses design/bug/large topics (routing each to the right verb), and an allowed topic mints a fresh T-ID work-item with the exact `type: task` shape, idempotently. | A keyword drift lets a design-rework topic through (or refuses a legitimate small task); a template change breaks the scaffolded shape the downstream chain expects. |
| **Chain composition** | The steps COMPOSE: one checkout flows through worktree entry → scaffold-inside-the-worktree → recap → cleanup, end to end, each seam honoring its contract in sequence. | The scaffolder can pass its own suite while the composed flow breaks — a scaffold that lands outside the worktree, a janitor that would sweep the live checkout. |
| **E2E-harness readiness** | The machinery that can run the WHOLE task verb for real (the local happy-path harness: sandbox, safety seams, evidence-derived reporting, auth gating) stays correct, without spending a model. | A harness regression makes the real E2E run unlaunchable — or worse, unsafe (a sandbox that pushes to a real remote, a report that renders a false pass). |

## The deliberate deterministic-only posture

This topic is enrolled in the topic contract's **deterministic-only** flavor
(`topic_contracts_deterministic:`): its three required coverage points are all
`mode: deterministic`, and the verb's agentic eval (the `goal-task-eval` row, a
real `claude --print` run driving the orchestrator to its complexity halt) is
*tolerated, never required* — runnable on demand while it exists, but deleting
it cannot red the contract. The conscious trade: **the agent-executed
`pipeline.md` prose has no required proof** — deterministic drills reach the
helper SCRIPTS only (the helpers-only ceiling), so a prose-level regression
ships silently until an operator run or an on-demand eval/E2E-harness run
catches it. Accepted because the agentic assets are scheduled for removal, and
enrollment must not depend on assets planned for deletion.

## How this goal is achieved (the tests)

The full "how" — which test proves each property, at which verification layer,
and how to run it — lives in the topic pages:

- **[Overview + coverage map](../tests/topics/goal-task/index.md)** — the property → test → layer map.
- **[CI-push layer](../tests/topics/goal-task/CI-push.md)** — the fast per-PR gate + scaffold suite.
- **[CI-nightly layer](../tests/topics/goal-task/CI-nightly.md)** — the composed helper-chain drill.
- **[local-hook layer](../tests/topics/goal-task/local-hook.md)** — the E2E harness's deterministic half.

## Coverage at a glance

| Property | Proven at | By |
|----------|-----------|-----|
| Gate + scaffold correctness | CI-push | `goal-task-scaffold` |
| Chain composition | CI-nightly | `goal-task-chain` |
| E2E-harness readiness | local-hook (also runs per-PR) | `goal-task-e2e-det` |
| Agent-executed prose | — (no required proof; deliberate) | on-demand eval / the real local E2E run, while they exist |
