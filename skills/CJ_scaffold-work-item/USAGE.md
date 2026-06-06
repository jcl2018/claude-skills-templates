---
skill-name: "CJ_scaffold-work-item"
version: 1.0.1
status: experimental
created: "2026-06-01"
last-updated: "2026-06-06T03:46:08Z"
---

# Skill Usage: CJ_scaffold-work-item

## When to use

- An /office-hours design doc exists and you need to turn it into a work-item directory
- An orchestrator (`/CJ_goal_feature`) is delegating the
  scaffold phase as a leaf subagent
- Re-running on the same design is safe — the skill is idempotent (NO-OP if the
  work-item dir already matches the manifest)

## When NOT to use

- You don't have a design doc yet — run `/office-hours` first to produce one
- You want to write code, not directory structure — that's `/CJ_implement-from-spec`
- You're a top-level operator routing by user intent — the routing rule routes you
  to `/CJ_goal_feature` instead, which calls this skill transitively
- The design doc was abandoned or not APPROVED — orchestrator halts upstream; do not
  scaffold against a draft

## Mental model

A pure transformer: design doc + templates + manifest + WORKFLOW.md → a compliant
`work-items/<type>/<id>_<slug>/` tree with all required artifacts populated. Reads
`personal-artifact-manifests.json` to learn which artifacts each work-item type
requires; writes one file per required artifact; runs `/CJ_personal-workflow check`
at boundaries to confirm structural compliance.

The fresh ID (Step 5.1) is minted from FOUR sources: the local work-items tree,
open PRs, `origin/main`, and — when `scripts/cj-id-claim.sh` is present (F000048)
— an atomic `mkdir` claim dir in the SHARED `.git` common-dir. The first three
are point-in-time and cannot see a concurrent sibling worktree that has not yet
pushed; the claim dir is the continuously-atomic 4th source that gives two
parallel same-machine scaffolds distinct IDs, closing the pre-push collision the
post-merge renumber used to recover by hand. If the helper is absent, Step 5.1
falls back to the 3-source `printf` and still mints an ID (the skill never breaks).

## Common pitfalls

- Calling it before `/office-hours` finishes — the doc must exist on disk first
- Hand-editing the manifest without updating templates — scaffolds produce
  half-shaped trees that pass scaffold-time but fail later validation
- Routing here directly when the operator's input is a topic, not a design — use
  `/CJ_goal_feature` so /office-hours runs first

## Related skills

- `/office-hours` (upstream gstack) — produces the design doc this skill consumes
- `/CJ_personal-workflow` — runs at scaffold boundaries to enforce structural shape
- `/CJ_implement-from-spec` — next phase: takes the scaffolded tree and writes code
- `/CJ_goal_feature` — top-level front door; calls this skill as a leaf subagent
