# Context Fabric - Agent Instructions
Read `START-HERE.md` first, then the `views/<document-id>/AGENTS.md` named for your work; nothing else is required reading.
Governed facts live in `views/` (generated) and are authored in `documents/`; never hand-edit anything under `views/`.
Templates are in `templates/`, contracts in `schemas/`, scripts in `scripts/`, skills in `.agents/skills/` (mirrored at `.claude/skills/`).
Framework changes are spec-driven: open a change under `openspec/` before editing behavior.
Machine paths and secret references belong only in your own Individual document, never in this repository.
`openwiki/` is generated contributor documentation about this repository, not governed fact; a view wins when they disagree.
Validate with `scripts/validate.sh` and regenerate with `scripts/generate.sh`; `--check` makes both read-only.
Report a wrong fact in a document you do not maintain with `scripts/propose.sh` instead of editing it.
