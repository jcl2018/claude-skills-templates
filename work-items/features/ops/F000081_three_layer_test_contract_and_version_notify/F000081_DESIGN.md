---
type: design
parent: F000081
title: "Three-layer test contract per category + portability reclass + git version-notification + retire CJ_portability-audit — Feature Design"
version: 1
status: Draft
date: 2026-07-04
author: Charlie Jiang
reviewers: []
---

<!-- A feature's cross-story design doc. Captures the PROBLEM, the SHAPE of
     the solution, the BIG DECISIONS with rationale, the RISKS, the
     DEFINITION OF DONE, and out-of-scope boundaries. Story-scope detail
     (SPEC/TEST-SPEC) lives on the nested user-stories — do
     not duplicate it here. -->

## Problem

Four coupled gaps in the workbench's test contract + deployment harness (all built on
the F000078 two-axis contract, driven by `scripts/test-spec.sh` + `scripts/test-run.sh`,
surfaced through `/CJ_test_audit` + `/CJ_test_run`):

1. **The two-axis test contract (category × layer) is half-populated.** Today only the
   `workflow` category has tests at all three meaningful per-category test levels; `infra`
   and `regression` are partial, and nothing REPORTS the gap. The three levels are
   **CI-nightly** (large deterministic — heavy checks off the per-PR path), **CI-push**
   (quick deterministic — the fast merge signal), and **local-hook** (quick agentic that
   verifies locally, on-demand, model-spending).
2. **Portability tests are miscategorized as `workflow`.** `portability-smoke` (CI-push)
   and `portability-deploy` (CI-nightly) are the install/sync/deploy HARNESS — standing
   verification `infra`, not a user-facing workflow — and portability has no local-hook
   third layer.
3. **The version-notification does not work on remote machines / foreign repos.**
   `scripts/skills-update-check` gates the whole check on the manifest `source` being a
   live workbench git checkout (`[ -d "$source_path/.git" ] || exit 0`, ~line 198). On a
   remote machine or consumer repo with no checkout it silently no-ops — so remote installs
   get NO "you're out of date" nudge.
4. **The standalone `/CJ_portability-audit` skill is now redundant.** Once portability is
   verified by the test contract (the automatic per-PR Check 18 lint + `portability-smoke`
   at CI-push, `portability-deploy` at CI-nightly, the version-check at local-hook), a
   manual verb is unneeded. Retire the skill; keep its engine.

The standing directive (memory `ci-push-gate-fast-only`) reinforces #1: the per-PR CI-push
gate must stay fast; the heavy `test.sh` (~11 min, OOM-flaky because it re-runs the whole
`validate.sh` ~16× plus fixture-repo suites) must move to a nightly cadence.

## Shape of the solution

Five workstreams that lock together, built as ONE work-item / ONE user-story / ONE PR
(the parts reinforce each other and the enum/contract change is cohesive — see Big
decisions #3):

- **WS1 — the per-category × 3-layer contract + advisory matrix (foundation).** A tight
  "three test levels per category" subsection in the general `spec/test-spec.md` prose
  (each category SHOULD reach CI-push / CI-nightly / local-hook; heavy-deterministic
  defaults OFF CI-push), mirrored byte-identically in the `test-spec.sh --seed` heredoc.
  `--check-structure` gains an ADVISORY per-category × {CI-push, CI-nightly, local-hook}
  coverage matrix — a `NOTE:` per empty cell (softer than the a–f `FINDING:`s), a small
  printed table, exit 0 always. `/CJ_test_audit` Stage 1 surfaces it.
- **WS2 — portability reclass + local-hook backfill.** Flip the two `categories:` rows to
  `category: infra` (both command-only, so `--check-structure` (b) forces NO folder move);
  hand-move the two front-door docs `docs/tests/workflow/{CI-push,CI-nightly}/…` →
  `docs/tests/infra/…`, update each row's `doc:` pointer + `purpose` wording, and edit the
  four `spec/doc-spec.md` rows so declared↔on-disk stays clean; regenerate the flat
  catalog. Backfill portability's local-hook cell with a command-only `portability-version-check`
  (infra/local-hook) row that runs a lightweight LOCAL sandbox check of the
  version-notification (mirroring the `e2e-local` pattern). Optional: an infra/CI-push
  command-row for the Check-18 lint itself, so all three portability layers are explicit.
- **WS3 — gstack-style version-notification via `git ls-remote`.** Rework
  `scripts/skills-update-check` to be checkout-independent: local version = manifest
  `collection_version`; remote version = `git ls-remote --tags <upstream_url> 'v*'` → the
  max `v<X.Y.Z>` tag (ssh-form `upstream_url` normalized → https). Remove the `.git`-gate
  as the hard stop; keep `.source` ONLY for the richer upgrade ACTION. Reuse the existing
  cache/snooze/skip machinery unchanged. A NEW root `tests/skills-update-check.test.sh`
  (family `test`) with a stubbed ls-remote + `.source`-absent manifest asserts the banner
  fires when remote > local, is silent when equal, and fail-softs when unreachable;
  registered as a `units:` row (Check 24 reverse sweep stays green).
- **WS4 — CI: safe-additive now (defer the trim).** IN: add `.github/workflows/nightly.yml`
  (cron + `workflow_dispatch`, full `scripts/test.sh` on ubuntu, mirroring
  `windows-nightly.yml`) + register it as a `ci` `units:` row; rewrite each negative test in
  `test.sh` to invoke ONLY its one targeted check (killing the ~16× re-run OOM flake). Both
  verifiable in-PR. DEFERRED: trimming `validate.yml`'s per-PR run + the matching `layer`
  reclass — an autonomous PR-stop can't verify a trimmed gate.
- **WS5 — retire `/CJ_portability-audit` (keep the engine).** Remove the routable verb
  across all consistency touchpoints (catalog, skill dir, routing, workflow-spec,
  philosophy), mirroring the `/CJ_repo-init` retirement precedent; keep
  `scripts/cj-portability-audit.sh` + Check 18; CHANGELOG the retirement.

| Concern | User-story | Artifact |
|---------|-----------|----------|
| The whole cohesive change — all five workstreams WS1–WS5 (three-layer contract + advisory matrix, portability→infra reclass + local-hook backfill, git ls-remote version-notification, safe-additive CI, retire /CJ_portability-audit) | S000131 | [S000131_three_layer_contract_portability_infra_version_notify/S000131_TRACKER.md](S000131_three_layer_contract_portability_infra_version_notify/S000131_TRACKER.md) |

## Big decisions

<!-- Choices that shape the feature, with rationale. -->

| # | Decision | Why |
|---|----------|-----|
| 1 | "Three levels per category" = category × **{CI-nightly, CI-push, local-hook}**; `pipeline-gate` is NOT a per-category test level (Premise 1). | These three are the meaningful per-category verification levels (large-deterministic / quick-deterministic / quick-agentic-local); `pipeline-gate` is an inline orchestrator halt, orthogonal to the per-category matrix. |
| 2 | Coverage is ADVISORY — report the matrix + backfill sensible cells; empty cells are `NOTE:`s, never hard-fails (Premise 2 / Q1). | `--check-structure` is "findings are the product, exit 0 always." An intentionally-empty cell must not hard-fail nor break the exit-0 posture; the matrix informs, it does not gate. |
| 3 | Ship all five parts as ONE feature / ONE PR (Premise 3 / Q2). | The parts reinforce each other (WS2 is an instance of WS1; WS3 is portability's missing local-hook; WS4 cashes in `ci-push-gate-fast-only`; WS5 is the punchline) and the enum/contract change is cohesive. |
| 4 | Part 3 mirrors gstack's checkout-independent MODEL but implements it with **`git ls-remote`**, not curl (Premise 4). | git is this repo's vetted hard dependency and handles ssh + non-GitHub upstream URLs a raw curl can't; the repo has ZERO curl precedent (`grep curl scripts/` = 0). The adversarial review showed gstack's own binary doesn't fit this repo — keep its MODEL, swap curl→git. |
| 5 | **CI: safe-additive now, defer the trim** (Premise 5). | IN this feature: the nightly full-suite workflow (+ its `ci` unit) and the targeted-negative-test refactor — both verifiable in-PR. DEFERRED: trimming `validate.yml`'s per-PR coverage + the matching layer-reclass — an autonomous PR-stop can't verify a trimmed gate or a cron-only nightly. |
| 6 | Part 2 reclassifies the two `categories:` TEST rows only; it does NOT touch the `CJ_portability-audit` catalog `portability` tier or Check 18 (Premise 6). | The engine + its automatic per-PR lint are what make the manual verb redundant — they must stay; only the row's `category` (and its doc path/purpose) changes. |
| 7 | Retire the `/CJ_portability-audit` routable verb; keep its engine `scripts/cj-portability-audit.sh` + Check 18 (Premise 7). | Once the contract proves portability automatically, a manual verb you must remember to run is redundant. The engine keeps working; only the redundant verb goes. Mirror the `/CJ_repo-init` retirement precedent. |
| 8 | `test`-family units live at repo ROOT; category cells are filled by command-only `categories:` rows, not by moving test files. | A `test`-family unit's `source` MUST be `scripts/test.sh` and its anchor `tests/<name>.test.sh` (root); the reverse sweep globs `tests/*.test.sh` at root only. A physical file under `tests/<cat>/<layer>/` is NOT a `units:` test. |

## Risks & open questions

<!-- What could go wrong, and what's still undecided. -->

| Risk / Question | Next check |
|-----------------|-----------|
| The `spec/test-spec.md` ↔ `test-spec.sh --seed` byte-identity is the single most fragile edit — the seed emitter is a heredoc INSIDE `test-spec.sh`; a lockstep miss reds the whole test-spec suite. | WS1 edits both files in lockstep; green the `seed-byte-identical` contract test in `tests/test-spec.test.sh` FIRST, before any other WS. |
| Every new `.github/workflows/*.yml` needs a `ci` `units:` row or Check 24's reverse sweep hard-fails on the PR that adds it. | WS4 registers `nightly.yml` as a `ci` unit (family `ci`, layer `CI-nightly`, anchor `name: <workflow name>`, source `.github/workflows/nightly.yml`) in the SAME PR. |
| A doc move under `docs/` is a doc-spec registry edit + a generated-catalog edit; `--seed-docs` seeds stubs but NEVER moves authored content — that is a hand-move. | WS2 hand-moves the two front-door docs, edits the four `spec/doc-spec.md` rows (Checks 15a/16), regenerates via `--render-docs` (Check 26), and re-runs `doc-spec.sh --check-on-disk` BEFORE greening. |
| `layer` must match the real trigger — relabeling a unit's `layer` to `CI-nightly` while it still runs per-PR is a contract lie the reverse sweep won't catch. | The DEFERRED units KEEP `layer: CI-push` (honest — they still run per-PR) until the deferred trim; the advisory matrix (WS1) simply reports the current placement. |
| Retiring a routable skill is consistency-heavy (Error checks 1/4/5, Checks 13/14, workflow-spec `--validate` + Check 27, the philosophy New-skills check, routing, Check 24). | WS5 mirrors the `/CJ_repo-init` retirement precedent (inspect git history + the current tree first) and runs whole `validate.sh` green before ship. |
| Portability's canonical local-hook level is "quick agentic"; the backfill fills it DETERMINISTICALLY (a stubbed-remote local sandbox). A truly agentic variant is deferred (Q1). | The advisory matrix (Q1) permits the deterministic fill; the agentic variant (a real skill preamble via `claude --print` in a stale sandbox) is a noted deferred follow-up. |
| `v`-tag assumption for ls-remote: WS3 reads the latest release `v<X.Y.Z>` tag. If a consumer's `upstream_url` repo doesn't tag releases, the check fail-softs to silent (Q2). | Acceptable (no false nudge) — holds today (collection v-tags are ratcheted by Error check 8, e.g. `v6.0.113`); noted in the script. |
| Depth-≤2 autonomous build, stop at a PR — anything the build + PR-stop cannot VERIFY in-PR is out of scope. | The `validate.yml` trim is DEFERRED to a separate attended work-item for exactly this reason; the autonomous PR ships only the in-PR-verifiable parts. |

## Definition of done

<!-- Objective, measurable criteria for "shipped." -->

- [ ] `test-spec.sh --seed` stays byte-identical to the edited `spec/test-spec.md` (`seed-byte-identical` contract test passes).
- [ ] `--check-structure` prints the per-category × 3-layer matrix + advisory gap `NOTE:`s, exit 0.
- [ ] The two portability rows read `category: infra`; the four front-door docs live under `docs/tests/infra/…`; `spec/doc-spec.md` updated; Checks 15a/16/26/27 green. The `portability-version-check` (infra/local-hook) command-row exists.
- [ ] `skills-update-check`, given a `.source`-absent manifest + a stubbed ls-remote, emits `SKILLS_UPGRADE_AVAILABLE` when remote > local, silent when equal, fail-soft when unreachable — proven by the new root `tests/skills-update-check.test.sh` (Check 24 reverse sweep green).
- [ ] `nightly.yml` exists + is registered as a `ci` unit (Check 24 green); negative tests are targeted (no whole-`validate.sh` re-run); full `test.sh` + full `validate.sh` green. `validate.yml` is UNTRIMMED this feature.
- [ ] `/CJ_portability-audit` is gone (catalog / dir / routing / workflow-spec / philosophy) with the engine + Check 18 intact; whole `validate.sh` green.
- [ ] VERSION bumped; README + generated catalogs regenerated.
- [ ] The deferred follow-up work-item is filed (trim `validate.yml`'s per-PR coverage + the matching layer-reclass).

## Not in scope

<!-- Explicit non-goals. -->

- Trimming `validate.yml`'s per-PR run to the fast set (moving the heavy suite / `test-deploy` off per-PR) + the matching `layer` reclass of those units to `CI-nightly` — DEFERRED to a separate attended work-item; an autonomous PR-stop can't verify a trimmed gate or a cron-only nightly (the review's core safety point).
- A truly agentic portability local-hook variant (a real skill preamble via `claude --print` in a stale sandbox asserting the model surfaces the prompt) — deferred; the backfill fills the cell deterministically, which the advisory matrix permits.
- Any change to the `CJ_portability-audit` catalog `portability` tier or Check 18 — only the two `categories:` TEST rows are reclassified; the engine + its per-PR lint are untouched.
- A TTL change to the version-check cache — YAGNI, cut per review; the existing cache/snooze/skip machinery is reused unchanged.
- Per-skill preamble edits for the new version-check — the checkout-independent rework is internal to `skills-update-check`; no preamble surface changes.

## Pointers

<!-- Cross-links to related artifacts. -->

- Parent tracker: [F000081_TRACKER.md](F000081_TRACKER.md)
- Roadmap: [F000081_ROADMAP.md](F000081_ROADMAP.md)
- Child user-story: [S000131_three_layer_contract_portability_infra_version_notify/S000131_TRACKER.md](S000131_three_layer_contract_portability_infra_version_notify/S000131_TRACKER.md)
- Source /office-hours design: `~/.gstack/projects/jcl2018-claude-skills-templates/chang-claude-ecstatic-greider-fb1178-design-20260704-003931.md`
- Lineage: F000074 (category test contract V1), F000075 (CI-push/CI-nightly cadence split), F000076 (QA-audit → nightly CI), F000077 (per-test-doc front door), F000078 (two-axis test contract), F000080 (CI-nightly deterministic); F000044/F000049 (Windows/portability + install==clone)
