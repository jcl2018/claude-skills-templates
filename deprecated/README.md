# deprecated/

Source-of-truth for skills marked `status: deprecated` in `skills-catalog.json`. Contents here are NOT deployable skills — `skills-deploy install` skips them by default (use `--include-deprecated` to install one anyway). They stay in the repo because byte-mirrored bundles (e.g. `work-copilot/`) reference them as upstream truth, enforced by `scripts/validate.sh` Error check 10's `MIRROR_SPECS` array.

To deprecate another skill: flip its catalog `status` to `deprecated`, move `skills/{name}/` here, set `templates_source: "deprecated/{name}/templates"` on the catalog entry, and update any `MIRROR_SPECS` source paths.
