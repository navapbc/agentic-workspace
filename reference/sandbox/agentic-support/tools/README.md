# Tools

Approved mechanics. Every tool is plain `bash` with `set -euo pipefail`, driven by
explicit CLI arguments, and invoked **by a skill** rather than free-floating. Nothing
here requires a language runtime or an install step beyond `git` and `jq`, so a
teammate can run it on a machine with no toolchain.

| Tool | What it does | Needs |
|---|---|---|
| `workspace-doctor.sh` | Session-start probe: where am I, which roots are declared, which capability tiers are available. Read-only. | bash |
| `generate-workspace-descriptor.sh` | Write this machine's declared roots. Refuses nesting, duplicates, missing roots, narrowing re-runs, and a checkout root inside the shared tree. | bash |
| `generate-repo-digests.sh` | Build per-repo digests so repository questions need no git and no checkout. | git |
| `refresh-manifest-repos.sh` | Hydrate/refresh checkouts from a reviewed manifest. Digest-bound preview→apply; fetch and fast-forward only. | git, jq |
| `route-artifact.sh` | Deterministic artifact routing, with registered area exceptions. `--card` regenerates the one-page card. | bash |
| `scaffold-product-area.sh` | Stand up a compliant product area and register it. | bash |
| `snapshot-context-fabric-record.sh` | Snapshot + changelog before a record edit; `--verify` after. | jq |
| `lint-context-fabric-records.sh` | Field-level record lint (required fields, path drift, id/url shape, syncability preconditions, dangling references, leaked paths and tokens). | jq |

## Conventions

- **A skill names the command it authorizes.** Tools never embed policy, and skills
  never embed a copy of tool logic.
- **`tools/paused/`** holds mechanics that are intentionally off. Keep them, with
  fail-closed messaging, so the reason they are off stays discoverable — deleting one
  loses the reason and invites someone to rebuild it.
- **Quote every path.** Cloud-mount paths contain spaces.
- **Read-only unless the name says otherwise.** `generate-*` writes only into
  `context-fabric/records/generated/`; `refresh-manifest-repos.sh` is the only tool
  that touches checkouts, and only on `--apply`.
