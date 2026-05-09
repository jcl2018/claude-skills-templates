# Behavioral eval harness — `tests/eval/`

V1 of the eval harness for the skill workbench. Spawns the real `claude` CLI
headless against scratch worktrees, validates structured JSON output against
per-case JSON Schemas. Cadence is nightly on `main` (see
`.github/workflows/eval-nightly.yml`, lands in S000025) plus manual local
invocation.

V1 scope: `personal-workflow` and `system-health` only — skills whose primary
user-facing output is a structured report. Filesystem-mutating skills
(`scaffold-work-item`, `implement-from-spec`, `qa-work-item`) defer to V2.

Source design: `~/.gstack/projects/jcl2018-claude-skills-templates/chjiang-main-design-20260509-110013.md`
Tracker: `work-items/features/ops/testing/F000013_eval_harness_v1/`

---

## Running locally

```bash
bash scripts/eval.sh                                      # all cases
bash scripts/eval.sh personal-workflow                    # one skill
bash scripts/eval.sh personal-workflow check-flags-missing-lifecycle  # one case
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
claude -p "/personal-workflow check work-items/" \
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

These projections need re-validation in S000024 when the full V1 case set
exists, but the V1 design holds up in the small.

## V1 case index

| # | Case | Skill | Type | What it validates |
|---|------|-------|------|-------------------|
| 1 | `check-flags-missing-lifecycle` | personal-workflow | reasoning | Tracker missing required lifecycle gate rows is detected and reported via JSON |
| 2 | `check-step18-faithful-comma-split` (S000024) | personal-workflow | regression | S000022: Claude correctly comma-splits multi-AC traceability cells |
| 3 | `check-passing-feature` (S000024) | personal-workflow | baseline | Canonical valid feature work-item produces overall=PASS |
| 4 | `check-missing-frontmatter` (S000024) | personal-workflow | failure-detection | Malformed frontmatter is detected |
| 5 | `check-lifecycle-drift` (S000024) | personal-workflow | failure-detection | Tracker missing lifecycle gates (variant) |
| 6 | `report-clean-system` (S000024) | system-health | baseline | Healthy state produces overall=PASS |
| 7 | `report-with-issues` (S000024) | system-health | failure-detection | Drifted state surfaces specific issues in JSON |

S000023 (this story) ships #1 only. S000024 fills out #2–#7.

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
