#!/usr/bin/env bash
set -euo pipefail

# snapshot-context-fabric-record.sh — snapshot-first editing for Context Fabric
# records.
#
# For a workspace shared over synced storage there is no review gate and no
# revert history: a saved file reaches every teammate silently. The safety model
# that replaces review is snapshot-before-edit + changelog + validate-after.
# This tool does the first two in one step and the third on request:
#
#   snapshot-context-fabric-record.sh <record.json> --why "reason" [--by name]
#       Before editing: archives the current file under records/archive/ and
#       appends a changelog entry. For a brand-new record there is nothing to
#       archive; the changelog entry still records the addition.
#
#   snapshot-context-fabric-record.sh --verify <record.json>
#       After editing: checks the file is well-formed JSON, runs the field lint,
#       and reminds you to run the full validation.
#
# A git-backed workspace already has this safety net (diff, review, revert) and
# can skip the tool — the changelog remains useful as a human-readable "what
# changed and why" for non-engineer teammates who do not read git history.
#
# Scope: curated records under context-fabric/records/ (systems, resources,
# profiles, sync-manifests). Not for records/generated/ (tool outputs) or
# records/archive/ (snapshots). Schema changes under schemas/ are out of scope:
# a bad record breaks one fact, a bad schema breaks validation for everything
# downstream — talk to the Context Fabric steward first.

support_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
records_root="${support_root}/context-fabric/records"
archive_root="${records_root}/archive"
changelog="${records_root}/CHANGELOG.md"

fail() { printf 'ERROR: %s\n' "$1" >&2; exit 1; }

verify_mode=0
record=''
why=''
by="${USER:-unknown}"
while (( $# > 0 )); do
  case "$1" in
    --verify) verify_mode=1; shift ;;
    --why)    why="${2:-}"; shift 2 ;;
    --by)     by="${2:-}"; shift 2 ;;
    -h|--help) sed -n '5,31p' "${BASH_SOURCE[0]}"; exit 0 ;;
    -*) fail "unknown flag: $1" ;;
    *)  record="$1"; shift ;;
  esac
done

[[ -n "${record}" ]] || fail 'no record path given (see --help)'

record_abs=$(cd "$(dirname "${record}")" 2>/dev/null && pwd)/$(basename "${record}") \
  || fail "cannot resolve path: ${record}"

case "${record_abs}" in
  "${archive_root}"/*)            fail 'snapshots under records/archive/ are read-only' ;;
  "${records_root}/generated"/*)  fail 'records/generated/ holds tool outputs; regenerate instead of editing' ;;
  "${records_root}"/*)            ;;
  *) fail "not a Context Fabric record: ${record_abs} (expected under ${records_root})" ;;
esac

rel="${record_abs#"${records_root}"/}"

if (( verify_mode )); then
  [[ -f "${record_abs}" ]] || fail "no file to verify: ${record_abs}"
  command -v jq >/dev/null 2>&1 || fail 'jq is required for --verify'
  jq empty "${record_abs}" || fail "not well-formed JSON: ${rel}"
  printf 'OK: %s is well-formed JSON.\n' "${rel}"
  case "${record_abs}" in
    "${records_root}/systems"/*|"${records_root}/resources"/*|"${records_root}/profiles"/*)
      "${support_root}/tools/lint-context-fabric-records.sh" "${record_abs}" ;;
  esac
  printf 'Run the full check when done: %s/validation/check-workspace.sh\n' "${support_root}"
  exit 0
fi

[[ -n "${why}" ]] || fail 'a one-line reason is required: --why "<reason>"'

stamp_dir=$(date +%Y-%m-%d-%H%M%S)
stamp_human=$(date '+%Y-%m-%d %H:%M')

if [[ ! -f "${changelog}" ]]; then
  {
    printf '# Context Fabric record changelog\n\n'
    printf 'Records are edited snapshot-first (tools/snapshot-context-fabric-record.sh)\n'
    printf 'with no review gate. This log and records/archive/ are the audit and\n'
    printf 'rollback surface. Newest entries last.\n\n'
  } > "${changelog}"
fi

if [[ -f "${record_abs}" ]]; then
  dest="${archive_root}/${stamp_dir}/${rel}"
  mkdir -p "$(dirname "${dest}")"
  cp -p "${record_abs}" "${dest}"
  printf -- '- %s — %s — %s — %s (snapshot: archive/%s/%s)\n' \
    "${stamp_human}" "${by}" "${rel}" "${why}" "${stamp_dir}" "${rel}" >> "${changelog}"
  printf 'Snapshotted %s\n  -> %s\n' "${rel}" "${dest}"
else
  printf -- '- %s — %s — %s — %s (new record, no prior version)\n' \
    "${stamp_human}" "${by}" "${rel}" "${why}" >> "${changelog}"
  printf 'New record %s: nothing to archive; changelog entry written.\n' "${rel}"
fi
printf 'Logged in %s\n' "${changelog}"
printf 'Edit the record now, then: %s --verify %s\n' "$(basename "${BASH_SOURCE[0]}")" "${record}"
