---
purpose: The architecture overview for a shared agentic product workspace. Layers, the authority chain, record kinds, and how context resolves.
audience: PMs and technical leads who want to understand the model before adopting it.
status: Active.
last_updated: 2026-07-29
---

# Architecture Overview

This is the clear picture of how a shared agentic workspace is put together. It generalizes the internal reference implementation (see [../reference/reference-implementation.md](../reference/reference-implementation.md)).

The design has one goal: **an agent, working in any folder, on any tool, on any machine, can reliably resolve what's true, what's allowed, and how the team does things** — without a human re-explaining it.

---

## 0. The workspace is multi-root

Before the layers, the topology. A member's workspace is **several physical directories handed to the harness at once**, not one folder:

```
  shared workspace root                     machine-local roots
  (git clone, or synced storage)            (never synced)
  ├── AGENTS.md / CLAUDE.md                 ├── repo-checkouts/     ← git checkouts
  ├── agentic-support/   ← the engine       │   └── AGENTS.md (points back to the engine)
  ├── product-work/                         └── <personal working dir>  (optional)
  └── prototyping/
                    ▲                                    ▲
                    └──────── both declared in ───────────┘
                       ~/.agentic-workspace/workspace-descriptor.yaml
                       (per machine · never synced · declared, not derived)
```

Three rules make this work, and each one exists because the obvious alternative failed in practice:

- **Physical roots, not symlinks.** Harness file viewers and pickers do not display the contents of symlinked folders, so a root assembled from links is invisible exactly where members work — while shell tools and validators still report green.
- **Declared, not derived.** Each member declares their machine-local roots once; tools resolve from that declaration and **fail closed** when it is missing or stale. A tool that guesses from sibling directories is right on the machine it was written on and quietly wrong everywhere else.
- **Machine-local primary folder.** Harnesses write session state (permission grants, local overrides) under the session's primary folder. If that folder is synced, one member's personal settings reach the whole team — and deleting the file does not help, because the next session recreates it.

`agentic-support/tools/workspace-doctor.sh` reports, at session start, which roots this session actually has and which capability tiers are therefore available. The full model is in the engine's own `docs/workspace-routing.md` and `docs/skill-binding-contract.md`.

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
│   product-work/  one folder per product area (shared, in use)      │
│                  each declares ONE context-fabric profile          │
│   prototyping/   spikes, mockups, experiments                      │
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
- **Bridged for Claude Code.** `AGENTS.md` is the source-of-truth, cross-tool file, but Claude Code reads `CLAUDE.md`, not `AGENTS.md`. Add a `CLAUDE.md` that is a one-line `@AGENTS.md` import (not a copy), so there is nothing to keep in sync. (See [harness-and-model-agnostic.md](harness-and-model-agnostic.md).)

A good root `AGENTS.md` is often under 20 lines. See `../templates/workspace/AGENTS.md.template`.

---

## 4. The support layer: the engine you install

This is the reusable operating system. It is a **separate top-level folder** (`agentic-support/`). It owns reusable capabilities, shared context, support mechanics, and validation. It does **not** own product strategy, generic documents, code checkouts, credentials, or local tool settings.

You do not build it. The kit ships it whole in [`../templates/support/`](../templates/support/), and [`../scripts/install-support.sh`](../scripts/install-support.sh) installs or upgrades it:

```bash
./scripts/install-support.sh <workspace> --check   # see what would change
./scripts/install-support.sh <workspace>
```

**Every file installs verbatim except two you author yourself:** `CONCEPTS.md` (your vocabulary) and `docs/context-source-ladder.md` (your sources). That property is what makes upgrades possible — a team pulls a newer engine without re-merging their own work, and a locally modified generic file is reported as a conflict rather than silently overwritten.

### skills/
A skill is a written-down procedure an agent can follow. Each lives at `skills/<id>/SKILL.md` with YAML frontmatter and required sections (Procedure, Guardrails, Output Shape, Failure Handling, Harness Interpretation). `skill-manifest.yaml` is the availability authority, with `enabled` / `partially-paused` / `paused` — and a **required `review_by` date on anything paused**, so a pause is a decision with a deadline rather than an untracked gap. The doctor surfaces overdue reviews at session start.

The `SKILL.md` is the source of truth. Each harness that needs a different runtime artifact gets a **thin adapter** under `skills/<id>/adapters/<harness>/` that points back to it and never forks the procedure. `sync-skills.sh` mirrors skills into each harness's runtime directory and detects drift with `--check`.

Three skills ship enabled: `workspace-setup` (interviews a new member from folder access to doctor-green), `artifact-routing` (the judgment cases the routing tool cannot decide), and `repo-sync` (digest-bound checkout hydration).

### context-fabric/
A schema-governed catalog of small, reviewable JSON records describing shared facts. Four record kinds:

| Kind | ID form | What it holds |
|---|---|---|
| **system resource** | `system:<slug>` | A shared system your products touch (a git host, a tracker, a warehouse) and how to reach it. Access *guidance*, never credentials. |
| **repository resource** | `repository:<org>/<repo>` | Identity and checkout facts for one code repo. Defined **once**, even when many products use it. |
| **local reference resource** | `reference:<slug>` | A governed cross-product source the team consults but does not sync. Must answer "how does a reader verify an artifact from here?" |
| **product profile** | `product:<slug>` | A product's aliases, its relationships to systems/repos/references, its steward, and task guidance. This is what a product-area `AGENTS.md` declares. |

The central pattern: **define a repo or system once, then let many product profiles express their own relationship to it** (which parts they use, when, at what priority). The schema enforces closed shapes and stable IDs, and *rejects secrets, credentialed URLs, and absolute machine paths*, so records stay safe to share. See [context-fabric.md](context-fabric.md).

Records under `records/generated/` are **projections**, not records: repo digests and the routing card are regenerated by tools and never hand-edited.

### tools/
Plain shell (`set -euo pipefail`), driven by explicit CLI arguments, invoked **by skills** rather than free-floating, and dependency-free beyond `git` and `jq` so they run on a machine with no toolchain:

| Tool | What it buys |
|---|---|
| `workspace-doctor.sh` | Session-start orientation and capability tiers. Read-only. |
| `generate-workspace-descriptor.sh` | The declaration, with guards against nesting, duplicates, narrowing re-runs, and a checkout root inside the shared tree. |
| `generate-repo-digests.sh` | Repository answers for teammates with no git and agents with no checkout. |
| `refresh-manifest-repos.sh` | Digest-bound preview→apply; fetch and fast-forward only, never pushes. |
| `route-artifact.sh` | The same placement answer for every teammate, with typed exceptions. |
| `snapshot-context-fabric-record.sh` | Snapshot + changelog before an edit — the safety net where there is no review gate. |
| `lint-context-fabric-records.sh` | Field-level record rules, including the syncability preconditions. |
| `scaffold-product-area.sh` | A compliant, registered product area in one command. |

### validation/
`check-workspace.sh` is the gate: manifest↔skill consistency, the skill contract, no user-home paths, no sibling-relative cross-root references, thin `AGENTS.md`, no secrets or leaked checkouts, JSON and record lint, `shellcheck`, and the component test suites in `validation/test/`. This is what keeps the model from rotting. The kit also ships a lighter, dependency-free `../scripts/validate-workspace.sh` for Crawl-phase workspaces with no engine installed yet.

---

## 5. The product-work layer: product work vs. prototyping

Two lanes, named by intent:

- **Product work** (`product-work/`, or whatever your team names it): the work the team relies on and shares. One folder per product area, each declaring its Context Fabric profile, with the team's chosen docs lanes.
- **Prototyping** (`prototyping/`): spikes, mockups, experiments. May contain runnable code and extra lanes. Has no assigned profile; it borrows the product-work Context Fabric when it needs context. Promotion into product work is an intentional move, not a drag-and-drop.

The split is by **location and intent** — "does the team rely on this, or am I still figuring it out?" How much review, ownership, or status labeling to attach to the product-work lane is a team choice, not a fixed rule. See [collaboration-and-governance.md](collaboration-and-governance.md).

---

## 6. Context that compounds across sessions

The model separates context by **load cost**, because anything auto-loaded is paid for in every session:

| Tier | Where | Loaded |
|---|---|---|
| Always-loaded, tiny | `AGENTS.md` files, `CONCEPTS.md` | Every session. Kept thin on purpose; the gate enforces it. |
| Load-on-demand | `skills/`, `context-fabric/` records, `docs/solutions/` | Only when the task needs them. Can grow without bound. |
| Audit-only | `records/CHANGELOG.md`, `records/archive/` | Never auto-loaded. Read when reconstructing a decision. |

Two accreting lanes ship with the engine:

- **`docs/solutions/<category>/<slug>.md`** — one file per durable learning (a bug with a non-obvious cause, a workflow trap, a pattern worth reusing), with frontmatter so an agent can judge relevance before reading the body. Load-on-demand, so it costs nothing until it is needed. The engine seeds three real ones that explain why the workspace pattern is shaped the way it is.
- **`CONCEPTS.md`** — the glossary. Always-loaded, so entries stay to a few sentences and detail moves into a solutions file or a record.

**The kit still does not prescribe an auto-loaded prompt log.** An append-everything log is the exact opposite of the cost ordering above: it grows without bound in the tier you pay for every time. Use your harness's own memory feature for session continuity, and keep unbounded logs out of the always-loaded tier.

---

## 7. How context actually flows (a concrete trace)

A PM opens their tool in `product-work/my-product/` and asks the agent to draft a spec.

1. The tool loads the nearest `AGENTS.md` (and `CLAUDE.md` if it's Claude Code). It reads: this is the My-Product area; boundaries X, Y; `Context Fabric profile: product:my-product`; reusable procedures live in the support layer.
2. The agent resolves `product:my-product` in the Context Fabric. It learns the product's aliases, which systems and repos it touches (and which parts), the vocabulary, and the steward.
3. If the task matches a skill (say, a spec-drafting procedure), the agent reads that skill's `SKILL.md` and follows it.
4. The agent produces the artifact in the correct docs lane, honoring the boundaries, without a human having restated any of it.

Every fact the agent used was written down once and referenced, not repeated. That is the whole architecture.

---

## 8. Two design decisions the kit makes explicit

The internal reference implementation surfaced two ambiguities worth resolving up front in any new workspace:

- **One source of truth.** Skills and Context Fabric records live in the support layer, full stop. Anything in a product folder that looks like shared context is a *pointer* to the support layer, clearly labeled as such. Do not maintain two "active" copies.
- **One sharing mechanism, chosen on purpose.** Decide git-backed or synced-storage sharing per team and per phase, and write it down in the workspace README. Do not wire up both halfway. The kit recommends synced storage for Crawl (low friction, no terminal) and git for the support layer at Run (versioned, drift-checkable). The choice changes the *safety model*, not just the plumbing: git gives you review and revert, while synced storage makes sync itself the distribution channel — which is why snapshot-first record editing and the "no member-specific harness state in the shared tree" rule exist. See [collaboration-and-governance.md](collaboration-and-governance.md).
- **No machine paths in shared files.** Per-machine locations live in one machine-local declaration and are referenced by binding token everywhere else. This is what lets the same workspace work for a teammate who organizes their disk differently — which is every teammate.
