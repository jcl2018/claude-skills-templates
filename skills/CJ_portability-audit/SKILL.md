---
name: CJ_portability-audit
description: "Static dependency lint for declared skill portability. Compares each catalog skill's declared `portability` field against its ACTUAL executed repo-local dependencies (root scripts/*.sh helpers, root config, CLAUDE.md, the manifest `.source` reach-back) using a strict tier ladder (standalone < local-only < workbench), an EXECUTED-vs-documented precision rule, bundled-own-script + scoped self-resolution-preamble carve-outs, and an optional `portability_requires` accepted-deps field. Emits a per-skill verdict (portable / portable-with-notes / findings:<list>). Engine-in-script; also wired into validate.sh as an advisory check (exit 0 in v1; PORTABILITY_STRICT=1 flips to hard-fail). Workbench-only. Use when: 'audit skill portability', 'check declared-vs-actual dependencies', 'is this skill really standalone'."
version: 0.1.0
allowed-tools:
  - Bash
  - Read
  - Glob
  - Grep
---

## Preamble

Check for collection updates (silent if none, banner if a newer version is available):

```bash
_S=$(jq -r '.source // empty' "$HOME/.claude/.skills-templates.json" 2>/dev/null)
[ -n "$_S" ] && [ -x "$_S/scripts/skills-update-check" ] && "$_S/scripts/skills-update-check" 2>/dev/null || true
```

Verify this is a git repository:

```bash
git rev-parse --show-toplevel 2>/dev/null || echo "NOT_A_GIT_REPO"
```

If `NOT_A_GIT_REPO`: tell the user "Error: /CJ_portability-audit requires a git repository (it reads the repo's skills-catalog.json + skills/ source tree)." and stop.

## Overview

`/CJ_portability-audit` is the **producer-side** counterpart to `/CJ_repo-init`.
Where `/CJ_repo-init` verifies a target repo HAS the per-repo prerequisites the
CJ_ family needs (consumer-side), this skill audits whether the workbench's own
skills HONESTLY declare their `portability` — i.e. whether a skill declared
`standalone` quietly reaches for repo-local artifacts (root `scripts/*.sh`
helpers, root config, `CLAUDE.md` conventions, the manifest `.source`
reach-back) that a fresh target repo will not have.

It is **advisory-first**: the current workbench HAS real declared-vs-actual
mismatches, so v1 surfaces findings WITHOUT hard-failing. The same static engine
also runs as a `validate.sh` advisory check that prints findings and **exits 0**
(a documented `PORTABILITY_STRICT=1` env flips it to hard-fail once declarations
are reconciled).

The full correct-behavior contract — the tier ladder, the EXECUTED-vs-documented
rule, the carve-outs, and the expected-findings table — is written verbatim in
[`doc/WORKFLOWS.md`](../../doc/WORKFLOWS.md) under `### /CJ_portability-audit`, so
the operator can read the intended behavior and confirm the implementation
matches. The summary below mirrors it.

### What the engine classifies

For each catalog skill in the **Check 14/15b selector set** (`status !=
"deprecated"` AND non-empty `files` — derived from the catalog at runtime, NEVER
a hardcoded list/count), the engine:

1. Collects the skill's files (catalog `files[]` + the skill dir's `*.md` + any
   `scripts/*.sh` under the skill dir).
2. Distinguishes an **EXECUTED** dependency (a ref in a runnable position —
   `bash "$X"` / `source "$X"` / `[ -f "$X" ]` / `[ -x "$X" ]` inside a ```bash
   fence or a `.sh` engine script) from a **DOCUMENTED** mention (prose / table /
   comment). The root `scripts/*.sh` helper set is derived dynamically by
   globbing `scripts/*.sh` basenames — NOT hardcoded (a hardcoded list is the
   exact baked-in-workbench rot this skill catches).
3. Classifies each hit against the skill's declared tier — a STRICT ladder where
   the bar is "works in a repo that has never seen this workbench":
   - `standalone` — own bundled scripts (`skills/<name>/scripts/`) + repo-init
     prereqs (`cj-document-release.json`, `CJ-DOC-RELEASE.md`, `TODOS.md`,
     `work-items/`) ONLY.
   - `local-only` — standalone's set PLUS the user's `~/.claude` deployed state.
   - `workbench` — everything PLUS root `scripts/*.sh`, the `.source` reach-back,
     `CLAUDE.md` reads, root config (`skills-catalog.json`, `VERSION`, …).
   An unknown `portability` value is itself a finding.
4. Applies the carve-outs:
   - **Bundled-own-script:** a `scripts/*.sh` ref resolving under the skill's OWN
     dir (`skills/<name>/scripts/…`) → OK, never a finding. Only ROOT helpers are
     candidates.
   - **Self-resolution preamble (scoped to tier):** the engine-locate / passive
     update-nudge `.source` reach-back is OK-with-note for `workbench`/`local-only`
     skills (those tiers may need the workbench); for a `standalone` skill, a
     preamble that reaches a ROOT `scripts/*.sh` engine is a FINDING.
   - **`portability_requires`:** an operator-adjudicated accepted-dep (a verbatim
     finding token) → OK; a listed-but-unreferenced entry → informational note,
     never a finding.
5. Emits a per-skill verdict: `portable` / `portable-with-notes` /
   `findings:<list>`. Each finding reads
   `<skill> declared <tier> but depends on <dep> (needs <higher-tier>)`.

## Architecture (engine-in-script / AUQ-in-prose)

This skill follows the workbench's documented split (CLAUDE.md "Novel pattern
callout", precedent `scripts/cj-repo-init.sh`): the static-lint logic lives in a
testable bash engine (`scripts/cj-portability-audit.sh`); this SKILL.md prose
owns the rich report rendering + any operator interaction. The script never
prompts; the skill never re-implements the lint.

The engine is a **ROOT script** resolved at runtime via the manifest `.source`
field (NOT bundled under the skill dir) — exactly like `cj-repo-init.sh` /
`skills-update-check`. Bundling it would buy no portability because the catalog +
skill source the engine reads exist only in the workbench clone anyway. (Meta:
the audit classifies its OWN root-engine reach-back as OK — a `workbench` skill
referencing a root workbench script inside its self-resolution preamble; the
carve-out covers it.)

## Steps

### Step 1: Resolve the engine path

The engine lives in the user's clone at `<source>/scripts/cj-portability-audit.sh`
(same resolution shape as `skills-update-check` / `cj-repo-init.sh`). Prefer the
repo-local copy when running inside the workbench; otherwise resolve via the
deployed manifest's `.source` field:

```bash
_PA=""
if [ -f "$(git rev-parse --show-toplevel 2>/dev/null)/scripts/cj-portability-audit.sh" ]; then
  _PA="$(git rev-parse --show-toplevel)/scripts/cj-portability-audit.sh"
else
  _SRC=$(jq -r '.source // empty' "$HOME/.claude/.skills-templates.json" 2>/dev/null)
  [ -n "$_SRC" ] && [ -x "$_SRC/scripts/cj-portability-audit.sh" ] && _PA="$_SRC/scripts/cj-portability-audit.sh"
fi
[ -z "$_PA" ] && { echo "Error: cj-portability-audit.sh not found. Run skills-deploy install or run from the workbench."; exit 2; }
echo "ENGINE: $_PA"
```

If the engine is not found, tell the user to run `skills-deploy install` (or to
run from inside the workbench) and stop. If the engine reports that
`skills-catalog.json` is not found, the current repo is not the workbench — relay
that this skill audits the workbench's own source tree and stop.

### Step 2: Run the audit (default — adjudicated)

Run the engine in default mode and print its output verbatim:

```bash
bash "$_PA"
```

Print the per-skill verdict table to the operator exactly as the engine emitted
it. Read the machine-readable tail:

- `FINDINGS=<n>` — number of skills with a `findings:` verdict (after
  `portability_requires` adjudication).
- `SKILLS_AUDITED=<n>` — size of the runtime-derived audit set.
- `RESULT: OK (advisory)` — v1 exits 0 even with findings (advisory posture).

### Step 3: Surface findings (no AUQ unless the operator asks to act)

This skill is **read-only** by default — it reports, it does not mutate. There is
no scaffold/fix step (unlike `/CJ_repo-init`). If `FINDINGS=0`, print a one-line
confirmation ("Portability: all declarations adjudicated"). If `FINDINGS>0`,
relay each `findings:` line and explain that the operator resolves a finding two
ways (the audit never auto-fixes):

- **Relabel** the skill's `portability` in `skills-catalog.json` to the tier the
  dependency actually needs (the honest fix when the skill genuinely needs the
  workbench).
- **Adjudicate** the dep via the optional `portability_requires` accepted-deps
  array on the skill's catalog entry (copy the verbatim finding token, e.g.
  `scripts/test.sh`, straight in) — for a dependency that is accepted/intentional.

If the operator explicitly asks to see the RAW pre-adjudication findings (to
confirm the audit is non-no-op), run:

```bash
bash "$_PA" --no-adjudication
```

This ignores `portability_requires` and shows every declared-vs-actual mismatch.

### Step 4: Done

This skill makes no commits and creates no branch. Any catalog relabel or
`portability_requires` edit the operator decides on is a separate edit + `/ship`
(or manual `git`) they drive themselves. Re-running `/CJ_portability-audit` is a
clean, idempotent read.

## Usage

```
/CJ_portability-audit                  # adjudicated per-skill verdict table (default)
/CJ_portability-audit --no-adjudication # raw, pre-adjudication findings (prove non-no-op)
```

Pass-through engine flags (advanced): `--skill <name>` (audit one skill),
`--catalog <path>` (audit a custom catalog). `PORTABILITY_STRICT=1` env flips the
exit code to non-zero when findings remain (the documented future hard-fail path;
advisory by default).

## Error handling

| Condition | Behavior |
|---|---|
| Not a git repo | Print the git-repo error and stop. |
| Engine not found | Print "Run skills-deploy install or run from the workbench." and stop (exit 2). |
| `skills-catalog.json` not found | Engine errors; this is not the workbench — relay and stop. |
| `FINDINGS=0` | Read-only no-op: print the table + a one-line confirmation; no AUQ. |
| `FINDINGS>0` | Relay each finding + the relabel-or-adjudicate options; never auto-fixes. |
