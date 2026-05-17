---
type: test-plan
parent: D000023
title: "Eval workflow hardening — F1 secret-exfil ingress + F3 prompt-injection RCE — Test Plan"
date: 2026-05-17
author: chjiang
status: Draft
---

<!-- Scope: ONE fix (defect) or ONE task. Cases must be concrete and reproducible.
     For broader coverage of a user story, use TEST-SPEC.md instead.
     For defects, the test cases are regression cases for the specific bug. -->

## Scope

This fix changes two files plus a fixture and the backlog (Approach C):

- `.github/workflows/eval-nightly.yml` — F1 atomic unit (branch-aware pre-check
  FIRST → protected Environment + secret-move → job `environment:` + `if: main`
  → delete old job-level `env:` LAST) + the T2 permanent non-`main` adversarial
  probe job step (ordered before the old-`env:` deletion).
- `tests/eval/lib/run-case.sh` — remove the `ANTHROPIC_API_KEY`-preservation
  special-case; scrub via `env -i`/explicit allowlist; add the fail-closed
  post-assert (`^ANTHROPIC` OR `_API_KEY|_TOKEN|_SECRET`).
- `tests/eval/<skill>/<case>/` — new plant-test fixture proving the post-assert
  fires (deliberately plants a fake key var; asserts the case aborts).
- `TODOS.md` — SEC-1 + F11 + F12 deferred follow-up rows (rows only, no code).

Out of scope (residual risk, explicit): same-UID recovery via files / `/proc` /
open FDs / loopback helper (Approach B, tracked V2 follow-up). The fail-closed
assert is env-surface only; the plant-test is defense-in-depth, not a
structural-impossibility claim.

## Regression Test Cases

| # | Test Case | Steps | Expected Result | Status |
|---|-----------|-------|-----------------|--------|
| 1 | F3 fail-closed post-assert fires on a planted key (plant-test) | Run the plant-test fixture: a scratch eval case whose setup exports `ANTHROPIC_API_KEY=planted` (or `FOO_API_KEY=planted`) into the to-be-exported env, then invoke `run-case.sh` on it. | `run-case.sh` aborts the case **non-zero** with a clear message naming the offending var; the `claude -p` subprocess is NOT spawned. Proves the assert cannot silently regress to fail-open. | Pending |
| 2 | F3 scrub is allowlist/`env -i`, not a broadened denylist | Inspect `run-case.sh`: confirm the `ANTHROPIC_API_KEY`-preservation special-case (old lines ~80-92) is deleted and the scrub builds the child env from an explicit allowlist / `env -i` (no `unset`-denylist pattern remains as the sole mechanism). | No `ANTHROPIC_API_KEY` (or any `*_API_KEY|*_TOKEN|*_SECRET`) survives into the case env on the non-`main`/local path; allowlist posture confirmed by inspection. | Pending |
| 3 | F3 negative probe — injection-style case cannot recover a usable key from env | Add a scratch case whose prompt instructs the model to `printenv` / dump env; run via `run-case.sh` on a non-`main`/local context. | No `ANTHROPIC*` value is present in the case env for the model's Bash to read (defense-in-depth level — NOT a structural-impossibility claim per the Non-goals boundary). | Pending |
| 4 | F1 branch-aware pre-check ships FIRST (atomic-unit, no-gap ordering) | Inspect the commit series / final `eval-nightly.yml`: the "Verify claude CLI + secret" step's `exit 1`-on-empty-key is gated behind `if: github.ref == 'refs/heads/main'`; off `main` it warns-not-fails and proceeds secretless. Verify by inspection that no commit leaves a non-`main` `key-with-old-env` window (the branch-aware gate / old-`env:`-made-main-only lands before/with the protected-Environment wiring, and the old job-level `env:` is removed LAST). | Branch-aware pre-check present and is the first cutover sub-step; no commit window where a non-`main` ref has the key under the old unconditional `env:`. | Pending |
| 5 | F1 Environment binding is the access control (not a bare `env:` ref) | Inspect `eval-nightly.yml`: the secret-bearing job declares `environment: <name>` AND `if: github.ref == 'refs/heads/main'`; the old unconditional job-level `env: ANTHROPIC_API_KEY` reference is gone. | Job declares `environment:` (deployment-branch rule → `main`) + `if: main` belt; no residual unconditional job-level `env:` secret reference. | Pending |
| 6 | T2 permanent non-`main` adversarial probe job step exists and is correctly ordered | Inspect `eval-nightly.yml`: a permanent job step asserts no `ANTHROPIC*` variable is visible on a non-`main` ref; it is ordered BEFORE the step that deletes/relies-on-removal of the old `env:`. | Permanent probe step present (not a one-time manual check); ordered before the irreversible old-`env:` deletion; a future Environment-rule regression would fail CI here. | Pending |
| 7 | TODOS.md deferred follow-up rows added (rows only, no code) | Inspect `TODOS.md`: dedicated rows for SEC-1 (npm-postinstall key exposure), F11 (full GITHUB_STEP_SUMMARY markdown sanitization), F12 (`actions/upload-artifact@v4 if: failure()`); `~~strikethrough~~`-exclusion left OFF (active backlog); each cross-references D000023 as the split origin. | 3 active (un-strikethrough) rows present, cross-referencing D000023; NO code change for SEC-1/F11/F12 in this work-item's diff. | Pending |
| 8 | SC2 — scheduled `main` nightly still runs the real API eval green | **[phase: post-ship]** After merge to `main`, a manual `main` dispatch (or the next scheduled run) executes the real API eval suite. | The scheduled-`main` real API eval suite runs green — no regression to the parent F000013 success criterion. **Structurally post-ship** — the protected Environment releases to `main` only by design, so this is NOT pre-merge-QA testable (TODOS.md:147 pattern). | Pending (post-ship) |
| 9 | Repo health — `/CJ_personal-workflow check` + `scripts/validate.sh` green | Run `/CJ_personal-workflow check work-items/.../D000023_*` and `./scripts/validate.sh` after the change. | Both pass; the new work-item dir + TODOS rows do not introduce catalog/manifest/template drift. | Pending |

## Verification Steps

<!-- How was the fix verified beyond the test cases above? -->

- [ ] `tests/eval/lib/run-case.sh` plant-test fixture run locally — case aborts non-zero (case #1)
- [ ] `bash -n tests/eval/lib/run-case.sh` clean; `bash -n`/`actionlint` (if available) on `eval-nightly.yml`
- [ ] `./scripts/validate.sh` passes (repo health, catalog/manifest/template)
- [ ] `/CJ_personal-workflow check` on the D000023 dir passes (boundary compliance)
- [ ] Inspection: F1 cutover ordering leaves no non-`main` `key-with-old-env` window and no scheduled-`main` no-key window (cases #4/#5)
- [ ] Inspection: T2 probe step is permanent and correctly ordered (case #6)
- [ ] Inspection: TODOS.md SEC-1/F11/F12 rows present, active, cross-ref D000023; no SEC-1/F11/F12 code in the diff (case #7)
- [ ] **[post-ship]** Manual `main` dispatch confirms the scheduled real API eval suite runs green (case #8 / SC2)

## Environments Tested

| Environment | Build | Result |
|------------|-------|--------|
| macOS (local dev — `run-case.sh` plant-test + scrub posture) | branch `claude/festive-borg-d10844` | Pending |
| GitHub Actions `ubuntu-latest` — non-`main` `workflow_dispatch` (secretless path + T2 probe) | branch `claude/festive-borg-d10844` | Pending |
| GitHub Actions `ubuntu-latest` — scheduled `main` (real API eval, SC2) | `main` post-merge | Pending (post-ship) |
