---
parent: F000001_reading_list_cli
---

<!-- This file is the SINGLE SOURCE OF TRUTH. Edit milestones here. -->

## Milestones

| # | Milestone | Target | Status | Notes |
|---|-----------|--------|--------|-------|
| 1 | Core CRUD (add, list, update, remove) | 2026-03-15 | In Progress | S000001 covers this |
| 2 | Search and filtering | 2026-03-22 | Planned | S000002, depends on M1 |
| 3 | Distribution (go install + GitHub Release) | 2026-03-29 | Planned | CI/CD pipeline needed |
| 4 | README + docs | 2026-03-31 | Planned | Installation, usage, examples |

## Dependencies

```
M1 (Core CRUD) ──→ M2 (Search)
                 ──→ M3 (Distribution)
                 ──→ M4 (Docs)
```

M1 is the only blocker. M2, M3, M4 can run in parallel after M1 ships.
