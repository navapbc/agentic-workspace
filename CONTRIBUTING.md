# Contributing

Changes to this framework are **spec-driven**. The specification changes first, the implementation follows, and the change is archived when it lands. That is how the repository stays describable to an agent that has never seen it.

## The loop

1. **Search before you author.** Check `openspec/specs/` for the capability you are about to change and `docs/experiments/README.md` for whether it was already tried and dropped.
2. **Open a change.** `openspec propose` writes a change under `openspec/changes/`. Say what capability changes and why; do not restate facts that already live in a document or a schema.
3. **Implement it.** Follow the change's deltas. `openspec apply` keeps the change and the tree in step.
4. **Verify.** `tests/run.sh` is the gate. `openspec validate --all --strict` must be clean.
5. **Archive.** `openspec archive` merges the deltas into `openspec/specs/` and closes the change.

`openspec validate --all --strict` runs in CI, but `tests/run.sh` is the authority: CI is advisory here.

## When a spec is not required

Set `skip_specs: true` on the change for work that carries no capability delta:

- example documents and their generated views
- marketing copy under `docs/marketing/`
- release notes and changelog entries
- tool version bumps
- anything generated under `openwiki/`

## What never belongs in a change

- A spec that restates a fact already stated by a document or a schema. Facts live in `documents/`; specs describe capabilities.
- A real organization, system, person, hostname, or credential. Examples are fictional; see `NOTICE`.
- An absolute machine path or an `op://` reference outside an Individual document. See `SECURITY.md`.
- A hand edit to anything under `views/` or `templates/`. Both are generated -- change the source and regenerate.

## Correcting a document you do not maintain

Do not edit it. Run `scripts/propose.sh` to file a correction proposal under `proposals/`; the document's maintainer accepts or declines it. This is the only supported path across a maintainer boundary.

## Before you push

- `tests/run.sh` passes. Exit 3 means a stage was skipped for a missing optional tool -- read which one before treating the run as green.
- `shellcheck --severity=warning` is clean over every shell script you touched.
- No generated file is stale: `scripts/generate.sh --check` and `scripts/render-templates.sh --check` both pass.

## Code of conduct

Participation is governed by `CODE_OF_CONDUCT.md`.
