# TODOS

## Active work

### Improve the test-plan extraction logic (P3, M)

We should investigate what the right shape for auto-generated test cases is.
Currently we extract the first sentence of the TODO body, but that misses
context. Body is long enough to pass the 50-char gate and isn't sensitive
surface; the gate this should hit is the design-needed keyword scan
(`investigate`).
