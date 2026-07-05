# Goal: portability — another machine gets the same skills as in this repo

> **Dream docs** state *what the system should achieve* — the aspiration a family
> of tests exists to realize. They are the WHAT. The matching
> [`docs/tests/topics/<topic>/`](../tests/topics/portability/index.md) pages are
> the HOW: which tests, at which layer, prove each property. Read this first, then
> follow the links to see how it is achieved.

## The end goal

**When someone installs this workbench on another machine, they get the same
`CJ_` skills — the same set, the same content, on any platform — as the repo
ships.** A `git clone` + `skills-deploy install` on a teammate's Mac, a fresh
Linux CI runner, or a Windows Git-Bash box must reproduce *this repo's* skill
surface faithfully. If it doesn't, a skill that works here silently breaks there,
and the "install == clone" promise is a lie.

This is not one test — it is a **topic**: a set of tests that together cover the
goal. The goal decomposes into three independent properties. All three must hold
for the end goal to hold.

## The three properties

| Property | What it means (the aspiration) | Why it can fail |
|----------|-------------------------------|-----------------|
| **Completeness** | *Every* skill the repo ships is deployed on the other machine — none silently missing. | A deploy bug drops a skill; a new skill isn't picked up; a filter excludes one. |
| **Fidelity** | The deployed bytes match the source, and any later drift is detected. | A copy corrupts a file; a CRLF rewrite on Windows; a hand-edit drifts a deployed skill away from source. |
| **Cross-platform parity** | Windows / Git-Bash gets a *functionally identical* install to macOS / Linux. | Real symlinks are unavailable on Git-Bash; a POSIX-only idiom (GNU `date`, `\r`-free jq) breaks the install path. |

### Why "install == clone" makes this achievable

The deep reason the goal is reachable at all: `skills-deploy install` makes the
deployed `~/.claude/skills/` resolve to the *same source tree* — symlinks on
POSIX, checksum-tracked real-file copies on Git-Bash. So parity is **by
construction** (same clone → same source → deployed verbatim). The tests below
verify the deploy step doesn't drop, corrupt, or platform-diverge anything.

## Supporting guarantees

Two more concerns aren't the end goal itself, but the goal is worthless without
them:

| Guarantee | What it means | Why it matters to the goal |
|-----------|---------------|----------------------------|
| **No hidden coupling** (precondition) | A skill declared `standalone` must not secretly depend on workbench-only files (root `scripts/*.sh`, `CLAUDE.md`, the manifest `.source`). | A skill that *can't* run without the workbench will "install" on another machine but fail at runtime — completeness without usability. |
| **Freshness signal** | When a newer collection version is published, the deployed skills nudge the user to upgrade. | A machine that installed once but never re-syncs slowly diverges from the repo — the goal decays over time. |

## How this goal is achieved (the tests)

The full "how" — which test proves each property, at which verification layer, and
how to run it — lives in the topic pages:

- **[Overview + coverage matrix](../tests/topics/portability/index.md)** — the property → test → layer map.
- **[CI-push layer](../tests/topics/portability/CI-push.md)** — the fast per-PR proofs (cross-platform parity + completeness + fidelity + the no-hidden-coupling lint).
- **[CI-nightly layer](../tests/topics/portability/CI-nightly.md)** — the heavy full deploy-harness proof.
- **[local-hook layer](../tests/topics/portability/local-hook.md)** — the freshness-signal proofs (deterministic + agentic).

## Coverage at a glance

| Property | Proven at | By |
|----------|-----------|-----|
| Completeness | CI-push (fast) + CI-nightly (full) | `windows-smoke` S5 · `portability-deploy` Test 1 |
| Fidelity | CI-push (fast) + CI-nightly (full) | `windows-smoke` S6 · `portability-deploy` C1/C3/C4 |
| Cross-platform parity | CI-push | `portability-smoke` S1–S4 |
| No hidden coupling | CI-push | `portability-check18-lint` (validate Check 18, strict) |
| Freshness signal | local-hook | `portability-version-check` + `portability-version-agentic` |
