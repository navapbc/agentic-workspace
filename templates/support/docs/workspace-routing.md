---
purpose: How a multi-root workspace fits together, for any practice and any agent harness.
audience: Everyone working in the workspace, and the agents they work with.
status: Active.
---

# Workspace routing

A member's workspace is the set of physical directories their harness session
sees, plus a machine-local declaration of those directories (the workspace
descriptor — [skill-binding-contract.md](skill-binding-contract.md)). This doc is
generic and shared: nothing member-specific belongs in it, or anywhere else in
the shared tree.

**Roots are handed to the harness directly. They are never assembled into one
folder with symlinks.** Harness file viewers and pickers do not display the
contents of symlinked folders, so an assembled root is invisible exactly where
members work — tools pass, doctors report green, and the workspace simply does
not appear in the UI. See
[solutions/architecture-patterns/multi-root-workspace-over-symlink-assembly.md](solutions/architecture-patterns/multi-root-workspace-over-symlink-assembly.md).

## Root roles

| Role | What it is | How to recognize it |
| --- | --- | --- |
| Agentic support (required) | `agentic-support/` in the shared workspace: skills, tools, Context Fabric, validation. The hub every session orients from. | Its `README.md` heading names the agentic support layer; `skills/skill-manifest.yaml` exists. |
| Repo checkouts (required) | A machine-local folder of git checkouts. Never inside any synced tree. | Its `AGENTS.md` heading names the checkouts root and points back to the support tree. |
| Working materials (required, one or more) | Where in-progress work and outputs land: a shared collaboration lane, or a personal local folder. | Shared lanes carry their own `README.md`/`AGENTS.md`; a personal folder is whatever the member declared. The doctor lists the declared set. |
| Extra roots (optional) | Any other folder the member added to the session. | Declared in the descriptor; the doctor reports them as informational. |

## Orientation rules for agents

- Start every session by running `tools/workspace-doctor.sh` from the support
  tree. It validates the machine's declared roots and reports what the session
  can do.
- **The root you opened in is not the whole workspace.** Read its guidance file,
  then orient from the support tree before adopting any single root's conventions
  as the pattern. A narrow root's `AGENTS.md` becoming the session's primary
  instruction file is a known failure mode.
- If the session sees only the checkouts root — or any single root without the
  support tree — context is missing. Ask for the support root to be added before
  proceeding.

## Output routing

- Outputs and in-progress work go to a **working-materials root**. The first
  declared working-materials root is the default destination when the member
  hasn't said otherwise.
- Never write outputs, credentials, dependency folders, or generated analysis
  into the checkouts root or into `agentic-support/`.
- Practice lanes own their internal conventions. Practice-specific tooling and
  routing lives in that practice's own skills and onboarding, not in this doc.

## Cross-root guardrails

- **Quote every path in shell.** Cloud-mount paths routinely contain spaces
  (`Shared drives`, `My Drive`, `OneDrive - <Org>`).
- **Never write sibling-relative `../` references across roots.** Roots share no
  common parent, so `../` cannot resolve anywhere. Cross-root references in
  shared materials use descriptor binding tokens — for example
  `${AGENTIC_REPO_CHECKOUT_ROOT}/<repo>/`. `validation/check-workspace.sh` turns
  a reintroduced sibling-relative reference into a hard failure.
- **Never store member-specific harness state inside a shared root**
  (`settings.local.json`, `*.code-workspace`, and — in a workspace with no review
  gate — `.claude/`, `.codex/`, `.gemini/`). It belongs in user scope on the
  member's machine. The doctor flags violations.
- **Use a machine-local primary folder.** A session whose *primary* folder is a
  synced shared folder recreates its local settings file there every time, so
  deleting the file does not fix anything. Attach shared roots as additional
  directories instead — the launch shape is the durable fix, not the cleanup.
