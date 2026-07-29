# Sync manifests

Reviewed lists of repositories a product hydrates locally, consumed by
`tools/refresh-manifest-repos.sh` and the `repo-sync` skill.

```
sync-manifests/releases/<product-slug>/<YYYY-MM-DD>.json
```

Author from `../../templates/sync-manifest.template.json`. A manifest is a
**reviewed** artifact: `reviewedBy` and `updatedAt` are what make it safe to run.

Amend a manifest through review. Never edit one to make a blocked repository pass —
the block is telling you about real local state (uncommitted work, diverged history,
a directory holding a different repository), and editing the manifest hides it
instead of resolving it.
