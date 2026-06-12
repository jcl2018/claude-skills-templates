---
name: CJ_doc_audit
description: "Audit a repo's docs against its doc contract — runnable standalone in ANY repo. Ensures the two-tier doc contract exists (creates spec/ and seed-delivers spec/doc-spec.md via doc-spec.sh --seed when missing, reporting seeded: yes; idempotent seeded: no on re-run), validates the MERGED registry (general + optional spec/doc-spec-custom.md overlay), runs the deterministic conformance checks (declared docs exist; no orphan docs/*.md / spec/*.md; root *.md declared; no work-item IDs in human-docs; front_table docs open with a summary table; generated views in sync where the repo-local generator exists), layers the agent-judged per-requirement alignment verdicts on top (up-to-date / stale / missing-requirement / n/a), and emits a findings report: DOC_AUDIT: <ok|findings> + FINDINGS=<n> + DOCS_AUDITED=<n> + per-finding lines + the verdict block. Findings never crash the audit — a broken contract IS the report. Engine resolution repo-local scripts/doc-spec.sh then ~/.claude/_cj-shared/scripts/. Dual posture: standalone invocations may use the Skill tool; inside a QA subagent (qa.md Step 8.6c) the logic executes INLINE by the agent reading this file (a subagent cannot spawn subagents). Use when: 'audit this repo's docs', 'check doc hygiene', 'does this repo follow its doc contract'."
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
(`spec/doc-spec-custom.md`) the parser merges in. The audit:

1. **Seed-delivers** the contract when missing (creating `spec/` if needed).
2. **Validates** the merged registry.
3. Runs the **deterministic conformance** checks.
4. Layers the **agent-judged alignment** verdicts (the registered-doc audit
   shape) on top.
5. Emits a grep-able **findings report**.

Findings never crash the audit and never halt a caller: a broken contract IS
the report. The audit is read-mostly — its ONLY write is the seed delivery
(step 1), which is idempotent.

**Dual posture.** Standalone (operator keystroke in any repo): invoke this
skill directly — it may be dispatched via the Skill tool. Inside a QA subagent
(`/CJ_qa-work-item` qa.md Step 8.6c, inside a cj_goal run): a subagent cannot
spawn subagents (the nested-subagent wall), so the QA agent executes this
file's steps INLINE by reading it. Both postures produce the identical report
shape.

## Step 1: Resolve the engine

The deterministic half runs on `doc-spec.sh`. Resolve it repo-local first,
then the deployed shared home:

```bash
_DA_ROOT=$(git rev-parse --show-toplevel)
_DA_ENGINE=""
if [ -x "$_DA_ROOT/scripts/doc-spec.sh" ]; then
  _DA_ENGINE="$_DA_ROOT/scripts/doc-spec.sh"
elif [ -x "${CJ_SHARED_SCRIPTS:-$HOME/.claude/_cj-shared/scripts}/doc-spec.sh" ]; then
  _DA_ENGINE="${CJ_SHARED_SCRIPTS:-$HOME/.claude/_cj-shared/scripts}/doc-spec.sh"
fi
if [ -z "$_DA_ENGINE" ]; then
  echo "DOC_AUDIT: findings"
  echo "FINDINGS=1"
  echo "DOCS_AUDITED=0"
  echo "FINDING: engine — doc-spec.sh unreachable (repo-local scripts/ + deployed _cj-shared both absent); run 'skills-deploy install'"
  # stop here — nothing else can run without the engine
fi
```

## Step 2: Ensure the contract exists (seed delivery)

If NEITHER `spec/doc-spec.md` NOR a root `doc-spec.md` exists, create `spec/`
and deliver the seed. Write to a temp file, verify non-empty AND
`--validate`-clean, THEN move into place (the corruption guard — a `--seed`
failure must never redirect a halt string into the new file). Report
`seeded: yes`; when the contract already exists report `seeded: no` (the
idempotence contract — a second run never re-seeds):

```bash
SEEDED=no
if [ ! -f "$_DA_ROOT/spec/doc-spec.md" ] && [ ! -f "$_DA_ROOT/doc-spec.md" ]; then
  _DA_TMP=$(mktemp -d)
  if bash "$_DA_ENGINE" --seed > "$_DA_TMP/doc-spec.md" 2>/dev/null \
     && [ -s "$_DA_TMP/doc-spec.md" ] \
     && DOC_SPEC_PATH="$_DA_TMP/doc-spec.md" bash "$_DA_ENGINE" --validate >/dev/null 2>&1; then
    mkdir -p "$_DA_ROOT/spec"
    mv "$_DA_TMP/doc-spec.md" "$_DA_ROOT/spec/doc-spec.md"
    SEEDED=yes
  fi
  rm -rf "$_DA_TMP"
fi
echo "seeded: $SEEDED"
```

A failed seed delivery (the `if` falls through) is a finding:
`FINDING: seed — doc-spec.sh --seed did not emit a valid doc-spec.md`.

## Step 3: Validate the merged registry

```bash
bash "$_DA_ENGINE" --validate
```

The engine merges `spec/doc-spec.md` + `spec/doc-spec-custom.md`-if-present
(overlay-absent repos: nothing to merge, no finding). A non-zero exit
(present-but-invalid registry, duplicate path across the two files, invalid
overlay) is ONE finding quoting the engine's `[doc-sync-no-config]` reason;
skip Steps 4–5 (their inputs are unparseable) and go to Step 6 with the
verdict block replaced by `n/a — registry invalid`.

## Step 4: Deterministic conformance

All driven from the engine's merged lists. Count each failed assertion as one
finding with a `FINDING: <area> — <detail>` line:

- **declared-exists** — every `--list-declared` path exists on disk.
- **no orphans** — every `docs/*.md` on disk (maxdepth 1) is declared; every
  `spec/*.md` on disk is declared (only when those dirs exist).
- **root declared** — every root `*.md` on disk is a declared registry path.
- **no work-item IDs in human-docs** — no `--list-human-docs` path contains
  `[FSTD][0-9]{6}`.
- **front_table** — every `--list-front-table-docs` path opens with a Markdown
  table (a `|`-row immediately followed by a `|---|`-style delimiter row)
  BEFORE its first `## ` heading.
- **views in sync** — ONLY when the repo-local generator exists (the Check 23
  guard, verbatim: `[ -f "$_DA_ROOT/scripts/generate-doc-views.sh" ]` and the
  views are present): regenerate into a temp dir and diff
  `docs/doc-general.md` + `docs/doc-custom.md`; drift is a finding. Where the
  generator is absent (consumer posture), diff each view's table against fresh
  `--render general|custom` output instead; a mismatch is a finding.

## Step 5: Agent-judged alignment (the registered-doc audit shape)

For each declared doc, read its registry `requirement:` string and judge the
doc against it — one verdict per doc:

- `up-to-date` — satisfies its requirement.
- `stale: <one-line why>` — no longer satisfies it. Counts as one finding.
- `missing-requirement` — the entry has no `requirement:`. SOFT — reported,
  never counted as a finding.
- `n/a` — out of scope for this run's judgment (say why).

This layer sits ABOVE the deterministic floor, never replaces it: a doc can be
structurally present (Step 4 green) and still `stale` here (e.g. a workflow
doc that no longer lists a live entry point).

## Step 6: Emit the findings report

Always emit, in this order (the grep-able contract callers parse):

```
DOC_AUDIT: <ok|findings>
FINDINGS=<n>
DOCS_AUDITED=<n>          # the merged --list-declared count
seeded: <yes|no>
FINDING: <area> — <detail>     # one line per finding, omitted when none
### Registered-doc verdicts
<path>: <verdict>              # one line per declared doc
```

`DOC_AUDIT: ok` requires FINDINGS=0 (every deterministic check green AND no
`stale:` verdict). `missing-requirement` verdicts do not block `ok`.

## Error handling

| Condition | Behavior |
|---|---|
| Not a git repo | "Error: /CJ_doc_audit requires a git repository." — stop |
| Engine unreachable | `DOC_AUDIT: findings` + the engine finding (Step 1) |
| Seed delivery fails | finding; audit continues on whatever exists |
| Registry present-but-invalid | ONE finding quoting `[doc-sync-no-config]`; Steps 4–5 skipped |
| Findings | reported, exit clean — findings are the product, not a crash |
