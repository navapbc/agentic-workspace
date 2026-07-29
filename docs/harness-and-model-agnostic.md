---
purpose: Why and how a shared agentic workspace stays portable across tools (harnesses) and models.
audience: PMs and leads who want to trust that the workspace won't lock the team into one tool or model.
status: Active.
last_updated: 2026-07-22
---

# Harness-Agnostic and Model-Agnostic by Design

A shared workspace is worthless if it only works for the person who built it, on the tool they happen to use. This kit is built so that any teammate, on any capable agent tool, backed by any capable model, gets the same context and the same procedures.

"Harness" means the agent tool: Codex (OpenAI's agent, now offered through ChatGPT), Claude Code, OpenCode, Cursor, and successors. "Model" means the LLM behind it.

---

## The single rule that makes it work

**Everything reusable is plain text (markdown, JSON) or plain shell, and `AGENTS.md` is the one source-of-truth instruction file.** Nothing reusable is expressed as tool-specific config or model-specific API calls.

From that rule, portability follows:

- Markdown instructions and procedures are readable by any tool and any model.
- JSON context records are validated by a schema, not interpreted by a model.
- Shell tools run the same regardless of which agent invoked them.

---

## How each layer stays portable

### Guidance layer
`AGENTS.md` is an emerging cross-tool standard. Codex, OpenCode, and Cursor read it. Claude Code reads `CLAUDE.md`, **not** `AGENTS.md`, so it needs a bridge. So:

- Author boundaries once in `AGENTS.md`.
- Bridge Claude Code with a `CLAUDE.md` that is a **one-line `@AGENTS.md` import**, not a copy. Claude Code expands the import at session start, so `AGENTS.md` stays the single source of truth and there is nothing to keep in sync. (A symlink `CLAUDE.md -> AGENTS.md` also works but is unreliable over Google Drive and on Windows, so prefer the import.)
- For any tool with a different filename, add a one-line pointer ("read `AGENTS.md`"), never a second copy of the content.

### Support layer — skills
A skill has three parts:

1. **The `SKILL.md`** — the full procedure, tool-neutral, with a `portable_across_harnesses: true` marker and a short "Harness Interpretation" note stating that every tool preserves the same output shape. This file is the source of truth.
2. **Thin adapters** at `skills/<name>/adapters/<harness>/` — each is a pointer that says "the `SKILL.md` controls behavior; if this adapter disagrees, the source-of-truth copy wins." Adapters differ only in the tool's name and its discovery convention. They never fork the procedure.
3. **A sync script** that mirrors the source-of-truth bundle into each tool's runtime directory, with a `--check` mode for drift.

This is what lets a Codex user and a Claude Code user run the "same" skill and get the same result.

### Support layer — context fabric
Records are JSON validated against a schema. A model reads them as data; it does not need to be a particular model to do so. The schema forbids secrets and absolute paths, so records are safe to share across machines.

### Tools
Plain shell with `set -euo pipefail`, driven by explicit CLI arguments. No dependency on any agent tool. A human or any agent can run them identically.

---

## Model-agnostic specifics

- **No model IDs or provider SDKs** appear in the workspace. If you build automation that calls a model, keep it in the prototyping lane and behind a boundary; do not bake a model choice into shared skills.
- **Review personas** are written as role descriptions and challenge patterns — prompts any capable model can adopt, not code.
- **Prompts avoid model-specific quirks.** Procedures describe the goal and the output shape, so a stronger or different model produces the same artifact.

---

## Portability across machines

Two mechanisms:

- **Binding tokens** replace hardcoded absolute paths with named variables (`${AGENTIC_SUPPORT_ROOT}`, `${AGENTIC_REPO_CHECKOUT_ROOT}`, …), resolved per machine through a declaration in the member's home directory that is never synced or committed. See [local-setup.md](local-setup.md) and the engine's `docs/skill-binding-contract.md`.
- **Relative references** between layers. A product folder points to the support layer by relative path, so the whole tree relocates cleanly.

---

## What you gain

- A new PM adopts the workspace with their existing tool. No one is forced to switch.
- The team is insulated from any single tool's or model's changes and pricing.
- Procedures and context compound as shared assets, not per-person, per-tool artifacts.
