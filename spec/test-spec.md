<!-- TEST-SPEC-GENERAL:BEGIN (portable — keep byte-identical across adopting repos) -->
# test-spec.md — the verification contract

This file is the single answer to one question: **what stops a broken change
from landing, what rules is the repo's verification surface held to, and at
which layer?** It is both the human-readable map (the prose + the four-layer
table below) and the machine source of truth (the fenced `yaml` registry at the
end), parsed by `test-spec.sh` (resolved `spec/test-spec.md` first, then a root
`test-spec.md` fallback).

This file is the **general tier** of a two-tier contract, delivered verbatim
(`test-spec.sh --seed` emits it byte-for-byte). A repo adopts the contract by
dropping in this file — and never editing it: repo-specific test logic — the
unit-level enumeration of the verification surface (every validator check,
test sub-suite, CI workflow, git hook) AND the per-mode pipeline gates — lives
in an optional **`test-spec-custom.md` overlay** next to this file (`units:`
rows + a `gates:` array in the same fenced-yaml grammar). The parser merges the
two internally, so consumers see ONE registry. An overlay-absent repo carries
the rules + layers alone: the coverage cross-check stays **inactive** until
`units:` rows exist, and tooling reports that state by name instead of inventing
findings.

## Two axes: category × layer

A test is classified on **two orthogonal axes** plus one per-test attribute — so
one place answers both *what kind of test is this?* and *where/when does it fire?*

- **category** — the *kind* of test, the closed set `{workflow, regression, infra}`:
  - **`workflow`** — proves a whole user-facing workflow runs end to end (features earn these).
  - **`regression`** — proves a specific past defect stays fixed (defects earn these).
  - **`infra`** — the standing verification surface itself (the validator, the full suite, the deploy harness).
- **layer** — *where/when* it runs, the closed set `{CI-push, CI-nightly, pipeline-gate, local-hook}` (below).
- **mode** — a per-test attribute, `deterministic | agentic` (agentic = spends model tokens; `agentic ⇒ tier ≠ free`).

The physical home reflects both axes: `tests/<category>/<layer>/<name>.test.sh`,
docs at `docs/tests/<category>/<layer>/<name>.md`.

## The four verification layers

A change passes through up to four independent verification layers between an
edit and a landed PR. Each layer runs at a different moment and owns a different
kind of guarantee:

| Layer | When it runs | What it owns | Disposition |
|-------|--------------|--------------|-------------|
| **CI-push** | on every push / PR (GitHub Actions) | the whole tree is structurally + behaviorally sound on a clean runner — the fast merge signal | hard-fail (gates the PR) |
| **CI-nightly** | on a nightly schedule (GitHub Actions) | heavier checks that would slow every PR run off the PR path on a nightly cadence | hard-fail (nightly) or advisory |
| **pipeline-gate** | during an orchestrated run | this run did the right thing — isolated, designed, tested, documented, honest — before it reached the PR | mixed (most halt; some advise) |
| **local-hook** | at `git commit` (pre-commit hook) + local-only manual harnesses | the commit is structurally valid before it ever leaves your machine | hard-fail (blocks the commit) |

`CI-push` and `CI-nightly` are the old undifferentiated `ci` blob, split by
cadence. **`ratchet` is no longer a layer** — a monotonic guard (VERSION never
regresses, the portability baseline, doc freshness) is a `ratchet: true` **flag**
on the unit that owns it, not a place a test runs.

The word **"gate"** is reserved here for a single thing: an **inline
orchestrator halt** (a `pipeline-gate` row, declared per repo in the overlay's
`gates:` array). The CI validator-as-a-whole is the **CI-push** layer (a set of
numbered *checks*), not "the gate." A monotonic guard is a **ratchet flag**.

## The five general rules

| Rule | What it asserts |
|------|-----------------|
| `tests-discoverable` | every test file under the repo's test dir(s) is wired into a runner declared by a `units:` row — no silent skips |
| `suite-green` | the declared full-suite runner passes before ship |
| `new-code-tested` | a change that adds behavior carries test rows covering it |
| `units-anchored` | every declared unit's anchor greps in its declared source (forward coverage) |
| `single-owner` | every live test surface resolves to exactly one declared unit (reverse coverage) |

Two enforcement layers stand behind the rules:

- **Deterministic** — `test-spec.sh --check-coverage` mechanizes
  `units-anchored` / `single-owner` / `tests-discoverable` wherever `units:`
  rows exist: forward, every unit's `anchor` must match LIVE in its declared
  `source`; reverse, every live test surface must resolve to exactly one unit;
  floor, the reverse extraction must keep yielding a healthy token count so
  grammar rot can never make the check vacuously pass.
- **Agent-judged** — `suite-green` and `new-code-tested` are judged against the
  repo's current state by the test audit (a red suite or behavior-adding code
  without covering test rows is a finding), layered ABOVE the deterministic
  floor, never replacing it.

## The behavior-coverage axis (optional, overlay-only)

The `rules:` + `layers:` + `units:` axes model the verification *plumbing*:
where verification fires, whether the test inventory is honest, and one row per
verification *mechanism*. None of them captures **what behavior the software
must be proven to do** — the contract is *closed-world over existing tests*, so
a behavior that *should* have a test but doesn't is structurally invisible.

An adopting repo MAY add a third, orthogonal axis in its
`test-spec-custom.md` overlay (these arrays are **optional-on-schema-1** and
live overlay-only — the machine block in this general file is unchanged):

- **`behaviors:`** — one row per *required behavior*: a stable `id`, a
  one-line `statement` (specific enough to fail), a first-class `level`, and an
  optional `area` / `purpose`. The `level` is the closed enum
  `unit | integration | contract | workflow | property` — it lives on the
  *obligation* (the behavior), NOT on a `units:` row, because one mechanism can
  legitimately prove several levels.
- **`behavior_coverage:`** — a many-to-many relation linking each behavior to a
  test-bearing `unit` (family `test | test-deploy | eval | windows-smoke` —
  never `validate | ci | hook`) plus a `source`/`anchor` pair pointing at the
  *semantic evidence* (the behavior named in the test/spec text, not merely the
  runner path).

`test-spec.sh --check-coverage` mechanizes the **structure** of this axis when
`behaviors:` rows exist (independent of the `units:` gate): every coverage link
resolves to exactly one behavior and one test-bearing unit, every `anchor`
greps live in its `source`, and every behavior has at least one covering row —
so a declared-but-uncovered behavior becomes a detectable gap instead of
silence. A repo with no `behaviors:` rows reports "behavior coverage inactive"
and stays green.

**Deterministic checks verify structure, not completeness.** The engine proves
the links resolve and the anchor greps live; it does NOT prove the linked test
*actually proves* the behavior (vs merely mentioning it), that the `level` is
correct, or that one broad test isn't over-claimed against many behaviors. That
substance judgment is the agent-judged test audit's job (`/CJ_test_audit`
Stage 2) — load-bearing, because the deterministic half alone merely relocates
the blind spot from untested code to vague behavior prose.

## The category axis (optional, overlay-only)

A repo MAY organize its tests on **two orthogonal axes** — `category` (the KIND)
× `layer` (WHERE/WHEN) — that together thread five surfaces: the folder a test
lives in (`tests/<category>/<layer>/`), the contract section that declares it, the
doc that describes it (`docs/tests/<category>/<layer>/<name>.md`), the index row
that references it, and the argument that runs it (`/CJ_test_run --category <cat>`,
`/CJ_test_run --layer <layer>`, or `/CJ_test_run <name>`). Audit and run share ONE
vocabulary; a newcomer looks at `tests/<category>/<layer>/` and sees at a glance
what a test *is* and *when it fires*.

The **category is the closed set `{workflow, regression, infra}`** — the *kind* of
test, modelled on the work-item that produced it:

- **`workflow`** — proves a whole user-facing workflow runs end to end (features earn these).
- **`regression`** — proves a specific past defect stays fixed (defects earn these).
- **`infra`** — the standing verification surface itself (the validator, the full suite, the deploy harness).

The **layer is the closed set `{CI-push, CI-nightly, pipeline-gate, local-hook}`**
— where/when it runs (the four verification layers above). On a `categories:` row
`layer` is **descriptive metadata** (the real cron/trigger stays in
`.github/workflows/*.yml`, kept consistent by hand).

**The three test levels per category.** Of the four layers, three are the
*per-category test levels* every category SHOULD reach — a category is only fully
covered when it has a test at each. `pipeline-gate` is an inline-orchestrator halt,
not a per-category test level, so it is excluded here:

- **CI-push** — a *quick deterministic* check: the fast per-PR merge signal
  (`mode: deterministic`, `tier: free`). Heavy deterministic work defaults OFF this
  level so the per-PR gate stays fast.
- **CI-nightly** — a *large deterministic* check: the heavier deterministic runs
  that would slow every PR, moved off the PR path onto a nightly cadence
  (`mode: deterministic`).
- **local-hook** — a *quick local* check a maintainer runs on their own machine:
  deterministic by default (`mode: deterministic`, `tier: free` — the pre-commit
  hook / run-before-push proof), optionally joined by an agentic proof
  (`mode: agentic`, so `tier ≠ free`) that spends model tokens on demand, never
  on a CI schedule.

An empty (category, level) cell is a *coverage gap*, not an error: some cells are
intentionally empty and a category need not fill all three. `test-spec.sh
--check-structure` therefore REPORTS the per-category × {CI-push, CI-nightly,
local-hook} matrix and emits an advisory `NOTE:` per empty cell — it never
hard-fails a gap (findings-are-the-product, exit 0 always). The matrix is a map of
where a category is thin, read by a maintainer (and surfaced in `/CJ_test_audit`
Stage 1), not a gate.

An adopting repo adds a `categories:` array to its `test-spec-custom.md` overlay
(**optional-on-schema-1**, overlay-only — the machine block in this general file
is unchanged). Each row declares one named test: `name` (a stable slug — it IS the
doc filename AND the `/CJ_test_run` argument), `category`
(`workflow | regression | infra`), `layer`
(`CI-push | CI-nightly | pipeline-gate | local-hook`), `mode`
(`deterministic | agentic` — REQUIRED, no default; `agentic ⇒ tier ≠ free`),
`command` (how to run it), `tier` (`free | paid | local-only`), an optional `doc`
(the `docs/tests/<category>/<layer>/<name>.md` pointer), and a short `purpose`.

`test-spec.sh --check-structure` mechanizes six structural checks when the
`categories:` axis exists: **(a)** a `tests/` folder holds the repo's scripts;
**(b)** `tests/` is split into per-`(category,layer)` subfolders (one
`tests/<category>/<layer>/` per pair that has ≥1 FILE-backed test — a command-only
row whose script lives elsewhere never forces an empty `tests/<cat>/<layer>/`);
**(c)** the `categories:` axis declares at least one test in each declared
category; **(d)** one `docs/tests/<category>/<layer>/<name>.md` per declared test;
**(e)** a `docs/tests/` INDEX table references every test by name; **(f)** each
per-test doc actually CONTENTS the three front-door sections (below). Each unmet
check is a `FINDING:` — findings are the product, never a crash. A repo with no
`categories:` axis reports "category contract not adopted / inactive" and stays
green.

**The per-test doc is the authoritative front door (GENERAL rule).** Each
declared category test's `docs/tests/<category>/<layer>/<name>.md` is the ONE place
a maintainer opens to understand and run that test, so it MUST document three
things, under these literal section headings:

- **`## What it is`** — one or two sentences: what this test verifies.
- **`## How to run`** — the exact command (matching the category's `command`) and
  the `/CJ_test_run <name>` / `/CJ_test_run --category <cat>` / `/CJ_test_run
  --layer <layer>` invocation.
- **`## Explanation`** — why the test exists / what it proves, cross-linking the
  relevant `docs/tests/<family>.md` units-detail page(s) for the per-unit
  breakdown.

The flat family docs (`docs/tests/<family>.md`, GENERATED by `--render-docs`) are
KEPT unchanged as that linked units-detail drill-down — the per-test doc is the
front door, the family doc is the detail behind it. `--seed-docs` seeds a fresh
per-test stub already carrying the three headings (present ⇒ skip preserves any
authored content), check **(f)** enforces their presence deterministically, and
`/CJ_test_audit` Stage 2 judges the content is TRUTHFUL (the how-to-run matches
the command; the what/why are accurate) — the doc-level catch for the
anchor-greps-while-the-doc-rots gap.

**The category axis is ADDITIVE and COEXISTS with the `units:`/`behaviors:`/
`runners:` axes** (V1 foundation). The audit REPORTS structural gaps and may SEED
missing doc stubs (`--seed-docs`, idempotent — present ⇒ skip), but NEVER moves or
rewrites test scripts: physically reorganizing a repo's tests into
`tests/<category>/<layer>/` is a one-time migration, not a run-time audit action,
so the audit stays standalone-safe on a repo it does not own.

## The topic axis + the three-layer topic contract (optional, overlay-only)

The `category` × `layer` axes place a single test; they do not say that a test
*topic* — a concern like portability or doc-sync that legitimately spans several
rows — is proven at every layer. A repo MAY add ONE more optional attribute plus an
enrollment list in its `test-spec-custom.md` overlay (both **optional-on-schema-1**,
overlay-only — the machine block in this general file is unchanged):

- **`topic:`** — an optional 9th field on any `categories:` row (a slug,
  `[a-z0-9-]+`) attributing that test to a *topic*. A row need not carry one; a
  topic simply clusters the rows that share it.
- **`topic_contracts:`** — an overlay-level list (e.g.
  `topic_contracts: [portability]`) naming the topics placed **under the
  three-layer contract**. Enrollment is the load-bearing seam: only enrolled topics
  are hard-checked, so adopting the contract for one topic never reds the build for
  the topics that are not yet ready.

**The three-deterministic-layers rule.** An enrolled topic must reach **all three
verification layers deterministically**:

- ≥1 `CI-push` test (the fast per-PR signal),
- ≥1 `CI-nightly` test (the heavier cadence off the PR path),
- ≥1 `local-hook` + `deterministic` test (the quick local proof).

A `local-hook` + `agentic` test is **advisory, never required**. Agentic proofs
run on-demand — they need a machine with Claude, which is why an agentic test
lives at `local-hook`, keeping model spend out of CI by construction — so
enrollment is never gated on the hardest-to-build test mode. Where an enrolled
topic has no agentic row, the check prints a per-topic advisory `note:`, keeping
the gap visible wherever the contract is read without redding the build; where a
topic does declare one, that proof catches the *green-but-inert* bugs the
deterministic layer structurally cannot (a stubbed test can pass while the real
behavior an operator sees is broken).

Each required coverage point must also carry its front-door
`docs/tests/<category>/<layer>/<name>.md`. `test-spec.sh --check-topic-contract`
mechanizes this for every enrolled topic — HARD (exit 1) on any missing
deterministic coverage point or front-door doc, an advisory `note:` (never a
finding) for a missing agentic row; it is **declaration-only**, so it runs in
plain CI with **zero model spend** — because `mode: agentic ⇒ tier ≠ free`, an
agentic row is present in CI but never *executed* there. The hard Check proves
the deterministic coverage is DECLARED; the executor (`/CJ_test_run --topic <t>
--e2e`, local-only) proves the agentic BEHAVIOR where a topic declares one.
A repo with no `categories:` axis or no `topic_contracts:` enrollment reports "topic
contract inactive" and stays green (a consumer passes vacuously). Surfaced by the
owner validator (a hard Check) + `/CJ_test_audit` Stage 1 (verbatim engine output),
with Stage 2 judging — where an enrolled topic declares an agentic row — that the
row names a real sandbox test, not a hollow prompt.

## The canonical contract-file template

The audit verbs (`/CJ_test_audit`, `/CJ_doc_audit`) own this contract's
canonical shape — what files are required, where they live, and their format:

- **Required** — the general file of each pair: `spec/test-spec.md` (this file)
  and `spec/doc-spec.md`. Each is delivered verbatim by its engine's `--seed`
  and must exist in an adopting repo (the audit seed-delivers a missing one).
- **Optional** — the `*-custom.md` overlay next to each general file
  (`spec/test-spec-custom.md`, `spec/doc-spec-custom.md`): the repo's chosen
  additions (here, the `units:` enumeration + the per-mode `gates:` array),
  merged in by the parser. A repo without an overlay carries the general
  contract alone.
- **Position** — `spec/` is canonical; the repo root is an accepted fallback
  (`test-spec.md` / `doc-spec.md`) for root-style consumers. The engine resolves
  `spec/`-then-root.
- **Format** — a single fenced `yaml` registry for test-spec; a 3-column
  Markdown table (`| Doc | Purpose | Requirement |`) for doc-spec. The block /
  table IS the source of truth, parsed directly.

`test-spec.sh --classify` reports a file's generation (canonical / absent /
duplicated). For test-spec, `--reconcile` is a dedup / no-op: the fenced-yaml
format has been canonical since introduction, so there is no legacy on-disk
format to migrate (unlike doc-spec, which migrates a legacy yaml registry to its
canonical Markdown table).

## Machine registry

The block below is the source of truth. Keep it the only fenced `yaml` block in
this file. It carries `rules[]` (the five portable rules) and `layers[]` (the
four-layer map — `CI-push | CI-nightly | pipeline-gate | local-hook`; `ratchet`
is a `ratchet: true` flag, not a layer). The repo-specific `units:` enumeration
and the per-mode `gates:` array live in the optional `test-spec-custom.md` overlay.

```yaml
# test-spec registry (parsed by test-spec.sh; merged with the optional
# test-spec-custom.md overlay; consumed by a CI validator + a test-audit skill)
schema_version: 1
rules:
  - id: tests-discoverable
    statement: "Every test file under the repo's test dir(s) (default tests/) is wired into a runner declared by a units: row — a test file on disk that no runner invokes silently never runs."
    scope: "every test file on disk"
    enforced_by: "test-spec.sh --check-coverage reverse sweep (active when units: rows exist)"
  - id: suite-green
    statement: "The declared full-suite runner passes before ship."
    scope: "the whole verification surface"
    enforced_by: "agent-judged by the test audit / QA (a red suite is a finding)"
  - id: new-code-tested
    statement: "A change that adds behavior carries test rows covering it."
    scope: "every behavior-adding change"
    enforced_by: "agent-judged by the test audit / QA (code-without-units drift is a finding)"
  - id: units-anchored
    statement: "Every declared unit's anchor matches LIVE in its declared source file (forward coverage — dead-text mentions do not count)."
    scope: "every units: row"
    enforced_by: "test-spec.sh --check-coverage forward anchor-grep"
  - id: single-owner
    statement: "Every live test surface resolves to exactly one declared unit (reverse coverage)."
    scope: "every live validator banner/comment, test file on disk, CI workflow, installed hook"
    enforced_by: "test-spec.sh --check-coverage reverse sweep + floor (active when units: rows exist)"
layers:
  - id: CI-push
    name: "CI on every push / PR"
    trigger: "on every push / PR"
    disposition: hard-fail
    owns: "the whole tree is structurally + behaviorally sound on a clean runner (the fast merge signal)"
  - id: CI-nightly
    name: "CI on a nightly schedule"
    trigger: "on a nightly schedule"
    disposition: hard-fail
    owns: "heavier checks off the PR path run on a nightly cadence"
  - id: pipeline-gate
    name: "In-orchestrator gates"
    trigger: "during an orchestrated run"
    disposition: mixed
    owns: "this run did the right thing before it reached the PR"
  - id: local-hook
    name: "Local pre-commit hook + local-only harnesses"
    trigger: "at git commit / local manual run"
    disposition: hard-fail
    owns: "the commit is structurally valid before it leaves the machine"
```
<!-- TEST-SPEC-GENERAL:END -->
