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
enum is `{local-hook, ci}` and would reject `pipeline-gate`. The general
test-spec carries the four `layers:` (local-hook / ci / pipeline-gate /
ratchet); this overlay carries the per-mode `gates:` that run in the
`pipeline-gate` layer.

## The verification surface, grouped by layer

The general contract ([`test-spec.md`](test-spec.md)) names the four
verification layers in the abstract; this section is the reader's-eye index of
which **kinds** of tests this repo actually runs in each one. The fenced `yaml`
registry below stays the source of truth — this grouping is derived from it
(prose drift is caught by the advisory registered-doc requirements audit, the
same posture as the per-row `purpose` one-liners). Each `units:` row carries a
`layer` (`local-hook | ci`) and a `family`; the `gates:` array is the
`pipeline-gate` layer; the `ratchet: true` flag marks the cross-cutting ratchet
layer (a ratchet unit also runs in `ci`).

### Handled by `ci` (every PR, on a clean runner — hard-fail)

The bulk of the surface. Four kinds, each its own table below.

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

**Standalone suites** (also manually runnable; some also run on push-main or
nightly):

| Check / Unit | What it asserts |
|---|---|
| skills-deploy suite — install/doctor/remove in isolation | Template ownership, drift overwrite, copy-mode and doctor verdicts in temp homes. |
| behavioral eval harness — headless skill evals | Spawns the headless CLI per eval case with JSON-schema output, budget-capped. |
| Windows smoke — CRLF + portable date + copy-mode | Git Bash assertions: CRLF tolerance, portable date math, copy-mode install stamp. |

**GitHub Actions workflows**:

| Check / Unit | What it asserts |
|---|---|
| validate workflow — PR gate | Runs the validator, full test suite and shellcheck on every PR. |
| windows workflow — Git Bash smoke gate | Runs the fast Windows smoke under Git Bash on PR + push-main (CI-push cadence). |
| windows-nightly workflow — nightly skills-deploy suite | Runs the full skills-deploy suite (test-deploy.sh) on windows-latest nightly + on dispatch (CI-nightly cadence). |
| eval-nightly workflow — scheduled evals | Runs the behavioral eval harness daily, with a manual dispatch trigger. |
| audit-nightly workflow — nightly doc/test audit | Runs /CJ_doc_audit + /CJ_test_audit headless daily and files findings to a GitHub issue (advisory; CI-nightly cadence). |

### Handled by `local-hook` (at `git commit`, before code leaves the machine)

The git hooks installed by `scripts/setup-hooks.sh`. (The validator rows carry
the `pre-commit pr-ci` trigger — the same checks, two firing points.)

| Check / Unit | What it asserts |
|---|---|
| pre-commit hook — validator at commit time | Runs the validator before every local commit; a failing check blocks it. |
| post-merge hook — auto re-deploy | Re-deploys skills, templates and rules after pulls; best-effort, never blocks git. |

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

The `ratchet: true` units (each also runs in `ci`):

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
  `local-hook | ci`. Per the doctrine ("validate.sh-as-a-whole is
  the ci layer"), `validate` rows record `ci`; hook rows record `local-hook`.
  Firing points are fully captured by `trigger`.
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
    layer: ci
    disposition: hard-fail
    trigger: "pre-commit pr-ci"
    purpose: "Every catalog entry's declared SKILL.md exists on disk; templates-only entries are exempt."
  - id: validate-error-check-2
    family: validate
    label: "Error check 2 — SKILL.md frontmatter required fields"
    anchor: "# Error check 2:"
    source: scripts/validate.sh
    layer: ci
    disposition: hard-fail
    trigger: "pre-commit pr-ci"
    purpose: "Every SKILL.md carries name and description in its YAML frontmatter."
  - id: validate-error-check-3
    family: validate
    label: "Error check 3 — declared templates exist on disk"
    anchor: "# Error check 3:"
    source: scripts/validate.sh
    layer: ci
    disposition: hard-fail
    trigger: "pre-commit pr-ci"
    purpose: "Every catalog templates entry resolves to a file on disk, honoring per-skill source overrides."
  - id: validate-error-check-4
    family: validate
    label: "Error check 4 — no orphan skill directories"
    anchor: "# Error check 4:"
    source: scripts/validate.sh
    layer: ci
    disposition: hard-fail
    trigger: "pre-commit pr-ci"
    purpose: "Every skill directory on disk (active or lifecycle-relocated) is claimed by a catalog entry."
  - id: validate-error-check-5
    family: validate
    label: "Error check 5 — doc triplets complete with type frontmatter"
    anchor: "# Error check 5:"
    source: scripts/validate.sh
    layer: ci
    disposition: hard-fail
    trigger: "pre-commit pr-ci"
    purpose: "Any per-skill doc directory carries all three design docs, each with type frontmatter."
  - id: validate-error-check-6
    family: validate
    label: "Error check 6 — skill dependencies resolve"
    anchor: "# Error check 6:"
    source: scripts/validate.sh
    layer: ci
    disposition: hard-fail
    trigger: "pre-commit pr-ci"
    purpose: "Every declared skill dependency names another catalog entry."
  - id: validate-error-check-7
    family: validate
    label: "Error check 7 — VERSION file valid semver"
    anchor: "# Error check 7:"
    source: scripts/validate.sh
    layer: ci
    disposition: hard-fail
    trigger: "pre-commit pr-ci"
    purpose: "The VERSION file exists and parses as semver."
  - id: validate-error-check-8
    family: validate
    label: "Error check 8 — VERSION never regresses"
    anchor: "# Error check 8:"
    source: scripts/validate.sh
    layer: ci
    disposition: hard-fail
    ratchet: true
    trigger: "pre-commit pr-ci"
    purpose: "VERSION is at least the latest collection v-tag; a version regression fails the build (ratchet)."
  - id: validate-error-check-9
    family: validate
    label: "Error check 9 — catalog skill versions valid semver"
    anchor: "# Error check 9:"
    source: scripts/validate.sh
    layer: ci
    disposition: hard-fail
    trigger: "pre-commit pr-ci"
    purpose: "Every catalog entry's version field parses as semver."
  - id: validate-error-check-9b
    family: validate
    label: "Error check 9b — catalog status closed enum"
    anchor: "# Error check 9b:"
    source: scripts/validate.sh
    layer: ci
    disposition: hard-fail
    trigger: "pre-commit pr-ci"
    purpose: "Every catalog status is one of active, experimental or deprecated; typos fail loudly."
  - id: validate-error-check-10
    family: validate
    label: "Error check 10 — Copilot bundle file existence"
    anchor: "# Error check 10:"
    source: scripts/validate.sh
    layer: ci
    disposition: hard-fail
    trigger: "pre-commit pr-ci"
    purpose: "Every required Copilot bundle file in the expected-files array is present on disk."
  - id: validate-error-check-11
    family: validate
    label: "Error check 11 — manifest reconciliation"
    anchor: "# Error check 11:"
    source: scripts/validate.sh
    layer: ci
    disposition: hard-fail
    trigger: "pre-commit pr-ci"
    purpose: "Work-item dirs and valid fixtures carry every artifact their manifest requires for their tracker type."
  # ---- validate family: warning checks (comment-anchored, advisory) ----
  - id: validate-warning-orphan-doc-dirs
    family: validate
    label: "Warning check — orphan doc directories"
    anchor: "# Warning check: Orphan doc directories"
    source: scripts/validate.sh
    layer: ci
    disposition: advisory
    trigger: "pre-commit pr-ci"
    purpose: "Flags per-skill doc directories with no matching catalog entry."
  - id: validate-warning-orphan-templates
    family: validate
    label: "Warning check 3 — orphan template files"
    anchor: "# Warning check 3: Orphan template files"
    source: scripts/validate.sh
    layer: ci
    disposition: advisory
    trigger: "pre-commit pr-ci"
    purpose: "Flags template files not referenced by any catalog entry, across the default dir and overrides."
  # ---- validate family: numbered checks (banner-anchored) ----
  - id: validate-check-11
    family: validate
    label: "Check 11 — rules deploy health"
    anchor: "=== Check 11:"
    source: scripts/validate.sh
    layer: ci
    disposition: hard-fail
    skips_when_absent: true
    trigger: "pre-commit pr-ci"
    purpose: "Every rules file is deployed to the local rules target; warn-degrades when the deploy target is absent."
  - id: validate-check-13
    family: validate
    label: "Check 13 — USAGE.md present with required sections"
    anchor: "=== Check 13:"
    source: scripts/validate.sh
    layer: ci
    disposition: hard-fail
    trigger: "pre-commit pr-ci"
    purpose: "Every routable non-deprecated skill has a USAGE.md with the five required section headings."
  - id: validate-check-14
    family: validate
    label: "Check 14 — USAGE.md content freshness"
    anchor: "=== Check 14:"
    source: scripts/validate.sh
    layer: ci
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
    layer: ci
    disposition: hard-fail
    trigger: "pre-commit pr-ci"
    purpose: "15a: every declared doc exists and every doc under docs/ (RECURSIVE, including the docs/workflows/ subfolder) and spec/ is declared (no orphans). 15b/15c are retired (the workflow surface is generated from spec/workflow-spec.md): the no-vanish guarantee lives in workflow-spec.sh --validate registry-completeness and freshness in Check 27."
  - id: validate-check-16
    family: validate
    label: "Check 16 — doc registry schema"
    anchor: "=== Check 16:"
    source: scripts/validate.sh
    layer: ci
    disposition: hard-fail
    skips_when_absent: true
    trigger: "pre-commit pr-ci"
    purpose: "The doc registry parses: one yaml fence, supported schema version, required keys, closed enums; skips when the registry is absent."
  - id: validate-check-17
    family: validate
    label: "Check 17 — root-doc placement allowlist"
    anchor: "=== Check 17:"
    source: scripts/validate.sh
    layer: ci
    disposition: hard-fail
    trigger: "pre-commit pr-ci"
    purpose: "Every root markdown doc on disk is a declared registry path, and every declared root doc exists."
  - id: validate-check-18
    family: validate
    label: "Check 18 — skill portability audit"
    anchor: "=== Check 18:"
    source: scripts/validate.sh
    layer: ci
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
    layer: ci
    disposition: hard-fail
    skips_when_absent: true
    trigger: "pre-commit pr-ci"
    purpose: "No registry human-doc contains an internal work-item ID; skips when the doc registry is absent."
  - id: validate-check-21
    family: validate
    label: "Check 21 — permission-policy drift"
    anchor: "=== Check 21:"
    source: scripts/validate.sh
    layer: ci
    disposition: advisory
    skips_when_absent: true
    trigger: "pre-commit pr-ci"
    purpose: "The permission policy parses, the handoff gate derives its denylist from it, and every goal orchestrator references it; skips when the policy is absent."
  - id: validate-check-24
    family: validate
    label: "Check 24 — test-spec coverage cross-check + gate marker drift"
    anchor: "=== Check 24:"
    source: scripts/validate.sh
    layer: ci
    disposition: hard-fail
    skips_when_absent: true
    trigger: "pre-commit pr-ci"
    purpose: "Validates the merged test-spec registry, then cross-checks coverage (forward, every unit anchor matches live in its declared source; reverse, every live validate banner and comment, test file on disk, workflow, and hook resolves to exactly one unit, with a floor of twenty reverse tokens) — hard; then the advisory per-mode gate marker-drift cross-check over the gates array (absorbed from the retired Check 22); skips when the registry is absent."
  - id: validate-check-25
    family: validate
    label: "Check 25 — README in sync with generate-readme.sh"
    anchor: "=== Check 25:"
    source: scripts/validate.sh
    layer: ci
    disposition: hard-fail
    skips_when_absent: true
    trigger: "pre-commit pr-ci"
    purpose: "README.md byte-matches the generate-readme.sh stdout, so a stale catalog-derived README cannot pass validation; read-only (the generator writes only to stdout); skips when the generator is absent."
  - id: validate-check-26
    family: validate
    label: "Check 26 — generated test catalog in sync with test-spec.sh --render-docs"
    anchor: "=== Check 26:"
    source: scripts/validate.sh
    layer: ci
    disposition: hard-fail
    skips_when_absent: true
    trigger: "pre-commit pr-ci"
    purpose: "The generated test catalog (docs/tests/<family>.md per unit family plus the docs/test-catalog.md index) byte-matches a fresh render from the merged registry, so a stale catalog cannot pass validation; read-only (--check renders only into a temp dir); skips when the engine is absent or no units are declared."
  - id: validate-check-27
    family: validate
    label: "Check 27 — generated workflow surface in sync with workflow-spec.sh --render-docs"
    anchor: "=== Check 27:"
    source: scripts/validate.sh
    layer: ci
    disposition: hard-fail
    skips_when_absent: true
    trigger: "pre-commit pr-ci"
    purpose: "The generated workflow surface (the docs/workflow.md index plus the six docs/workflows/<name>.md per-workflow files) byte-matches a fresh render from spec/workflow-spec.md, so a stale workflow doc cannot pass validation; read-only (--check renders only into a temp dir); registry-gated, skips when spec/workflow-spec.md is absent. Replaces the retired shape-only Checks 15b/15c."
  - id: validate-check-28
    family: validate
    label: "Check 28 — every CJ_goal_* orchestrator has a level:workflow behavior (workflow-coverage gate)"
    anchor: "=== Check 28:"
    source: scripts/validate.sh
    layer: ci
    disposition: hard-fail
    skips_when_absent: true
    trigger: "pre-commit pr-ci"
    purpose: "The forward+reverse workflow-coverage gate (test-spec.sh --check-workflow-coverage): every declared CJ_goal_* orchestrator (workflow-spec.sh --list-orchestrators) has a level:workflow behavior whose workflow: equals it, and no level:workflow behavior names an undeclared orchestrator, so a documented-but-untested workflow cannot pass validation; runs in plain CI (registry-only, no API); registry-gated, skips when the test-spec engine is absent or no orchestrators are resolvable."
  - id: validate-check-29
    family: validate
    label: "Check 29 — cj_goal E2E sandbox marker absent from the tracked tree"
    anchor: "=== Check 29:"
    source: scripts/validate.sh
    layer: ci
    disposition: hard-fail
    trigger: "pre-commit pr-ci"
    purpose: "The marker-absence guard for the build-gate auto-answer seam: git ls-files must never track .cj-e2e-sandbox (the second half of the seam's double guard, CJ_GOAL_E2E_AUTO=1 AND the marker). A committed marker could make the seam live in a real repo with only an env flag; this check hard-fails the moment git tracks it, anywhere in the tree (the gitignored sandbox copy passes cleanly)."
  # ---- validate family: the portability audit engine (repo-custom test logic) ----
  - id: portability-audit
    family: validate
    label: "portability audit — declared-vs-actual skill dependency lint"
    anchor: "scripts/cj-portability-audit.sh"
    source: scripts/validate.sh
    layer: ci
    disposition: advisory
    skips_when_absent: true
    ratchet: true
    trigger: "pre-commit pr-ci manual"
    purpose: "The portability engine behind validate.sh Check 18 and the standalone /CJ_portability-audit skill: each skill's declared portability matches its actual executed dependencies; the clean baseline is the ratchet."
  # ---- test family: registered tests/*.test.sh sub-suites ----
  # (source MUST be scripts/test.sh and anchor MUST be the literal runner path —
  #  the forward check proves the file is wired into the hand-wired runner.)
  - id: test-cj-worktree-init
    family: test
    label: "cj-worktree-init suite — worktree creation helper"
    anchor: "tests/cj-worktree-init.test.sh"
    source: scripts/test.sh
    layer: ci
    disposition: hard-fail
    trigger: "pr-ci"
    purpose: "Caller prefixes, dirty-checkout guard and base-freshness fork behavior of the worktree-init helper."
  - id: test-cj-worktree-cleanup
    family: test
    label: "cj-worktree-cleanup suite — post-run worktree janitor"
    anchor: "tests/cj-worktree-cleanup.test.sh"
    source: scripts/test.sh
    layer: ci
    disposition: hard-fail
    trigger: "pr-ci"
    purpose: "PR-state-gated sweep, orphan-dir removal, guard refusals and pipeline seams of the worktree janitor."
  - id: test-cj-task-scaffold
    family: test
    label: "cj-task-scaffold suite — task complexity gate + scaffold"
    anchor: "tests/cj-task-scaffold.test.sh"
    source: scripts/test.sh
    layer: ci
    disposition: hard-fail
    trigger: "pr-ci"
    purpose: "Complexity-gate refusals, dry-run preview, live scaffold and idempotency of the task scaffolder."
  - id: test-cj-e2e-gate
    family: test
    label: "cj-e2e-gate suite — build-gate auto-answer seam verdict matrix"
    anchor: "tests/cj-e2e-gate.test.sh"
    source: scripts/test.sh
    layer: ci
    disposition: hard-fail
    trigger: "pr-ci"
    purpose: "The full verdict matrix of the build-gate auto-answer seam helper (scripts/cj-e2e-gate.sh): flag-only and marker-only both inactive, both-guards + green qa-audit continues, both-guards + findings/empty qa-audit halts (never auto-waive), a non-allowlisted gate id stays inactive, design-gate auto-approves — all deterministic, no Claude."
  - id: test-audit-nightly
    family: test
    label: "audit-nightly suite — nightly doc/test audit runner deterministic half"
    anchor: "tests/audit-nightly.test.sh"
    source: scripts/test.sh
    layer: ci
    disposition: hard-fail
    trigger: "pr-ci"
    purpose: "The DETERMINISTIC (no-Claude, no-network) half of scripts/audit-nightly.sh — the relocated nightly agent-judged audit: SKIP without a model key, the --dry-run plan, the two-count findings parse + report emission, and the create/update/none-clean GitHub-issue decision — all with claude + gh stubbed on PATH."
  - id: test-e2e-local
    family: test
    label: "e2e-local suite — local happy-path E2E harness deterministic half"
    anchor: "tests/e2e-local.test.sh"
    source: scripts/test.sh
    layer: ci
    disposition: hard-fail
    trigger: "pr-ci"
    purpose: "The DETERMINISTIC (no-Claude) half of the local-E2E harness (scripts/e2e-local.sh + tests/e2e-local/lib/{sandbox,report}.sh): the SKIP path when CJ_E2E_LOCAL is unset OR a prerequisite is absent (exit 0, never reaches claude), the sandbox provision/teardown (a mktemp clone + a .cj-e2e-sandbox marker + a LOCAL bare origin that defeats gh pr create), the materialized report generator on synthetic evidence (DETERMINISTIC-vs-claude-print rows, a json sibling, and a missing-evidence row rendering `unverified` never a false pass), the gitignore posture (reports/ ignored except a tracked EXAMPLE.md), and the auth gate via fake claude stubs (no key + not-logged-in skips; ANTHROPIC_API_KEY takes the api-key path with no probe; a logged-in-but-probe-401 skips rather than false-pass; a logged-in + probe-ok takes the claude-login path). The REAL /CJ_goal_task run is a LOCAL manual E2E, not asserted here."
  - id: test-test-run
    family: test
    label: "test-run suite — runners: axis grammar + test-run.sh engine (fixture repos)"
    anchor: "tests/test-run.test.sh"
    source: scripts/test.sh
    layer: ci
    disposition: hard-fail
    trigger: "pr-ci"
    purpose: "The runners: axis + scripts/test-run.sh engine against TEMP-DIR fixture registries (never the real test.sh — a recursion trap): --validate accepts a well-formed runners: axis and rejects each violation (duplicate id, bad tier/platform, empty command, unknown covers family, explicit ci/hook in covers); --list-runners + --list-units --with-family emit the machine-readable forms; the --dry-run plan prints per-runner decisions + uncovered-family/ci-only/hook lines; tier gating (free default; --evals/--e2e/--all widen; unselected = tier-not-selected); the platform guard; rc->outcome mapping with aggregate {pass, fail, all-skipped} (fail => exit 1, all-skipped NEVER pass); self-gate detection (first-line ^SKIP: only); ledger fields (schema 1, timestamp, HEAD sha, repo root, flags, aggregate, per-runner + ci/hook family rows); the absent/invalid/zero-runners edge paths (no report on the last two); and covers: all expansion. ALSO the additive category-mode selection: --category <workflow|CI> + single-test-NAME runs reusing the docs/tests name, tier-gated (paid/local-only skip on the default free tier), --category+name mutual-exclusion + unknown-name exit 2, the mode: category ledger, additivity of the runners: flow when neither --category nor a name is passed, and the inactive-when-no-categories note."
  - id: test-setup-hooks
    family: test
    label: "setup-hooks suite — git hook installer"
    anchor: "tests/setup-hooks.test.sh"
    source: scripts/test.sh
    layer: ci
    disposition: hard-fail
    trigger: "pr-ci"
    purpose: "The installed post-merge hook re-deploys skills without mutating trackers; hook install is clobber-safe."
  - id: test-drain-one-todo-worktree-resolve
    family: test
    label: "drain-one-todo suite — deployed-path resolution"
    anchor: "tests/drain-one-todo-worktree-resolve.test.sh"
    source: scripts/test.sh
    layer: ci
    disposition: hard-fail
    trigger: "pr-ci"
    purpose: "A deployed drain helper resolves the worktree-init helper via the manifest source path."
  - id: test-drain-one-todo-helper-unavailable
    family: test
    label: "drain-one-todo suite — unreachable-helper fail-loud"
    anchor: "tests/drain-one-todo-helper-unavailable.test.sh"
    source: scripts/test.sh
    layer: ci
    disposition: hard-fail
    trigger: "pr-ci"
    purpose: "The drain halts loudly when the worktree helper is unreachable instead of scaffolding in place."
  - id: test-cj-document-release
    family: test
    label: "cj-document-release suite — doc-release skill structure"
    anchor: "tests/cj-document-release.test.sh"
    source: scripts/test.sh
    layer: ci
    disposition: hard-fail
    trigger: "pr-ci"
    purpose: "Doc-release skill structure, frontmatter, halt markers and config-helper assertions."
  - id: test-cj-document-release-config
    family: test
    label: "doc-release config suite — doc registry + helper + seed"
    anchor: "tests/cj-document-release-config.test.sh"
    source: scripts/test.sh
    layer: ci
    disposition: hard-fail
    trigger: "pr-ci"
    purpose: "Doc registry table shape, every doc-spec helper subcommand, strict no-config gates (malformed table row, no-table registry), and the byte-identical embedded seed."
  - id: test-cj-goal-doc-sync-wiring
    family: test
    label: "goal doc-sync wiring suite — symmetric step wiring"
    anchor: "tests/cj-goal-doc-sync-wiring.test.sh"
    source: scripts/test.sh
    layer: ci
    disposition: hard-fail
    trigger: "pr-ci"
    purpose: "The doc-sync step and halt-taxonomy rows are present and correctly ordered in the goal orchestrators."
  - id: test-cj-goal-pr-body-splice-guard
    family: test
    label: "goal PR-body splice guard suite — no multi-line awk -v payload idiom"
    anchor: "tests/cj-goal-pr-body-splice-guard.test.sh"
    source: scripts/test.sh
    layer: ci
    disposition: hard-fail
    trigger: "pr-ci"
    purpose: "No executable line in any of the four cj_goal pipeline.md passes a multi-line shell payload through awk -v; only the safe --body-file filename idiom and the warning comments remain, and each file keeps its gh pr edit --body-file splice."
  - id: test-post-land-sync
    family: test
    label: "post-land-sync suite — post-merge local sync helper"
    anchor: "tests/post-land-sync.test.sh"
    source: scripts/test.sh
    layer: ci
    disposition: hard-fail
    trigger: "pr-ci"
    purpose: "Sync-helper guards refuse a bad source checkout; dry-run previews without mutating the live home."
  - id: test-cj-goal-common-sync
    family: test
    label: "goal-common sync suite — pre-build skills-sync phase"
    anchor: "tests/cj-goal-common-sync.test.sh"
    source: scripts/test.sh
    layer: ci
    disposition: hard-fail
    trigger: "pr-ci"
    purpose: "Dry-run, opt-out, guard-refusal and real-run paths of the pre-build sync phase all emit the four-key schema, fail-soft and hermetic."
  - id: test-cj-goal-common-recap
    family: test
    label: "goal-common recap suite — land/PR 3-part recap formatter"
    anchor: "tests/cj-goal-common-recap.test.sh"
    source: scripts/test.sh
    layer: ci
    disposition: hard-fail
    trigger: "pr-ci"
    purpose: "The --phase recap pure formatter renders all three labelled sections, switches the header on --when before|after, is fail-soft on a missing field, and prints --field content verbatim (no eval)."
  - id: test-cj-id-claim
    family: test
    label: "cj-id-claim suite — atomic work-item ID claim"
    anchor: "tests/cj-id-claim.test.sh"
    source: scripts/test.sh
    layer: ci
    disposition: hard-fail
    trigger: "pr-ci"
    purpose: "Concurrent-race uniqueness, both reap modes, prefix isolation, same-branch reuse and worktree-shared claim-root resolution."
  - id: test-cj-goal-feature-smoke
    family: test
    label: "feature-path smoke suite — worktree entry + common phases"
    anchor: "tests/cj-goal-feature-smoke.test.sh"
    source: scripts/test.sh
    layer: ci
    disposition: hard-fail
    trigger: "pr-ci"
    purpose: "Feature-caller worktree entry, the shared helper's worktree/ship/telemetry phases, and leaf dispatch targets present on disk."
  - id: test-doc-spec-overlay
    family: test
    label: "doc-spec overlay suite — two-tier merge semantics"
    anchor: "tests/doc-spec-overlay.test.sh"
    source: scripts/test.sh
    layer: ci
    disposition: hard-fail
    trigger: "pr-ci"
    purpose: "Overlay merge semantics, the duplicate-path guard, merged list subcommands, seed-equals-general-file byte identity, and the --check-on-disk Stage-1 battery (clean fixture: five checks PASS / CHECKS_RUN=5; seeded violations each isolated to its own stage1/<id> finding, including the docs/workflows/ recursed orphan and the registry-gated workflows-subfolder mandate; registry-absent REGISTRY=absent skip; invalid-registry halt)."
  - id: test-test-spec
    family: test
    label: "test-spec suite — two-tier registry parser + coverage drills"
    anchor: "tests/test-spec.test.sh"
    source: scripts/test.sh
    layer: ci
    disposition: hard-fail
    trigger: "pr-ci"
    purpose: "Merged-registry parser round-trip, the absent-vs-invalid split, malformed fixtures, the units-gated floor note, seed emission, and the temp-dir coverage drift drills. ALSO the additive category axis (Section 10): --list-categories (+ --names/--category filters) with pre-existing-subcommand additivity, --seed carrying the category prose, --check-structure's five a-e checks (findings-not-crash; folders derived from the distinct declared categories) + --seed-docs idempotency + stale-INDEX refresh + inactive-when-no-axis, and the closed {workflow, CI-push, CI-nightly} V2 category-enum HALT."
  - id: test-cj-audit-skills
    family: test
    label: "audit-skills suite — seed delivery + audit engines"
    anchor: "tests/cj-audit-skills.test.sh"
    source: scripts/test.sh
    layer: ci
    disposition: hard-fail
    trigger: "pr-ci"
    purpose: "Bare-repo seed delivery for both audit skills, second-run idempotence, engine-flagged seeded-violation findings (stage1/ prefixes), the per-stage report contract on both SKILL.mds plus qa.md's block template, the planted-drift stage3 cross-walk drill, and the clean workbench baseline."
  - id: test-doc-spec-reconcile
    family: test
    label: "doc-spec reconcile suite — classify + legacy->canonical migration"
    anchor: "tests/doc-spec-reconcile.test.sh"
    source: scripts/test.sh
    layer: ci
    disposition: hard-fail
    trigger: "pr-ci"
    purpose: "doc-spec.sh --classify labeling the four generations (absent/canonical/legacy/duplicate, plus malformed-not-legacy), --reconcile migrating a 40+-row legacy YAML fixture to the canonical Markdown table preserving every row (atomic + .bak + idempotent), the audit_class asymmetry guard (RECONCILE-WARN), the malformed-file no-clobber halt, and the live-workbench canonical-no-reconcile-noise baseline."
  - id: test-test-spec-reconcile
    family: test
    label: "test-spec reconcile suite — symmetric classify + dedup/no-op"
    anchor: "tests/test-spec-reconcile.test.sh"
    source: scripts/test.sh
    layer: ci
    disposition: hard-fail
    trigger: "pr-ci"
    purpose: "test-spec.sh --classify labeling absent/canonical/duplicate/malformed (never legacy — the fenced-yaml format never diverged), --reconcile as a dedup/no-op (canonical clean no-op, duplicate reports the redundant copy with no auto-delete, malformed halts), and the live-workbench canonical-no-reconcile-noise baseline."
  - id: test-test-spec-render
    family: test
    label: "test-spec render suite — generated catalog renderer + freshness primitive"
    anchor: "tests/test-spec-render.test.sh"
    source: scripts/test.sh
    layer: ci
    disposition: hard-fail
    trigger: "pr-ci"
    purpose: "The --render-docs renderer emits a deterministic (render-twice byte-identical), work-item-ID-free generated test catalog from the merged registry, and --render-docs --check exits zero on a fresh render and non-zero after a hand-edit — the freshness primitive behind validate.sh Check 26."
  - id: test-workflow-spec-render
    family: test
    label: "workflow-spec render suite — generated workflow-docs renderer + freshness primitive + no-vanish drill + CRLF-jq drill"
    anchor: "tests/workflow-spec-render.test.sh"
    source: scripts/test.sh
    layer: ci
    disposition: hard-fail
    trigger: "pr-ci"
    purpose: "The --render-docs renderer emits a deterministic (render-twice byte-identical), work-item-ID-free generated workflow surface from spec/workflow-spec.md; --render-docs --check exits zero on a fresh render and non-zero after a hand-edit or a missing file; a remove-an-entry drill proves workflow-spec.sh --validate registry-completeness fails closed (the no-vanish guarantee behind validate.sh Check 27 + the retired Check 15c); and a CRLF-jq drill (a PATH-prepended jq shim appending CR to every output line) proves --list-orchestrators and --validate stay green under a Windows CRLF-emitting jq — no registry-completeness false-halt."
  - id: test-seed-contracts
    family: test
    label: "seed-contracts suite — forced contract seeding + stale-engine probe + data-loss guard"
    anchor: "tests/seed-contracts.test.sh"
    source: scripts/test.sh
    layer: ci
    disposition: hard-fail
    trigger: "pr-ci"
    purpose: "skills-deploy seed-contracts force-seeds the three contracts (doc-spec/test-spec/workflow-spec) into a consumer repo corruption-guarded (--seed → non-empty + --validate-clean → mv) and idempotent (present⇒skip); the workbench self-repo is detected (manifest-source match OR custom-overlay presence) and SKIPPED so its authored spec/*.md are never overwritten with skeletons (the data-loss guard); and the stale-engine capability probe detects a vendored repo-local engine lacking --classify, falls back to _cj-shared, and emits stage1/engine-stale (the actual stale-engine-shadow bug fix)."
  - id: test-cj-contract-gate
    family: test
    label: "cj-contract-gate suite — deterministic Stage-1 contract gate + guarded consumer hook install"
    anchor: "tests/cj-contract-gate.test.sh"
    source: scripts/test.sh
    layer: ci
    disposition: hard-fail
    trigger: "pr-ci"
    purpose: "scripts/cj-contract-gate.sh (the engine-only Stage-1 subset of validate.sh, agent-free) PASSes on a clean fully-adopted contract and hard-FAILS (exit non-zero) on a planted violation (a stale generated catalog OR a malformed registry); a missing DECLARED doc is a SOFT remediation pointing at /CJ_document-release (exit 0 — never a block) and an unadopted contract (REGISTRY=absent) is a clean SKIP; and the guarded consumer pre-commit auto-install (skills-deploy install-contract-gate, reusing the shared cj-hook-lib.sh install_hook safety) installs a sentinel hook resolving the gate from _cj-shared (idempotent re-run), SKIPS a custom core.hooksPath (husky) and the workbench self-repo, and --remove uninstalls ONLY a sentinel hook while a non-workbench hook is left untouched."
  - id: test-workflow-coverage
    family: test
    label: "workflow-coverage suite — the level:workflow gate + 6th-column parser + --list-orchestrators"
    anchor: "tests/workflow-coverage.test.sh"
    source: scripts/test.sh
    layer: ci
    disposition: hard-fail
    trigger: "pr-ci"
    purpose: "test-spec.sh --check-workflow-coverage is green from birth on the live tree and FAILS hermetically on a forward miss (a 5th orchestrator with no level:workflow behavior), a reverse orphan (an undeclared workflow: value via the enum-check, and an empty workflow: field via the gate's own reverse arm), while a consumer-absent registry SKIPs (REGISTRY=absent / inactive + exit 0); the 6th `workflow` behaviors-TSV column round-trips with the `-` placeholder unwrap (positional $1-only consumers unaffected) and --validate enum-checks workflow: ONLY on level:workflow rows against workflow-spec.sh --list-orchestrators; the gate behind validate.sh Check 28."
  # ---- test family: inline scripts/test.sh families (banner-anchored) ----
  - id: testsh-validate-rerun
    family: test
    label: "Inline — full validator re-run"
    anchor: "=== Running validate.sh ==="
    source: scripts/test.sh
    layer: ci
    disposition: hard-fail
    trigger: "pr-ci"
    purpose: "Runs the whole validator inside the test suite so every check gates the test run too."
  - id: testsh-harness-guards
    family: test
    label: "Inline — harness-principle regression guards"
    anchor: "# === F000053/S000093: trajectory-QA regression guards ==="
    source: scripts/test.sh
    layer: ci
    disposition: hard-fail
    trigger: "pr-ci"
    purpose: "Static guards that the trajectory-QA, permission-policy and within-phase-receipt fixes stay in place."
  - id: testsh-catalog-smoke
    family: test
    label: "Inline — catalog + frontmatter + doc-triplet smoke"
    anchor: "Checking for duplicate skill names..."
    source: scripts/test.sh
    layer: ci
    disposition: hard-fail
    trigger: "pr-ci"
    purpose: "No duplicate skill names; SKILL.md frontmatter parses; doc triplets carry their required sections."
  - id: testsh-advisory-generators
    family: test
    label: "Inline — advisory-script crash + generator idempotency"
    anchor: "Smoke-testing advisory scripts..."
    source: scripts/test.sh
    layer: ci
    disposition: hard-fail
    trigger: "pr-ci"
    purpose: "Doctor, lint and deps scripts run without crashing; the README generator is idempotent (temp-only)."
  - id: testsh-skill-creation-integration
    family: test
    label: "Inline — manual skill-creation integration cycle"
    anchor: "Integration test: manual skill creation cycle..."
    source: scripts/test.sh
    layer: ci
    disposition: hard-fail
    trigger: "pr-ci"
    purpose: "A scaffolded temp skill keeps the validator green; plant-and-restore negatives prove the doc checks actually fire."
  - id: testsh-goal-common-phases
    family: test
    label: "Inline — goal-common phase integration"
    anchor: "Integration test (F000045 / S000081): --phase sync end-to-end"
    source: scripts/test.sh
    layer: ci
    disposition: hard-fail
    trigger: "pr-ci"
    purpose: "Sync and task-worktree phases of the shared goal helper, end-to-end and hermetic."
  - id: testsh-template-content
    family: test
    label: "Inline — template content + validator portability + orphan negatives"
    anchor: "Checking tracker template content..."
    source: scripts/test.sh
    layer: ci
    disposition: hard-fail
    trigger: "pr-ci"
    purpose: "Tracker templates carry required sections; the workflow validator stands alone; orphan-directory detection fires."
  - id: testsh-regression-battery
    family: test
    label: "Inline — defect and story regression battery"
    anchor: "Regression test (D000005): Windows jq CRLF wrapper present..."
    source: scripts/test.sh
    layer: ci
    disposition: hard-fail
    trigger: "pr-ci"
    purpose: "Shipped defect and story fixes stay fixed: CRLF wrappers, the merge-convention guard, template sync, copy-mode fallback and more."
  - id: testsh-copilot-bundle
    family: test
    label: "Inline — Copilot bundle coverage + round-trip"
    anchor: "Checking S000010 bundle-artifact-completeness coverage..."
    source: scripts/test.sh
    layer: ci
    disposition: hard-fail
    trigger: "pr-ci"
    purpose: "Bundle completeness coverage, the instructions size budget and the deploy round-trip."
  - id: testsh-todos-append-guard
    family: test
    label: "Inline — backlog append POSIX-clean guard"
    anchor: "Checking CJ_improve-queue append path keeps TODOS.md POSIX-clean..."
    source: scripts/test.sh
    layer: ci
    disposition: hard-fail
    trigger: "pr-ci"
    purpose: "The improve-queue append path keeps the backlog file POSIX-clean."
  - id: testsh-version-queue-smoke
    family: test
    label: "Inline — version-queue preflight smoke"
    anchor: "Smoke-testing scripts/check-version-queue.sh..."
    source: scripts/test.sh
    layer: ci
    disposition: hard-fail
    trigger: "pr-ci"
    purpose: "The version-queue preflight runs read-only and degrades cleanly when offline."
  - id: testsh-handoff-gate
    family: test
    label: "Inline — handoff-gate deterministic suite"
    anchor: "=== F000026: scripts/cj-handoff-gate.sh deterministic tests ==="
    source: scripts/test.sh
    layer: ci
    disposition: hard-fail
    trigger: "pr-ci"
    purpose: "Denylist hits, size caps, rename/symlink/test-weakening detection and the QA predicate of the deterministic handoff gate."
  - id: testsh-static-wiring
    family: test
    label: "Inline — static wiring checks"
    anchor: "Checking S000078 portable POSIX runtime"
    source: scripts/test.sh
    layer: ci
    disposition: hard-fail
    trigger: "pr-ci"
    purpose: "Portable POSIX runtime idioms, registered-doc audit wiring, defect tracker promotion and the workflow-doc Touches blocks."
  - id: testsh-portability-fixture
    family: test
    label: "Inline — portability-engine hermetic fixture"
    anchor: "Integration test (F000047 / S000083): cj-portability-audit.sh engine fixture..."
    source: scripts/test.sh
    layer: ci
    disposition: hard-fail
    trigger: "pr-ci"
    purpose: "The portability-audit engine's verdicts against a controlled fixture catalog."
  - id: testsh-install-clone
    family: test
    label: "Inline — install equals clone integration battery"
    anchor: "Integration test (F000049 / S000085): shared-scripts self-containment..."
    source: scripts/test.sh
    layer: ci
    disposition: hard-fail
    trigger: "pr-ci"
    purpose: "Shared-script self-containment, bundle install, develop-in-place and the in-place install-equals-clone contract."
  - id: testsh-test-spec-guards
    family: test
    label: "Inline — test-spec registry + coverage guards"
    anchor: "# === F000060: test-spec registry + coverage guards ==="
    source: scripts/test.sh
    layer: ci
    disposition: hard-fail
    trigger: "pr-ci"
    purpose: "The test-spec parser validates the merged registry, the coverage cross-check passes on the live tree, and an absent registry classifies as inactive rather than a finding."
  # ---- standalone suites (wrapper blocks in test.sh share these rows) ----
  - id: suite-test-deploy
    family: test-deploy
    label: "skills-deploy suite — install/doctor/remove in isolation"
    anchor: "scripts/test-deploy.sh"
    source: scripts/test.sh
    layer: ci
    disposition: hard-fail
    trigger: "pr-ci manual"
    purpose: "Template ownership, drift overwrite, copy-mode fallback, shared-script orphan pruning (manifest-keyed, ownership-safe), and doctor verdicts (incl. the shared-scripts health section) in isolated temp homes; runs inside the test suite (via scripts/test.sh) and by hand — its standalone Windows run moved to the nightly windows-nightly.yml (owned by ci-windows-nightly)."
  - id: suite-eval
    family: eval
    label: "behavioral eval harness — headless skill evals"
    anchor: "scripts/eval.sh"
    source: .github/workflows/eval-nightly.yml
    layer: ci
    disposition: hard-fail
    trigger: "nightly manual"
    purpose: "Spawns the headless CLI against scratch worktrees per eval case with JSON-schema output validation; budget-capped per case and per run."
  - id: suite-windows-smoke
    family: windows-smoke
    label: "Windows smoke — CRLF + portable date + copy-mode"
    anchor: "scripts/windows-smoke.sh"
    source: scripts/test.sh
    layer: ci
    disposition: hard-fail
    trigger: "pr-ci push-main manual"
    purpose: "Git Bash portability assertions: CRLF tolerance, portable date math, copy-mode install and the in-place install stamp."
  # ---- ci family: GitHub Actions workflows ----
  - id: ci-validate
    family: ci
    label: "validate workflow — PR gate"
    anchor: "name: Validate Skills"
    source: .github/workflows/validate.yml
    layer: ci
    disposition: hard-fail
    trigger: "pr-ci"
    purpose: "Runs the validator, the full test suite and shellcheck on every pull request."
  - id: ci-windows
    family: ci
    label: "windows workflow — Git Bash smoke gate"
    anchor: "name: Windows (Git Bash)"
    source: .github/workflows/windows.yml
    layer: ci
    disposition: hard-fail
    trigger: "pr-ci push-main"
    purpose: "Runs the fast Windows smoke (windows-smoke.sh) under Git Bash on every pull request and push to main — the CI-push cadence; the slow skills-deploy suite moved to the nightly workflow."
  - id: ci-windows-nightly
    family: ci
    label: "windows-nightly workflow — nightly skills-deploy suite"
    anchor: "name: Windows Nightly (skills-deploy suite)"
    source: .github/workflows/windows-nightly.yml
    layer: ci
    disposition: hard-fail
    trigger: "nightly manual"
    purpose: "Runs the full skills-deploy suite (test-deploy.sh) on windows-latest under Git Bash on a nightly schedule, with a manual dispatch trigger — the CI-nightly cadence windows-deploy test."
  - id: ci-eval-nightly
    family: ci
    label: "eval-nightly workflow — scheduled evals"
    anchor: "name: Eval Nightly"
    source: .github/workflows/eval-nightly.yml
    layer: ci
    disposition: hard-fail
    trigger: "nightly manual"
    purpose: "Runs the behavioral eval harness on a daily schedule, with a manual dispatch trigger."
  - id: ci-audit-nightly
    family: ci
    label: "audit-nightly workflow — nightly doc/test audit"
    anchor: "name: Audit Nightly"
    source: .github/workflows/audit-nightly.yml
    layer: ci
    disposition: hard-fail
    trigger: "nightly manual"
    purpose: "Runs /CJ_doc_audit + /CJ_test_audit headless (scripts/audit-nightly.sh) on a nightly schedule + manual dispatch, filing findings to the audit-drift GitHub issue — the relocated home of the advisory agent-judged audit, off the CJ_goal_* build hot path (CI-nightly cadence)."
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
    backing: "/CJ_document-release (Step 5.5 doc-sync)"
    checks: "doc drift is folded into the same PR (registry parses; declared docs current)"
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
categories:
  # ---- the categories: axis (F000074; taxonomy V2 F000075): the category-based
  # test contract ----
  # ADDITIVE + optional; the PRIMARY axis of the category model (category ->
  # tests), consumed by /CJ_test_audit (--check-structure) + /CJ_test_run
  # (--category / single-name). Each row: name (unique slug — IS the
  # docs/tests/<category>/<name>.md filename AND the /CJ_test_run argument),
  # category {workflow, CI-push, CI-nightly}, command (how to run it), tier
  # {free, paid, local-only}, optional doc pointer, optional purpose. V2 taxonomy
  # is the closed set {workflow, CI-push, CI-nightly} — the CI category split by
  # cadence (the category name IS the cadence, so --category CI-push /
  # --category CI-nightly is the whole selection API, no new flag). This axis
  # COEXISTS with units:/behaviors:/runners: (their removal + the physical
  # test-script move into tests/<category>/ are a deferred follow-up); the scripts
  # are NOT moved in this PR, so the `command` values point at their current flat
  # paths.
  #
  # workflow — deterministic end-to-end workflow tests (what proves a whole
  #            user-facing workflow runs): the cj_goal eval cases + the local
  #            happy-path E2E harness.
  - name: goal-task-eval
    category: workflow
    command: "bash scripts/eval.sh CJ_goal_task"
    tier: paid
    doc: "docs/tests/workflow/goal-task-eval.md"
    purpose: "The /CJ_goal_task workflow eval — drives the task orchestrator through a real gstack-independent path (task -> halted_at_too_complex)."
  - name: e2e-local
    category: workflow
    command: "CJ_E2E_LOCAL=1 bash scripts/e2e-local.sh"
    tier: local-only
    doc: "docs/tests/workflow/e2e-local.md"
    purpose: "The local happy-path E2E harness — a real /CJ_goal_task build in a throwaway sandbox, driven through the build gates to the /ship boundary."
  # CI-push — deploy-gate tests that run on EVERY push / PR (the fast merge
  #           signal): the validator, the full behavioral suite, the deploy-install
  #           suite, and the Windows Git Bash smoke.
  - name: validate
    category: CI-push
    command: "bash scripts/validate.sh"
    tier: free
    doc: "docs/tests/CI-push/validate.md"
    purpose: "The repo validator (the ci layer): all numbered + error + warning checks against the catalog, docs, and spec family."
  - name: suite
    category: CI-push
    command: "bash scripts/test.sh"
    tier: free
    doc: "docs/tests/CI-push/suite.md"
    purpose: "The full behavioral test suite — runs validate.sh, every registered tests/*.test.sh sub-suite, test-deploy.sh, and windows-smoke.sh."
  - name: test-deploy
    category: CI-push
    command: "bash scripts/test-deploy.sh"
    tier: free
    doc: "docs/tests/CI-push/test-deploy.md"
    purpose: "The skills-deploy end-to-end suite in isolated temp dirs (install / remove / relink / doctor / drift) — the POSIX-host push-cadence run."
  - name: windows
    category: CI-push
    command: "bash scripts/windows-smoke.sh"
    tier: free
    doc: "docs/tests/CI-push/windows.md"
    purpose: "The Windows Git Bash portability smoke (copy-mode install, in-place stamp, _cj-shared update-check resolution) — the fast per-PR Windows signal."
  # CI-nightly — deploy-gate tests deferred to a nightly schedule (heavier checks
  #              off the PR path): the Windows-native skills-deploy suite.
  - name: windows-deploy
    category: CI-nightly
    command: "bash scripts/test-deploy.sh"
    tier: free
    doc: "docs/tests/CI-nightly/windows-deploy.md"
    purpose: "The skills-deploy end-to-end suite on windows-latest, run nightly (windows-nightly.yml) — same script as the push-cadence test-deploy, but a distinct CI context (platform + cadence); locally it runs on the host platform (no platform: field yet)."
```
