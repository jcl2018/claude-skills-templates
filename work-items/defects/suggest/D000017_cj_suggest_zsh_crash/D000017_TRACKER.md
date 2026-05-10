---
name: "/CJ_suggest crashes under zsh — extract bash block to scripts/suggest.sh"
type: defect
id: "D000017"
status: active
created: "2026-05-10"
updated: "2026-05-10"
repo: "/Users/chjiang/Documents/projects/claude-skills-templates"
branch: "claude/vigilant-morse-671a6a"
blocked_by: ""
---

## Lifecycle

### Phase 1: Track

1. Document reproduction steps in the Log section
2. Create working branch: `git checkout -b fix/cj_suggest_zsh_crash`
3. Scaffold required docs:
   - `RCA.md` (root cause analysis) — from `templates/doc-RCA.md`
   - `test-plan.md` (regression test plan) — from `templates/doc-test-plan.md`
4. Run `/investigate` to diagnose root cause
   → produces investigation findings in Log + Insights
5. Log initial symptoms and hypotheses

**Gates:**
- [x] Reproduction steps documented
- [x] Working branch created (`branch` field populated)
- [x] Required docs scaffolded (RCA + test-plan)
- [x] Root cause identified (or best hypothesis logged)

### Phase 2: Implement

1. Work from `/office-hours` design doc (if applicable) + root cause analysis
   → design doc at `~/.gstack/projects/{slug}/`
2. Implement fix based on root cause analysis
3. Write regression test covering the defect scenario
4. Commit fix and test together
5. Update RCA doc with final root cause

**Gates:**
- [ ] Fix committed
- [x] RCA doc updated
- [x] Todos section reflects remaining work (no stale items)

### Phase 3: Ship

1. Run `/CJ_personal-workflow check` — verify no regressions
2. Verify test-plan: regression test scenarios passing
3. Run `/ship` — creates fix PR (includes pre-landing code review)
4. Run `/land-and-deploy` — merges and verifies fix in production

❌ If regression test fails: investigate further
❌ If CI fails: fix, push, re-run `/ship`

**Gates:**
- [ ] `/CJ_personal-workflow check` — validation passed
- [ ] Test-plan verified (regression scenarios passing)
- [ ] `/ship` — PR created
- [ ] `/land-and-deploy` — merged and deployed

## Reproduction Steps

<!-- Steps to reproduce the defect. Include environment details. -->

1. On a machine where the Claude Code Bash tool dispatches commands through zsh
   (`Shell: zsh` in env).
2. Invoke `/CJ_suggest` so the harness pastes the bash heredoc body from
   `skills/CJ_suggest/SKILL.md` into the Bash tool.
3. The block reaches line 33 where it executes
   `status=$(echo "$row" | awk -F'\t' '{print $2}')`.
4. **Observe:** zsh aborts the eval with `(eval):33: read-only variable: status`,
   the skill exits 1, and no top-5 ranked table is printed.

## Todos

<!-- Actionable items for this defect fix. -->

- [x] Create `skills/CJ_suggest/scripts/suggest.sh` with the bash body verbatim,
      `#!/usr/bin/env bash` shebang, and `set -euo pipefail`.
- [x] Reduce `skills/CJ_suggest/SKILL.md` routing block to the one-liner
      `bash "$(git rev-parse --show-toplevel)/skills/CJ_suggest/scripts/suggest.sh"`
      and trim the now-obsolete "Single-file by design" caveat in Notes.
- [x] Update `skills-catalog.json` so the `CJ_suggest` entry's `files` array
      lists `skills/CJ_suggest/scripts/suggest.sh`.
- [x] Verify `chmod +x` is set on the new script (or rely on `bash <path>` invocation).
      (Decision: invocation uses `bash <path>` form, so the executable bit is irrelevant.)
- [x] Smoke-test: run `bash skills/CJ_suggest/scripts/suggest.sh` from repo root
      with the canonical fixture (current TODOS.md + work-items/) and confirm a
      5-row markdown table.
- [x] Run `scripts/validate.sh` — must exit 0 (catches catalog/filesystem drift).
- [x] Run `scripts/test.sh` — must exit 0.
- [ ] (Deferred to /CJ_qa-work-item) Verify `skills-deploy install` (in a scratch HOME)
      deploys `~/.claude/skills/CJ_suggest/scripts/suggest.sh` — covered by test-plan
      case 6, runs at QA phase.

## Log

<!-- Chronological entries with dates and commit SHAs. -->

- 2026-05-10: Created. `/CJ_suggest`'s embedded bash block crashes under zsh
  because `status=` collides with zsh's read-only `$status` builtin
  (alias of `$?`). Workaround in-session: write body to tempfile and
  `bash /tmp/suggest.sh` explicitly — verified working. Permanent fix:
  Approach B from design doc — extract to `skills/CJ_suggest/scripts/suggest.sh`
  with `#!/usr/bin/env bash` shebang, pinning execution regardless of harness shell.

## PRs

<!-- PR links with status (open/merged/closed). -->

## Files

<!-- Affected file paths. -->

- `skills/CJ_suggest/SKILL.md` — replace bash heredoc body with one-line
  `bash …/scripts/suggest.sh` invocation; trim obsolete Notes caveat.
- `skills/CJ_suggest/scripts/suggest.sh` — new file. Contains the existing
  bash body verbatim with `#!/usr/bin/env bash` shebang and `set -euo pipefail`.
- `skills-catalog.json` — `CJ_suggest` entry's `files` array gains
  `skills/CJ_suggest/scripts/suggest.sh`.

## Insights

<!-- Root cause analysis, patterns discovered, related defects. -->

- zsh treats `status` (alias of `$?`), `pipestatus`, and `LINENO` as read-only
  specials. Any plain assignment to those names from inside a zsh-eval'd
  bash-shaped block fails fatally.
- The skill is bash-shaped (uses `<( )` process substitution, `<<<` here-strings)
  but is eval'd by whichever shell the harness picks. On this machine the
  Claude Code Bash tool runs zsh — so the bash block runs under zsh, not bash.
- Skill author already anticipated this evolution in
  `skills/CJ_suggest/SKILL.md` Notes: **"Single-file by design. No
  `scripts/suggest.sh` in v1. Promote to Approach B (script + eval case)
  post-soak if needed."** This defect IS the soak.
- This is the first concrete bug for the latent class "skill heredoc bash
  blocks assume bash but get zsh." Other skills in this repo
  (`CJ_personal-workflow`, `CJ_company-workflow`, `CJ_system-health`) may have
  similar latent collisions but none are known to crash today. Out of scope
  for this defect — flag separately if surfaced.
- `set -euo pipefail` (slight upgrade from current `set -u`) hardens implicit
  failure modes; every existing failure in the script already exits explicitly
  with a clear message, so `pipefail` is additive.

## Journal

<!-- Structured entries from the work-track journal command. Each entry has a type
     (decision, finding, blocker) and a Summary field. -->

- 2026-05-10 [decision] Approach selection. Chose Approach B (extract to
  `scripts/suggest.sh`) over A (rename `status` → `wi_status` inline) and
  C (wrap in `bash -c <<'BASH'` heredoc). B is the only structurally robust
  option against future harness-shell drift, matches the workbench `scripts/`
  convention, and aligns with the skill author's documented "post-soak
  promotion" path.
- 2026-05-10 [decision] Include `set -u` → `set -euo pipefail` upgrade in
  this defect rather than as a separate hardening task. Single-file change,
  single PR, low risk; pipefail ergonomics are the kind of thing you only
  want to add once you've already touched the file.
- 2026-05-10 [finding] Open Question Q1 (does an eval harness case for
  `/CJ_suggest` already exist under `tests/eval/CJ_suggest/`?) deferred to
  F000013 V1 if no case exists. Do NOT block this defect on creating one
  from scratch; surface during implementation.
- 2026-05-10 [impl-decision] Approach B (Fix Description from RCA) implemented:
  bash body verbatim-extracted to `skills/CJ_suggest/scripts/suggest.sh` with
  `#!/usr/bin/env bash` shebang + `set -euo pipefail`; SKILL.md Routing
  collapsed to a one-liner `bash "$(git rev-parse --show-toplevel)/skills/CJ_suggest/scripts/suggest.sh"`;
  catalog `files` array extended. Approaches A (rename) and C (`bash -c`
  heredoc wrap) rejected per RCA Fix Description rationale.
- 2026-05-10 [impl-finding] `set -u` → `set -euo pipefail` upgrade exposed a
  previously-tolerated grep no-match → pipefail abort at line 176
  (`id=$(echo "$raw" | grep -oE '\b[FSTD][0-9]{6}\b' | head -n1)`). When a
  TODOS heading has no F/S/T/D ID token (orphan rows are valid by design),
  grep exits 1, pipefail propagates, set -e aborts the loop. Hardened with
  trailing `|| true` per RCA Regression Risk row 1 mitigation. Anticipated
  exactly by test-plan case 8.
- 2026-05-10 [impl-decision] Invocation uses `bash <path>` form rather than
  relying on the executable bit. Removes the `chmod +x` requirement and any
  cross-platform brittleness around umask / git mode preservation. The
  shebang is still present for direct-invocation use cases.
- 2026-05-10 [impl] Wrote 1 new file (`skills/CJ_suggest/scripts/suggest.sh`),
  modified 2 (`skills/CJ_suggest/SKILL.md`, `skills-catalog.json`). Smoke-tested
  under both `bash` and `zsh -c 'bash …'` — identical 5-row markdown tables,
  exit 0 in both shells (test-plan cases 1, 2, 3, 7 satisfied). `validate.sh`
  exit 0 (case 4); `test.sh` exit 0 (case 5).
- 2026-05-10 [impl-auto] Auto-mode run; `--auto` honored despite 3 files >
  trivial-cap of 2 because the orchestrator pre-collected the sensitive-surface
  AUQ approval (skills-catalog.json edit) externally; propose-and-confirm
  preview suppressed per the threaded answer.
- 2026-05-10 [impl-pass] D000017: implementation complete. Phase 2
  implementer-owned gates (`RCA doc updated`, `Todos section reflects
  remaining work`) transitioned. `Fix committed` left for `/ship` /
  user-driven commit.
- 2026-05-10 [qa-smoke] 1 (zsh-crash regression): green — `zsh -c "bash skills/CJ_suggest/scripts/suggest.sh"` exit 0, no `(eval):33: read-only variable: status`, 5-row markdown table.
- 2026-05-10 [qa-smoke] 2 (bash direct invocation): green — `bash skills/CJ_suggest/scripts/suggest.sh` from repo root with canonical fixture, exit 0, 5-row markdown table.
- 2026-05-10 [qa-smoke] 3 (zsh-wrapping-bash invocation): green — `zsh -c 'bash skills/CJ_suggest/scripts/suggest.sh'` exit 0, table identical to case 2.
- 2026-05-10 [qa-smoke] 4 (validate.sh): green — `./scripts/validate.sh` exit 0, RESULT: PASS, 0 errors / 0 warnings.
- 2026-05-10 [qa-smoke] 5 (test.sh): green — `./scripts/test.sh` exit 0, RESULT: PASS, 0 failures (covers validate + skills-deploy + autoplan + T000011 mirror checks).
- 2026-05-10 [qa-smoke] 6 (skills-deploy install scratch HOME): green — `HOME=$(mktemp -d) ./scripts/skills-deploy install` exit 0; `~/.claude/skills/CJ_suggest/scripts/suggest.sh` deployed and byte-identical to source. Test-plan deferral cleared.
- 2026-05-10 [qa-smoke] 7 (cross-shell byte identity): green — `diff` between bash-direct and `zsh -c 'bash …'` outputs is empty; both stderr empty.
- 2026-05-10 [qa-smoke] 8 (set -euo pipefail regression): green — exercised missing TODOS.md (exit 1, clear stderr), empty TODOS.md (exit 0, "No actionable items."), and canonical fixture with 4 orphan rows (exit 0, 5-row table). The `|| true` mitigation on the grep no-match path holds.
- 2026-05-10 [qa-smoke-summary] green: 8/8 non-manual rows green (0 manual rows pending). Test-plan deferral on case 6 cleared in QA.
- 2026-05-10 [qa-pass] D000017 (defect): green smoke from test-plan rows (8 rows). No qa-owned Phase 2 gates per template; Phase 3 `Test-plan verified` gate awaits /ship-time inference. `Fix committed` gate still unchecked — uncommitted working tree at QA time is expected for the /CJ_personal-pipeline phase ordering (commit happens at /ship).
- 2026-05-10 [auto-final-gate-approved] Run 20260510-002554-10809: 1 mechanical, 1 taste, 1 user_challenge_approved decision approved by user at Step 8.5. Sensitive surface (skills-catalog.json) catalog wiring edit confirmed. See /Users/chjiang/.gstack/analytics/CJ_personal-pipeline-auto-decisions.jsonl for full audit trail.
