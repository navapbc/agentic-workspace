# Repo Checkouts

Scope: local git repository checkouts. Machine-local, never synced. This root is one part of a multi-root workspace — it is not the workspace itself, and its conventions are not the workspace's conventions.

- Primary guidance lives in the agentic support tree, not here: `{{AGENTIC_SUPPORT_ROOT}}`. If this is the only root visible in your session, you are missing required context — add the support root to the session (routing rules: `{{AGENTIC_SUPPORT_ROOT}}/docs/workspace-routing.md`) before treating this folder's conventions as the pattern.
- Session start: run the workspace doctor at `{{AGENTIC_SUPPORT_ROOT}}/tools/workspace-doctor.sh`.
- Repository questions: read the generated digest at `{{AGENTIC_SUPPORT_ROOT}}/context-fabric/records/generated/repo-digests/<repo>.md` first; open the checkout here only when the digest cannot answer.
- Checkouts are read-only in practice: the sync tooling only fetches and fast-forwards, and never pushes. Hydrate or refresh through the `repo-sync` skill's reviewed manifests.
- Do not write synthesis, credentials, dependency folders, or generated analysis into checkout repos. Outputs belong in a working-materials root (the doctor names your default).
