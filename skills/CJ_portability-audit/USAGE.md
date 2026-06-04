---
skill-name: "CJ_portability-audit"
version: 0.1.0
status: experimental
created: "2026-06-04"
last-updated: "2026-06-04T14:30:00Z"
---

# Skill Usage: CJ_portability-audit

## When to use

- "audit skill portability", "check declared-vs-actual dependencies", "is this
  skill really standalone", "which skills are workbench-coupled"
- You added or edited a skill and want to confirm its `portability` declaration
  in `skills-catalog.json` is honest (it doesn't quietly reach for a root
  `scripts/*.sh` helper, root config, `CLAUDE.md`, or the `.source` reach-back a
  fresh target repo won't have)
- A skill declared `standalone` is about to ship to (or run in) a non-workbench
  repo and you want the static proof it degrades gracefully
- You want the per-skill verdict table that turns the self-declared `portability`
  field from an honor-system label into a verified invariant

## When NOT to use

- You want to verify a TARGET repo HAS the per-repo prerequisites the CJ_ family
  needs — that's the **consumer-side** `/CJ_repo-init` (this skill is the
  **producer-side** counterpart: it audits the workbench's OWN skills).
- You want a `~/.claude/` install-health dashboard — that's `/CJ_system-health` /
  `skills-deploy doctor`.
- You want to FIX a mismatch automatically — this skill never auto-fixes. It
  reports; you either relabel the skill's `portability` or adjudicate the dep via
  `portability_requires`, then `/ship` that edit yourself.
- You want the DYNAMIC proof (actually running a skill in a stripped scratch repo)
  — that is Layer 2 (`scripts/eval.sh --portability`), which in v1 is only a
  single `CJ_suggest` proof-of-life case; broad coverage is deferred to Story 2.

## Mental model

One static engine (`scripts/cj-portability-audit.sh`), two surfaces. For each
catalog skill in the runtime-derived Check-14/15b selector set (`status !=
deprecated` + non-empty `files` — never hardcoded), the engine collects the
skill's files, finds each **executed** repo-local dependency (distinguished from
a merely **documented** prose mention), and classifies it against the skill's
declared tier using a strict ladder: `standalone` ⊂ `local-only` ⊂ `workbench`.
A dep exceeding the declared tier is a finding
(`<skill> declared <tier> but depends on <dep> (needs <higher-tier>)`); three
carve-outs (bundled-own-script, scoped self-resolution-preamble,
`portability_requires` adjudication) keep the table signal-not-noise. The verdict
is one of `portable` / `portable-with-notes` / `findings:<list>`.

Surface 1 = this skill (rich report, engine resolved repo-local-first then via
`.source`). Surface 2 = a `validate.sh` advisory check (prints findings, exits 0
in v1; `PORTABILITY_STRICT=1` flips it to hard-fail once declarations are
reconciled). The full correct-behavior contract lives in `doc/WORKFLOWS.md`
(`### /CJ_portability-audit`).

## Common pitfalls

- **Expecting it to flag every mention of a workbench script.** It deliberately
  does NOT — the EXECUTED-vs-documented rule is the whole point. A skill that
  only *mentions* `scripts/foo.sh` in prose gets an informational note, not a
  finding; only an executed reach (or, for a `standalone` skill, a root-helper
  path hardcoded in its contract) is a finding. This is what keeps the table from
  being an all-red wall of noise.
- **Expecting it to auto-fix.** It reports only. Resolve a finding by relabeling
  the skill's `portability` (the honest fix when the skill genuinely needs the
  workbench) OR by adding the verbatim finding token to the skill's
  `portability_requires` array — then re-run; the adjudicated dep is OK and the
  re-run won't re-flag it.
- **Reading exit 0 as "no findings."** v1 is advisory: the engine exits 0 even
  when findings remain. Read the `FINDINGS=<n>` tail (and the verdict table), not
  the exit code. `PORTABILITY_STRICT=1` is the opt-in that makes findings
  non-zero-exit.
- **Running it in a non-workbench repo.** The engine reads the repo's
  `skills-catalog.json` + `skills/` source tree, which exist only in the
  workbench clone — so the skill is `workbench`-scoped by construction. Run it
  from the workbench.
- **Confusing a stale `portability_requires` entry with a finding.** A listed dep
  the skill no longer references is surfaced as an informational note
  (`portability_requires entry 'X' no longer referenced`), never a finding — the
  mirror of the rot this skill detects, surfaced but never blocking.

## Related skills

- `/CJ_repo-init` — the **consumer-side** counterpart. It verifies a target repo
  HAS the per-repo prerequisites (`cj-document-release.json`, `CJ-DOC-RELEASE.md`,
  `TODOS.md`, `work-items/`) and scaffolds the missing ones. This skill is the
  **producer-side** mirror: do the workbench's own skills reach for
  un-scaffoldable repo-local things. Different lifecycles, related domain.
- `/CJ_system-health` — sibling read-only utility; audits `~/.claude/` install
  health (this skill audits the catalog's `portability` honesty, not the install).
- `/CJ_document-release` — declared `workbench`; a within-tier example in the
  audit's table (it operates ON the workbench, so its root-script + `.source`
  reach-backs are OK).
