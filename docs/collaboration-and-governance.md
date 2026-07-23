---
purpose: How multiple PMs share a workspace safely. The two lanes, optional review and ownership practices, and how to set up git or Google Drive sharing.
audience: PMs setting up multi-person collaboration in a shared agentic workspace.
status: Active.
last_updated: 2026-07-22
---

# Collaboration and Governance

A shared workspace stays trustworthy when teammates know three things: where finished-enough work lives versus experiments, how the workspace is shared, and (if the team wants it) who reviews or owns what. This page covers all three. The safety invariants at the bottom are mandatory; everything else is a choice your team makes and writes down.

---

## The two lanes

Every workspace splits product work into two lanes:

| | Product work | Prototyping |
|---|---|---|
| Location | `product-work/` (rename to suit your team) | `prototyping/` |
| Intent | Work the team relies on and shares | Exploratory, in-progress, throwaway |
| Context Fabric | Each area declares one `product:` profile | No assigned profile; borrows the product-work catalog |
| Contents | Strategy, deliverables, reference, extractions | Spikes, mockups, runnable experiments, `.pen` files |
| Extra lanes | The team's chosen docs lanes | May also use `brainstorms/`, `prototypes/`, apps |

The lanes are the spine of the model. Keeping them separate is what lets a team move fast in prototyping without muddying the work everyone depends on. The distinction is **location and intent** — "is this something the team relies on, or something I'm still figuring out?" — not a formal certification. Name the lanes whatever your team prefers; just keep the split.

---

## Optional: review, ownership, and status

How much process to attach to the product-work lane is a **team choice**. A two-person Crawl team may need none of this; a large multi-product team at Run usually wants some. Adopt only what earns its keep, and record what you chose in the workspace `README.md`.

- **Review before sharing.** Some teams have a peer or lead look at product-work artifacts before they are relied on or shared outside the team. Useful where correctness matters (policy, compliance, external-facing content); overkill for internal working notes. Decide per team, or per artifact type.
- **Named owners.** Assigning one person per product area (recorded in the profile's `maintainers` and, if you like, a summary table at the product-work root) helps a bigger team know who keeps an area current. A small team can skip it.
- **Status labels.** If it helps readers tell a draft from settled work, add a `status:` line to a doc's front matter (`draft` / `active`, or your own vocabulary). This is a convenience, not a requirement — do not gate work on labeling every file.
- **Review personas** (optional, for high-stakes work). An agent can critique an artifact from a few role angles (for example plain-language, accessibility, policy-accuracy) before a human signs off.

Promotion from prototyping to product work is an intentional move, not a drag-and-drop: create the product-area folder, write its thin `AGENTS.md`, create its Context Fabric profile, and move only the intended artifacts. Whatever review or ownership practices your team adopts apply at that point.

---

## Sharing mechanism: git vs. Google Drive

Decide this per team and per phase, and write it down. **Do not wire up both halfway** — that is a common source of drift.

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

### Setting up Google Drive sharing

The goal is that every teammate has the *same workspace folder* available as a real local path their agent tool can read, kept in sync automatically.

**1. Create the workspace on a Shared Drive, not a personal My Drive.** A Shared Drive is owned by the team, so the workspace survives anyone leaving. In Google Drive, create (or ask an admin for) a Shared Drive such as `Agentic Workspaces`, then a folder inside it for this workspace, e.g. `benefits-notices-workspace/`.

**2. Put the workspace at the root of that folder.** The folder's contents are the workspace root — the same layout `new-workspace.sh` produces:

```
benefits-notices-workspace/        <- the Shared Drive folder = workspace root
├─ AGENTS.md
├─ CLAUDE.md                        (one line: @AGENTS.md)
├─ README.md
├─ bindings.env.template            (commit the template only, never a filled-in bindings.env)
├─ product-work/
├─ prototyping/
├─ docs/
└─ agentic-support/                 (Walk phase and up)
```

Scaffold locally first, then move the folder into the Shared Drive (or run `new-workspace.sh --dir` pointed at your synced Drive path). Do not scaffold two copies.

**3. Each teammate installs Google Drive for Desktop and adds the Shared Drive.** This gives them a local path like `~/Library/CloudStorage/GoogleDrive-you@nava/Shared drives/Agentic Workspaces/benefits-notices-workspace` (macOS) or `G:\Shared drives\...` (Windows).

**4. Make the workspace available offline (mirrored), not stream-only.** Agent tools need to read real files, not on-demand placeholders. In Drive for Desktop, set the workspace folder to **Available offline** (right-click → Offline access → Available offline) so it is mirrored to disk.

**5. Point the harness and bindings at that local path.** Open the synced folder in your agent tool (see [local-setup.md](local-setup.md)). Copy `bindings.env.template` to `bindings.env` and set `WORKSPACE_ROOT` to your machine's Drive path. `bindings.env` is per-machine — never commit it into the shared folder.

**6. Use the `@AGENTS.md` import for `CLAUDE.md`, not a symlink.** Symlinks do not survive Drive sync or Windows; the one-line `@AGENTS.md` import does. `new-workspace.sh` already creates it this way.

**Drive gotchas:**
- Simultaneous edits to the same file surface as duplicate "conflicted copy" files, not a merge. Coordinate edits to shared files, or move the support layer to git.
- `.DS_Store` and `Icon` files can appear; the safety invariants forbid them and `validate-workspace.sh` catches them.
- There is no history or CI. If you need either, put that part of the workspace in git.

### Setting up git sharing

Initialize the workspace (or just the support layer) as a git repo, push it to your team's host, and have each teammate clone it to a local path outside any cloud-synced folder. Point the harness and `bindings.env` at the clone. At Run phase, add `scripts/validate-workspace.sh` as a CI check so the invariants are enforced on every change. Keep code checkouts out of the repo — reference them by path via bindings.

---

## Safety invariants (never negotiable)

These hold in every lane, on every machine, under any sharing mechanism. `scripts/validate-workspace.sh` checks them.

- **No credentials.** No PATs, tokens, `.env`, `op://` URIs, vault IDs, or raw authenticated responses. Inject secrets at runtime; never store them.
- **No code checkouts inside the workspace.** Cloned repos live outside, referenced by path.
- **No OS metadata or dependency folders** (`.DS_Store`, `Icon`, `node_modules`).
- **No absolute machine paths in shared files.** Use bindings.
- **Client-sensitive, hiring, internal-only, or business-development material is gated.** Ask before moving, summarizing, or sharing it. This follows the workspace's root authority boundary.

---

## A quick check before you share product work

Not a required gate — a short sanity pass:

- [ ] It's in the product-work lane, and any status label you use reflects reality.
- [ ] If your team reviews before sharing, that has happened.
- [ ] It contains no credentials, no absolute paths, and no client-sensitive material that isn't cleared.
- [ ] It references shared facts (Context Fabric, skills) rather than restating them.
- [ ] `validate-workspace.sh` passes (Walk/Run).
