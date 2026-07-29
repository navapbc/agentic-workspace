#!/usr/bin/env bash
set -euo pipefail

# lint-context-fabric-records.sh — field-level lint for Context Fabric records.
#
# Dependency-free (bash + jq) so that open, snapshot-first record editing has a
# structural safety net beyond JSON well-formedness — on any teammate's machine,
# with no toolchain to install. Read-only.
#
# Usage:
#   lint-context-fabric-records.sh <record.json>   # lint one record
#   lint-context-fabric-records.sh --all           # lint all curated records
#
# Rules:
#   R1 required fields: kind, id, schemaVersion, updatedAt, contentLocations
#   R2 contentLocations[0].path matches the record's actual path (drift)
#   R3 repositoryResource: id == repository:<organization>/<repository>
#   R4 repositoryResource: url is https://<host>/<organization>/<repository>
#   R5 repositoryResource: checkoutDirectory is a bare basename
#   R6 syncable == true requires lifecycle active + accessState available
#      + validation.status validated
#   R7 productProfile: repositories[].resourceId, referenceResources[].resourceId,
#      and systems[].systemId resolve to existing record files
#   R8 no absolute machine paths and no token-shaped values in any record
#
# R6 is the rule teams underestimate: it makes "we sync this repo" impossible to
# assert about a repository nobody has confirmed is active, reachable, and
# validated — which is how stale or wrong checkouts get into a shared manifest.

support_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
records_root="${support_root}/context-fabric/records"
fabric_root="${support_root}/context-fabric"
failures=0

fail() {
  printf 'FAIL: %s\n' "$*" >&2
  failures=$((failures + 1))
}

command -v jq >/dev/null 2>&1 || { printf 'ERROR: jq is required\n' >&2; exit 1; }

lint_record() {
  local file="$1"
  local rel="${file#"${fabric_root}"/}"

  jq empty "${file}" 2>/dev/null || { fail "not well-formed JSON: ${rel}"; return; }

  # R1
  local field
  for field in kind id schemaVersion updatedAt contentLocations; do
    if [[ "$(jq -r --arg f "${field}" 'has($f)' "${file}")" != "true" ]]; then
      fail "missing required field '${field}': ${rel}"
    fi
  done

  # R2
  local declared_path
  declared_path=$(jq -r '.contentLocations[0].path // empty' "${file}")
  if [[ -n "${declared_path}" && "${declared_path}" != "${rel}" ]]; then
    fail "contentLocations path drift: ${rel} declares '${declared_path}'"
  fi

  local kind
  kind=$(jq -r '.kind // empty' "${file}")

  if [[ "${kind}" == "repositoryResource" ]]; then
    local id org repo url checkout
    id=$(jq -r '.id // empty' "${file}")
    org=$(jq -r '.organization // empty' "${file}")
    repo=$(jq -r '.repository // empty' "${file}")
    url=$(jq -r '.url // empty' "${file}")
    checkout=$(jq -r '.checkoutDirectory // empty' "${file}")

    # R3
    if [[ "${id}" != "repository:${org}/${repo}" ]]; then
      fail "id '${id}' != repository:${org}/${repo}: ${rel}"
    fi
    # R4 — host is the team's own (public GitHub, an enterprise host, GitLab, …);
    # the shape is what matters, so the lint stays portable across hosts.
    if [[ ! "${url}" =~ ^https://[A-Za-z0-9._-]+/${org}/${repo}$ ]]; then
      fail "url '${url}' is not https://<host>/${org}/${repo}: ${rel}"
    fi
    # R5
    case "${checkout}" in
      ''|*/*|*..*) fail "checkoutDirectory must be a bare basename, got '${checkout}': ${rel}" ;;
    esac
    # R6
    if [[ "$(jq -r '.syncable == true' "${file}")" == "true" ]]; then
      if [[ "$(jq -r '.lifecycle == "active" and .accessState == "available" and .validation.status == "validated"' "${file}")" != "true" ]]; then
        fail "syncable repository is not active+available+validated: ${rel}"
      fi
    fi
  fi

  # R7
  if [[ "${kind}" == "productProfile" ]]; then
    local ref
    while IFS= read -r ref; do
      [[ -n "${ref}" ]] || continue
      local ref_file=''
      case "${ref}" in
        repository:*) ref_file="${records_root}/resources/repositories/${ref#repository:}.json" ;;
        reference:*)  ref_file="${records_root}/resources/local/${ref#reference:}.json" ;;
        system:*)     ref_file="${records_root}/systems/${ref#system:}.json" ;;
        *) fail "unrecognized reference id scheme '${ref}': ${rel}"; continue ;;
      esac
      [[ -f "${ref_file}" ]] || fail "dangling reference '${ref}' (no ${ref_file#"${support_root}"/}): ${rel}"
    done < <(jq -r '[(.repositories // [])[].resourceId, (.referenceResources // [])[].resourceId, (.systems // [])[].systemId] | .[]' "${file}")
  fi

  # R8 — records are shared verbatim with every teammate, so a machine path or a
  # token in one is a portability break or a credential leak for everyone.
  if grep -Eq '"(/Users/|/home/|[A-Za-z]:\\\\)' "${file}"; then
    fail "absolute machine path in record (use a binding token instead): ${rel}"
  fi
  if grep -Eq 'ghp_[A-Za-z0-9]{20,}|github_pat_[A-Za-z0-9_]{20,}|xox[baprs]-|-----BEGIN [A-Z ]*PRIVATE KEY-----' "${file}"; then
    fail "token-shaped value in record: ${rel}"
  fi
}

if [[ "${1:-}" == "--all" ]]; then
  count=0
  while IFS= read -r record_file; do
    lint_record "${record_file}"
    count=$((count + 1))
  done < <(find "${records_root}/systems" "${records_root}/resources" "${records_root}/profiles" \
    -type f -name '*.json' 2>/dev/null | sort)
  if (( failures > 0 )); then
    printf '%s record lint failure(s) across %s record(s)\n' "${failures}" "${count}" >&2
    exit 1
  fi
  printf 'record lint passed (%s records)\n' "${count}"
else
  record="${1:-}"
  [[ -n "${record}" ]] || { printf 'usage: %s <record.json> | --all\n' "$(basename "$0")" >&2; exit 1; }
  [[ -f "${record}" ]] || { printf 'ERROR: no such file: %s\n' "${record}" >&2; exit 1; }
  record_abs=$(cd "$(dirname "${record}")" && pwd)/$(basename "${record}")
  lint_record "${record_abs}"
  if (( failures > 0 )); then
    printf '%s record lint failure(s)\n' "${failures}" >&2
    exit 1
  fi
  printf 'record lint passed: %s\n' "${record_abs#"${fabric_root}"/}"
fi
