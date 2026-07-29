---
purpose: Harness-agnostic and model-agnostic local setup. Dependencies by phase, per-tool configuration, and how a teammate joins an existing workspace.
audience: PMs setting up their machine to work in a shared agentic workspace.
status: Active.
last_updated: 2026-07-29
---

# Local Setup

Setup is **phased**: you only install what your phase needs. A new PM at Crawl needs almost nothing. This page also covers pointing each tool (harness) at a workspace, and how a teammate joins one that already exists.

Nothing here is model-specific. The workspace works the same whether the agent behind your tool is a Claude model, a GPT model, or anything else.

---

## Dependencies by phase

| Tool | What it's for | Crawl | Walk | Run |
|---|---|:---:|:---:|:---:|
| An agent tool (Codex / Claude Code / OpenCode / Cursor) | Doing the work | required | required | required |
| A text editor | Editing markdown | required | required | required |
| `git` | Versioned sharing (optional at Crawl) | optional | optional | recommended |
| `jq` | Validate/inspect Context Fabric JSON | – | recommended | required |
| `yq` | Read the skill manifest / YAML in checks | – | recommended | required |
| `rg`, `fd` | Search and validation scripts | – | recommended | required |
| `shellcheck` | Validate the kit's shell scripts before running | – | optional | recommended |
| Node.js (`node`/`npm`) | Only if you run the Context Fabric selector/validator scripts | – | – | optional |

On macOS, the Walk/Run CLI tools install in one line:

```bash
brew install jq yq ripgrep fd shellcheck
```

Node is only needed if your team runs the optional JSON-schema validation and profile-selection scripts. The workspace is fully usable without it.

---

## Harness-agnostic configuration

The workspace is authored once and read by whatever tool each teammate uses. The bridge is always `AGENTS.md`.

### Choosing a harness (least-technical first)

If you do not use a terminal, prefer a graphical or web agent over a command-line one. None of these need a command line:

- **Codex in ChatGPT, Claude Desktop, the claude.ai web app, or Cursor** — graphical or web apps. Good default for non-technical teammates.
- **Codex CLI or Claude Code** — powerful but run in a terminal. Best for people already comfortable there.

A web-only agent (for example Codex in ChatGPT, or claude.ai with the Google Drive connector) can work without installing anything locally. It cannot run the kit's scripts or validator, which is fine at Crawl. For that path, share the workspace over Google Drive (see [collaboration-and-governance.md](collaboration-and-governance.md)). The per-tool setup below applies whichever you pick.

### Codex (ChatGPT)
Codex is OpenAI's coding agent, now offered through ChatGPT. It reads `AGENTS.md` directly and can consume the shared `SKILL.md` bundle without a separate adapter. Point it at the workspace root. See `templates/harness-config/` for notes.

### Claude Code
Reads `CLAUDE.md`, **not** `AGENTS.md`. In each folder that has an `AGENTS.md`, add a `CLAUDE.md` containing the single line `@AGENTS.md` — Claude Code expands that import at session start, so you maintain only `AGENTS.md`. `new-workspace.sh` creates the root `CLAUDE.md` import for you, and skills sync into Claude Code's skills directory. No project config file is required to pick up `CLAUDE.md`. (A symlink `CLAUDE.md -> AGENTS.md` works too, but the import is safer over Google Drive and on Windows.)

### OpenCode
Reads `AGENTS.md` and loads workspace skills via `opencode.json`. Drop this at the workspace root (also in `templates/harness-config/opencode.json`):

```json
{
  "$schema": "https://opencode.ai/config.json",
  "instructions": ["AGENTS.md"],
  "skills": { "paths": ["skills"] }
}
```

### Cursor and others
Any tool that supports an agent-instructions file can point at `AGENTS.md`. If it uses a different filename, add a thin file that says "read `AGENTS.md`" rather than duplicating content.

The rule across all tools: **`AGENTS.md` is the source of truth; per-tool files are mirrors or pointers, never independent copies.** See [harness-and-model-agnostic.md](harness-and-model-agnostic.md).

---

## Skill sync (Walk and up)

Skills are authored once under `skills/<id>/SKILL.md` (in the support layer) and mirrored into each tool's runtime directory. `sync-skills.sh` is installed with the support engine. Each teammate runs it from their own machine:

```bash
./agentic-support/skills/sync-skills.sh --target all   # mirror source-of-truth skills into each tool
./agentic-support/skills/sync-skills.sh --check         # detect stale/missing mirrors (CI or preflight)
```

Runtime target directories are owned by each tool and keep that tool's own (lowercase) convention:

```
opencode -> ~/.config/opencode/skills
codex    -> ~/.agents/skills
claude   -> ~/.claude/skills
```

Adjust to your machine. The source-of-truth `skills/<id>/` is the only thing you edit; the mirrors are generated.

---

## Multi-root setup: declaring where your roots are

Your workspace is several physical directories, not one folder: the shared workspace, a machine-local checkouts root, and one or more working-materials roots. Two things follow.

**1. Tell your harness about the extra roots — in user scope.** Each harness has its own mechanism (an additional-directories setting, a writable-roots list, a multi-root workspace file). The per-harness details live in the engine's `skills/workspace-setup/SKILL.md`, which stays current as harnesses change.

**Put every persistent setting in user scope on your machine, and launch with a machine-local primary folder.** Harnesses write session state under the session's primary folder; if that folder is on shared synced storage, your personal permission grants sync to the whole team — and deleting the file does not help, because the next session recreates it.

**2. Declare your roots once.** Machine-local paths live in a single declaration in your home directory, never in the shared tree:

```bash
agentic-support/tools/generate-workspace-descriptor.sh \
  --checkout-root "$HOME/projects/repo-checkouts" \
  --working-materials-root "<the lane you work in>"
```

That writes `~/.agentic-workspace/workspace-descriptor.yaml`. Shared documents then reference `${AGENTIC_REPO_CHECKOUT_ROOT}/<repo>/` instead of your absolute path, and every tool resolves it on the reader's machine. Roots are **declared, not guessed**: the generator refuses roots that do not exist, roots that nest, and a re-run that would silently drop a previously declared root.

Check it any time:

```bash
agentic-support/tools/workspace-doctor.sh
```

The doctor tells you where you are, which roots this session has, which capability tiers are available, and the one step that unlocks each locked tier. **Easier path:** ask your agent to run the `workspace-setup` skill and it does all of the above conversationally, including the harness configuration.

---

## Joining a workspace someone else created

1. Get the workspace onto your machine (clone the git repo, or sync the shared folder). See [collaboration-and-governance.md](collaboration-and-governance.md) for which one your team uses.
2. Install your phase's dependencies (table above).
3. Ask your agent to run the `workspace-setup` skill. It configures your harness for the multiple roots, writes your machine-local declaration, and runs the doctor until it is green.
4. If the workspace uses skills, run `agentic-support/skills/sync-skills.sh --target all` once.
5. Ask the agent to read the root `AGENTS.md` and the product area you're working in. You now share the team's context.

No manual path editing, and nothing you configure ends up in the shared tree.

---

## Safety invariants (all phases)

These are enforced by `scripts/validate-workspace.sh` and should be true on every machine:

- **No credentials.** No PATs, tokens, `.env` files, `op://` URIs, or vault IDs anywhere in the workspace. Inject secrets at runtime (for example via `op run`), never store them.
- **No code checkouts inside the workspace.** Cloned repos live outside it, referenced by path.
- **No OS metadata or dependency folders** committed (`.DS_Store`, `Icon`, `node_modules`).
- **No absolute machine paths in shared files.** Use bindings.

If you install the recommended toolchain, run `shellcheck` on any script from this kit before executing it. The kit's scripts are written to pass it.
