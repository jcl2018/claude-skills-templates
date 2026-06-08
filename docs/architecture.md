# Architecture

Mechanism reference for the workbench's load-bearing layers. Pair with
[philosophy.md](philosophy.md) — that doc explains *why* this workbench exists
and which `CJ_` skill to call; this doc explains *how* the mechanisms underneath
those skills work. Most layers below are Claude-side; the final section documents
the parallel **GitHub Copilot** delivery surface (`work-copilot/`).

## The shared cj-goal-common.sh helper

`scripts/cj-goal-common.sh` is the deterministic helper consumed by the
intent-named front doors (`/CJ_goal_feature`, `/CJ_goal_defect`,
`/CJ_goal_todo_fix`). It absorbs the phases that don't need per-skill prose:
worktree management, PR-check polling, telemetry writes, post-run worktree
cleanup, and the pre-ship portability gate.

**Phases it owns:**

- **worktree** — auto-creates `.claude/worktrees/cj-{feat|def|todo}-<ts>-<pid>/`
  when invoked from `main` with arguments, no-ops inside an existing
  managed worktree, and exposes `--assert-isolated` so each orchestrator's
  isolation gate can refuse to proceed on a dirty working tree. **Base-freshness:**
  inside `cj-worktree-init.sh`, just before `git worktree add`, when on
  `main`/`master` with an existing `origin/<branch>` ref, the helper fail-soft
  fetches + fast-forwards local `main` to the origin tip so the new worktree
  branches off current trunk. Outcome rides the `note` field of the `created`
  emit (`ff'd N commits` / `local main diverged from origin; building on local
  main` / `freshness skipped (offline)`); never halts; skipped under `--dry-run`.
- **sync** — pre-build skills-sync. Delegates to `post-land-sync.sh`'s guarded
  pull+install core so installed skills match trunk at build start. The
  orchestrator runs `--phase sync` BEFORE the worktree block. Fail-soft exactly
  like `pr-check`: a guard refusal (off-main / dirty tracked tree) or an offline
  pull emits `PHASE_RESULT=skipped` (exit 0), never failed. `--no-sync`
  short-circuits to `skipped` before any install (base-freshness still runs);
  `--dry-run` forwards to `post-land-sync.sh --dry-run`. Under install==clone the
  checkout this pulls IS the in-place checkout (`install_mode: in-place`, `source`
  == `bundle_path`); the sync is reframed onto that one checkout — kept, not
  retired, because a remote `gh pr merge` still needs a post-merge pull.
- **pr-check** — polls `gh pr view` for the merge state of an open PR, captures
  the PR URL into the per-branch state file, and produces a deterministic
  `next_action=` / `resume_cmd=` / `pr_url=` line that the orchestrator can drop
  directly into its journal entry.
- **telemetry** — appends a single JSONL line per run to
  `~/.gstack/analytics/<skill>.jsonl` (one file per front door).
- **cleanup** — at each orchestrator's post-land terminal, sweeps *landed*
  `cj-(feat|def|todo)-*` worktrees (removed only when their PR reads
  MERGED/CLOSED via the `pr-check` phase — not by branch ancestry, which a squash
  merge breaks), runs `git worktree prune`, and switches the root checkout back
  to `main` and pulls it. Strictly best-effort — it never halts the run.
  Delegates to the teardown-mirror helper `scripts/cj-worktree-cleanup.sh`;
  `/CJ_goal_todo_fix` calls that helper directly rather than through this phase.
- **portability-audit** — the pre-ship portability gate. After the
  Step 5.5 doc-sync handler and immediately before `/ship`, each orchestrator
  runs `--phase portability-audit`, which resolves the engine via
  `resolve_portability_engine()` (sibling-in-scriptdir -> manifest `.source`,
  the `resolve_worktree_helper` idiom), runs `scripts/cj-portability-audit.sh`
  under `PORTABILITY_STRICT=1`, and classifies the result into
  `ok` / `findings` / `skipped`. Unlike `sync` / `pr-check` it is NOT fully
  fail-soft: a real finding (`PHASE_RESULT=findings`) HALTS the run with
  `[portability-red]` / `halted_at_portability` BEFORE any PR is created; an
  engine-absent result (`PHASE_RESULT=skipped` — a broken install, not a
  finding) prints a visible note and continues. On `ok` the clean
  `VERDICT_LINE` is spliced into the PR body's `## Documentation` section
  alongside the registered-doc verdicts. The catalog baseline is clean, so the
  gate is green today and a free regression ratchet. This is cj_goal-scoped
  enforcement; `validate.sh` Check 18 stays advisory globally.

**Modes it dispatches on:**

- **feature** — paired with `/CJ_goal_feature` (build a feature: topic ->
  reviewable PR). Stops at the PR; deploy is a separate human step.
- **defect** — paired with `/CJ_goal_defect` (fix a bug: description -> shipped
  fix). Runs `/investigate` as a depth-<=2 leaf subagent and only mints a defect
  ID after the Iron-Law gate passes.

The helper is deliberately one shell file, not a directory or a skill. Each phase
is a function the orchestrator sources and calls — there is no second layer of
orchestration. Treat it as plumbing for the front doors.

## Doc-sync (inline Step 5.5 + `/ship` Step 18)

Doc-sync runs INLINE on every common main-moving path, rather than as a
post-merge marker picked up on a later session. There are two inline surfaces:

- **Orchestrator paths** — each `cj_goal` orchestrator folds doc updates into the
  same code PR at **Step 5.5** (`/CJ_document-release`, between the QA pass and
  `/ship`).
- **`/ship` paths** — `/ship` Step 18 dispatches `/document-release` on every
  invocation, after the push and before the PR exists, so a manual `/ship` still
  lands doc updates in the PR.

The one path NOT auto-covered is a main-move that bypasses BOTH the orchestrators
AND `/ship` (a raw `git push` to `main`, or a hand-rolled `gh pr create` + `gh pr
merge`). It is rare and manually recoverable: run `/document-release` by hand from
a feature branch to fold the drift into a follow-up PR.

### The inline doc-sync wrapper (`/CJ_document-release`)

`/CJ_document-release` folds the doc update into the same PR as the code by
running inline at pipeline Step 5.5, between the QA pass and `/ship`. It is a
workbench skill that **wraps** upstream gstack `/document-release` (invoked via
the Skill tool), adding workbench-specific behaviors the upstream skill doesn't
own:

- **`--docs <comma-list>` subset filter** — per-invocation doc subset selection
  (e.g. `--docs README,CHANGELOG`), best-effort via a project-context block.
- **Halt-on-red contract** — an upstream non-green result emits `[doc-sync-red]`
  to the orchestrator's halt taxonomy, so it can stop the pipeline instead of
  barreling into `/ship` with broken docs.
- **Doc-only auto-commit whitelist** — the auto-commit step stages ONLY files in
  the doc-only whitelist; a non-whitelist write HALTs with
  `[doc-sync-non-doc-write]`. The whitelist is **derived from the `doc-spec.md`
  registry** (see below) — there is no separate hand-maintained whitelist file.

Under squash-merges the Step 5.5 inline call and `/ship`'s Step 18 post-push call
are partially redundant for the auto-trigger use case, but the re-run is
idempotent and harmless. The operator-callable surface
(`/CJ_document-release --docs <subset>`) is the other reason the wrapper exists —
point-in-time doc audits on a feature branch outside the `cj_goal` pipeline.

## The doc-spec.md contract + /CJ_document-release

The workbench declares **what docs it carries and what each is for** in one root
file, `doc-spec.md` — both the human-readable map and the machine source of truth
(a fenced `yaml` registry). See [`doc-spec.md`](../doc-spec.md) for the contract
itself; this section is the mechanism reference for how it is parsed, enforced,
and self-healed.

```
                    doc-spec.md (root)
                    +---------------------------+
                    | Common (portable seed)    |
                    | Custom (this repo)        |
                    | ```yaml machine registry``|
                    |  schema_version: 1        |
                    |  docs[]: path / section / |
                    |    audit_class / purpose /|
                    |    requirement            |
                    +-----+---------------+-----+
                          | parses        | parses
            +-------------v---+     +------v--------------------+
            | scripts/        |     | /CJ_document-release      |
            |   validate.sh   |     |  (+ scripts/doc-spec.sh)  |
            | declared <=>    |     |  1. read doc-spec.md      |
            |  on-disk        |     |     (self-bootstrap from  |
            | schema valid    |     |      the Common seed if   |
            | no work-item    |     |      missing)             |
            |  IDs in human   |     |  2. stub-scaffold missing |
            |  docs           |     |     declared docs         |
            +-----------------+     |  3. registered-doc audit  |
                                    |     (+ no-ref for human)  |
                                    |  4. derive whitelist      |
                                    +---------------------------+
```

### The registry schema

The `yaml` block in `doc-spec.md` is the source of truth:

```yaml
schema_version: 1
docs:
  - path: docs/philosophy.md
    section: common          # common | custom
    audit_class: human-doc   # human-doc | operational
    purpose: "..."
    requirement: "..."
```

- **`schema_version`** — must be `1`. Any other value is a hard error.
- **`audit_class`** — closed enum. `human-doc` = human-facing, must exist + carry
  **no work-item IDs** (`[FSTD]NNNNNN`) + ASCII charts preferred (advisory).
  `operational` = must exist, work-item references allowed (CHANGELOG, CLAUDE.md,
  TODOS.md, etc.).
- **`section`** — `common` (portable, byte-identical across adopting repos, seeded
  from `templates/doc-spec-common.md`) or `custom` (repo-specific).

### The doc-spec checks in `scripts/validate.sh`

These are the `validate.sh` checks that enforce the *doc* contract — one slice of
the larger verification story, not "the gate" as a whole. ("Gate" is reserved for
an inline orchestrator halt; see [`gate-spec.md`](../gate-spec.md) and the
[gate-spec.md contract](#the-gate-specmd-contract) section below for the
four-layer map of every verification surface.) The validator parses the registry
and asserts the contract:

- **declared <=> on-disk** — every declared doc exists, AND every `docs/*.md` on
  disk is declared (no orphans).
- **schema** — `doc-spec.md` exists, its `yaml` block parses, `schema_version: 1`,
  every entry has `path` / `section` / `audit_class`, and every `audit_class` is
  in the closed enum.
- **root-docs allowlist** — every root `*.md` on disk must be a declared entry in
  the registry (or it is an un-allowlisted orphan).
- **no work-item IDs in human docs** — for every `audit_class: human-doc` entry,
  the validator greps `[FSTD][0-9]{6}` and ERRORs on any hit. This is the hard
  lint that keeps the human docs human-readable.
- **front-table-required docs open with a table** (Check 20) — for every entry
  flagged `front_table: required` (enumerated via `doc-spec.sh
  --list-front-table-docs`; today `docs/philosophy.md` + `docs/workflow.md`), the
  validator asserts a Markdown table appears BEFORE the doc's first `## ` heading.
  Registry-driven, so flagging a third doc later is a one-line registry edit —
  `docs/architecture.md` is a human-doc but is deliberately NOT flagged, so it is
  exempt, which demonstrates the registry-driven scoping.
- **workflow completeness** — `docs/workflow.md` carries a section for every
  `CJ_goal_*` orchestrator, each with an ASCII chart and a 4-bullet Touches block.

### The helper (`scripts/doc-spec.sh`)

A single bash file owns the parse/derive logic the SKILL.md and validator
consume. Subcommands:

- `--validate` — exit 0 + print `OK schema_version=<n>` if the registry is valid;
  exit 1 + emit `[doc-sync-no-config] <reason>` otherwise.
- `--list-declared` — emit every declared `path` (sorted, unique).
- `--list-human-docs` — emit only the `audit_class: human-doc` paths.
- `--list-front-table-docs` — emit only the paths whose `front_table` is
  `required` (a separate awk pass; the workbench-local field the validator's
  front-table check consumes).
- `--expand-whitelist` — emit the doc-only auto-commit whitelist (every declared
  `path` + `doc-spec.md` + every `docs/**/*.md` on disk; sorted, unique).
- `--seed` — emit the portable Common-section seed (used by the self-bootstrap to
  recreate a missing `doc-spec.md`).

It reads `doc-spec.md` via `git rev-parse --show-toplevel`, so a copy resolved
from the deployed `_cj-shared` home still parses THIS repo's registry — never the
workbench's.

### /CJ_document-release behavior (self-heal + audit)

On every major `cj_goal` run (Step 5.5) or a manual invocation, the wrapper:

1. **Reads `doc-spec.md`.** If it is **missing**, scaffolds it from the portable
   Common seed (`scripts/doc-spec.sh --seed`), commits it, and continues. This is
   the self-bootstrap that lets a fresh repo adopt the contract with no manual
   step.
2. **Stub-scaffolds missing declared docs.** For each declared doc that is
   missing, writes a **stub** (title + a section skeleton its `audit_class`
   implies + a `<!-- TODO: fill in -->` marker), commits it, and records it in the
   audit as `stub — needs content`. Idempotent: a re-run never writes a second
   stub.
3. **Runs the registered-doc audit (ADVISORY — never halts).** Judges each
   declared doc against its `requirement`. For `human-doc` entries it also runs
   the **no-work-item-ref check** (any `[FSTD][0-9]{6}` -> `stale: contains
   work-item refs`). Emits one verdict per doc to the wrapper RESULT and to the
   gitignored scratch file `.cj-goal-feature/registered-doc-verdicts.md`; the
   orchestrators surface that block to the PR body post-`/ship`.
4. **Derives the doc-only whitelist** for the auto-commit gate from the registry
   (`scripts/doc-spec.sh --expand-whitelist`).

### The registered-doc audit, in full

The audit answers the one question the hard gates structurally can't: **is THIS
registered doc up to date against ITS declared requirement?** It generalizes the
shape the workbench already had for USAGE.md (is it up to date vs its requirement,
the SKILL.md?).

**The registered set** is two groups, both enumerated dynamically (no hardcoded
counts):

1. **The registry docs** — every entry in the `doc-spec.md` registry, each
   carrying its `requirement:` value.
2. **The routable skill MDs (active OR experimental)** — every skill returned by
   `jq -r '.[] | select(.status != "deprecated") | select((.files | length) > 0) | .name' skills-catalog.json`
   (the `!= "deprecated"` predicate, deliberately broader than the active-only
   New-skills check, so the audit covers the whole `CJ_` family). Each skill's
   `SKILL.md` is a registered doc; its requirement is the skill's optional
   `doc_requirement` field in `skills-catalog.json`, else the shared default
   below.

**Shared default skill-MD requirement** (when a skill has no `doc_requirement`):

> The SKILL.md frontmatter `description` and the documented behavior/steps match
> the skill's current implementation; the skill's USAGE.md is current.

**Verdict taxonomy** (one per registered doc):

- `up-to-date` — satisfies its requirement given what the run changed.
- `stale: <one-line why>` — no longer satisfies its requirement.
- `missing-requirement` — the registered doc has no declared requirement. SOFT —
  never a halt.
- `n/a` — registered but out of scope for this run's judgment.

The audit is **advisory, agent-judged, never a hard gate**. A registered doc
lacking a requirement gets a soft `missing-requirement` verdict, not a CI error.
The positive line `Registered-doc requirements: all current` is emitted ONLY when
every verdict is `up-to-date`, so reviewers can tell the audit ran cleanly vs
skipped silently.

### Why this step is needed

A remote `gh pr merge` is a **remote** merge. The local post-merge auto-sync hook
only fires on a local `git pull`/`merge`, so a remote merge bypasses it entirely
— a just-merged skill lands on `main` but is NOT installed into `~/.claude/skills/`
until you pull + install. `post-land-sync.sh` is that pull + install in one
correct command (it resolves the in-place checkout, guards it, `git pull
--ff-only`, runs `skills-deploy install`, and reports `collection_version`
before->after). It is a manual operator step + the internal core the `--phase
sync` pre-build fork reuses — not an orchestrator pipeline step.

## The gate-spec.md contract

The workbench declares **what stops a broken cj_goal change from landing, and at
which layer** in one root file, [`gate-spec.md`](../gate-spec.md) — both the
human-readable map (prose + a four-layer summary table + an ASCII diagram + a
division-of-labor) and the machine source of truth (a fenced `yaml` registry of
`layers[]` + `gates[]`). It is the third member of the `doc-spec.md` →
`permission-policy.md` → `gate-spec.md` family: the same shape (a root registry
doc + a `scripts/` reader + an advisory `validate.sh` check) applied to
verification. This section is the mechanism reference; see the file itself for
the contract.

```
                    gate-spec.md (root)
                    +---------------------------+
                    | four-layer map +          |
                    | division-of-labor +       |
                    | ```yaml machine registry``|
                    |  schema_version: 1        |
                    |  layers[]: local-hook|ci| |
                    |    pipeline-gate|ratchet  |
                    |  gates[]: per-mode        |
                    |    `markers` map          |
                    |    ({enforced_by} escape) |
                    +-----+---------------+-----+
                          | parses        | cross-checks
            +-------------v---+     +------v--------------------+
            | scripts/        |     | scripts/validate.sh       |
            |   gate-spec.sh  |     |   Check 22 (advisory)     |
            | --validate      |     |  1. gate-spec.sh          |
            | --list-layers   |     |     --validate exits 0    |
            | --list-gates    |     |  2. per-mode marker drift |
            +-----------------+     |     guard (literal in its |
                                    |     mode's pipeline/SKILL)|
                                    +---------------------------+
```

**The four layers.** A cj_goal change is verified at four independent layers,
each owning a different guarantee: **local-hook** (the pre-commit `validate.sh`,
hard-fail at commit), **ci** (GitHub Actions, hard-fail on the PR),
**pipeline-gate** (the inline orchestrator halts — isolation, design-summary, QA,
doc-sync, portability, ship — during a run), and **ratchet** (monotonic guards:
Check 8 VERSION-never-regresses, the portability `FINDINGS=0` baseline, Check 14
USAGE.md freshness). The contract reserves the word **"gate"** for a single
referent — a `pipeline-gate` row — so `validate.sh`-as-a-whole is the **ci**
layer (a set of *checks*), never "the gate."

**The per-mode `markers` map.** A gate's `markers` is a map keyed by
`feature|defect|task|todo`. A mode absent from the map does not run that gate
(only `doc-sync` + `portability` are universal; isolation has three different
markers and is absent in todo; `design-gate`/`root-cause`/`complexity` are
single-mode). A map value is either a literal `"[marker]"` (Check 22 greps for it
in that mode's files) or `{ enforced_by: subagent | auq }` (the gate runs but
emits no bracket marker — the escape hatch that keeps the baseline honestly
clean, e.g. todo's QA + ship).

### The helper (`scripts/gate-spec.sh`)

A single bash file owns the parse/validate logic, mirroring `scripts/doc-spec.sh`.
Subcommands:

- `--validate` — exit 0 + print `OK schema_version=<n>` if the registry is valid
  (fenced block present, `schema_version: 1`, every gate has
  `id`/`layer`/`order`/`markers`/`disposition`/`backing`, every `layer` and
  `disposition` in its closed enum, every `markers` value a `"[...]"` literal or
  an `{enforced_by: subagent|auq}` escape); exit 1 + emit `[gate-spec-no-config]
  <reason>` otherwise.
- `--list-layers` — emit every declared layer id (sorted, unique).
- `--list-gates` — emit every declared gate id (sorted, unique).

It reads `gate-spec.md` via `git rev-parse --show-toplevel`, like `doc-spec.sh`.
`--list-for <mode>` (an ordered per-mode view) and `--seed` (self-bootstrap
parity) are deferred — no v1 consumer.

### The advisory check (`validate.sh` Check 22)

Structurally a clone of Check 21 (the permission-policy drift check). It asserts
the contract against the live tree: (1) `gate-spec.sh --validate` exits 0; (2) a
per-mode marker drift guard — for every gate, for every mode key in its `markers`
map, a literal `"[marker]"` must appear in at least one of that mode's files
(`skills/CJ_goal_<mode-dir>/pipeline.md` OR `SKILL.md`; mode-dir: feature →
`CJ_goal_feature`, defect → `CJ_goal_defect`, task → `CJ_goal_task`, todo →
`CJ_goal_todo_fix`), while an `{enforced_by: ...}` value is skipped. A missing
literal marker is a finding (the pipeline drifted from the contract, or the
registry is stale). It is **advisory** in v1 — a finding prints but `validate.sh`
exits 0, exactly like Check 21 / Check 18 — because the registry is authored
honestly (per-mode markers + the `enforced_by` escape), so the check is green on
the clean baseline and the flip-to-strict is a one-line follow-up ratchet.

## The work-copilot Copilot bundle (parallel delivery surface)

Everything above is Claude-side plumbing. `work-copilot/` is the workbench's
*other* delivery surface: a self-contained **GitHub Copilot** bundle that carries
the doc-first work-item contract to machines without Claude Code. It is NOT a
Claude skill — no `SKILL.md`, no `USAGE.md`, no entry in `skills-catalog.json` —
and it is not `/`-invoked. It is driven by a Python CLI and consumed by Copilot's
own prompt surface.

**What it carries (canonical source, no upstream sync):**

- `work-copilot/templates/` — the work-item templates (`tracker-*`, `doc-*`),
  mirroring the `CJ_personal-workflow` set.
- `work-copilot/WORKFLOW.md` + `work-copilot/copilot-artifact-manifests.json` —
  the structural rules + artifact manifest (the Copilot-side analogue of
  `personal-artifact-manifests.json`).
- `work-copilot/prompts/` — the Copilot slash-command surface: `/wc-investigate`,
  `/wc-scaffold`, `/wc-implement`, `/wc-qa`, `/wc-ship`, `/wc-pipeline`, and
  `/validate`.
- `work-copilot/reference/`, `philosophy/`, `examples/`, `fixtures/`, `domain/`
  skeletons, and `instructions/copilot-instructions.md` — ambient guidance +
  worked examples + validation fixtures.

**Deploy mechanism — `scripts/copilot-deploy.py`:**

- `find_bundle_dir()` resolves the bundle at `<repo-root>/work-copilot/` (the
  script directory's parent), so the bundle lives at the repo root **by design** —
  not under `skills/`, which is reserved for Claude skills.
- `python3 scripts/copilot-deploy.py install <target>` copies the bundle into the
  target repo under `.github/` and installs the Copilot instructions file;
  `doctor` and `remove` use the same CLI.
- It is one-way distribution: the workbench is the source of truth, target repos
  receive a copy.

**Bundle integrity — `scripts/validate.sh`:**

- An `EXPECTED_BUNDLE_FILES` array lists every required bundle file; the check
  ERRORs if any is missing. `scripts/test.sh` adds a size budget on
  `copilot-instructions.md` and an install round-trip test.
- **To add a bundle file:** create it under `work-copilot/<subdir>/` and append
  one entry to `EXPECTED_BUNDLE_FILES`. That single array is the registration
  point.

**Relationship to the Claude side.** Same doc-first *contract* (templates +
validation + ambient conventions), different runtime. The `CJ_` orchestrators do
NOT port — they are Claude-only. What ports is the structure a contributor
scaffolds against and the `/validate` pass that checks it. See
[philosophy.md -> Two delivery surfaces](philosophy.md#two-delivery-surfaces-one-contract)
for the why.

## Component skills (non-workflow roster)

The per-skill component roster — the phase-step skills the `cj_goal` orchestrators
dispatch, the `CJ_personal-workflow` validator, and the standalone utilities —
lives in [workflow.md](workflow.md) `## Utilities & phase-step skills` (alongside
the orchestrator chains, so the whole routable-skill catalog is one doc). This doc
keeps the *mechanism* sections above; the per-skill reference lives there.

## Decision tree mirror

The active-skill routing diagram lives in
[philosophy.md ## Decision tree](philosophy.md#decision-tree-which-cj_-skill-do-i-call)
— that is the single source of truth. This document does not duplicate the
diagram. If you landed on architecture.md first looking for "which `CJ_` skill do
I call?", follow the link to philosophy's Decision tree section.

The split is intentional: philosophy answers *which skill to call*; architecture
answers *how the mechanism underneath works*.
