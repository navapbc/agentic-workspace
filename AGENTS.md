# Context Fabric - Agent Instructions
Building this framework? Read `CONTRIBUTING.md` first: changes are spec-driven, so open a change under `openspec/` before editing behavior. Everything below is for *using* it.
Read `START-HERE.md` first, then the `views/<document-id>/AGENTS.md` named for your work; nothing else is required reading.
Governed facts live in `views/` (generated) and are authored in `documents/`; never hand-edit anything under `views/`.
Templates are in `templates/`, contracts in `schemas/`, scripts in `scripts/`, skills in `.agents/skills/` (mirrored at `.claude/skills/`).
Machine paths and secret references belong only in your own Individual document, never in this repository.
`openwiki/` is generated contributor documentation about this repository, not governed fact; a view wins when they disagree.
Validate with `scripts/validate.sh` and regenerate with `scripts/generate.sh`; `--check` makes both read-only.
Report a wrong fact in a document you do not maintain with `scripts/propose.sh` instead of editing it.
