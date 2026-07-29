#!/usr/bin/env bash
set -euo pipefail

# refresh-manifest-repos.sh — hydrate or refresh local checkouts from a reviewed
# sync manifest. Fetch and fast-forward only; it never pushes, never merges
# non-linear history, and never touches a dirty worktree.
#
# Two-step by design. Preview prints the plan and emits a previewDigest that
# binds the manifest bytes to the resolved checkout root. Apply requires that
# digest, so an edited manifest or a different checkout root between the two
# steps blocks the mutation instead of silently doing something else. In a
# workspace shared over synced storage the manifest can change under you while
# you read the preview; the digest is what makes that harmless.
#
# Usage:
#   refresh-manifest-repos.sh --manifest <path> --checkout-root <dir>
#   refresh-manifest-repos.sh --apply --manifest <path> --preview-digest <sha256> --checkout-root <dir>
#
# Manifest shape: context-fabric/templates/sync-manifest.template.json
# Authentication is delegated entirely to the caller's git credential helper —
# this tool never reads, stores, or prints a credential.

usage() {
  cat <<'USAGE'
Usage:
  refresh-manifest-repos.sh --manifest <path> --checkout-root <dir>
  refresh-manifest-repos.sh --apply --manifest <path> --preview-digest <sha256> --checkout-root <dir>

Preview is the default. Apply requires the preview digest emitted by preview.
USAGE
}

fail() {
  printf 'ERROR: %s\n' "$1" >&2
  exit "${2:-1}"
}

redact() {
  sed -E 's#([A-Za-z][A-Za-z0-9+.-]*://)[^/@[:space:]]+@#\1[redacted]@#g; s#([A-Za-z][A-Za-z0-9+.-]*://[^/@[:space:]]+):[^/@[:space:]]+@#\1:[redacted]@#g; s#(^|[[:space:]])[^[:space:]@/:]+:[^[:space:]@]+@#\1[redacted]@#g'
}

sha256() { # stdin -> hex digest; portable across BSD and GNU userlands
  if command -v shasum >/dev/null 2>&1; then shasum -a 256
  elif command -v sha256sum >/dev/null 2>&1; then sha256sum
  else fail 'need shasum or sha256sum to compute manifest digests'
  fi | awk '{print $1}'
}

command -v git >/dev/null 2>&1 || fail 'git is required'
command -v jq  >/dev/null 2>&1 || fail 'jq is required'

manifest_path=''
checkout_root=''
expected_digest=''
mode='preview'

while (($#)); do
  case "$1" in
    --manifest)
      shift; (($#)) || fail '--manifest requires a path'; manifest_path="$1" ;;
    --checkout-root)
      shift; (($#)) || fail '--checkout-root requires a directory'; checkout_root="$1" ;;
    --preview-digest|--manifest-digest)
      shift; (($#)) || fail 'digest flag requires a sha256 value'; expected_digest="$1" ;;
    --apply) mode='apply' ;;
    --preview|--dry-run) mode='preview' ;;
    --help|-h) usage; exit 0 ;;
    *) fail "unknown argument: $1" ;;
  esac
  shift
done

[[ -n "${manifest_path}" ]] || fail '--manifest is required'
[[ -n "${checkout_root}" ]] || fail '--checkout-root is required'
[[ -r "${manifest_path}" ]] || fail "manifest is missing or unreadable: ${manifest_path}"
[[ -d "${checkout_root}" ]] || fail "checkout root is missing or unreadable: ${checkout_root}"
[[ "${mode}" == 'preview' || -n "${expected_digest}" ]] || fail '--apply requires --preview-digest from preview'

manifest_digest="$(sha256 < "${manifest_path}")"

checkout_root_real="$(cd -- "${checkout_root}" && pwd -P)"
checkout_root_logical="$(cd -- "${checkout_root}" && pwd)"

# Checkouts must sit outside the shared workspace tree: a checkout root inside it
# would replicate git internals to every teammate. The guard compares against the
# PHYSICAL workspace root (this script's real grandparent) in both logical and
# physical forms, so no symlink or alias indirection evades the refusal.
workspace_root_real="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd -P)"
for form in "${checkout_root_real}" "${checkout_root_logical}"; do
  case "${form}" in
    "${workspace_root_real}"|"${workspace_root_real}"/*)
      fail "checkout root resolves into the shared workspace tree: ${checkout_root_real}"
      ;;
  esac
done

preview_digest="$(printf 'manifestDigest=%s\ncheckoutRoot=%s\n' "${manifest_digest}" "${checkout_root_real}" | sha256)"
if [[ "${mode}" == 'apply' && "${preview_digest}" != "${expected_digest}" ]]; then
  fail "preview digest changed after preview: expected ${expected_digest}, actual ${preview_digest}"
fi

validation_errors="$(
  jq -r '
    def missing($path): "missing required field: " + $path;
    def scalar($path): "invalid required field: " + $path;
    [
      (if (.productId | type) == "string" and (.productId | length) > 0 then empty else missing("productId") end),
      (if (.version | type) == "string" and (.version | length) > 0 then empty else missing("version") end),
      (if (.updatedAt | type) == "string" and (.updatedAt | length) > 0 then empty else missing("updatedAt") end),
      (if (.reviewedBy | type) == "string" and (.reviewedBy | length) > 0 then empty else missing("reviewedBy") end),
      (if (.repositories | type) == "array" and (.repositories | length) > 0 then empty else missing("repositories") end),
      (
        .repositories[]? as $repo |
        if ($repo.id | type) == "string" and ($repo.id | length) > 0 then empty else scalar("repositories[].id") end,
        if ($repo.url | type) == "string" and ($repo.url | length) > 0 then empty else scalar("repositories[].url") end,
        if ($repo.checkoutDirectory | type) == "string" and ($repo.checkoutDirectory | length) > 0 then empty else scalar("repositories[].checkoutDirectory") end,
        if (($repo.checkoutDirectory // "") | startswith("/") | not)
          and (($repo.checkoutDirectory // "") | test("(^|/)\\.\\.(/|$)") | not)
          and (($repo.checkoutDirectory // "") != ".")
        then empty else "invalid checkoutDirectory: " + ($repo.checkoutDirectory // "<missing>") end,
        # URL shape is host-agnostic on purpose: public GitHub, an enterprise
        # host, GitLab, or Bitbucket all pass. An option-like value never does.
        if (($repo.url // "") | startswith("-")) then "invalid repository URL: option-like value is not allowed"
        elif ($repo.url | test("^https://[A-Za-z0-9._-]+/[A-Za-z0-9_./-]+/[A-Za-z0-9_.-]+$")) then empty
        elif ($repo.url | test("^ssh://git@[A-Za-z0-9._-]+(:[0-9]+)?/[A-Za-z0-9_./-]+/[A-Za-z0-9_.-]+$")) then empty
        elif ($repo.url | test("^git@[A-Za-z0-9._-]+:[A-Za-z0-9_./-]+/[A-Za-z0-9_.-]+$")) then empty
        elif (((.localPathException.allowed // false) == true)
          and (((.localPathException.reason // "") | length) > 0)
          and ($repo.url | test("^/[^[:cntrl:]]+$")))
        then empty
        else "repository URL is not a recognized remote form; a local path needs a documented localPathException: " + ($repo.url // "<missing>") end
      ),
      ([.repositories[]?.id] | group_by(.)[] | select(length > 1) | "duplicate repository id: " + .[0]),
      ([.repositories[]?.url] | group_by(.)[] | select(length > 1) | "duplicate repository url: " + (.[0] | tostring)),
      ([.repositories[]?.checkoutDirectory] | group_by(.)[] | select(length > 1) | "duplicate checkout directory: " + (.[0] | tostring))
    ] | .[]
  ' "${manifest_path}" 2>&1 | redact
)"

if [[ -n "${validation_errors}" ]]; then
  printf '%s\n' "${validation_errors}" >&2
  exit 1
fi

printf 'mode=%s\n' "${mode}"
printf 'manifest=%s\n' "${manifest_path}"
printf 'manifestDigest=%s\n' "${manifest_digest}"
printf 'checkoutRoot=%s\n' "${checkout_root_real}"
printf 'previewDigest=%s\n' "${preview_digest}"

planned_failures=0

check_local_state() {
  local repo_id="$1"
  local repo_url="$2"
  local checkout_dir="$3"
  local prefix="$4"
  local target="${checkout_root_real}/${checkout_dir}"
  local target_parent target_real target_parent_real actual_url current_branch ahead_behind ahead behind

  target_parent="$(dirname -- "${target}")"
  case "${target}" in
    "${checkout_root_real}"/*) ;;
    *) printf '%s id=%s action=blocked reason=outside-checkout-root checkoutDirectory=%s\n' "${prefix}" "${repo_id}" "${checkout_dir}" | redact; return 1 ;;
  esac
  if [[ -e "${target}" ]]; then
    target_real="$(cd -- "${target}" 2>/dev/null && pwd -P || true)"
    case "${target_real}" in
      "${checkout_root_real}"/*) ;;
      *) printf '%s id=%s action=blocked reason=outside-checkout-root target=%s\n' "${prefix}" "${repo_id}" "${target}" | redact; return 1 ;;
    esac
  elif [[ -e "${target_parent}" ]]; then
    target_parent_real="$(cd -- "${target_parent}" 2>/dev/null && pwd -P || true)"
    case "${target_parent_real}" in
      "${checkout_root_real}"|"${checkout_root_real}"/*) ;;
      *) printf '%s id=%s action=blocked reason=outside-checkout-root target=%s\n' "${prefix}" "${repo_id}" "${target}" | redact; return 1 ;;
    esac
  fi

  [[ -e "${target}" ]] || return 0

  if [[ ! -d "${target}/.git" ]]; then
    printf '%s id=%s action=blocked reason=target-exists-not-git target=%s\n' "${prefix}" "${repo_id}" "${target}" | redact
    return 1
  fi

  actual_url="$(git -C "${target}" config --get remote.origin.url || true)"
  if [[ "${actual_url}" != "${repo_url}" ]]; then
    printf '%s id=%s action=blocked reason=unexpected-remote expected=%s actual=%s\n' "${prefix}" "${repo_id}" "${repo_url}" "${actual_url:-<missing>}" | redact
    return 1
  fi

  if [[ -n "$(git -C "${target}" status --porcelain)" ]]; then
    printf '%s id=%s action=blocked reason=dirty-worktree target=%s\n' "${prefix}" "${repo_id}" "${target}" | redact
    return 1
  fi

  if ! git -C "${target}" rev-parse --abbrev-ref --symbolic-full-name '@{u}' >/dev/null 2>&1; then
    current_branch="$(git -C "${target}" branch --show-current || true)"
    if [[ -n "${current_branch}" ]] \
      && [[ -n "$(git -C "${target}" config --get "branch.${current_branch}.remote" || true)" ]] \
      && [[ -n "$(git -C "${target}" config --get "branch.${current_branch}.merge" || true)" ]]; then
      printf '%s id=%s action=blocked reason=upstream-comparison-failed target=%s\n' "${prefix}" "${repo_id}" "${target}" | redact
    else
      printf '%s id=%s action=blocked reason=no-upstream target=%s\n' "${prefix}" "${repo_id}" "${target}" | redact
    fi
    return 1
  fi

  if ! ahead_behind="$(git -C "${target}" rev-list --left-right --count 'HEAD...@{u}' 2>/dev/null)"; then
    printf '%s id=%s action=blocked reason=upstream-comparison-failed target=%s\n' "${prefix}" "${repo_id}" "${target}" | redact
    return 1
  fi
  ahead="${ahead_behind%%$'\t'*}"
  behind="${ahead_behind##*$'\t'}"
  if [[ "${ahead}" != '0' && "${behind}" != '0' ]]; then
    printf '%s id=%s action=blocked reason=diverged-history ahead=%s behind=%s target=%s\n' "${prefix}" "${repo_id}" "${ahead}" "${behind}" "${target}" | redact
    return 1
  fi

  return 0
}

# Apply runs a full preflight before mutating anything: one blocked repo stops
# the whole batch, so a run never leaves the checkout root half-refreshed.
if [[ "${mode}" == 'apply' ]]; then
  while IFS=$'\t' read -r repo_id repo_url checkout_dir; do
    check_local_state "${repo_id}" "${repo_url}" "${checkout_dir}" 'PREFLIGHT-BLOCKED' || planned_failures=1
  done < <(jq -r '.repositories[] | [.id, .url, .checkoutDirectory] | @tsv' "${manifest_path}")
  if [[ "${planned_failures}" != '0' ]]; then
    exit "${planned_failures}"
  fi
fi

while IFS=$'\t' read -r repo_id repo_url checkout_dir; do
  target="${checkout_root_real}/${checkout_dir}"
  check_local_state "${repo_id}" "${repo_url}" "${checkout_dir}" 'BLOCKED' || { planned_failures=1; continue; }

  if [[ ! -e "${target}" ]]; then
    printf 'ACTION id=%s action=clone url=%s target=%s\n' "${repo_id}" "${repo_url}" "${target}" | redact
    if [[ "${mode}" == 'apply' ]]; then
      if ! git_output="$(git clone --quiet -- "${repo_url}" "${target}" 2>&1)"; then
        printf '%s\n' "${git_output}" | redact >&2
        planned_failures=1
      fi
    fi
    continue
  fi

  if [[ "${mode}" == 'apply' ]]; then
    if ! git_output="$(git -C "${target}" fetch --quiet origin 2>&1)"; then
      printf '%s\n' "${git_output}" | redact >&2
      planned_failures=1
      continue
    fi
  fi

  if ! ahead_behind="$(git -C "${target}" rev-list --left-right --count 'HEAD...@{u}' 2>/dev/null)"; then
    printf 'BLOCKED id=%s action=blocked reason=upstream-comparison-failed target=%s\n' "${repo_id}" "${target}" | redact
    planned_failures=1
    continue
  fi
  ahead="${ahead_behind%%$'\t'*}"
  behind="${ahead_behind##*$'\t'}"
  if [[ "${ahead}" != '0' && "${behind}" != '0' ]]; then
    printf 'BLOCKED id=%s action=blocked reason=diverged-history ahead=%s behind=%s target=%s\n' "${repo_id}" "${ahead}" "${behind}" "${target}" | redact
    planned_failures=1
    continue
  fi
  if [[ "${behind}" != '0' ]]; then
    printf 'ACTION id=%s action=fast-forward behind=%s target=%s\n' "${repo_id}" "${behind}" "${target}" | redact
    if [[ "${mode}" == 'apply' ]] && ! git_output="$(git -C "${target}" merge --ff-only --quiet '@{u}' 2>&1)"; then
      printf '%s\n' "${git_output}" | redact >&2
      planned_failures=1
    fi
    continue
  fi

  if [[ "${mode}" == 'preview' ]]; then
    printf 'ACTION id=%s action=fetch reason=clean-existing-checkout target=%s\n' "${repo_id}" "${target}" | redact
  else
    printf 'ACTION id=%s action=skip reason=up-to-date target=%s\n' "${repo_id}" "${target}" | redact
  fi
done < <(jq -r '.repositories[] | [.id, .url, .checkoutDirectory] | @tsv' "${manifest_path}")

# Keep shared repo digests aligned with the checkouts they describe: a digest
# that silently lags its checkout is worse than no digest.
if [[ "${mode}" == 'apply' && "${planned_failures}" == '0' ]]; then
  digest_tool="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/generate-repo-digests.sh"
  if [[ -x "${digest_tool}" ]]; then
    printf 'INFO regenerating repo digests after apply\n'
    "${digest_tool}" || printf 'WARN digest regeneration failed; run tools/generate-repo-digests.sh manually\n' >&2
  else
    printf 'WARN repo digests may be stale; run tools/generate-repo-digests.sh\n' >&2
  fi
fi

exit "${planned_failures}"
