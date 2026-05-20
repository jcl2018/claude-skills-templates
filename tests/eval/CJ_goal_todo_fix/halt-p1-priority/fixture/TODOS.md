# TODOS

## Active work

### Rewrite the entire validator from scratch (P1, M)

This is a sizable refactor that needs careful design. It rewrites the entire
validator from scratch with a new dependency model. Worth doing but not the
kind of thing you slip in between other features. Body is long enough to pass
the 50-char check, no sensitive surface, no design-needed keywords — the only
gate this should hit is the P1 priority cap.
