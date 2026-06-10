---
type: test-plan
parent: T000046
title: "Add a document-integrity principle to docs/philosophy.md — Test Plan"
date: 2026-06-09
author: Charlie
status: Draft
---

<!-- Scope: ONE task. Cases must be concrete and reproducible. -->

## Scope

Add ONE new principle — **"Trustworthy by construction, not by convention"** —
under the EXISTING `## Topic: Doc contract` section of `docs/philosophy.md`.
The principle's distinct claim is document INTEGRITY: a doc you can't trust is
worse than no doc, so trust is enforced by machinery (generation over
hand-maintenance, byte-identical seed copies, declared-vs-on-disk gates,
lint-enforced cleanliness, self-healing + advisory audit) rather than promised
by convention. It must NOT duplicate the two existing doc-contract principles
("one file, human + machine"; "Two tiers, one portable pass"). The front
summary table gains a matching row in the same position order as the body
(third Doc-contract row), the `## Decision tree: which CJ_ skill do I call?`
heading stays LAST, and the doc remains a clean human-doc (no work-item IDs).
Only `docs/philosophy.md` changes (plus the work-item tracker + this test-plan).

## Regression Test Cases

| # | Test Case | Steps | Expected Result | Status |
|---|-----------|-------|-----------------|--------|
| 1 | New principle present in body | `grep -n '^### Trustworthy by construction, not by convention' docs/philosophy.md` | exactly one match, inside `## Topic: Doc contract` (no new `## Topic:` heading added) | Pending |
| 2 | Front-table row present, position matches body | inspect the summary table before the first `## ` heading | a third **Doc contract** row for the new principle, directly after the "Two tiers, one portable pass" row | Pending |
| 3 | Integrity machinery named | grep the new principle for: generated views / byte-identical seed / declared-vs-on-disk / hard lint / stub-scaffold / advisory audit | all five machinery classes covered (generation, seed drift test, declared⇔on-disk + schema, hard lints, self-healing + advisory audit) | Pending |
| 4 | No duplication of sibling principles | read the new principle vs the two existing doc-contract principles | distinct claim (integrity/trust-by-machinery); no restatement of "one file" or "two tiers" as its thesis | Pending |
| 5 | Decision tree still last | `grep -n '^## ' docs/philosophy.md \| tail -1` | last `## ` heading is `## Decision tree: which CJ_ skill do I call?` | Pending |
| 6 | No work-item IDs (human-doc) | `grep -nE '[FSTD][0-9]{6}' docs/philosophy.md` | zero matches (Check 19 hard lint) | Pending |
| 7 | validate.sh green | `./scripts/validate.sh` | exit 0, 0 errors (Checks 15/15a/15b/16/17/19/20/23 + New-skills) | Pending |

## Verification Steps

- [ ] `./scripts/validate.sh` passes (0 errors) — the philosophy.md human-doc lints (Check 19 no work-item IDs, Check 20 front-table) and the generated-view drift check (Check 23 — views untouched by this change) all green.
- [ ] `docs/philosophy.md` reads coherently: the new principle complements rather than duplicates the existing two doc-contract principles (where the contract lives / what it covers vs why you can trust it), matching the doc's prose style and principle length.
- [ ] Only `docs/philosophy.md` is changed by the implement step (plus the work-item tracker + this test-plan).

## Environments Tested

| Environment | Build | Result |
|------------|-------|--------|
| local macOS | current branch (off main 379df75 / v6.0.62) | Pending |
