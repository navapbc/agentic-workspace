---
purpose: How to author and change a Context Fabric record safely.
audience: Anyone adding a shared fact.
status: Active.
---

# Authoring records

## The loop

```sh
# 1. Snapshot and log, before you edit
../tools/snapshot-context-fabric-record.sh records/profiles/<slug>.json --why "<one line>"

# 2. Edit the record (copy a template if it is new)

# 3. Verify shape
../tools/snapshot-context-fabric-record.sh --verify records/profiles/<slug>.json

# 4. Run the full gate before you call it done
../validation/check-workspace.sh
```

Step 1 is not optional in a workspace shared over synced storage: there is no
review and no diff, so the snapshot and the changelog line *are* the safety net.

## Choosing a kind

Ask what the fact is *about*:

- About a **system** the team reaches into (a tracker, a wiki, a warehouse, a git
  host) → `systemResource`.
- About **one repository's identity** (where it is, is it active, can we reach it,
  do we sync it) → `repositoryResource`.
- About a **governed source we consult** but do not sync → `localReferenceResource`.
- About **a product's relationship** to any of the above → `productProfile`.

If the fact is really "how we do something", it is a skill, not a record. If it is
"where an artifact goes", it is routing. See
[../../docs/placement-doctrine.md](../../docs/placement-doctrine.md).

## Rules

- **Define once, reference many.** Create a repository or system record once; let
  many profiles reference it by `resourceId` / `systemId`. Never make a second
  record for the same thing — that is how two "true" answers appear.
- **Stable IDs.** Keep the namespaced ID stable for the life of the thing it
  describes; other records reference it. Renaming an ID is a migration, not an edit.
- **`contentLocations[0].path` is the record's own path** relative to
  `context-fabric/`. The lint fails on drift, which is how a copy-pasted record gets
  caught before it becomes a second source of truth.
- **No secrets, no absolute machine paths, no credentials in URLs.** Records are
  shared verbatim with every teammate. Both the schema and the lint reject them.
- **Record access guidance, never access.** "Request via the platform team's intake"
  is a fact. A token is a liability.
- **Validation is a claim about reality.** `validation.status: validated` asserts
  that a named person confirmed this against the real system on a date. Do not set
  it because the JSON parses.
- **`syncable: true` has preconditions:** lifecycle `active`, accessState
  `available`, and validation status `validated`. The lint enforces all three, so a
  repository nobody has confirmed cannot enter a sync manifest by way of a profile.

## Admitting a reference source

A `localReferenceResource` is for a **governed** cross-product source: it has its
own status registry, freshness dates, or validation reports, so a reader can check
whether a specific artifact is still safe to rely on.

Never admit a broad container (a whole shared drive), a work-in-progress lane, or an
operational capability. The test is `relianceCheck`: if you cannot say how a reader
verifies an artifact from this source, the source cannot be relied on, and pointing
agents at it makes their answers less trustworthy rather than more.

## Freshness

Stamp `updatedAt` on every change. For generated records, the tools stamp
`generated_at` and `do_not_rely_after`; a source past its `do_not_rely_after` date is
treated as **unavailable**, and the reader uses the declared alternate from
[the context-source ladder](../../docs/context-source-ladder.md) and says why.
