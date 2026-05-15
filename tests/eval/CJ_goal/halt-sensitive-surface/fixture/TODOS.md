# TODOS

## Active work

### Update skills-catalog.json portability field for CJ_run (P3, S)

This TODO directly modifies skills-catalog.json, which is a sensitive surface
(catalog wiring drives validation, deploy, and skill discovery; mistakes
cascade). Body is long enough to pass the 50-char gate and has no design-needed
keywords; the gate this should hit is the sensitive-surface AUQ. /CJ_goal
defaults to halt at sensitive-surface AUQ per design (user-declined as default).
