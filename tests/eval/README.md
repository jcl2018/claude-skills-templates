# Behavioral eval harness — `tests/eval/`

## Why this exists

The harness answers: *"did a change to a skill break expected behavior?"* without requiring manual runs and eyeballing output.

**V1 value is narrow.** All 5 current cases test `/CJ_personal-workflow check`, the workbench's most stable skill. Nightly CI on V1 is useful but not critical — a solo maintainer who knows when they edited `check.md` will catch most regressions manually anyway.

**V2 is where this earns its keep.** The high-value targets are the mutating skills: `CJ_scaffold-work-item`, `CJ_implement-from-spec`, `CJ_qa-work-item`. A silent bug in `implement.md` that writes malformed tracker files is easy to miss across a refactor and hard to catch without automation. Eval cases for those skills need structural-assertion helpers (file-tree shape, frontmatter presence, journal entries written) — that's V2 scope.

Until V2 cases exist: trigger manually (`bash scripts/eval.sh` or `gh workflow run eval-nightly.yml`) before shipping changes to `check.md`. Nightly cron is low-value at the current 5-case coverage.

---

V1 of the eval harness for the skill workbench. Spawns the real `claude` CLI
headless against scratch worktrees, validates structured JSON output against
per-case JSON Schemas. Cadence is nightly on `main` (see
`.github/workflows/eval-nightly.yml`, shipped in S000025 / v2.0.7) plus manual
local invocation (`bash scripts/eval.sh` or `gh workflow run eval-nightly.yml`).

V1 scope: `CJ_personal-workflow` and `CJ_system-health` only — skills whose primary
user-facing output is a structured report. Filesystem-mutating skills
(`scaffold-work-item`, `implement-from-spec`, `qa-work-item`) defer to V2.

Source design: `~/.gstack/projects/jcl2018-claude-skills-templates/chjiang-main-design-20260509-110013.md`
Tracker: `work-items/features/ops/testing/F000013_eval_harness_v1/`

---

## Running locally

```bash
bash scripts/eval.sh                                      # all cases
bash scripts/eval.sh CJ_personal-workflow                    # one skill
bash scripts/eval.sh CJ_personal-workflow check-flags-missing-lifecycle  # one case
```

Exit 0 = all PASS. Exit 1 = at least one FAIL. Failed case names are surfaced
on stderr after the summary line.

The runner spawns `claude` per case in parallel under `xargs -P 4`. Each case
gets its own scratch tmpdir + fake `$HOME`, so concurrent runs don't share
state.

Per-case cost cap: `--max-budget-usd 0.15`. Total V1 budget target:
≤ $1.50/run for 6–10 cases; revise after first nightly CI observation
(S000025).

## Authoring a new case

A case is a directory under `tests/eval/<skill>/<case-name>/` containing three
files:

```
tests/eval/<skill>/<case-name>/
├── prompt.md              # what we ask Claude to do + JSON output contract
├── fixture/               # files seeded into the scratch tmpdir
│   └── ...
└── expected.schema.json   # JSON Schema asserting the shape of the model's response
```

**`prompt.md` contract** — every prompt:

1. **Opens with the explicit slash-command invocation** of the skill being tested.
   `--bare` skips CLAUDE.md auto-discovery, so the prompt MUST spell out
   `/skill-name <args>` rather than relying on the model to infer the skill.
2. **Closes with the JSON contract** instruction: `"Output only the JSON object
   matching the provided schema. Do not include prose outside the JSON."`

**Schema design** — assert on shape, not bytes. The schema validates that the
model emitted the right structural keys + types, not that the wording is
identical run-to-run. LLM variance in prose is expected; structural variance is
what indicates a real regression.

**Fixture design** — keep fixtures minimal. A case that needs a multi-file
work-item tree to exercise `personal-workflow check` should include just enough
files to surface the behavior. Hand-author the fixture from scratch or copy
+ trim from an existing closed work-item.

## Debugging a failing case

The runner prints `FAIL: <skill>/<case>` plus a one-line reason. To get the
full Claude output for a single case:

```bash
# Re-run the failing case manually with stderr visible:
bash tests/eval/lib/run-case.sh "<skill>"$'\t'"tests/eval/<skill>/<case>/" \
  ./skills ./templates 2>&1 | tee /tmp/eval-debug.log
```

Common failure modes:

- **`model did not emit parseable JSON in .result`** — the prompt didn't
  reliably elicit JSON output. Tighten the JSON contract in `prompt.md`. Tip:
  show an example JSON object inline in the prompt.
- **`schema validation`** — model emitted JSON, but it didn't match the schema.
  The ajv-cli error usually names the offending field. Either tighten the
  prompt or relax the schema (preserve coverage, drop over-strictness).
- **`claude exit N`** — non-zero exit from the CLI itself. Common causes: cost
  cap hit (`--max-budget-usd 0.15`), auth failure (`ANTHROPIC_API_KEY` not
  set), `--plugin-dir` couldn't load the skill (see Spike 0 below).

## Spike 0 findings (resolved 2026-05-09)

Three CLI behaviors that the V1 design treated as unknowns. All resolved
empirically against the `check-flags-missing-lifecycle` fixture.

### S0.0 — Auth in `--bare` mode (newly discovered)

`claude --bare` documents: *"Anthropic auth is strictly ANTHROPIC_API_KEY or
apiKeyHelper via --settings (OAuth and keychain are never read)."*

For OAuth-authenticated local users (the common case), `--bare` subprocess
**fails with "Not logged in · Please run /login"**. CI with
`ANTHROPIC_API_KEY` set as a repo secret would work fine.

**Decision:** drop `--bare` from V1's `run-case.sh`. Trade-off: we lose the
hermetic-context benefit (`--bare` skips hooks, plugin sync, auto-memory,
CLAUDE.md auto-discovery). For V1 this is acceptable — the eval is
single-skill scoped and the user's CLAUDE.md / hooks aren't going to mutate
the structured-JSON output materially. Revisit for V2 if reproducibility
issues surface.

For CI: set `ANTHROPIC_API_KEY` as a secret, runner works either way.

### S0.1 — Skill loading via `--plugin-dir`

**RESOLVED — direct works.**

Test:
```bash
claude -p "/CJ_personal-workflow check work-items/" \
  --plugin-dir <repo>/skills \
  --add-dir <fixture-tmpdir> \
  --print --output-format json --no-session-persistence \
  --permission-mode bypassPermissions \
  --model sonnet
```

The skill is discovered + invoked, runs the validation, emits output. No
fake `$HOME`, no plugin manifest wrapper, no symlink dance needed.
`run-case.sh` simplified to use direct `--plugin-dir`.

### S0.2 — `--json-schema` syntax

**RESOLVED — inline JSON works as documented.**

`--json-schema "$(cat schema.json)"` accepted. The CLI parses the schema and
enforces it on the model's structured output. `@<file>` shorthand was not
tested — `run-case.sh` uses inline regardless.

### S0.3 — `--json-schema` enforcement on mismatch

**RESOLVED — outcome (a): non-zero exit, retries until cap.**

Test: passed a deliberately impossible schema (required a field the prompt
didn't elicit). The CLI:

- Retried 16 turns trying to coerce the model into matching the schema
- Eventually exit-failed with `subtype: error_max_structured_output_retries`
- `is_error: true`, `exit_code: 1`
- Cost: $0.26 (vs $0.15 for the happy-path run on a sane schema)

**Decisions:**

1. **Drop the `ajv-cli` post-validation step.** The CLI enforces natively;
   layering ajv-cli is redundant.
2. **Schemas should focus on shape + critical values, not every value.**
   Over-strict schemas trigger retry storms that 2x the per-case cost.
3. **Per-case `--max-budget-usd` raised from 0.15 to 0.50** to leave headroom
   for occasional retry storms during normal authoring iteration.

### Empirical baselines from Spike 0

- **`check-flags-missing-lifecycle` happy-path cost:** $0.13–$0.16
- **`check-flags-missing-lifecycle` happy-path wall-clock:** ~28–37s
- **Retry-storm cost (over-strict schema):** ~$0.26 / ~54s before giving up

Projected V1 totals (extrapolating from this case to 10 cases of similar
complexity):

- **10 × $0.15 = $1.50/run** (matches the design's success criterion ≤ $1.50)
- **10 × 28s ÷ 4 parallel = ~70s wall-clock** (well under the 12-min target)

S000024 shipped 5 cases (case index #2–#6). Observed per-case spend during
authoring: $0.13–$0.35 (median $0.15). Six-case suite cost: see the
full-suite verification log in `work-items/features/ops/testing/F000013_eval_harness_v1/S000024_v1_case_coverage/S000024_TRACKER.md`.

## V1 case index

| # | Case | Skill | Type | What it validates |
|---|------|-------|------|-------------------|
| 1 | `check-flags-missing-lifecycle` | CJ_personal-workflow | reasoning | Tracker missing whole `### Phase` headers is detected; reports `missing_phases` and `below_minimum` in JSON |
| 2 | `check-step18-faithful-comma-split` | CJ_personal-workflow | regression | S000022: Claude comma-splits multi-AC traceability cells like `AC-1, AC-2, AC-3` so each P0 maps to coverage. See empirical caveat below. |
| 3 | `check-passing-feature` | CJ_personal-workflow | baseline | Canonical valid feature work-item produces `overall: PASS` with every sub-check PASS. Distinguishes "real failure detected" from "validator broken on valid input". |
| 4 | `check-missing-frontmatter` | CJ_personal-workflow | failure-detection | Tracker with only `name` + `type` (other required fields missing) is flagged with `missing_fields` populated and `overall: FAIL`. |
| 5 | `check-lifecycle-drift` | CJ_personal-workflow | failure-detection | Gate-row drift inside lifecycle phases — every `### Phase` header is present but checkbox count is below template minimum. Distinct from #1 (missing phase) by enforcing `missing_phases: []`. |
| 6 | `check-untested-p0` | CJ_personal-workflow | failure-detection | Step 18 `[UNTESTED]` detection — SPEC has P0 #1, #2; TEST-SPEC's `ac_set` only contains `AC-1`. Schema asserts `untested_p0_stories: [2]`. Complements case #2 (which proves coverage works) by proving uncovered detection works. |

**S000023** (the spike) shipped #1. **S000024** ships #2–#6.

### Deferred to V2

| Case | Skill | Reason |
|------|-------|--------|
| `report-clean-system` | system-health | The runner doesn't fake `$HOME`, so any fixture under `tests/eval/system-health/<case>/fixture/` is invisible — the skill scans the maintainer's real `~/.claude/`. Needs `HOME=$tmpdir` override in `run-case.sh` (out of S000024 scope). |
| `report-with-issues` | system-health | Same blocker as above. |

The system-health gates are reachable in V2 once the runner gains a HOME-faking surface OR system-health gains a `--root <path>` argument. Until then, system-health behavioral coverage stays at zero.

### Empirical caveat — S000022 regression case (#2)

The case PASSed even when `check.md` Step 18's comma-split spec was reverted on a throwaway test branch. The signal is therefore **weaker** than the SPEC anticipated: Claude infers comma-splitting from common sense even when the spec is silent. The case still catches a deeper "model can't comma-split at all" regression (e.g., a future model whose extraction breaks on mixed-AC cells), but it doesn't catch a "we forgot to mandate comma-split in the spec" regression. The V2 parser-extraction work in `scripts/check-helpers/parse-traceability.sh` + unit tests is the path to deterministic regression coverage of this specific behavior.

### LLM-variance flake observations

Two cases exhibit a ~33% failure rate under repeated runs, both with `no parseable JSON object in .result` (model returns prose instead of JSON):

- **`check-untested-p0`** — 4 of 6 observed runs PASS (67% pass rate). Symptom: `--json-schema` enforcement retries fail; the case eventually exits without producing schema-matching JSON.
- **`check-passing-feature`** — 4 of 6 observed runs PASS (67% pass rate). Same symptom. This case asks Claude to do the most expensive work in the suite (full directory-mode validation across 3 artifact files), which probably explains why it's the second flaky one.

This aligns with the SPEC's pre-acknowledged Coverage Gap on LLM run-to-run variance. **Nightly CI at S000025 will surface flake rates empirically and is the right venue for tuning a retry policy or hardening these specific prompts.** Locally, `bash scripts/eval.sh` will sometimes need a single retry before reporting 6/6 PASS.

## V2 trajectory (out of V1 scope)

- Add scaffold-work-item, implement-from-spec, qa-work-item cases. These need
  structural-assertion helpers (file-tree shape, frontmatter present, journal
  entry written) layered on top of the V1 schema-only assertion.
- Per-PR cadence with `paths: ['skills/**', 'templates/**']` filter.
- LLM-judge for cases where `--json-schema` is too rigid (prose-quality output).
- Migration to Bun + TypeScript runner if bash debugging UX becomes a sustained
  pain point. Eval cases are runner-agnostic — only `eval.sh` + `run-case.sh`
  rewrite.
- Schema consolidation: lift shared `$ref`-able fragments into
  `tests/eval/schemas/common-frags.json`.
- Parser-logic unit tests for `check.md` (extract parser into
  `scripts/check-helpers/parse-traceability.sh`, unit-test in `scripts/test.sh`).
  Closes the gap acknowledged in `check-step18-faithful-comma-split`'s caveat.
