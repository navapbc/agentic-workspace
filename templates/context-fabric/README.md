# Context Fabric record templates

Copy these to author the three kinds of shared-context records. Read `../../docs/context-fabric.md` first.

| Template | Creates | ID form |
|---|---|---|
| `system.template.json` | A shared system your products touch | `system:<slug>` |
| `repository.template.json` | One code repository's identity/checkout facts | `repository:<org>/<repo>` |
| `profile.template.json` | A product's profile, referencing systems and repos | `product:<slug>` |

## Where records live

```
context-fabric/
  schemas/<schema-name>/<version>/schema.json   # your JSON Schema (author once)
  records/
    systems/<slug>.json
    resources/<org>/<repo>.json
    profiles/<slug>.json
  templates/                                    # copies of these templates
```

## Rules

- **Define once, reference many.** Create a repository or system record once; let many profiles reference it by `resourceId` / `systemId`. Never make a second record for the same thing.
- **No secrets, no absolute paths.** Records are shareable. No tokens, no `op://`, no `/Users/...`, no URLs with embedded credentials.
- **Stable IDs.** Keep the namespaced ID stable for the life of the thing it describes; other records reference it.
- **Provenance and validation.** Stamp `updatedAt`; note who validated the record and when.
- **Validate.** At minimum `jq empty <file>` to confirm it parses. At Run phase, validate against your schema.

Replace every `{{PLACEHOLDER}}` and delete comment lines before saving a real record. JSON does not allow comments, so the `_comment` fields here must be removed.
