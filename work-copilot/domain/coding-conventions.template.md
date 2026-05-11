# Coding Conventions

<!-- This file is per-target-repo USER DATA. `copilot-deploy install` writes
     this skeleton on first install ONLY. Re-installs preserve your filled-in
     content (you'll see `[KEEP-USER] coding-conventions.md` in the install
     log).

     Replace each section below with your real repo conventions.
     /wc-investigate reads this file as ambient context so its design-doc
     recommendations match how this codebase is actually written. -->

## Language and framework

<!-- What you're coding in. Include language version + key frameworks. -->

Example: `Python 3.11; FastAPI for the HTTP layer; SQLAlchemy 2.0 for ORM;
pytest for tests; pydantic v2 for schema validation.`

Replace with: ...

## File / module layout

<!-- The high-level directory shape. Where do new modules go? -->

Example:

```
src/
  api/        # FastAPI routers, one file per resource
  models/     # SQLAlchemy models
  services/   # business logic, called from api/ handlers
  schemas/    # pydantic request/response models
  webhooks/   # outbound delivery
  tests/      # pytest, mirrors src/ layout
```

Replace with: ...

## Naming + style

<!-- Conventions that aren't obvious from reading 2-3 files. -->

- **Imports:** absolute, e.g. `from src.services.billing import ...`
- **Test files:** `test_<module>.py`, one per module
- **Type hints:** required on public functions; optional on private helpers
- **Async:** all I/O is `async def`; sync code is the exception

Replace with: ...

## Lint / format / type-check commands

<!-- What does CI run? What should /wc-implement / /wc-qa propose for
     verification? -->

Example:

```bash
ruff check .          # lint
ruff format --check . # format check
mypy src/             # type check
pytest                # tests
```

Replace with: ...

## Anti-patterns to avoid

<!-- Things that are technically legal but discouraged in this repo. -->

Example:

- Don't use `print()` for logging — use `logger.info()` from `src.logging`
- Don't catch bare `Exception` — narrow to the specific exception type
- Don't put business logic in `api/` handlers — keep it in `services/`

Replace with: ...
