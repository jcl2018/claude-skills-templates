# TODOS

## Active work

### ~~Rename user-authored skills to `CJ_` prefix (P2, M)~~ DONE
Closed by T000018 (v2.0.0). All 8 user-authored skills now namespaced under
`CJ_*`: `CJ_personal-workflow`, `CJ_system-health`, `CJ_scaffold-work-item`,
`CJ_implement-from-spec`, `CJ_qa-work-item`, `CJ_personal-pipeline`,
`CJ_suggest`, `CJ_company-workflow` (deprecated). Aligns with the existing
`anthropic-skills:*` and `KB_*` namespacing on the user's machine, ends slash-
command collision risk with upstream/native skills, marks ownership unambiguously.
**Breaking:** all slash-command names change post-deploy; consumers must run
`./scripts/skills-deploy install --include-deprecated` after pulling v2.0.0
to re-link the renamed skills under `~/.claude/skills/CJ_*/` and templates
under `~/.claude/templates/CJ_personal-workflow/`. Catalog, scripts (`validate.sh`,
`test.sh`, `test-deploy.sh`, `skills-deploy`, `eval.sh`,
`check-gates-update.sh`), CLAUDE.md routing block, README.md (regenerated),
work-copilot byte-mirror, and per-skill SKILL.md cross-references all updated
in lockstep. `git mv` used throughout so blame history follows.

### ~~scripts/test.sh SIGPIPE flake forces --admin overrides at ship time (P2, S)~~ DONE
Closed in v1.15.1. `scripts/test.sh` lines 1879/1893/1907/1918/1929/1950/1970 used `if [ ... ] && echo "$_t11_out" | grep -qF "needle"; then` patterns. Under `set -o pipefail` (inherited from `lib.sh`), GitHub Actions runners hit a SIGPIPE race: when `grep -qF` matched early and exited, `echo`'s next write hit a closed pipe → pipeline exits non-zero → enclosing `if` becomes false → `fail_test` triggered spuriously. Locally the race window was too tight to reproduce; in CI it tripped 2-3 times per run inconsistently. Two consecutive ships needed `--admin` overrides for the same flake: PR #74 (v1.13.1) and PR #75 (v1.14.0). **Fix shipped:** replaced each pipeline with a SIGPIPE-free `case "$_t11_out" in *"needle"*) true;; *) false;; esac` form across all 7 call sites in T000011 + autoplan D5 blocks. Full local suite green. Out-of-scope sites at lines 1700/1713/1732/1741/1816/1835 left alone (different test blocks — same fix can be applied if they ever flake). **Reference:** spawned as a follow-up task during /land-and-deploy on PR #75 (2026-05-10).

### ~~T000003: skills-deploy subfolder template support (P1, M)~~ DONE
Regex extended to allow `subfolder/name.md` patterns. `mkdir -p` added for subfolder creation during deploy. Company-workflow templates now deploy correctly.

### ~~Fork-aware update detection for skills-update-check (P3, S)~~ DONE
Closed by T000015 (v1.13.0). Implemented as part of F000014's bootstrap pipeline run — `/personal-pipeline` was invoked on a synthetic design doc, scaffolded T000015 task, and the implement subagent shipped the fork-aware fallback. The original "if origin missing, try upstream" gate was tightened during /ship adversarial review: now drives off fetch success rather than remote-configured-ness, so a dead-URL origin also falls through to upstream cleanly.

### ~~Pre-existing template-ownership test failures in test-deploy.sh (P2, S)~~ DONE
Re-pointed 22 references to `doc-RCA.md` (subfoldered to `templates/personal-workflow/doc-RCA.md` in v1.3.x) onto `templates/doc-SKILL-DESIGN.md` (the only remaining flat-path template). Tests T2/T4-T7 now pass end-to-end. Closed by D000016 alongside the wire-into-CI fix below.

### ~~Wire test-deploy.sh into CI / test.sh (P3, S)~~ DONE
Added invocation of `scripts/test-deploy.sh` to `scripts/test.sh` between the T11 manifest schema-parity tests and the Summary block. The existing wrapper-grep pre-flight check stays as-is (structural assertion). Negative test confirmed wire-up catches future regressions: reintroducing one stale reference produces `RESULT: FAIL` with named failure, restored → PASS. Closed by D000016.

### v1.17.0: drop telemetry `mode` field from personal-pipeline JSONL writes (P4, S)
v1.16.0 (S000029) flipped `/personal-pipeline` to single-mode. The telemetry `mode` field at `~/.gstack/analytics/personal-pipeline.jsonl` now always emits `"auto"` literal (deletion deferred to give external JSONL readers one release of grace). v1.17.0 should drop the field entirely from `skills/personal-pipeline/pipeline.md` Step 9.1 jq emit and the fallback `echo` line, and update the explanatory comment. Sunset trip-wire (Step 9.2) doesn't slice by mode anyway, so deletion is mechanical. **When:** v1.17.0 release window. **Reference:** `work-items/features/personal-workflow/F000014_personal_pipeline_orchestrator/S000029_auto_default/`.

### Origin remote URL pinning for the upgrade path (P4, S)
The "Upgrade now" body block runs `git -C "$source" pull --ff-only origin main` based on `manifest.source` from `~/.claude/.skills-templates.json`. A user who can write that manifest can redirect upgrades to attacker-controlled code. Mitigation: at install time, store `manifest.upstream_url` (the expected `origin` URL) and have skills-update-check verify `git -C "$source" remote get-url origin` matches before recommending upgrade. Same trust boundary already applies to skills-deploy install, so this is hardening, not a new defense. **Depends on:** any real-world threat scenario where this matters.

### ~~`/personal-pipeline` orchestrator over the 3 pipeline skills (P3, M)~~ DONE
Closed by F000014 (v1.13.0). Built per Approach B from the 2026-05-08 office-hours session, but with two design adjustments locked by S000026 spike findings: (a) AUQs are pre-collected at the orchestrator before Phase 2 dispatch (subagents have no AskUserQuestion tool in Claude Code 2.1.91 — `RESULT: AUQ_NEEDED` contract was unworkable), (b) RESULT-line parser is lenient (strips markdown blockquote prefixes + code fences, since subagents wrap RESULT inconsistently 60% of trials). Soak gate behavior: orchestrator carries an explicit sunset criterion (mechanical trip-wire on `~/.gstack/analytics/personal-pipeline.jsonl`, ≥3 of 5 `halted_at_gate` recommends delete; AUQ on invocation 6 then every 5). First real run on the Fork-aware update detection task ran end-to-end green during /ship.

### ~~Phase 3 lifecycle-gate auto-update gap: /ship and /land-and-deploy don't update trackers (P2, M)~~ DONE
Closed by F000011 (v1.10.0). Approach: combined option 2 + option 3 from the original list — built `/personal-workflow check --update` flag (the engine, in `scripts/check-gates-update.sh`) AND extended the existing post-merge hook to call it. Auto-trigger via `git pull main` after ship satisfies P5 (no new manual command to remember). 5 of 6 Phase 3 gates auto-marked from external state; `E2E walked manually` explicit-excluded; `/personal-workflow check — validation passed` deferred in v1 due to recursion risk. Documented in `work-items/features/personal-workflow/F000011_phase3_gate_autoupdate/`.

### `/scaffold-work-item` Step 5 idempotency hole (P3, S)
Step 5 of `skills/scaffold-work-item/scaffold.md` always generates a fresh ID by incrementing the max existing tracker prefix. Re-running on `chjiang-main-design-20260508-102829.md` (F000010's source design doc) would write a duplicate F000011 alongside the existing F000010 — Step 9's idempotency check uses TARGET_PATH derived from the freshly-generated NEW_ID, so the existing dir is never inspected. Closes the deferred S000017 AC-5 (idempotency). **Fix:** before Step 5, either read the source design doc's `**Status: SCAFFOLDED → ...**` footer (Step 12 already writes it) OR grep `work-items/*/TRACKER.md` frontmatter for a tracker referencing this design-doc path; if matched, set NEW_ID to the existing ID and let Step 9 boundary-check + NO-OP run as designed. **When:** before the next re-run of `/scaffold-work-item` on an existing work item — until then, the bootstrap workflow (backup → delete → re-scaffold → diff) is the working alternative. **Reference:** found 2026-05-08 during S000018/S000019 verification.

### ~~`/personal-workflow check` Step 18 traceability parser comma-split (P3, S)~~ DONE
Closed by S000022 (F000012, v1.11.1). Step 18 sub-step 3 prose tightened with explicit "split the cell on comma and trim whitespace" instruction; two worked examples added (multi-AC cell + mixed cell with placeholder); contract paragraph at the end of sub-step 3 names the split-before-filter ordering. Verified 2026-05-09 against F000010's S000018 + S000019 TEST-SPECs (which contain real multi-AC cells `AC-1, AC-2, AC-3`, `AC-5, AC-6`, `AC-2, AC-4`).

### ~~F000010 pipeline gap: implement+qa skills are user-story-only (P3, M)~~ PARTIAL — option 1 implemented in v1.11.0 (S000021)
S000021 (in F000012_pipeline_parity, v1.11.0) implemented option 1 — generalize per-type. `/implement-from-spec` and `/qa-work-item` now dispatch on `_TRACKER.md` frontmatter `type:` field and route to per-type input artifacts (user-story → SPEC + DESIGN; defect → RCA + test-plan; task → TRACKER + test-plan; feature → AskUserQuestion to pick a child). Per-type Phase 2 gate transitions implemented; commit gates (`Fix committed` for defects, `Core changes committed` for tasks) remain user/`/ship`-owned. Existing user-story flows preserved identically. **What's still pending:** (a) defect-path live integration test — manual smoke S1 in S000021's TEST-SPEC requires running `/scaffold-work-item <doc> --type defect` → `/implement-from-spec` → `/qa-work-item` end-to-end on a real defect. Will exercise post-merge when the next real defect surfaces. (b) Task-path live integration test — same shape but for task type; no real task work-items exist yet to verify against. (c) Defect QA E2E split — defect QA in v1 treats all `test-plan.md` rows as smoke-equivalent; if real-world demand surfaces for defect E2E with subagent dispatch, file a follow-up.

### `qa-work-item` + `implement-from-spec` catalog descriptions still say "user-story" (P3, S)
`skills-catalog.json` entries for `qa-work-item` and `implement-from-spec` describe scope as "a personal-workflow user-story" — but F000012 / v1.11.0 (S000021) generalized both skills to dispatch on tracker `type:` and handle all four work-item types (user-story, defect, task, feature-via-child-AUQ). The catalog descriptions never got updated, and `README.md` is auto-generated from the catalog (`scripts/generate-readme.sh`), so the staleness propagates to the public Skills table. Caught during /document-release for v1.13.0. **Fix:** edit both `description` fields in `skills-catalog.json` to mention the per-type dispatch (mirror the pattern of the `personal-pipeline` description), then `./scripts/generate-readme.sh > README.md`. **When:** next time someone touches either skill — bundle the fix with the same ship. **Reference:** found 2026-05-09 during F000014's /document-release post-ship audit.

### Verify `/personal-pipeline` works on a fresh remote machine (P3, S)
v1.13.0 shipped `/personal-pipeline` and the bootstrap pipeline run was validated on the author's machine. Need a clean-room verification on a different machine: fresh git clone, `./scripts/setup.sh` (or `skills-deploy install`), then run the orchestrator on a synthetic design doc end-to-end. **Why it matters:** Agent-tool subagent behavior, AskUserQuestion availability inside subagents (S000026 spike key finding), and `claude -p` headless behavior are all environment-dependent — the spike findings were captured on Claude Code 2.1.91 with the Opus overlay. A fresh-machine run validates the design holds across setups and catches any path-resolution / upstream-skill discovery regressions. **Steps:** (1) clone repo on remote machine, (2) `./scripts/setup.sh` (or `git pull && ./scripts/skills-deploy install` if already cloned), (3) verify `~/.claude/skills/personal-pipeline/SKILL.md` exists, (4) `/office-hours` to produce a small design doc, (5) `/personal-pipeline <design-doc>` end-to-end, (6) check `~/.gstack/analytics/personal-pipeline.jsonl` for the telemetry line. **When:** before recommending the skill broadly, or when a second machine becomes available. **Reference:** found 2026-05-09 during v1.13.0's /document-release session.

### F000013 V1 eval harness — nightly CI (P1, S)
S000024 shipped in v1.16.1: 4 personal-workflow cases (#2–#5 in the V1 case index) plus a supplementary `check-untested-p0` to satisfy AC-7 after system-health deferral; full suite verified via `bash scripts/eval.sh` at $0.99 / ~72s wall-clock. system-health behavioral cases (`report-clean-system`, `report-with-issues`) deferred to V2 — `tests/eval/lib/run-case.sh` doesn't fake `$HOME` and `system-health` hard-codes `~/.claude/`, so fixtures under `tests/eval/system-health/<case>/fixture/` are invisible. Path forward: opt-in `HOME=$tmpdir` runner flag. Remaining: **S000025** (nightly CI workflow at `.github/workflows/eval-nightly.yml`, first real CI run validation). After S000025 ships, mark the parent eval-harness entry DONE-V1.

## Deferred work

### ~~scripts/migrate-commands.sh (P3, S)~~ RETIRED
Depends on create-skill.sh which was removed. Skills are now created manually via CLAUDE.md guide.

### ~~Template version tracking (P3, S)~~ RETIRED
Superseded by collection versioning. Templates are covered by the collection version.

### ~~Skill authoring harness skill (P1, M)~~ RETIRED
Shipped as v0.1.0, then sunset in v0.2.3. Replaced by /office-hours + implement + /ship workflow.

### ~~Skill authoring enhancements (P3, S)~~ RETIRED
Depends on skill-author which was removed.

### ~~GitHub Actions CI for skill lifecycle (P3, S)~~ RETIRED
Depends on skill-check.sh which was removed. Validation now handled by validate.sh only.

### ~~skill-status.sh dashboard (P3, S)~~ RETIRED
Depends on skill-check.sh which was removed.

### ~~skill-diff.sh version comparison (P3, S)~~ RETIRED
Depends on skill-ship.sh which was removed.

### ~~Add `/docs check` and `/docs tree` to Phase 3 review gates (P2, S)~~ DONE
Already present in all 4 tracker templates. Phase 3 gates include `/docs check` and
`/docs tree` (feature/user-story) or `/docs check` (task/defect).

### ~~Stale example output in check.md and tree.md (P2, S)~~ DONE
Updated examples to show current hierarchy (1 story, 1 task). References to
deleted S000002, S000003, T000002, T000003 replaced.

### ~~Sync global rules with repo-local rules (P2, S)~~ DONE
Run `skills-deploy install --overwrite` to deploy repo-local source. Global rules
now match artifact-manifests.json (features = tracker only, 3-level fallback).

### ~~Template fallback chain inconsistency (P3, S)~~ DONE
Standardized to 3-level chain across all files: check.md, PHILOSOPHY.md, rules,
CLAUDE.md. The `~/.claude/spec/templates/` directory is now checked during validation.

### validate.sh structural check via graph JSON (P2, M)
Add structural completeness check to validate.sh by reading `work-item-graph.json`
badges instead of doing its own YAML parsing. Catches structural violations in
pre-commit, not just when someone runs `/docs check`.
**When:** After graph artifact schema (v1.0.0) is proven stable.
**Depends on:** `.docs/work-item-graph.json` emitted by `/docs check` Steps 15-17.

### Behavioral eval harness (P1, M) — PARTIAL — V1 case coverage shipped in v1.12.0 (S000023) + v1.16.1 (S000024); nightly CI (S000025) remains
Golden tasks, expected outputs, regression fixtures, safety checks per skill.
Measures whether a skill actually works, not just whether metadata exists.

**Shipped in v1.12.0 (S000023):** `scripts/eval.sh` runner + `tests/eval/lib/{run-case,seed-fixture}.sh` + first passing case (`check-flags-missing-lifecycle` for personal-workflow, $0.10/15s end-to-end). Spike 0 resolved (direct `--plugin-dir` works; schema enforcement is exit-fail). Security hardening (env scrub, symlink rejection, schema $ref lint, aggregate budget cap) baked in.

**Pending in F000013 follow-ups:**
- ~~**S000024** — V1 case coverage~~ — **shipped in v1.16.1.** 5 personal-workflow cases authored (#2–#6 in `tests/eval/README.md` V1 case index): `check-step18-faithful-comma-split` (S000022 regression), `check-passing-feature` (baseline), `check-missing-frontmatter`, `check-lifecycle-drift`, `check-untested-p0`. Full suite green at $0.99/run, ~72s wall-clock. `check-untested-p0` exhibits ~33% LLM-variance flake (3-run baseline) — nightly CI will surface drift. system-health cases deferred — see V2 trajectory below.
- **S000025** — Nightly CI workflow (`.github/workflows/eval-nightly.yml`), first real CI run validation, this entry marked DONE-V1 then.

**V2 trajectory:** runner $HOME-faking (unblocks system-health behavioral cases — current blocker is `tests/eval/lib/run-case.sh` not setting `HOME=$tmpdir` while `system-health` hard-codes `~/.claude/`); scaffold/implement/qa skill cases (need structural-assertion helpers); per-PR cadence with `paths` filter; LLM-judge for prose-quality outputs; sandboxed execution (drop `Bash` from --allowedTools, `env -i`-level scrub); parser-logic unit tests for `check.md` Step 18 in `scripts/check-helpers/parse-traceability.sh` (deterministic regression coverage that closes the S000022 spec-execution gap surfaced in S000024 RC2).

**Reference:** [F000013_eval_harness_v1/](work-items/features/ops/testing/F000013_eval_harness_v1/), source design at `~/.gstack/projects/jcl2018-claude-skills-templates/chjiang-main-design-20260509-110013.md`.

### ~~Batch version mode for multi-skill commits (P3, S)~~ SIMPLIFIED
Simplified by collection versioning. Use `collection-version.sh bump patch`.
**Depends on:** collection-version.sh
