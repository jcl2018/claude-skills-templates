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
  gate is green today and a free regression ratchet. This gate is the
  cj_goal-scoped enforcement; `validate.sh` Check 18 is **strict-by-default
  globally** (a portability finding hard-fails every commit, CI, and manual run;
  `PORTABILITY_STRICT=0` downgrades it to advisory), so the whole repo is the
  portability ratchet and this gate is the orchestrated-path belt.
- **recap** — the land/PR human-readable 3-part recap formatter. A **pure
  formatter**: it renders a standardized block — **Delivered / How to E2E-test it
  / Next step** — with a header keyed off `--when {before|after}`, sourcing the
  content from the existing repeatable `--field` parsing (`delivered=` / `e2e=` /
  `next=`, printed verbatim, no eval). It computes nothing, mutates nothing, and
  writes no telemetry; it emits `PHASE_RESULT=ok` and exits 0 — fully fail-soft
  (a missing field renders an empty section; it never halts). The four
  orchestrators call it at their land/PR-stop step (a before+after pair around the
  land for the two landing verbs `defect` / `todo_fix`; one at-PR recap for the
  two PR-stop verbs `feature` / `task`), with a documented prose fallback when the
  helper is absent. The agent authors the content; the helper only standardizes
  the shape. Advisory — there is no `validate.sh` gate asserting the wiring.

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

The workbench declares **what docs it carries and what each is for** in a
two-tier registry: the GENERAL `spec/doc-spec.md` (the portable contract,
byte-identical to `doc-spec.sh --seed`, never edited in place) plus the
optional `spec/doc-spec-custom.md` overlay carrying this repo's repo-specific
rows. Both tiers are a 3-column Markdown table (`| Doc | Purpose | Requirement |`)
parsed directly — the table IS the registry, no second copy to drift. The
parser merges the two internally, so every consumer sees ONE registry. See
[`spec/doc-spec.md`](../spec/doc-spec.md) for the contract itself; this section
is the mechanism reference for how it is parsed, merged, enforced, and
self-healed.

```
   doc-spec.md (spec/ — GENERAL,        doc-spec-custom.md (spec/ —
   == doc-spec.sh --seed)               optional overlay, this repo)
   +---------------------------+        +---------------------------+
   | Common prose (portable)   |        | repo-specific prose       |
   | | Doc | Purpose |         |        | | Doc | Purpose |         |
   | |  Requirement | table    |        | |  Requirement | table    |
   | (general docs)            |        | (repo-specific docs)      |
   +-------------+-------------+        +-------------+-------------+
                 +-----------------+------------------+
                                   | merged by scripts/doc-spec.sh
                                   | (duplicate path => error)
                          +--------+--------+
                          | parses          | parses
            +-------------v---+     +------v--------------------+
            | scripts/        |     | /CJ_document-release      |
            |   validate.sh   |     |  + /CJ_doc_audit          |
            | declared <=>    |     |  1. read the merge        |
            |  on-disk        |     |     (self-bootstrap the   |
            | table valid     |     |      general seed into    |
            | no work-item    |     |      spec/ if missing)    |
            |  IDs in human   |     |  2. stub-scaffold missing |
            |  docs           |     |     declared docs         |
            +-----------------+     |  3. registered-doc audit  |
                                    |     (+ no-ref for human)  |
                                    |  4. derive whitelist      |
                                    +---------------------------+
```

### The registry table

The 3-column Markdown table in each file (general + overlay, same grammar) is
the source of truth:

```
| Doc | Purpose | Requirement |
|-----|---------|-------------|
| `docs/philosophy.md` | Major design logic… | Arranged by principle; … no work-item IDs. |
```

- **the table** — the header (`| Doc | Purpose | Requirement |`) and the
  `|---|` delimiter row are skipped; each data row is split on `|`, cells are
  trimmed, and surrounding backticks are stripped from the Doc (path) cell. A
  literal `|` inside a cell is rejected (Markdown tables cannot carry one).
- **`audit_class` (derived, not declared)** — a declared path under `docs/` OR
  the root `README.md` is a `human-doc` (must exist + carry **no work-item
  IDs** `[FSTD]NNNNNN` + ASCII charts preferred, advisory); every other declared
  path is `operational` (must exist, work-item references allowed — CHANGELOG,
  CLAUDE.md, TODOS.md, etc.).
- **the tier is the file, not a field** — a row in the general
  `spec/doc-spec.md` is a general doc; a row in the `spec/doc-spec-custom.md`
  overlay is a repo-specific doc. There is no per-row `section` field.
- **duplicate-path guard** — the same path declared in both files (or twice
  anywhere in the merge) fails `--validate`.

### The doc-spec checks in `scripts/validate.sh`

These are the `validate.sh` checks that enforce the *doc* contract — one slice of
the larger verification story, not "the gate" as a whole. ("Gate" is reserved for
an inline orchestrator halt; see [`spec/test-spec.md`](../spec/test-spec.md) and the
[test-spec.md contract](#the-test-specmd-contract-two-tier--the-verification-contract)
section below for the four-layer map of every verification surface.) The validator
parses the registry and asserts the contract:

- **declared <=> on-disk** — every declared doc exists, AND every `docs/**/*.md`
  on disk (recursive — including the `docs/workflows/` subfolder) is declared (no
  orphans).
- **table valid** — `doc-spec.md` exists, its registry table parses (the
  `| Doc | Purpose | Requirement |` shape, no literal `|` inside a cell), and no
  path is duplicated across the two files.
- **root-docs allowlist** — every root `*.md` on disk must be a declared entry in
  the registry (or it is an un-allowlisted orphan).
- **no work-item IDs in human docs** — for every path-derived human-doc (a
  declared path under `docs/` or the root `README.md`), the validator greps
  `[FSTD][0-9]{6}` and ERRORs on any hit. This is the hard lint that keeps the
  human docs human-readable.
- **workflows-subfolder mandate** — when the registry is present, `docs/workflows/`
  must exist and be non-empty (the portable contract's two-level docs structure;
  registry-gated, so it never fires on a non-adopting repo).
- **workflow completeness** — `docs/workflow.md` (the index) + every
  `docs/workflows/<name>.md` are GENERATED from `spec/workflow-spec.md` (see "The
  generated workflow docs" below). Each `CJ_goal_*` orchestrator carries an ASCII
  chart + a 4-bullet Touches block by construction (it is an `orchestrator`-kind
  registry entry), the index links each one, and `validate.sh` Check 27 +
  `workflow-spec.sh --validate` enforce freshness + the no-vanish guarantee. The
  former shape-only Checks 15b/15c are retired (their intent moved into generation
  + registry-completeness).

### The helper (`scripts/doc-spec.sh`)

A single bash file owns the parse/derive logic the SKILL.md and validator
consume. Subcommands:

- `--validate` — exit 0 + print `OK schema_version=<n>` if the merged registry
  table is valid; exit 1 + emit `[doc-sync-no-config] <reason>` otherwise.
- `--list-declared` — emit every declared `Doc` path (sorted, unique).
- `--list-human-docs` — emit only the path-derived human-doc paths (a path under
  `docs/` or the root `README.md`).
- `--expand-whitelist` — emit the doc-only auto-commit whitelist (every merged
  declared path + the contract files + every `docs/**/*.md` on disk; sorted,
  unique).
- `--seed` — emit the portable general file (used by the self-bootstrap and by
  `/CJ_doc_audit`'s seed delivery to recreate a missing `spec/doc-spec.md`; kept
  3-way byte-identical with `spec/doc-spec.md` + `templates/doc-spec-common.md`).

It reads the registry via `git rev-parse --show-toplevel` (general resolved
`spec/`-then-root; the overlay always next to the general file), so a copy
resolved from the deployed `_cj-shared` home still parses THIS repo's registry —
never the workbench's. All subcommands operate on the MERGE; an overlay-absent
repo simply parses the general file alone.

### The portable CI hook (scoped honestly)

Because `doc-spec.sh` resolves the cwd repo's registry and travels with the
install (the deployed `_cj-shared/scripts/` home), a consumer repo — any repo, not
just this workbench — can wire the registry schema check into its own CI as a
portable gate:

```yaml
# In a consumer repo's CI workflow, after checkout + skills install:
- name: Validate doc-spec registry
  run: "${CJ_SHARED_SCRIPTS:-$HOME/.claude/_cj-shared/scripts}/doc-spec.sh --validate"
```

`doc-spec.sh --validate` exits 0 (`OK schema_version=<n>`) when the registry is
well-formed and exits 1 (`[doc-sync-no-config] <reason>`) otherwise. And the
schema check is no longer the only mechanical guarantee that travels:
`doc-spec.sh --check-on-disk` carries the full deterministic conformance set in
the same portable helper — the audit Stage-1 engine. It runs five checks of the
MERGED registry against the disk state — declared-exists, orphans (`docs/**/*.md`
RECURSIVE — including `docs/workflows/` — + `spec/*.md` maxdepth 1, each dir only
when present; an undeclared overlay file IS an orphan), workflows-subfolder
(registry-gated: `docs/workflows/` exists + non-empty), root-declared, and
human-doc-ids — emitting one
`check: <id> — PASS` line per clean check, one `FINDING: stage1/<id> — <detail>`
line per violation, and a `CHECKS_RUN=`/`FINDINGS=` tail (exit 0 clean / 1
findings). It probes registry existence ITSELF before the parse gates: an absent
registry is `REGISTRY=absent` + exit 0 (the seed-delivery step owns that case),
while a present-but-invalid registry keeps the `[doc-sync-no-config]` halt. So a
consumer repo's CI can carry the whole conformance gate with one portable
command:

```yaml
- name: Doc-contract conformance
  run: "${CJ_SHARED_SCRIPTS:-$HOME/.claude/_cj-shared/scripts}/doc-spec.sh --check-on-disk"
```

`/CJ_document-release` also runs there cold (its workbench-only
`skills-catalog.json` read is guarded — absent ⇒ a clean skip, no `jq` noise, no
stray artifact).

**The workbench keeps its own copies — for now.** This repo's
`scripts/validate.sh` Checks 15/15a (declared⇔on-disk), 17 (root declared), and
19 (no-work-item-ID human-doc lint) retain their own implementations alongside
the engine — a deliberate same-PR blast-radius decision when `--check-on-disk`
shipped. Converging those checks onto the engine is a tracked TODOS row.

### /CJ_document-release behavior (self-heal + audit)

On every major `cj_goal` run (Step 5.5) or a manual invocation, the wrapper:

1. **Reads `doc-spec.md`.** If it is **missing**, scaffolds it from the portable
   Common seed (`scripts/doc-spec.sh --seed`), commits it, and continues. This is
   the self-bootstrap that lets a fresh repo adopt the contract with no manual
   step.
2. **Stub-scaffolds missing declared docs.** For each declared doc that is
   missing, writes a **stub** (title + a section skeleton its path-derived
   audit_class implies + a `<!-- TODO: fill in -->` marker), commits it, and
   records it in the audit as `stub — needs content`. Idempotent: a re-run never
   writes a second stub.
3. **Runs the registered-doc audit (ADVISORY — never halts).** Judges each
   declared doc against its `Requirement`. For human-doc entries it also runs
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

1. **The registry docs** — every row in the `doc-spec.md` registry table, each
   carrying its `Requirement` value.
2. **The routable skill MDs (active OR experimental)** — every skill returned by
   `jq -r '.[] | select(.status != "deprecated") | select((.files | length) > 0) | .name' skills-catalog.json`
   (the `!= "deprecated"` predicate, deliberately broader than the active-only
   New-skills check, so the audit covers the whole `CJ_` family). Each skill's
   `SKILL.md` is a registered doc; its requirement is the skill's optional
   `doc_requirement` field in `skills-catalog.json`, else the shared default
   below. This group reads `skills-catalog.json`, which is workbench-only, so it
   is **guarded**: in a consumer repo with no catalog the skill-MD half skips
   cleanly (one note, no `jq` noise) while group 1 — the registry docs, including
   the human-doc no-work-item-ref lint — still runs.

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

## The test-spec.md contract (two-tier — the verification contract)

The workbench declares its full verification contract in TWO tiers, mirroring
the doc contract. The GENERAL [`spec/test-spec.md`](../spec/test-spec.md)
(byte-identical to `test-spec.sh --seed`, never edited in place) carries the
five portable rules every adopting repo holds its verification surface to —
`tests-discoverable`, `suite-green`, `new-code-tested`, `units-anchored`,
`single-owner` — PLUS the four-layer map (`layers[]`: local-hook / ci /
pipeline-gate / ratchet — the answer to "what stops a broken change from
landing, and at which layer"). The CUSTOM overlay
[`spec/test-spec-custom.md`](../spec/test-spec-custom.md) carries **this repo's
verification surface, check by check** — every validator check (both ID
namespaces plus the warning checks), every registered test sub-suite and inline
test family, the standalone suites, the CI workflows, and the git hooks — as
`units:` rows, PLUS the per-mode pipeline-gate halts as a top-level `gates:`
array, PLUS a behavior-coverage axis: `behaviors:` rows (open-world
statements of WHAT the software must prove, each with a first-class `level` from
the closed enum `{unit, integration, contract, workflow, property}`) and
`behavior_coverage:` rows (each behavior linked to a test-bearing `units:` row
plus a semantic-evidence source/anchor). `scripts/test-spec.sh` merges everything
internally; consumers see ONE verification contract.

**One contract, folded from two.** The former `spec/gate-spec.md`
member (the LAYER map + the per-mode `gates[]`) and its `scripts/gate-spec.sh`
reader were folded into this contract: `layers[]` into the general file,
`gates[]` into the overlay, the gate parsing into `scripts/test-spec.sh`, and
the advisory marker-drift cross-check (the retired Check 22) into Check 24. The
spec-registry family is now `spec/doc-spec.md` (+ overlay) →
`spec/permission-policy.md` → `spec/test-spec.md` (+ overlay).

**The four layers.** A change is verified at four independent layers, each
owning a different guarantee: **local-hook** (the pre-commit `validate.sh`,
hard-fail at commit), **ci** (GitHub Actions, hard-fail on the PR),
**pipeline-gate** (the inline orchestrator halts — isolation, design-summary, QA,
the qa-audit checkpoint, doc-sync, portability, ship — during a run), and
**ratchet** (monotonic guards: Check 8 VERSION-never-regresses, the portability
`FINDINGS=0` baseline, Check 14 USAGE.md freshness). The contract reserves the
word **"gate"** for a single referent — a `pipeline-gate` row (a `gates:` entry)
— so `validate.sh`-as-a-whole is the **ci** layer (a set of *checks*), never
"the gate."

**The per-mode `markers` map (the `gates:` array).** A gate's `markers` is a map
keyed by `feature|defect|task|todo`. A mode absent from the map does not run
that gate (`qa-audit`, `doc-sync` + `portability` are universal; isolation has
three different markers and is absent in todo;
`design-gate`/`root-cause`/`complexity` are single-mode). A map value is either
a literal `"[marker]"` (Check 24's advisory marker-drift cross-check greps for
it in that mode's files) or `{ enforced_by: subagent | auq }` (the gate runs but
emits no bracket marker — the escape hatch that keeps the baseline honestly
clean, e.g. todo's QA + ship). The `qa-audit` row (order 45, between qa 40 and
doc-sync 50) is the post-QA audit-findings checkpoint: the QA leaf's Step 8.6
block produces the doc/test audit digest, the orchestrator AUQ owns the
Continue/Halt decision (`[qa-audit-declined]` literal in all four modes;
waivers journal as `[qa-audit-waived]`).

```
   test-spec.md (spec/ — GENERAL,       test-spec-custom.md (spec/ —
   == test-spec.sh --seed)              optional overlay, this repo)
   +---------------------------+       +----------------------------+
   | the 5 portable rules +    |       | anchor/extraction doctrine |
   | the 4-layer layers[] map  |       | ```yaml machine registry`` |
   | ```yaml machine registry``|       |  units[]: id / family /    |
   |  schema_version: 1        |       |    label / anchor / source/|
   |  rules[]: id / statement /|       |    layer / disposition /   |
   |    scope / enforced_by    |       |    skips? / ratchet? /     |
   |  layers[]: id / name /    |       |    trigger / purpose       |
   |    trigger / disposition  |       |  gates[]: id / layer /     |
   |    / owns                 |       |    order / markers / ...   |
   +-------------+-------------+       +-------------+--------------+
                 +-----------+-----------------------+
                             | merged by scripts/test-spec.sh
                             | (REGISTRY=absent + exit 0 when neither
                             |  spec/ nor root general file exists)
                  +----------+----------+
                  | parses              | cross-checks
        +---------v---------+    +------v----------------------+
        | scripts/          |    | scripts/validate.sh         |
        |  test-spec.sh     |    |  Check 24 (MIXED):          |
        | --validate        |    |   --validate the merge,     |
        | --list-rules      |    |   then --check-coverage     |
        | --list-units      |    |   (forward + reverse +      |
        | --list-layers     |    |    floor — HARD), then the  |
        | --list-gates      |    |   per-mode gate marker      |
        | --list-behaviors  |    |   drift cross-check         |
        | --list-behavior-  |    |   (ADVISORY); + behavior-   |
        |   coverage        |    |   coverage 6 checks when    |
        | --check-coverage  |    |   behaviors: exist          |
        | --seed            |    |                             |
        +---------+---------+    +-----------------------------+
                  |
                  v              /CJ_test_audit  (seed-deliver -> validate ->
                                  coverage -> agent-judged suite-green / new-code-tested)
```

**The hard loop.** A change to the live surface without a matching units row —
a new validator check, a renamed banner, a new test file, a new workflow, a new
hook — fails Check 24: *forward*, every row's `anchor` must match LIVE in its
declared `source` (execution-shaped matching; dead-text mentions do not count);
*reverse*, every live validator banner/comment, every `tests/*.test.sh` on
disk, every workflow file and every installed hook must resolve to exactly one
registry row; *floor*, the reverse extraction must keep yielding at least 20
live tokens (`TEST_SPEC_REVERSE_FLOOR`) so grammar rot can never make the check
vacuously pass. Check 24 also runs `test-spec.sh --validate` first — the
symmetric schema gate Check 16 runs for the doc-spec.

**The units gate (one parser, two postures).** The reverse sweep + floor apply
ONLY where `units:` rows exist. A seeded consumer repo carries the rules alone:
its coverage cross-check reports `no units declared — coverage cross-check
inactive` by name and passes — never a misleading extraction-grammar finding.
Declaring units in `spec/test-spec-custom.md` activates the deterministic floor.

**The silent-skip catch.** Test discovery in this repo is hand-wired, not
glob-based — a test file on disk that nobody registers in the runner silently
never runs. The registry mechanizes that discipline: a test row's `source` MUST
be the runner script and its `anchor` MUST be the literal runner path, so the
forward check proves the file is actually WIRED into the suite, and the reverse
sweep proves every file on disk has a row at all.

**What stays agent-judged.** `suite-green` and `new-code-tested` (rules the
grep engine structurally cannot prove) are judged by `/CJ_test_audit` against
the repo's current state, layered ABOVE the deterministic floor; semantic
accuracy of each row's one-line `purpose`/`label` is likewise judged — the
test audit's requirement-compliance stage reads the source at each unit's
anchor and asks whether the description still tells the truth (the anchor can
grep while the description rots). The hard loop buys structural sync; the
judged stages buy meaning sync.

**The audit verbs.** `/CJ_doc_audit` + `/CJ_test_audit` front the two
contracts as standalone operator keystrokes in ANY repo, each running THREE
named stages: seed-deliver the general file when missing (creating `spec/`;
`seeded: yes`, idempotent `seeded: no`), then **Stage 1 — deterministic
conformance (engine)**: one tested engine call per audit
(`doc-spec.sh --check-on-disk`; `test-spec.sh --validate` +
`--check-coverage`), printed verbatim — no executor-authored loops; **Stage 2
— requirement compliance (agent-judged, evidence-forced)**: each declared
doc's `Requirement` (and each test rule's `statement` + each unit's
`purpose`) quoted, decomposed, and judged with cited evidence; **Stage 3 —
implementation drift (agent-judged)**: ground truth enumerated from the live
repo state first, then each contract doc / verification surface cross-walked
against it. Standalone, Stages 2+3 run in ONE fresh-context subagent (the
dispatch prompt carries only repo root + engine path + the Stage-1 report +
the stage protocols — never the invoking session's beliefs). The per-stage
report carries `DOC_AUDIT:`/`TEST_AUDIT:` + `FINDINGS=` +
`STAGE1/2/3_FINDINGS=` + grep-able `stageN/` finding prefixes. Inside a
cj_goal run the same logic executes INLINE at `/CJ_qa-work-item` Step 8.6 (a
subagent cannot spawn subagents — the honest degradation, labeled in the
report), and every orchestrator surfaces the per-stage block at its post-QA
`qa-audit` checkpoint before doc-sync.

**Consumer-repo posture.** Where no test-spec registry exists at all, the
parser classifies it mechanically — `REGISTRY=absent` + exit 0 — and Check 24
SKIPs; the first `/CJ_test_audit` run seeds the general contract and the repo
opts into units whenever it is ready.

### The generated test catalog (`docs/tests/` — the human-readable view)

The `units:` overlay is a machine registry — the right shape for the engine and
the AI, the wrong shape for a human asking "what tests do we have and what does
each prove?" So the registry gets a **generated human-readable view**:
`docs/test-catalog.md` (the index, families with counts) plus one
`docs/tests/<family>.md` per unit `family` (`validate`, `test`, `ci`, `hook`,
`windows-smoke`, `test-deploy`, `eval`). `test-spec.sh --render-docs` renders
them deterministically from the merged registry's **rendered fields only**
(`label`, `purpose`, `layer`, `disposition`, `trigger`; the `anchor` shown as an
inline code reference with any work-item ID masked, so a generated human-doc is
work-item-ID-free by construction and passes Check 19).

This is the **same primitive** the repo already trusts for `README.md`: a single
source of truth (the `spec/` registry) renders a `docs/` view, and a freshness
check keeps the two in lockstep. The catalog's freshness gate is **`validate.sh`
Check 26** — regenerate to a temp dir, diff against on-disk, hard-fail on any
mismatch (the structural mirror of Check 25's README freshness gate, with its
parallel `scripts/test.sh` integration fixture). The same freshness check also
runs as **`/CJ_test_audit` Stage 1** (`test-spec.sh --render-docs --check`), so a
stale catalog is caught the moment the audit runs — even in a consumer repo that
carries no `validate.sh`. The audit's Stage-3 drift pass recognizes
`docs/tests/` as a generated surface, never flagging it as an orphan. Editing a
catalog page by hand is therefore pointless: the next regenerate (or the
freshness gate) reverts it — to change the catalog, change the registry.

## The generated workflow docs (`docs/workflows/` — from `spec/workflow-spec.md`)

The **third instance** of the generate→freshness→audit primitive (after
`README.md` and the test catalog) covers the workflow docs. `docs/workflow.md`
(the index) + the six `docs/workflows/*.md` were hand-authored prose whose
4-bullet **Touches** blocks drifted on every workflow change. They are now
GENERATED from a single registry, `spec/workflow-spec.md`, by
`scripts/workflow-spec.sh --render-docs`.

The registry is bash-parseable structured Markdown — one `## <name>` section per
workflow, in two `kind`s: **orchestrator** (the four `CJ_goal_*` verbs — a key
block + a verbatim ASCII `chart` + the four Touches axes `skills`/`steps`/
`scripts`/`docs` + an "In words" summary) and **roster** (the two free-form
roster docs — a verbatim `body`), plus a header block holding the
`docs/workflow.md` index preamble. The renderer emits a normalized template;
charts, roster bodies, and the preamble are reproduced verbatim (the migration
from the hand-authored docs was a one-time reviewed reformat, not a byte
round-trip), and the output is work-item-ID-free by construction (Check 19).

Freshness is the **`validate.sh` Check 27** gate (regenerate→diff vs on-disk,
hard-fail on mismatch — the structural mirror of Check 26, with its parallel
`scripts/test.sh` fixture), and the same `workflow-spec.sh --render-docs --check`
runs as **`/CJ_doc_audit` Stage 1** so a stale workflow doc is caught standalone
in any repo; Stage 3 recognizes the surface as generated. The **no-vanish
guarantee** — every routable `CJ_goal_*` orchestrator has a registry entry — is a
`workflow-spec.sh --validate` registry-completeness check (`jq` over
`skills-catalog.json`), STRONGER than the index-link grep it replaces. This is
why the former shape-only **Checks 15b/15c were retired**: a generated doc cannot
be missing its chart/Touches and the generated index cannot drop a link, so the
only remaining risk (a routable workflow with no entry) is exactly what
`--validate` fails closed on.

## Contract seeding + the stale-engine probe (adoption)

The three `spec/` contracts (`doc-spec.md`, `test-spec.md`, `workflow-spec.md`)
are per-repo files: an adopting repo carries them so the audits + `validate.sh`
have something to check. Two mechanisms make seeding **forced and reliable** in
any consumer repo.

**The stale-engine capability probe (the bug fix).** Every consumer of a
`spec/` engine resolves it **repo-local `scripts/<engine>.sh` → `_cj-shared`**.
A consumer that vendored an OLD engine had the stale copy WIN, and a stale engine
lacks the current `--seed`/`--classify` surface — so seeding silently no-op'd
("it doesn't force generate the seeding"). The fix: after picking the repo-local
engine, probe it with the side-effect-free `--classify` (read-only; a current
engine emits `GENERATION=`). A repo-local engine that does NOT emit `GENERATION=`
is treated as **stale** — resolution falls back to `_cj-shared` and the audit
emits an advisory `stage1/engine-stale` finding naming the engine + the remedy
(update/remove the vendored script, or re-run `skills-deploy install`). This makes
the existing seeding actually fire in a repo that carries a stale vendored engine.

**Forced seeding through every adoption path.** A shared `do_seed_contracts`
routine in `scripts/skills-deploy` seeds each of the three contracts into a target
repo when absent — corruption-guarded (write a temp file, require non-empty AND
`--validate`-clean, then `mv`) and idempotent (present ⇒ skip). Three triggers
call it: the standalone **`skills-deploy seed-contracts`** subcommand (the
explicit adopt command), **`install` run from a consumer repo** (always seeds,
forced, git-repo-guarded), and **both audits' lazy Step-2 seed** (`/CJ_doc_audit`
now seeds `doc-spec` + `workflow-spec`; `/CJ_test_audit` seeds `test-spec`). The
**workbench self-repo is always skipped** — a worktree-aware data-loss guard with
two signals. The PRIMARY signal is identity: the target's main toplevel matches
the manifest `source`/`bundle_path` (worktree-aware via `--git-common-dir`). The
SECONDARY signal is an AUTHORED custom overlay (`spec/doc-spec-custom.md` without
the `auto-generated by skills-deploy` marker, or `spec/test-spec-custom.md`) —
but ONLY when a root `skills-catalog.json` is ALSO present. The catalog gate is
what separates the workbench from a CONSUMER that legitimately hand-authored its
own overlay: a consumer never ships a `skills-catalog.json`, so an overlay alone
no longer false-positives a real consumer as the workbench and skips its adoption
+ gate-hook install. The workbench carries the catalog + its authored overlays
(still skipped — data-loss protection preserved); a consumer with a curated
overlay but no catalog now proceeds through adoption. Either way the workbench
AUTHORS the real contracts and re-seeding would clobber them with skeletons. A consumer's seeded
`workflow-spec` is a vacuously-complete skeleton (no `CJ_goal_*` workflows), so
its `--validate` no-vanish check passes with zero entries.

### The deterministic contract gate (`cj-contract-gate.sh`) — enforced in each repo

Seeding makes a consumer repo *carry* the contracts and the audits *run on
demand*; the gate makes the deterministic checks **forced**. `scripts/cj-contract-gate.sh`
is the **engine-only (Stage-1) subset of `validate.sh`** — runnable with NO agent,
so a consumer can enforce its contract from a git **pre-commit hook** or a **CI
step** (the agent-judged Stage 2/3 audits stay on-demand via `/CJ_doc_audit` /
`/CJ_test_audit`). It composes the three engines and thresholds their dispositions:

The gate is **FULLY HARD with exactly ONE soft exception** — `declared-exists`.
Every other check blocks; `declared-exists` is soft because it is the one gap a
machine cannot close (it can't auto-author prose docs):

- `doc-spec.sh --check-on-disk` — HARD, **except** a `declared-exists` finding,
  which is a **SOFT** `REMEDIATION:` note pointing at `/CJ_document-release`. This
  is the SINGLE documented soft remediation: a consumer carries the registry but
  not yet the human-authored prose docs (README/CHANGELOG/architecture/…), and a
  machine can't write those for it. The orphan / `workflows-subfolder` /
  `root-declared` / `human-doc-ids` checks stay HARD — they are made to pass by
  *adoption* (below), not by softening the gate.
- `test-spec.sh --validate` + `--check-coverage` — HARD (a rules-only consumer's
  coverage cross-check reports "inactive", which is *not* a finding).
- `workflow-spec.sh --validate` — HARD (the no-vanish / registry-completeness guard).
- `test-spec.sh --render-docs --check` + `workflow-spec.sh --render-docs --check` —
  HARD freshness (a stale generated catalog / workflow surface).

The `workflows-subfolder` doc-spec check has one **empty-registry tolerance**
(`doc-spec.sh`): the `docs/workflows/` surface is GENERATED from
`spec/workflow-spec.md`, so when the workflow registry declares **zero** workflows
(absent, or present with no `kind:` section — a fresh consumer's vacuous seed) an
empty/absent `docs/workflows/` is correct, not a violation. A repo that declares a
workflow still requires a non-empty `docs/workflows/` (the workbench is unchanged).

It is **registry-gated** throughout: an engine that reports `REGISTRY=absent` (a
contract the repo has not adopted) is a clean **SKIP** (exit 0 for that check). The
gate exits non-zero **iff at least one HARD check finds a violation**, printing a
compact per-check summary (`PASS` / `FINDING` / `REMEDIATION` / `SKIP`). `--quiet`
suppresses the per-check lines on success (silent for hook use); on a block it
replays the summary so the developer sees exactly which check failed. Engine
resolution reuses the seeding stale-engine probe: **repo-local `scripts/<engine>.sh`
(only if its `--classify` emits `GENERATION=`) → `_cj-shared`** — a stale vendored
engine never silently mis-gates.

**Adoption completes the repo (so the fully-hard gate passes from the first
commit).** Rather than softening the gate for a fresh adopter, `skills-deploy`
makes adoption leave the repo **contract-clean**. In the consumer-path block, AFTER
seeding and BEFORE the gate-hook install, `complete_consumer_adoption` runs two
idempotent, deterministic steps: it **refreshes the generated surfaces**
(`test-spec.sh --render-docs` + `workflow-spec.sh --render-docs` → `docs/test-catalog.md`,
`docs/tests/`, `docs/workflow.md`, `docs/workflows/`) so the freshness checks pass,
and it **auto-declares the seeded/generated docs** — it writes a minimal,
auto-marked `spec/doc-spec-custom.md` overlay declaring every `docs/**/*.md` +
`spec/*.md` orphan the engine reports (so `orphans` passes), validating the merged
registry and rolling back if invalid. A repo that already carries a hand-authored
overlay (no auto-marker) is treated as already-adopted and left untouched; the
auto-marker also keeps an adoption overlay from counting as an AUTHORED overlay in
the workbench-self data-loss guard (a belt-and-suspenders alongside the guard's
`skills-catalog.json` gate, which a consumer lacks anyway). After adoption the only remaining finding is `declared-exists`
(the prose docs), which is soft — so the auto-installed gate never bricks the next
commit, and no pre-flight is needed.

**Consumer pre-commit auto-install (guarded).** `skills-deploy install` run from a
consumer repo installs the gate as a pre-commit hook (in the same consumer-path
block as the seeding, AFTER it — the contracts must exist before enforcing them).
The hook body resolves `cj-contract-gate.sh` from `${CJ_SHARED_SCRIPTS:-$HOME/.claude/_cj-shared/scripts}`
at commit time and blocks the commit on a non-zero exit. The install reuses the
clobber-safe `cj_install_hook` from the shared `scripts/cj-hook-lib.sh` (the ONE
implementation both `setup-hooks.sh` and `skills-deploy` source — no drifting
copies), carrying the `setup-hooks` SENTINEL so re-install is idempotent and
`--remove` recognizes it. Guards: a custom `core.hooksPath` (husky/lefthook) is
SKIPPED with a note (the committed hooks dir is left alone), a **non-workbench**
pre-commit hook is **backed up with a WARN** (never clobbered), the **workbench
self-repo** is SKIPPED (it enforces via `validate.sh` — no double-enforcement), and
a non-git cwd is a clean no-op.

**Standalone command.** `skills-deploy install-contract-gate [--repo <path>]`
installs the hook explicitly; `--remove` uninstalls **only** a sentinel
(workbench-owned) hook, leaving a non-workbench hook untouched.

**CI snippet (doc-only — no workflow file is shipped into consumers).** A team
that prefers server-side enforcement can run the gate on PRs by copying this into
`.github/workflows/contract-gate.yml`:

```yaml
name: contract-gate
on: [pull_request]
jobs:
  contract-gate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      # Make the deployed gate + engines available under _cj-shared. In a repo that
      # vendors scripts/cj-contract-gate.sh + scripts/{doc,test,workflow}-spec.sh,
      # point CJ_SHARED_SCRIPTS at scripts/ instead of running skills-deploy install.
      - name: Run the deterministic contract gate
        run: |
          GATE="${CJ_SHARED_SCRIPTS:-$HOME/.claude/_cj-shared/scripts}/cj-contract-gate.sh"
          [ -x "$GATE" ] || GATE="scripts/cj-contract-gate.sh"   # repo-vendored fallback
          bash "$GATE" --repo .
```

The gate exits non-zero on a hard finding, failing the check; a missing declared
doc is a soft remediation (exit 0) and an unadopted contract is a clean SKIP, so
the CI gate never spuriously fails a partially-adopted consumer.

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
lives in [workflows/utilities-and-phase-steps.md](workflows/utilities-and-phase-steps.md)
`## Utilities & phase-step skills` (one of the per-workflow files under
`docs/workflows/` that the [workflow.md](workflow.md) index links). This doc
keeps the *mechanism* sections above; the per-skill reference lives there.

## Decision tree mirror

The active-skill routing diagram lives in
[philosophy.md ## Decision tree](philosophy.md#decision-tree-which-cj_-skill-do-i-call)
— that is the single source of truth. This document does not duplicate the
diagram. If you landed on architecture.md first looking for "which `CJ_` skill do
I call?", follow the link to philosophy's Decision tree section.

The split is intentional: philosophy answers *which skill to call*; architecture
answers *how the mechanism underneath works*.
