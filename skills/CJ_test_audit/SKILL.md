---
name: CJ_test_audit
description: "Three-stage test audit against a repo's test contract — runnable standalone in ANY repo. Ensures the two-tier test contract is CANONICAL via test-spec.sh --classify: absent → seed-deliver spec/test-spec.md (seeded: yes; idempotent seeded: no on re-run); canonical → ok; duplicate → an advisory RECONCILE: directive in the Stage-1 report (NO auto-write; run /CJ_test_audit --reconcile — a dedup/no-op, since test-spec's fenced-yaml format never diverged, so unlike doc-spec there is no legacy migration). Stage 1 (deterministic — engine, unchanged mechanics): test-spec.sh --validate + --check-coverage (forward anchor-grep per unit, reverse sweep of live surfaces, >=20-token floor — all units-gated, so a rules-only consumer repo gets a named 'coverage cross-check inactive' note, never a misleading finding), findings prefixed stage1/. Stage 2 (requirement compliance — agent-judged, evidence-forced): each general RULE's statement quoted and judged with cited evidence (suite-green cites the freshest full-suite run; new-code-tested cites the diff-vs-units comparison), each overlay UNIT's purpose/label judged for truthfulness against the source at its anchor (the anchor-greps-while-the-description-rots catch), AND — when the overlay declares the behavior-coverage axis — each declared BEHAVIOR judged for substance the deterministic check can't reach (statement falsifiable/specific? level correct? linked test proves vs merely mentions? one broad test over-claimed?), findings prefixed stage2/behavior:&lt;id&gt;. Stage 3 (implementation drift — agent-judged): enumerate live verification surfaces (tests on disk, validate banners, workflows, hooks), judge coverage-in-substance — a unit row that no longer reflects reality, or a NEW surface class the rules don't contemplate. Standalone runs MUST dispatch Stages 2+3 to ONE fresh-context subagent (Agent tool; the same subagent MAY judge both audits when run together); inside a QA subagent (qa.md Step 8.6d) they run INLINE (a subagent cannot spawn subagents). Per-stage report: TEST_AUDIT: <ok|findings> + FINDINGS= + STAGE1/2/3_FINDINGS= + UNITS_AUDITED= + seeded: + three --- stage N --- sections. Findings never crash the audit — a broken contract IS the report. Engine resolution repo-local scripts/test-spec.sh then ~/.claude/_cj-shared/scripts/. Use when: 'audit this repo's tests', 'are tests aligned with the test spec', 'check the test coverage contract'."
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

If `NOT_A_GIT_REPO`: tell the user "Error: /CJ_test_audit requires a git repository." and stop.

## Overview

`/CJ_test_audit` answers one question in ANY repo: **are this repo's tests
aligned with its test contract?** The contract is the two-tier test-spec
registry — the portable general rules (`spec/test-spec.md`, byte-identical to
`test-spec.sh --seed`: tests-discoverable, suite-green, new-code-tested,
units-anchored, single-owner) plus an optional repo-specific units overlay
(`spec/test-spec-custom.md`) the parser merges in. The audit runs in **three
named stages**, symmetric with `/CJ_doc_audit` (one shape, both audits):

- **Stage 1 — deterministic conformance (engine, unchanged mechanics):** the
  existing engine calls — `test-spec.sh --validate` + `--check-coverage` —
  with the registry-existence probe and the units-gated floor exactly as
  shipped. Findings carry the `stage1/` prefix.
- **Stage 2 — requirement compliance (agent-judged, evidence-forced):** each
  general RULE's `statement` quoted and judged with cited evidence; each
  overlay UNIT's `purpose`/`label` text judged for truthfulness against the
  source at its anchor.
- **Stage 3 — implementation drift (agent-judged, evidence-forced):** live
  verification surfaces enumerated FIRST, then coverage-in-substance judged —
  where Stage 1 proves a mapping EXISTS, Stage 3 judges whether it is still
  TRUE.

Findings never crash the audit and never halt a caller: a broken contract IS
the report. The audit is read-mostly — on a plain run its ONLY write is the
idempotent seed delivery (Step 2). A non-canonical contract (a duplicated file)
is detected by `test-spec.sh --classify` and surfaced as an advisory
`RECONCILE:` directive in the Stage-1 report (no write); the dedup runs ONLY
under the opt-in standalone `--reconcile` flag, which forwards to the engine's
`--reconcile`. NOTE — symmetric with `/CJ_doc_audit` but reduced: test-spec's
fenced-yaml format never diverged (confirmed from git history), so there is no
legacy-to-canonical migration; `--reconcile` is a dedup / no-op. The in-QA path
never passes `--reconcile`, and the directive — like a `REMEDIATION:` line —
never crashes the audit or flips QA red.

**Judge context (load-bearing).** Standalone (operator keystroke at top
level): Stages 2+3 are REQUIRED to run in ONE fresh-context general-purpose
subagent (the Agent tool) — see "Fresh-context dispatch" below. Inside a QA
subagent (`/CJ_qa-work-item` qa.md Step 8.6d, inside a cj_goal run): a
subagent cannot spawn subagents (the nested-subagent wall), so the QA agent
executes ALL stages — including 2+3 — INLINE by reading this file, following
the same stage protocols. This inline posture is an honest degradation; the
standalone fresh-context run is the independence proof. Both postures produce
the identical per-stage report shape.

## Step 1: Resolve the engine

The deterministic stage runs on `test-spec.sh`. Resolve it repo-local first,
then the deployed shared home:

```bash
_TA_ROOT=$(git rev-parse --show-toplevel)
_TA_ENGINE=""
if [ -x "$_TA_ROOT/scripts/test-spec.sh" ]; then
  _TA_ENGINE="$_TA_ROOT/scripts/test-spec.sh"
elif [ -x "${CJ_SHARED_SCRIPTS:-$HOME/.claude/_cj-shared/scripts}/test-spec.sh" ]; then
  _TA_ENGINE="${CJ_SHARED_SCRIPTS:-$HOME/.claude/_cj-shared/scripts}/test-spec.sh"
fi
[ -n "$_TA_ENGINE" ] || echo "ENGINE_UNREACHABLE"
```

If `ENGINE_UNREACHABLE`: this is a STAGE-1 finding —
`FINDING: stage1/engine — test-spec.sh unreachable (repo-local scripts/ +
deployed _cj-shared both absent); run 'skills-deploy install'`. Nothing else
can run; emit the per-stage report (Step 6) with `STAGE1_FINDINGS=1`, Stages
2+3 each printing their header + `skipped: engine unreachable — nothing to
judge against`, and `TEST_AUDIT: findings`.

## Step 2: Ensure the contract is canonical (classify → seed | ok | reconcile)

This step generalizes the former "seed if missing" into a **classify-driven
reconcile** (F000065), symmetric with `/CJ_doc_audit` Step 2. Run
`test-spec.sh --classify` (READ-ONLY) and route on `GENERATION`:

- **`absent`** → seed-deliver (today's behavior, unchanged): create `spec/`,
  write the seed to a temp file, verify non-empty AND `--validate`-clean, THEN
  move into place (the corruption guard). Report `seeded: yes`.
- **`canonical`** → nothing to do (`seeded: no`); NO `RECONCILE:` line (the
  canonical repo stays silent).
- **`duplicate`** (`DUPLICATE=1`) → a redundant copy at both `spec/` and root.
  Emit an advisory `RECONCILE:` directive naming the issue + remedy, write
  NOTHING on a plain run. (There is NO `legacy` branch for test-spec — its
  fenced-yaml format never diverged, so `--reconcile` is a dedup / no-op.)
- **`malformed`** → a present-but-broken registry; the `[test-spec-no-config]`
  halt surfaced by Stage 1's `--validate` call (Step 3) — not a reconcile
  target.

```bash
SEEDED=no
RECONCILE_DIRECTIVE=""
_TA_GEN=$(bash "$_TA_ENGINE" --classify 2>/dev/null | awk -F= '/^GENERATION=/{print $2}')
_TA_DUP=$(bash "$_TA_ENGINE" --classify 2>/dev/null | awk -F= '/^DUPLICATE=/{print $2}')
case "$_TA_GEN" in
  absent)
    _TA_TMP=$(mktemp -d)
    if bash "$_TA_ENGINE" --seed > "$_TA_TMP/test-spec.md" 2>/dev/null \
       && [ -s "$_TA_TMP/test-spec.md" ] \
       && TEST_SPEC_PATH="$_TA_TMP/test-spec.md" bash "$_TA_ENGINE" --validate >/dev/null 2>&1; then
      mkdir -p "$_TA_ROOT/spec"
      mv "$_TA_TMP/test-spec.md" "$_TA_ROOT/spec/test-spec.md"
      SEEDED=yes
    fi
    rm -rf "$_TA_TMP"
    ;;
  canonical)
    if [ "$_TA_DUP" = "1" ]; then
      RECONCILE_DIRECTIVE="RECONCILE: a duplicate test-spec contract file exists at both spec/ and root — run /CJ_test_audit --reconcile (reports the redundant copy; does not auto-delete; test-spec has no legacy migration)"
    fi
    ;;
  malformed) : ;;  # Stage 1's --validate surfaces the stage1/registry halt.
  *) : ;;
esac
echo "seeded: $SEEDED"
[ -n "$RECONCILE_DIRECTIVE" ] && echo "$RECONCILE_DIRECTIVE"
```

A failed seed delivery (the `absent` branch falls through) is a STAGE-1
finding: `FINDING: stage1/seed — test-spec.sh --seed did not emit a valid
test-spec.md`.

### Step 0: `--reconcile` flag (standalone only — opt-in)

Parse the skill's arguments for `--reconcile`. When present AND running
standalone (NOT inside `/CJ_qa-work-item` — the in-QA path NEVER passes it),
and when Step 2's classify reported `duplicate`, forward to the engine's opt-in
path and print its report verbatim in the Stage-1 section:

```bash
if [ "$TEST_AUDIT_RECONCILE" = "1" ] && [ "$_TA_DUP" = "1" ]; then
  bash "$_TA_ENGINE" --reconcile
fi
```

For test-spec the engine's `--reconcile` is a dedup / no-op (it reports the
redundant copy; it never migrates a format, because the format never diverged).
A plain (no-flag) run is read-mostly: its only write stays the idempotent
`absent` → seed delivery.

## Step 3: Stage 1 — deterministic conformance (engine, unchanged mechanics)

The existing engine calls, printed verbatim as the stage-1 section:

```bash
bash "$_TA_ENGINE" --validate
```

The engine merges `spec/test-spec.md` + `spec/test-spec-custom.md`-if-present
(overlay-absent repos: nothing to merge, no finding; `REGISTRY=absent` cannot
occur here — Step 2 just guaranteed the general file). A non-zero exit
(present-but-invalid registry: schema, closed enums, duplicate ids, the
test-row source pin, a work-item ID in a rendered field) is ONE STAGE-1
finding — `FINDING: stage1/registry — <the engine's [test-spec-no-config]
reason, quoted>` — and Stages 2+3 are skipped (each prints its header +
`skipped: registry invalid — nothing to judge against` + `STAGE*_FINDINGS=0`).

On success, capture the unit count and run the coverage cross-check:

```bash
UNITS_AUDITED=$(bash "$_TA_ENGINE" --list-units 2>/dev/null | grep -c . || true)
bash "$_TA_ENGINE" --check-coverage
```

- Exit 0 with `OK coverage ...` — the forward anchor-grep (`units-anchored`),
  reverse sweep (`single-owner` + `tests-discoverable`), and token floor are
  all clean.
- Exit 0 with the named note `no units declared — coverage cross-check
  inactive; declare units in spec/test-spec-custom.md to activate` — a
  rules-only registry (the seeded consumer default). NOT a finding; report
  the note verbatim (the honest "inactive" state).
- Exit 1 — each `FINDING:` line the engine printed is one STAGE-1 finding;
  quote it verbatim with the `stage1/` prefix
  (`FINDING: stage1/coverage — <engine line>`).

## Fresh-context dispatch (standalone posture — REQUIRED)

At top level (standalone), Stages 2+3 MUST be executed by ONE fresh
general-purpose subagent via the Agent tool. The dispatch prompt carries
ONLY:

1. the repo root path,
2. the engine path (`$_TA_ENGINE`),
3. the Stage-1 report (the verbatim `--validate` + `--check-coverage` output,
   `UNITS_AUDITED`, `seeded:`),
4. the Stage-2 and Stage-3 protocols below (copy them into the prompt),

and explicitly NOT the invoking session's beliefs about the tests. The
subagent reads the registry, the rules, the units, and the live surfaces
cold, judges per the protocols, and returns the two stage sections VERBATIM.
The invoking skill splices them into the report unchanged.

When the operator runs `/CJ_doc_audit` and `/CJ_test_audit` together, the
same single subagent MAY judge both audits' Stages 2+3 in one dispatch (one
fresh context is the point; two dispatches are not required).

**In-QA degradation (honest, documented).** Inside `/CJ_qa-work-item` Step
8.6d the QA agent is ALREADY a subagent and cannot spawn subagents (the
nested-subagent wall) — it executes Stages 2+3 INLINE per the same protocols.
No pretend-dispatch: the report is identical in shape, and the standalone
fresh-context run is the independence proof.

## Step 4: Stage 2 — requirement compliance (agent-judged, evidence-forced)

Two halves, each evidence-forced:

**4.1 — Per general RULE** (enumerate via the merged registry's `rules:`):
quote the rule's `statement`, judge whether the repo CURRENTLY honors it, and
emit one verdict line citing the decisive evidence:

- **`suite-green`** — cite the FRESHEST full-suite evidence: inside a cj_goal
  QA run, the QA pass that just completed IS the evidence; standalone, run
  the repo's declared runner when one exists and is affordable (this
  workbench: `./scripts/test.sh`), else verdict `n/a — no affordable
  full-suite evidence this run` with the reason. A red suite is a finding.
- **`new-code-tested`** — cite the diff-vs-units comparison: inspect the
  current branch's diff against its base (`git diff --name-only @{upstream}`
  or the default branch); new/changed non-doc code with NO corresponding test
  surface (no new/changed `tests/*` and no `units:` row addition) is a
  finding; doc-only diffs are vacuously green.
- **`tests-discoverable` / `units-anchored` / `single-owner`** — Stage 1's
  coverage cross-check IS the deterministic evidence where units exist; cite
  it ("per Stage 1's reverse sweep") rather than re-deriving. In a rules-only
  repo, judge `tests-discoverable` directly (does a declared runner exist?).

**4.2 — Per overlay UNIT** (enumerate via `--list-units`; the row schema is
`id/family/label/anchor/source/layer/disposition/trigger/purpose` — there is
no `asserts` field): judge whether the unit's `purpose` (and `label`) text
still TRUTHFULLY describes what the source at the anchor does. The anchor can
still grep (Stage 1 forward check green) while the description rots — this is
Stage 2's unique catch. Read the source at the anchor for any unit whose
description looks doubtful; spot-coverage of every unit is not required, but
every unit touched by the current change MUST be checked.

**4.3 — Per declared BEHAVIOR** (F000066; enumerate via `--list-behaviors`,
present only when the overlay declares the behavior-coverage axis — skip this
half cleanly with a one-line note when `--list-behaviors` is empty). This is
the load-bearing substance half (premise P5): Stage 1's deterministic
behavior-coverage checks only prove the links resolve and the `anchor` greps
live — they CANNOT tell whether the linked test genuinely proves the behavior
or merely mentions it. For each behavior, read its `statement` + `level` and
the linked test at each `behavior_coverage` row's `source`/`anchor`, then judge
(evidence-forced):

- **Falsifiable / specific?** Is the `statement` specific enough that a real
  regression would make it fail, or is it vague prose ("mutations work") that
  could pass against almost anything? A statement so broad that no test could
  disprove it is a finding.
- **`level` correct?** Does the declared `level` (`unit | integration |
  contract | workflow | property`) match what the linked test actually
  exercises? A behavior marked `unit` but proven only by a broad end-to-end
  smoke (or vice-versa) is a mis-level finding.
- **Proves vs mentions?** Does the test at the anchor actually ASSERT the
  behavior, or does the anchor merely appear in a comment / log string / unrelated
  line? A `grep -F`-passing-but-semantically-empty anchor (the deterministic
  check's blind spot) is the prime finding here.
- **Over-claimed?** Is ONE broad test linked as the proof for MANY behaviors
  such that it cannot really prove each? A single suite cited across several
  distinct behaviors, none of which it specifically asserts, is over-claim
  drift.

Every behavior touched by the current change MUST be checked; spot-coverage of
the rest is acceptable but call out any obviously vague/over-claimed row.

Verdict grammar (one line per rule + one per judged unit + one per judged behavior):

```
<rule-id|unit-id>: satisfies — <evidence cited>
<rule-id|unit-id>: n/a — <why out of scope>
behavior:<id>: faithful — <level + proves-the-statement evidence cited>
FINDING: stage2/<rule-id|unit-id> — <clause/description not met: evidence>
FINDING: stage2/behavior:<id> — <vague | mis-leveled | mentions-not-proves | over-claimed: evidence>
```

Only `FINDING:` lines count toward `STAGE2_FINDINGS`.

## Step 5: Stage 3 — implementation drift (agent-judged, evidence-forced)

Ground truth FIRST, judgment second.

**5.1 — Enumerate the live verification surfaces** (the reverse-sweep inputs;
emit one summary line opening the stage-3 section, e.g. `ground truth: 28
tests/*.test.sh, 24 validate banners, 4 workflows, 2 installed hooks`):

- `tests/*.test.sh` on disk.
- Live validate banners/comments (this repo: `scripts/validate.sh` check
  banners) where a validator exists.
- `.github/workflows/*` (when present).
- Installed git hooks.

**5.2 — Judge coverage-in-substance** against the registry:

- A live surface whose unit row EXISTS (Stage 1's reverse sweep proves the
  mapping) but whose row no longer reflects reality — the suite was gutted,
  repurposed, or its assertions moved — is drift. Where Stage 1 proves a
  mapping EXISTS, Stage 3 judges whether it is still TRUE.
- A NEW surface class the rules don't contemplate (e.g. the repo gained a
  fuzzing harness, a benchmark gate, or a deployment smoke that no rule or
  unit family covers) is drift: the contract no longer describes the
  verification surface.

**5.3 — Verdict lines:**

```
<surface|unit-id>: no-drift
FINDING: stage3/<surface|unit-id> — <named delta, e.g. "unit row describes 7 assertions; suite now only smoke-checks existence" / "new surface class .github/workflows/bench.yml uncontemplated by the rules">
```

Only `FINDING:` lines count toward `STAGE3_FINDINGS`. Every finding NAMES the
delta against the enumerated ground truth.

## Step 6: Emit the per-stage report

Always emit, in this order (the grep-able contract callers parse):

```
TEST_AUDIT: <ok|findings>
FINDINGS=<n>              # total = stage1 + stage2 + stage3
STAGE1_FINDINGS=<n>
STAGE2_FINDINGS=<n>
STAGE3_FINDINGS=<n>
UNITS_AUDITED=<n>         # --list-units count post-validate (0 = rules-only)
BEHAVIORS_AUDITED=<n>     # --list-behaviors count (0 = no behavior-coverage axis)
seeded: <yes|no>
--- stage 1: deterministic conformance (engine) ---
<any advisory RECONCILE: directive from Step 2 (duplicate — NOT a finding);
 the --validate + --check-coverage output verbatim; plus any stage1/engine,
 stage1/seed, stage1/registry pre-stage FINDING lines; and, under the standalone
 --reconcile flag, the engine's dedup report>
--- stage 2: requirement compliance (agent-judged, fresh-context) ---
<per-rule + per-unit + per-behavior verdict lines + FINDING: stage2/... lines>
--- stage 3: implementation drift (agent-judged, fresh-context) ---
<ground-truth summary line + verdict lines + FINDING: stage3/... lines>
```

In-QA (inline) runs label the stage-2/3 headers `(agent-judged, inline)`
instead of `(agent-judged, fresh-context)`. `TEST_AUDIT: ok` REQUIRES all
three stage counts = 0; `FINDINGS` always equals their sum. The inactive-
coverage note and `n/a` verdicts never block `ok`. The `stage1/` / `stage2/`
/ `stage3/` prefixes keep stages grep-able even when a consumer flattens the
report.

**Pre-stage findings and skipped stages (the error-path grammar).** The
engine-unreachable (Step 1), seed-delivery-failure (Step 2), and
registry-invalid (Step 3) findings are deterministic — they count toward
`STAGE1_FINDINGS` with prefixes `stage1/engine`, `stage1/seed`,
`stage1/registry` and print inside the stage-1 section. When a pre-stage
failure makes later stages unjudgeable, each skipped stage still prints its
section header with ONE line — `skipped: <reason>` — and its
`STAGE*_FINDINGS=0`. The report shape never collapses on the error path.

## Error handling (stage terms)

| Condition | Stage accounting | Behavior |
|---|---|---|
| Not a git repo | (pre-audit) | "Error: /CJ_test_audit requires a git repository." — stop |
| Engine unreachable | `FINDING: stage1/engine` → `STAGE1_FINDINGS` | Stages 2+3 print headers + `skipped: engine unreachable — nothing to judge against`; `TEST_AUDIT: findings` |
| Seed delivery fails | `FINDING: stage1/seed` → `STAGE1_FINDINGS` | audit continues on whatever exists |
| Registry present-but-invalid | ONE `FINDING: stage1/registry` quoting `[test-spec-no-config]` → `STAGE1_FINDINGS` | Stages 2+3 print headers + `skipped: registry invalid — nothing to judge against` |
| Duplicate contract file | advisory `RECONCILE:` directive — NOT a finding, counts toward NO stage | Plain run points at the remedy + writes nothing; `--reconcile` (standalone) forwards to the engine dedup (test-spec has no legacy migration) |
| Coverage findings | `FINDING: stage1/coverage — <engine line>` → `STAGE1_FINDINGS` | Stages 2+3 still run (the registry parsed; the surface just disagrees) |
| No units declared | the named inactive note — never a finding | `UNITS_AUDITED=0`; Stage 2's unit half is vacuous, the rule half still runs |
| No behaviors declared | the named "behavior coverage inactive" note — never a finding | `BEHAVIORS_AUDITED=0`; Stage 2's behavior half (4.3) is skipped cleanly with a one-line note |
| Any findings | counted in their stage | reported, exit clean — findings are the product, not a crash |
