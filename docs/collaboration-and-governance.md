---
purpose: How multiple PMs share a workspace safely. Canonical vs. prototype, the review gate, stewardship, and git-vs-Drive sharing.
audience: PMs setting up multi-person collaboration in a shared agentic workspace.
status: Active.
last_updated: 2026-07-22
---

# Collaboration and Governance

A shared workspace only stays trustworthy if everyone knows what is reviewed and safe to rely on, who owns each product area, and how the workspace is shared. This page defines all three.

---

## The two lanes

Every workspace splits product work into two lanes, governed by a short root charter (the root `AGENTS.md`):

| | Canonical | Prototyping |
|---|---|---|
| Location | `canonical/` (or `product-work/`) | `prototyping/` (or `local-solutions-prototyping/`) |
| Status | Reviewed, source-of-truth, shareable **after human review** | Exploratory, pre-review |
| Context Fabric | Each area declares one `product:` profile | No assigned profile; borrows the canonical catalog |
| Contents | Strategy, deliverables, reference, extractions | Spikes, mockups, runnable experiments, `.pen` files |
| Extra lanes | Standard Docs lanes only | May use `docs/brainstorms/`, `docs/prototypes/`, apps |

The lanes are the spine of the model. Keeping them separate is what lets a team move fast in prototyping without polluting the source of truth.

---

## What makes something "canonical"

Canonical is defined by **lane + review gate + named steward**, not by location alone:

1. It lives in the canonical lane.
2. It has passed **human review** (a peer or lead outside the immediate work).
3. It has a named steward who owns that area.

Until all three hold, treat an artifact as draft, even if it sits in the canonical folder. Say so explicitly in the file's frontmatter (`status:`).

### Promotion from prototype to canonical
Promotion is an intentional, gated step. When a prototype concept becomes a real product area, run the product-area onboarding flow (a skill at Run phase, or the checklist in [phased-adoption.md](phased-adoption.md)): create the canonical folder, write its thin `AGENTS.md`, create its Context Fabric profile, assign a steward, and move only the intended artifacts. Do not treat the prototyping folder as a source of truth.

---

## Stewardship

- **One steward per product area.** Recorded in the profile's `maintainers` (with `role: product steward`) and in a stewardship summary table at the product-work root.
- **Stewards own their sections.** They keep the area's `AGENTS.md`, profile, and canonical artifacts current, and are the human review gate for their area.
- **Domain review panels** where correctness matters. Two forms:
  - *Expert review panel*: 5-6 role personas (with priorities and challenge patterns) that an agent can adopt sequentially to critique an artifact, plus human advisors for high-stakes work.
  - *Representative user panel*: personas standing in for the people who will live with the product.
  Disagreements between personas surface real trade-offs. This mirrors the Make-or-Buy expert-panel pattern.

---

## Sharing mechanism: git vs. Google Drive

Decide this per team and per phase, and write it down. **Do not wire up both halfway** — a common source of drift.

| | Google Drive | Git |
|---|---|---|
| Friction for non-engineers | Low | Medium |
| Versioning / history | Weak | Strong |
| Drift detection / CI | No | Yes |
| Merge conflicts | Silent, painful | Explicit, resolvable |
| Best for | Crawl phase; product-work lanes; PMs who don't use git | The support layer; Run phase; anything validated |

**Recommendation:**

- **Crawl:** Drive. Lowest friction, gets the team sharing context immediately.
- **Walk:** Drive is fine; move the support layer to git if you want drift checks on skills.
- **Run:** git-backed support layer with `validate-workspace.sh` in CI. Product-work lanes can stay on Drive if your PMs prefer it.

Whichever you choose, the safety invariants below are mandatory.

---

## Safety invariants (never negotiable)

These hold in every lane, on every machine, under any sharing mechanism. `scripts/validate-workspace.sh` checks them.

- **No credentials.** No PATs, tokens, `.env`, `op://` URIs, vault IDs, or raw authenticated responses. Inject secrets at runtime; never store them.
- **No code checkouts inside the workspace.** Cloned repos live outside, referenced by path.
- **No OS metadata or dependency folders** (`.DS_Store`, `Icon`, `node_modules`).
- **No absolute machine paths in shared files.** Use bindings.
- **Client-sensitive, hiring, internal-only, or business-development material is gated.** Ask before moving, summarizing, or sharing it. This follows the workspace's root authority boundary.

---

## Review checklist before you share anything canonical

- [ ] It's in the canonical lane and its frontmatter `status:` reflects reality.
- [ ] A human other than the author has reviewed it.
- [ ] It contains no credentials, no absolute paths, no client-sensitive material that isn't cleared.
- [ ] It references shared facts (Context Fabric, skills) rather than restating them.
- [ ] `validate-workspace.sh` passes (Walk/Run).
