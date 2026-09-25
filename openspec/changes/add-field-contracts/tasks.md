# Tasks

## 1. Shared vocabulary

- [ ] `schemas/shared/1/defs.json` — identifier, upstream reference, location
      grammar, organization, maintainer, release, status, and the denylist data
      with its derived patterns.
      **Verification:** the file is valid JSON and every `$defs` key a tier
      contract references resolves.

## 2. Tier contracts

- [ ] `schemas/org/1/schema.json`
- [ ] `schemas/bounded-context/1/schema.json`
- [ ] `schemas/individual/1/schema.json`
      **Verification:** each valid fixture validates against its tier with the
      network disabled; each invalid fixture trips exactly the code it is named
      for.

## 3. Fixture corpus

- [ ] One valid fixture per tier.
- [ ] One invalid fixture per schema-detectable rule, named by its finding code
      lowercased with `_` replaced by `-`.
- [ ] An evasion corpus for denylist near-misses.
      **Verification:** `tests/schemas.test.sh` passes, and asserts every
      denylist entry has both a fixture that trips it and a valid fixture that
      does not.

## 4. Template rendering

- [ ] `scripts/render-templates.sh` with `--check`.
- [ ] `templates/org.TEMPLATE.yaml`, `templates/bounded-context.TEMPLATE.yaml`,
      `templates/individual.TEMPLATE.yaml`, committed as rendered.
      **Verification:** `tests/render-templates.test.sh` passes; output is
      byte-identical across two runs; `--check` fails after a hand edit.

## 5. Migration guard and contract immutability

- [ ] `tests/migrations.test.sh` — for every tier and every contract version
      above 1, the migration step exists, is idempotent, and its round-trip
      fixture matches byte for byte. Passes vacuously at contract 1.
- [ ] Frozen-hash assertion over every released contract directory.
      **Verification:** both tests pass at contract 1; editing a released
      schema in place fails the frozen-hash assertion.

## 6. Tooling and screening

- [ ] Pin `check-jsonschema` in `framework.json` and give the schema stage a
      named skipped-stage code.
- [ ] Add `openspec/` to the denylist and real-name screening scopes — the
      tree is public and carries reasoning drawn from documents that are not.
- [ ] `tests/openspec.test.sh` — version pin matches, and every
      capability-affecting change carries a non-empty rejected-alternatives
      section.
      **Verification:** `tests/run.sh` exits 0 locally; CI's allowed-skip list
      is updated only for codes CI genuinely cannot satisfy.
