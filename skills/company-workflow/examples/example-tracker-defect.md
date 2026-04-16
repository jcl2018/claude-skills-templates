---
name: "Rate limiter returns incorrect remaining count after Redis failover"
type: user-story
workflow_type: defect
id: "D000099"
status: active
created: "2026-03-08"
updated: "2026-03-11"
url: "https://jira.example.com/browse/PLAT-1058"
repo: "saas-platform"
branch: "fix/rate-limit-failover-count"
blocked_by: ""
---

## Lifecycle

### Phase 1: Track
- [x] Defect scoped (reproduction steps documented)
- [x] Working branch created (`branch` field populated)
- [x] Symptom documented in Log

### Phase 2: Implement
- [x] Root cause identified (RCA in Insights section)
- [x] Hypothesis tested with evidence (finding entries in Journal)
- [x] Fix committed (>=1 commit SHA in Log)
- [ ] Regression test added
- [x] Files section updated with all changed files

### Phase 3: Review
- [ ] Code review requested (reviewer noted)
- [ ] Review feedback captured (suggestions + resolutions in Journal)
- [ ] All review suggestions resolved or marked won't-fix

### Phase 4: Ship
- [ ] Linux branch build passes
- [ ] Regression tests pass
- [ ] Code review completed (reviewer noted in Journal)
- [ ] PR description generated
- [ ] PR created (PR link in PRs section)
- [ ] Merged to target branch

## Reproduction Steps

1. Set up Redis Sentinel with one primary and two replicas
2. Configure rate limiter to connect via Sentinel with `retryStrategy` enabled
3. Send 50 requests to any rate-limited endpoint (establishes counter state)
4. Trigger a Redis primary failover using `redis-cli DEBUG SLEEP 30` on the primary
5. Wait for Sentinel to promote a replica (typically 5-10 seconds)
6. Send another request to the same endpoint immediately after failover completes
7. Observe: X-RateLimit-Remaining header shows the full limit (e.g., 1000) instead of the correct remaining count (e.g., 950)

Environment: staging cluster, Redis 7.2, ioredis 5.3.2, Node.js 20.11

## Todos

- [x] Reproduce the defect in local Docker Compose environment
- [x] Identify root cause in Redis reconnection path
- [x] Implement fix with counter state recovery
- [ ] Add failover regression test using testcontainers
- [ ] Verify fix in staging with controlled failover

## Log

- 2026-03-08: Created. After Redis Sentinel failover, rate limit counters reset to zero causing X-RateLimit-Remaining to report incorrect values. Reported by on-call after tenant complained about inconsistent rate limit headers.
- 2026-03-09: Reproduced locally. Confirmed the sorted set keys are lost when ioredis reconnects to the new primary because the reconnection triggers a fresh SELECT on the wrong database index. `f12a8b3`
- 2026-03-10: Root cause confirmed: ioredis `reconnectOnError` handler was not preserving the database index from the original connection config. The default reconnect selects db 0, but rate limit keys live in db 2. `g45d9c7`
- 2026-03-11: Fix committed. Added explicit `db` parameter to the reconnection config and a post-reconnect verification step that checks key existence before resetting counters. `h78e2f1`

## PRs

## Files

- src/services/redis-rate-store.ts
- src/services/redis-connection.ts
- src/services/redis-connection.test.ts
- src/config/redis-sentinel.yaml
- test/integration/redis-failover.test.ts

## Insights

- Root cause: ioredis reconnection after Sentinel failover defaults to database 0, but rate limit sorted sets are stored in database 2. The reconnect handler did not pass the `db` option from the original connection config, so all ZRANGEBYSCORE queries returned empty sets, making the middleware treat every request as the first in the window.
- The ioredis `reconnectOnError` callback receives the error object but not the original connection options. The fix stores the db index in a closure captured at connection creation time.
- This class of bug only manifests during failover events, which is why it was not caught in unit tests that use a single Redis instance.

## Journal

### 2026-03-09 -- finding
**Summary:** Reproduced the bug in Docker Compose with Redis Sentinel. The sorted set keys exist on the new primary (replication is working), but the client queries db 0 after reconnect instead of db 2. Confirmed by adding DEBUG logging to redis-rate-store.ts. Commit `f12a8b3`.

### 2026-03-10 -- finding
**Summary:** Traced through ioredis source code. The `retryStrategy` reconnection path creates a new internal connection that uses default options. The `db` field from the constructor config is not forwarded. This is a known ioredis behavior (not a bug in ioredis itself) -- the consumer must handle db selection in the `reconnectOnError` callback. Commit `g45d9c7`.

### 2026-03-11 -- decision
**Summary:** Chose to fix by capturing the db index in the connection factory closure rather than patching ioredis or switching to a different client library. This is the least invasive change and follows the existing connection management pattern in the codebase. Commit `h78e2f1`.
