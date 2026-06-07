# permission-policy.md — what the cj_goal orchestrators are allowed to do

One declared **allow / ask / deny** contract for the `cj_goal` orchestrator
family (`/CJ_goal_feature`, `/CJ_goal_defect`, `/CJ_goal_todo_fix`). It answers
one question from a single artifact — *"what is this orchestrator allowed to
do?"* — instead of three half-connected surfaces (the `allowed-tools`
frontmatter, the sensitive-surface AskUserQuestion in leaf-skill code, and the
dormant `cj-handoff-gate.sh` denylist).

It is both human-readable (this prose) and machine-readable (the fenced `yaml`
block at the end, parsed by `scripts/permission-policy.sh`). Add a permission by
adding a registry row — never by editing one of the enforcement points directly.

## The three modes

- **allow** — friction-free; the orchestrator acts without a gate.
- **ask** — a human gate (an AskUserQuestion) first. The sensitive *file*
  surfaces (catalog, manifests, validators, skill dirs, git hooks, tests) live
  here: edits there cascade to every other skill, so a human reviews first.
- **deny** — blocked. The riskiest *operations* (a direct push to `main`, an
  autonomous `gh pr merge`, `rm`, network egress in a build) are never the
  orchestrator's to do autonomously — they are the human's, post-PR. **An
  unenumerated verb resolves to `deny`** (design permission before capability —
  fail closed).

## The two live enforcement points + one dormant deriver

- **`allowed-tools` frontmatter (allow, live)** — each orchestrator `SKILL.md`
  declares the tools it may use; that set is the **allow** surface, governed by
  this policy.
- **sensitive-surface AskUserQuestion (ask, live)** — `/CJ_implement-from-spec`
  (and the orchestrators' pre-flight) gate edits to the **ask** surfaces below.
- **`cj-handoff-gate.sh` denylist (derive, dormant)** — the auto-merge gate's
  file denylist is **derived** from this policy's `ask` surface globs (via
  `permission-policy.sh --surface-globs ask`), not hand-maintained. The gate is
  dormant (its consumers `/CJ_goal_auto` + `/CJ_goal_run` are deleted), so this
  is forward-looking: correct if it is ever reactivated.

`scripts/validate.sh` Check 21 flags drift between this policy and the
enforcement points (advisory — exit 0, like the portability Check 18).

## Deny verbs vs ask surfaces (the two layers)

The `ask` rows are **file surfaces** (globs); the `deny` rows are **operations**
(verbs). The handoff-gate guards the *file* surfaces (so it derives from the
`ask` globs); the deny *verbs* are operation-level and are already contained by
the orchestrators' PR-stop + human-merge — the deny rows *declare* that
contract, they are not enforced by the file gate.

## Machine registry

The block below is the source of truth. Keep it the only fenced `yaml` block in
this file. Each row: `verb` (the operation/surface name), `kind`
(`surface` = a file edit, `op` = an operation), `mode`
(`allow` | `ask` | `deny`), `scope` (a file-path glob for surfaces, a
description for ops).

```yaml
# cj_goal permission policy (parsed by scripts/permission-policy.sh)
schema_version: 1
policy:
  # --- allow: friction-free ---
  - verb: edit-in-scope
    kind: surface
    mode: allow
    scope: "work-items/"
  # --- ask: sensitive file surfaces (a human reviews; the handoff-gate denylist derives from these) ---
  - verb: edit-catalog
    kind: surface
    mode: ask
    scope: "skills-catalog.json"
  - verb: edit-manifest-personal
    kind: surface
    mode: ask
    scope: "personal-artifact-manifests.json"
  - verb: edit-manifest-company
    kind: surface
    mode: ask
    scope: "company-artifact-manifests.json"
  - verb: edit-validator
    kind: surface
    mode: ask
    scope: "scripts/validate.sh"
  - verb: edit-test-suite
    kind: surface
    mode: ask
    scope: "scripts/test.sh"
  - verb: edit-test-deploy
    kind: surface
    mode: ask
    scope: "scripts/test-deploy.sh"
  - verb: edit-skill
    kind: surface
    mode: ask
    scope: "skills/"
  - verb: edit-git-hook
    kind: surface
    mode: ask
    scope: ".git/hooks/"
  - verb: edit-tests
    kind: surface
    mode: ask
    scope: "tests/"
  - verb: edit-fixtures
    kind: surface
    mode: ask
    scope: "fixtures/"
  - verb: edit-templates
    kind: surface
    mode: ask
    scope: "templates/"
  # --- deny: riskiest operations (the human's, post-PR; never autonomous) ---
  - verb: git-push-to-main
    kind: op
    mode: deny
    scope: "direct push to main/master (orchestrators push feature branches + PR-stop)"
  - verb: gh-pr-merge
    kind: op
    mode: deny
    scope: "autonomous gh pr merge (the merge is the human autonomy ceiling)"
  - verb: rm
    kind: op
    mode: deny
    scope: "rm / rm -rf (use git rm for tracked files)"
  - verb: network-egress
    kind: op
    mode: deny
    scope: "curl / wget / network egress during a build"
```
