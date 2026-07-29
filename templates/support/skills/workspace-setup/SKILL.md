---
workflow_id: workspace-setup
version: 1
status: enabled
owner: workspace stewardship
source_of_truth: true
portable_across_harnesses: true
---

# Workspace Setup Workflow

Take a team member — any practice, macOS or Windows — from "I can see the shared
folder" to a working, doctor-green multi-root workspace. This is the
practice-agnostic first run: it interviews the member for their roots, walks them
through configuring those roots in their agent harness, instantiates the
checkouts-root guidance, writes the machine descriptor, and then walks through
optional additions.

A workspace is a set of member-selected **physical** directories (roles and routing
rules: `${AGENTIC_SUPPORT_ROOT}/docs/workspace-routing.md`). Symlinking folders
together is not part of this workflow: harness file viewers do not display
symlinked folders' contents, so roots are handed to the harness directly.

## Bindings

Resolve these before running the workflow:

| Binding | Meaning | Resolution |
| --- | --- | --- |
| `${AGENTIC_SUPPORT_ROOT}` | Canonical agent guidance, Context Fabric, tools, validation. | The loaded support tree. |
| `${AGENTIC_WORKSPACE_TEMPLATES}` | Canonical checkouts-root guidance template. | `${AGENTIC_SUPPORT_ROOT}/templates/checkouts-root` |
| `${AGENTIC_SHARED_WORKSPACE}` | The team's shared workspace folder. | The parent of `${AGENTIC_SUPPORT_ROOT}` — a git clone, or a synced-storage mount (see Platform Reference). |
| `${AGENTIC_WORKSPACE_DESCRIPTOR}` | The machine-local declaration of this member's roots. | Environment override, else `~/.agentic-workspace/workspace-descriptor.yaml`. |

Follow the [skill binding contract](../../docs/skill-binding-contract.md). Every
root is chosen by the member during this workflow; nothing is inferred from another
user's default or from directory shape.

## Triggers

Use this workflow when the task asks to:

- set up the workspace on a new machine, for any practice;
- declare, repair, or re-declare workspace roots (including after moving one);
- configure an agent harness to see the workspace's multiple roots;
- explain how the shared lanes relate to machine-local roots;
- get a new team member from folder access to a working agent session.

## Required Context

Read these before acting:

- `${AGENTIC_SHARED_WORKSPACE}/README.md` — the workspace charter and the team's
  recorded decisions (sharing mechanism, lanes, harnesses in use).
- `${AGENTIC_SUPPORT_ROOT}/docs/workspace-routing.md` — root roles and routing rules.
- `${AGENTIC_WORKSPACE_TEMPLATES}/AGENTS.md` — the checkouts-root guidance this
  workflow instantiates.

## Platform Reference

| Fact | macOS | Windows |
| --- | --- | --- |
| Synced-storage mount | `~/Library/CloudStorage/<Provider>-<account>/…` | A mapped drive letter by default; it is configurable — detect it, do not hardcode |
| Shell runtime | Any POSIX shell | Git Bash (Git for Windows). WSL is out of scope for setup |
| Path form in Git Bash | n/a | `/<drive-letter>/<path>` |
| Home paths | `~` | `~` in Git Bash resolves to the user profile; `~/.agentic-workspace` works unchanged |

If the shared workspace is a git clone rather than synced storage, there is no
mount to detect: the member clones it wherever they like and declares that path.

## Procedure

1. **Confirm preconditions.** The member can see the shared workspace folder. On
   synced storage, confirm the provider's desktop client is installed and signed
   in, and direct the member to mark the workspace folder available offline —
   streamed placeholders make searches slow and flaky. On git, confirm the clone
   exists.
2. **Interview the member for their roots.** No declared root may sit inside
   another declared root.
   - **Repo checkouts (required):** a machine-local folder for git checkouts, never
     inside any synced tree. Any local, non-synced location works; create it if
     absent.
   - **Working materials (required, one or more):** where their in-progress work and
     outputs land — a shared collaboration lane, a personal local folder, or both.
     **The first one declared becomes the default output destination**, so ask which
     they want first.
   - **Extra roots (optional):** any other folders they want their sessions to see.
3. **Instantiate the checkouts-root guidance.** Copy
   `${AGENTIC_WORKSPACE_TEMPLATES}/AGENTS.md` into the checkouts root, replacing
   every `{{AGENTIC_SUPPORT_ROOT}}` token with this machine's path to the support
   tree. Add a `CLAUDE.md` beside it containing only `@AGENTS.md`. If a guidance
   file already exists there, show the member the diff before replacing.
4. **Configure the member's harness to see the roots** — the support tree, the
   checkouts root, and each working-materials and extra root. Use the Per-Harness
   Appendix below. Every persistent setting goes in **user scope on the member's
   machine** — never in a settings file inside a shared root.
5. **Write the machine descriptor** with the full declaration:

   ```sh
   "${AGENTIC_SUPPORT_ROOT}/tools/generate-workspace-descriptor.sh" \
     --checkout-root "<path>" \
     --working-materials-root "<path>" [--working-materials-root "<path>"]... \
     [--extra-root "<path>"]...
   ```

   Quote every path — synced mount paths contain spaces. The generator validates
   existence and nesting, and refuses to silently drop a previously declared root.
6. **Run the health check:** `"${AGENTIC_SUPPORT_ROOT}/tools/workspace-doctor.sh"`.
   It must report all declared roots green with the shared-context tier available.
7. **Walk through optional additions**, by the member's role and interest:
   - Repo checkouts for agent work: point to `repo-sync/SKILL.md`. Engineers keep
     any existing checkouts exactly where they are — this workspace never touches
     them. Checkouts hydrated here are workflow-scoped and read-only in practice:
     the sync tooling only fetches and fast-forwards, never pushes, and refuses
     checkout roots that would land inside a synced tree.
   - Credentialed access to the team's tracker or wiki, if the workspace declares
     one (`tools/doctor.conf`).
   - Deeper offline availability for any large shared reference lane the member
     works from while disconnected.
8. **State where the member's edits go.** Changes inside shared lanes reach the
   whole team (on sync, or on merge if git-backed); the checkouts root,
   `~/.agentic-workspace`, and harness settings stay on this machine only.

## Per-Harness Appendix

Concrete multi-root configuration per harness. Mechanisms and support levels change
— verify against current harness docs and update this appendix, rather than
assuming. **Persistent settings always live in user scope.**

- **Claude Code (CLI and desktop app):** persistent — add each non-primary root to
  `permissions.additionalDirectories` in `~/.claude/settings.json` (user scope).
  Per-session — `claude --add-dir "<path>"` (repeatable) or `/add-dir` inside a
  session. The desktop app's folder picker selects one primary folder; the
  settings-based additional directories still apply. Never put a `.claude/` settings
  folder inside a shared synced root.
- **OpenAI Codex CLI:** reads local directories broadly under `workspace-write`;
  grant edit access to additional roots via
  `[sandbox_workspace_write] writable_roots = ["<path>", ...]` in
  `~/.codex/config.toml`. Launch from the root you want as the working directory
  (`codex --cd "<path>"`).
- **Cursor:** create a `.code-workspace` file with a `"folders"` array listing every
  root and open it (File ▸ Open Workspace from File). Store the `.code-workspace`
  file machine-local — never inside a shared synced folder.
- **Gemini CLI:** persistent — `"includeDirectories": ["<path>", ...]` in
  `~/.gemini/settings.json`; per-session — `--include-directories`.
- **Harnesses without multi-root support:** some agent tools had none as of
  mid-2026, and some open multi-root workspaces in the editor but traverse them
  unreliably in agent mode. Check before adopting one for multi-root work; if it
  cannot see all the roots, it cannot follow the routing rules.

## Guardrails

- Never create files at the shared workspace folder root; its README and AGENTS.md
  are the workspace charter and change only through the steward.
- Never write harness configuration (`.claude/`, `.codex/`, `.gemini/`,
  `*.code-workspace`, any `settings.local.json`) into a shared synced root — user
  scope on the member's machine only. The doctor flags violations.
- Never place checkouts, credentials, dependency folders, or generated local
  artifacts inside a shared lane.
- Declared roots must not nest — no root inside another declared root.
- Never overwrite an existing populated checkouts root, descriptor, or guidance file
  without showing the member what changes first.
- Write paths in tilde or mount-relative form in all guidance and recorded output;
  never a user-home absolute path.

## Output Shape

Report at completion:

- The declared roots, by role, and the platform.
- The harness configured and the mechanism used (settings key, workspace file, or
  per-session flags).
- The descriptor path written.
- Doctor result: declared roots and capability tiers reported.
- Optional additions taken or deferred.
- One concrete next step for the member's first real task.

## Failure Handling

- **Shared folder not visible:** confirm folder membership and the sync client's
  sign-in, or the clone path. Do not guess alternative paths.
- **Doctor exits 3 with "No workspace descriptor":** run step 5 — the declaration
  has not been written on this machine yet.
- **Doctor exits 3 naming a declared root that no longer exists:** the root moved or
  was deleted; re-run step 5 with the full corrected declaration.
- **Generator refuses a re-run because it would drop a previously declared root:**
  include the missing root in the declaration, or — to retire it intentionally —
  delete the descriptor and re-declare the full set.
- **Doctor warns about harness configuration inside the shared tree:** move the
  settings to user scope, fix the launch shape (machine-local primary folder), then
  delete the shared-tree copy. Deletion alone will not stick.
- **Existing checkouts root with unknown content:** stop and ask; never merge
  silently.

## Harness Interpretation

This file is directly usable in any capable harness. The member's agent runs the
workflow conversationally; the shell steps are small and observable, and each
mutation is announced before it runs. Adapters under `../adapters/<harness>/` may
add capability discovery but must not fork this procedure.
