---
type: architecture
parent: S999001
feature: F999001
title: "Uncovered AC Fixture — Architecture"
version: 1
status: Draft
date: 2026-05-11
author: chjiang
prd: PRD.md
reviewers: []
---

## Overview

Fixture-level architecture for the uncovered-AC scenario. The fixture
demonstrates the shape `/wc-qa` walks: a user-story with PRD-declared ACs
where one (AC-3) has no corresponding TEST-SPEC row.

## Architecture

```
+----------------+
| Entry point    |  AC-1
+--------+-------+
         |
         v
+--------+--------+
| Input handler  |   AC-2
+--------+--------+
         |
         v
+--------+--------+
| CSV exporter   |   AC-3 (uncovered by TEST-SPEC)
+----------------+
```

### Components Affected

| Component | Repo | Change Type | Description |
|-----------|------|------------|-------------|
| `entry.ts` | test-repo | New | Mounts the feature |
| `input-handler.ts` | test-repo | New | Validates and accepts input |
| `csv-exporter.ts` | test-repo | New | Exports data as CSV |
