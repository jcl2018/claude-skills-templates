---
type: roadmap
parent: F000001
title: "Reading List CLI — Roadmap"
date: 2026-03-01
author: chjiang
status: Draft
---

<!-- Example ROADMAP: merged content from the prior example-doc-feature-summary.md
     + example-doc-milestones.md. Demonstrates the v3 shape (Scope, Non-Goals,
     Success Criteria, Decomposition, Delivery Timeline with Delivery History,
     Dependency Graph, Open Questions). -->

<!-- ===== From example-doc-feature-summary.md ===== -->

## Scope

Per-tenant API rate limiting that prevents abuse and enforces fair resource allocation across pricing tiers (free, pro, enterprise). Implemented as middleware in the API gateway using a sliding-window algorithm backed by a Redis cluster. Adds `X-RateLimit-*` response headers on every API call and returns `429 Too Many Requests` with a `Retry-After` value when a tenant exceeds their limit. The feature spans gateway middleware, Redis state, response headers, admin observability, and per-tier configuration. The detailed PRD, architecture decisions, and test specification live at the user-story level — this doc is the feature's identity at the roll-up.

## Success Criteria

- [x] Free tenants are throttled at 100 req/min sliding window; pro at 1000/min; enterprise at 10000/min — verifiable from production metrics
- [x] All API responses include `X-RateLimit-Limit`, `X-RateLimit-Remaining`, `X-RateLimit-Reset` headers
- [ ] 429 responses include a `Retry-After` header that matches the sliding-window expiry
- [ ] Admin dashboard surfaces per-tenant rate-limit usage and throttled-request counts within 60 seconds of a throttle event
- [ ] Middleware overhead stays under 5ms p99 at 5000 concurrent users (load-test gate)
- [ ] No false-throttle incidents reported in the 30 days after launch

## Constituent User-Stories

- [S000412 — Sliding-window middleware](S000412-sliding-window-middleware/S000412_TRACKER.md)
- [S000413 — Per-tier limit configuration](S000413-per-tier-limit-config/S000413_TRACKER.md)
- [S000414 — Rate-limit response headers](S000414-rate-limit-headers/S000414_TRACKER.md)
- [S000415 — Admin dashboard rate-limit widgets](S000415-admin-rate-limit-widgets/S000415_TRACKER.md)

## Out-of-Scope

- Cross-region rate-limit synchronization — single-region Redis is sufficient for current traffic; multi-region revisited when EU launch lands
- Per-endpoint rate limits (vs. per-tenant) — Phase 2 work; tracked separately as F000118
- Dynamic limit adjustment based on tenant behavior — out of scope; will be evaluated after baseline metrics from this feature accumulate
- IP-based throttling for unauthenticated traffic — covered by the WAF, not this feature

<!-- ===== From example-doc-milestones.md ===== -->

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
