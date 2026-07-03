---
skill: CJ_test_run
last-updated: "2026-07-03T20:01:48Z"
---

# Using /CJ_test_run

`/CJ_test_run` executes a repo's test contract and reports evidence-derived
pass/fail. It is the "does it pass?" companion to `/CJ_test_audit`'s "is it
wired?": the audit proves the declared tests are wired (anchor-grep, coverage,
catalog freshness) but never RUNS them — a suite can be cited-green while actually
red. `/CJ_test_run` runs them and reports honest pass/fail, with the static
Stage-1 audit as a pre-step.

## When to use

- You want to actually RUN the repo's tests and get honest pass/fail — not just a
  static "are the tests wired?" audit.
- After a change, before `/ship`, to confirm the free-tier suite is green.
- On a machine where you suspect the audit-of-record is green but the suite might
  be red (the exact false-confidence gap this skill closes).
- In ANY repo that has adopted the two-tier test contract AND declared a
  `runners:` axis — the contract defines what runs, so this is portable.
- With `--dry-run` first, to see the plan (which runners, which tier, what each
  covers) before spending anything.
- To run ONE category or ONE named test (F000074; taxonomy V2 F000075):
  `--category <workflow|CI-push|CI-nightly>` runs every test in that category; a
  bare NAME runs the single test of that name (reusing the
  `docs/tests/<category>/<name>.md` name), honoring the same cost tiers as the
  runners flow. The `CI` category is split by cadence into `CI-push` (runs on
  every push / PR) and `CI-nightly` (runs nightly). A single-name run also
  surfaces/links that test's `docs/tests/<category>/<name>.md` front door — its
  `## How to run` section is the canonical command, so the run and the doc agree.

## When NOT to use

- To check whether tests are WIRED / whether the catalog is fresh / whether a
  `CJ_goal_*` orchestrator has a workflow test — that is `/CJ_test_audit` (the
  read-only static audit). `/CJ_test_run` runs `/CJ_test_audit`'s Stage-1 engine
  calls as a pre-step, but the audit's Stage 2/3 agent judgment lives in
  `/CJ_test_audit`.
- In a repo with no test-spec registry (nothing to run — it SKIPs honestly) or a
  registry with no `runners:` axis (it SKIPs with `no runners declared`; add
  runners first).
- When you want a paid eval or the local E2E harness by DEFAULT — those are
  behind `--evals` / `--e2e` / `--all` on purpose (the hard cost-tier law); a
  default run never touches a model.
- As a gate that decides merge — it is an operator-run report. The orchestrated
  cj_goal pipelines enforce QA via `/CJ_qa-work-item`, not this skill.

## Mental model

Three layers, one direction of data flow:

```
CONTRACT declares   ── the runners: overlay axis in spec/test-spec-custom.md
  (HOW to run)          (id, command, tier {free|paid|local-only}, covers, platform)
        │ parsed by test-spec.sh --list-runners
        ▼
ENGINE executes     ── scripts/test-run.sh: plan → tiered execution → report + ledger
  (evidence-derived)   every outcome derived from rc + output; nothing inferred
        │ invoked by (flags forwarded) after the Stage-1 audit pre-step
        ▼
WRAPPER narrates    ── /CJ_test_run: Stage-1 engine calls verbatim, then the engine,
                       then the report + ledger paths + the aggregate verdict
```

No layer infers. A registry with no runners is an honest `SKIP: no runners
declared`, never a guessed command. **Category mode (F000074, ADDITIVE)** is a
second selection on the SAME engine: `--category <workflow|CI-push|CI-nightly>`
or a bare test NAME selects from the `categories:` axis
(`test-spec.sh --list-categories`),
maps `name → command`, and runs exactly those tests under the same cost tiers,
writing a `mode: category` ledger; with no `--category` and no name the runners
flow runs unchanged. Because the `name → command` selection reuses the
`docs/tests/<category>/<name>.md` name, a single-name run surfaces/links that
per-test doc's `## How to run` front door (F000077) — the executed command and the
documented command are the same `categories:` row, so they can't drift apart. Every run writes a `.md` report + a
`.json` ledger (schema 1, timestamp, HEAD SHA, aggregate, per-runner rc/outcome/
covered-families) — the first citable evidence artifact for the contract's own
`suite-green` rule. The aggregate is a closed enum `{pass, fail, all-skipped}`:
any executed runner failing ⇒ `fail` + exit 1; ≥1 green and none failed ⇒
`pass`; zero executed ⇒ `all-skipped` + exit 0, NEVER rendered `pass`.

## Common pitfalls

- **Expecting a default run to run evals or E2E.** It doesn't — default is
  `tier: free` only. Pass `--evals` (paid), `--e2e` (local-only), or `--all`.
- **Reading a `skipped(...)` runner as green.** A skipped tier/platform/self-gated
  runner is NOT a pass; the aggregate counts only executed runners. An
  `all-skipped` aggregate is exit 0 but is never `pass`.
- **Confusing the two audits.** Stage-1 findings (coverage drift, stale catalog)
  are SURFACED in the pre-step but do NOT block the run — an invalid registry
  HALTS, but findings on a valid registry ride the final report. The full
  wired-ness judgment is `/CJ_test_audit`.
- **Committing a report.** `tests/test-run/reports/` is gitignored except the
  committed `EXAMPLE.md` — real reports are per-run artifacts, not tracked.
- **Adding a `ci` or `hook` runner.** Those families are runner-less-by-design
  (`ci` runs on GitHub; `hook` is verified installed). `test-spec.sh --validate`
  rejects them in a runner's `covers`; they appear in the ledger as family-level
  rows (`ci-only`; `hook-check: pass|fail`).

## Related skills

- **/CJ_test_audit** — the read-only static test audit (is it wired?). This skill
  runs its Stage-1 engine calls as a pre-step; the audit owns Stages 2/3.
- **/CJ_doc_audit** — the sibling doc contract audit.
- **/CJ_qa-work-item** — the orchestrated QA phase that enforces a work-item's
  test rows during a cj_goal run (the gate; this skill is an operator report).
- **/CJ_portability-audit** — the other engine-in-script operator lint over the
  catalog.
