---
type: design
parent: F000013
title: "Behavioral eval harness V1 — Feature Design"
version: 1
status: Draft
date: 2026-05-09
author: chjiang
reviewers: []
---

<!-- A feature's cross-story design doc. Captures the PROBLEM, the SHAPE of
     the solution, the BIG DECISIONS with rationale, the RISKS, the
     DEFINITION OF DONE, and out-of-scope boundaries. Story-scope detail
     (SPEC/TEST-SPEC) lives on the nested user-stories — do
     not duplicate it here. For a filled-in example, see
     `work-items/features/F000004_work_copilot/F000004_DESIGN.md`. -->

## Problem

The skill workbench has comprehensive metadata validation (`scripts/validate.sh`) and structural smoke tests (`scripts/test.sh`, `scripts/test-deploy.sh`), but no automated check that a skill *behaves correctly at runtime* against a fixture. Recent regressions (S000022 Step 18 traceability parser, D000016 stale template references) were caught by manual smoke testing or in-the-wild use, not by CI. Behavioral coverage is the missing tier.

The "Behavioral eval harness (P1, M)" TODO has been deferred since at least 2026-04-10 because scratch-workspace invocation of skills via Claude was previously "uncharted in Claude Code." That has since changed — the 2026 `claude` CLI exposes `--print`, `--output-format json`, `--json-schema`, `--plugin-dir`, `--max-budget-usd`, `--bare`, `--no-session-persistence` — a stack purpose-built for evals. V1 collapses what was previously a custom-runner project into a few-hundred-line bash script that spawns the real CLI against scratch worktrees.

## Shape of the solution

V1 is a bash runner (`scripts/eval.sh`) that discovers cases under `tests/eval/<skill>/<case>/`, seeds each case's fixture into a scratch tmpdir, spawns headless `claude` via the CLI, and validates the model's structured JSON output against a per-case JSON Schema. Cadence is nightly on `main` plus manual local invocation. V1 covers `personal-workflow` and `system-health` only.

The work decomposes into three shipping units, each one a coherent slice that can be tested + landed independently.

| Concern | User-story | Artifact |
|---------|-----------|----------|
| Verify CLI flag behaviors + ship the runner skeleton + first passing case | S000023 | [S000023/S000023_TRACKER.md](S000023_spike_and_skeleton/S000023_TRACKER.md) |
| Fill in V1 eval case coverage (personal-workflow + system-health) | S000024 | [S000024/S000024_TRACKER.md](S000024_v1_case_coverage/S000024_TRACKER.md) |
| Wire up nightly CI workflow + first real CI run + TODOS.md update | S000025 | [S000025/S000025_TRACKER.md](S000025_nightly_ci/S000025_TRACKER.md) |

## Big decisions

<!-- Choices that shape the feature, with rationale. Future readers need
     to know why this path over the rejected alternatives. -->

| # | Decision | Why |
|---|----------|-----|
| 1 | Eval target = real `claude` CLI invocation (not script-level extraction or raw Anthropic API call) | High-fidelity: tests the artifact the user actually invokes, not a deterministic core that happens to back it. Catches SKILL.md prose drift that script tests miss. CLI exposing first-class eval flags makes this no longer "uncharted." |
| 2 | Variance = structured JSON output validated against `--json-schema`, not prose golden-diff | LLM-driven prose output is non-deterministic; assertions on shape (not bytes) are robust. Eval prompts mandate JSON-only output. Schema validation is a CLI feature, no custom parsing. |
| 3 | Runner = bash + jq, V2 = Bun + TypeScript reserved | Matches existing `scripts/` conventions, ships fastest, eval cases (prompts, fixtures, schemas) are runner-agnostic so migration later only swaps `eval.sh` + `run-case.sh`. |
| 4 | V1 scope = `personal-workflow` + `system-health` only | Both have a primary user-facing output that's a structured report Claude returns to the user. Filesystem-mutating skills (`scaffold-work-item`, `implement-from-spec`, `qa-work-item`) need structural-assertion helpers that don't exist yet — defer to V2. |
| 5 | Cadence = nightly on `main`, not per-PR | Per-PR adds 30–90s + token cost to every CI run, dominated by lint-only/docs-only PRs that touch zero skills. `paths: ['skills/**', 'templates/**']` filter can be added later if signal/cost ratio justifies. |
| 6 | Eval tests in-repo skill source via fake `$HOME` + symlinks | The skill resolves `_REPO_ROOT` via `git rev-parse`; in a fixture tmpdir without `git init`, resolution falls through to `~/.claude/skills/` — directly contradicting "test in-repo source." Fake `$HOME` per case isolates skill loading and is concurrency-safe under `xargs -P`. |

## Risks & open questions

<!-- What could go wrong, and what's still undecided. Each row should
     have a "Next check" naming who/when resolves it — otherwise it
     will rot. -->

| Risk / Question | Next check |
|-----------------|-----------|
| S0.1: `--plugin-dir` may not load custom skills in `--bare --print` mode (designed for plugin-shaped directories, workbench has flat skill dirs) | Spike 0 (S000023 first task) — empirical test against known-valid fixture |
| S0.2: `--json-schema` may not accept inline JSON syntax shown in `claude --help` reliably | Spike 0 — verify via known-passing schema |
| S0.3: `--json-schema` may warn-only on mismatch instead of exit-failing | Spike 0 — run a known-bad case and observe; fallback is to always pipe through `ajv-cli` |
| Wall-clock estimate (under 12 min) is derived from 3-min/case worst with 4× parallelism — first nightly CI run may exceed | First real CI run in S000025 — if observed numbers exceed 50%, V1 needs fewer cases or tighter prompts |
| S000022 case tests "Claude faithfully executes the spec," not the parser logic itself — weaker signal than the design implies | Acknowledged trade-off; closing the gap requires extracting parser into `scripts/check-helpers/` (V2 scope) |
| `npx ajv-cli@5` cold-start under concurrent `xargs` children could race the npm cache (~30s × 4) on first run | Pre-warm step in `eval.sh` before xargs (already in design) |

## Definition of done

- [ ] `bash scripts/eval.sh` runs end-to-end on a clean checkout, reporting PASS/FAIL per case
- [ ] All three child stories (S000023, S000024, S000025) have shipped (Phase 3 complete)
- [ ] First nightly CI run completes successfully and surfaces metrics (cost, wall-clock)
- [ ] Observed cost ≤ $1.50/run; observed wall-clock ≤ 12 min/run (or success criteria revised in V1.1)
- [ ] TODOS.md "Behavioral eval harness (P1, M)" entry is marked DONE-V1 with pointer to this feature dir

## Not in scope

- **Filesystem-mutating skill coverage** (`scaffold-work-item`, `implement-from-spec`, `qa-work-item`) — defer to V2 with structural-assertion helpers
- **`deprecated/company-workflow` coverage** — permanently out of scope (skill is deprecated)
- **Per-PR cadence** — V1 is nightly only; per-PR with `paths` filter is a V2 concern
- **LLM-judge for prose-quality cases** — V1 is structured-JSON-only; LLM-judge for cases where schema is too rigid (e.g., design-doc-generating skills) is V2
- **Schema consolidation across cases** — V1 accepts hand-written drift; lifting shared shapes into `tests/eval/schemas/` with `$ref`s is V2
- **Parser-logic unit tests for `check.md`** — V1 closes the "Claude executes the spec" half; the "spec is correct" half requires extracting parser logic into `scripts/check-helpers/` and unit-testing in `scripts/test.sh` (V2)

## Pointers

- Parent tracker: [F000013_TRACKER.md](F000013_TRACKER.md)
- Roadmap: [F000013_ROADMAP.md](F000013_ROADMAP.md)
- Source design doc (`/office-hours`): `~/.gstack/projects/jcl2018-claude-skills-templates/chjiang-main-design-20260509-110013.md`
- Originating TODO: `TODOS.md` → "Behavioral eval harness (P1, M)" under Deferred work
