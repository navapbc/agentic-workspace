# Context Fabric

The shared-facts layer: small JSON records under a versioned schema, not prose
documents. It answers "what is true about our products, systems, and
repositories" once, so no session has to re-derive it and no document has to
restate it.

Records are edited directly, snapshot-first: archive the current file and log the
change with `../tools/snapshot-context-fabric-record.sh` before editing, verify
after (see [authoring guidance](docs/authoring.md)). `records/CHANGELOG.md` and
`records/archive/` are the audit and rollback surface.

## Entry path (any practice)

1. Start with [authoring guidance](docs/authoring.md) and the
   [profile template](templates/profile.template.json).
2. Find the relevant product profile in `records/profiles/` — profiles are
   product-scoped and shared across practices — then follow its repository,
   reference, and system relationships into `records/resources/` and
   `records/systems/`.
3. Use `schemas/workspace-context/1.0.0/schema.json` to understand record shape.

## Record kinds

| Kind | ID form | Lives in | What it holds |
|---|---|---|---|
| `systemResource` | `system:<slug>` | `records/systems/<slug>.json` | A shared system your products touch and how to reach it. No credentials. |
| `repositoryResource` | `repository:<org>/<repo>` | `records/resources/repositories/<org>/<repo>.json` | Identity and checkout facts for one repository. Defined **once**, even when many products use it. |
| `localReferenceResource` | `reference:<slug>` | `records/resources/local/<slug>.json` | A governed cross-product reference source the team consults but does not sync. |
| `productProfile` | `product:<slug>` | `records/profiles/<slug>.json` | A product's aliases, its relationships to systems/repos/references, its steward, and task guidance. This is what a product area's `AGENTS.md` declares. |

The central pattern: **define a repository or system once, then let many product
profiles express their own relationship to it** — which parts they use, when, at
what priority. That is what keeps one repository from acquiring five slightly
different descriptions.

## Records vs. projections

Everything under `records/generated/` is derived by tools and regenerated, never
hand-edited:

- `records/generated/repo-digests/` — per-repository summaries so repository
  questions can be answered with no git and no checkout.
- `records/generated/routing-card.md` — the one-page artifact-routing answer with
  registered exceptions applied.

## Sync manifests

The Fabric is reference context. Local checkout mutation uses reviewed sync
manifests under `records/sync-manifests/releases/` and the workflow in
`../skills/repo-sync/SKILL.md`.

Each manifest records product ID, version, review date, reviewer, catalog
references, repository URLs, and checkout directories. Preview emits
`manifestDigest` and `previewDigest`; apply requires `previewDigest`, which binds
the manifest bytes and the resolved checkout root, so an edit or a checkout-root
mix-up between preview and apply blocks the mutation. The Fabric itself is never
mutated by sync.

## Operating model

- **Snapshot-first authoring, no review gate.** Records change with
  `../tools/snapshot-context-fabric-record.sh` and are validated structurally with
  `../validation/check-workspace.sh`. The changelog and archive make every change
  visible and reversible. On a git-backed workspace, review and revert already do
  this; the changelog stays useful as a plain-language "what changed and why" for
  teammates who do not read git history.
- **Schemas are steward-gated.** A bad record breaks one fact; a bad schema breaks
  validation for everything downstream. Talk to the Context Fabric steward before
  changing anything under `schemas/`.
- **Dependency-free by design.** The lint is bash + jq. Nothing here requires a
  language runtime or an install step, so a teammate can author and check a record
  on a machine with no toolchain.
- **Never store** credentials, tokens, absolute machine paths, API definitions,
  live responses, or payloads. Record where a thing is and how to get access;
  never the access itself.
