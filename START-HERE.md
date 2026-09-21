# Start here

> **Skeleton.** U13 writes the full onboarding path and the U8 dress rehearsal proves it. This file exists so a fresh session has an entry point from the first commit.

## If you are an agent

Read `AGENTS.md`, then the `views/<document-id>/AGENTS.md` for the document you were pointed at. Nothing else in this repository is required reading.

## If you are a person

1. **Read a view, not a document.** `views/` holds standalone projections an agent can read on its own. `documents/` holds the authored source.
2. **Pick your tier.** Org describes an organization's systems. A Bounded Context describes one team's or workstream's working set and extends one or more Org documents. An Individual document binds those to your machine.
3. **Check your tools.** `scripts/check-tools.sh` reports what is present and what each missing tool would unlock. It installs nothing.
4. **Bind your machine.** `scripts/setup-individual.sh` writes your Individual document outside this repository. Starting with nothing at all, `scripts/bootstrap-solo.sh` walks the whole path.
5. **Validate and generate.** `scripts/validate.sh` reports findings; `scripts/generate.sh` rebuilds views. Both take `--check`.

## The rules that matter on day one

- Never hand-edit anything under `views/` or `templates/`; both are generated.
- Your machine paths and your secret references belong in your Individual document, which lives outside this repository. Nothing else may carry them (`SECURITY.md`).
- To correct a document someone else maintains, file a proposal with `scripts/propose.sh`; do not edit it.
- Framework changes are spec-driven (`CONTRIBUTING.md`).
