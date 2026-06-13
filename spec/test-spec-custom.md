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
| Warning check — orphan doc directories | Flags per-skill doc directories with no matching catalog entry. |
| Warning check 3 — orphan template files | Flags template files not referenced by any catalog entry. |
| portability audit — declared-vs-actual skill dependency lint | The engine behind Check 18 and the strict pre-ship gate. |

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
| goal-common portability suite — pre-ship portability gate | Clean catalog passes, dry-run runs nothing, dishonest declaration yields findings. |
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
| Inline — goal-common phase integration | Sync, portability-audit and task-worktree phases end-to-end and hermetic. |
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
| windows workflow — Git Bash gate | Runs the Windows smoke and skills-deploy suite under Git Bash on PR + push-main. |
| eval-nightly workflow — scheduled evals | Runs the behavioral eval harness daily, with a manual dispatch trigger. |

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
| 50 | qa-audit | all four | operator declines the post-sync audit findings |
| 60 | portability | all four | a skill lies about its portability tier |
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
  its 15a/15b sub-assertions are described in that row's `purpose` (they
  exist only as bare comments).
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
(`--validate | --list-rules | --list-units | --list-layers | --list-gates |
--check-coverage | --seed`), an awk-only reader; it resolves the general
registry `spec/test-spec.md` first, then a root `test-spec.md` fallback, and
this overlay next to it. `--validate` additionally lints every `label` +
`purpose` for the work-item-ID pattern, so an ID slip fails at the registry.

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

## Machine registry (overlay)

```yaml
# test-spec custom overlay (units + gates merged into spec/test-spec.md by
# scripts/test-spec.sh; consumed by validate.sh Check 24 --check-coverage +
# the advisory per-mode marker-drift cross-check)
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
    label: "Check 15 — doc registry declared matches on-disk + workflow doc completeness"
    anchor: "=== Check 15:"
    source: scripts/validate.sh
    layer: ci
    disposition: hard-fail
    trigger: "pre-commit pr-ci"
    purpose: "15a: every declared doc exists and every doc under docs/ and spec/ is declared (no orphans); 15b: the workflow doc carries a charted section plus a four-bullet Touches block per goal orchestrator."
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
    disposition: advisory
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
    purpose: "The portability engine behind the advisory audit check and the strict pre-ship orchestrator gate: each skill's declared portability matches its actual executed dependencies; the clean baseline is the ratchet."
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
  - id: test-cj-goal-common-portability
    family: test
    label: "goal-common portability suite — pre-ship portability gate"
    anchor: "tests/cj-goal-common-portability.test.sh"
    source: scripts/test.sh
    layer: ci
    disposition: hard-fail
    trigger: "pr-ci"
    purpose: "A clean catalog passes, dry-run runs nothing, a dishonest declaration yields findings, and an absent engine skips fail-soft."
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
    purpose: "Overlay merge semantics, the duplicate-path guard, merged list subcommands, seed-equals-general-file byte identity, and the --check-on-disk Stage-1 battery (clean fixture; four seeded violations each isolated to its own stage1/<id> finding; registry-absent REGISTRY=absent; invalid-registry halt)."
  - id: test-test-spec
    family: test
    label: "test-spec suite — two-tier registry parser + coverage drills"
    anchor: "tests/test-spec.test.sh"
    source: scripts/test.sh
    layer: ci
    disposition: hard-fail
    trigger: "pr-ci"
    purpose: "Merged-registry parser round-trip, the absent-vs-invalid split, malformed fixtures, the units-gated floor note, seed emission, and the temp-dir coverage drift drills."
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
    purpose: "Sync, portability-audit and task-worktree phases of the shared goal helper, end-to-end and hermetic."
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
    trigger: "pr-ci push-main manual"
    purpose: "Template ownership, drift overwrite, copy-mode fallback and doctor verdicts in isolated temp homes; runs inside the test suite, in the Windows workflow, and by hand."
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
    label: "windows workflow — Git Bash gate"
    anchor: "name: Windows (Git Bash)"
    source: .github/workflows/windows.yml
    layer: ci
    disposition: hard-fail
    trigger: "pr-ci push-main"
    purpose: "Runs the Windows smoke and the skills-deploy suite under Git Bash on every pull request and push to main."
  - id: ci-eval-nightly
    family: ci
    label: "eval-nightly workflow — scheduled evals"
    anchor: "name: Eval Nightly"
    source: .github/workflows/eval-nightly.yml
    layer: ci
    disposition: hard-fail
    trigger: "nightly manual"
    purpose: "Runs the behavioral eval harness on a daily schedule, with a manual dispatch trigger."
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
  # --- universal, same marker in all four: doc-sync runs BEFORE the qa-audit
  #     checkpoint (F000064 reorder), so the checkpoint decides on post-sync docs ---
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
  # --- universal, same marker in all four: the post-sync audit-findings checkpoint ---
  - id: qa-audit
    layer: pipeline-gate
    order: 50
    markers:
      feature: "[qa-audit-declined]"
      defect:  "[qa-audit-declined]"
      task:    "[qa-audit-declined]"
      todo:    "[qa-audit-declined]"
    disposition: halt
    backing: "orchestrator-level post-sync /CJ_doc_audit + /CJ_test_audit (one combined read-only subagent, run AFTER doc-sync) + the checkpoint AUQ"
    checks: "the operator saw the post-sync doc/test audit findings before the PR budget was spent"
  # --- universal, same marker in all four ---
  - id: portability
    layer: pipeline-gate
    order: 60
    markers:
      feature: "[portability-red]"
      defect:  "[portability-red]"
      task:    "[portability-red]"
      todo:    "[portability-red]"
    disposition: halt
    backing: "cj-goal-common.sh --phase portability-audit (PORTABILITY_STRICT=1)"
    checks: "no touched skill declares a portability tier it does not honor"
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
```
