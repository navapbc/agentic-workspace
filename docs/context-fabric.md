---
purpose: What the Context Fabric is, when a team needs it, the three record kinds, and how to author records safely.
audience: PMs at Walk/Run phase ready to make product context machine-readable.
status: Active.
last_updated: 2026-07-22
---

# The Context Fabric

The Context Fabric is a small, schema-governed catalog of shared facts about your products, the systems they touch, and the code repositories that back them. It is how an agent knows "which repo, which system, whose product, what vocabulary" without a human explaining it.

You do **not** need it at Crawl. Add it when "which system or repo does this product touch?" keeps coming up, or when a second product area needs to reference the same system without copying its details.

---

## The central idea

**Define each shared thing once. Let many products express their own relationship to it.**

A system (say, your GitHub org) is described in exactly one record. A repository is described in exactly one record, even if five products use it. Then each product's *profile* references those records and layers on product-specific meaning: which parts it uses, when, at what priority, and who stewards it.

This is what stops the copy-paste drift where every product folder has a slightly different, slightly stale description of the same repo.

---

## The three record kinds

| Kind | ID form | Holds | Deliberately excludes |
|---|---|---|---|
| **System resource** | `system:<slug>` | A shared system and how to reach it (a git host, an issue tracker, a wiki, a data warehouse), stable interface metadata | Credentials, product ownership, maintainers |
| **Repository resource** | `repository:<org>/<repo>` | Identity and checkout facts of one repo: lifecycle, access state, whether it's syncable, provenance | Product-specific meaning (that lives in profiles) |
| **Product profile** | `product:<slug>` | A product's aliases, its relationships to systems and repos, stewards, anchors, task guidance | Anything that belongs to a shared system/repo |

Templates for all of them are in `../templates/support/context-fabric/templates/`, and land in your workspace at `agentic-support/context-fabric/templates/`.

### What a profile looks like (conceptually)

A `product:my-product` profile:

- names the product and its steward,
- lists the **systems** it uses by `systemId`, with validated **anchors** (for example, the exact tracker project key or wiki page ID that is the product's home),
- lists the **repositories** it uses by `resourceId`, each tagged with:
  - `selectionTier`: `primary` | `supporting` | `conditional`
  - `coverage`: `direct` (the product's own code) | `reference` (consulted, not owned)
  - `useWhen`: the trigger that makes this repo relevant to a task,
- adds profile-local **aliases** (friendly names for repos),
- carries `provenance` and `validation` timestamps on entries, and
- includes `taskGuidance` telling an agent where synthesis for this product belongs.

A product-area `AGENTS.md` connects to all of this with one line: `Context Fabric profile: product:my-product`.

---

## The schema and its guardrails

Records validate against a JSON Schema (Draft 2020-12). The schema is not bureaucracy; it enforces the properties that keep the catalog safe and consistent:

- **Closed shapes** (`additionalProperties: false`) so typos and stray fields are caught.
- **Stable, namespaced IDs** (`system:`, `repository:`, `product:`) so references never break.
- **A single schema version** and an ISO `updatedAt` on records.
- **A text rule that rejects secrets and absolute machine paths.** It refuses values that look like tokens (`ghp_...`, `Bearer ...`, `password=`) or machine paths (`/Users/`, `~/`, drive letters), and URLs with embedded credentials. This is what makes records safe to commit and share.

A starter schema and the design rationale (why it borrows stable-identifier and closed-shape discipline without adopting any heavyweight standard wholesale) are documented in the internal reference implementation; see [../reference/reference-implementation.md](../reference/reference-implementation.md).

---

## Authoring a profile (the workflow)

1. Copy the relevant templates from `agentic-support/context-fabric/templates/`.
2. Create or reuse the `system:` records for systems the product touches.
3. Create or reuse the `repository:` records for its repos. **Reuse** if the repo already has one; do not make a second.
4. Create the `product:` profile that references those records and adds the product-specific tiers, coverage, aliases, anchors, and steward.
5. Declare the profile in the product area's `AGENTS.md`.
6. Validate (Run phase): run your schema validator, or at minimum `jq empty` over every record to confirm it parses, plus `scripts/validate-workspace.sh`.

---

## Operational vs. reference records

Keep two things separate:

- The **catalog** (systems, repositories, profiles) is *reference*: what exists and how products relate to it.
- A **sync manifest** is *operational*: the reviewed list of repos to actually check out locally, with `reviewedBy`, a version, and checkout directories. Tools consume the manifest; the catalog documents the world.

Don't conflate them. The catalog rarely changes; manifests are versioned per release.

---

## The pause/enable status field

The Context Fabric machinery (schema validators, profile-selection scripts, CI) can be built ahead of use and marked deferred. Records and profiles carry a status so you can ship the structure and navigate it manually while the automation matures. This lets a team adopt the *shape* of shared context before investing in the tooling around it. Use it: a `paused` selector script with hand-navigated records is a legitimate, useful Walk-phase state.
