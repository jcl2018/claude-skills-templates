# Philosophy

Why this workbench is built the way it is, the runtime standard its agent loop is
held to, and how to choose which `CJ_` skill to call. This doc is arranged by
**topic**; each topic groups the principles that share a concern. For the
machinery under the hood see [architecture.md](architecture.md), and for the
end-to-end workflows see [workflow.md](workflow.md).

| Topic | Principle | In one line |
|-------|-----------|-------------|
| **Deployment** | One source of truth — this checkout | Install == clone; every repo references the single `~/.claude/` install, `git pull` is deploy. |
| **Deployment** | Two delivery surfaces, one contract | The same doc-first work contract ships to Claude Code skills and a self-contained GitHub Copilot bundle. |
| **Doc contract** | The doc contract is one file, human + machine | `doc-spec.md` is both the human-readable doc map and the machine registry the CI validator + doc-release skill parse. |
| **Doc contract** | Two tiers, one portable pass: general by default, custom per repo | A general doc set ships to every repo; each repo adds its custom docs; one portable skill keeps both current, gated by the machine registry. |
| **Doc contract** | Trustworthy by construction, not by convention | A doc you can't trust is worse than no doc — generated views, declared-vs-on-disk gates, hard lints, and a self-healing advisory audit make doc trust mechanical, not promised. |
| **Harness-engineering best practices** | 1. Context is a finite resource — curate it | The window is an attention budget; keep the smallest high-signal set live. |
| **Harness-engineering best practices** | 2. Externalize state to durable storage | Write important state to the filesystem, not just the window — if a session dies, the work survives. |
| **Harness-engineering best practices** | 3. Design for stateless handoff | Make resumption a read, not a recollection — the unit of work ends by writing what the next one needs. |
| **Harness-engineering best practices** | 4. Verification is a continuous gate — judge the path | A quality gate at every step, evaluating the trajectory, with the verifier kept independent of the doer. |
| **Harness-engineering best practices** | 5. Tools & permissions are first-class | Spec tools like prompts; design permission before capability and give the riskiest verbs the strictest rules. |
| **CI/CD** | Four verification layers, one owner each | local-hook / ci / pipeline-gate / ratchet — each guarantee is owned by exactly one layer; `test-spec.md` is the map. |
| — | Decision tree | Which `CJ_` skill to call for a given input — see the routing map at the bottom of this doc. |

## Topic: Deployment

These principles are about how the workbench is *built and delivered* — the
producer/consumer side. They describe the single source of truth and the two
runtimes that contract ships to. (The one-file doc contract that holds the docs
themselves honest is its own topic — see *Topic: Doc contract* below.)

### One source of truth — this checkout

This workbench has one first principle. Everything else in its deployment design
is a consequence of it, not a separate decision.

> **There is exactly one source of truth — this git checkout. Installing it does
> not copy it; it references it. Every repo on the machine, and the workbench
> itself, run that one install.**

It has two halves: the **install model** (what `skills-deploy install` actually
does to your machine) and the **reference model** (how every other repo uses the
result). They are the same idea seen from the producer side and the consumer
side.

#### The install model: install == clone

You clone this repo and run `./scripts/skills-deploy install`. The install *is*
the clone. There is no second copy of the skills that can drift from the one you
edit.

- **Skills are symlinks into the checkout.** `~/.claude/skills/<skill>/<file>`
  points straight back at `skills/<skill>/<file>` in this checkout (macOS/Linux).
  Edit a skill's pipeline file here and the next invocation runs the edit — no
  reinstall, no build step.
- **Shared scripts are deposited copies.** `~/.claude/_cj-shared/scripts/*` are
  checksum-tracked copies of this repo's `scripts/*.sh`. They are the one
  deliberate exception to pure-symlink, so a consumer repo can resolve them
  without reaching into the checkout.
- **The manifest knows it is the clone.** `~/.claude/.skills-templates.json`
  records `install_mode: in-place` with `source == bundle_path`, both pointing at
  this checkout.

So `git pull` is the update mechanism: skills update the instant you pull (they
are symlinks); shared scripts refresh on the next `skills-deploy install`. And
there is **no runtime reach-back to a registered source path** — a skill resolves
its shared scripts repo-local-first (this checkout's own live `scripts/`), then
the `_cj-shared` copies. Nothing has to look up "where is the real install,"
because the install you are looking at *is* the real install.

#### The reference model: every repo references the one install

Other repos do not carry their own copy of the `CJ_` skills. They **reference**
the single `~/.claude/` install.

```
                         ~/.claude/  (the one install)
                         skills/ -> symlinks --+
                                               |
   +--------------+   +--------------+   +------v---------+
   |  repo A      |   |  repo B      |   | this checkout  |
   |  /CJ_goal_*  |   |  /CJ_goal_*  |   | (the source)   |
   +------+-------+   +------+-------+   +------+---------+
          |                  |                 |
          +------------------+-----------------+
                  all resolve to the SAME code
```

- Invoke a `CJ_` skill from any repo on the machine. Claude Code loads it from
  `~/.claude/skills/` — which is symlinks into this checkout. That repo is
  transitively running this workbench's live code.
- Behavior is therefore **identical across every repo and the workbench
  itself**, because they all resolve to the same one install. There is no
  per-repo skill copy to fall out of sync, and no "which version is this repo on"
  question to answer.

The single nuance: *inside* this checkout, a skill prefers its **own live
`scripts/`** (repo-local-first) so the workbench dogfoods its own uncommitted
edits before they are deposited; any other repo uses the `_cj-shared/` copies.
After an install those two are identical content.

#### Why this is the first principle

State "install == clone, reference one install" once and the rest of the design
follows as corollaries rather than choices:

- **One install, not N.** No per-skill bundles and no shared `~/.claude/cj-bin/`
  — there is a single checkout, and `~/.claude/` is a view onto it.
- **Develop in place.** The files you edit and the files that run are the same
  files. No copy-to-install step, no "did I reinstall?" doubt.
- **`git pull` is deploy.** Updating the checkout updates the machine, because
  the machine references the checkout.
- **Worktrees are isolated checkouts off the one source.** The orchestrators
  auto-create worktrees so parallel builds don't collide, then sweep them once
  their PR lands — each is a branch of the single source, not a rival copy.
- **A post-land sync step exists only because GitHub merges are remote.** A
  remote merge lands on GitHub without touching your local checkout, so afterward
  you `git pull` to bring the one source current. That is the *only* reason a
  post-merge sync step exists.

#### Windows: the model holds, the mechanism changes

Git Bash on Windows cannot create real symlinks, so `skills-deploy install`
falls back to **copy-mode**: `~/.claude/skills/` gets real-file copies with
checksum drift tracking instead of symlinks. The *model* is unchanged — the
manifest still records `install_mode: in-place`, the reference model is the same,
behavior is the same. Only the link mechanism differs, and CI guards that the
in-place contract holds under copy-mode.

### Two delivery surfaces, one contract

This workbench ships the same doc-first work contract to two runtimes:

- **Claude Code skills** (`skills/`) — the `CJ_` workflow family + utilities,
  auto-discovered and run as `/`-commands.
- **A GitHub Copilot bundle** (`work-copilot/`) — a self-contained bundle that
  carries the same work-item templates + a `/validate` workflow to machines
  without Claude Code. It is driven by a Python CLI, not a `/`-command.

What ports between them is the *structure* a contributor scaffolds against and
the validation that checks it. The `CJ_` orchestrators themselves are
Claude-only. See [architecture.md](architecture.md) for the Copilot bundle's
deploy mechanism.

## Topic: Harness-engineering best practices

The Deployment topic is about how the workbench is *built and delivered*. This is
a second, orthogonal lens — how the `cj_goal` agent loop should *behave at
runtime*. They are five principles distilled from the agent-harness engineering
field (Anthropic, OpenAI, Google, LangChain, Arize, and the 2025-2026
harness-engineering literature). An agent is "an LLM using tools in a loop," and
the model is the least reliable component in that loop; these five are how the
*harness* stays bounded when the model is wrong. The prompt decides how it
speaks; the harness decides how it acts.

### 1. Context is a finite resource — curate it

The window is an attention
budget with diminishing returns, and recall rots as it fills — a bigger window
just fills with stale tool output as fast. Keep the smallest high-signal set
live: compact, summarize, or offload as you go. *In the workbench:* the silent
build dispatches scaffold → implement → QA as depth-≤2 leaf subagents that
return ≤200-token summaries (detail goes to the tracker, not back through the
tool result), so the orchestrator's own window stays lean.

### 2. Externalize state to durable storage

Don't hold important state only in
the window — write it to the filesystem, the agent's real memory, as an index
of pointers and decisions rather than a transcript. *In the workbench:* the
per-branch resume state file, the committed work-item tracker + its journal,
the SPEC/DESIGN/TEST-SPEC triplet, and the per-run telemetry JSONL all live on
disk; if a session dies, the work survives.

### 3. Design for stateless handoff

Assume the next turn, session, or agent
remembers nothing; make resumption a *read*, not a recollection — the unit of
work ends by writing exactly what the next one needs. *In the workbench:* a
re-invocation resumes from the state file with validate-before-skip (the
recorded phase SHA must be an ancestor of HEAD, any recorded PR must still read
OPEN, the recorded design doc must still read `APPROVED`), and each leaf
subagent hands back a one-line RESULT, never its working context.

### 4. Verification is a continuous gate — judge the path

A quality gate at
every step, not only the end; evaluate the trajectory (what the agent actually
did), not just the final artifact, and keep the verifier independent of the
doer. *In the workbench:* `/CJ_personal-workflow check` runs at every phase
boundary, QA executes the work-item's test rows rather than merely checking a
TEST-SPEC exists, and the deterministic per-PR gate (`validate.sh` at the commit
hook, CI on the PR) blocks a broken change before it ever lands. The
agent-judged doc/test audit that surfaces deeper drift no longer sits on the
build path — it runs nightly in CI (filing findings to a GitHub issue) and on
demand via the standalone `/CJ_doc_audit` + `/CJ_test_audit` verbs. The concrete map of this principle — every verification surface, on
which of the two axes (category `{workflow, regression, infra}` × layer
`{CI-push, CI-nightly, pipeline-gate, local-hook}`) — is the `spec/test-spec.md`
registry (its `layers[]` map + the overlay's `categories[]` + `gates[]`); the
**CI/CD topic** below is the layered model this principle resolves to.

### 5. Tools & permissions are first-class

Spec tools like prompts; consolidate
fiddly multi-call flows into one high-level tool; return high-signal fields.
Permission is explicit — *design permission before capability*, and give the
riskiest verbs (push, merge, `rm`, network) the strictest rules. *In the
workbench:* every skill declares `allowed-tools`, feature runs stop at a
human-reviewed PR with no automatic merge, and `cj-handoff-gate.sh`'s denylist
blocks auto-deploy of exactly the skill surfaces a change touches.

The first three are the framework's strongest habits — externalized state and
stateless handoff are designed in from the ground up, and they are the two
hardest to retrofit later. Verification and context curation, once strong only
*between* phases, now reach *within* a long phase too: QA re-executes the
work-item's tests on a same-SHA resume instead of trusting a stale pass, and the
interactive design phase distills a compact receipt the rest of the build
continues from rather than carrying its full transcript. Permission is now a
single declared allow/ask/deny policy the live enforcement points reference, no
longer rules spread across frontmatter, leaf-skill code, and an external
denylist. The decision tree below is how you *use* the framework; these five are
the standard it holds itself to.

## Topic: CI/CD

The Harness topic's fourth principle — "Verification is a continuous gate" — says
*why* the workbench verifies at every step. This topic is the *concrete layered
model* that principle resolves to: the specific layers a change passes through,
and which layer owns which guarantee. (The Harness principle is the why; this is
the what-and-where.)

### Two axes: category × layer

A test is classified on **two orthogonal axes** — its *kind* and *where/when it
runs* — so one place answers both "what kind of test is this?" and "when does it
fire?" plus a per-test `deterministic | agentic` **mode** (agentic spends model
tokens, so `agentic ⇒ tier ≠ free`):

- **category** — the *kind*, `{workflow, regression, infra}`, modelled on the
  work-item that produced the test: a **workflow** test proves a whole
  user-facing workflow runs end to end (features earn these), a **regression**
  test proves a past defect stays fixed (defects earn these), and **infra** is
  the standing verification surface itself (the validator, the full suite, the
  deploy harness).
- **layer** — *where/when*, the four verification layers below.

The payoff a maintainer feels: `tests/<category>/<layer>/` tells you at a glance
what a test *is* and *when it fires* — the Windows portability smoke is
`workflow / CI-push` (it proves the install+sync workflow, cheap enough to gate
every PR); the heavy Windows deploy proof is the same workflow at `CI-nightly`.

### Four verification layers, one owner each

A change travels from an edit to a landed PR through **four independent
verification layers**, each running at a different moment and owning a different
kind of guarantee:

- **CI-push** — runs on every push / PR (GitHub Actions). It owns the whole tree
  being structurally and behaviorally sound on a clean runner: `validate.sh` +
  `test.sh` + shellcheck + the Windows Git-Bash smoke job. It hard-fails and
  gates the PR — the fast merge signal.
- **CI-nightly** — runs on a nightly schedule (GitHub Actions). It owns the
  heavier checks that would slow every PR run, deferred off the PR path: the
  Windows-native `skills-deploy` suite, the behavioral eval harness, the
  agent-judged doc/test audit.
- **pipeline-gate** — runs *during* a cj_goal orchestrator run. It owns the claim
  that this run did the right thing before it reached the PR: the inline halts for
  isolation, design-summary approval, QA, doc-sync, and ship. These
  are the halts the word "gate" is reserved for.
- **local-hook** — runs at `git commit` (the pre-commit hook) and for the
  local-only manual harnesses. It owns one thing: the commit is structurally valid
  before it ever leaves your machine. It runs `validate.sh` and hard-fails,
  blocking the commit.

`CI-push` and `CI-nightly` are the old undifferentiated `ci` blob, split by
cadence. **`ratchet` is no longer a layer** — a monotonic guard (VERSION never
goes backwards, the portability baseline stays at `FINDINGS=0`, USAGE.md stays
fresh against its SKILL.md) is a `ratchet: true` **flag** on the unit that owns
it, not a place a test runs.

The discipline is **one owning layer per guarantee** — each guarantee is checked
at exactly one layer, never re-checked at three layers with three vocabularies.
That is what makes the question *"what stops a broken change, and at which
layer?"* answerable from a single place: a structurally broken change is stopped
by **CI-push**, a process-broken change (built in-place, never designed, never
tested, undocumented, or self-merging) by a **pipeline-gate**, and a regression of
a monotonic property by a **ratchet flag**.

The concrete, machine-checked map of both axes and every gate — the prose, the
four-layer table, and a fenced `yaml` registry — is the verification contract
[`spec/test-spec.md`](../spec/test-spec.md) (its `layers[]` map + the overlay's
`categories[]` + per-mode `gates[]`, enforced by `validate.sh` Check 24). This
topic is the principle; `test-spec.md` is the live map.

## Topic: Doc contract

These principles are about how the *docs themselves* are kept honest. The model
is one chain: a single machine **registry** (`spec/doc-spec.md`) is the
source of truth — one Markdown table that a human reads and the parser parses,
so there is never a second copy to hand-maintain; and the contract's **logic**
lives here. `doc-spec.sh --validate` is the portable CI hook that keeps the
registry well-formed.

### The doc contract is one file, human + machine

What docs the repo carries — and what each one is for — lives in one file,
`spec/doc-spec.md`. It is both the human-readable map and the machine source of
truth: a single 3-column Markdown table (`Doc · Purpose · Requirement`) the CI
validator and the doc-release skill both parse directly. The table IS the
source — no fenced registry, no generated view, no second list to keep in sync.
Human docs carry no internal work-item IDs; that rule is a hard CI lint, not a
guideline. See [spec/doc-spec.md](../spec/doc-spec.md) for the contract itself
and [architecture.md](architecture.md) for how it is enforced and self-healed.

### Two tiers, one portable pass: general by default, custom per repo

The doc contract sorts every registered doc into one of two tiers, and one
portable skill keeps both current in *any* repo — not just this workbench.

> **A general tier ships to every repo by default and is required in every
> adopting repo; a custom tier is whatever a repo adds on top. One portable
> doc-release pass keeps both current anywhere, and the machine registry is the
> CI gate that proves it.**

- **General tier (`section: common`) — required in every adopting repo.** The
  doc set every repo gets by default and must carry: the one canonical seed the
  doc-release skill self-bootstraps declares all of it, and the stub-scaffold
  pass creates any general doc that is missing. It is "general by default" AND
  required: a fresh repo with no doc contract is stubbed up to the full general
  set, not left empty, and a registry that omits a general doc is surfaced
  (advisorily) on the next doc-release pass.
- **Custom tier (`section: custom`) — per-repo.** Whatever a particular repo
  adds beyond the general set — its own root convention docs, its own
  architecture notes. Declared and carried only by the repo that wants them,
  never required anywhere else. The general tier is shared and required
  everywhere; the custom tier is the repo's own.
- **One portable pass.** `/CJ_document-release` is written to run in any repo, not
  only this one: it reads the registry, self-heals a missing contract from the
  seed, and audits the docs against their declared requirements. When a repo has
  no skill catalog it degrades cleanly to the portable half rather than failing.
- **The machine registry is the CI gate.** The same `doc-spec.md` a human reads is
  the registry a CI hook validates — `doc-spec.sh --validate` is the portable
  schema check a consumer repo can wire in. The registry is the contract; the
  prose explains it.

This is the sibling of *the doc contract is one file*: that principle says the map
and the gate are one file; this one says that one file describes two tiers and a
single portable skill maintains them anywhere. See
[architecture.md](architecture.md) for the portable-CI-hook recipe and its honest
boundary (the schema check travels; the declared⇔on-disk loop is workbench-local).

### Trustworthy by construction, not by convention

A doc you can't trust is worse than no doc — a stale map sends its reader,
human or agent, confidently to the wrong place. The first two principles say
where the contract lives and what it covers; this one says why you can believe
it: every property that makes the docs trustworthy is *enforced by machinery*,
never promised by convention.

- **Generated, never hand-maintained.** Anything that would be a second copy is
  derived from its one source — the readable doc views from the registry, the
  README from the skill catalog — and a CI drift check fails if a derived view
  is edited by hand. A list that cannot be hand-edited cannot quietly rot.
- **Declared matches on-disk, both ways.** Every declared doc must exist and
  every doc on disk must be declared — no ghosts, no orphans — and the registry
  itself is schema-validated. The portable seed the doc-release pass bootstraps
  from is kept byte-identical across its copies by a drift test, so "the same
  contract everywhere" is checked, not assumed.
- **Hard floor, self-healing above it.** Cleanliness is a hard CI lint — a human
  doc carrying an internal work-item ID fails outright, and a required front
  table is gated the same way — while recovery is automatic: a missing contract
  is bootstrapped from the seed, a missing declared doc is stub-scaffolded, and
  every registered doc is advisorily audited against its declared requirement,
  including whether the general tier is fully present.

The division of labor is deliberate: what a machine can decide (existence,
drift, schema, IDs) is a hard gate; the judgment call — "does this doc still
satisfy its requirement?" — is a recurring advisory audit rather than a false
green. Convention gets you a doc set; machinery gets you a doc set you can
trust.

## Topic: Shipping discipline — earn the merge

The Harness topic is how the loop *behaves*; the CI/CD topic is the *layers* a
change passes through. This topic is the discipline that carries a change *across*
those layers honestly — the standard the build-to-land lifecycle holds itself to
when a green local run tempts you to ship early. The model, and the operator
driving it, are optimists; these principles are how the work stays trustworthy
when the optimism is wrong.

### 1. Reproduce the real gate — a partial pass is not a pass

The gate that decides the merge is the one that runs on the PR, not the fastest
check you happened to run. Reproduce it *exactly* and *to completion* before you
push; a standalone drill that skips the slow path proves the drill, not the code.
*In the workbench:* the PR job runs `validate.sh`, the full `test.sh` suite, and
`shellcheck` (which fails on *any* finding, even an info-level one), so a bug that
a fast fixture skips — a `grep -c || echo 0` that double-counts, a backtick inside
a single-quoted format that trips `SC2016` — only surfaces when you run all three
locally first, instead of after CI has rejected the push twice.

### 2. Adversarially verify your own work — a green happy path proves the demo

Independent skepticism catches what the author cannot. Spawn a fresh-context
reviewer whose job is to *break* the change, then re-verify each finding
adversarially so only real defects survive. *In the workbench:* before a build's
PR opens, a review fans out over the diff and every finding is re-checked by a
second agent trying to refute it, catching latent defects — an unanchored match
that silently false-passes, a seed step that never refreshes a stale index — that
every happy-path check had waved through.

### 3. Findings are the product — report every gap, never crash

A verifier that dies on the first problem hides the rest and reads as a bug; one
that reports every gap and still exits clean lets you fix the whole set in one
pass and can never be mistaken for a false green. *In the workbench:* the audits
and structural checks emit a `FINDING:` line per gap and exit 0 regardless — a
broken contract *is* the report, not a stack trace, and a missing piece is a named
line the operator can act on.

### 4. Land additively — stage the risky half for its own increment

A change that coexists with what exists and keeps every gate green is safer than a
big-bang replacement that turns them all red at once. Ship the foundation
additively and defer the destructive step — moving files, removing the old
grammar, re-expressing the gates — to its own reviewed increment. *In the
workbench:* a new contract axis is added *beside* the old one, existing checks
unchanged and no files relocated, so the foundation lands green while the
migration waits for a later, separately reviewed run.

### 5. Fix before you land — a red gate is a stop, not a suggestion

When review or CI surfaces a defect, fix it, re-verify against the *same* gate,
and only then merge; never ship on red, and never let a convenience flag decide
the merge for you. *In the workbench:* the merge convention confirms the PR reads
`MERGED` before any branch cleanup and refuses `gh pr merge --auto` (which exits 0
even when the merge failed), so a CI failure routes back to fix-and-re-verify
rather than sliding through on a misread exit code.

These five are the discipline behind the CI/CD layers: the layers are *where* a
change is checked; this is *how* you carry it across them without lying to
yourself. A build is not done when it runs — it is done when it survives the gate
it will actually be judged by.

## Decision tree: which CJ_ skill do I call?

The Deployment topic is about *how the workbench is built*. This is the routing
map for *using* it. Every `CJ_` front door converges on the same downstream chain
(`/ship` -> `/land-and-deploy`); pick by what you have in hand.

| Your input | Front door |
|---|---|
| One-line feature topic -> reviewable PR | `/CJ_goal_feature "<topic>"` |
| Small ad-hoc task (no design, no bug) -> reviewable PR | `/CJ_goal_task "<small task>"` |
| Bug description -> shipped fix | `/CJ_goal_defect "<bug>"` |
| Drain shippable `TODOS.md` rows | `/CJ_goal_todo_fix [<id> \| "<frag>"]` |
| "What should I work on?" | `/CJ_suggest` |
| "Is my `~/.claude/` healthy?" | `/CJ_system-health` |
| "Are my skills' `portability` labels honest?" | `/CJ_portability-audit` |
| "Do this repo's docs follow its doc contract?" | `/CJ_doc_audit` |
| "Are this repo's tests aligned with its test contract?" | `/CJ_test_audit` |
| "Do this repo's tests pass?" (run them, not just audit wiring) | `/CJ_test_run` |
| Triage a Claude best-practice URL | `/CJ_improve-queue evaluate <url>` |

Internal phase-step skills are dispatched transitively by the orchestrators — do
not route to them directly: `/CJ_scaffold-work-item`, `/CJ_implement-from-spec`,
`/CJ_qa-work-item`, `/CJ_document-release`, `/CJ_personal-workflow`. The
[workflow.md](workflow.md) index links the full per-skill roster + the
per-workflow ASCII charts, which live one level down under `docs/workflows/`.
