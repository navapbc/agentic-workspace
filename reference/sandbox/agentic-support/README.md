# Agentic Support

This directory is the team's shared operating system for agent guidance, shared
facts, support mechanics, and validation. It serves every practice that shares
this workspace — product, engineering, design, delivery — and their agents. It
is root-level infrastructure, not a document lane and not one practice's folder.

Installed from the [Agentic Workspace Starter Kit](https://github.com/navapbc/agentic-workspace).
Every file here except `CONCEPTS.md` and `docs/context-source-ladder.md` is
generic: upgrade by re-running the kit's `scripts/install-support.sh`, and your
two authored files are left alone.

## The agentic stack

Every agent session in this workspace passes through the same layers, whatever
the practice and whatever the harness:

```text
  agent session — any harness, any practice
        │  opens with the member's declared roots
        ▼
  root guidance files ► tools/workspace-doctor.sh
  (boundaries,          (where am I, which capability
   routing,              tiers this session has)
   guardrails)
        ▼
  skills/skill-manifest.yaml ──► skills/<name>/SKILL.md
  (discovery + availability)     (canonical procedure: behavior lives here)
        ▼
  context-fabric/ ─────────────────────────── shared facts, not documents
    records/profiles ─► repositories · systems · local references
    generated projections: repo digests · routing card
        ▼
  tools/ (approved mechanics)  ·  validation/ (cross-system checks)
```

Authority runs top-down: active user instructions, then this support tree, then
the selected skill, then the relevant Context Fabric record and any lane-local
instructions. Lane guidance may narrow a rule here; it never duplicates a shared
procedure or a shared fact.

## How queries flow through this tree

What a session gains — or doesn't — from this tree, by the shape of the ask:

| A session asks… | Path through this tree | What the support layer buys |
| --- | --- | --- |
| "What does repo X do / where does Y live in it?" | generated digest under `context-fabric/records/generated/repo-digests/` | Answers without opening a checkout; works on machines with no git at all |
| A code-level question a digest can't answer | digest → hydrated checkout under the declared checkouts root | Read-only code evidence; sync guards keep checkouts out of the shared tree |
| System ownership, interfaces, access | `context-fabric/records/systems/` | Validated interface facts with explicit validation status, not folklore |
| A governed reference fact (policy, standard, catalog) | profile → its `reference:` resource → that source's own status check | A cited answer from a governed source instead of model memory |
| "Where does this artifact belong?" | `tools/route-artifact.sh`, judgment cases via the `artifact-routing` skill | Consistent placement across every practice's lanes |
| "Set up / repair my workspace" | the `workspace-setup` skill | Shared-drive access to doctor-green on macOS or Windows |
| "Refresh my checkouts" | the `repo-sync` skill + a reviewed sync manifest | Digest-bound preview/apply; fetch-only; placement guards |
| Writing product or practice synthesis | **Not here.** The owning product area or practice lane | This tree guides work; it never hosts it |
| A practice-specific workflow | **Not here.** That practice's own lane | Admission is crosscutting-only; one practice benefiting is not enough |
| Generic drafting with no workspace surface | **Mostly untouched.** Root guidance guardrails still apply | The stack costs nothing when a query needs none of it |

## Context Fabric architecture

`context-fabric/` is the shared-facts layer: small JSON records under a
versioned schema, not prose documents. Product profiles are the entry points,
and they are shared across practices — engineering, design, and delivery work
reuses the same product profiles rather than per-practice or per-person copies.

```text
  productProfile (records/profiles/)      ← entry point per product, all practices
    ├─ repositories ──► repositoryResource   lifecycle · syncability · stewardship
    ├─ systems ───────► systemResource       interfaces (api/cli/git/web) · validation status
    └─ references ────► localReferenceResource   consultation use · reliance checks
```

Its operating patterns:

- **Snapshot-first authoring.** Records are edited directly with no review gate,
  but always snapshot-first: `tools/snapshot-context-fabric-record.sh` archives
  the file and logs the change in `records/CHANGELOG.md`, making every edit
  visible and reversible even where sync, not review, is the distribution
  channel.
- **Schemas are steward-gated.** A bad record breaks one fact; a bad schema
  breaks validation for everything downstream. Talk to the Context Fabric
  steward before touching `schemas/`.
- **Records vs. projections.** Everything under `records/generated/` (repo
  digests, routing card) is derived by tools and regenerated, never hand-edited.
- **Consultable sources only.** A `localReferenceResource` is admitted only for
  a governed, cross-product reference source (a design-system standard, an
  architecture catalog, a runbook library). Broad containers, work-in-progress
  lanes, and operational capability never qualify — see
  [authoring guidance](context-fabric/docs/authoring.md).
- **Digest-bound mutation.** The only supported local mutation path is
  manifest-based checkout refresh: preview emits digests binding the manifest
  bytes and checkout root, and apply refuses when either changed. The Fabric
  itself is never mutated by sync.

## Boundaries

This system owns reusable agent capabilities, shared context records, support
mechanics, and validation. A capability lives here only when its value is core
and crosscutting across practices; practice-specific capability belongs in that
practice's own lane. It does not own product strategy, generic workspace
documents, cloned repositories, credentials, raw authenticated content,
dependency folders, or local agent settings.

## Start here

1. New machine? Run the [`workspace-setup`](skills/workspace-setup/SKILL.md) workflow first.
2. Select a capability from [`skills/skill-manifest.yaml`](skills/skill-manifest.yaml)
   and read that skill's canonical `SKILL.md` before acting.
3. Use [`context-fabric/`](context-fabric/README.md) for shared records, schemas,
   templates, and authoring guidance when the skill requires context.
4. Run [`tools/`](tools/) only when the selected skill authorizes the action.
5. Put resulting synthesis in its owning lane — never in this tree.

## Components

| Component | Purpose |
| --- | --- |
| `skills/` | Canonical, harness-neutral agent capability bundles. |
| `context-fabric/` | Records, schemas, templates, and authoring guidance. |
| `templates/` | Canonical guidance files instantiated per machine by setup. |
| `tools/` | Enabled reusable mechanics; `tools/paused/` preserves inactive stubs. |
| `validation/` | Cross-component checks that keep the structure honest. |
| `docs/` | Architecture, placement doctrine, contracts, and contribution guidance. |
| `CONCEPTS.md` | Shared workspace vocabulary. Team-authored. |

## Harness interpretation

Skills in this tree are plain markdown with a documented procedure, guardrails,
and output shape. Any capable harness — Codex, Claude Code, OpenCode, Cursor,
Gemini CLI — can execute them directly; `skills/adapters/` holds thin runtime
pointers only, never forked procedures. Nothing here depends on a specific model.
