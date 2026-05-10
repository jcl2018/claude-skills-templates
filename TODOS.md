# TODOS

## Active work

### ~~T000003: skills-deploy subfolder template support (P1, M)~~ DONE
Regex extended to allow `subfolder/name.md` patterns. `mkdir -p` added for subfolder creation during deploy. Company-workflow templates now deploy correctly.

### ~~Fork-aware update detection for skills-update-check (P3, S)~~ DONE
Closed by T000015 (v1.13.0). Implemented as part of F000014's bootstrap pipeline run — `/personal-pipeline` was invoked on a synthetic design doc, scaffolded T000015 task, and the implement subagent shipped the fork-aware fallback. The original "if origin missing, try upstream" gate was tightened during /ship adversarial review: now drives off fetch success rather than remote-configured-ness, so a dead-URL origin also falls through to upstream cleanly.

### ~~Pre-existing template-ownership test failures in test-deploy.sh (P2, S)~~ DONE
Re-pointed 22 references to `doc-RCA.md` (subfoldered to `templates/personal-workflow/doc-RCA.md` in v1.3.x) onto `templates/doc-SKILL-DESIGN.md` (the only remaining flat-path template). Tests T2/T4-T7 now pass end-to-end. Closed by D000016 alongside the wire-into-CI fix below.

### ~~Wire test-deploy.sh into CI / test.sh (P3, S)~~ DONE
Added invocation of `scripts/test-deploy.sh` to `scripts/test.sh` between the T11 manifest schema-parity tests and the Summary block. The existing wrapper-grep pre-flight check stays as-is (structural assertion). Negative test confirmed wire-up catches future regressions: reintroducing one stale reference produces `RESULT: FAIL` with named failure, restored → PASS. Closed by D000016.

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

### Behavioral eval harness (P1, M) — PARTIAL — V1 first slice shipped in v1.12.0 (S000023 of F000013)
Golden tasks, expected outputs, regression fixtures, safety checks per skill.
Measures whether a skill actually works, not just whether metadata exists.

**Shipped in v1.12.0 (S000023):** `scripts/eval.sh` runner + `tests/eval/lib/{run-case,seed-fixture}.sh` + first passing case (`check-flags-missing-lifecycle` for personal-workflow, $0.10/15s end-to-end). Spike 0 resolved (direct `--plugin-dir` works; schema enforcement is exit-fail). Security hardening (env scrub, symlink rejection, schema $ref lint, aggregate budget cap) baked in.

**Pending in F000013 follow-ups:**
- **S000024** — V1 case coverage (5 personal-workflow cases incl. S000022 regression + 2 system-health cases; xargs concurrency exercised once ≥2 cases exist).
- **S000025** — Nightly CI workflow (`.github/workflows/eval-nightly.yml`), first real CI run validation, this entry marked DONE-V1 then.

**V2 trajectory:** scaffold/implement/qa skill cases (need structural-assertion helpers), per-PR cadence with `paths` filter, LLM-judge for prose-quality outputs, sandboxed execution (drop `Bash` from --allowedTools, `env -i`-level scrub), parser-logic unit tests for `check.md` (closes the S000022 spec-vs-execution gap).

**Reference:** [F000013_eval_harness_v1/](work-items/features/ops/testing/F000013_eval_harness_v1/), source design at `~/.gstack/projects/jcl2018-claude-skills-templates/chjiang-main-design-20260509-110013.md`.

### ~~Batch version mode for multi-skill commits (P3, S)~~ SIMPLIFIED
Simplified by collection versioning. Use `collection-version.sh bump patch`.
**Depends on:** collection-version.sh
