---
purpose: Entry point for a PM adopting the Agentic Workspace Starter Kit. Explains the operating model and how to stand up a shared workspace.
audience: Nava PMs new to agentic-supported product management.
status: Active.
reading_order: 1 of 1 at root. See README.md for the full kit map.
last_updated: 2026-07-22
---

# Start Here: Standing Up a Shared Agentic Workspace

This document explains what an agentic operating model is, why you'd want one, and how to stand one up with this kit. Read it once, front to back. It takes about ten minutes.

---

## 1. The problem this solves

If you use an AI agent (Claude Code, Codex, OpenCode, Cursor) for product work today, you have probably felt these:

- **You re-explain context every session.** The agent doesn't know your program's acronyms, which systems matter, where the source-of-truth documents live, or what it must not touch.
- **Your teammates get different results.** Each PM has their own prompts, their own folder habits, and their own tool. Nothing is shared, so nothing compounds.
- **Good procedures don't stick.** You figure out a great way to do a role intake or a policy extraction, and then it lives in your head or one chat log.

Nava's AI strategy names this directly: *"we do not have shared models for agentic ways of working."* This kit is a shared model. It gives a group of PMs one workspace where the context, boundaries, vocabulary, and reusable procedures are written down once, in a form every tool and every teammate can use.

---

## 2. What "operating model" means here

An operating model is just the answer to: **when a PM (or their agent) sits down to work on this product, how do they know what's true, what's allowed, and how we do things?**

For an agentic workspace, that answer lives in three layers:

1. **Guidance** — thin `AGENTS.md` files, one per folder, that state boundaries and route work. "This folder is X. Don't put Y here. Reusable procedures live over there."
2. **Support** — the reusable stuff: *skills* (written-down procedures) and a *shared-context catalog* (machine-readable facts about your products, systems, and repos). Authored once, used by everyone.
3. **Product work** — the actual artifacts (strategy docs, deliverables, research), split into **canonical** (reviewed, shareable) and **prototype** (exploratory) lanes.

The kit gives you templates and scripts for all three. You adopt them in phases.

See [docs/architecture.md](docs/architecture.md) for the full picture, including the *authority chain* an agent follows to resolve what to do.

---

## 3. The core idea: write once, use in any tool

The single most important design choice is this: **`AGENTS.md` is the shared instruction file, and everything reusable is plain text or shell.**

- `AGENTS.md` is a cross-tool standard. Codex, OpenCode, and Cursor read it directly. Claude Code reads `CLAUDE.md`, so we add a `CLAUDE.md` that is a one-line `@AGENTS.md` import — same content, nothing to keep in sync.
- Skills are plain-markdown `SKILL.md` files. They are authored once in the support layer, then *mirrored* into each teammate's tool by a sync script. Each tool gets a thin adapter that points back to the one canonical copy.
- The shared-context catalog is JSON validated against a schema. No tool or model is baked in.

The payoff: a teammate on Codex and a teammate on Claude Code, on different laptops, get the same context and the same procedures. Nothing depends on a particular model. See [docs/harness-and-model-agnostic.md](docs/harness-and-model-agnostic.md).

---

## 4. How to adopt it (the short version)

**Step 1 — Pick your phase.** Read [docs/phased-adoption.md](docs/phased-adoption.md). If you're new, start at **Crawl**: one workspace, one `AGENTS.md`, and the standard Docs lanes. That is genuinely useful on day one and takes 15 minutes.

**Step 2 — Do local setup once.** Follow [docs/local-setup.md](docs/local-setup.md). It installs a short list of dependencies and points your tool at the workspace. You can do the Crawl phase with essentially no dependencies.

**Step 3 — Scaffold a workspace.** From inside the folder where your shared workspace should live:

```bash
./scripts/new-workspace.sh --name "my-product-workspace"
```

That creates a workspace from `templates/workspace/`: a thin root `AGENTS.md`, a `CLAUDE.md` that imports it (`@AGENTS.md`), a `README.md`, and the standard `docs/` lanes. If you'd rather not run a script, copy `templates/workspace/` by hand; it works the same way.

**Step 4 — Fill in the boundaries.** Edit the new `AGENTS.md` to say what the workspace is, what doesn't belong, and where reusable procedures live. Keep it thin. This is the highest-leverage 20 minutes you'll spend.

**Step 5 — Add teammates.** Share the workspace (git or Google Drive; see [docs/collaboration-and-governance.md](docs/collaboration-and-governance.md)). Each teammate does Step 2 on their own machine. That's it: they now share your context.

**Step 6 — Grow when you feel the pain.** Add a Context Fabric profile when "which repo/system does this product touch?" keeps coming up. Add a skill when a procedure is worth reusing. Don't build these before you need them.

---

## 5. Working inside this kit

If you (or an agent) are editing the kit itself rather than using it, read [AGENTS.md](AGENTS.md) first. It defines two operating modes: **using the kit** to stand up a workspace, and **improving the kit** itself. They have different rules.

---

## 6. What to read next

- New PM, just want a workspace: [docs/phased-adoption.md](docs/phased-adoption.md) → [docs/local-setup.md](docs/local-setup.md) → scaffold.
- Want the architecture first: [docs/architecture.md](docs/architecture.md).
- Sharing with a team: [docs/collaboration-and-governance.md](docs/collaboration-and-governance.md).
- Ready for shared context: [docs/context-fabric.md](docs/context-fabric.md).
- Want to poke at a real one: open [reference/sandbox/](reference/sandbox/), a fully populated fictional workspace you can explore and run before building your own.
- Want to see it done for real: [reference/reference-implementation.md](reference/reference-implementation.md) and [reference/example-walkthrough.md](reference/example-walkthrough.md).
