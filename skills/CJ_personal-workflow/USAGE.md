---
skill-name: "CJ_personal-workflow"
version: 4.0.0
status: active
created: "2026-06-01"
last-updated: "2026-06-01"
---

# Skill Usage: CJ_personal-workflow

## When to use

- You want to validate a work-item directory or TRACKER.md file against the personal
  templates and `personal-artifact-manifests.json`
- A scaffolder/implementer/QA step needs to assert structural compliance before
  proceeding ("Phase 1 gates passed?")
- You just hand-edited a TRACKER.md and want to confirm the YAML frontmatter and the
  Lifecycle/Acceptance/Files sections still pass the manifest
- `/CJ_personal-workflow check` is the canonical invocation

## When NOT to use

- You want to scaffold a brand new work-item — that's `/CJ_scaffold-work-item`, which
  calls this skill at boundaries
- You want validation to auto-fix the drift — this skill flags only ("flag, don't fix"
  principle); regeneration is operator work
- You want repo-wide health (catalog vs filesystem) — that's `scripts/validate.sh`
  (Bash, not a skill)

## Mental model

A passive validator. Takes a tracker file or work-item dir as input, joins it against
`personal-artifact-manifests.json` (the source of truth for which artifacts each
type requires), and prints findings. Findings are advisory — nothing is written back.
Templates + WORKFLOW.md are the single source of truth for structural rules; this
skill is the read-only enforcer.

## Common pitfalls

- Expecting `check` to write tracker rows for you — it won't; it only verifies.
- Running it against a hand-rolled work-item dir that bypasses
  `/CJ_scaffold-work-item` — manifest mismatches will look like skill bugs, but
  the fault is upstream scaffolding.
- Updating templates without updating the manifest (or vice versa) — the validator
  passes locally but downstream skills break; keep both in sync.

## Related skills

- `/CJ_scaffold-work-item` — upstream caller; runs `check` at boundaries
- `/CJ_implement-from-spec` — upstream caller; runs `check` at boundaries
- `/CJ_qa-work-item` — upstream caller; refuses on incomplete Phase 2
- `scripts/validate.sh` — adjacent script-level validator (catalog vs filesystem,
  not work-item shape)
