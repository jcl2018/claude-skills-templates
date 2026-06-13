---
skill-name: "CJ_document-release"
version: 0.1.0
status: experimental
created: "2026-06-02"
last-updated: "2026-06-10T17:39:06Z"
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
- Standalone in ANY repo (not just this workbench) for peace of mind that docs
  are current. When the repo has no `skills-catalog.json`, the skill degrades
  cleanly to its portable half: the registry-doc audit (6.7.1) + the human-doc
  no-work-item-ID lint (6.7.3) still run; the skill-MD audit half (6.7.2) is
  skipped with one clean note and the cj_goal `.cj-goal-feature/` scratch write
  is skipped too (no stray artifact). The mechanical portable gate a consumer
  repo can wire into CI is `doc-spec.sh --validate`.

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
(1) it reads + self-heals the `spec/doc-spec.md` contract — self-bootstraps a
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
every `human-doc` AND a general-contract coverage check (Step 6.7.3b): the
general set is enumerated by writing `doc-spec.sh --seed` to a temp file and
listing it (`DOC_SPEC_PATH=<temp> doc-spec.sh --list-declared` — the isolated
seed carries only general rows); a repo registry that omits a general-contract
doc gets `stale: registry missing general-contract doc(s): <paths>` on the
contract file's own verdict
line (basename path-equivalence for spec/-prefixed seed paths: a root-style
consumer's `doc-spec.md` satisfies the seed's `spec/doc-spec.md`) — advisory,
never a halt. The result is that
orchestrator sessions can call CJ_document-release after QA (and after the
post-QA audit checkpoint), and `/ship` (next
pipeline step) sees a clean tree where any doc updates are pre-committed.

### The doc-spec.md contract

The wrapper reads the merged doc-spec registry on every run: the GENERAL
`spec/doc-spec.md` (byte-identical to the seed, never edited in place) plus the
optional `spec/doc-spec-custom.md` overlay (the same 3-column Markdown-table
grammar) — `doc-spec.sh` merges them internally, and a path duplicated across
the two files is a validate error. The registry is a `| Doc | Purpose |
Requirement |` table: each row declares a doc's path, what it is for, and what
makes it current. `audit_class` is no longer a column — it is DERIVED from the
path (a path under `docs/` or the root `README.md` is a `human-doc`, every
other declared path is `operational`); only human-docs get the no-work-item-ref
lint. The two-tier contract: the general docs are the portable contract and are
REQUIRED — the seed declares all of them on self-bootstrap (delivered to
`spec/doc-spec.md`) and the stub-scaffold step creates any missing one
(`spec/test-spec.md` is special-cased via `test-spec.sh --seed` so the stub is a
VALID registry, never a title-plus-section stub that would hard-halt the test
audit; `TODOS.md` stub-scaffold and the existing lazy-creation by TODOS-reading
skills are convergent — whichever runs first creates the file, the other
no-ops); overlay docs are per-repo additions declared in `doc-spec-custom.md`.
The auto-commit whitelist + the `--docs` resolution are both DERIVED from the
merged registry — there is no separate hand-maintained whitelist file. The
helper at `scripts/doc-spec.sh` parses + validates + expands; the wrapper
resolves it **2-tier**: repo-local first, then the deployed `_cj-shared/scripts/`
home that travels with the install (no runtime manifest `.source` reach-back —
`CJ_document-release` is `local-only`, not `workbench`). A `_cj-shared`-resolved
helper still parses THAT repo's own `doc-spec.md` because it reads the registry
from the cwd's git toplevel (`git rev-parse --show-toplevel`), not its own
location. Strict-required posture: the wrapper HALTs with `[doc-sync-no-config]`
BEFORE any audit when `doc-spec.md` has no registry table or a malformed table
row (a literal `|` inside a cell). A simply-absent `doc-spec.md` is
self-bootstrapped from the portable Common seed instead of halting.

### Runs cold in a non-workbench repo

The skill is `local-only`, not workbench-bound: it runs in any repo. The one
workbench-specific read — `skills-catalog.json` in Step 6.7.2 (the skill-MD audit
half) — is GUARDED. When the catalog is absent the skill prints one clean note
("no skills-catalog.json — non-workbench mode") and skips both the skill-MD
enumeration AND the `.cj-goal-feature/` scratch write (that scratch only feeds the
cj_goal PR-body surfacing, which doesn't exist standalone, and isn't gitignored in
a consumer repo). The catalog-independent halves — 6.7.1 (registry-doc audit) and
6.7.3 (the human-doc no-work-item-ID lint) — still run. No `set -e` abort, no `jq`
stderr noise, no stray artifact. The honest CI boundary: `doc-spec.sh --validate`
(registry table) is the portable gate a consumer repo wires in; the
declared⇔on-disk loop (`validate.sh` Checks 15/15a) is workbench-local and does
NOT travel.

## Common pitfalls

- `[doc-sync-no-config]` halt means `doc-spec.md`'s registry table is broken —
  no registry table, a malformed table row (a literal `|` inside a cell or the
  wrong column count), or a path duplicated across the two files. Repair the
  registry table (spec/doc-spec.md, resolved spec/-then-root). (A simply-absent `doc-spec.md` is NOT a halt —
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
- `[doc-sync-red]` at the Step 4→5 boundary with no upstream output usually
  means gstack `/document-release` is not installed (a Step-4 resolution
  failure, distinct from a Step-5 non-green audit). The halt message names
  "gstack `/document-release` not installed" as a possible cause for exactly
  this reason — confirm it is installed before chasing a doc error.

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
