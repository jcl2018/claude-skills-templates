# Test: `portability-smoke` (`infra` / `CI-push`)

> **Topic:** [portability](../../topics/portability/index.md) · **Goal:**
> [another machine gets the same skills](../../../goals/portability.md) ·
> **Layer view:** [CI-push](../../topics/portability/CI-push.md).
> This test achieves **cross-platform parity** plus the fast **completeness** +
> **fidelity** per-PR proofs (S5/S6).

| Field | Value |
|-------|-------|
| Name | `portability-smoke` |
| Category | `infra` |
| Layer | `CI-push` |
| Mode | `deterministic` |
| Command | `bash scripts/windows-smoke.sh` |
| Tier | `free` |

## What it is

The fast Windows/Git-Bash smoke of the deploy/install harness. It runs the
`skills-deploy install` path forced into copy-mode (`SKILLS_DEPLOY_FORCE_COPY=1`)
so the Git-Bash behavior is exercised on *every* host — the ubuntu CI and macOS
included — not only on `windows-latest`. It is the per-PR stand-in for the heavy
`portability-deploy` harness: seconds, not minutes.

## What it proves

| Case | Assertion | Achieves |
|------|-----------|----------|
| **S1** | shell scripts check out with LF endings (no `w/crlf` under `git ls-files --eol`) | Cross-platform parity (CRLF safety) |
| **S2** | the portable `date_to_epoch` probe resolves (GNU `date -d` or BSD `date -j -f`); `suggest.sh` runs end-to-end | Cross-platform parity (date math) |
| **S3** | copy-mode install lands *regular files* (not symlinks), records `install_kind=copy`, and `doctor` is healthy | Cross-platform parity (copy-mode) |
| **S4** | the default install stamps `install_mode: in-place` (`bundle_path == source`), deposits `skills-update-check` to `_cj-shared`, and the copy-installed orchestrator resolves the update-check with no `.source` | Cross-platform parity (`install == clone`) |
| **S5** | a full `skills-deploy install` lands *every* catalog skill: deployed skill-dir count `== SKILL_COUNT` | **Completeness** (fast) |
| **S6** | the manifest's per-file `source_checksums` match the installed copies' actual hashes | **Fidelity** (fast) |

S5 and S6 are the per-PR halves of "another machine gets the *same* skills":
completeness (none missing) and fidelity (bytes match). The exhaustive install /
remove / relink / doctor / drift matrix is `portability-deploy`'s job at
[CI-nightly](../../topics/portability/CI-nightly.md).

## How to run

```bash
bash scripts/windows-smoke.sh                # S1–S6 (passes on macOS/Linux too, via FORCE_COPY)
# via the contract:
/CJ_test_run portability-smoke
/CJ_test_run --category infra
/CJ_test_run --layer CI-push
```

## Explanation

This is where **cross-platform parity** — the third property of the
[dream](../../../goals/portability.md) — is proven: real symlinks are unavailable
on Git-Bash, so `skills-deploy` must fall back to checksum-tracked copy-mode and
still reproduce the repo's skill surface. Because the assertions run under
`SKILLS_DEPLOY_FORCE_COPY=1`, a regression in the Windows install path turns the PR
red on Linux too — the parity guarantee is not left untested until a nightly
Windows run. S5/S6 additionally promote **completeness + fidelity** onto the fast
per-PR gate without moving the slow `test-deploy.sh` suite, keeping CI-push fast
while still gating the "same skills" promise on every merge.

For the per-unit breakdown of what the smoke asserts, see the
[windows-smoke family doc](../../windows-smoke.md); for the layer-level "how", see
[portability @ CI-push](../../topics/portability/CI-push.md).
