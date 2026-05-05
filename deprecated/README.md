# deprecated/

Source-of-truth for skills marked `status: deprecated` in `skills-catalog.json`. Contents here are NOT deployable skills — `skills-deploy install` skips them by default (use `--include-deprecated` to install one anyway). They stay in the repo because byte-mirrored bundles (e.g. `work-copilot/`) reference them as upstream truth, enforced by `scripts/validate.sh` Error check 10's `MIRROR_SPECS` array.

`deprecated/work-items/` holds the work-item history (trackers, design docs, RCAs, test plans) for skills that have since been deprecated. They're frozen historical records — not validated by `scripts/validate.sh`'s reconciliation walk, which only inspects active items under `work-items/`. The chronological IDs (F-numbers, D-numbers) are preserved so cross-references in CHANGELOG and other historical artifacts remain readable.

To deprecate another skill: flip its catalog `status` to `deprecated`, move `skills/{name}/` here, set `templates_source: "deprecated/{name}/templates"` on the catalog entry, update any `MIRROR_SPECS` source paths, and move its primary work-item directories (the feature itself + any defects whose primary subject is this skill) to `deprecated/work-items/`.
