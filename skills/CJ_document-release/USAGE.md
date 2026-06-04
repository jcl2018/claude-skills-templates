---
skill-name: "CJ_document-release"
version: 0.1.0
status: experimental
created: "2026-06-02"
last-updated: "2026-06-04T17:44:06Z"
---

# Skill Usage: CJ_document-release

## When to use

- The 3 cj_goal orchestrators (`/CJ_goal_feature`, `/CJ_goal_defect`,
  `/CJ_goal_todo_fix`) auto-invoke this skill inline at Step 5.5 (between QA
  pass and `/ship`) — operators do not call it directly in that path; it just
  fires as part of the orchestrator pipeline.
- Manual invocation when on a feature branch with stale docs and you want
  doc updates folded into the next code commit before `/ship`:
  `/CJ_document-release` (full audit) or `/CJ_document-release --docs README`
  (README-only filter).
- After a code change that touched a file referenced in README/ARCHITECTURE
  and you want the doc sync to happen in the SAME PR as the code change
  (atomic doc + code).

## When NOT to use

- On `main` / `master` / a base branch — upstream `/document-release`
  hard-aborts there. The wrapper refuses fast with `[doc-sync-red]` before
  spending a Skill call. Run from a feature branch.
- Working tree has uncommitted NON-DOC changes — the wrapper refuses to run
  on top of them (it can't tell what's user-intent vs noise). Commit or
  stash the non-doc changes first.
- You want the full `/document-release` behavior with no workbench wrapping
  (no `--docs` filter, no halt-on-red contract, no auto-commit gate) — call
  upstream `/document-release` directly. The wrapper is for the orchestrator
  path; the bare upstream is for non-orchestrator paths.
- Non-orchestrator paths — `/ship` (Step 18) already runs `/document-release`
  on every invocation, so a manual `/ship` still folds doc updates into the
  PR. The only uncovered path is a main-move that bypasses BOTH the cj_goal
  orchestrators AND `/ship` (a raw `git push` or a hand-rolled
  `gh pr create` + `gh pr merge`); recover that by running `/document-release`
  by hand from a feature branch.

## Mental model

A thin workbench wrapper around upstream gstack `/document-release` that
adds four workbench-specific concerns: (1) `--docs <comma-list>` per-doc
subset (best-effort filter via project-context block; documentation-only,
not enforced); (2) halt-on-red contract that emits `[doc-sync-red]` on
upstream failure so the calling orchestrator HALTs instead of silently
continuing; (3) doc-only auto-commit gated by a per-repo whitelist loaded
from `cj-document-release.json` (F000037), with a `[doc-sync-non-doc-write]`
HALT if upstream writes anything outside that whitelist; (4) a registered-doc
requirements audit (T000038, Step 6.7) that emits advisory `up-to-date` /
`stale` / `missing-requirement` verdicts per registered doc (the tracked-doc/
manifest entries + active skill MDs) into the PR body — see CLAUDE.md
`## Registered-doc requirements audit`. The result is that orchestrator
sessions can call CJ_document-release after QA, and `/ship` (next pipeline
step) sees a clean tree where any doc updates are pre-committed.

### Per-repo config

The wrapper reads `cj-document-release.json` at the repo root (sibling of
`skills-catalog.json`) on every run. The JSON declares (a) the
`whitelist_patterns` that gate the auto-commit step (globs against the
working tree, e.g. `doc/**/*.md`), and (b) the `categories` map that
resolves `--docs <token>` flags into concrete file lists (e.g.
`"readme": ["README.md"]`). Schema is versioned (`schema_version: 1`); the
helper at `scripts/cj-document-release-config.sh` parses + validates +
expands. Strict-required posture (no fallback): the wrapper HALTs with
`[doc-sync-no-config]` BEFORE any audit when the JSON is missing, invalid,
or schema_version-unsupported. Every adopting repo declares its own JSON;
the workbench's bundled JSON seeds the F000036-compat set.

## Common pitfalls

- `[doc-sync-no-config]` halt means `cj-document-release.json` is missing,
  not valid JSON, schema_version-unsupported, or missing required fields
  (`whitelist_patterns` / `categories`). Copy the workbench's seed JSON
  (root of `claude-skills-templates`) as a starting point and adjust for
  your repo's doc surface. F000037 strict-required posture: no fallback to
  hardcoded defaults — every adopting repo declares intent upfront.
- Invoking on main: refuses fast with `[doc-sync-red]`; switch to a feature
  branch and re-run.
- Working tree dirty with non-doc files: refuses fast with `[doc-sync-red]`;
  commit/stash first.
- `--docs` filter is documentation-only, not programmatic — if upstream
  audits everything anyway, the wrapper still auto-commits whatever
  upstream produced (so it's not a "hard filter"; treat it as operator
  intent, not a gate).
- `[doc-sync-non-doc-write]` halt means upstream wrote a file outside the
  doc-only whitelist; inspect the listed files before re-running. Do NOT
  blindly extend the whitelist — the conservative shape is on purpose.
- Cron / `--quiet` mode: halt-on-red contracts are NOT suppressed by
  `--quiet`; only summary banners + AUQs are. The cron operator reads the
  halt journal at their convenience.

## Related skills

- `/document-release` (upstream gstack) — the audited skill this wrapper
  invokes via the Skill tool. No modification to upstream; the workbench
  wrapper adds filter/halt/auto-commit logic externally.
- `/CJ_goal_feature` — top-level orchestrator that auto-invokes this skill
  at Step 5.5 (between QA pass and `/ship`); doc updates fold into the
  same code PR.
- `/CJ_goal_defect` — same Step 5.5 wiring for the defect verb.
- `/CJ_goal_todo_fix` — same Step 5.5 wiring for the TODO drain verb.
- `/ship` (upstream gstack) — the next pipeline step after Step 5.5; opens
  a PR containing both code commits (from earlier phases) AND the doc
  commit (from this skill).
