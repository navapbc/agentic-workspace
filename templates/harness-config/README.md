# Harness configuration

How to point each agent tool at a shared workspace. The bridge is always `AGENTS.md`.

## Codex (ChatGPT)

Codex is OpenAI's coding agent, now offered through ChatGPT. It reads `AGENTS.md` directly and can consume the shared `SKILL.md` bundle without a separate adapter. Point Codex at the workspace root. Runtime skill copies (from the sync script) default to `~/.agents/skills`.

## Claude Code

Claude Code reads `CLAUDE.md`, **not** `AGENTS.md`. In each folder with an `AGENTS.md`, add a `CLAUDE.md` containing just `@AGENTS.md`; Claude Code expands the import at session start, so you maintain only `AGENTS.md`. Skills sync into `~/.claude/skills`. No project config file is required to pick up `CLAUDE.md`.

## OpenCode

Drop `opencode.json` (in this folder) at the workspace root. It loads `AGENTS.md` as instructions and the workspace `skills/` directory. Restart OpenCode only if it doesn't pick up an updated workspace skill.

## Cursor and other tools

Any tool with an agent-instructions file can point at `AGENTS.md`. If it insists on a different filename, add a one-line file that says "read `AGENTS.md`" rather than duplicating content.

## The invariant

`AGENTS.md` is the source of truth. Every per-tool file is a pointer (`CLAUDE.md` = `@AGENTS.md` import) or config, never an independent copy. Change boundaries in `AGENTS.md`; the import means Claude Code picks the change up automatically.
