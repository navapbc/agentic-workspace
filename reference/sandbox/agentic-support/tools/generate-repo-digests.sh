#!/usr/bin/env bash
# shellcheck disable=SC2016  # literal binding tokens in generated markdown are intentional
set -euo pipefail

# generate-repo-digests.sh — steward tool: build per-repo digests from the local
# checkouts so repository questions can be answered from the shared workspace
# with no git and no checkout.
#
# For each git checkout under the declared AGENTIC_REPO_CHECKOUT_ROOT (from the
# machine-local workspace descriptor; docs/skill-binding-contract.md), writes
# context-fabric/records/generated/repo-digests/<repo>.md containing the repo's
# purpose (from its README), top-level layout, and last-refreshed commit.
# Read-only against the checkouts; requires git.
#
# Re-run after checkout syncs to keep digests honest — each digest carries
# generated_at and do_not_rely_after dates so a stale digest reads as stale
# instead of authoritative.
#
# Digests are the highest-leverage piece of the support layer: most orientation
# questions ("what is repo X for", "where does Y live in it") end here, which
# means teammates with no git installed and agents with no checkout access can
# still answer them, and no session burns context walking a repository tree.

support_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
descriptor="${AGENTIC_WORKSPACE_DESCRIPTOR:-${HOME}/.agentic-workspace/workspace-descriptor.yaml}"
digest_root="${support_root}/context-fabric/records/generated/repo-digests"
digest_ttl_days="${AGENTIC_DIGEST_TTL_DAYS:-60}"

command -v git >/dev/null 2>&1 || { printf 'ERROR: git is required\n' >&2; exit 1; }
if [[ ! -f "${descriptor}" ]]; then
  printf 'ERROR: no workspace descriptor at %s — declare your roots via the workspace-setup skill first\n' "${descriptor}" >&2
  exit 1
fi
checkout_root="$(sed -n 's/^AGENTIC_REPO_CHECKOUT_ROOT: //p' "${descriptor}" | head -1)"
if [[ -z "${checkout_root}" ]]; then
  printf 'ERROR: descriptor at %s declares no repo-checkouts root — re-declare via the workspace-setup skill\n' "${descriptor}" >&2
  exit 1
fi
[[ -d "${checkout_root}" ]] || {
  printf 'ERROR: declared checkout root does not exist: %s — re-declare via the workspace-setup skill\n' "${checkout_root}" >&2
  exit 1
}

redact_url() {
  sed -E 's#(://)[^/@[:space:]]+@#\1[redacted]@#g'
}

readme_purpose() {
  # First prose paragraph of README.md: skip headings, badges, images, HTML
  # tags, and blank lines; stop at the end of the first real paragraph.
  local readme="$1"
  [[ -f "${readme}" ]] || { printf '(no README in checkout)\n'; return; }
  awk '
    /^[[:space:]]*$/ { if (started) exit; next }
    /^#/ || /^\[!\[/ || /^!\[/ || /^</ || /^---/ { if (started) exit; next }
    { started = 1; print }
  ' "${readme}" | head -6
}

generated_at=$(date +%Y-%m-%d)
if date -v "+${digest_ttl_days}d" +%Y-%m-%d >/dev/null 2>&1; then
  rely_until=$(date -v "+${digest_ttl_days}d" +%Y-%m-%d)   # BSD/macOS
else
  rely_until=$(date -d "+${digest_ttl_days} days" +%Y-%m-%d)  # GNU
fi

mkdir -p "${digest_root}"
count=0

for dir in "${checkout_root}"/*/; do
  dir="${dir%/}"
  [[ -d "${dir}/.git" ]] || continue
  name=$(basename "${dir}")

  remote=$(git -C "${dir}" remote get-url origin 2>/dev/null | redact_url || true)
  branch=$(git -C "${dir}" rev-parse --abbrev-ref HEAD 2>/dev/null || echo 'unknown')
  sha=$(git -C "${dir}" rev-parse --short HEAD 2>/dev/null || echo 'unknown')
  commit_date=$(git -C "${dir}" log -1 --format=%cs 2>/dev/null || echo 'unknown')

  top_paths=$(find "${dir}" -mindepth 1 -maxdepth 1 \( -type d -o -type f -name '*.md' \) \
    ! -name '.git' ! -name '.DS_Store' ! -name 'Icon' \
    | sort | head -14 | while IFS= read -r p; do
        b=$(basename "${p}")
        if [[ -d "${p}" ]]; then printf -- '- `%s/`\n' "${b}"; else printf -- '- `%s`\n' "${b}"; fi
      done)

  {
    printf -- '---\n'
    printf 'repo: %s\n' "${name}"
    printf 'generated_at: %s\n' "${generated_at}"
    printf 'do_not_rely_after: %s\n' "${rely_until}"
    printf 'source_commit: %s\n' "${sha}"
    printf 'source_branch: %s\n' "${branch}"
    printf 'last_commit_date: %s\n' "${commit_date}"
    [[ -n "${remote}" ]] && printf 'remote: %s\n' "${remote}"
    printf -- '---\n\n'
    printf '# %s\n\n' "${name}"
    printf '## Purpose (from repo README)\n\n'
    readme_purpose "${dir}/README.md"
    printf '\n## Top-level layout\n\n%s\n\n' "${top_paths}"
    printf '## Freshness\n\n'
    printf 'Digest reflects the local checkout at commit `%s` (%s). ' "${sha}" "${commit_date}"
    printf 'For anything deeper than purpose and layout, inspect the checkout at `${AGENTIC_REPO_CHECKOUT_ROOT}/%s/` — this digest is orientation, not a substitute for the source.\n' "${name}"
  } > "${digest_root}/${name}.md"
  count=$((count + 1))
done

{
  printf -- '---\n'
  printf 'generated_at: %s\n' "${generated_at}"
  printf 'do_not_rely_after: %s\n' "${rely_until}"
  printf 'digest_count: %s\n' "${count}"
  printf -- '---\n\n'
  printf '# Repo digests\n\n'
  printf 'Generated summaries of each local checkout: purpose, top-level layout, and last-refreshed commit. '
  printf 'Consult these before opening a checkout — most orientation-level repository questions end here, and no git setup is needed to read them.\n\n'
  printf 'Regenerate after checkout syncs: `tools/generate-repo-digests.sh` (steward task, requires git). '
  printf 'Do not edit digests by hand; they are generated records.\n'
} > "${digest_root}/README.md"

printf 'Wrote %s digest(s) to %s\n' "${count}" "${digest_root}"
