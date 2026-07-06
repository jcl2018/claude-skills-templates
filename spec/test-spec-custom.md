# test-spec-custom.md — this repo's verification-surface overlay

This file is the **custom tier** of the two-tier test contract: the machine
source of truth for **this repo's verification surface**. It carries two
top-level arrays. (1) A `units:` block — one row per verification unit: every
numbered `scripts/validate.sh` check (both ID namespaces) and warning check,
every registered `tests/*.test.sh` sub-suite and inline `scripts/test.sh`
family, the standalone suites (`test-deploy`, `eval`, `windows-smoke`), the
GitHub Actions workflows, and the git hooks. (2) A `gates:` block — one row per
per-mode pipeline-gate halt (the four-layer map's `pipeline-gate` layer, folded
in from the retired `gate-spec.md`). `scripts/test-spec.sh` merges both into the
portable general contract ([`spec/test-spec.md`](test-spec.md), the seed — which
carries the `rules:` + the four-layer `layers:` registry — never edited in
place), so consumers see ONE verification contract.

The `gates:` rows are a SEPARATE array, NOT `units:` rows: the `units:` `layer`
enum is `{local-hook, CI-push, CI-nightly}` and would reject `pipeline-gate`. The
general test-spec carries the four `layers:` (CI-push / CI-nightly / pipeline-gate
/ local-hook — `ratchet` is now a `ratchet: true` flag, not a layer); this overlay
carries the per-mode `gates:` that run in the `pipeline-gate` layer.

## The verification surface, grouped by layer

The general contract ([`test-spec.md`](test-spec.md)) names the four
verification layers in the abstract; this section is the reader's-eye index of
which **kinds** of tests this repo actually runs in each one. The fenced `yaml`
registry below stays the source of truth — this grouping is derived from it
(prose drift is caught by the advisory registered-doc requirements audit, the
same posture as the per-row `purpose` one-liners). Each `units:` row carries a
`layer` (`local-hook | CI-push | CI-nightly`) and a `family`; the `gates:` array is
the `pipeline-gate` layer; the `ratchet: true` flag marks the cross-cutting
ratchet property (a ratchet unit also runs in `CI-push`).

### Handled by `CI-push` (every push / PR, on a clean runner — hard-fail)

The bulk of the surface. Four kinds, each its own table below. (The sole remaining
`CI-nightly` row — the `windows-nightly` workflow — is in its own subsection below.
The former `eval-nightly` / `audit-nightly` workflows were removed with F000080, and
`suite-eval` + the agentic eval / doc-sync category tests now run on-demand at the
`local-hook` layer.)

**Validator checks** — `scripts/validate.sh` (also run at `pre-commit`, below).
The *Error checks* are hard-fail and comment-anchored; the *numbered Checks* are
banner-anchored; the two *Warning checks* are advisory; the *portability-audit
engine* runs behind Check 18. ("Error check 11" and "Check 11" are two distinct
live checks sharing a numeral.)

| Check / Unit | What it asserts |
|---|---|
| Error check 1 — catalog entries have SKILL.md on disk | Every catalog entry's declared SKILL.md exists (templates-only exempt). |
| Error check 2 — SKILL.md frontmatter required fields | Every SKILL.md carries name + description in its frontmatter. |
| Error check 3 — declared templates exist on disk | Every catalog template resolves to a file, honoring source overrides. |
| Error check 4 — no orphan skill directories | Every skill directory on disk is claimed by a catalog entry. |
| Error check 5 — doc triplets complete with type frontmatter | Each per-skill doc dir carries all three design docs, typed. |
| Error check 6 — skill dependencies resolve | Every declared skill dependency names another catalog entry. |
| Error check 7 — VERSION file valid semver | The VERSION file exists and parses as semver. |
| Error check 8 — VERSION never regresses | VERSION is at least the latest collection v-tag (ratchet). |
| Error check 9 — catalog skill versions valid semver | Every catalog entry's version field parses as semver. |
| Error check 9b — catalog status closed enum | Every status is active, experimental or deprecated; typos fail. |
| Error check 10 — Copilot bundle file existence | Every required Copilot bundle file is present on disk. |
| Error check 11 — manifest reconciliation | Work-item dirs carry every artifact their manifest requires per type. |
| Check 11 — rules deploy health | Every rules file is deployed locally; warn-degrades when target absent. |
| Check 13 — USAGE.md present with required sections | Every routable skill has a USAGE.md with five required headings. |
| Check 14 — USAGE.md content freshness | USAGE.md no older than its sibling SKILL.md (ratchet). |
| Check 15 — doc registry declared matches on-disk + workflow doc completeness | Declared docs exist, no orphans, and workflow doc charts each orchestrator. |
| Check 16 — doc registry schema | The doc registry parses: schema version, required keys, closed enums. |
| Check 17 — root-doc placement allowlist | Every root markdown doc is a declared registry path. |
| Check 18 — skill portability audit | Each skill's declared portability matches its actual dependencies (ratchet baseline). |
| Check 19 — no work-item refs in human docs | No registry human-doc contains an internal work-item ID. |
| Check 21 — permission-policy drift | The permission policy parses and every orchestrator references it. |
| Check 24 — test-spec coverage cross-check + gate marker drift | The test-spec registry validates and coverage cross-checks (forward + reverse). |
| Check 25 — README.md in sync with generate-readme.sh | The committed README byte-matches the generator's output, so a catalog-derived README cannot drift. |
| Warning check — orphan doc directories | Flags per-skill doc directories with no matching catalog entry. |
| Warning check 3 — orphan template files | Flags template files not referenced by any catalog entry. |
| portability audit — declared-vs-actual skill dependency lint | The engine behind Check 18. |

**Behavioral test suites** — `scripts/test.sh`. The *registered `tests/*.test.sh`
sub-suites* and the *inline `test.sh` families*:

| Check / Unit | What it asserts |
|---|---|
| cj-worktree-init suite — worktree creation helper | Caller prefixes, dirty-checkout guard and base-freshness of worktree-init. |
| cj-worktree-cleanup suite — post-run worktree janitor | PR-state-gated sweep, orphan-dir removal and guard refusals of the janitor. |
| cj-task-scaffold suite — task complexity gate + scaffold | Complexity-gate refusals, dry-run, live scaffold and idempotency of the scaffolder. |
| setup-hooks suite — git hook installer | The post-merge hook re-deploys skills without mutating trackers; clobber-safe. |
| drain-one-todo suite — deployed-path resolution | A deployed drain helper resolves the worktree-init helper via manifest source. |
| drain-one-todo suite — unreachable-helper fail-loud | The drain halts loudly when the worktree helper is unreachable. |
| cj-document-release suite — doc-release skill structure | Doc-release skill structure, frontmatter, halt markers and config-helper assertions. |
| doc-release config suite — doc registry + helper + seed | Doc registry table shape, every doc-spec subcommand, no-config gates, embedded seed. |
| goal doc-sync wiring suite — symmetric step wiring | Doc-sync step and halt-taxonomy rows present and ordered in orchestrators. |
| post-land-sync suite — post-merge local sync helper | Sync-helper guards refuse a bad source; dry-run previews without mutating. |
| tag-release suite — post-land v<VERSION> tag publish | Publishes the v<VERSION> tag to a fake bare origin so the update-check ls-remote read sees the newest release; idempotent, fail-soft. |
| goal-common sync suite — pre-build skills-sync phase | Dry-run, opt-out, guard-refusal and real-run paths emit the four-key schema. |
| cj-id-claim suite — atomic work-item ID claim | Concurrent-race uniqueness, both reap modes, prefix isolation and reuse. |
| feature-path smoke suite — worktree entry + common phases | Feature worktree entry, the shared helper's phases, and leaf dispatch targets. |
| doc-spec overlay suite — two-tier merge semantics | Overlay merge, duplicate-path guard, seed byte identity, the Stage-1 battery. |
| test-spec suite — two-tier registry parser + coverage drills | Parser round-trip, absent-vs-invalid split, the floor note, coverage drift drills. |
| audit-skills suite — seed delivery + audit engines | Seed delivery, idempotence, seeded-violation findings, per-stage report contract. |
| doc-spec reconcile suite — classify + legacy→canonical migration | `doc-spec.sh --classify` the four generations + `--reconcile` a legacy YAML registry to the canonical table (atomic, idempotent). |
| test-spec reconcile suite — symmetric classify + dedup/no-op | `test-spec.sh --classify` absent/canonical/duplicate/malformed + `--reconcile` as a dedup/no-op (never legacy). |
| Inline — full validator re-run | Runs the whole validator inside the suite so every check gates it. |
| Inline — harness-principle regression guards | Static guards that the trajectory-QA, permission and receipt fixes stay. |
| Inline — catalog + frontmatter + doc-triplet smoke | No duplicate names; frontmatter parses; doc triplets carry required sections. |
| Inline — advisory-script crash + generator idempotency | Doctor, lint and deps run without crashing; the README generator is idempotent. |
| Inline — manual skill-creation integration cycle | A scaffolded temp skill stays green; plant-and-restore negatives fire. |
| Inline — goal-common phase integration | Sync and task-worktree phases end-to-end and hermetic. |
| Inline — template content + validator portability + orphan negatives | Tracker templates carry sections; validator stands alone; orphan detection fires. |
| Inline — defect and story regression battery | Shipped defect and story fixes stay fixed (CRLF, merge guard, copy-mode). |
| Inline — Copilot bundle coverage + round-trip | Bundle completeness, the instructions size budget and the deploy round-trip. |
| Inline — backlog append POSIX-clean guard | The improve-queue append path keeps the backlog file POSIX-clean. |
| Inline — version-queue preflight smoke | The version-queue preflight runs read-only and degrades cleanly offline. |
| Inline — handoff-gate deterministic suite | Denylist hits, size caps, rename/symlink detection and the QA predicate. |
| Inline — static wiring checks | POSIX idioms, registered-doc audit wiring, tracker promotion, Touches blocks. |
| Inline — portability-engine hermetic fixture | The portability-audit engine's verdicts against a controlled fixture catalog. |
| Inline — install equals clone integration battery | Shared-script self-containment, bundle install and the install-equals-clone contract. |
| Inline — test-spec registry + coverage guards | The parser validates the merged registry and coverage passes on the live tree. |

**Standalone suites** (also manually runnable; some also run on push-main):

| Check / Unit | What it asserts |
|---|---|
| Windows smoke — CRLF + portable date + copy-mode | Git Bash assertions: CRLF tolerance, portable date math, copy-mode install stamp. |

(The `skills-deploy` / `test-deploy` standalone suite is re-layered to `CI-nightly` —
see the section below.)

**GitHub Actions workflows** (CI-push subset):

| Check / Unit | What it asserts |
|---|---|
| validate workflow — PR gate | Runs the validator, the FAST test subset (`TEST_FAST=1` — skips the heavy `test-deploy` suite) and shellcheck on every PR. |
| windows workflow — Git Bash smoke gate | Runs the fast Windows smoke under Git Bash on PR + push-main (CI-push cadence). |

### Handled by `CI-nightly` (heavier DETERMINISTIC checks off the PR path, on a nightly schedule)

Deterministic-only. Two scheduled workflows run here: `nightly.yml` (the ubuntu
full `scripts/test.sh`, F000081/WS4) and `windows-nightly.yml` (the windows-latest
skills-deploy suite, F000080). The heavy `skills-deploy` / `test-deploy` suite is
re-layered to this cadence (F000081 follow-up): the per-PR `test.sh` skips it under
`TEST_FAST=1`, so it gates via `nightly.yml` rather than on every PR. The
`portability-deploy` workflow-category test shares this cadence.

| Check / Unit | What it asserts |
|---|---|
| nightly workflow — full test suite | Runs the FULL scripts/test.sh (including test-deploy.sh) on ubuntu-latest nightly + on dispatch (CI-nightly cadence). |
| skills-deploy suite — install/doctor/remove in isolation | Template ownership, drift overwrite, copy-mode and doctor verdicts in temp homes; re-layered from CI-push (the per-PR test.sh skips it under TEST_FAST=1). |
| windows-nightly workflow — nightly skills-deploy suite | Runs the full skills-deploy suite (test-deploy.sh) on windows-latest nightly + on dispatch (CI-nightly cadence). |

### Handled by `local-hook` (at `git commit`, or run on-demand before code leaves the machine)

The git hooks installed by `scripts/setup-hooks.sh` (the validator rows carry
the `pre-commit pr-ci` trigger — the same checks, two firing points), plus the
on-demand agentic proofs that F000080 moved off the CI schedule: the behavioral
eval harness (`suite-eval`), the `goal-task-eval` / `goal-feature-eval` /
`doc-sync` workflow-category tests, and the `e2e-local` happy-path harness. These
spend model tokens, so they run only when the operator invokes them
(`bash scripts/eval.sh`, `bash scripts/audit-nightly.sh`, `/CJ_test_run`), never
unattended in CI.

| Check / Unit | What it asserts |
|---|---|
| pre-commit hook — validator at commit time | Runs the validator before every local commit; a failing check blocks it. |
| post-merge hook — auto re-deploy | Re-deploys skills, templates and rules after pulls; best-effort, never blocks git. |
| behavioral eval harness — headless skill evals | Spawns the headless CLI per eval case with JSON-schema output, budget-capped; run on-demand (`bash scripts/eval.sh`). |

### Handled by `pipeline-gate` (during an orchestrated `CJ_goal_*` run)

The `gates:` array — the inline halts a goal orchestrator runs before its PR, in
`order`. Each mode runs its subset:

| order | gate | runs in | halts on |
|------:|------|---------|----------|
| 10 | isolation | feature, defect, task | un-isolated / dirty checkout |
| 20 | design-gate | feature | design not approved |
| 25 | root-cause | defect | no populated root cause |
| 30 | complexity | task | topic too big for a task |
| 40 | qa | all four | failing test rows |
| 45 | doc-sync | all four | doc drift can't fold into the PR |
| 70 | ship | all four | the human ship gate (PR-stop) |

### Ratchets (cross-cutting — monotonic guards that never regress)

The `ratchet: true` units (each also runs in `CI-push`; `ratchet` is a flag, not a layer):

| Check / Unit | What it asserts |
|---|---|
| Error check 8 — VERSION never regresses | VERSION is at least the latest collection v-tag; a regression fails. |
| Check 14 — USAGE.md content freshness | USAGE.md is no older than its sibling SKILL.md. |
| Check 18 — skill portability audit | The clean zero-findings portability baseline never regresses. |
| portability audit — declared-vs-actual skill dependency lint | The portability engine's clean baseline behind Check 18 is the ratchet. |

## How the registry is enforced

One hard `validate.sh` loop keeps this registry honest by construction —
**coverage (Check 24, via `scripts/test-spec.sh --check-coverage`)**:

- *Forward*: every row's `anchor` must match LIVE in its declared `source`
  file. A renamed/removed check orphans its row; a de-registered test file's
  runner block disappearing from `scripts/test.sh` orphans that row.
- *Reverse*: every live `^echo "=== Check N:"` banner, `^# Error check N:`
  comment and `^# Warning check` comment in `scripts/validate.sh`, every
  `tests/*.test.sh` on disk, every `.github/workflows/*.yml`, and every
  `install_hook` invocation in `scripts/setup-hooks.sh` must resolve to
  exactly one registry row in its namespace.
- *Floor*: reverse extraction must yield ≥ 20 tokens, so grammar rot can
  never make the check vacuously pass. Both the reverse sweep and the floor
  are **gated on `units:` rows existing** — a rules-only consumer repo gets a
  named "coverage cross-check inactive" note, never a misleading finding.

Semantic accuracy of each `purpose` one-liner is NOT mechanized — it stays
with the advisory registered-doc requirements audit (the same posture as every
other registered doc). The checks above buy structural sync, not meaning sync.

## Schema

The fenced `yaml` block at the end is the overlay registry. Keep it the
**only** fenced `yaml` block in this file. One `units[]` entry per
verification unit:

- `id` — stable slug, unique across the merged registry, `[a-z0-9-]+`.
- `family` — closed enum: `validate | test | test-deploy | eval |
  windows-smoke | ci | hook`.
- `label` — the human label. **Work-item-ID-free** (the rendered-field lint).
  For `validate` rows the label preserves the exact ID namespace — "Error
  check 11" and "Check 11" are two distinct live checks sharing a numeral.
- `anchor` — a literal grep string locating the unit in its `source` file.
  Anchors MAY carry work-item IDs (they never render) but must not contain
  double quotes or tabs (parser constraint).
- `source` — the repo-relative file the anchor must be found in. **Rule for
  `tests/*.test.sh` rows: `source` MUST be `scripts/test.sh` and `anchor`
  MUST be the literal runner path** (`tests/<name>.test.sh`) — the forward
  check is what proves the file is actually WIRED into the suite (test
  discovery is hand-wired, not glob-based; an unregistered test file silently
  never runs).
- `layer` — the four-layer-map layer that OWNS the unit, closed enum
  `local-hook | CI-push | CI-nightly` (the `ci` blob split by cadence; F000078).
  Per the doctrine ("validate.sh-as-a-whole is the CI-push layer"), `validate`
  rows record `CI-push`; hook rows record `local-hook`; a `nightly`-triggered
  unit records `CI-nightly`. Firing points are fully captured by `trigger`.
- `disposition` — closed enum `hard-fail | advisory` (failure severity only).
- `skips_when_absent` — optional boolean; `true` when the unit has an
  explicit absent-dependency SKIP-or-degrade branch (it emits SKIP/WARNING
  instead of ERROR when its precondition is absent). Orthogonal to
  `disposition`; never conflated.
- `ratchet` — optional boolean flag marking the regression ratchets
  (VERSION-never-regresses, USAGE freshness, the portability baseline).
- `trigger` — when the unit runs: quoted, space-separated, each token in the
  closed enum `pre-commit | post-merge | pr-ci | push-main | nightly |
  manual`. Doctrine for `manual`: every script is trivially manual-runnable,
  so `manual` is recorded only where manual invocation is a documented
  operational mode (the standalone suites, the eval harness, the portability
  audit verb); enforcement rows (validate/test) record their enforcement
  triggers only.
- `purpose` — authored, single-line, work-item-ID-free description of what
  the unit asserts.

Row-granularity conventions the extraction grammar honors:

- Check 15 is ONE row — the live source has a single `=== Check 15` banner;
  its 15a sub-assertion is described in that row's `purpose` (15b/15c are
  retired — the workflow surface is generated, enforced by Check 27 +
  workflow-spec.sh --validate).
- Check 17 is echo-anchored only (it has no `# Check 17:` comment header).
- Check 12 is retired; it must not be resurrected by extraction.
- `scripts/test.sh` wrapper blocks that merely invoke a standalone suite
  share that suite's row via multi-valued triggers (e.g. `windows-smoke`
  runs in the Windows workflow on PR + push-main AND inside `test.sh` on
  ubuntu PR CI) — no duplicate rows.
- New standalone suite scripts and new inline `test.sh` families outside the
  banner grammar are forward-anchor-only — the reverse sweep covers validate
  banners/comments, test files, workflows, and hooks (documented, accepted
  boundary).

`purpose` and `label` are single-line double-quoted strings (no YAML
folding). The parser is `scripts/test-spec.sh`
(`--validate | --list-rules | --list-units [--with-family] | --list-runners |
--list-layers | --list-gates | --list-behaviors | --list-behavior-coverage |
--check-coverage | --seed`), an awk-only reader; it resolves the general
registry `spec/test-spec.md` first, then a root `test-spec.md` fallback, and
this overlay next to it. `--validate` additionally lints every `label` +
`purpose` for the work-item-ID pattern (and every behavior's `statement` +
`purpose`), so an ID slip fails at the registry.

### The `gates:` array (per-mode pipeline-gate rows)

A `gates[]` entry declares one pipeline-gate halt:

- `id` — stable slug, unique across the `gates:` array, `[a-z0-9-]+`.
- `layer` — always `pipeline-gate` (the closed value; this array's whole point
  is the layer the `units:` enum cannot hold).
- `order` — the canonical run order; a mode runs its subset of gates in this
  order.
- `markers` — a **per-mode map** keyed by `feature | defect | task | todo`. A
  mode absent from the map does not run that gate. A map value is either a
  literal `"[marker]"` (validate.sh Check 24's advisory marker-drift
  cross-check greps for it in that mode's `skills/CJ_goal_<mode>/{pipeline,SKILL}.md`)
  OR `{ enforced_by: subagent | auq }` (the gate runs but emits no bracket
  marker, so the cross-check records it without grepping — the escape hatch
  that keeps the baseline honestly clean).
- `disposition` — closed enum `hard-fail | advisory | mixed | halt`.
- `backing` — free text: the live enforcement point.
- `checks` — free text: what the gate proves.

### The `behaviors:` and `behavior_coverage:` arrays (the behavior-coverage axis)

Two more overlay-only arrays (optional-on-schema-1; the general file's machine
block is unchanged) declare **what this repo's software must be proven to do**,
orthogonal to the `units:` mechanism inventory. They dogfood the axis on
`test-spec` itself.

A `behaviors[]` entry declares one required behavior:

- `id` — stable slug, unique across the merged registry, `[a-z0-9-]+`.
- `statement` — a one-line required behavior, specific enough to fail.
  **Work-item-ID-free** (the rendered-field lint covers `statement` + `purpose`).
- `level` — the closed enum `unit | integration | contract | workflow |
  property`; lives on the obligation, not the mechanism.
- `area` — optional free-text bucket; PARSED-AND-IGNORED in v1 (no check or
  consumer reads it; per-`area` reporting is the deferred Approach B).
- `purpose` — optional, single-line, work-item-ID-free.

A `behavior_coverage[]` entry is a many-to-many link (no `id`; rows key on
`- behavior:`, the first field):

- `behavior` — a `behaviors[].id`; must resolve to exactly one behavior.
- `unit` — a `units[].id` whose `family` is test-bearing (`test | test-deploy |
  eval | windows-smoke`); `validate | ci | hook` proofs are rejected.
- `source` — the repo-relative file carrying the semantic evidence (the
  behavior named in the test/spec text — not merely the runner path).
- `anchor` — a literal grep string locating that evidence; matched LIVE via
  fixed-string `grep -F` (NOT the family-shaped `_fwd_match` dispatcher). No
  double quotes or tabs (parser constraint).

`test-spec.sh --check-coverage` mechanizes the structure (links resolve, anchors
grep live, every behavior has ≥1 cover) when `behaviors:` rows exist; a
no-behaviors repo reports "behavior coverage inactive" and stays green.
**Deterministic checks verify structure, not completeness** — whether the
linked test *actually proves* the behavior (vs mentions it), whether the `level`
is right, and whether one broad test over-claims many behaviors is the
agent-judged `/CJ_test_audit` Stage-2 sub-check's job (findings prefixed
`stage2/behavior:<id>`).

### The `runners:` array (the execution axis)

Where `units:`/`behaviors:` model WHAT the repo verifies, the `runners:` array
(F000072, overlay-only + optional-on-schema-1) declares **HOW to run it** — the
contract becomes executable. `scripts/test-run.sh` reads it (via
`test-spec.sh --list-runners`) to plan and run the repo's tests and write a
`.md` report + `.json` ledger; `test-spec.sh --validate` enforces its grammar.

A `runners[]` entry declares one runnable command:

- `id` — stable slug, unique across the `runners:` array, `[a-z0-9-]+`.
- `command` — a non-empty shell string run ONCE per selected runner (`bash
  scripts/test.sh`, `npm test`, `make check` — whatever the repo uses).
- `tier` — the closed cost enum `free | paid | local-only`. Default execution
  runs only `free`; `--evals` adds `paid`, `--e2e` adds `local-only`, `--all`
  everything. This is the hard UX law — a default run never surprise-spends.
- `covers` — a non-empty list of the RUNNABLE families `{validate, test,
  test-deploy, eval, windows-smoke}` OR the literal `all`. "Runnable" is defined
  HERE explicitly — it is deliberately NOT the contract's existing "test-bearing"
  set (which excludes `validate`), to avoid overloading the term. An explicit
  `ci` or `hook` is REJECTED by `--validate`: those families are
  **runner-less-by-design** (`ci` runs on GitHub; `hook` is verified installed),
  and appear in the ledger as family-level rows (`ci-only`; `hook-check:
  pass|fail`) OUTSIDE the `skipped(<reason>)` enum.
- `platform` — optional, closed enum `any | windows | posix` (default `any`); a
  runner whose platform does not match the host is `skipped(platform)`.
- `note` — optional free text.

The axis is **registry-gated** like `behaviors:` — its absence changes no
existing behavior. A declared registry with zero `runners:` rows is an honest
`SKIP: no runners declared` (no report, no ledger, no inference). The workbench
dogfoods three rows: `run-test-sh` (free; the full suite covering
validate+test+test-deploy+windows-smoke as ONE row), `run-eval` (paid), and
`run-e2e-local` (local-only).

### The `defect_coverage:` array (the defect↔proof ledger)

One more overlay-only array (optional-on-schema-1; placed LAST in the machine
block) answers a question none of the other axes can: **"is defect X still
protected, and by what?"** One row per defect work-item dir under
`work-items/defects/`, each naming its live proof — so proof is declared, not
folklore, and a hallucinated citation is structurally impossible (every row is
re-verified by the engine on every run).

A `defect_coverage[]` entry (rows key on `- defect:`, the first field):

- `defect` — the **full dir path relative to `work-items/defects/`** (e.g.
  `ops/ship/D000008_<slug>`). Full paths, never bare D-IDs — the repo carries a
  genuinely duplicated bare ID across two component dirs. Unique across the
  ledger (duplicate keys are a `--validate` error).
- `disposition` — the closed enum `covered-by | covered-by-anchor | waived`:
  - **`covered-by`** + `test:` — a dedicated, runnable-by-name regression test:
    `test` names a `categories:` row, which MUST be `mode: deterministic` (an
    agentic proof is an engine FINDING — the deterministic-only ledger rule,
    so a future agentic-test purge can never orphan defect coverage).
  - **`covered-by-anchor`** + `source:`/`anchor:` — the proof lives inside a
    shared file (a `scripts/test.sh` inline banner, a shared suite's named
    case, `scripts/test-deploy.sh`, a `scripts/validate.sh` check): the
    `anchor` must grep LIVE in `source` (fixed-string `grep -F`, the
    `behavior_coverage` idiom).
  - **`waived`** + `reason:` — no automatable proof: a process/doc-only defect,
    a retired surface, or a coverage GAP. A gap waiver is
    `reason: "gap — <what a drill would prove>"` plus an optional `todo:`
    pointing at its TODOS.md follow-up row — gaps stay enumerable and never
    block the ledger.

`test-spec.sh --check-defect-coverage` mechanizes the ledger (surfaced by
`validate.sh` Check 32 + `/CJ_test_audit` Stage 1): **forward**, every
`work-items/defects/**/D??????_*` dir has exactly one row; **reverse**, every
row's dir exists and its disposition-specific proof is live (covered-by resolves
deterministic; covered-by-anchor greps; waived has a non-empty reason). Absent
registry / no `defect_coverage:` axis / no `work-items/defects/` dir ⇒ the named
`defect coverage inactive — <reason>` skip (exit 0), so a consumer repo passes
vacuously. This file is an OPERATIONAL doc, so ledger fields may carry work-item
IDs (nothing here renders into a human-doc).

## Machine registry (overlay)

```yaml
# test-spec custom overlay (units + gates + behaviors + behavior_coverage merged
# into spec/test-spec.md by scripts/test-spec.sh; consumed by validate.sh
# Check 24 --check-coverage + the advisory per-mode marker-drift cross-check)
schema_version: 1
units:
  # ---- validate family: scripts/validate.sh error checks (comment-anchored) ----
  - id: validate-error-check-1
    family: validate
    label: "Error check 1 — catalog entries have SKILL.md on disk"
    anchor: "# Error check 1:"
    source: scripts/validate.sh
    layer: CI-push
    disposition: hard-fail
    trigger: "pre-commit pr-ci"
    purpose: "Every catalog entry's declared SKILL.md exists on disk; templates-only entries are exempt."
  - id: validate-error-check-2
    family: validate
    label: "Error check 2 — SKILL.md frontmatter required fields"
    anchor: "# Error check 2:"
    source: scripts/validate.sh
    layer: CI-push
    disposition: hard-fail
    trigger: "pre-commit pr-ci"
    purpose: "Every SKILL.md carries name and description in its YAML frontmatter."
  - id: validate-error-check-3
    family: validate
    label: "Error check 3 — declared templates exist on disk"
    anchor: "# Error check 3:"
    source: scripts/validate.sh
    layer: CI-push
    disposition: hard-fail
    trigger: "pre-commit pr-ci"
    purpose: "Every catalog templates entry resolves to a file on disk, honoring per-skill source overrides."
  - id: validate-error-check-4
    family: validate
    label: "Error check 4 — no orphan skill directories"
    anchor: "# Error check 4:"
    source: scripts/validate.sh
    layer: CI-push
    disposition: hard-fail
    trigger: "pre-commit pr-ci"
    purpose: "Every skill directory on disk (active or lifecycle-relocated) is claimed by a catalog entry."
  - id: validate-error-check-5
    family: validate
    label: "Error check 5 — doc triplets complete with type frontmatter"
    anchor: "# Error check 5:"
    source: scripts/validate.sh
    layer: CI-push
    disposition: hard-fail
    trigger: "pre-commit pr-ci"
    purpose: "Any per-skill doc directory carries all three design docs, each with type frontmatter."
  - id: validate-error-check-6
    family: validate
    label: "Error check 6 — skill dependencies resolve"
    anchor: "# Error check 6:"
    source: scripts/validate.sh
    layer: CI-push
    disposition: hard-fail
    trigger: "pre-commit pr-ci"
    purpose: "Every declared skill dependency names another catalog entry."
  - id: validate-error-check-7
    family: validate
    label: "Error check 7 — VERSION file valid semver"
    anchor: "# Error check 7:"
    source: scripts/validate.sh
    layer: CI-push
    disposition: hard-fail
    trigger: "pre-commit pr-ci"
    purpose: "The VERSION file exists and parses as semver."
  - id: validate-error-check-8
    family: validate
    label: "Error check 8 — VERSION never regresses"
    anchor: "# Error check 8:"
    source: scripts/validate.sh
    layer: CI-push
    disposition: hard-fail
    ratchet: true
    trigger: "pre-commit pr-ci"
    purpose: "VERSION is at least the latest collection v-tag; a version regression fails the build (ratchet)."
  - id: validate-error-check-9
    family: validate
    label: "Error check 9 — catalog skill versions valid semver"
    anchor: "# Error check 9:"
    source: scripts/validate.sh
    layer: CI-push
    disposition: hard-fail
    trigger: "pre-commit pr-ci"
    purpose: "Every catalog entry's version field parses as semver."
  - id: validate-error-check-9b
    family: validate
    label: "Error check 9b — catalog status closed enum"
    anchor: "# Error check 9b:"
    source: scripts/validate.sh
    layer: CI-push
    disposition: hard-fail
    trigger: "pre-commit pr-ci"
    purpose: "Every catalog status is one of active, experimental or deprecated; typos fail loudly."
  - id: validate-error-check-10
    family: validate
    label: "Error check 10 — Copilot bundle file existence"
    anchor: "# Error check 10:"
    source: scripts/validate.sh
    layer: CI-push
    disposition: hard-fail
    trigger: "pre-commit pr-ci"
    purpose: "Every required Copilot bundle file in the expected-files array is present on disk."
  - id: validate-error-check-11
    family: validate
    label: "Error check 11 — manifest reconciliation"
    anchor: "# Error check 11:"
    source: scripts/validate.sh
    layer: CI-push
    disposition: hard-fail
    trigger: "pre-commit pr-ci"
    purpose: "Work-item dirs and valid fixtures carry every artifact their manifest requires for their tracker type."
  # ---- validate family: warning checks (comment-anchored, advisory) ----
  - id: validate-warning-orphan-doc-dirs
    family: validate
    label: "Warning check — orphan doc directories"
    anchor: "# Warning check: Orphan doc directories"
    source: scripts/validate.sh
    layer: CI-push
    disposition: advisory
    trigger: "pre-commit pr-ci"
    purpose: "Flags per-skill doc directories with no matching catalog entry."
  - id: validate-warning-orphan-templates
    family: validate
    label: "Warning check 3 — orphan template files"
    anchor: "# Warning check 3: Orphan template files"
    source: scripts/validate.sh
    layer: CI-push
    disposition: advisory
    trigger: "pre-commit pr-ci"
    purpose: "Flags template files not referenced by any catalog entry, across the default dir and overrides."
  # ---- validate family: numbered checks (banner-anchored) ----
  - id: validate-check-11
    family: validate
    label: "Check 11 — rules deploy health"
    anchor: "=== Check 11:"
    source: scripts/validate.sh
    layer: CI-push
    disposition: hard-fail
    skips_when_absent: true
    trigger: "pre-commit pr-ci"
    purpose: "Every rules file is deployed to the local rules target; warn-degrades when the deploy target is absent."
  - id: validate-check-13
    family: validate
    label: "Check 13 — USAGE.md present with required sections"
    anchor: "=== Check 13:"
    source: scripts/validate.sh
    layer: CI-push
    disposition: hard-fail
    trigger: "pre-commit pr-ci"
    purpose: "Every routable non-deprecated skill has a USAGE.md with the five required section headings."
  - id: validate-check-14
    family: validate
    label: "Check 14 — USAGE.md content freshness"
    anchor: "=== Check 14:"
    source: scripts/validate.sh
    layer: CI-push
    disposition: hard-fail
    skips_when_absent: true
    ratchet: true
    trigger: "pre-commit pr-ci"
    purpose: "USAGE.md's last commit is at least as recent as its sibling SKILL.md's (git timestamps, staged-aware); skips untracked files (ratchet)."
  - id: validate-check-15
    family: validate
    label: "Check 15 — doc registry declared matches on-disk + workflows completeness"
    anchor: "=== Check 15:"
    source: scripts/validate.sh
    layer: CI-push
    disposition: hard-fail
    trigger: "pre-commit pr-ci"
    purpose: "15a: every declared doc exists and every doc under docs/ (RECURSIVE, including the docs/workflows/ subfolder) and spec/ is declared (no orphans). 15b/15c are retired (the workflow surface is generated from spec/workflow-spec.md): the no-vanish guarantee lives in workflow-spec.sh --validate registry-completeness and freshness in Check 27."
  - id: validate-check-16
    family: validate
    label: "Check 16 — doc registry schema"
    anchor: "=== Check 16:"
    source: scripts/validate.sh
    layer: CI-push
    disposition: hard-fail
    skips_when_absent: true
    trigger: "pre-commit pr-ci"
    purpose: "The doc registry parses: one yaml fence, supported schema version, required keys, closed enums; skips when the registry is absent."
  - id: validate-check-17
    family: validate
    label: "Check 17 — root-doc placement allowlist"
    anchor: "=== Check 17:"
    source: scripts/validate.sh
    layer: CI-push
    disposition: hard-fail
    trigger: "pre-commit pr-ci"
    purpose: "Every root markdown doc on disk is a declared registry path, and every declared root doc exists."
  - id: validate-check-18
    family: validate
    label: "Check 18 — skill portability audit"
    anchor: "=== Check 18:"
    source: scripts/validate.sh
    layer: CI-push
    disposition: hard-fail
    skips_when_absent: true
    ratchet: true
    trigger: "pre-commit pr-ci"
    purpose: "Each skill's declared portability matches its actual executed dependencies; the clean zero-findings baseline is the ratchet (strict mode flips findings to errors); skips when the engine is absent."
  - id: validate-check-19
    family: validate
    label: "Check 19 — no work-item refs in human docs"
    anchor: "=== Check 19:"
    source: scripts/validate.sh
    layer: CI-push
    disposition: hard-fail
    skips_when_absent: true
    trigger: "pre-commit pr-ci"
    purpose: "No registry human-doc contains an internal work-item ID; skips when the doc registry is absent."
  - id: validate-check-21
    family: validate
    label: "Check 21 — permission-policy drift"
    anchor: "=== Check 21:"
    source: scripts/validate.sh
    layer: CI-push
    disposition: advisory
    skips_when_absent: true
    trigger: "pre-commit pr-ci"
    purpose: "The permission policy parses, the handoff gate derives its denylist from it, and every goal orchestrator references it; skips when the policy is absent."
  - id: validate-check-24
    family: validate
    label: "Check 24 — test-spec coverage cross-check + gate marker drift"
    anchor: "=== Check 24:"
    source: scripts/validate.sh
    layer: CI-push
    disposition: hard-fail
    skips_when_absent: true
    trigger: "pre-commit pr-ci"
    purpose: "Validates the merged test-spec registry, then cross-checks coverage (forward, every unit anchor matches live in its declared source; reverse, every live validate banner and comment, test file on disk, workflow, and hook resolves to exactly one unit, with a floor of twenty reverse tokens) — hard; then the advisory per-mode gate marker-drift cross-check over the gates array (absorbed from the retired Check 22); skips when the registry is absent."
  - id: validate-check-25
    family: validate
    label: "Check 25 — README in sync with generate-readme.sh"
    anchor: "=== Check 25:"
    source: scripts/validate.sh
    layer: CI-push
    disposition: hard-fail
    skips_when_absent: true
    trigger: "pre-commit pr-ci"
    purpose: "README.md byte-matches the generate-readme.sh stdout, so a stale catalog-derived README cannot pass validation; read-only (the generator writes only to stdout); skips when the generator is absent."
  - id: validate-check-26
    family: validate
    label: "Check 26 — generated test catalog in sync with test-spec.sh --render-docs"
    anchor: "=== Check 26:"
    source: scripts/validate.sh
    layer: CI-push
    disposition: hard-fail
    skips_when_absent: true
    trigger: "pre-commit pr-ci"
    purpose: "The generated test catalog (docs/tests/<family>.md per unit family plus the docs/test-catalog.md index) byte-matches a fresh render from the merged registry, so a stale catalog cannot pass validation; read-only (--check renders only into a temp dir); skips when the engine is absent or no units are declared."
  - id: validate-check-27
    family: validate
    label: "Check 27 — generated workflow surface in sync with workflow-spec.sh --render-docs"
    anchor: "=== Check 27:"
    source: scripts/validate.sh
    layer: CI-push
    disposition: hard-fail
    skips_when_absent: true
    trigger: "pre-commit pr-ci"
    purpose: "The generated workflow surface (the docs/workflow.md index plus the six docs/workflows/<name>.md per-workflow files) byte-matches a fresh render from spec/workflow-spec.md, so a stale workflow doc cannot pass validation; read-only (--check renders only into a temp dir); registry-gated, skips when spec/workflow-spec.md is absent. Replaces the retired shape-only Checks 15b/15c."
  - id: validate-check-28
    family: validate
    label: "Check 28 — every CJ_goal_* orchestrator has a level:workflow behavior (workflow-coverage gate)"
    anchor: "=== Check 28:"
    source: scripts/validate.sh
    layer: CI-push
    disposition: hard-fail
    skips_when_absent: true
    trigger: "pre-commit pr-ci"
    purpose: "The forward+reverse workflow-coverage gate (test-spec.sh --check-workflow-coverage): every declared CJ_goal_* orchestrator (workflow-spec.sh --list-orchestrators) has a level:workflow behavior whose workflow: equals it, and no level:workflow behavior names an undeclared orchestrator, so a documented-but-untested workflow cannot pass validation; runs in plain CI (registry-only, no API); registry-gated, skips when the test-spec engine is absent or no orchestrators are resolvable."
  - id: validate-check-29
    family: validate
    label: "Check 29 — cj_goal E2E sandbox marker absent from the tracked tree"
    anchor: "=== Check 29:"
    source: scripts/validate.sh
    layer: CI-push
    disposition: hard-fail
    trigger: "pre-commit pr-ci"
    purpose: "The marker-absence guard for the build-gate auto-answer seam: git ls-files must never track .cj-e2e-sandbox (the second half of the seam's double guard, CJ_GOAL_E2E_AUTO=1 AND the marker). A committed marker could make the seam live in a real repo with only an env flag; this check hard-fails the moment git tracks it, anywhere in the tree (the gitignored sandbox copy passes cleanly)."
  - id: validate-check-30
    family: validate
    label: "Check 30 — three-layer topic contract (enrolled topics reach all three layers deterministically; agentic advisory)"
    anchor: "=== Check 30:"
    source: scripts/validate.sh
    layer: CI-push
    disposition: hard-fail
    trigger: "pre-commit pr-ci"
    purpose: "The three-layer topic contract: every ENROLLED topic (topic_contracts:, portability / validator / full-suite today) must carry a CI-push + a CI-nightly + a local-hook{deterministic} test, each with its front-door doc; a missing local-hook{agentic} test is an ADVISORY per-topic note, never a finding (agentic proofs run on-demand, not required). Calls test-spec.sh --check-topic-contract; declaration-only, so it is CI-safe (zero model spend — an agentic behavior, where declared, is proven local-only by /CJ_test_run --e2e). Registry-gated: skips when the engine is absent or the contract reports inactive."
  - id: validate-check-31
    family: validate
    label: "Check 31 — topic docs contract (enrolled topics have a dream doc + topic-by-layer subdir)"
    anchor: "=== Check 31:"
    source: scripts/validate.sh
    layer: CI-push
    disposition: hard-fail
    trigger: "pre-commit pr-ci"
    purpose: "The topic docs contract (the doc-legibility companion to Check 30): every ENROLLED topic (topic_contracts:, portability / validator / full-suite today) must have a docs/goals/<topic>.md dream doc AND a docs/tests/topics/<topic>/ subdir — an index that references the dream doc plus a per-layer page for each layer the topic spans. Calls test-spec.sh --check-topic-docs; declaration-only, so it is CI-safe. Registry-gated: skips when the engine is absent or the contract reports inactive."
  - id: validate-check-32
    family: validate
    label: "Check 32 — defect-coverage ledger (every defect dir maps to a live proof row)"
    anchor: "=== Check 32:"
    source: scripts/validate.sh
    layer: CI-push
    disposition: hard-fail
    trigger: "pre-commit pr-ci"
    purpose: "The defect-coverage ledger check: every defect work-item dir under work-items/defects/ maps to exactly one defect_coverage: row (keyed by full dir path), and every row's disposition-specific proof is live — a covered-by resolves to exactly one DETERMINISTIC categories: regression row (an agentic citation is a finding: the deterministic-only ledger rule), a covered-by-anchor greps live in its source, a waived row has a non-empty reason. Calls test-spec.sh --check-defect-coverage. Registry-gated: skips when the engine is absent or the check reports inactive (no registry / no axis / no defects dir — a consumer passes vacuously)."
  # ---- validate family: the portability audit engine (repo-custom test logic) ----
  - id: portability-audit
    family: validate
    label: "portability audit — declared-vs-actual skill dependency lint"
    anchor: "scripts/cj-portability-audit.sh"
    source: scripts/validate.sh
    layer: CI-push
    disposition: advisory
    skips_when_absent: true
    ratchet: true
    trigger: "pre-commit pr-ci manual"
    purpose: "The portability engine behind validate.sh Check 18: each skill's declared portability matches its actual executed dependencies; the clean baseline is the ratchet. (The former standalone /CJ_portability-audit verb was retired; the engine + Check 18 stay.)"
  # ---- test family: registered tests/*.test.sh sub-suites ----
  # (source MUST be scripts/test.sh and anchor MUST be the literal runner path —
  #  the forward check proves the file is wired into the hand-wired runner.)
  - id: test-cj-worktree-init
    family: test
    label: "cj-worktree-init suite — worktree creation helper"
    anchor: "tests/cj-worktree-init.test.sh"
    source: scripts/test.sh
    layer: CI-push
    disposition: hard-fail
    trigger: "pr-ci"
    purpose: "Caller prefixes, dirty-checkout guard and base-freshness fork behavior of the worktree-init helper."
  - id: test-cj-worktree-cleanup
    family: test
    label: "cj-worktree-cleanup suite — post-run worktree janitor"
    anchor: "tests/cj-worktree-cleanup.test.sh"
    source: scripts/test.sh
    layer: CI-push
    disposition: hard-fail
    trigger: "pr-ci"
    purpose: "PR-state-gated sweep, orphan-dir removal, guard refusals and pipeline seams of the worktree janitor."
  - id: test-cj-task-scaffold
    family: test
    label: "cj-task-scaffold suite — task complexity gate + scaffold"
    anchor: "tests/cj-task-scaffold.test.sh"
    source: scripts/test.sh
    layer: CI-push
    disposition: hard-fail
    trigger: "pr-ci"
    purpose: "Complexity-gate refusals, dry-run preview, live scaffold and idempotency of the task scaffolder."
  - id: test-cj-e2e-gate
    family: test
    label: "cj-e2e-gate suite — build-gate auto-answer seam verdict matrix"
    anchor: "tests/cj-e2e-gate.test.sh"
    source: scripts/test.sh
    layer: CI-push
    disposition: hard-fail
    trigger: "pr-ci"
    purpose: "The full verdict matrix of the build-gate auto-answer seam helper (scripts/cj-e2e-gate.sh): flag-only and marker-only both inactive, both-guards + green qa-audit continues, both-guards + findings/empty qa-audit halts (never auto-waive), a non-allowlisted gate id stays inactive, design-gate auto-approves — all deterministic, no Claude."
  - id: test-audit-nightly
    family: test
    label: "audit-nightly suite — doc/test audit runner deterministic half"
    anchor: "tests/audit-nightly.test.sh"
    source: scripts/test.sh
    layer: CI-push
    disposition: hard-fail
    trigger: "pr-ci"
    purpose: "The DETERMINISTIC (no-Claude, no-network) half of scripts/audit-nightly.sh — the relocated (now on-demand) agent-judged audit runner: SKIP without a model key, the --dry-run plan, the two-count findings parse + report emission, and the create/update/none-clean GitHub-issue decision — all with claude + gh stubbed on PATH."
  - id: test-doc-sync-workflow
    family: test
    label: "doc-sync workflow front door — audit-nightly dry-run honesty"
    anchor: "tests/workflow/local-hook/doc-sync.test.sh"
    source: scripts/test.sh
    layer: CI-push
    disposition: hard-fail
    trigger: "pr-ci"
    purpose: "The doc-sync workflow category's deterministic front door: audit-nightly --dry-run (the categories row's exact command) either prints its dry-run plan or self-gates with a leading SKIP, never runs a real audit and never spends a model token; the lighter workflow-level assertion coexisting with the audit-nightly suite's stubbed parse/report/issue drills. The first NESTED tests/<category>/<layer>/ file the recursed reverse sweep owns (formerly a green-but-inert orphan invisible to the flat glob)."
  - id: test-e2e-local
    family: test
    label: "e2e-local suite — local happy-path E2E harness deterministic half"
    anchor: "tests/e2e-local.test.sh"
    source: scripts/test.sh
    layer: CI-push
    disposition: hard-fail
    trigger: "pr-ci"
    purpose: "The DETERMINISTIC (no-Claude) half of the local-E2E harness (scripts/e2e-local.sh + tests/e2e-local/lib/{sandbox,report}.sh): the SKIP path when CJ_E2E_LOCAL is unset OR a prerequisite is absent (exit 0, never reaches claude), the sandbox provision/teardown (a mktemp clone + a .cj-e2e-sandbox marker + a LOCAL bare origin that defeats gh pr create), the materialized report generator on synthetic evidence (DETERMINISTIC-vs-claude-print rows, a json sibling, and a missing-evidence row rendering `unverified` never a false pass), the gitignore posture (reports/ ignored except a tracked EXAMPLE.md), and the auth gate via fake claude stubs (no key + not-logged-in skips; ANTHROPIC_API_KEY takes the api-key path with no probe; a logged-in-but-probe-401 skips rather than false-pass; a logged-in + probe-ok takes the claude-login path). The REAL /CJ_goal_task run is a LOCAL manual E2E, not asserted here."
  - id: test-test-run
    family: test
    label: "test-run suite — runners: axis grammar + test-run.sh engine (fixture repos)"
    anchor: "tests/test-run.test.sh"
    source: scripts/test.sh
    layer: CI-push
    disposition: hard-fail
    trigger: "pr-ci"
    purpose: "The runners: axis + scripts/test-run.sh engine against TEMP-DIR fixture registries (never the real test.sh — a recursion trap): --validate accepts a well-formed runners: axis and rejects each violation (duplicate id, bad tier/platform, empty command, unknown covers family, explicit ci/hook in covers); --list-runners + --list-units --with-family emit the machine-readable forms; the --dry-run plan prints per-runner decisions + uncovered-family/ci-only/hook lines; tier gating (free default; --evals/--e2e/--all widen; unselected = tier-not-selected); the platform guard; rc->outcome mapping with aggregate {pass, fail, all-skipped} (fail => exit 1, all-skipped NEVER pass); self-gate detection (first-line ^SKIP: only); ledger fields (schema 1, timestamp, HEAD sha, repo root, flags, aggregate, per-runner + ci/hook family rows); the absent/invalid/zero-runners edge paths (no report on the last two); and covers: all expansion. ALSO the additive category-mode selection: --category <workflow|CI> + single-test-NAME runs reusing the docs/tests name, tier-gated (paid/local-only skip on the default free tier), --category+name mutual-exclusion + unknown-name exit 2, the mode: category ledger, additivity of the runners: flow when neither --category nor a name is passed, and the inactive-when-no-categories note."
  - id: test-setup-hooks
    family: test
    label: "setup-hooks suite — git hook installer"
    anchor: "tests/setup-hooks.test.sh"
    source: scripts/test.sh
    layer: CI-push
    disposition: hard-fail
    trigger: "pr-ci"
    purpose: "The installed post-merge hook re-deploys skills without mutating trackers; hook install is clobber-safe."
  - id: test-drain-one-todo-worktree-resolve
    family: test
    label: "drain-one-todo suite — deployed-path resolution"
    anchor: "tests/regression/CI-push/drain-one-todo-worktree-resolve.test.sh"
    source: scripts/test.sh
    layer: CI-push
    disposition: hard-fail
    trigger: "pr-ci"
    purpose: "A deployed drain helper resolves the worktree-init helper via the manifest source path."
  - id: test-drain-one-todo-helper-unavailable
    family: test
    label: "drain-one-todo suite — unreachable-helper fail-loud"
    anchor: "tests/regression/CI-push/drain-one-todo-helper-unavailable.test.sh"
    source: scripts/test.sh
    layer: CI-push
    disposition: hard-fail
    trigger: "pr-ci"
    purpose: "The drain halts loudly when the worktree helper is unreachable instead of scaffolding in place."
  - id: test-cj-document-release
    family: test
    label: "cj-document-release suite — doc-release skill structure"
    anchor: "tests/cj-document-release.test.sh"
    source: scripts/test.sh
    layer: CI-push
    disposition: hard-fail
    trigger: "pr-ci"
    purpose: "Doc-release skill structure, frontmatter, halt markers and config-helper assertions."
  - id: test-cj-document-release-config
    family: test
    label: "doc-release config suite — doc registry + helper + seed"
    anchor: "tests/cj-document-release-config.test.sh"
    source: scripts/test.sh
    layer: CI-push
    disposition: hard-fail
    trigger: "pr-ci"
    purpose: "Doc registry table shape, every doc-spec helper subcommand, strict no-config gates (malformed table row, no-table registry), and the byte-identical embedded seed."
  - id: test-cj-goal-doc-sync-wiring
    family: test
    label: "goal doc-sync wiring suite — symmetric step wiring"
    anchor: "tests/cj-goal-doc-sync-wiring.test.sh"
    source: scripts/test.sh
    layer: CI-push
    disposition: hard-fail
    trigger: "pr-ci"
    purpose: "The doc-sync step and halt-taxonomy rows are present and correctly ordered in the goal orchestrators."
  - id: test-cj-goal-pr-body-splice-guard
    family: test
    label: "goal PR-body splice guard suite — no multi-line awk -v payload idiom"
    anchor: "tests/cj-goal-pr-body-splice-guard.test.sh"
    source: scripts/test.sh
    layer: CI-push
    disposition: hard-fail
    trigger: "pr-ci"
    purpose: "No executable line in any of the four cj_goal pipeline.md passes a multi-line shell payload through awk -v; only the safe --body-file filename idiom and the warning comments remain, and each file keeps its gh pr edit --body-file splice."
  - id: test-cj-goal-jq-crlf
    family: test
    label: "goal jq-CRLF drill — CR-stripping jq() wrapper in the 5 orchestrator helpers"
    anchor: "tests/regression/CI-push/cj-goal-jq-crlf.test.sh"
    source: scripts/test.sh
    layer: CI-push
    disposition: hard-fail
    trigger: "pr-ci"
    purpose: "The CR-stripping jq() wrapper (mirrors lib.sh:24) is present in cj-goal-common.sh, cj-worktree-init.sh, cj-worktree-cleanup.sh, check-version-queue.sh and check-gates-update.sh, and under a CRLF-emitting jq shim it strips CR from jq output and preserves jq's non-zero exit status without pipefail — so a Windows jq's CRLF cannot re-taint the orchestrator helpers (breaking the src directory guard and silently skipping the sync/pr-check phases)."
  - id: test-post-land-sync
    family: test
    label: "post-land-sync suite — post-merge local sync helper"
    anchor: "tests/post-land-sync.test.sh"
    source: scripts/test.sh
    layer: CI-push
    disposition: hard-fail
    trigger: "pr-ci"
    purpose: "Sync-helper guards refuse a bad source checkout; dry-run previews without mutating the live home."
  - id: test-tag-release
    family: test
    label: "tag-release suite — post-land v<VERSION> tag publish (the inert-notification fix)"
    anchor: "tests/regression/CI-push/tag-release.test.sh"
    source: scripts/test.sh
    layer: CI-push
    disposition: hard-fail
    trigger: "pr-ci"
    purpose: "scripts/tag-release.sh publishes the v<VERSION> release tag to origin at LAND (called fail-soft from post-land-sync.sh) so scripts/skills-update-check's `git ls-remote --tags` read can see the newest release — the regression that guards the previously-inert version-notification, where the land flow bumped VERSION but never tagged so origin's newest tag stayed v1.1.0 forever. Hermetic: a local `git init --bare` fake origin (no network), asserting the tag is created + pushed, idempotent on re-run, --version override, non-semver → exit 1, and the --strict-fails / default-fail-softs push-failure split."
  - id: test-cj-goal-common-sync
    family: test
    label: "goal-common sync suite — pre-build skills-sync phase"
    anchor: "tests/cj-goal-common-sync.test.sh"
    source: scripts/test.sh
    layer: CI-push
    disposition: hard-fail
    trigger: "pr-ci"
    purpose: "Dry-run, opt-out, guard-refusal and real-run paths of the pre-build sync phase all emit the four-key schema, fail-soft and hermetic."
  - id: test-cj-goal-common-recap
    family: test
    label: "goal-common recap suite — land/PR 3-part recap formatter"
    anchor: "tests/cj-goal-common-recap.test.sh"
    source: scripts/test.sh
    layer: CI-push
    disposition: hard-fail
    trigger: "pr-ci"
    purpose: "The --phase recap pure formatter renders all three labelled sections, switches the header on --when before|after, is fail-soft on a missing field, and prints --field content verbatim (no eval)."
  - id: test-cj-id-claim
    family: test
    label: "cj-id-claim suite — atomic work-item ID claim"
    anchor: "tests/cj-id-claim.test.sh"
    source: scripts/test.sh
    layer: CI-push
    disposition: hard-fail
    trigger: "pr-ci"
    purpose: "Concurrent-race uniqueness, both reap modes, prefix isolation, same-branch reuse, worktree-shared claim-root resolution, and the slug-less feature-tracker reap regression (a merged `${id}_TRACKER.md` with no slug is reaped on both the id_on_origin regex and id_has_workitem_dir find-glob paths)."
  - id: test-cj-goal-feature-smoke
    family: test
    label: "feature-path smoke suite — worktree entry + common phases"
    anchor: "tests/cj-goal-feature-smoke.test.sh"
    source: scripts/test.sh
    layer: CI-push
    disposition: hard-fail
    trigger: "pr-ci"
    purpose: "Feature-caller worktree entry, the shared helper's worktree/ship/telemetry phases, and leaf dispatch targets present on disk."
  - id: test-doc-spec-overlay
    family: test
    label: "doc-spec overlay suite — two-tier merge semantics"
    anchor: "tests/doc-spec-overlay.test.sh"
    source: scripts/test.sh
    layer: CI-push
    disposition: hard-fail
    trigger: "pr-ci"
    purpose: "Overlay merge semantics, the duplicate-path guard, merged list subcommands, seed-equals-general-file byte identity, and the --check-on-disk Stage-1 battery (clean fixture: five checks PASS / CHECKS_RUN=5; seeded violations each isolated to its own stage1/<id> finding, including the docs/workflows/ recursed orphan and the registry-gated workflows-subfolder mandate; registry-absent REGISTRY=absent skip; invalid-registry halt)."
  - id: test-test-spec
    family: test
    label: "test-spec suite — two-tier registry parser + coverage drills"
    anchor: "tests/test-spec.test.sh"
    source: scripts/test.sh
    layer: CI-push
    disposition: hard-fail
    trigger: "pr-ci"
    purpose: "Merged-registry parser round-trip, the absent-vs-invalid split, malformed fixtures, the units-gated floor note, seed emission, and the temp-dir coverage drift drills. ALSO the additive category axis (Section 10): --list-categories (+ --names/--category filters) with pre-existing-subcommand additivity, --seed carrying the category prose, --check-structure's five a-e checks (findings-not-crash; folders derived from the distinct declared categories) + --seed-docs idempotency + stale-INDEX refresh + inactive-when-no-axis, and the closed {workflow, CI-push, CI-nightly} V2 category-enum HALT."
  - id: test-cj-audit-skills
    family: test
    label: "audit-skills suite — seed delivery + audit engines"
    anchor: "tests/cj-audit-skills.test.sh"
    source: scripts/test.sh
    layer: CI-push
    disposition: hard-fail
    trigger: "pr-ci"
    purpose: "Bare-repo seed delivery for both audit skills, second-run idempotence, engine-flagged seeded-violation findings (stage1/ prefixes), the per-stage report contract on both SKILL.mds plus qa.md's block template, the planted-drift stage3 cross-walk drill, and the clean workbench baseline."
  - id: test-doc-spec-reconcile
    family: test
    label: "doc-spec reconcile suite — classify + legacy->canonical migration"
    anchor: "tests/doc-spec-reconcile.test.sh"
    source: scripts/test.sh
    layer: CI-push
    disposition: hard-fail
    trigger: "pr-ci"
    purpose: "doc-spec.sh --classify labeling the four generations (absent/canonical/legacy/duplicate, plus malformed-not-legacy), --reconcile migrating a 40+-row legacy YAML fixture to the canonical Markdown table preserving every row (atomic + .bak + idempotent), the audit_class asymmetry guard (RECONCILE-WARN), the malformed-file no-clobber halt, and the live-workbench canonical-no-reconcile-noise baseline."
  - id: test-test-spec-reconcile
    family: test
    label: "test-spec reconcile suite — symmetric classify + dedup/no-op"
    anchor: "tests/test-spec-reconcile.test.sh"
    source: scripts/test.sh
    layer: CI-push
    disposition: hard-fail
    trigger: "pr-ci"
    purpose: "test-spec.sh --classify labeling absent/canonical/duplicate/malformed (never legacy — the fenced-yaml format never diverged), --reconcile as a dedup/no-op (canonical clean no-op, duplicate reports the redundant copy with no auto-delete, malformed halts), and the live-workbench canonical-no-reconcile-noise baseline."
  - id: test-test-spec-render
    family: test
    label: "test-spec render suite — generated catalog renderer + freshness primitive"
    anchor: "tests/test-spec-render.test.sh"
    source: scripts/test.sh
    layer: CI-push
    disposition: hard-fail
    trigger: "pr-ci"
    purpose: "The --render-docs renderer emits a deterministic (render-twice byte-identical), work-item-ID-free generated test catalog from the merged registry, and --render-docs --check exits zero on a fresh render and non-zero after a hand-edit — the freshness primitive behind validate.sh Check 26."
  - id: test-workflow-spec-render
    family: test
    label: "workflow-spec render suite — generated workflow-docs renderer + freshness primitive + no-vanish drill + CRLF-jq drill"
    anchor: "tests/workflow-spec-render.test.sh"
    source: scripts/test.sh
    layer: CI-push
    disposition: hard-fail
    trigger: "pr-ci"
    purpose: "The --render-docs renderer emits a deterministic (render-twice byte-identical), work-item-ID-free generated workflow surface from spec/workflow-spec.md; --render-docs --check exits zero on a fresh render and non-zero after a hand-edit or a missing file; a remove-an-entry drill proves workflow-spec.sh --validate registry-completeness fails closed (the no-vanish guarantee behind validate.sh Check 27 + the retired Check 15c); and a CRLF-jq drill (a PATH-prepended jq shim appending CR to every output line) proves --list-orchestrators and --validate stay green under a Windows CRLF-emitting jq — no registry-completeness false-halt."
  - id: test-seed-contracts
    family: test
    label: "seed-contracts suite — forced contract seeding + stale-engine probe + data-loss guard"
    anchor: "tests/seed-contracts.test.sh"
    source: scripts/test.sh
    layer: CI-push
    disposition: hard-fail
    trigger: "pr-ci"
    purpose: "skills-deploy seed-contracts force-seeds the three contracts (doc-spec/test-spec/workflow-spec) into a consumer repo corruption-guarded (--seed → non-empty + --validate-clean → mv) and idempotent (present⇒skip); the workbench self-repo is detected (manifest-source match OR custom-overlay presence) and SKIPPED so its authored spec/*.md are never overwritten with skeletons (the data-loss guard); and the stale-engine capability probe detects a vendored repo-local engine lacking --classify, falls back to _cj-shared, and emits stage1/engine-stale (the actual stale-engine-shadow bug fix)."
  - id: test-cj-contract-gate
    family: test
    label: "cj-contract-gate suite — deterministic Stage-1 contract gate + guarded consumer hook install"
    anchor: "tests/cj-contract-gate.test.sh"
    source: scripts/test.sh
    layer: CI-push
    disposition: hard-fail
    trigger: "pr-ci"
    purpose: "scripts/cj-contract-gate.sh (the engine-only Stage-1 subset of validate.sh, agent-free) PASSes on a clean fully-adopted contract and hard-FAILS (exit non-zero) on a planted violation (a stale generated catalog OR a malformed registry); a missing DECLARED doc is a SOFT remediation pointing at /CJ_document-release (exit 0 — never a block) and an unadopted contract (REGISTRY=absent) is a clean SKIP; and the guarded consumer pre-commit auto-install (skills-deploy install-contract-gate, reusing the shared cj-hook-lib.sh install_hook safety) installs a sentinel hook resolving the gate from _cj-shared (idempotent re-run), SKIPS a custom core.hooksPath (husky) and the workbench self-repo, and --remove uninstalls ONLY a sentinel hook while a non-workbench hook is left untouched."
  - id: test-workflow-coverage
    family: test
    label: "workflow-coverage suite — the level:workflow gate + 6th-column parser + --list-orchestrators"
    anchor: "tests/workflow-coverage.test.sh"
    source: scripts/test.sh
    layer: CI-push
    disposition: hard-fail
    trigger: "pr-ci"
    purpose: "test-spec.sh --check-workflow-coverage is green from birth on the live tree and FAILS hermetically on a forward miss (a 5th orchestrator with no level:workflow behavior), a reverse orphan (an undeclared workflow: value via the enum-check, and an empty workflow: field via the gate's own reverse arm), while a consumer-absent registry SKIPs (REGISTRY=absent / inactive + exit 0); the 6th `workflow` behaviors-TSV column round-trips with the `-` placeholder unwrap (positional $1-only consumers unaffected) and --validate enum-checks workflow: ONLY on level:workflow rows against workflow-spec.sh --list-orchestrators; the gate behind validate.sh Check 28."
  - id: test-skills-update-check
    family: test
    label: "skills-update-check suite — checkout-independent git-ls-remote version-notification"
    anchor: "tests/skills-update-check.test.sh"
    source: scripts/test.sh
    layer: CI-push
    disposition: hard-fail
    trigger: "pr-ci"
    purpose: "scripts/skills-update-check reads local = manifest collection_version and remote = the max v<X.Y.Z> tag from a stubbed git ls-remote, emitting the SKILLS_UPGRADE_AVAILABLE banner when remote > local, staying silent when equal/older, and fail-softing silent when the remote is unreachable or has no v-tags — with the .source/.git gate removed (a non-checkout .source no longer suppresses the banner), the ssh→https upstream_url normalization, and the SKILLS_UPDATE_REMOTE_URL / SKILLS_UPDATE_STATE_DIR test seams (hermetic, no real network / no real ~/.claude)."
  - id: test-portability-version-agentic
    family: test
    label: "portability-version-agentic — the local-hook AGENTIC proof of the version-notification (SKIP path in CI)"
    anchor: "tests/portability-version-agentic.test.sh"
    source: scripts/test.sh
    layer: CI-push
    disposition: hard-fail
    trigger: "pr-ci"
    purpose: "The agentic counterpart to skills-update-check.test.sh: portability's local-hook agentic level asserts an AGENT running the update-check preamble in a repo-neutral sandbox (a bare upstream tagged v-newer via SKILLS_UPDATE_REMOTE_URL) SURFACES the SKILLS_UPGRADE_AVAILABLE nudge — the green-but-inert catch the deterministic version-check cannot see. Local-only (tier local-only via the categories: row): it SKIPs cleanly (exit 0, no model spend) without CJ_E2E_LOCAL=1 + a claude login, so in CI / test.sh only the SKIP path runs (the live claude --print path is a local /CJ_test_run --topic portability --e2e run). Registered here so the Check-24 forward grep proves the file is wired."
  - id: test-portability-version-agentic-detail
    family: test
    label: "portability-version-agentic detail — the cold-agent prompt+response surfacing plumbing (hermetic, no model)"
    anchor: "tests/portability-version-agentic-detail.test.sh"
    source: scripts/test.sh
    layer: CI-push
    disposition: hard-fail
    trigger: "pr-ci"
    purpose: "The hermetic regression for the detailed-report plumbing: run_preamble_via_claude's optional 6th prompt-out-path arg writes the EXACT prompt sent to claude byte-identically (proved against a stubbed claude that records its -p value — expose, don't alter) and is a no-op when absent; the portability-version-agentic test emits the delimited AGENTIC-DETAIL BEGIN/END block (prompt + raw response + verdict) only PAST the SKIP gate (the real test still SKIPs clean with no such block when CJ_E2E_LOCAL is unset); and scripts/test-run.sh folds that block into the materialized category report via the marker-keyed _cm_extract_detail passthrough. Spends no model (stubbed claude + source greps)."
  # ---- test family: inline scripts/test.sh families (banner-anchored) ----
  - id: testsh-validate-rerun
    family: test
    label: "Inline — full validator re-run"
    anchor: "=== Running validate.sh ==="
    source: scripts/test.sh
    layer: CI-push
    disposition: hard-fail
    trigger: "pr-ci"
    purpose: "Runs the whole validator inside the test suite so every check gates the test run too."
  - id: testsh-harness-guards
    family: test
    label: "Inline — harness-principle regression guards"
    anchor: "# === F000053/S000093: trajectory-QA regression guards ==="
    source: scripts/test.sh
    layer: CI-push
    disposition: hard-fail
    trigger: "pr-ci"
    purpose: "Static guards that the trajectory-QA, permission-policy and within-phase-receipt fixes stay in place."
  - id: testsh-catalog-smoke
    family: test
    label: "Inline — catalog + frontmatter + doc-triplet smoke"
    anchor: "Checking for duplicate skill names..."
    source: scripts/test.sh
    layer: CI-push
    disposition: hard-fail
    trigger: "pr-ci"
    purpose: "No duplicate skill names; SKILL.md frontmatter parses; doc triplets carry their required sections."
  - id: testsh-advisory-generators
    family: test
    label: "Inline — advisory-script crash + generator idempotency"
    anchor: "Smoke-testing advisory scripts..."
    source: scripts/test.sh
    layer: CI-push
    disposition: hard-fail
    trigger: "pr-ci"
    purpose: "Doctor, lint and deps scripts run without crashing; the README generator is idempotent (temp-only)."
  - id: testsh-skill-creation-integration
    family: test
    label: "Inline — manual skill-creation integration cycle"
    anchor: "Integration test: manual skill creation cycle..."
    source: scripts/test.sh
    layer: CI-push
    disposition: hard-fail
    trigger: "pr-ci"
    purpose: "A scaffolded temp skill keeps the validator green; plant-and-restore negatives prove the doc checks actually fire."
  - id: testsh-goal-common-phases
    family: test
    label: "Inline — goal-common phase integration"
    anchor: "Integration test (F000045 / S000081): --phase sync end-to-end"
    source: scripts/test.sh
    layer: CI-push
    disposition: hard-fail
    trigger: "pr-ci"
    purpose: "Sync and task-worktree phases of the shared goal helper, end-to-end and hermetic."
  - id: testsh-template-content
    family: test
    label: "Inline — template content + validator portability + orphan negatives"
    anchor: "Checking tracker template content..."
    source: scripts/test.sh
    layer: CI-push
    disposition: hard-fail
    trigger: "pr-ci"
    purpose: "Tracker templates carry required sections; the workflow validator stands alone; orphan-directory detection fires."
  - id: testsh-regression-battery
    family: test
    label: "Inline — defect and story regression battery"
    anchor: "Regression test (D000005): Windows jq CRLF wrapper present..."
    source: scripts/test.sh
    layer: CI-push
    disposition: hard-fail
    trigger: "pr-ci"
    purpose: "Shipped defect and story fixes stay fixed: CRLF wrappers, the merge-convention guard, template sync, copy-mode fallback and more."
  - id: testsh-copilot-bundle
    family: test
    label: "Inline — Copilot bundle coverage + round-trip"
    anchor: "Checking S000010 bundle-artifact-completeness coverage..."
    source: scripts/test.sh
    layer: CI-push
    disposition: hard-fail
    trigger: "pr-ci"
    purpose: "Bundle completeness coverage, the instructions size budget and the deploy round-trip."
  - id: testsh-todos-append-guard
    family: test
    label: "Inline — backlog append POSIX-clean guard"
    anchor: "Checking CJ_improve-queue append path keeps TODOS.md POSIX-clean..."
    source: scripts/test.sh
    layer: CI-push
    disposition: hard-fail
    trigger: "pr-ci"
    purpose: "The improve-queue append path keeps the backlog file POSIX-clean."
  - id: testsh-version-queue-smoke
    family: test
    label: "Inline — version-queue preflight smoke"
    anchor: "Smoke-testing scripts/check-version-queue.sh..."
    source: scripts/test.sh
    layer: CI-push
    disposition: hard-fail
    trigger: "pr-ci"
    purpose: "The version-queue preflight runs read-only and degrades cleanly when offline."
  - id: testsh-handoff-gate
    family: test
    label: "Inline — handoff-gate deterministic suite"
    anchor: "=== F000026: scripts/cj-handoff-gate.sh deterministic tests ==="
    source: scripts/test.sh
    layer: CI-push
    disposition: hard-fail
    trigger: "pr-ci"
    purpose: "Denylist hits, size caps, rename/symlink/test-weakening detection and the QA predicate of the deterministic handoff gate."
  - id: testsh-static-wiring
    family: test
    label: "Inline — static wiring checks"
    anchor: "Checking S000078 portable POSIX runtime"
    source: scripts/test.sh
    layer: CI-push
    disposition: hard-fail
    trigger: "pr-ci"
    purpose: "Portable POSIX runtime idioms, registered-doc audit wiring, defect tracker promotion and the workflow-doc Touches blocks."
  - id: testsh-portability-fixture
    family: test
    label: "Inline — portability-engine hermetic fixture"
    anchor: "Integration test (F000047 / S000083): cj-portability-audit.sh engine fixture..."
    source: scripts/test.sh
    layer: CI-push
    disposition: hard-fail
    trigger: "pr-ci"
    purpose: "The portability-audit engine's verdicts against a controlled fixture catalog."
  - id: testsh-install-clone
    family: test
    label: "Inline — install equals clone integration battery"
    anchor: "Integration test (F000049 / S000085): shared-scripts self-containment..."
    source: scripts/test.sh
    layer: CI-push
    disposition: hard-fail
    trigger: "pr-ci"
    purpose: "Shared-script self-containment, bundle install, develop-in-place and the in-place install-equals-clone contract."
  - id: testsh-test-spec-guards
    family: test
    label: "Inline — test-spec registry + coverage guards"
    anchor: "# === F000060: test-spec registry + coverage guards ==="
    source: scripts/test.sh
    layer: CI-push
    disposition: hard-fail
    trigger: "pr-ci"
    purpose: "The test-spec parser validates the merged registry, the coverage cross-check passes on the live tree, and an absent registry classifies as inactive rather than a finding."
  # ---- standalone suites (wrapper blocks in test.sh share these rows) ----
  - id: suite-test-deploy
    family: test-deploy
    label: "skills-deploy suite — install/doctor/remove in isolation"
    anchor: "scripts/test-deploy.sh"
    source: scripts/test.sh
    layer: CI-nightly
    disposition: hard-fail
    trigger: "nightly manual"
    purpose: "Template ownership, drift overwrite, copy-mode fallback, shared-script orphan pruning (manifest-keyed, ownership-safe), and doctor verdicts (incl. the shared-scripts health section) in isolated temp homes; runs inside the test suite (via scripts/test.sh) and by hand. Re-layered to CI-nightly: the per-PR test.sh skips it under TEST_FAST=1, so it now gates via the nightly full-suite (.github/workflows/nightly.yml), NOT per-PR; its standalone Windows run is the nightly windows-nightly.yml (owned by ci-windows-nightly)."
  - id: suite-eval
    family: eval
    label: "behavioral eval harness — headless skill evals"
    anchor: "Behavioral eval harness"
    source: scripts/eval.sh
    layer: local-hook
    disposition: hard-fail
    trigger: "manual"
    purpose: "Spawns the headless CLI against scratch worktrees per eval case with JSON-schema output validation; budget-capped per case and per run. Run on-demand (bash scripts/eval.sh) — no longer on a nightly CI schedule."
  - id: suite-windows-smoke
    family: windows-smoke
    label: "Windows smoke — CRLF + portable date + copy-mode + parity (completeness/fidelity)"
    anchor: "scripts/windows-smoke.sh"
    source: scripts/test.sh
    layer: CI-push
    disposition: hard-fail
    trigger: "pr-ci push-main manual"
    purpose: "Git Bash portability assertions: CRLF tolerance, portable date math, copy-mode install and the in-place install stamp (S1-S4), plus the fast per-PR parity assertions (S5 completeness — a full install lands every catalog skill, count == SKILL_COUNT; S6 fidelity — deployed source_checksums match) that gate 'another machine gets the same skills' on every PR without the slow deploy suite."
  # ---- ci family: GitHub Actions workflows ----
  - id: ci-validate
    family: ci
    label: "validate workflow — PR gate"
    anchor: "name: Validate Skills"
    source: .github/workflows/validate.yml
    layer: CI-push
    disposition: hard-fail
    trigger: "pr-ci"
    purpose: "Runs the validator, the full test suite and shellcheck on every pull request."
  - id: ci-windows
    family: ci
    label: "windows workflow — Git Bash smoke gate"
    anchor: "name: Windows (Git Bash)"
    source: .github/workflows/windows.yml
    layer: CI-push
    disposition: hard-fail
    trigger: "pr-ci push-main"
    purpose: "Runs the fast Windows smoke (windows-smoke.sh) under Git Bash on every pull request and push to main — the CI-push cadence; the slow skills-deploy suite moved to the nightly workflow."
  - id: ci-windows-nightly
    family: ci
    label: "windows-nightly workflow — nightly skills-deploy suite"
    anchor: "name: Windows Nightly (skills-deploy suite)"
    source: .github/workflows/windows-nightly.yml
    layer: CI-nightly
    disposition: hard-fail
    trigger: "nightly manual"
    purpose: "Runs the full skills-deploy suite (test-deploy.sh) on windows-latest under Git Bash on a nightly schedule, with a manual dispatch trigger — the CI-nightly cadence windows-deploy test."
  - id: ci-nightly
    family: ci
    label: "nightly workflow — nightly full test suite"
    anchor: "name: Nightly (full test suite)"
    source: .github/workflows/nightly.yml
    layer: CI-nightly
    disposition: hard-fail
    trigger: "nightly manual"
    purpose: "Runs the FULL scripts/test.sh on ubuntu-latest on a nightly schedule, with a manual dispatch trigger — the safe-additive CI-nightly home for the heavy suite that would slow every PR; mirrors windows-nightly.yml. The per-PR validate.yml is UNTRIMMED (that trim is a deferred follow-up), so the suite still also runs on every PR."
  # (ci-eval-nightly + ci-audit-nightly removed with F000080: the eval-nightly.yml
  # + audit-nightly.yml cron wrappers were deleted; the eval + audit runners
  # (scripts/eval.sh, scripts/audit-nightly.sh) now run on-demand at the local-hook
  # layer, so their CI-nightly workflow units no longer exist.)
  # ---- hook family: git hooks installed by scripts/setup-hooks.sh ----
  - id: hook-pre-commit
    family: hook
    label: "pre-commit hook — validator at commit time"
    anchor: "install_hook pre-commit"
    source: scripts/setup-hooks.sh
    layer: local-hook
    disposition: hard-fail
    trigger: "pre-commit"
    purpose: "Runs the validator before every local commit; a failing check blocks the commit."
  - id: hook-post-merge
    family: hook
    label: "post-merge hook — auto re-deploy"
    anchor: "install_hook post-merge"
    source: scripts/setup-hooks.sh
    layer: local-hook
    disposition: advisory
    trigger: "post-merge"
    purpose: "Re-deploys skills, templates and rules into the local home after pulls that touch them; best-effort, never blocks git."
gates:
  # The per-mode pipeline-gate rows (folded in from the retired gate-spec.md).
  # These are a SEPARATE top-level array, NOT units: rows — the units: `layer`
  # enum is {local-hook, ci} and would reject `pipeline-gate`. Each gate's
  # `markers` is a per-mode map (feature|defect|task|todo); a mode absent from
  # the map does not run that gate. A map value is either a literal "[marker]"
  # (validate.sh Check 24's advisory marker-drift cross-check greps for it in
  # that mode's pipeline files) OR { enforced_by: subagent | auq } (the gate
  # runs but emits no bracket marker, so the cross-check records it without
  # grepping). order = the canonical run order; a mode runs its subset in this
  # order. backing = the live enforcement point; checks = what the gate proves.
  # --- same concept, DIFFERENT marker per mode, absent in todo (todo runs inside the drain worktree) ---
  - id: isolation
    layer: pipeline-gate
    order: 10
    markers:
      feature: "[feature-not-isolated]"
      defect:  "[investigate-not-isolated]"
      task:    "[task-not-isolated]"
      # todo: omitted — todo runs inside the drain worktree, no isolation gate
    disposition: halt
    backing: "cj-worktree-init.sh isolation assertion"
    checks: "the build runs in a clean, isolated worktree (no in-place source write)"
  # --- feature-only: the design-summary approval gate ---
  - id: design-gate
    layer: pipeline-gate
    order: 20
    markers:
      feature: "[design-gate-declined]"
      # defect/task/todo: omitted — no /office-hours design phase
    disposition: halt
    backing: "design-summary approval AUQ (feature pipeline)"
    checks: "the APPROVED design is confirmed before the autonomous build budget is spent"
  # --- defect-only: the investigate Iron-Law gate ---
  - id: root-cause
    layer: pipeline-gate
    order: 25
    markers:
      defect: "[investigate-no-root-cause]"
      # feature/task/todo: omitted — only defect roots a fix in /investigate
    disposition: halt
    backing: "/investigate Iron-Law gate (defect pipeline)"
    checks: "a populated root cause exists before anything is promoted or shipped"
  # --- task-only: the hard complexity gate ---
  - id: complexity
    layer: pipeline-gate
    order: 30
    markers:
      task: "[task-too-complex]"
      # feature/defect/todo: omitted — only task gates on size
    disposition: halt
    backing: "cj-task-scaffold.sh hard complexity gate (task pipeline)"
    checks: "the task is genuinely small (not disguised design or bug work)"
  # --- a gate feature/defect/task run with a literal marker; todo enforces WITHOUT a marker ---
  - id: qa
    layer: pipeline-gate
    order: 40
    markers:
      feature: "[qa-red]"
      defect:  "[qa-red]"
      task:    "[qa-red]"
      todo:    { enforced_by: subagent }   # runs QA, emits no bracket marker
    disposition: halt
    backing: "/CJ_qa-work-item leaf subagent"
    checks: "the work-item's test rows pass"
  # --- universal, same marker in all four: doc-sync folds doc drift into the
  #     same code PR (Step 5.5), just before /ship (F000076 removed the trailing
  #     post-sync audit + qa-audit checkpoint — that audit now runs in CI-nightly) ---
  - id: doc-sync
    layer: pipeline-gate
    order: 45
    markers:
      feature: "[doc-sync-red]"
      defect:  "[doc-sync-red]"
      task:    "[doc-sync-red]"
      todo:    "[doc-sync-red]"
    disposition: halt
    backing: "deterministic doc-regen (Step 5.5 — test-spec.sh + workflow-spec.sh --render-docs)"
    checks: "the generated catalogs are regenerated into the same PR (Check 26/27 stay green); the slow /CJ_document-release LLM pass was replaced by the deterministic regen — the agentic prose/overlay sync defers to the nightly audit"
  # --- feature/defect/task run a ship gate with a literal marker; todo ships via /land-and-deploy ---
  - id: ship
    layer: pipeline-gate
    order: 70
    markers:
      feature: "[ship-declined]"
      defect:  "[ship-declined]"
      task:    "[ship-declined]"
      todo:    { enforced_by: auq }   # /ship Gate #2 fires per drained TODO; no [ship-declined] bracket
    disposition: halt
    backing: "/ship Gate #2 (always human)"
    checks: "the change reaches a human before it merges (PR-stop + human merge)"
behaviors:
  # ---- the behavior-coverage axis, dogfooded on test-spec itself (F000066) ----
  # WHAT the test-spec machinery must be proven to do. Each behavior links to a
  # test-bearing unit (here the `test-spec suite` / `test-spec reconcile suite`
  # rows) via a behavior_coverage row whose anchor greps live in the test file.
  - id: seed-byte-identical
    statement: "The general spec/test-spec.md is byte-identical to test-spec.sh --seed output."
    level: contract
    area: registry-integrity
    purpose: "A drifted seed would break every consumer's self-bootstrap; the suite proves byte identity."
  - id: absent-registry-is-distinct
    statement: "An absent test-spec registry classifies as REGISTRY=absent + exit 0 (a machine-classifiable skip, never a halt)."
    level: contract
    area: consumer-parity
    purpose: "Distinguishes a non-adopting repo from a broken one so callers skip rather than fail."
  - id: present-invalid-registry-halts
    statement: "A present-but-invalid registry fails closed with [test-spec-no-config] and a non-zero exit."
    level: contract
    area: registry-integrity
    purpose: "A malformed registry must halt loudly, never silently degrade to a vacuous pass."
  - id: overlay-merge-produces-one-registry
    statement: "The general rules + the custom units overlay merge into one registry with unique ids across both tiers."
    level: integration
    area: two-tier-merge
    purpose: "Consumers see ONE registry; a duplicate id across tiers is a guarded error."
  - id: coverage-inactive-without-units
    statement: "A rules-only registry (no units: rows) reports coverage cross-check inactive and stays green — no fabricated findings."
    level: contract
    area: consumer-parity
    purpose: "A seeded consumer with no overlay must not see invented extraction-grammar findings."
  - id: forward-anchor-drift-detected
    statement: "A units: row whose anchor no longer greps live in its declared source is flagged by the forward check, naming the row and its source."
    level: unit
    area: coverage-cross-check
    purpose: "A removed/renamed check or a de-wired test file orphans its row and is caught forward."
  - id: reverse-orphan-test-surface-detected
    statement: "A tests/*.test.sh file on disk with no registry row is flagged by the reverse sweep (single-owner)."
    level: unit
    area: coverage-cross-check
    purpose: "An unregistered test file silently never runs; the reverse sweep makes it a hard finding."
  - id: reverse-floor-prevents-vacuous-pass
    statement: "An absurd TEST_SPEC_REVERSE_FLOOR makes the otherwise-clean reverse sweep fail loudly, proving the floor assert is alive and overridable."
    level: property
    area: coverage-cross-check
    purpose: "Grammar rot can never make the reverse sweep vacuously pass while the token floor holds."
  # ---- the workflow-coverage axis: one level:workflow behavior per CJ_goal_*
  # orchestrator (F000070). Each carries the 6th `workflow:` forward-link naming
  # the orchestrator it proves, and links (below) to a REAL Claude-driven eval
  # case under tests/eval/<skill>/<case>/ via the suite-eval unit. The eval cases
  # target gstack-INDEPENDENT paths (task → hard complexity-gate halt; feature /
  # defect → --dry-run preview), so the workflow genuinely RUNS up to a decision
  # without reaching /office-hours or /ship. The forward/reverse gate
  # (test-spec.sh --check-workflow-coverage) makes a documented-but-untested
  # orchestrator structurally impossible.
  - id: workflow-cj-goal-task-runs
    statement: "Running /CJ_goal_task on a design-rework topic via claude --print drives the workflow through its preamble + isolation + hard complexity gate and emits halt_class halted_at_too_complex with the /CJ_goal_feature routing suggestion (schema-validated by the eval harness)."
    level: workflow
    workflow: CJ_goal_task
    area: workflow-coverage
    purpose: "A documented-but-unrun orchestrator is the gap this axis catches; the eval case is a real Claude-driven run of /CJ_goal_task up to a gstack-independent decision (the full happy-path-to-PR E2E is deferred on the gstack-in-CI blocker)."
  - id: workflow-cj-goal-feature-runs
    statement: "Running /CJ_goal_feature --dry-run on a topic via claude --print drives the workflow through its preamble + dry-run chain-plan preview and emits end_state dry_run_preview without reaching any gstack skill (schema-validated by the eval harness)."
    level: workflow
    workflow: CJ_goal_feature
    area: workflow-coverage
    purpose: "Proves /CJ_goal_feature actually runs to its dry-run preview on the clean gstack-independent path; a richer pre-gstack halt is a deferred upgrade of this same behavior."
  - id: workflow-cj-goal-defect-runs
    statement: "Running /CJ_goal_defect --dry-run on a bug description via claude --print drives the workflow through its preamble + dry-run chain-plan + write-path preview and emits end_state dry_run_preview without reaching any gstack skill (schema-validated by the eval harness)."
    level: workflow
    workflow: CJ_goal_defect
    area: workflow-coverage
    purpose: "Proves /CJ_goal_defect actually runs to its dry-run preview on the clean gstack-independent path; the full /investigate-to-ship E2E is a deferred upgrade of this same behavior."
  - id: workflow-cj-goal-todo-fix-runs
    statement: "Running /CJ_goal_todo_fix against a size-L TODO via claude --print drives the workflow through its preamble + pre-flight gates and emits a halt class at the size cap before any gstack skill (schema-validated by the eval harness)."
    level: workflow
    workflow: CJ_goal_todo_fix
    area: workflow-coverage
    purpose: "Reuses the existing CJ_goal_todo_fix preflight-halt eval case as the real Claude-driven run proving the orchestrator runs up to a gstack-independent decision."
  # ---- the doc-sync workflow-category test's backing behavior (F000078). NOTE:
  # this is level: integration, NOT level: workflow — Check 28 governs ONLY
  # orchestrator <-> level:workflow, and /CJ_doc_audit is not a CJ_goal_*
  # orchestrator, so a level:workflow behavior here would FAIL Check 28's reverse
  # arm. The category=workflow <-> behavior link stays convention-only this
  # increment (the deferred enforcement gate wires it). ----
  - id: workflow-doc-audit-runs
    statement: "The doc/test-drift audit workflow (/CJ_doc_audit + /CJ_test_audit, driven by the scripts/audit-nightly.sh runner, run on-demand) exercises its three-stage audit engines end to end — the standing doc/test-sync guarantee the doc-sync workflow-category test proves."
    level: integration
    area: doc-sync-workflow
    purpose: "The doc-sync workflow-category test backs a real integration behavior — the audit engines run end to end — not a level:workflow orchestrator claim (that would fail Check 28)."
  # ---- the runners: axis + test-run.sh engine (F000072/S000122) ----
  - id: runners-axis-optional-registry-gated
    statement: "test-spec.sh --validate accepts a well-formed runners: axis (unique ids, closed tier/platform enums, non-empty command, valid covers) and an axis-less registry validates exactly as before, with ci/hook rejected in covers."
    level: contract
    area: execution-axis
    purpose: "The execution axis is optional + registry-gated; its absence changes nothing, and ci/hook (runner-less-by-design) cannot be covered."
  - id: test-run-aggregate-evidence-derived
    statement: "test-run.sh derives its aggregate from captured evidence: any executed runner failing => fail + exit 1; zero executed => all-skipped + exit 0 and NEVER pass; a self-gating runner (rc=0 + first line ^SKIP:) is skipped(self-gated), never counted green."
    level: integration
    area: execution-engine
    purpose: "A skipped tier is never counted green and no false pass is possible — the honest-everywhere posture, generalized from e2e-local.sh."
  - id: test-run-registry-edges-honest
    statement: "test-run.sh classifies each registry edge distinctly: absent => REGISTRY=absent + exit 0; invalid => the [test-spec-no-config] passthrough + exit 1; valid with zero runners: rows => 'SKIP: no runners declared' + exit 0 with NO report and NO ledger."
    level: contract
    area: execution-engine
    purpose: "Each edge is machine-classifiable — never inference, never a fabricated ledger, never fake green."
  # ---- the cj_goal build-gate slimmed-shape invariant ----
  - id: build-gate-no-inline-slow-sync
    statement: "No CJ_goal_* orchestrator (feature/task/defect/todo_fix) runs an inline slow doc-sync (/CJ_document-release) or an inline agent-judged test-sync amendment sweep: Step 5.5 is a deterministic doc-regen (--render-docs) and QA's 8.6a/8.6b agentic sweep is gated by the DEFER_SYNC dispatch directive, so the agentic doc/test sync defers to the nightly audit while the deterministic per-PR gate stays green."
    level: integration
    area: build-gate-shape
    purpose: "Makes the build-path invariant a first-class enforced entry: a future edit that re-introduces an inline /CJ_document-release call or drops the DEFER_SYNC gate is caught by the linked guard test (which /CJ_test_run executes). Deliberately level:integration, not level:workflow — it spans the four orchestrators + qa.md, not one orchestrator's run (the workflow-coverage gate governs only orchestrator-to-level:workflow), mirroring the workflow-doc-audit-runs behavior."
behavior_coverage:
  - behavior: seed-byte-identical
    unit: test-test-spec
    source: tests/test-spec.test.sh
    anchor: "--seed == spec/test-spec.md byte-for-byte (the general file IS the seed)"
  - behavior: absent-registry-is-distinct
    unit: test-test-spec
    source: tests/test-spec.test.sh
    anchor: "absent registry: --validate prints REGISTRY=absent + exits 0 (machine-classifiable skip)"
  - behavior: present-invalid-registry-halts
    unit: test-test-spec
    source: tests/test-spec.test.sh
    anchor: "fails closed with [test-spec-no-config]"
  - behavior: overlay-merge-produces-one-registry
    unit: test-test-spec
    source: tests/test-spec.test.sh
    anchor: "overlay units, all ids unique"
  - behavior: coverage-inactive-without-units
    unit: test-test-spec
    source: tests/test-spec.test.sh
    anchor: "no units declared — coverage cross-check inactive"
  - behavior: forward-anchor-drift-detected
    unit: test-test-spec
    source: tests/test-spec.test.sh
    anchor: "forward check names the row + its source"
  - behavior: reverse-orphan-test-surface-detected
    unit: test-test-spec
    source: tests/test-spec.test.sh
    anchor: "reverse sweep flags it (no registry row)"
  - behavior: reverse-floor-prevents-vacuous-pass
    unit: test-test-spec
    source: tests/test-spec.test.sh
    anchor: "the floor finding fires (alive + overridable)"
  # ---- workflow-coverage axis (F000070): each level:workflow behavior links to
  # its REAL eval case prompt via the suite-eval (family: eval) unit; the anchor
  # is a literal present verbatim in that prompt.md (Check 5 greps it live -F).
  - behavior: workflow-cj-goal-task-runs
    unit: suite-eval
    source: tests/eval/CJ_goal_task/halt-too-complex/prompt.md
    anchor: "emits `halted_at_too_complex` and suggests `/CJ_goal_feature`"
  - behavior: workflow-cj-goal-feature-runs
    unit: suite-eval
    source: tests/eval/CJ_goal_feature/dry-run-plan/prompt.md
    anchor: "naming the planned worktree + the office-hours/scaffold/implement/qa/ship chain"
  - behavior: workflow-cj-goal-defect-runs
    unit: suite-eval
    source: tests/eval/CJ_goal_defect/dry-run-plan/prompt.md
    anchor: "naming the draft path + the investigate/promote/RCA/qa/ship chain"
  - behavior: workflow-cj-goal-todo-fix-runs
    unit: suite-eval
    source: tests/eval/CJ_goal_todo_fix/halt-size-large/prompt.md
    anchor: "which halt class /CJ_goal_todo_fix emits"
  # ---- the doc-sync workflow-category test's coverage link (F000078): backed by
  # the deterministic cj-audit-skills suite, which exercises the /CJ_doc_audit +
  # /CJ_test_audit engines end to end. ----
  - behavior: workflow-doc-audit-runs
    unit: test-cj-audit-skills
    source: tests/cj-audit-skills.test.sh
    anchor: "audit-skill (CJ_doc_audit / CJ_test_audit) engine assertions"
  # ---- the runners: axis + test-run.sh engine (F000072/S000122) ----
  - behavior: runners-axis-optional-registry-gated
    unit: test-test-run
    source: tests/test-run.test.sh
    anchor: "axis-less registry validates unchanged"
  - behavior: test-run-aggregate-evidence-derived
    unit: test-test-run
    source: tests/test-run.test.sh
    anchor: "zero executed => all-skipped + exit 0 (never pass)"
  - behavior: test-run-registry-edges-honest
    unit: test-test-run
    source: tests/test-run.test.sh
    anchor: "SKIP: no runners declared + exit 0"
  - behavior: build-gate-no-inline-slow-sync
    unit: test-cj-goal-doc-sync-wiring
    source: tests/cj-goal-doc-sync-wiring.test.sh
    anchor: "build-gate deterministic-agentic split"
runners:
  # ---- the runners: axis (F000072): HOW to run this repo's tests ----
  # Overlay-only + optional; consumed by scripts/test-run.sh (plan / tiered
  # execution / report + ledger). Each row: id (unique), command (non-empty),
  # tier {free, paid, local-only}, covers (a runnable-family list or `all`),
  # optional platform {any, windows, posix} (default any), optional note. An
  # explicit ci/hook in covers is REJECTED (runner-less-by-design). Default
  # execution runs only tier: free; --evals adds paid, --e2e adds local-only,
  # --all everything.
  - id: run-test-sh
    command: "bash scripts/test.sh"
    tier: free
    covers: [validate, test, test-deploy, eval, windows-smoke]
    platform: any
    note: "The full suite. test.sh runs validate.sh, drives test-deploy.sh end-to-end AND runs windows-smoke.sh on ANY host — all four families are covered by this ONE runner; a separate windows-smoke row would double-execute on Windows and mis-report skipped(platform) on POSIX. (test.sh does NOT invoke eval.sh — the eval family is nominally covered here but run-eval owns real eval execution.)"
  - id: run-eval
    command: "bash scripts/eval.sh"
    tier: paid
    covers: [eval]
    platform: any
    note: "The behavioral eval harness — spawns headless claude --print per case (real model spend); runs only under --evals / --all."
  - id: run-e2e-local
    command: "CJ_E2E_LOCAL=1 bash scripts/e2e-local.sh"
    tier: local-only
    covers: [test]
    platform: any
    note: "The local happy-path E2E harness — a real /CJ_goal_task build in a sandbox; self-gates (first-line ^SKIP:) without CJ_E2E_LOCAL + gstack + a claude login; runs only under --e2e / --all."
# ---- topic_contracts (F000082): enrollment into the three-layer topic contract ----
# The OPT-IN seam: only the topics listed here are HARD-checked by
# test-spec.sh --check-topic-contract (surfaced by validate.sh + /CJ_test_audit
# Stage 1) — an enrolled topic MUST reach all three layers DETERMINISTICALLY
# (CI-push + CI-nightly + local-hook{deterministic}), each row with its front-door
# doc. A local-hook AGENTIC test is ADVISORY, never required: agentic proofs run
# on-demand (they need a machine with Claude), so enrollment is never gated on the
# hardest-to-build test mode — a missing agentic row prints a per-topic `note:`
# wherever the contract is read, without redding the build. (Re-hardening, if
# agentic proofs ever become cheap here, is a one-line reversal in
# _run_topic_contract plus the matching prose/seed mirror.) Every other topic keeps
# the advisory per-category × 3-layer matrix (the grandfather seam), so enrolling
# one topic never reds the build for the rest.
#
# Three enrolled topics:
# - `portability` — CI-push (portability-check18-lint / portability-smoke) +
#   CI-nightly (portability-deploy) + local-hook{deterministic}
#   (portability-version-check); ALSO declares the advisory local-hook agentic
#   proof (portability-version-agentic), runnable via
#   /CJ_test_run --topic portability --e2e, so it gets no advisory note.
# - `validator` — CI-push (the existing `validate` row) + CI-nightly
#   (validate-nightly) + local-hook{deterministic} (validate-hook). No agentic
#   row (advisory note expected).
# - `full-suite` — CI-push (the existing `suite` row) + CI-nightly (suite-nightly)
#   + local-hook{deterministic} (suite-local). No agentic row (advisory note
#   expected).
#
# `deploy-harness` stays deliberately UNENROLLED: its missing CI-push point is a
# conscious speed decision (test-deploy.sh runs nightly, off the per-PR gate), and
# claiming windows-smoke as its CI-push row would double-count — windows-smoke is
# portability's row, and honest coverage beats complete-looking coverage. The 5
# remaining labeled topics (deploy-harness / cj-goal-eval / doc-sync / e2e /
# cj-goal-gate) are labeled but UNENROLLED — each needs its missing deterministic
# coverage points built before it can enroll (tracked as follow-up TODOs in
# TODOS.md).
topic_contracts: [portability, validator, full-suite]
categories:
  # ---- the categories: axis (F000074; two-axis reframe F000078): the
  # category-based test contract ----
  # ADDITIVE + optional; the PRIMARY axis of the category model (category ->
  # tests), consumed by /CJ_test_audit (--check-structure) + /CJ_test_run
  # (--category / --layer / single-name). TWO orthogonal axes + a mode attribute
  # (F000078): each row declares one named test with
  #   name     — unique slug — IS the docs/tests/<category>/<layer>/<name>.md
  #              filename AND the /CJ_test_run argument
  #   category — the KIND {workflow, regression, infra}: workflow proves a whole
  #              user-facing workflow (features earn these); regression proves a
  #              past defect stays fixed (defects earn these); infra is the
  #              standing verification surface (the validator, the full suite, the
  #              deploy harness)
  #   layer    — WHERE/WHEN {CI-push, CI-nightly, pipeline-gate, local-hook};
  #              descriptive metadata (the real cron/trigger lives in
  #              .github/workflows/*.yml, kept consistent by hand)
  #   mode     — {deterministic, agentic}; agentic (spends model tokens) => tier != free
  #   command / tier {free, paid, local-only} / optional doc / optional purpose.
  # This axis COEXISTS with units:/behaviors:/runners: (their removal is a
  # deferred follow-up). Physical placement is SCOPED, not bulk: only the PURE
  # dedicated per-defect drills live in the contract home
  # (tests/regression/CI-push/ — the regression rows below); the shared suites
  # (setup-hooks, cj-worktree-cleanup, doc-spec-overlay, seed-contracts,
  # cj-id-claim, ...) and the inline scripts/test.sh regression battery
  # deliberately STAY at their current flat paths (single-owner: each proves
  # more than one defect/feature, so the defect_coverage: ledger references
  # them in place via covered-by-anchor rows, never by moving or re-owning
  # them). There is NO planned bulk migration of the remaining flat
  # tests/*.test.sh — a flat test moves only when it is a pure single-purpose
  # drill for exactly one category row.
  #
  # ---- infra — the standing verification surface (the validator, the full suite,
  #      the deploy harness) ----
  - name: validate
    category: infra
    layer: CI-push
    mode: deterministic
    command: "bash scripts/validate.sh"
    tier: free
    doc: "docs/tests/infra/CI-push/validate.md"
    purpose: "The repo validator (the CI-push layer): all numbered + error + warning checks against the catalog, docs, and spec family."
    topic: validator
  - name: suite
    category: infra
    layer: CI-push
    mode: deterministic
    command: "bash scripts/test.sh"
    tier: free
    doc: "docs/tests/infra/CI-push/suite.md"
    purpose: "The full behavioral test suite — runs validate.sh, every registered tests/*.test.sh sub-suite, test-deploy.sh, and windows-smoke.sh."
    topic: full-suite
  - name: test-deploy
    category: infra
    layer: CI-nightly
    mode: deterministic
    command: "bash scripts/test-deploy.sh"
    tier: free
    doc: "docs/tests/infra/CI-nightly/test-deploy.md"
    purpose: "The skills-deploy end-to-end suite in isolated temp dirs (install / remove / relink / doctor / drift) — the POSIX-host run, re-layered to CI-nightly: the per-PR test.sh skips it under TEST_FAST=1, so it gates via the nightly full-suite (nightly.yml), not per-PR."
    topic: deploy-harness
  # ---- infra: the validator + the full suite at their other two layers — the
  #      CI-push level of each is carried by the EXISTING validate/suite rows
  #      above; these rows fill CI-nightly + local-hook for the enrolled
  #      validator/full-suite topics (same-command dual-row precedent:
  #      test-deploy/portability-deploy — one script, distinct execution contexts) ----
  - name: validate-hook
    category: infra
    layer: local-hook
    mode: deterministic
    command: "bash scripts/validate.sh"
    tier: free
    doc: "docs/tests/infra/local-hook/validate-hook.md"
    purpose: "The repo validator as the pre-commit hook run — the setup-hooks.sh workbench pre-commit hook runs exactly this command at git commit, so a broken tree is caught before it leaves the machine; the validator topic's local-hook deterministic level. (The consumer-side cj-contract-gate.sh hook is a different, engine-only subset — deliberately not this row's evidence.)"
    topic: validator
  - name: validate-nightly
    category: infra
    layer: CI-nightly
    mode: deterministic
    command: "bash scripts/validate.sh"
    tier: free
    doc: "docs/tests/infra/CI-nightly/validate-nightly.md"
    purpose: "The repo validator as executed inside the nightly full-suite run (nightly.yml -> test.sh -> validate.sh) — the validator topic's CI-nightly level: same command as the per-PR validate row, a distinct cadence + context (the full non-TEST_FAST suite on a clean nightly runner)."
    topic: validator
  - name: suite-nightly
    category: infra
    layer: CI-nightly
    mode: deterministic
    command: "bash scripts/test.sh"
    tier: free
    doc: "docs/tests/infra/CI-nightly/suite-nightly.md"
    purpose: "The full behavioral test suite as nightly.yml's full non-TEST_FAST run — the full-suite topic's CI-nightly level: the heavy end-to-end pass (including test-deploy.sh, which the per-PR TEST_FAST=1 run skips) off the per-PR path."
    topic: full-suite
  - name: suite-local
    category: infra
    layer: local-hook
    mode: deterministic
    command: "bash scripts/test.sh"
    tier: free
    doc: "docs/tests/infra/local-hook/suite-local.md"
    purpose: "The full behavioral test suite as the documented run-locally-before-push harness (the CI-gate convention: run the full test.sh locally before pushing, since per-PR CI fails on any finding) — the full-suite topic's local-hook deterministic level."
    topic: full-suite
  # ---- infra: the deploy/install (portability) harness, at all three test levels —
  #      CI-push {the Check-18 declared-vs-actual lint + the Git-Bash smoke},
  #      CI-nightly {the Windows-native deploy suite}, local-hook {the version-check} ----
  - name: portability-check18-lint
    category: infra
    layer: CI-push
    mode: deterministic
    command: "bash scripts/cj-portability-audit.sh"
    tier: free
    doc: "docs/tests/infra/CI-push/portability-check18-lint.md"
    purpose: "The declared-vs-actual portability lint (validate.sh Check 18's engine): each catalog skill's declared portability tier is checked against its actual repo-local dependencies — the fast per-PR portability signal of the deploy/install harness."
    topic: portability
  - name: portability-smoke
    category: infra
    layer: CI-push
    mode: deterministic
    command: "bash scripts/windows-smoke.sh"
    tier: free
    doc: "docs/tests/infra/CI-push/portability-smoke.md"
    purpose: "The Windows Git Bash portability smoke of the deploy/install harness (copy-mode install, in-place stamp, _cj-shared update-check resolution) — standing verification infra, not a user-facing workflow; the fast per-PR Windows signal."
    topic: portability
  - name: portability-deploy
    category: infra
    layer: CI-nightly
    mode: deterministic
    command: "bash scripts/test-deploy.sh"
    tier: free
    doc: "docs/tests/infra/CI-nightly/portability-deploy.md"
    purpose: "The skills-deploy end-to-end run of the deploy/install harness on windows-latest, run nightly (windows-nightly.yml) — standing verification infra (the install/remove/relink/doctor harness) held Windows-native; same script as the push-cadence test-deploy, a distinct CI context (platform + cadence)."
    topic: portability
  - name: portability-version-check
    category: infra
    layer: local-hook
    mode: deterministic
    command: "bash tests/skills-update-check.test.sh"
    tier: free
    doc: "docs/tests/infra/local-hook/portability-version-check.md"
    purpose: "The local sandbox check of the deploy/install harness's version-notification — a stubbed git ls-remote + a .source-absent manifest proving skills-update-check nudges when a newer release is published; portability's local-hook level (deterministic fill; the agentic model-surfaced-prompt variant is the sibling portability-version-agentic row)."
    topic: portability
  - name: portability-version-agentic
    category: infra
    layer: local-hook
    mode: agentic
    command: "bash tests/portability-version-agentic.test.sh"
    tier: local-only
    doc: "docs/tests/infra/local-hook/portability-version-agentic.md"
    purpose: "The local AGENTIC proof of the deploy/install harness's version-notification — a repo-neutral sandbox + a bare upstream tagged v-newer drives the skills-update-check preamble through claude --print and asserts the agent SURFACES the upgrade nudge to a human (not merely that the banner text exists); portability's local-hook agentic level, closing the green-but-inert blind spot the deterministic version-check cannot see. Local-only (SKIPs clean without CJ_E2E_LOCAL=1 + a claude login), so CI never spends a model."
    topic: portability
  # ---- workflow — proves a whole user-facing workflow runs end to end: the
  #      cj_goal orchestrators, the doc-sync pipeline, and the local happy-path E2E
  #      harness (the portability install/deploy harness rows moved to infra) ----
  - name: goal-task-eval
    category: workflow
    layer: local-hook
    mode: agentic
    command: "bash scripts/eval.sh CJ_goal_task"
    tier: paid
    doc: "docs/tests/workflow/local-hook/goal-task-eval.md"
    purpose: "The /CJ_goal_task workflow eval — drives the task orchestrator through a real gstack-independent path (task -> halted_at_too_complex); agentic (spends model tokens), so it runs on-demand at the local-hook layer, never on a CI schedule or the free-tier default."
    topic: cj-goal-eval
  - name: goal-feature-eval
    category: workflow
    layer: local-hook
    mode: agentic
    command: "bash scripts/eval.sh CJ_goal_feature"
    tier: paid
    doc: "docs/tests/workflow/local-hook/goal-feature-eval.md"
    purpose: "The /CJ_goal_feature workflow eval — drives the feature orchestrator through its dry-run chain-plan preview on the gstack-independent path (end_state dry_run_preview); backs the workflow-cj-goal-feature-runs level:workflow behavior; agentic, on-demand local-hook cadence."
    topic: cj-goal-eval
  - name: doc-sync
    category: workflow
    layer: local-hook
    mode: agentic
    command: "bash scripts/audit-nightly.sh --dry-run"
    tier: paid
    doc: "docs/tests/workflow/local-hook/doc-sync.md"
    purpose: "The doc/test-sync audit workflow — exercises the /CJ_doc_audit + /CJ_test_audit logic end to end via the scripts/audit-nightly.sh runner; agentic (claude --print), so it runs on-demand at the local-hook layer and never on the free-tier default."
    topic: doc-sync
  - name: e2e-local
    category: workflow
    layer: local-hook
    mode: agentic
    command: "CJ_E2E_LOCAL=1 bash scripts/e2e-local.sh"
    tier: local-only
    doc: "docs/tests/workflow/local-hook/e2e-local.md"
    purpose: "The local happy-path E2E harness — a real /CJ_goal_task build in a throwaway sandbox, driven through the build gates to the /ship boundary; agentic + local-only (runs on your machine, never in CI)."
    topic: e2e
  - name: cj-goal-gate-shape
    category: workflow
    layer: CI-push
    mode: deterministic
    command: "bash tests/cj-goal-doc-sync-wiring.test.sh"
    tier: free
    doc: "docs/tests/workflow/CI-push/cj-goal-gate-shape.md"
    purpose: "The cj_goal build-gate shape guard — proves no CJ_goal_* orchestrator runs an inline slow doc-sync (/CJ_document-release) or agent-judged test-sync sweep: Step 5.5 is a deterministic doc-regen and QA's 8.6a/8.6b agentic sweep is DEFER_SYNC-gated, so the agentic doc/test sync defers to the nightly audit. Deterministic (grep, no model), runs per-PR; the complement to the doc-sync workflow test that proves the nightly safety net."
    topic: cj-goal-gate
  # ---- regression — proves a specific past defect stays fixed (defects earn
  #      these): the pure dedicated per-defect drills, migrated into the
  #      contract home tests/regression/CI-push/ and runnable by name; each is
  #      the covered-by proof of its defect_coverage: ledger row below. ALL
  #      regression rows are mode: deterministic + tier: free by rule (the
  #      ledger's mode gate FINDINGs on an agentic covered-by target). ----
  - name: tag-release
    category: regression
    layer: CI-push
    mode: deterministic
    command: "bash tests/regression/CI-push/tag-release.test.sh"
    tier: free
    doc: "docs/tests/regression/CI-push/tag-release.md"
    purpose: "The post-land release-tag drill: the tag-release helper publishes the v<VERSION> tag to a hermetic local bare origin — created + pushed, idempotent on re-run, --version override honored, non-semver rejected, and the strict-fails vs default-fail-softs push-failure split — guarding the once-inert version notification whose ls-remote tag compare starved when the land flow bumped VERSION without ever tagging."
  - name: cj-goal-jq-crlf
    category: regression
    layer: CI-push
    mode: deterministic
    command: "bash tests/regression/CI-push/cj-goal-jq-crlf.test.sh"
    tier: free
    doc: "docs/tests/regression/CI-push/cj-goal-jq-crlf.md"
    purpose: "The orchestrator-helper jq-CRLF drill: the CR-stripping jq() wrapper is present in the five cj-goal helpers and, under a CRLF-emitting jq shim, strips CR from jq output while preserving jq's non-zero exit status — so a Windows jq's CRLF can no longer re-taint the worktree/sync/pr-check phases."
  - name: drain-one-todo-helper-unavailable
    category: regression
    layer: CI-push
    mode: deterministic
    command: "bash tests/regression/CI-push/drain-one-todo-helper-unavailable.test.sh"
    tier: free
    doc: "docs/tests/regression/CI-push/drain-one-todo-helper-unavailable.md"
    purpose: "The drain fail-loud drill: when the worktree-init helper is unreachable everywhere (manifest source gone AND the in-repo fallback absent), the TODO drain halts with a named RESULT and a non-zero exit instead of silently scaffolding the drained TODO into the current (possibly dirty) branch."
  - name: drain-one-todo-worktree-resolve
    category: regression
    layer: CI-push
    mode: deterministic
    command: "bash tests/regression/CI-push/drain-one-todo-worktree-resolve.test.sh"
    tier: free
    doc: "docs/tests/regression/CI-push/drain-one-todo-worktree-resolve.md"
    purpose: "The drain deployed-path drill: a deployed drain helper resolves the worktree-init helper via the manifest source path (not a deploy-relative guess) and creates a real per-iteration worktree, so drained TODOs never collide on one branch."
# ---- defect_coverage (F000085): the defect↔proof LEDGER — one row per defect
#      work-item dir, keyed by the FULL path relative to work-items/defects/
#      (bare D-IDs are ambiguous: D000021 exists twice). Three closed
#      dispositions: covered-by (a named deterministic regression categories:
#      row), covered-by-anchor (proof inside a shared file — a scripts/test.sh
#      inline banner, a shared suite's named case, scripts/test-deploy.sh, or a
#      validate.sh check — anchor greps LIVE via grep -F), waived (a reason;
#      gaps are `waived: "gap — …"` + a todo pointer at their TODOS.md row).
#      Enforced by test-spec.sh --check-defect-coverage (validate.sh Check 32 +
#      /CJ_test_audit Stage 1). Every row below was VERIFIED against the live
#      repo at backfill time (anchor grepped / drill located) — the ledger
#      declares proof, never folklore. This block stays LAST in the overlay. ----
defect_coverage:
  # ---- ops/ (ship / skills-deploy / workflow) ----
  - defect: ops/ship/D000008_ship_gh_pr_merge_auto_requires_method_flag
    disposition: covered-by-anchor
    source: scripts/test.sh
    anchor: "Regression test (D000008): CLAUDE.md merge convention guard"
  - defect: ops/skills-deploy/D000005_skills_deploy_windows_jq_crlf
    disposition: covered-by-anchor
    source: scripts/test.sh
    anchor: "Regression test (D000005): Windows jq CRLF wrapper present"
  - defect: ops/skills-deploy/D000013_skills_deploy_auto_sync_hook
    disposition: covered-by-anchor
    source: scripts/test.sh
    anchor: "Regression test (D000013): setup-hooks.sh installs post-merge auto-sync hook"
  - defect: ops/skills-deploy/D000015_skills_deploy_install_overwrite_default
    disposition: covered-by-anchor
    source: scripts/test.sh
    anchor: "Regression test (D000015): skills-deploy install overwrites drifted templates by default"
  - defect: ops/skills-deploy/D000021_setup_sh_missing_hook_wiring
    disposition: covered-by-anchor
    source: scripts/test.sh
    anchor: "D000021: setup.sh bootstrap must wire setup-hooks.sh"
  - defect: ops/skills-deploy/D000022_setup_hooks_blind_clobber
    disposition: covered-by-anchor
    source: scripts/test.sh
    anchor: "D000022: the git-hook installer must not blind-clobber"
  - defect: ops/workflow/D000001_milestones_artifact_placement
    disposition: waived
    reason: "surface migrated — the milestones artifact placement this defect fixed was folded into the ROADMAP template during the feature-summary+milestones migration; the original placement surface no longer exists"
  - defect: ops/workflow/D000002_workitem_format_consistency
    disposition: waived
    reason: "process/convention defect — work-item format consistency is enforced broadly by the template + manifest structural checks (the D000014 count-drift guard among them), not by one isolated drill"
  - defect: ops/workflow/D000007_workflow_template_single_source_of_truth
    disposition: covered-by-anchor
    source: scripts/test.sh
    anchor: "Regression test (D000007): contract.json eliminated; templates are the single source of truth"
  - defect: ops/workflow/D000014_workflow_md_artifact_count_drift_and_extra_detection
    disposition: covered-by-anchor
    source: scripts/test.sh
    anchor: "Regression test (D000014): WORKFLOW.md type-to-artifact counts match manifest"
  # ---- personal-workflow/ ----
  - defect: personal-workflow/D000009_personal_workflow_feature_missing_design_doc
    disposition: covered-by-anchor
    source: scripts/test.sh
    anchor: "Regression test (D000009): feature type requires DESIGN.md artifact"
  - defect: personal-workflow/D000012_personal_workflow_template_deploy_drift
    disposition: covered-by-anchor
    source: scripts/test.sh
    anchor: "Regression test (D000012): deployed workflow templates stay in sync with workbench"
  - defect: personal-workflow/D000016_test_deploy_stale_templates
    disposition: covered-by-anchor
    source: scripts/test.sh
    anchor: "Integration: test-deploy.sh end-to-end (D000016)"
  - defect: personal-workflow/D000018_qa_e2e_subagent_structural_inspection
    disposition: covered-by-anchor
    source: scripts/test.sh
    anchor: "Regression test (D000018): QA E2E dispatch keeps the leaf-node + parent-inline execution contract"
  # ---- skills/ ----
  - defect: skills/D000019_pipeline_type_aware_gates
    disposition: waived
    reason: "gap — a deterministic drill would prove the QA pipeline's type-aware gate semantics (defect/task rows treat an ambiguous E2E verdict as the canonical not-applicable marker instead of halting; the pre-scan covers defect/task inputs + the skills/*/scripts/ trust boundary)"
    todo: "TODOS:10 (author the D000019 type-aware QA-gate shape-guard)"
  - defect: skills/D000020_investigate_idempotency_edge_cases
    disposition: waived
    reason: "surface retired — the investigate orchestrator this defect patched was reshaped into the defect verb (/CJ_goal_defect); its Step-3 idempotency dispatch table no longer exists as a live surface"
  # ---- suggest/ ----
  - defect: suggest/D000017_cj_suggest_zsh_crash
    disposition: covered-by-anchor
    source: scripts/test.sh
    anchor: "S000078: suggest.sh ranks on"
  # ---- uncategorized/ ----
  - defect: uncategorized/D000021_drain_one_todo_worktree_init_path_resolution
    disposition: covered-by
    test: drain-one-todo-worktree-resolve
  - defect: uncategorized/D000024_drain_silent_fallthrough_inplace_scaffold
    disposition: covered-by
    test: drain-one-todo-helper-unavailable
  - defect: uncategorized/D000025_d_id_allocator_resolver_shallow_find_maxdepth_2_sc
    disposition: covered-by-anchor
    source: scripts/test.sh
    anchor: "Regression test (D000025): D-ID allocator find sites carry no -maxdepth cap"
  - defect: uncategorized/D000026_cj_goal_feature_preamble_doc_sync_auq_recommends_a
    disposition: waived
    reason: "surface removed — the doc-sync preamble AUQ whose recommendation polarity this defect fixed was retired wholesale with the post-merge marker mechanism; no orchestrator preamble carries the AUQ block anymore"
  - defect: uncategorized/D000027_that_docs_skill_category_doesn_t_inlcude_my_copilo
    disposition: waived
    reason: "doc/catalog-mapping defect — a one-time docs categorization fix with no isolated failure mode to drill; the doc contract checks own the docs-completeness surface broadly"
  - defect: uncategorized/D000028_cj_worktree_cleanup_sh_root_refresh_guard_skips_ma
    disposition: covered-by-anchor
    source: tests/cj-worktree-cleanup.test.sh
    anchor: "Case 12b: root-refresh proceeds on untracked-only root"
  - defect: uncategorized/D000029_post_merge_phase_3_lifecycle_gate_hook_mis_links_p
    disposition: covered-by-anchor
    source: tests/setup-hooks.test.sh
    anchor: "post-merge hook has no Phase-3 / check-gates-update tracker auto-tick"
  - defect: uncategorized/D000030_the_cj_document_release_wrapper_can_t_resolve_its
    disposition: covered-by-anchor
    source: scripts/test.sh
    anchor: "the consumer-repo simulation — the D000030/D000032"
  - defect: uncategorized/D000031_cj_goal_defect_step_7_4_promotes_a_structurally_mi
    disposition: waived
    reason: "agent-judged pipeline-prose surface — the promotion gate is orchestrator prose executed by an agent; a deterministic drill would need a full pipeline fixture, and the deterministic-only ledger rule excludes an agentic one"
  - defect: uncategorized/D000033_cj_portability_audit_skill_md_advisory_rationale_i
    disposition: waived
    reason: "surface retired — the standalone portability-audit verb whose stale advisory prose this defect fixed now lives under deprecated/; the engine + Check 18 that remain are covered as infra categories rows"
  - defect: uncategorized/D000034_doc_audit_no_remediation_pointer
    disposition: covered-by-anchor
    source: tests/doc-spec-overlay.test.sh
    anchor: "8b-2. a declared-exists finding ALSO emits the read-mostly REMEDIATION pointer"
  - defect: uncategorized/D000035_test_spec_sh_reverse_sweep_per_namespace_floors_mi
    disposition: covered-by-anchor
    source: tests/test-spec.test.sh
    anchor: "surface-existence gating of the reverse floors (D000035)"
  - defect: uncategorized/D000036_skills_deploy_is_workbench_self_repo_false_positiv
    disposition: covered-by-anchor
    source: tests/seed-contracts.test.sh
    anchor: "Case B2: CONSUMER with a hand-authored overlay + NO catalog is NOT self"
  - defect: uncategorized/D000037_complete_consumer_adoption_skips_a_hand_authored_o
    disposition: covered-by-anchor
    source: scripts/test-deploy.sh
    anchor: "Test S000117b: hand-authored overlay adoption — refresh + append-only declare (D000037)"
  - defect: uncategorized/D000038_jq_crlf_output_breaks_the_spec_engines_on_windows
    disposition: covered-by-anchor
    source: tests/workflow-spec-render.test.sh
    anchor: "T7: the CRLF-jq drill"
  - defect: uncategorized/D000039_cj_id_claim_sh_reap_regex_misses_id_tracker_md_fea
    disposition: covered-by-anchor
    source: tests/cj-id-claim.test.sh
    anchor: "SLUG-LESS feature tracker"
  - defect: uncategorized/D000040_jq_crlf_class_in_orchestrator_helpers_on_windows
    disposition: covered-by
    test: cj-goal-jq-crlf
  - defect: uncategorized/D000042_version_notification_release_tag_inertness
    disposition: covered-by
    test: tag-release
  - defect: uncategorized/D000043_doctor_misses_crlf_template_line_ending_drift
    disposition: covered-by-anchor
    source: scripts/test-deploy.sh
    anchor: "Test 8c: Doctor flags CRLF template drift"
  # ---- work-copilot/ ----
  - defect: work-copilot/D000010_copilot_deploy_security_hardening
    disposition: covered-by-anchor
    source: scripts/test.sh
    anchor: "path-traversal defense in doctor"
  - defect: work-copilot/D000011_copilot_bundle_install_requires_full_repo
    disposition: covered-by-anchor
    source: scripts/validate.sh
    anchor: "Error check 10: work-copilot bundle existence check"
```
