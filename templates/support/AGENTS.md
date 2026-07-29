# Agentic Support

This directory is the canonical support system for this workspace's agent
guidance, shared facts, reusable mechanics, and validation. It serves the whole
team — every practice and their agents. Admit a new skill, tool, profile, or
resource only when its value is core and crosscutting across practices.

- Start with `README.md`, then select a canonical skill from `skills/`.
- Run `tools/workspace-doctor.sh` at session start: it reports which roots this
  session sees and which capability tiers are available.
- `docs/solutions/` holds documented learnings from past work (bugs, workflow
  traps, patterns), organized by category with YAML frontmatter; `CONCEPTS.md`
  defines shared workspace vocabulary. Read both when working in a documented area.
- Keep product synthesis, plans, and product-specific exceptions in the owning
  product area or practice lane, not here.
- Keep cloned repositories in the machine-local checkouts root; they are not
  support-system artifacts.
- Do not store credentials, `.env*`, local agent configuration, dependency
  folders, raw authenticated content, or generated local output here.
- Context Fabric records are edited snapshot-first via
  `tools/snapshot-context-fabric-record.sh`; schema changes need the steward first.
- `skills/<name>/SKILL.md` is canonical. Harness adapters may point to it but
  must not fork its procedures.

See `docs/contributing.md` before changing this system, and
`docs/placement-doctrine.md` when unsure where something belongs.
