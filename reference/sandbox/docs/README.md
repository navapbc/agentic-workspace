# Docs lanes

Standard output lanes for a shared agentic workspace. Use these; do not invent new lanes by default. Consistent lanes let any agent and any teammate know where a given kind of output belongs.

| Lane | What goes here |
|---|---|
| `ideation/` | Early idea generation and option exploration. |
| `plans/` | Brainstormed scope and implementation plans. |
| `solutions/` | Documented, reusable learnings from solved problems (with YAML frontmatter). |
| `pulse-reports/` | Periodic health/status snapshots (optional). |
| `dogfood-reports/` | Notes from using your own tools/workspace (optional). |
| `references/` | Read-only source bundles: one folder per source, each with a README, the files, and any extracted text. |

Create a lane folder only when you first write into it. Prototyping workspaces may add `brainstorms/` and `prototypes/`; canonical workspaces should not.

Directory and lane names are lowercase kebab-case (see the kit's `docs/directory-and-naming-standard.md`), which matches the compound-engineering skills' default `docs/` lanes.
