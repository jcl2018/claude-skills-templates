---
skill-name: "CJ_document-release"
version: 0.1.0
status: experimental
created: "2026-06-02"
last-updated: "2026-06-06T18:00:00Z"
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
adds workbench-specific concerns on top of the upstream doc-sync pass:
(1) it reads + self-heals the root `doc-spec.md` contract — self-bootstraps a
missing `doc-spec.md` from the portable Common seed, and stub-scaffolds any
declared-but-missing doc (idempotent); (2) `--docs <comma-list>` per-doc subset
(best-effort filter via project-context block; documentation-only, not
enforced); (3) halt-on-red contract that emits `[doc-sync-red]` on upstream
failure so the calling orchestrator HALTs instead of silently continuing;
(4) doc-only auto-commit gated by a whitelist DERIVED from the `doc-spec.md`
registry (every declared path + `doc-spec.md` + `docs/**/*.md`), with a
`[doc-sync-non-doc-write]` HALT if upstream writes anything outside it; (5) a
registered-doc requirements audit (Step 6.7) that emits advisory `up-to-date` /
`stale` / `missing-requirement` verdicts per registered doc (the registry docs +
the routable skill MDs) into the PR body, including a no-work-item-ref check for
every `human-doc`. The result is that orchestrator sessions can call
CJ_document-release after QA, and `/ship` (next pipeline step) sees a clean tree
where any doc updates are pre-committed.

### The doc-spec.md contract

The wrapper reads the root `doc-spec.md` on every run. It is the single source of
truth for what docs the repo carries — a portable Common section, a repo Custom
section, and ONE fenced `yaml` registry. The registry declares each doc's `path`
/ `section` / `audit_class` / `purpose` / `requirement`; `audit_class` is a closed
enum `{human-doc, operational}` (only `human-doc` gets the no-work-item-ref
lint). The auto-commit whitelist + the `--docs` resolution are both DERIVED from
this registry — there is no separate hand-maintained whitelist file. The helper
at `scripts/doc-spec.sh` parses + validates + expands; the wrapper resolves it
**2-tier**: repo-local first, then the deployed `_cj-shared/scripts/` home that
travels with the install (no runtime manifest `.source` reach-back —
`CJ_document-release` is `local-only`, not `workbench`). A `_cj-shared`-resolved
helper still parses THAT repo's own `doc-spec.md` because it reads the registry
from the cwd's git toplevel (`git rev-parse --show-toplevel`), not its own
location. Strict-required posture: the wrapper HALTs with `[doc-sync-no-config]`
BEFORE any audit when `doc-spec.md` is missing the `yaml` registry, declares an
unsupported `schema_version`, or has an entry with a missing field / an
out-of-enum `audit_class`. A simply-absent `doc-spec.md` is self-bootstrapped
from the portable Common seed instead of halting.

## Common pitfalls

- `[doc-sync-no-config]` halt means `doc-spec.md`'s `yaml` registry is broken —
  no `yaml` block, an unsupported `schema_version`, an entry missing a required
  field, or an `audit_class` outside `{human-doc, operational}`. Repair the
  registry block at the repo root. (A simply-absent `doc-spec.md` is NOT a halt —
  the wrapper self-bootstraps it from the portable Common seed and continues.)
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
