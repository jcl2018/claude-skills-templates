# Goal: goal-defect — a bug description becomes a shipped fix

> **Dream docs** state *what the system should achieve* — the aspiration a family
> of tests exists to realize. They are the WHAT. The matching
> [`docs/tests/topics/<topic>/`](../tests/topics/goal-defect/index.md) pages are
> the HOW: which tests, at which layer, prove each property. Read this first, then
> follow the links to see how it is achieved.

## The end goal

**When the operator types `/CJ_goal_defect "<bug description>"`, the workbench
carries that description all the way to a shipped, locally-synced fix** — an
isolated worktree, a root-caused investigation, a promoted defect work-item
with an atomically-minted D-ID, a QA'd fix, and — because defect is a LANDING
verb, unlike the PR-stop feature/task verbs — an in-pipeline merge followed by
the post-land sync that reinstalls the merged skills locally. The defect verb's
promise extends past the PR: the fix is not "done" until the operator's own
machine runs it.

This is not one test — it is a **topic**. The goal decomposes into three
properties.

## The three properties

| Property | What it means (the aspiration) | Why it can fail |
|----------|-------------------------------|-----------------|
| **Entry + phase shape** | The worktree entry mints an isolated `cj-def-*` checkout and every shared helper phase (worktree / ship / telemetry) answers its documented contract under `--mode defect`, with the qa/doc-sync leaf targets real on disk. | A helper refactor changes the caller prefix or drops a phase field; a leaf skill moves — and (before this topic) the defect path had NO per-PR proof to catch it. |
| **Chain + land-tail composition** | The steps COMPOSE through the land tail: worktree entry → the D-ID atomic-claim preview → pr-check → the before/after recap pair → the post-land-sync preview → cleanup, each seam honoring its contract in sequence. | The land bracket is defect-specific — a recap regression or a claim-engine change breaks only the landing verbs, invisible to feature/task coverage. |
| **Land-tail safety** | The post-land sync's guards refuse a bad `.source` (missing / not a repo / off-main / dirty) and its preview mutates nothing — the last deterministic mile between a remote merge and the operator's live `~/.claude`. | A guard regression lets a sync run against a dirty or wrong checkout, corrupting the live install after a land. |

## The deliberate deterministic-only posture

This topic is enrolled in the topic contract's **deterministic-only** flavor
(`topic_contracts_deterministic:`): its three required coverage points are all
`mode: deterministic`. The defect verb has NO declared agentic row at all — its
on-disk eval case stays undeclared on the category axis by choice (no new
agentic dependencies while the agentic assets are scheduled for removal). The
conscious trade: **the agent-executed `pipeline.md` prose — including the
root-cause iron-law gate the agent enforces — has no required proof**;
deterministic drills reach the helper SCRIPTS only (the helpers-only ceiling),
so a prose-level regression ships silently until an operator run catches it.
The deterministic smoke + chain + land-sync coverage is the accepted proxy.

## How this goal is achieved (the tests)

The full "how" — which test proves each property, at which verification layer,
and how to run it — lives in the topic pages:

- **[Overview + coverage map](../tests/topics/goal-defect/index.md)** — the property → test → layer map.
- **[CI-push layer](../tests/topics/goal-defect/CI-push.md)** — the fast per-PR shape smoke.
- **[CI-nightly layer](../tests/topics/goal-defect/CI-nightly.md)** — the composed chain drill through the land tail.
- **[local-hook layer](../tests/topics/goal-defect/local-hook.md)** — the post-land sync guards + preview.

## Coverage at a glance

| Property | Proven at | By |
|----------|-----------|-----|
| Entry + phase shape | CI-push | `goal-defect-smoke` |
| Chain + land-tail composition | CI-nightly | `goal-defect-chain` |
| Land-tail safety | local-hook (also runs per-PR) | `goal-defect-land-sync` |
| Agent-executed prose | — (no required proof; deliberate) | operator runs; no declared agentic row for this verb |
