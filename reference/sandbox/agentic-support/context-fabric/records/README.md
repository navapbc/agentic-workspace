# Records

Authored shared facts. One file per fact, under the schema in
`../schemas/workspace-context/1.0.0/schema.json`.

```
records/
  profiles/<slug>.json                          productProfile — the entry point per product
  resources/repositories/<org>/<repo>.json      repositoryResource — one repository, defined once
  resources/local/<slug>.json                   localReferenceResource — a governed consultable source
  systems/<slug>.json                           systemResource — a shared system and how to reach it
  sync-manifests/releases/<product>/<date>.json reviewed checkout lists
  generated/                                    TOOL OUTPUT — never hand-edit
  archive/<timestamp>/<path>                    snapshots written before each edit
  CHANGELOG.md                                  what changed, when, by whom, and why
```

Edit snapshot-first (`../../tools/snapshot-context-fabric-record.sh`), then run
`../../validation/check-workspace.sh`. See [authoring guidance](../docs/authoring.md).
