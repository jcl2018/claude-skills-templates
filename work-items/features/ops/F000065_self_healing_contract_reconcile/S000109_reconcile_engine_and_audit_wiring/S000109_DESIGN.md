---
type: design
parent: S000109
title: "Reconcile engines + audit-skill wiring — Design"
version: 1
status: Draft
date: 2026-06-13
author: chjiang
reviewers: []
---

<!-- This atomic story derives directly from the parent feature's /office-hours
     session. The parent feature DESIGN (F000065_DESIGN.md) holds the full
     cross-story design; this stub keeps the 7 sections present and links up. -->

## Problem

The audit skills seed a MISSING contract file but dead-stop on one that exists in a
non-canonical shape: a `doc-spec.md` still on the old YAML generation is rejected
with `[doc-sync-no-config] … has no registry table` and no actionable next step.
See parent [F000065_DESIGN.md](../F000065_DESIGN.md) `## Problem` for full context.

## Shape of the solution

One atomic story, two internal phases. Phase 1: add a read-only `--classify` and an
opt-in `--reconcile` to BOTH `scripts/doc-spec.sh` and `scripts/test-spec.sh`
(`--classify` labels absent/canonical/legacy/duplicate; `--reconcile` migrates a
legacy YAML file → canonical 3-column Markdown preserving every declared row,
atomic + `.bak` + report, idempotent no-op on canonical, with the `audit_class`
asymmetry guard). Phase 2: wire the audit skills' Step-2 "seed if missing" into a
reconcile step driven by `--classify` (non-canonical → an advisory `RECONCILE:`
directive, NO auto-write), add an opt-in audit `--reconcile` flag (standalone
only), document the canonical contract-file template in the USAGE.md + spec prose,
and add classify/reconcile fixtures registered in `scripts/test.sh` +
`spec/test-spec-custom.md`. See parent
[F000065_DESIGN.md](../F000065_DESIGN.md) `## Shape of the solution`. The
requirement-level detail lives in [S000109_SPEC.md](S000109_SPEC.md).

## Big decisions

The five settled decisions (D-A Approach A reconcile+migrate flag-gated / D1
report-directive-not-AUQ / D2 duplicate report-only no auto-delete / D legacy-vs-
malformed signature gate / D3 awk/sed POSIX parser no new dep) are recorded in the
parent feature design's `## Big decisions` table — see
[F000065_DESIGN.md](../F000065_DESIGN.md). Story-local: the work is one cohesive
change with no task children; the two phases are build sequencing inside one PR.

## Risks & open questions

The full risk table (malformed-canonical mis-classified as legacy, every-row-
preservation on a 40+-row registry, the `audit_class` asymmetry, a new write path
in a read-mostly skill, no workbench reconcile noise, the implement-subagent
`test.sh`-fixture blind spot, OQ1 auto-delete-duplicates, OQ2 root→spec
relocation, OQ3 the test-spec legacy signature) lives in the parent
[F000065_DESIGN.md](../F000065_DESIGN.md) `## Risks & open questions`. The top
blocker for this story is preserving every declared row through the legacy→canonical
migrate — mitigated by the atomic temp→`--validate`-clean→`mv` write + `.bak` and a
40+-row round-trip fixture.

## Definition of done

Both engines classify absent/canonical/legacy/duplicate correctly; `doc-spec.sh
--reconcile` migrates a 40+-row legacy fixture preserving every row (`--validate`-
clean, `.bak`, idempotent); the `audit_class` asymmetry guard fires; both audit
skills surface the advisory `RECONCILE:` directive on a legacy fixture and migrate
under `--reconcile` while a canonical repo emits zero reconcile lines; the canonical
template is documented; `validate.sh` + `test.sh` are green and the workbench
classifies `canonical` clean. See the full list in
[S000109_TRACKER.md](S000109_TRACKER.md) `## Acceptance Criteria` and parent
[F000065_ROADMAP.md](../F000065_ROADMAP.md) `## Success Criteria`.

## Not in scope

Auto-deleting duplicates (OQ1); relocating a root-only contract into `spec/`
(OQ2); redefining the canonical format/position (the audits already own it);
auto-creating the docs/units a contract declares; any external/runtime dependency
change. See parent [F000065_DESIGN.md](../F000065_DESIGN.md) `## Not in scope`.

## Pointers

- Parent feature design: [../F000065_DESIGN.md](../F000065_DESIGN.md)
- Parent feature roadmap: [../F000065_ROADMAP.md](../F000065_ROADMAP.md)
- This story's spec: [S000109_SPEC.md](S000109_SPEC.md)
- This story's test-spec: [S000109_TEST-SPEC.md](S000109_TEST-SPEC.md)
- This story's tracker: [S000109_TRACKER.md](S000109_TRACKER.md)
