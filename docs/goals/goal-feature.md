# Goal: goal-feature — a one-line topic becomes a reviewable PR

> **Dream docs** state *what the system should achieve* — the aspiration a family
> of tests exists to realize. They are the WHAT. The matching
> [`docs/tests/topics/<topic>/`](../tests/topics/goal-feature/index.md) pages are
> the HOW: which tests, at which layer, prove each property. Read this first, then
> follow the links to see how it is achieved.

## The end goal

**When the operator types `/CJ_goal_feature "<topic>"`, the workbench carries
that one line all the way to a reviewable PR** — an isolated worktree, an
approved design, a scaffolded work-item, an implementation, a QA pass, folded
docs, and a PR that stops for human review. The feature verb is the workbench's
primary build surface; if its plumbing rots, the daily path from idea to PR
silently breaks.

This is not one test — it is a **topic**: a set of tests that together cover the
verb's *deterministic* machinery. The goal decomposes into three properties.

## The three properties

| Property | What it means (the aspiration) | Why it can fail |
|----------|-------------------------------|-----------------|
| **Entry + phase shape** | The worktree entry mints an isolated `cj-feat-*` checkout and every shared helper phase (worktree / ship / telemetry) answers its documented contract, with the leaf-dispatch targets real on disk. | A helper refactor changes a caller prefix, drops a phase field, or a leaf skill moves — the pipeline's first steps break before any build starts. |
| **Chain composition** | The phases COMPOSE: one checkout flows through worktree → sync → pr-check → the design-gate seam → recap → cleanup, end to end, each seam honoring its contract in sequence. | Each phase can pass in isolation while an interaction breaks — a worktree the janitor won't preview, a sync opt-out that halts the chain, a gate seam that fires without its guards. |
| **Gate-seam safety** | The design-gate auto-answer seam is inert in a normal run (double hard guard), auto-approves only under the sandbox harness, and can never answer a ship/merge/deploy gate. | A guard regression makes the seam live in a real repo — the one interactive design gate silently self-approves. |

## The deliberate deterministic-only posture

This topic is enrolled in the topic contract (`topic_contracts:`), where the
`local-hook`+`agentic` point is **advisory for every enrolled topic**, so
this topic's three required coverage points are all
`mode: deterministic`, and the verb's agentic eval (the `goal-feature-eval` row,
a real `claude --print` run of the orchestrator) is *tolerated, never required*
— it remains runnable on demand while it exists, but deleting it cannot red the
contract. The conscious trade: **the agent-executed `pipeline.md` prose has no
required proof** — deterministic drills reach the helper SCRIPTS only (the
helpers-only ceiling), so a prose-level pipeline regression ships silently until
an operator run or an on-demand eval catches it. That re-opens, for this topic,
the green-but-inert blind spot the agentic mode exists to close — accepted
because the agentic assets are scheduled for removal, and enrollment must not
depend on assets planned for deletion.

## How this goal is achieved (the tests)

The full "how" — which test proves each property, at which verification layer,
and how to run it — lives in the topic pages:

- **[Overview + coverage map](../tests/topics/goal-feature/index.md)** — the property → test → layer map.
- **[CI-push layer](../tests/topics/goal-feature/CI-push.md)** — the fast per-PR shape smoke.
- **[CI-nightly layer](../tests/topics/goal-feature/CI-nightly.md)** — the composed helper-chain drill.
- **[local-hook layer](../tests/topics/goal-feature/local-hook.md)** — the gate-seam verdict matrix.

## Coverage at a glance

| Property | Proven at | By |
|----------|-----------|-----|
| Entry + phase shape | CI-push | `goal-feature-smoke` |
| Chain composition | CI-nightly | `goal-feature-chain` |
| Gate-seam safety | local-hook (also runs per-PR) | `goal-feature-gate-seam` |
| Agent-executed prose | — (no required proof; deliberate) | on-demand eval, while it exists |
