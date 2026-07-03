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

## The four verification layers

A change passes through up to four independent verification layers between an
edit and a landed PR. Each layer runs at a different moment and owns a different
kind of guarantee:

| Layer | When it runs | What it owns | Disposition |
|-------|--------------|--------------|-------------|
| **local-hook** | at `git commit` (pre-commit hook) | the commit is structurally valid before it ever leaves your machine | hard-fail (blocks the commit) |
| **ci** | on every PR (GitHub Actions) | the whole tree is structurally + behaviorally sound on a clean runner | hard-fail (gates the PR) |
| **pipeline-gate** | during an orchestrated run | this run did the right thing — isolated, designed, tested, documented, honest — before it reached the PR | mixed (most halt; some advise) |
| **ratchet** | inside ci / the orchestrator | a monotonic property never regresses (VERSION, the portability baseline, doc freshness) | advisory or hard-fail |

The word **"gate"** is reserved here for a single thing: an **inline
orchestrator halt** (a `pipeline-gate` row, declared per repo in the overlay's
`gates:` array). The CI validator-as-a-whole is the **ci** layer (a set of
numbered *checks*), not "the gate." A monotonic guard is a **ratchet**. Three
words, three referents, no overload.

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

A repo MAY organize its tests by **category** — one clean noun that threads five
surfaces: the folder a test lives in (`tests/<category>/`), the contract section
that declares it, the doc that describes it (`docs/tests/<category>/<name>.md`),
the index row that references it, and the argument that runs it
(`/CJ_test_run --category <cat>` or `/CJ_test_run <name>`). Audit and run share
ONE vocabulary; a newcomer can look at `tests/` and see what kinds of tests exist.

The **V1 taxonomy is the closed set `{workflow, CI}`**:

- **`workflow`** — deterministic end-to-end workflow tests (what proves a whole
  user-facing workflow runs).
- **`CI`** — tests required at each deployment / the deploy gate (what must be
  green to ship).

An adopting repo adds a `categories:` array to its `test-spec-custom.md` overlay
(**optional-on-schema-1**, overlay-only — the machine block in this general file
is unchanged). Each row declares one named test: `name` (a stable slug — it IS the
doc filename AND the `/CJ_test_run` argument), `category` (`workflow | CI`),
`command` (how to run it), `tier` (`free | paid | local-only`), an optional `doc`
(the `docs/tests/<category>/<name>.md` pointer), and a short `purpose`.

`test-spec.sh --check-structure` mechanizes five structural checks when the
`categories:` axis exists: **(a)** a `tests/` folder holds the repo's scripts;
**(b)** `tests/` is split into per-category subfolders (V1 requires `tests/workflow/`
+ `tests/CI/`); **(c)** the `categories:` axis declares the `workflow` + `CI` tests;
**(d)** one `docs/tests/<category>/<name>.md` per declared test; **(e)** a
`docs/tests/` INDEX table references every test by name. Each unmet check is a
`FINDING:` — findings are the product, never a crash. A repo with no `categories:`
axis reports "category contract not adopted / inactive" and stays green.

**The category axis is ADDITIVE and COEXISTS with the `units:`/`behaviors:`/
`runners:` axes** (V1 foundation). The audit REPORTS structural gaps and may SEED
missing doc stubs (`--seed-docs`, idempotent — present ⇒ skip), but NEVER moves or
rewrites test scripts: physically reorganizing a repo's tests into
`tests/<category>/` is a one-time migration, not a run-time audit action, so the
audit stays standalone-safe on a repo it does not own.

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
four-layer map). The repo-specific `units:` enumeration and the per-mode
`gates:` array live in the optional `test-spec-custom.md` overlay.

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
  - id: local-hook
    name: "Local pre-commit hook"
    trigger: "at git commit"
    disposition: hard-fail
    owns: "the commit is structurally valid before it leaves the machine"
  - id: ci
    name: "CI on every PR"
    trigger: "on every PR"
    disposition: hard-fail
    owns: "the whole tree is structurally + behaviorally sound on a clean runner"
  - id: pipeline-gate
    name: "In-orchestrator gates"
    trigger: "during an orchestrated run"
    disposition: mixed
    owns: "this run did the right thing before it reached the PR"
  - id: ratchet
    name: "Regression ratchets"
    trigger: "inside ci / the orchestrator"
    disposition: advisory
    owns: "a monotonic property never regresses"
```
<!-- TEST-SPEC-GENERAL:END -->
