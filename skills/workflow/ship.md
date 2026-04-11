# ship — Phase 4: Ship

Subcommand of /workflow. Validates TEST-SPEC acceptance criteria, runs contract
quality gates, then delegates to gstack /ship.

Shared context (branch, work item, phase) is already resolved by SKILL.md.

## Step 1: Load context

1. Read tracker: name, type, status, current phase
2. Read TEST-SPEC.md if it exists (for acceptance criteria validation)

## Step 2: Validate TEST-SPEC acceptance criteria

If TEST-SPEC.md exists:
- Read the Test Matrix section
- For each P0 test case:
  - Run Tier 1 smoke test commands if Script/Command is specified
  - For Tier 2 (manual), list them for user to confirm
- **P0 failures block shipping.** Do not proceed.

If validation fails:
- Journal: `### {date} -- ship-blocked\nShip blocked. Failing: {list of failing test cases}`
- Handoff: `<!-- HANDOFF: phase=ship status=blocked reason=spec-validation -->`
- Tell user: "Ship blocked by failing acceptance criteria. Fix, then re-run `/workflow ship`."
- **Stop.** Do not proceed.

If no TEST-SPEC.md:
- Warn: "No TEST-SPEC.md found. Shipping without spec validation."
- Proceed.

## Step 3: Contract Quality Gate

Run both check and test via the /contracts skill.

### Check if contracts skill exists
```bash
CONTRACTS_FOUND="no"
for dir in "$(git rev-parse --show-toplevel 2>/dev/null)/skills/contracts" "$HOME/.claude/skills/contracts"; do
  [ -f "$dir/SKILL.md" ] && CONTRACTS_FOUND="yes" && break
done
[ "$CONTRACTS_FOUND" = "yes" ] && echo "CONTRACTS_AVAILABLE" || echo "CONTRACTS_MISSING"
```

### Failure mode A: Contracts skill missing
- Log: "WARN: /contracts skill not installed. Skipping doc quality gate.
  To enable: run `skills-deploy install` from your claude-skills-templates clone,
  or verify ~/.claude/skills/contracts/SKILL.md exists."
- Journal: `### {date} -- ship-gate\nContract gate skipped: skill not installed.`
- Proceed to Step 4.

### Failure mode B: Contract check/test finds failures
- Invoke /contracts check on the work item directory:
  ```
  Skill: contracts, args: "check {work_item_dir}"
  ```
- Invoke /contracts test:
  ```
  Skill: contracts, args: "test"
  ```
- If either returns FAIL findings:
  - Display failures to user
  - Ask via AskUserQuestion: "Contract gate found {N} failures. Override and ship anyway? [y/N]"
  - If override: journal `### {date} -- ship-gate\nContract gate: {N} failures overridden.`
  - If not override: journal `### {date} -- ship-gate\nContract gate: blocked.` and stop.
- If both pass: journal `### {date} -- ship-gate\nContract gate passed (check + test).`

## Step 4: Advisory sub-gate warnings

Read the tracker's Phase 4 (Ship) lifecycle checkboxes. Warn about unchecked items:
```
Advisory: These Ship sub-gates are not checked:
- [ ] Tests pass
- [ ] Code review completed
Continue anyway?
```

This is advisory only. The user can proceed regardless.

## Step 5: Journal entry

Write to tracker Journal:
```
### {date} -- ship
Entering ship phase. Spec validation: {passed/skipped/N-A}. Contract gate: {passed/skipped/overridden}.
```

## Step 6: Delegate to gstack /ship

Invoke gstack /ship using the Skill tool:
```
Skill: ship
```

The upstream skill handles PR creation, VERSION bump, CHANGELOG update,
commit, push, and PR submission.

## Step 7: Capture outcome

After /ship completes:
- Journal: `### {date} -- shipped\nPR created: {PR URL}. Status: {merged/open}.`
- Update PRs section in tracker with the PR link
- Mark Phase 4 sub-gates as complete in Lifecycle
- Handoff: `<!-- HANDOFF: phase=ship status=complete -->`
- Suggest: "Work item complete. Run `/workflow track close` to close it."

## Rules

- **Spec validation gates shipping.** P0 TEST-SPEC failures block. No exceptions.
- **Contract gate runs both check and test.** Two failure modes same as review.
- **Advisory sub-gate warnings.** Unchecked lifecycle items warn but do not block.
- **Always delegate to /ship.** The ship logic lives upstream in gstack.
- **Journal every ship attempt.** Pass or fail, the outcome goes in the tracker.
