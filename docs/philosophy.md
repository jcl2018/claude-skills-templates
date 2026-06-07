# Philosophy

Why this workbench is built the way it is, the runtime standard its agent loop is
held to, and how to choose which `CJ_` skill to call. This doc is arranged by
principle; for the machinery under the hood see
[architecture.md](architecture.md), and for the end-to-end workflows see
[workflow.md](workflow.md).

| # | Principle | In one line |
|---|-----------|-------------|
| 1 | One source of truth — this checkout | Install == clone; every repo references the single `~/.claude/` install, `git pull` is deploy. |
| 2 | Two delivery surfaces, one contract | The same doc-first work contract ships to Claude Code skills and a self-contained GitHub Copilot bundle. |
| 3 | The doc contract is one file, human + machine | `doc-spec.md` is both the human-readable doc map and the machine registry the CI validator + doc-release skill parse. |
| ★ | Five harness-engineering principles | The runtime standard the `cj_goal` agent loop is judged against: curate context · externalize state · stateless handoff · verify the path · permissions first-class. |
| — | Decision tree | Which `CJ_` skill to call for a given input — see the routing map at the bottom of this doc. |

## Principle 1: There is exactly one source of truth — this checkout

This workbench has one first principle. Everything else in its deployment design
is a consequence of it, not a separate decision.

> **There is exactly one source of truth — this git checkout. Installing it does
> not copy it; it references it. Every repo on the machine, and the workbench
> itself, run that one install.**

It has two halves: the **install model** (what `skills-deploy install` actually
does to your machine) and the **reference model** (how every other repo uses the
result). They are the same idea seen from the producer side and the consumer
side.

### The install model: install == clone

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

### The reference model: every repo references the one install

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

### Why this is the first principle

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

### Windows: the model holds, the mechanism changes

Git Bash on Windows cannot create real symlinks, so `skills-deploy install`
falls back to **copy-mode**: `~/.claude/skills/` gets real-file copies with
checksum drift tracking instead of symlinks. The *model* is unchanged — the
manifest still records `install_mode: in-place`, the reference model is the same,
behavior is the same. Only the link mechanism differs, and CI guards that the
in-place contract holds under copy-mode.

## Principle 2: Two delivery surfaces, one contract

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

## Principle 3: The doc contract is one file, human + machine

What docs the repo carries — and what each one is for — lives in one root file,
`doc-spec.md`. It is both the human-readable map and the machine source of truth
(a fenced `yaml` registry the CI validator and the doc-release skill both parse).
Human docs carry no internal work-item IDs; that rule is a hard CI lint, not a
guideline. See [doc-spec.md](../doc-spec.md) for the contract itself and
[architecture.md](architecture.md) for how it is enforced and self-healed.

## The runtime standard: five harness-engineering principles

Principles 1-3 are about how the workbench is *built and delivered*. This is a
second, orthogonal lens — how the `cj_goal` agent loop should *behave at
runtime*. They are five principles distilled from the agent-harness engineering
field (Anthropic, OpenAI, Google, LangChain, Arize, and the 2025-2026
harness-engineering literature). An agent is "an LLM using tools in a loop," and
the model is the least reliable component in that loop; these five are how the
*harness* stays bounded when the model is wrong. The prompt decides how it
speaks; the harness decides how it acts.

1. **Context is a finite resource — curate it.** The window is an attention
   budget with diminishing returns, and recall rots as it fills — a bigger window
   just fills with stale tool output as fast. Keep the smallest high-signal set
   live: compact, summarize, or offload as you go. *In the workbench:* the silent
   build dispatches scaffold → implement → QA as depth-≤2 leaf subagents that
   return ≤200-token summaries (detail goes to the tracker, not back through the
   tool result), so the orchestrator's own window stays lean.

2. **Externalize state to durable storage.** Don't hold important state only in
   the window — write it to the filesystem, the agent's real memory, as an index
   of pointers and decisions rather than a transcript. *In the workbench:* the
   per-branch resume state file, the committed work-item tracker + its journal,
   the SPEC/DESIGN/TEST-SPEC triplet, and the per-run telemetry JSONL all live on
   disk; if a session dies, the work survives.

3. **Design for stateless handoff.** Assume the next turn, session, or agent
   remembers nothing; make resumption a *read*, not a recollection — the unit of
   work ends by writing exactly what the next one needs. *In the workbench:* a
   re-invocation resumes from the state file with validate-before-skip (the
   recorded phase SHA must be an ancestor of HEAD, any recorded PR must still read
   OPEN, the recorded design doc must still read `APPROVED`), and each leaf
   subagent hands back a one-line RESULT, never its working context.

4. **Verification is a continuous gate — judge the path.** A quality gate at
   every step, not only the end; evaluate the trajectory (what the agent actually
   did), not just the final artifact, and keep the verifier independent of the
   doer. *In the workbench:* `/CJ_personal-workflow check` runs at every phase
   boundary, QA executes the work-item's test rows rather than merely checking a
   TEST-SPEC exists, and a pre-ship portability gate halts the run before a PR is
   ever opened.

5. **Tools & permissions are first-class.** Spec tools like prompts; consolidate
   fiddly multi-call flows into one high-level tool; return high-signal fields.
   Permission is explicit — *design permission before capability*, and give the
   riskiest verbs (push, merge, `rm`, network) the strictest rules. *In the
   workbench:* every skill declares `allowed-tools`, feature runs stop at a
   human-reviewed PR with no automatic merge, and `cj-handoff-gate.sh`'s denylist
   blocks auto-deploy of exactly the skill surfaces a change touches.

The first three are the framework's strongest habits — externalized state and
stateless handoff are designed in from the ground up, and they are the two
hardest to retrofit later. Verification and context curation are strong *between*
phases and still maturing *within* a long phase; a single explicit, declared
permission policy (rather than today's rules spread across frontmatter,
leaf-skill code, and an external denylist) is the principle with the most
headroom. The decision tree below is how you *use* the framework; these five are
the standard it holds itself to.

## Decision tree: which CJ_ skill do I call?

Principles 1-3 are about *how the workbench is built*. This is the routing map
for *using* it. Every `CJ_` front door converges on the same downstream chain
(`/ship` -> `/land-and-deploy`); pick by what you have in hand.

| Your input | Front door |
|---|---|
| One-line feature topic -> reviewable PR | `/CJ_goal_feature "<topic>"` |
| Bug description -> shipped fix | `/CJ_goal_defect "<bug>"` |
| Drain shippable `TODOS.md` rows | `/CJ_goal_todo_fix [<id> \| "<frag>"]` |
| "What should I work on?" | `/CJ_suggest` |
| "Is my `~/.claude/` healthy?" | `/CJ_system-health` |
| "Are my skills' `portability` labels honest?" | `/CJ_portability-audit` |
| Triage a Claude best-practice URL | `/CJ_improve-queue evaluate <url>` |

Internal phase-step skills are dispatched transitively by the orchestrators — do
not route to them directly: `/CJ_scaffold-work-item`, `/CJ_implement-from-spec`,
`/CJ_qa-work-item`, `/CJ_document-release`, `/CJ_personal-workflow`. The full
per-skill roster + ASCII workflow charts live in [workflow.md](workflow.md).
