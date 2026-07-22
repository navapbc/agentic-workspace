---
purpose: The architecture overview for a shared agentic product workspace. Layers, the authority chain, record kinds, and how context resolves.
audience: PMs and technical leads who want to understand the model before adopting it.
status: Active.
last_updated: 2026-07-22
---

# Architecture Overview

This is the clear picture of how a shared agentic workspace is put together. It generalizes the internal reference implementation (see [../reference/reference-implementation.md](../reference/reference-implementation.md)).

The design has one goal: **an agent, working in any folder, on any tool, on any machine, can reliably resolve what's true, what's allowed, and how the team does things** — without a human re-explaining it.

---

## 1. The three layers

```
┌──────────────────────────────────────────────────────────────────┐
│  GUIDANCE LAYER  —  thin AGENTS.md (+ CLAUDE.md @import) per folder │
│  "What is this folder? What doesn't belong? Where do procedures    │
│   and shared facts live?"  Boundaries and routing only.            │
└───────────────┬────────────────────────────────────────────────────┘
                │ points to
                ▼
┌──────────────────────────────────────────────────────────────────┐
│  SUPPORT LAYER  —  the reusable "operating system"                 │
│                                                                    │
│   skills/            reusable procedures (SKILL.md), authored once │
│                      + thin per-harness adapters                   │
│   context-fabric/    machine-readable shared facts (JSON records)  │
│   tools/             approved mechanics (shell), run only by skills │
│   validation/        checks that keep the structure honest         │
└───────────────┬────────────────────────────────────────────────────┘
                │ referenced by
                ▼
┌──────────────────────────────────────────────────────────────────┐
│  PRODUCT-WORK LAYER  —  the actual artifacts                       │
│                                                                    │
│   canonical/     one folder per product area (reviewed, shareable) │
│                  each declares ONE context-fabric profile          │
│   prototyping/   spikes, mockups, experiments (pre-review)         │
└──────────────────────────────────────────────────────────────────┘
```

The layers are deliberately **separate directories**, not one blended folder. The support layer is the "operating system"; the product-work layer is what runs on top of it. Keeping them apart is what lets many product areas share one set of skills and one context catalog.

At Crawl phase you only have the guidance layer and a product-work folder. The support layer appears at Walk/Run. See [phased-adoption.md](phased-adoption.md).

---

## 2. The authority chain

When an agent needs to decide how to act, it resolves context in this fixed order. Later, more-specific sources refine earlier ones; they must never contradict them silently.

```
1. Active user instructions (this session's prompt)
2. Support-layer guidance (the operating-system README + root AGENTS.md)
3. The selected skill (the written-down procedure for this task)
4. The relevant Context Fabric record + the product-local AGENTS.md
```

Put plainly: **skills define behavior, Context Fabric defines shared records, tools perform approved mechanics, and validation checks their integration.** The guidance layer routes; it does not carry the procedures itself.

This is why the guidance files stay thin. If a boundary or procedure is written in five `AGENTS.md` files, it drifts. Written once in a skill or a Context Fabric record and *referenced*, it stays consistent.

---

## 3. The guidance layer: thin AGENTS.md, one per folder

Every folder that needs boundaries gets an `AGENTS.md`. Rules:

- **Thin.** Directory-specific boundaries, routing, and exceptions only. No copied procedures, no duplicated facts.
- **Cascading.** Root sets the authority boundary. Each child narrows it. The nearest, most-specific file wins for local decisions, unless it conflicts with a higher authority boundary.
- **Profile-declaring.** A product-area `AGENTS.md` declares exactly one Context Fabric profile at the top, e.g. `Context Fabric profile: product:my-product`. That one line connects the folder to its shared facts.
- **Bridged for Claude Code.** `AGENTS.md` is the canonical, cross-tool file, but Claude Code reads `CLAUDE.md`, not `AGENTS.md`. Add a `CLAUDE.md` that is a one-line `@AGENTS.md` import (not a copy), so there is nothing to keep in sync. (See [harness-and-model-agnostic.md](harness-and-model-agnostic.md).)

A good root `AGENTS.md` is often under 20 lines. See `../templates/workspace/AGENTS.md.template`.

---

## 4. The support layer: skills, context fabric, tools, validation

This is the reusable operating system. It is a **separate top-level folder** (for example, `agentic-support/`). It owns reusable capabilities, shared context, support mechanics, and validation. It does **not** own product strategy, generic documents, code checkouts, credentials, or local tool settings.

### skills/
A skill is a written-down procedure an agent can follow: role intake, a policy extraction, an onboarding flow. Each lives at `skills/<name>/SKILL.md` with YAML frontmatter and standard sections (Triggers, Required Context, Procedure, Guardrails, Output Shape). A `skill-manifest.yaml` indexes them with a `status` field (`enabled` / `paused`) so you can ship the structure before every skill is finished.

The canonical `SKILL.md` is the source of truth. Each tool gets a **thin adapter** under `skills/<name>/adapters/<harness>/` that points back to it and never forks the procedure. A sync script mirrors skills into each tool's runtime directory. See [context-fabric.md](context-fabric.md) and `../templates/skills/`.

### context-fabric/
A schema-governed catalog of small, reviewable JSON records describing shared facts. Three record kinds:

| Kind | ID form | What it holds |
|---|---|---|
| **system resource** | `system:<slug>` | A shared system your products touch (a GitHub org, a Jira, a data warehouse) and how to reach it. No credentials. |
| **repository resource** | `repository:<org>/<repo>` | Identity and checkout facts for one code repo. Defined **once**, even when many products use it. |
| **product profile** | `product:<slug>` | A product's aliases, its relationships to systems and repos, its steward, and task guidance. This is what a product-area `AGENTS.md` declares. |

The central pattern: **define a repo or system once, then let many product profiles express their own relationship to it** (which parts they use, when, at what priority). The schema enforces closed shapes, stable IDs, and a text rule that *rejects secrets and absolute machine paths*, so records stay safe to share. See [context-fabric.md](context-fabric.md).

### tools/
Plain shell scripts (`set -euo pipefail`) that perform approved mechanics, such as materializing checkouts from a reviewed manifest. They are driven by explicit CLI arguments, invoked **by skills** (never free-floating), and safeguard against mistakes (for example, requiring a digest that binds a preview to its apply step, and redacting credentials from output). Harness-agnostic by construction.

### validation/
A script that checks the invariants after any structural change: every skill in the manifest resolves to a real file, required infra files exist, no secrets are present, no code checkouts or OS metadata leak in, and every JSON record parses. This is what keeps the model from rotting. The kit ships a generalized version at `../scripts/validate-workspace.sh`.

---

## 5. The product-work layer: canonical vs. prototype

Two lanes, governed by a short root charter:

- **Canonical** (`canonical/` or `product-work/`): reviewed, source-of-truth, collaboration-ready **after human review**. One folder per product area, each declaring its Context Fabric profile, with standard Docs lanes.
- **Prototyping** (`prototyping/` or `local-solutions-prototyping/`): spikes, mockups, experiments. May contain runnable code and lanes forbidden in canonical work. Has no assigned profile; it borrows the canonical Context Fabric when it needs context. Promotion into canonical is an intentional, gated step, not a drag-and-drop.

"Canonical" is defined by **lane + review gate + named steward**, not by location alone. See [collaboration-and-governance.md](collaboration-and-governance.md).

---

## 6. Persistent context across sessions (deferred)

Workspaces that run many sessions will eventually want context to survive across sessions and PMs. The internal reference implementation does this with a memory loop (`MEMORY.md` index + `memory/*.md`, plus `PROMPT_LOG.md` and `TASKS.md`) — see the reference implementation.

**The kit intentionally does not prescribe a persistent-context model yet.** The append-everything variant (especially a full prompt log) is token-inefficient for mature projects: anything an agent auto-loads each session must stay tiny, while durable records and audit logs should be loaded on demand or not at all. A token-aware model that separates "always-loaded (tiny)" from "load-on-demand" from "audit-only (never auto-loaded)" is a deliberate future addition, not part of this version. Teams that need session memory today can adopt their harness's own memory feature or a thin, hand-curated `MEMORY.md` index, and should avoid auto-loading unbounded logs.

---

## 7. How context actually flows (a concrete trace)

A PM opens their tool in `canonical/my-product/` and asks the agent to draft a spec.

1. The tool loads the nearest `AGENTS.md` (and `CLAUDE.md` if it's Claude Code). It reads: this is the My-Product area; boundaries X, Y; `Context Fabric profile: product:my-product`; reusable procedures live in the support layer.
2. The agent resolves `product:my-product` in the Context Fabric. It learns the product's aliases, which systems and repos it touches (and which parts), the vocabulary, and the steward.
3. If the task matches a skill (say, a spec-drafting procedure), the agent reads that skill's canonical `SKILL.md` and follows it.
4. The agent produces the artifact in the correct docs lane, honoring the boundaries, without a human having restated any of it.

Every fact the agent used was written down once and referenced, not repeated. That is the whole architecture.

---

## 8. Two design decisions the kit makes explicit

The internal reference implementation surfaced two ambiguities worth resolving up front in any new workspace:

- **One source of truth.** Canonical skills and Context Fabric records live in the support layer, full stop. Anything in a product folder that looks like shared context is a *pointer* to the support layer, clearly labeled as such. Do not maintain two "active" copies.
- **One sharing mechanism, chosen on purpose.** Decide git-backed or Drive-backed sharing per team and per phase, and write it down. Do not wire up both halfway. The kit recommends Drive for Crawl (low friction) and git for the support layer at Run (versioned, drift-checkable). See [collaboration-and-governance.md](collaboration-and-governance.md).
