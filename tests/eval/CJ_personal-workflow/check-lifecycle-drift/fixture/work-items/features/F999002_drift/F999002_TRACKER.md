---
name: "Lifecycle Drift Feature"
type: feature
id: "F999002"
status: active
created: "2026-05-09"
updated: "2026-05-09"
repo: "/Users/eval/test"
branch: "test/eval-fixture"
blocked_by: ""
---

<!-- Fixture: all three Phase headers are present, but each phase has FEWER
     gate rows than the template requires. The validator's lifecycle check
     should flag below_minimum=true while not flagging any missing_phases. -->

## Lifecycle

### Phase 1: Track

1. Plan stuff

**Gates:**
- [ ] /office-hours design produced (in `~/.gstack/projects/`)
- [ ] Working branch created (`branch` field populated)

### Phase 2: Implement

1. Build stuff

**Gates:**
- [ ] Implementation done

### Phase 3: Ship

1. Ship stuff

**Gates:**
- [ ] /ship done
- [ ] /land-and-deploy done

## Acceptance Criteria

- [ ] Feature works

## Todos

- [ ] Build it

## Log

## PRs

## Files

## Insights

## Journal
