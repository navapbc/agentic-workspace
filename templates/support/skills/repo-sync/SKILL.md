---
workflow_id: repo-sync
version: 1
status: enabled
owner: workspace stewardship
source_of_truth: true
portable_across_harnesses: true
---

# Repo Sync Workflow

Hydrate or refresh the member's machine-local checkouts from a reviewed sync
manifest, then regenerate the shared repo digests so the rest of the team can answer
repository questions without git.

Two-step by design: **preview, then apply with the digest preview emitted.** The
digest binds the manifest bytes to the resolved checkout root, so an edited manifest
or a different checkout root between the two steps blocks the mutation instead of
quietly doing something else.

## Bindings

| Binding | Meaning | Resolution |
| --- | --- | --- |
| `${AGENTIC_SUPPORT_ROOT}` | Support tree holding the refresh tool and the manifests. | The loaded support tree. |
| `${AGENTIC_REPO_CHECKOUT_ROOT}` | The member's machine-local checkouts root. | **Required.** Workspace descriptor, or an explicit caller input. Never inferred. |
| Sync manifest | The reviewed list of repositories to hydrate. | `${AGENTIC_SUPPORT_ROOT}/context-fabric/records/sync-manifests/releases/…`, or a user-provided path. |

This workflow requires an explicit checkout root before preview or apply. If the
descriptor does not declare one, stop and run the `workspace-setup` skill.

## Triggers

- Hydrate checkouts on a new machine for a product the member works on.
- Refresh existing checkouts before a code-level question.
- Regenerate repo digests after a refresh.
- Diagnose a blocked or partial refresh.

## Required Context

- The sync manifest for the product in scope, and its `reviewedBy` / `updatedAt`
  fields. An unreviewed manifest is not a manifest.
- `${AGENTIC_SUPPORT_ROOT}/context-fabric/records/profiles/<product>.json` — which
  repositories that product actually needs, and their `syncable` state.
- `${AGENTIC_SUPPORT_ROOT}/docs/workspace-routing.md` — placement guardrails.

## Procedure

1. **Resolve the checkout root** from the descriptor (or the caller). Confirm it sits
   outside every shared/synced tree; the tool refuses otherwise, and that refusal is
   correct — git internals inside a synced folder replicate to the whole team.
2. **Confirm authentication out of band.** The tool delegates entirely to the
   caller's git credential helper. Verify access with a plain `git ls-remote` against
   one repository in the manifest before running a batch. Never paste a credential
   into a manifest, a record, or a session transcript.
3. **Preview:**

   ```sh
   "${AGENTIC_SUPPORT_ROOT}/tools/refresh-manifest-repos.sh" \
     --manifest "<manifest path>" --checkout-root "<checkout root>"
   ```

   Read the plan. Every line is either `ACTION` (what would change) or `BLOCKED`
   (why nothing will). Capture the `previewDigest`.
4. **Review the blocked lines before applying.** Common causes and their meanings:
   - `dirty-worktree` — the member has uncommitted work. Ask; never discard it.
   - `diverged-history` — local commits the remote does not have. Ask; the tool will
     not merge non-linearly.
   - `unexpected-remote` — the directory holds a different repository than the
     manifest names. Stop; do not repoint it silently.
   - `no-upstream` — the branch tracks nothing. The member decides what it should
     track.
5. **Apply**, passing the digest from preview:

   ```sh
   "${AGENTIC_SUPPORT_ROOT}/tools/refresh-manifest-repos.sh" --apply \
     --manifest "<manifest path>" --preview-digest "<previewDigest>" \
     --checkout-root "<checkout root>"
   ```

   Apply runs a full preflight first: one blocked repository stops the whole batch,
   so a run never leaves the checkout root half-refreshed.
6. **Confirm digests regenerated.** Apply calls
   `tools/generate-repo-digests.sh` on success. If it reports a WARN, run the tool
   manually — a digest that silently lags its checkout is worse than no digest.
7. **Report** what changed, what was skipped, and what remains blocked.

## Guardrails

- **Fetch and fast-forward only.** This workflow never pushes, never force-updates,
  never merges non-linear history, and never touches a dirty worktree.
- The checkout root must sit outside every shared/synced tree. No exceptions, and the
  guard compares physical paths so symlinks cannot evade it.
- Never write outputs, analysis, credentials, or dependency folders into a checkout.
  Outputs go to a working-materials root.
- Never edit a manifest to make a blocked repository pass. Fix the underlying state,
  or amend the manifest through review.
- Never hand-edit generated digests.
- An engineer's pre-existing checkouts stay where they are. This workflow manages
  only the declared checkout root.

## Output Shape

- Mode run (preview / apply), manifest path, and `manifestDigest`.
- The resolved checkout root.
- Per repository: cloned, fast-forwarded, up to date, or blocked with the reason.
- Digest regeneration result.
- Any follow-up the member owns (dirty worktrees, diverged history, access gaps).

## Failure Handling

- **No checkout root declared:** stop; run `workspace-setup`. Do not guess a
  location.
- **Checkout root inside a shared tree:** the tool refuses. Re-declare a machine-local
  root; do not work around it.
- **`preview digest changed after preview`:** the manifest or the checkout root
  changed between the steps. Re-run preview and read the new plan — do not reuse the
  old digest.
- **Authentication failure:** resolve it with the host's own credential flow. Output
  is redacted; if a credential still appears anywhere, treat it as exposed and rotate
  it.
- **Partial batch on apply:** the preflight should have prevented this. Report the
  exact per-repository state, and do not re-run apply until every blocked cause is
  resolved.

## Harness Interpretation

Any capable harness runs the same two commands and reads the same structured output.
The preview/apply digest contract is what makes the workflow safe to run
conversationally: the mutation cannot drift from the plan the member approved.
