---
skill-name: "CJ_goal_defect"
version: 0.1.0
status: experimental
created: "2026-06-01"
last-updated: "2026-07-03T20:06:32Z"
---

# Skill Usage: CJ_goal_defect

## When to use

- "fix this bug", "fix this bug end-to-end from a description", "bug report to
  deployed fix", "root-cause and ship a fix", "RCA and deploy"
- You have a plain bug description (no pre-existing defect dir required)
- Resume: re-invoking the same verb on the same branch picks up where you left off
- `--dry-run` previews the chain plan + write paths without mutation
- `--no-sync` skips the pre-build skills-sync (F000045) for a faster start; the
  worktree's local-main fast-forward still runs

## When NOT to use

- The work is a feature, not a bug — use `/CJ_goal_feature`
- You only want to root-cause without shipping — call `/investigate` directly
  (this orchestrator ships the fix after RCA passes)
- The Iron-Law `/investigate` gate returns no root cause — the orchestrator
  HALTs (nothing promoted, nothing shipped); fix the investigation first
- You're a non-macOS host — workbench-only

## Mental model

A fresh-base start (F000045): the preamble first runs a pre-build skills-sync
(`cj-goal-common.sh --phase sync` → `post-land-sync.sh`'s guarded pull +
`skills-deploy install` from `.source`, fail-soft) so installed skills match
trunk, then the worktree phase fast-forwards local `main` to `origin/main`
before `git worktree add` so the build branches off current trunk (Fork 1, in
`cj-worktree-init.sh`). Both halves are fail-soft — offline / divergence / guard
refusal proceed with a one-line advisory; the build is never blocked.

Then a 4-step chain: throwaway `.inbox/<slug>/DRAFT.md` scratchpad →
`/investigate` as Agent subagent (Iron-Law: no RCA ⇒ HALT) → on populated RCA,
write RCA+test-plan and promote draft to a canonical
`work-items/defects/uncategorized/D000NNN_<slug>/` dir (D-ID minted ONLY after
the Iron-Law gate passes) → `/CJ_qa-work-item` leaf subagent (with the inline
audits SKIPPED — the orchestrator passes a literal `DEFER_AUDIT: true` directive
so QA skips its Step 8.6c/8.6d doc/test audits and returns `AUDITS=deferred`, while
still running the 8.6a/8.6b spec-overlay writes) → an idempotent pre-doc-sync
commit → `/CJ_document-release` (Step 5.5 doc-sync) → `/ship` (Gate #2 always
human) → `/land-and-deploy --suppress-readiness-gate`. The agent-judged doc/test
audit (`/CJ_doc_audit` + `/CJ_test_audit`) no longer runs on the build path or
gates the ship; it runs on-demand off the build path (locally via `/CJ_doc_audit`
+ `/CJ_test_audit`, or `bash scripts/audit-nightly.sh` which files findings to a
GitHub issue — the former nightly CI workflow was removed by F000080). The
deterministic per-PR gate (`validate.sh` / pre-commit) is unchanged. A ~80% reshape of the
retired `/CJ_goal_investigate` v1.1 pipeline; depth ≤ 2 (no
subagent-spawns-subagent).

## Common pitfalls

- Trying to resume an existing D-id work-item — this orchestrator is
  start-from-scratch; the retired `/CJ_goal_investigate` was the resume-by-D-id
  path and is now a rejection-on-D-id shim
- Expecting D-ID to be minted before RCA — by design, the D-ID is minted ONLY
  after Iron-Law passes; failed investigations leave nothing behind
- Running it inside a subagent — depth-≤2 ceiling; the orchestrator must be
  top-level
- Skipping the bug-description and just running the skill — needs a description
  arg to seed the `.inbox/<slug>/DRAFT.md`
- Expecting `--no-sync` to also skip the base fast-forward — it does not; `--no-sync`
  only suppresses the heavy `skills-deploy install`, Fork-1's local-main ff still runs

## Related skills

- `/investigate` (upstream gstack) — Iron-Law root-cause analysis subagent
- `/CJ_qa-work-item` — leaf subagent that runs the test-plan rows; when
  orchestrator-driven it SKIPS its Step 8.6c/8.6d inline audits (`DEFER_AUDIT:
  true`) — the agent-judged `/CJ_doc_audit` + `/CJ_test_audit` run on-demand off
  the build path (standalone `/CJ_qa-work-item` still runs them inline)
- `/ship` (upstream gstack) — opens PR with Gate #2
- `/land-and-deploy` (upstream gstack) — merges and verifies deploy
- `/CJ_goal_feature` — sibling top-level verb for feature-from-topic
- `/CJ_goal_todo_fix` — sibling top-level verb for TODOS.md drains
