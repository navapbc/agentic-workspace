# Security Policy

This kit is documentation, templates, and small shell scripts — it has no runtime, network surface, or data store. The security posture is about what the kit teaches and what must never end up in a workspace built from it.

## The kit's safety invariants

Workspaces stood up from this kit must never contain:

- Secrets or credentials — no API tokens, PATs, passwords, `.env` files, `op://` references, or vault IDs. Inject secrets at runtime; never store them.
- Code checkouts inside the workspace — cloned repos live outside and are referenced by path.
- Absolute machine paths in shared files — use bindings instead.

`scripts/validate-workspace.sh` checks these, and CI runs it against the bundled sandbox on every change.

## Reporting a concern

If you find a secret, credential, or other sensitive content committed to this repo — or a template/script that could lead someone to leak one — please report it privately rather than opening a public issue:

> **joseoyola@navapbc.com** — or open a private security advisory on this repo.

Please include the file path and a short description. We'll acknowledge and remediate promptly.

## Scope

Because there is no executable service here, traditional vulnerability classes (RCE, injection, auth bypass) do not apply. The relevant risks are accidental disclosure (secrets/PII/internal identifiers committed to a shared repo) and scripts that could mislead a user into unsafe handling. Reports in those categories are in scope.
