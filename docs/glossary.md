---
purpose: Shared vocabulary for the Agentic Workspace Starter Kit.
audience: Anyone reading or using the kit.
status: Active.
last_updated: 2026-07-22
---

# Glossary

Terms used throughout the kit, defined once.

| Term | Definition |
|---|---|
| **Agentic operating model** | The shared answer to "when a PM or their agent works on this product, how do they know what's true, what's allowed, and how we do things." Expressed as the three layers below. |
| **Harness** | The agent tool a person uses: Claude Code, Codex, OpenCode, Cursor, etc. The kit is harness-agnostic. |
| **Model** | The LLM behind the harness. The kit is model-agnostic; nothing depends on a specific model. |
| **Guidance layer** | The thin `AGENTS.md` (and `CLAUDE.md` `@AGENTS.md` import) files, one per folder, that state boundaries and route work. |
| **Support layer** | The reusable operating system: `skills/`, `context-fabric/`, `tools/`, `validation/`. A separate top-level folder. |
| **Product-work layer** | The actual product artifacts, split into product-work and prototyping lanes. |
| **`AGENTS.md`** | The source-of-truth, cross-tool agent-instructions file. Thin. Boundaries and routing only. |
| **`CLAUDE.md`** | The file Claude Code reads (it ignores `AGENTS.md`). In this kit it is a one-line `@AGENTS.md` import, so `AGENTS.md` stays the single source of truth. |
| **Authority chain** | The fixed order in which an agent resolves context: user instructions → support-layer guidance → selected skill → Context Fabric record + product-local `AGENTS.md`. |
| **Skill** | A written-down, reusable procedure at `skills/<name>/SKILL.md` with YAML frontmatter and standard sections. |
| **Skill manifest** | `skill-manifest.yaml`: the index of skills, their versions, and their `status` (enabled/paused). |
| **Adapter** | A thin per-harness pointer at `skills/<name>/adapters/<harness>/` that references the source-of-truth `SKILL.md` and never forks it. |
| **Sync (skills)** | Mirroring the source-of-truth skills into each harness's runtime directory via a script; `--check` detects drift. |
| **Context Fabric** | A schema-governed JSON catalog of shared facts: system, repository, and product-profile records. |
| **System resource** | A Context Fabric record (`system:<slug>`) for a shared system and how to reach it. No credentials. |
| **Repository resource** | A Context Fabric record (`repository:<org>/<repo>`) for one repo's identity and checkout facts. Defined once. |
| **Product profile** | A Context Fabric record (`product:<slug>`) binding a product to its systems, repos, aliases, anchors, and steward. |
| **Anchor** | A validated, exact reference inside a system (a Jira project key, a Confluence page ID) that is a product's home there. |
| **Selection tier** | A repo's importance to a product: `primary`, `supporting`, or `conditional`. |
| **Coverage** | Whether a product owns a repo's code (`direct`) or only consults it (`reference`). |
| **Bindings** | Named path variables (`${SUPPORT_ROOT}`, etc.) set per machine so skills and workflows are portable. |
| **Sync manifest** | The reviewed, versioned, operational list of repos to check out locally. Distinct from the reference catalog. |
| **Product-work lane** | The lane (`product-work/`, or your team's name for it) holding work the team relies on and shares. Review, ownership, and status labels are optional practices a team can attach. |
| **Prototype / prototyping lane** | Exploratory work: spikes, mockups, experiments. No assigned profile. |
| **Steward / owner** | Optional: the named owner of a product area. A team can use owners and a review step where they help, or skip them. |
| **Persistent context** | Any mechanism for carrying context across sessions/PMs. The kit defers prescribing one (see architecture §6); auto-loaded context must stay tiny, and unbounded logs should never be auto-loaded. |
| **Docs lanes** | Subfolders under a workspace `docs/` where output lands. The kit suggests `ideation/`, `plans/`, `solutions/`, and reports as a starting set; each team picks, renames, or replaces them. |
| **Directory naming standard** | Lowercase kebab-case for all directories (matches the internal reference implementation and skill/slug identifiers). See `directory-and-naming-standard.md`. |
| **Pause/enable status** | A field on skills and Context Fabric records that lets you ship the structure before the machinery is finished. |
| **Crawl / Walk / Run** | The three adoption phases. Start at Crawl. |
