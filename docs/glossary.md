---
purpose: Shared vocabulary for the Agentic Workspace Starter Kit.
audience: Anyone reading or using the kit.
status: Active.
last_updated: 2026-07-29
---

# Glossary

Terms used throughout the kit, defined once.

| Term | Definition |
|---|---|
| **Agentic operating model** | The shared answer to "when a PM or their agent works on this product, how do they know what's true, what's allowed, and how we do things." Expressed as the three layers below. |
| **Harness** | The agent tool a person uses: Codex (OpenAI's agent, now offered through ChatGPT), Claude Code, OpenCode, Cursor, etc. The kit is harness-agnostic. |
| **Model** | The LLM behind the harness. The kit is model-agnostic; nothing depends on a specific model. |
| **Guidance layer** | The thin `AGENTS.md` (and `CLAUDE.md` `@AGENTS.md` import) files, one per folder, that state boundaries and route work. |
| **Support layer** | The reusable operating system: `skills/`, `context-fabric/`, `tools/`, `validation/`. A separate top-level folder. |
| **Product-work layer** | The actual product artifacts, split into product-work and prototyping lanes. |
| **`AGENTS.md`** | The source-of-truth, cross-tool agent-instructions file. Thin. Boundaries and routing only. |
| **`CLAUDE.md`** | The file Claude Code reads (it ignores `AGENTS.md`). In this kit it is a one-line `@AGENTS.md` import, so `AGENTS.md` stays the single source of truth. |
| **Authority chain** | The fixed order in which an agent resolves context: user instructions → support-layer guidance → selected skill → Context Fabric record + product-local `AGENTS.md`. |
| **Skill** | A written-down, reusable procedure at `skills/<name>/SKILL.md` with YAML frontmatter and standard sections. |
| **Skill manifest** | `skill-manifest.yaml`: the availability authority — each skill's `id`, path, and status (`enabled` / `partially-paused` / `paused`). A paused entry requires a `review_by` date, so a pause is a decision with a deadline. |
| **Adapter** | A thin per-harness pointer at `skills/<name>/adapters/<harness>/` that references the source-of-truth `SKILL.md` and never forks it. |
| **Sync (skills)** | Mirroring the source-of-truth skills into each harness's runtime directory via a script; `--check` detects drift. |
| **Context Fabric** | A schema-governed JSON catalog of shared facts: system, repository, and product-profile records. |
| **System resource** | A Context Fabric record (`system:<slug>`) for a shared system and how to reach it. No credentials. |
| **Repository resource** | A Context Fabric record (`repository:<org>/<repo>`) for one repo's identity and checkout facts. Defined once. |
| **Product profile** | A Context Fabric record (`product:<slug>`) binding a product to its systems, repos, aliases, anchors, and steward. |
| **Local reference resource** | A Context Fabric record (`reference:<slug>`) for a governed cross-product source the team consults but does not sync. Admitted only if it can answer "how does a reader verify an artifact from here?" |
| **Anchor** | A validated, exact reference inside a system (a tracker project key, a wiki page ID) that is a product's home there. Anchors are what stop an agent from searching a whole system. |
| **Selection tier** | A repo's importance to a product: `primary`, `supporting`, or `conditional`. |
| **Coverage** | Whether a product owns a repo's code (`direct`) or only consults it (`reference`). |
| **Multi-root workspace** | The topology: an agent session attaches several *physical* directories at once — the shared workspace plus machine-local roots — rather than assembling them into one folder with symlinks (which harness file viewers cannot display). |
| **Workspace descriptor** | The machine-local declaration of a member's roots (`~/.agentic-workspace/workspace-descriptor.yaml`). Declared by the member, never derived from directory shape; never synced, shared, or committed. |
| **Binding token** | A named placeholder for a machine-local root (`${AGENTIC_SUPPORT_ROOT}`, `${AGENTIC_REPO_CHECKOUT_ROOT}`) that shared documents use, resolved per machine through the descriptor. Replaces sibling-relative `../` paths, which cannot resolve when roots share no common parent. |
| **Declared, not derived** | The rule that machine-local paths come from an explicit declaration and tools **fail closed** without one, rather than guessing from a sibling directory or `$HOME`. A guess is right on the author's machine and quietly wrong elsewhere. |
| **Primary folder** | The single folder a harness treats as its project scope. It persists session state (permission grants, local overrides) there, so it must be machine-local — never a shared synced folder. |
| **Launch shape** | Which folder is the primary folder and which roots are attached. The durable defense against leaking personal harness state into a shared tree lives here, because detection can only warn after the write. |
| **Workspace doctor** | The read-only session-start probe: where am I, which roots are declared, which capability tiers are available, and what unlocks each locked one. |
| **Capability tier** | A band of what a session can do, gated on what is present: shared context and repo digests (no git needed), checkout inspection, checkout refresh, credentialed access. |
| **Repo digest** | A generated per-repository summary (purpose, layout, last-refreshed commit, freshness dates) so repository questions can be answered with no git installed and no checkout open. |
| **Snapshot-first** | Archiving a record and logging the reason *before* editing it. The safety net that replaces review where sync, not merge, is the distribution channel. |
| **Digest-bound mutation** | The preview→apply contract for checkout refresh: preview emits a digest binding the manifest bytes and checkout root; apply refuses if either changed. |
| **Placement doctrine** | The four ordered questions that decide whether something is `AGENTS.md` guidance, a skill, a schema, or a tool. Ordered by load cost, not by taste. |
| **Sync manifest** | The reviewed, versioned, operational list of repos to check out locally. Distinct from the reference catalog. |
| **Product-work lane** | The lane (`product-work/`, or your team's name for it) holding work the team relies on and shares. Review, ownership, and status labels are optional practices a team can attach. |
| **Prototype / prototyping lane** | Exploratory work: spikes, mockups, experiments. No assigned profile. |
| **Steward / owner** | Optional: the named owner of a product area. A team can use owners and a review step where they help, or skip them. |
| **Persistent context** | Context carried across sessions, separated by load cost: always-loaded and tiny (`AGENTS.md`, `CONCEPTS.md`), load-on-demand (skills, records, `docs/solutions/`), and audit-only (record changelog and archive, never auto-loaded). The kit still prescribes no auto-loaded prompt log. See architecture §6. |
| **Docs lanes** | Subfolders under a workspace `docs/` where output lands. The kit suggests `ideation/`, `plans/`, `solutions/`, and reports as a starting set; each team picks, renames, or replaces them. |
| **Directory naming standard** | Lowercase kebab-case for all directories (matches the internal reference implementation and skill/slug identifiers). See `directory-and-naming-standard.md`. |
| **Pause/enable status** | A field on skills and Context Fabric records that lets you ship the structure before the machinery is finished. |
| **Crawl / Walk / Run** | The three adoption phases. Start at Crawl. |
