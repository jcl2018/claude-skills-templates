---
name: CJ_doc_audit
description: "Three-stage doc audit against a repo's doc contract — runnable standalone in ANY repo. Ensures the two-tier doc contract is CANONICAL via doc-spec.sh --classify: absent → seed-deliver spec/doc-spec.md (seeded: yes; idempotent seeded: no on re-run); canonical → ok; legacy/duplicate → an advisory RECONCILE: directive in the Stage-1 report (NO auto-write; run /CJ_doc_audit --reconcile to migrate a legacy yaml registry to the canonical 3-column Markdown table preserving every row). Stage 1 (deterministic — engine): doc-spec.sh --check-on-disk (declared-exists, orphans, root-declared, human-doc-ids vs the MERGED registry — four checks), printed verbatim, PLUS the workflow-docs freshness check (workflow-spec.sh --render-docs --check when the engine is present — the generated docs/workflow.md + docs/workflows/ surface, the same owner validate.sh Check 27 calls; stage1/workflow-render); pre-stage failures count as stage1/engine|seed|registry. Stage 2 (requirement compliance — agent-judged, evidence-forced): each declared doc's requirement: quoted, decomposed into clauses, verdicts satisfies | missing-requirement (soft) | n/a | FINDING: stage2/<path> with cited evidence. Stage 3 (implementation drift — agent-judged): ground-truth enumeration FIRST (catalog skills, scripts, workflows, spec family, dirs), then a per-doc cross-walk; docs/workflow.md + docs/workflows/ are recognized as a GENERATED surface (sourced from spec/workflow-spec.md), never an orphan/drift; verdicts no-drift | FINDING: stage3/<path> — <named delta>. Standalone runs MUST dispatch Stages 2+3 to ONE fresh-context subagent (Agent tool); inside a QA subagent (qa.md Step 8.6c) they run INLINE (a subagent cannot spawn subagents). Per-stage report: DOC_AUDIT: <ok|findings> + FINDINGS= + STAGE1/2/3_FINDINGS= + DOCS_AUDITED= + seeded: + three --- stage N --- sections. Findings (and the RECONCILE directive) never crash the audit — a broken contract IS the report. Engine resolution repo-local scripts/doc-spec.sh then ~/.claude/_cj-shared/scripts/. Use when: 'audit this repo's docs', 'check doc hygiene', 'does this repo follow its doc contract'."
version: 0.3.0
allowed-tools:
  - Bash
  - Read
  - Glob
  - Grep
  - Agent
---

## Preamble

Check for collection updates (silent if none, banner if a newer version is available):

```bash
_UC="${CJ_SHARED_SCRIPTS:-$HOME/.claude/_cj-shared/scripts}/skills-update-check"
[ -x "$_UC" ] && "$_UC" 2>/dev/null || true
```

Verify this is a git repository:

```bash
git rev-parse --show-toplevel 2>/dev/null || echo "NOT_A_GIT_REPO"
```

If `NOT_A_GIT_REPO`: tell the user "Error: /CJ_doc_audit requires a git repository." and stop.

## Overview

`/CJ_doc_audit` answers one question in ANY repo: **do this repo's docs follow
its doc contract?** The contract is the two-tier doc-spec registry — the
portable general file (`spec/doc-spec.md`, byte-identical to
`doc-spec.sh --seed`) plus an optional repo-specific overlay
(`spec/doc-spec-custom.md`) the parser merges in. The audit runs in **three
named stages**, split exactly along the deterministic/judged boundary:

- **Stage 1 — deterministic conformance (engine):** ONE tested engine call,
  `doc-spec.sh --check-on-disk`, printed verbatim. No executor-authored loops.
- **Stage 2 — requirement compliance (agent-judged, evidence-forced):** each
  declared doc judged clause-by-clause against its quoted `requirement:`
  string, every verdict citing decisive evidence.
- **Stage 3 — implementation drift (agent-judged, evidence-forced):** ground
  truth enumerated FIRST from the live repo state, then each contract doc
  cross-walked against it; every drift finding names the delta.

Findings never crash the audit and never halt a caller: a broken contract IS
the report. The audit is read-mostly — on a plain run its ONLY write is the
idempotent seed delivery (Step 2). A non-canonical contract (a legacy-generation
or duplicated file) is detected by `doc-spec.sh --classify` and surfaced as an
advisory `RECONCILE:` directive in the Stage-1 report (no write); the migration
runs ONLY under the opt-in standalone `--reconcile` flag, which forwards to the
engine's `--reconcile` (the only new write path). The in-QA path never passes
`--reconcile`, and the directive — like a `REMEDIATION:` line — never crashes
the audit or flips QA red.

**Judge context (load-bearing).** Standalone (operator keystroke at top
level): Stages 2+3 are REQUIRED to run in ONE fresh-context general-purpose
subagent (the Agent tool) — see "Fresh-context dispatch" below. Inside a QA
subagent (`/CJ_qa-work-item` qa.md Step 8.6c, inside a cj_goal run): a
subagent cannot spawn subagents (the nested-subagent wall), so the QA agent
executes ALL stages — including 2+3 — INLINE by reading this file, following
the same stage protocols. This inline posture is an honest degradation: the
in-QA judge carries more resident context than a standalone fresh-context
judge; the standalone dogfood is the fresh-context proof. Both postures
produce the identical per-stage report shape.

## Step 1: Resolve the engine

The deterministic stage runs on `doc-spec.sh`. Resolve it repo-local first,
then the deployed shared home:

```bash
_DA_ROOT=$(git rev-parse --show-toplevel)
_DA_ENGINE=""
if [ -x "$_DA_ROOT/scripts/doc-spec.sh" ]; then
  _DA_ENGINE="$_DA_ROOT/scripts/doc-spec.sh"
elif [ -x "${CJ_SHARED_SCRIPTS:-$HOME/.claude/_cj-shared/scripts}/doc-spec.sh" ]; then
  _DA_ENGINE="${CJ_SHARED_SCRIPTS:-$HOME/.claude/_cj-shared/scripts}/doc-spec.sh"
fi
[ -n "$_DA_ENGINE" ] || echo "ENGINE_UNREACHABLE"
```

If `ENGINE_UNREACHABLE`: this is a STAGE-1 finding —
`FINDING: stage1/engine — doc-spec.sh unreachable (repo-local scripts/ +
deployed _cj-shared both absent); run 'skills-deploy install'`. Nothing else
can run; emit the per-stage report (Step 6) with `STAGE1_FINDINGS=1`, Stages
2+3 each printing their header + `skipped: engine unreachable — nothing to
judge against`, and `DOC_AUDIT: findings`.

## Step 2: Ensure the contract is canonical (classify → seed | ok | reconcile)

This step generalizes the former "seed if missing" into a **classify-driven
reconcile** (F000065). Run `doc-spec.sh --classify` (READ-ONLY) and route on
`GENERATION`:

- **`absent`** → seed-deliver the canonical contract (today's behavior,
  unchanged): create `spec/`, write the seed to a temp file, verify non-empty
  AND `--validate`-clean, THEN move into place (the corruption guard — a
  `--seed` failure must never redirect a halt string into the new file). Report
  `seeded: yes`.
- **`canonical`** → nothing to do (`seeded: no`); the contract is already in
  the canonical shape. NO `RECONCILE:` line is emitted (a canonical repo stays
  silent — the read-mostly, zero-noise contract).
- **`legacy`** or **`duplicate`** (`DUPLICATE=1`) → the contract exists in a
  non-canonical shape. Emit an **advisory `RECONCILE:` directive** into the
  Stage-1 report naming the issue + the remedy, and **DO NOT write** on a plain
  run. This directive is advisory exactly like a `REMEDIATION:` line — it never
  crashes the audit, never flips a caller red, and the in-QA path never acts on
  it. ONLY when the operator passed the audit `--reconcile` flag (standalone —
  Step 0 below) does the skill forward to `doc-spec.sh --reconcile` and print
  its migration report.
- **`malformed`** → a present-but-broken canonical file. This is the
  `[doc-sync-no-config]` halt path surfaced by Stage 1's engine call (Step 3) —
  NOT a reconcile target (a hand-broken canonical file is never auto-clobbered).
  Do not seed and do not reconcile; let Step 3 surface the `stage1/registry`
  finding.

```bash
SEEDED=no
RECONCILE_DIRECTIVE=""
_DA_GEN=$(bash "$_DA_ENGINE" --classify 2>/dev/null | awk -F= '/^GENERATION=/{print $2}')
_DA_DUP=$(bash "$_DA_ENGINE" --classify 2>/dev/null | awk -F= '/^DUPLICATE=/{print $2}')
case "$_DA_GEN" in
  absent)
    _DA_TMP=$(mktemp -d)
    if bash "$_DA_ENGINE" --seed > "$_DA_TMP/doc-spec.md" 2>/dev/null \
       && [ -s "$_DA_TMP/doc-spec.md" ] \
       && DOC_SPEC_PATH="$_DA_TMP/doc-spec.md" bash "$_DA_ENGINE" --validate >/dev/null 2>&1; then
      mkdir -p "$_DA_ROOT/spec"
      mv "$_DA_TMP/doc-spec.md" "$_DA_ROOT/spec/doc-spec.md"
      SEEDED=yes
    fi
    rm -rf "$_DA_TMP"
    ;;
  legacy)
    RECONCILE_DIRECTIVE="RECONCILE: doc-spec.md is on the legacy yaml generation — run /CJ_doc_audit --reconcile to migrate it to the canonical 3-column Markdown table (preserves every declared row; writes a .bak)"
    ;;
  canonical)
    if [ "$_DA_DUP" = "1" ]; then
      RECONCILE_DIRECTIVE="RECONCILE: a duplicate doc-spec contract file exists at both spec/ and root — run /CJ_doc_audit --reconcile (reconciles the canonical spec/ copy and reports the redundant one; does not auto-delete)"
    fi
    ;;
  malformed) : ;;  # Stage 1's engine call surfaces the stage1/registry halt.
  *) : ;;
esac
echo "seeded: $SEEDED"
[ -n "$RECONCILE_DIRECTIVE" ] && echo "$RECONCILE_DIRECTIVE"
```

A failed seed delivery (the `absent` branch falls through) is a STAGE-1
finding: `FINDING: stage1/seed — doc-spec.sh --seed did not emit a valid
doc-spec.md`.

### Step 0: `--reconcile` flag (standalone only — opt-in write)

Parse the skill's arguments for `--reconcile`. When present AND running
standalone (NOT inside `/CJ_qa-work-item` — the in-QA path NEVER passes it),
and when Step 2's classify reported `legacy` or `duplicate`, forward to the
engine's opt-in write path and print its migration report verbatim in the
Stage-1 section:

```bash
if [ "$DOC_AUDIT_RECONCILE" = "1" ] && { [ "$_DA_GEN" = "legacy" ] || [ "$_DA_DUP" = "1" ]; }; then
  bash "$_DA_ENGINE" --reconcile
fi
```

The audit `--reconcile` flag is the ONLY way the audit writes the contract (the
engine's `--reconcile` is the ONLY new write path). A plain (no-flag) run is
read-mostly: its only write stays the idempotent `absent` → seed delivery. The
RECONCILE directive on a plain run is ADVISORY — it points at the remedy and
writes nothing.

## Step 3: Stage 1 — deterministic conformance (engine)

ONE engine call. Print its output VERBATIM as the stage-1 section of the
report — no executor-authored conformance loops exist in this skill:

```bash
bash "$_DA_ENGINE" --check-on-disk
```

The engine probes registry existence itself (absent ⇒ `REGISTRY=absent` +
exit 0 — cannot normally occur here, Step 2 just delivered the seed; if it
does, the `stage1/seed` finding above already covers it), validates the
MERGED registry (`spec/doc-spec.md` + `spec/doc-spec-custom.md`-if-present),
then runs the four conformance checks — declared-exists, orphans (docs/*.md
maxdepth 1 + spec/*.md), root-declared, human-doc-ids — emitting
`check: <id> — PASS` / `FINDING: stage1/<id> — <detail>` lines plus the
`CHECKS_RUN=`/`FINDINGS=` tail. Its `FINDINGS=` count IS the engine-check
portion of `STAGE1_FINDINGS`.

When `declared-exists` finds required docs missing on disk, the engine also
emits a trailing `REMEDIATION: stage1/declared-exists — …` advisory line that
names `/CJ_document-release` as the scaffolder (it reads this same merged
registry and stub-scaffolds the missing docs). The remediation line is NOT a
finding — it does not change `FINDINGS=` or `STAGE1_FINDINGS`. It exists so a
standalone / consumer-repo run is actionable rather than a dead-end list of
missing docs: the audit stays read-mostly and never scaffolds them itself, but
it points at the verb that does.

A present-but-invalid registry makes the engine exit 1 with
`[doc-sync-no-config] <reason>`: count ONE STAGE-1 finding —
`FINDING: stage1/registry — <the engine's reason, quoted>` — and skip Stages
2+3 (their inputs are unparseable; each still prints its section header +
`skipped: registry invalid — nothing to judge against` + `STAGE*_FINDINGS=0`).

Capture `DOCS_AUDITED` as the merged `--list-declared` count.

### Step 3b: workflow-docs freshness (the generated workflow surface)

Stage 1 ALSO runs the workflow-docs freshness check when the engine is present —
the same `--render-docs --check` owner that `validate.sh` Check 27 calls, so a
stale `docs/workflow.md` / `docs/workflows/*.md` is caught standalone in ANY repo
that carries the engine (F000069/S000115). The workflow surface is GENERATED from
`spec/workflow-spec.md`; this check renders to a temp dir, diffs vs on-disk, and
reports a freshness finding if the surface drifted from the registry:

```bash
_DA_WFENGINE=""
if [ -x "$_DA_ROOT/scripts/workflow-spec.sh" ]; then
  _DA_WFENGINE="$_DA_ROOT/scripts/workflow-spec.sh"
elif [ -x "${CJ_SHARED_SCRIPTS:-$HOME/.claude/_cj-shared/scripts}/workflow-spec.sh" ]; then
  _DA_WFENGINE="${CJ_SHARED_SCRIPTS:-$HOME/.claude/_cj-shared/scripts}/workflow-spec.sh"
fi
if [ -n "$_DA_WFENGINE" ] && [ "$(bash "$_DA_WFENGINE" --classify 2>/dev/null | awk -F= '/^GENERATION=/{print $2}')" = "canonical" ]; then
  if bash "$_DA_WFENGINE" --render-docs --check >/dev/null 2>&1; then
    echo "check: stage1/workflow-render — PASS (generated workflow surface in sync with spec/workflow-spec.md)"
  else
    echo "FINDING: stage1/workflow-render — the generated workflow surface (docs/workflow.md + docs/workflows/) is stale vs spec/workflow-spec.md (run: scripts/workflow-spec.sh --render-docs)"
  fi
fi
```

Each `FINDING: stage1/workflow-render` line counts toward `STAGE1_FINDINGS`. When
the engine is absent or `spec/workflow-spec.md` is not canonical (a consumer repo
without the workflow registry) the check is skipped silently — no finding, no
noise (the registry-gated posture mirrors Check 27).

## Fresh-context dispatch (standalone posture — REQUIRED)

At top level (standalone), Stages 2+3 MUST be executed by ONE fresh
general-purpose subagent via the Agent tool. The dispatch prompt carries
ONLY:

1. the repo root path,
2. the engine path (`$_DA_ENGINE`),
3. the Stage-1 report (the verbatim `--check-on-disk` output + `seeded:`),
4. the Stage-2 and Stage-3 protocols below (copy them into the prompt),

and explicitly NOT the invoking session's beliefs about the docs — no "we
just updated X", no summaries of recent work. The subagent reads the docs and
the repo cold, judges per the protocols, and returns the two stage sections
VERBATIM (the per-doc verdict lines + FINDING lines, under the two section
headers). The invoking skill splices them into the report unchanged.

When the operator runs `/CJ_doc_audit` and `/CJ_test_audit` together, the
same single subagent MAY judge both audits' Stages 2+3 in one dispatch (one
fresh context is the point; two dispatches are not required).

**In-QA degradation (honest, documented).** Inside `/CJ_qa-work-item` Step
8.6c the QA agent is ALREADY a subagent and cannot spawn subagents (the
nested-subagent wall) — it executes Stages 2+3 INLINE per the same protocols.
No pretend-dispatch: the report is identical in shape, and the standalone
fresh-context run is the independence proof.

## Step 4: Stage 2 — requirement compliance (agent-judged, evidence-forced)

For EACH declared doc in the merged registry (enumerate via
`--list-declared`; read each row's `Requirement` cell from the registry table):

1. **Quote** the doc's `Requirement` cell.
2. **Decompose** it into clauses (e.g. "Arranged by principle" / "states the
   repo's first principle(s)" / "no work-item IDs").
3. **Check each clause** against the doc's ACTUAL content (read the doc).
4. **Emit exactly one verdict line** per doc, citing the decisive evidence:

```
<path>: satisfies
<path>: missing-requirement (soft — no requirement: declared)
<path>: n/a — <why out of scope for this run's judgment>
FINDING: stage2/<path> — clause '<clause>' not met: <evidence>
```

Only `FINDING:` lines count toward `STAGE2_FINDINGS` (`missing-requirement`
and `n/a` are non-counting). A doc failing multiple clauses emits one FINDING
line per failed clause. Clauses already proven deterministically by Stage 1
(e.g. "no work-item IDs" = the `human-doc-ids` check) are CITED from Stage 1's
output ("human-doc-ids: PASS per Stage 1"), never re-derived.

## Step 5: Stage 3 — implementation drift (agent-judged, evidence-forced)

Ground truth FIRST, judgment second. Never judge a doc's claims from memory —
enumerate the live repo state, then cross-walk.

**5.1 — Enumerate ground truth** (emit one summary line opening the stage-3
section, e.g. `ground truth: 23 routable skills, 31 scripts/*.sh, 4
workflows, 4 spec-registry files, 9 top-level dirs`):

- Routable skills: `jq -r '.[] | select(.status != "deprecated") |
  select((.files | length) > 0) | .name' skills-catalog.json` — ONLY when
  `skills-catalog.json` exists. In a no-catalog consumer repo, skip the
  catalog-dependent cross-walks with a named note (the guard pattern:
  `note: no skills-catalog.json — catalog cross-walks skipped`); the
  script/dir cross-walks still run.
- Scripts on disk: `scripts/*.sh` (when the dir exists).
- CI workflows: `.github/workflows/*` (when present).
- The spec-registry family: `spec/*.md` on disk.
- Top-level directories: `ls -d */`.

**5.2 — Cross-walk each contract doc** per the doc-type playbook (apply the
rows that exist in THIS repo):

| Doc | Cross-walk |
|---|---|
| `docs/workflow.md` + `docs/workflows/*.md` | GENERATED surface (sourced from `spec/workflow-spec.md` by `workflow-spec.sh --render-docs`) — its freshness is owned by Stage 1's `stage1/workflow-render` check, NOT re-judged here. Do NOT flag it as an orphan, an uncontemplated surface, or hand-authored drift; cross-walk the REGISTRY instead. Names every routable skill: every routable `CJ_goal_*` skill has a `## <name>` orchestrator entry in `spec/workflow-spec.md`, and the registry mentions NO retired/nonexistent skill. |
| `docs/philosophy.md` | Its decision tree covers every ACTIVE routable skill. |
| `docs/architecture.md` | Every named piece of machinery (scripts, registries, checks, helpers) exists on disk. |
| `README.md` | Its folder-structure section matches the actual tree. |
| `CLAUDE.md` | Every scripts-reference row points at an existing script. |
| Other declared docs | Named files/dirs/commands they reference exist; spec-registry docs' named parsers exist. |

**5.3 — Verdict per doc** (one line each):

```
<path>: no-drift
FINDING: stage3/<path> — <named delta, e.g. "mentions retired scripts/test-pipeline.sh" / "routable skill CJ_x absent from the workflow list">
```

Only `FINDING:` lines count toward `STAGE3_FINDINGS`. Every finding NAMES the
delta against the enumerated ground truth — never "seems stale".

## Step 6: Emit the per-stage report

Always emit, in this order (the grep-able contract callers parse):

```
DOC_AUDIT: <ok|findings>
FINDINGS=<n>              # total = stage1 + stage2 + stage3
STAGE1_FINDINGS=<n>
STAGE2_FINDINGS=<n>
STAGE3_FINDINGS=<n>
DOCS_AUDITED=<n>          # the merged --list-declared count
seeded: <yes|no>
--- stage 1: deterministic conformance (engine) ---
<any advisory RECONCILE: directive from Step 2 (legacy/duplicate — NOT a finding);
 the --check-on-disk output verbatim — check:/FINDING: lines, the
 CHECKS_RUN=/FINDINGS= tail, and (when declared docs are missing) the trailing
 REMEDIATION: stage1/declared-exists line naming /CJ_document-release; plus any
 stage1/engine, stage1/seed, stage1/registry pre-stage FINDING lines; and, under
 the standalone --reconcile flag, the engine's migration report (RECONCILE:
 migrated N rows / ...)>
--- stage 2: requirement compliance (agent-judged, fresh-context) ---
<per-doc verdict lines + FINDING: stage2/... lines>
--- stage 3: implementation drift (agent-judged, fresh-context) ---
<ground-truth summary line + per-doc verdict lines + FINDING: stage3/... lines>
```

In-QA (inline) runs label the stage-2/3 headers `(agent-judged, inline)`
instead of `(agent-judged, fresh-context)` — the posture is part of the
report, never hidden. `DOC_AUDIT: ok` REQUIRES all three stage counts = 0;
`FINDINGS` always equals their sum. The `stage1/` / `stage2/` / `stage3/`
finding prefixes keep stages grep-able even when a consumer flattens the
report.

**Pre-stage findings and skipped stages (the error-path grammar).** The
engine-unreachable (Step 1), seed-delivery-failure (Step 2), and
registry-invalid (Step 3) findings are deterministic — they count toward
`STAGE1_FINDINGS` and print inside the stage-1 section with prefixes
`stage1/engine`, `stage1/seed`, `stage1/registry`. When a pre-stage failure
makes later stages unjudgeable, each skipped stage still prints its section
header with ONE line — `skipped: <reason>` — and its `STAGE*_FINDINGS=0`.
The report shape never collapses on the error path.

## Error handling (stage terms)

| Condition | Stage accounting | Behavior |
|---|---|---|
| Not a git repo | (pre-audit) | "Error: /CJ_doc_audit requires a git repository." — stop |
| Engine unreachable | `FINDING: stage1/engine` → `STAGE1_FINDINGS` | Stages 2+3 print headers + `skipped: engine unreachable — nothing to judge against`; `DOC_AUDIT: findings` |
| Seed delivery fails | `FINDING: stage1/seed` → `STAGE1_FINDINGS` | audit continues on whatever exists |
| Registry present-but-invalid | ONE `FINDING: stage1/registry` quoting `[doc-sync-no-config]` → `STAGE1_FINDINGS` | Stages 2+3 print headers + `skipped: registry invalid — nothing to judge against` |
| Legacy / duplicate contract file | advisory `RECONCILE:` directive — NOT a finding, counts toward NO stage | Plain run points at the remedy + writes nothing; `--reconcile` (standalone) forwards to the engine migration |
| Stage-1 engine findings | `FINDING: stage1/<check-id>` lines → `STAGE1_FINDINGS` | Stages 2+3 still run (the registry parsed; the disk just disagrees) |
| Any findings | counted in their stage | reported, exit clean — findings are the product, not a crash |
