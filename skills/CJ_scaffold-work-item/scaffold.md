# /CJ_scaffold-work-item — Work Item Scaffolding

Scaffold a CJ_personal-workflow work item from an `/office-hours` design doc. The
templates in `templates/CJ_personal-workflow/` and `personal-artifact-manifests.json`
are the **single source of truth** for required artifacts and structure.

This file is the step-by-step logic invoked from [SKILL.md](SKILL.md). Read SKILL.md
first for path resolution, error handling, and usage; then follow the steps below.

---

## Step 1: Validate Input

Parse the user's argument:

- The first positional argument is `<design-doc-path>`.
- If `--type {feature|user-story|task|defect}` is also supplied, capture it as the explicit type override.

Verify the design doc exists:

```bash
[ -f "$DESIGN_DOC_PATH" ] && echo "DESIGN_DOC_FOUND" || echo "DESIGN_DOC_MISSING"
```

If `DESIGN_DOC_MISSING`: print "Error: design doc not found at {path}" and stop.

## Step 2: Read the Design Doc

Read the design doc and extract these fields:

- **Title:** the first `# Design: {title}` line. Strip the `Design: ` prefix to get the title.
- **Mode:** the `Mode:` line in the frontmatter block (Builder or Startup or other).
- **Branch:** the `Branch:` line.
- **Status:** the `Status:` line.
- **Problem Statement:** the `## Problem Statement` section content.
- **Recommended Approach:** the `## Recommended Approach` section content.
- **Open Questions:** the `## Open Questions` section content.
- **Eng-Review Revisions:** if present, the `## Eng-Review Revisions` section content (overrides body where they conflict).

Distill these into the variables `TITLE`, `MODE`, `SOURCE_BRANCH`, `SOURCE_STATUS`,
`PROBLEM`, `APPROACH`, `OPEN_QUESTIONS`, `ENG_REVIEW_DELTAS`.

If any required field is missing or unparseable, print:
"Error: could not extract title/mode/recommended-approach from {path}. Verify the design doc was produced by /office-hours."
And stop.

## Step 3: Determine Work-Item Type

Detection order:

1. **Explicit `--type` argument:** if provided, use it and skip to Step 4.
2. **Current git branch:** match the branch name against these patterns (case-insensitive):
   - `^(feature|feat)[-/]` → `feature`
   - `^story[-/]` → `user-story`
   - `^(task|chore)[-/]` → `task`
   - `^(defect|fix|bugfix)[-/]` → `defect`
3. **AskUserQuestion fallback:** if no match, ask:

   > Branch '{branch_name}' doesn't match a type pattern. Which work-item type should I scaffold?

   Options (per the design doc's `Mode: Builder` and recommended-approach phrasing — pick the most likely default):
   - feature (recommended if design doc has feature-shaped scope)
   - user-story
   - task
   - defect

   Use the user's answer.

If the user cancels: print "Aborted: type required to proceed." and stop.

## Step 4: Read Manifest and WORKFLOW.md

```bash
cat "$_PW_SKILL_DIR/personal-artifact-manifests.json"
```

Parse the JSON. Look up `types[$TYPE].required` to get the list of required artifacts:
each entry has `artifact`, `template`, `filename`. Store as `REQUIRED_ARTIFACTS`.

Read `$_PW_SKILL_DIR/WORKFLOW.md` for hierarchy + scaffolding rules. Pay attention to:

- Branch naming conventions (already used in Step 3).
- Required children (e.g., feature → at least 1 user-story child).
- Placement rules (`work-items/features/{component}/{ID}_{slug}/` etc).
- Slug rules: `[a-z0-9_-]+`, lowercase, no spaces or capitals.
- ID format: `{TYPE_PREFIX}{NNNNNN}` (F/S/T/D + 6 digits).

## Step 5: Generate ID

### Step 5.0: Idempotency pre-check (existing-ID detection)

Before generating a fresh ID, check whether this design doc has already been
scaffolded. Two probes (either match → reuse the existing ID and skip the
fresh-ID generation below):

**Probe A — read the design-doc footer.** Step 12 writes a footer of the form
`**Status: SCAFFOLDED → \`<path>\` on YYYY-MM-DD-HH-MM-SS**` to the source
design doc. If the footer is present and the captured `<path>` exists on disk,
extract the ID from the path's basename (e.g. `F000010_personal_workflow/` →
`F000010`).

```bash
EXISTING_ID=""
EXISTING_PATH=""
# Match the footer regex; capture the path between backticks (Step 12's form).
FOOTER_LINE=$(grep -E '^\*\*Status: SCAFFOLDED → ' "$DESIGN_DOC_PATH" | tail -1)
if [ -n "$FOOTER_LINE" ]; then
  EXISTING_PATH=$(printf '%s\n' "$FOOTER_LINE" | sed -E 's/^\*\*Status: SCAFFOLDED → `?([^`]+)`?( on .*)?$/\1/' | sed -E 's/\*\*$//')
  if [ -n "$EXISTING_PATH" ] && [ -d "$EXISTING_PATH" ]; then
    # Extract ID from the basename: ${PREFIX}NNNNNN_...
    EXISTING_ID=$(basename "$EXISTING_PATH" | sed -E "s/^(${PREFIX}[0-9]{6})_.*/\1/")
    # Sanity check: basename matches the expected prefix
    case "$EXISTING_ID" in
      ${PREFIX}[0-9][0-9][0-9][0-9][0-9][0-9]) ;;
      *) EXISTING_ID="" ;;  # path doesn't match expected shape; ignore
    esac
  fi
fi
```

**Probe B — grep tracker frontmatter for a reference to this design doc.**
Covers the case where Step 12's footer was hand-stripped or never written
(partial-write recovery). Search `work-items/*/TRACKER.md` files for a tracker
whose frontmatter or body references this design-doc path. Use the absolute
path to avoid cwd ambiguity.

```bash
if [ -z "$EXISTING_ID" ]; then
  _REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null)
  if [ -n "$_REPO_ROOT" ]; then
    # Recurse through any feature/child nesting depth.
    REF_TRACKER=$(find "$_REPO_ROOT/work-items" -name "*_TRACKER.md" 2>/dev/null \
      | xargs grep -l "$DESIGN_DOC_PATH" 2>/dev/null \
      | head -1)
    if [ -n "$REF_TRACKER" ]; then
      EXISTING_PATH=$(dirname "$REF_TRACKER")
      EXISTING_ID=$(basename "$REF_TRACKER" | sed -E "s/^(${PREFIX}[0-9]{6})_.*/\1/")
      case "$EXISTING_ID" in
        ${PREFIX}[0-9][0-9][0-9][0-9][0-9][0-9]) ;;
        *) EXISTING_ID="" ;;
      esac
    fi
  fi
fi
```

**On match (either probe):** set `NEW_ID=$EXISTING_ID`, set the target path to
`$EXISTING_PATH`, and skip the fresh-ID generation block below. Step 9's
boundary check will inspect the existing dir; if it's compliantly scaffolded,
the check returns PASS and the scaffold exits as a NO-OP (idempotent re-run).
If the existing dir has drift, Step 9 surfaces the violations via AskUserQuestion
as designed.

```bash
if [ -n "$EXISTING_ID" ]; then
  NEW_ID="$EXISTING_ID"
  TARGET_PATH="$EXISTING_PATH"
  echo "INFO: design doc already scaffolded → ${NEW_ID} at ${TARGET_PATH}. Reusing existing ID; Step 9 will handle idempotency."
  # Skip Step 5.1 (fresh-ID generation); jump to Step 6 (slug derivation still runs
  # for completeness, but Step 9's boundary check is the gate).
fi
```

### Step 5.1: Fresh-ID generation (only when 5.0 did not match)

Scan local work-items AND open PRs AND origin/main for the highest existing ID matching the type prefix. The three-source check prevents ID collisions when parallel worktrees scaffold from the same baseline (e.g. main at S000028 → both worktrees grab S000029) before either has merged, AND when origin/main has moved ahead of the local checkout since the last fetch (e.g. a sibling PR merged a new F-ID while this worktree was in flight).

```bash
# Source 1: local work-items
LOCAL_MAX=$(find work-items -name "${PREFIX}*_TRACKER.md" 2>/dev/null \
  | sed "s|.*/${PREFIX}\([0-9]*\)_.*|\1|" \
  | sort -un | tail -1)
LOCAL_MAX=${LOCAL_MAX:-0}

# Source 2: open PRs (queue-collision detection — added 2026-05-10).
# Skip silently if gh is offline/unauthenticated or `gh pr list` fails.
# Cap at 5 open PRs to keep the call cheap (~2-5s total). Limitation: only
# catches collisions where the parallel worktree has ALREADY pushed and opened
# a PR. Two worktrees both scaffolding without push still collide; the
# post-push /land-and-deploy Step 3.4 VERSION drift check is the safety net
# for that case.
PR_MAX=0
if command -v gh >/dev/null 2>&1 && gh auth status >/dev/null 2>&1; then
  for PR_NUM in $(gh pr list --state open --base main --limit 5 --json number -q '.[].number' 2>/dev/null); do
    while IFS= read -r CLAIMED; do
      case "$CLAIMED" in
        ''|*[!0-9]*) continue ;;
      esac
      [ "$CLAIMED" -gt "$PR_MAX" ] && PR_MAX="$CLAIMED"
    done < <(
      gh pr view "$PR_NUM" --json files -q '.files[].path' 2>/dev/null \
        | grep -oE "${PREFIX}[0-9]{6}(_[^/]*)?_TRACKER\.md$" \
        | sed "s|^${PREFIX}\([0-9]*\)_.*|\1|"
    )
  done
fi

# Source 3: origin/main post-fetch (origin-drift detection — added 2026-05-16).
# Why: when origin/main has moved ahead since the local checkout (e.g. a sibling
# PR merged a new ${PREFIX}-ID while this worktree was in flight), Sources 1+2
# miss it — Source 1 only sees the lagging local tree; Source 2 only sees OPEN
# PRs, not merged ones. Fetch quietly and skip silently if offline / no remote /
# no origin/main; the existing LOCAL+PR sources remain the floor.
git fetch origin main --quiet 2>/dev/null || true
ORIGIN_MAX=$(git ls-tree -r --name-only origin/main work-items/ 2>/dev/null \
  | grep -oE "${PREFIX}[0-9]{6}(_[^/]*)?_TRACKER\.md$" \
  | sed "s|^${PREFIX}\([0-9]*\)_.*|\1|" \
  | sort -un | tail -1)
ORIGIN_MAX=${ORIGIN_MAX:-0}

HIGHEST=$LOCAL_MAX
[ "$PR_MAX" -gt "$HIGHEST" ] 2>/dev/null && HIGHEST=$PR_MAX
[ "$((10#$ORIGIN_MAX))" -gt "$((10#$HIGHEST))" ] 2>/dev/null && HIGHEST=$ORIGIN_MAX
# Force base-10 in arithmetic context: bash interprets leading-zero strings
# like "000029" as octal, which fails on digits 8/9. The 10# prefix is
# bash-specific but zsh tolerates it (with OCTAL_ZEROES unset, the default).

# Source 4: atomic claim dir (F000048 — closes the pre-push race the Source-2
# comment above flags as uncovered). Sources 1-3 are point-in-time and CANNOT
# see a sibling worktree that has not yet pushed/opened a PR, so two parallel
# worktrees scaffolding from the same baseline both compute the same HIGHEST and
# both mint HIGHEST+1. cj-id-claim.sh adds a 4th source on top: an atomic `mkdir`
# CAS in the SHARED `.git` common-dir (instantly visible to every sibling
# worktree). It claims strictly above max($HIGHEST, any live claim), so
# concurrent *worktrees* (distinct branches → pure mint) always get distinct IDs;
# same-branch reuse is best-effort (at most one re-run reuses a given pending
# claim). Two deliberately-different git-dir
# queries: the script is located via `--show-toplevel` (the CALLER's own
# worktree's scripts/), while cj-id-claim.sh resolves the claim dir under
# `--git-common-dir` (the SHARED .git) — that split is what makes the lock
# cross-worktree. Fail-soft: if the helper is absent/non-executable or returns
# nothing, fall back to the existing 3-source printf so scaffold never breaks
# (deploys without the helper degrade cleanly to point-in-time IDs).
NEW_ID=""
_CLAIM="$(git rev-parse --show-toplevel)/scripts/cj-id-claim.sh"
if [ -x "$_CLAIM" ]; then
  NEW_ID=$("$_CLAIM" --prefix "$PREFIX" --floor "$HIGHEST" | sed -n 's/^CLAIMED_ID=//p')
fi
[ -n "$NEW_ID" ] || NEW_ID=$(printf "${PREFIX}%06d" $((10#$HIGHEST + 1)))
```

Where `PREFIX` is `F` for feature, `S` for user-story, `T` for task, `D` for defect. The PR-claim and origin/main checks apply to all four prefixes uniformly: any open PR adding a `${PREFIX}NNNNNN_*_TRACKER.md` file, OR any such file already present on `origin/main`, counts as claiming that ID. Source 4 (the atomic claim dir) adds the only continuously-atomic source — it is the cross-worktree lock that the point-in-time Sources 1-3 cannot provide; Sources 2+3 remain the cross-clone backstop post-push.

Result: `NEW_ID` (e.g., `F000010`), guaranteed not to collide with local state, any open PR's claimed IDs, origin/main's latest state, OR a concurrent same-machine sibling worktree's atomic claim.

## Step 6: Determine Slug

The slug derives from the design doc's title:

1. Lowercase the title.
2. Replace spaces and `—` with `_`.
3. Strip non-alphanumeric chars except `_-`.
4. Collapse runs of `_` to a single `_`.
5. Trim leading/trailing `_-`.

Example: "Personal-workflow pipeline skills" → `personal-workflow_pipeline_skills`.

If the slug is awkward or > 40 chars, AskUserQuestion to refine:

> Slug derived from title: '{slug}'. Use as-is, edit, or override?

Capture as `SLUG`.

## Step 7: Determine Component (Grouping Folder)

Existing convention: features and defects nest under a component subfolder
(`features/CJ_personal-workflow/`, `features/CJ_system-health/`, etc).

Scan existing components:

```bash
find work-items/${TYPE}s -mindepth 1 -maxdepth 1 -type d 2>/dev/null \
  | sed 's|.*/||' | sort -u
```

If components exist, AskUserQuestion:

> Which component does this work item belong to?
>
> Options:
> - {existing-component-1} (recommended if slug is component-related)
> - {existing-component-2}
> - ...
> - + new component (specify)

If the user picks an existing component, use it. If "+ new", ask for the new component name (slug rules apply).

Capture as `COMPONENT`.

If no components exist yet (e.g., empty `work-items/features/`): default to the slug or AskUserQuestion to provide one explicitly.

## Step 8: Plan Tree

Compute the target path:

- **Feature:** `work-items/features/{COMPONENT}/{NEW_ID}_{SLUG}/`
- **User-story (standalone scaffold):** error — user-stories must nest under a feature. Tell the user: "user-stories must be scaffolded as children of a feature; pass the feature dir to scaffold child stories." (or, if the design doc explicitly references a parent feature, use that path).
- **Task (standalone scaffold):** same constraint as user-story but under a feature/user-story.
- **Defect:** `work-items/defects/{COMPONENT}/{NEW_ID}_{SLUG}/`

For features, decide the user-story children:

1. Parse the design doc's `## Recommended Approach` section.
2. Extract listed alternatives or sub-components (e.g., "Skill 1: /CJ_scaffold-work-item", "Skill 2: ...").
3. For each, derive a candidate slug (Step 6's logic).
4. AskUserQuestion to confirm:

   > Proposed user-story children for {NEW_ID}:
   > - {S_ID_1}_{slug_1}
   > - {S_ID_2}_{slug_2}
   > - {S_ID_3}_{slug_3}
   >
   > Confirm or override?

   Options:
   - Confirm all (recommended)
   - Edit slugs (interactive)
   - Skip user-story children (scaffold feature only; user adds stories later)

5. Capture user-story IDs by incrementing from the highest existing S-prefix.

Store `TARGET_PATH`, `CHILDREN_LIST`.

## Step 9: Boundary Check at Start (Premise 1.3) + Idempotency

If `TARGET_PATH` already exists:

1. Run `/CJ_personal-workflow check {TARGET_PATH}` and capture the result.
2. **If check returns PASS:** the work item is already scaffolded compliantly.
   Print: "INFO: {NEW_ID} already scaffolded at {TARGET_PATH}; nothing to do."
   Exit 0 (idempotent NO-OP).
3. **If check returns DRIFT/MISSING violations:** the existing dir is partially scaffolded or stale.
   AskUserQuestion:

   > {NEW_ID} exists at {TARGET_PATH} but has structural issues:
   >   {summary of violations}
   >
   > Options:
   > - Refuse and abort (recommended — manual repair is safer)
   > - Refresh missing artifacts only (write only the missing files; don't overwrite existing)
   > - Overwrite (rewrite all artifacts from scratch — DESTRUCTIVE, lose any manual edits)

   Default: refuse and abort. Only proceed if user explicitly chooses refresh or overwrite.

If `TARGET_PATH` does not exist: continue to Step 10.

## Step 10: Write the Directory Tree

For features:

```bash
mkdir -p "{TARGET_PATH}"
```

For each child user-story (if any):

```bash
mkdir -p "{TARGET_PATH}/{S_ID}_{child-slug}"
```

For each required artifact in `REQUIRED_ARTIFACTS` (from the manifest):

1. Resolve the template via the 2-level fallback chain (`$_TMPL_DIR/{template}` then `~/.claude/templates/CJ_personal-workflow/{template}`).
2. Read the template.
3. Fill placeholders:

   | Placeholder | Value |
   |---|---|
   | `{ITEM_NAME}` (or `{FEATURE_NAME}`, `{STORY_NAME}`) | From `TITLE` (feature) or child slug-as-title (user-story) |
   | `{ITEM_ID}` (or `{FEATURE_ID}`, `{STORY_ID}`, etc.) | `NEW_ID` or child ID |
   | `{PARENT_ID}` | For children: parent's `NEW_ID`. For features: leave blank (`""`). |
   | `{FEATURE_ID}` | Top-level feature ID (for nested SPEC/TEST-SPEC frontmatter) |
   | `{YYYY-MM-DD}` | Today's date in `YYYY-MM-DD` format |
   | `{REPO_PATH}` | `$(git rev-parse --show-toplevel)` |
   | `{BRANCH_NAME}` | `$(git branch --show-current)` |
   | `{author}` | `$(whoami)` |
   | `{slug}` | `SLUG` |

4. Distill content from the design doc into the artifact:

   - **TRACKER.md:** populate `## Acceptance Criteria` from the design's Success Criteria. Populate `## Todos` with implementation tasks. Populate `## Log` with one entry: "{date}: Created. {brief description from design title}". Populate `## Insights` with key insights from design's "What I noticed" or "What Makes This Cool" section. Populate `## Journal` with `[decision]` entries for each Eng-Review revision (if present).
   - **DESIGN.md (feature):** populate `## Problem` from design's Problem Statement. Populate `## Shape of the solution` from design's Recommended Approach + decomposition table linking to children. Populate `## Big decisions` from design's Premises + Eng-Review Revisions. Populate `## Risks & open questions` from design's Open Questions. Populate `## Definition of done` from design's Success Criteria. Populate `## Not in scope` from eng-review's NOT-in-scope section if present.
   - **DESIGN.md (user-story):** keep all 7 `##` sections from doc-DESIGN.md (Problem, Shape of the solution, Big decisions, Risks & open questions, Definition of done, Not in scope, Pointers). The tracker-user-story.md template comment says DESIGN.md "may be a brief stub" — that refers to CONTENT brevity (1-2 sentences per section is fine for atomic stories), NOT structural omission. **Do not omit sections.** Section completeness is enforced by `/CJ_personal-workflow check` Step 16; missing sections produce `[DRIFT]` findings and the boundary check at end (Step 11) fails. Each section gets at least a brief sentence, even if it's just "See parent F000010_DESIGN.md for context."
   - **ROADMAP.md (feature only):** populate `## Scope`, `## Non-Goals`, `## Success Criteria` from the design. Populate `## Decomposition` with the user-story children table. Populate `## Delivery Timeline` with one row per child ("Ship S0000XX") + one row for "End-to-end pipeline run." Populate `## Dependency Graph` ASCII diagram.
   - **SPEC.md (user-story only):** populate `## Problem Statement`, `## Mental Model`, `## Requirements` (P0 from design's specific user-story scope), `## Acceptance Criteria` (Given/When/Then format, one block per P0 requirement), `## Architecture` (ASCII diagram + components), `## Tradeoffs`, `## Open Questions`.
   - **TEST-SPEC.md (user-story only):** populate `## Smoke Tests` (one row per testable smoke check), `## E2E Tests` (one row per user-visible scenario), `## Coverage Gaps`. AC column maps each row to a SPEC `#` story number.

5. Write the file via the Write tool to `{TARGET_PATH}/{NEW_ID}_{filename}` (or for children, `{TARGET_PATH}/{S_ID}_{child-slug}/{S_ID}_{filename}`).

**Slug-to-filename rule:** filename is `{ID}_{filename}` per the manifest's `filename` field. Strip directory parts.

## Step 11: Boundary Check at End (Premise 1.3)

Run `/CJ_personal-workflow check {TARGET_PATH}` (Directory Mode).

Per check.md Steps 8-13: validates artifact completeness against the manifest, frontmatter against templates, sections against templates, lifecycle phases, and checkbox counts.

For features with user-story children: run check on each child dir as well, OR run check on the parent's parent (work-items/) for full Tier 2 coverage.

**If check returns PASS:** proceed to Step 12.

**If check returns violations (DRIFT, MISSING, etc.):**

```
AskUserQuestion:
> The scaffolded directory failed /CJ_personal-workflow check:
>   {summary of violations}
> 
> Options:
> - Surface violations and exit (recommended — review manually before proceeding)
> - Auto-fix common drifts (e.g., missing Open Questions section: insert template stub)
> - Ignore and proceed (NOT RECOMMENDED)
```

Default: surface and exit. Recovery is up to the user.

## Step 12: Append SCAFFOLDED Footer to Source Design Doc (P1)

Open the source design doc (`<design-doc-path>`) and append a small footer at the end:

```markdown

---

**Status: SCAFFOLDED → `{TARGET_PATH}` on {YYYY-MM-DD-HH-MM-SS}**
```

If the design doc already has this footer (idempotency), update the timestamp and path
in place rather than appending a duplicate.

## Step 13: Print Path and Exit

Print a summary in the chat:

```
SCAFFOLD COMPLETE: {NEW_ID} at {TARGET_PATH}

Artifacts written:
  - {TARGET_PATH}/{NEW_ID}_TRACKER.md
  - {TARGET_PATH}/{NEW_ID}_DESIGN.md
  - {TARGET_PATH}/{NEW_ID}_ROADMAP.md  (feature only)
  - (children, if any: list each child dir)

Boundary check: PASS

Next:
  /CJ_implement-from-spec {first-child-or-the-dir-itself}
```

The last line of output is the directory path (or first child dir for multi-story features), formatted for copy-paste into the next skill invocation.

---

## Error Handling

See [SKILL.md](SKILL.md)'s Error Handling table. All errors are non-recoverable
(skill exits cleanly); the user re-runs after fixing the underlying issue.

## Idempotency Contract (Premise 1.1)

This skill is idempotent. Three behaviors:

1. **Already scaffolded compliantly** (Step 9 boundary check passes on existing target): NO-OP, exit clean.
2. **Already scaffolded with drift** (Step 9 boundary check finds violations): refuse to proceed by default; AskUserQuestion to refresh/overwrite.
3. **Partial-write recovery** (skill aborted mid-Step-10): re-run resumes from Step 9, sees partial state, AskUserQuestion to refresh missing artifacts.

No automatic rollback on failure. Tracker journal records the abort if a tracker
exists; otherwise filesystem state is the truth.

## Boundary Validation Contract (Premise 1.3)

`/CJ_personal-workflow check` runs at:

- **Step 9 (start):** on existing `TARGET_PATH` if present — gates input drift, detects idempotency.
- **Step 11 (end):** on the freshly written `TARGET_PATH` — gates output compliance.

Both invocations use Directory Mode. For multi-story features, run check on each child after writing the child.

## Subagent Use (Deferred to v2)

The design's optional "validator subagent" is NOT used in v1. The Step 11 boundary
check via `/CJ_personal-workflow check` covers the same need (detect structural drift)
without spawning an Agent tool call. Reconsider in v2 if /CJ_personal-workflow check
proves insufficient.
