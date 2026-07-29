---
purpose: Which source to consult first for a given question in the BN workspace.
audience: Every agent session; maintained by the BN steward.
status: Active (fictional example).
---

# Context-source ladder

One of the two files a team authors itself. The compact version lives in the workspace
root `AGENTS.md`; this page carries the reasoning and the degraded paths.

A **primary**, a **declared alternate**, and a **reserve discipline**. Improvised
fallbacks — broad scans, neighboring checkouts, unscoped searches — are what turn a cheap
question into an expensive session, so every branch names its alternate up front.

## The ladder

| Question class | Primary | Declared alternate |
|---|---|---|
| Repo purpose or layout | Repo digests (`context-fabric/records/generated/repo-digests/`) | Hydrated checkout under `${AGENTIC_REPO_CHECKOUT_ROOT}/` |
| Code-level detail (rendering, delivery logic) | Hydrated checkout, hydrated via the reviewed sync manifest | Digest for orientation, plus an explicit note that checkout inspection is needed |
| Which system owns a fact, and how to reach it | Context Fabric `records/systems/` | Ask the named system owner |
| Current notice content | The template set for that notice ID | Ask the BN steward; do not reconstruct notice text from memory |
| Upstream determination event shape | `repository:example-gov/eligibility-events` (reference coverage) | Ask the Eligibility Platform owner |
| BN decision history | `product-work/benefits-notices/docs/` lanes | Ask the BN steward |
| Open BN work items | The Notices Tracker, only when the doctor reports the credential loaded | Ask the user to paste the item; never guess at ticket contents |
| External / current-events context | Web search with citations | — |

## Reserve discipline (token budget)

- Load the specific record, digest, or file section that answers the question — never a
  whole bundle, catalog, or repository tree.
- Prefer generated summaries over raw sources for orientation-level questions; drop to
  raw sources only for detail the summary cannot carry.
- Inspect before reading in full: listings, manifests, and frontmatter first.
- A source past its `do_not_rely_after` date is **unavailable**: use the declared
  alternate and say why.

## Maintenance

Add a row when a source class appears or retires, and update the compact copy in the root
`AGENTS.md` in the same change. The two must not drift.
