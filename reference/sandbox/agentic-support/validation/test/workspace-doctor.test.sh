#!/usr/bin/env bash
set -euo pipefail
# shellcheck disable=SC2015  # `check && pass || fail` is the intended report shape here

# workspace-doctor.test.sh — behavioral tests for the session-start probe.
#
# The doctor's contract is its exit codes: 0 = report produced (even when degraded),
# 2 = support tree unresolvable, 3 = the declaration is missing or invalid. Skills
# and onboarding branch on those codes, so a drifted exit code silently changes what
# every new member is told to do.
#
# All runs use AGENTIC_WORKSPACE_DESCRIPTOR pointed at a temp file.

support_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)
workspace_root=$(cd "${support_root}/.." && pwd)
doctor="${support_root}/tools/workspace-doctor.sh"

tmp=$(mktemp -d)
planted="${workspace_root}/.tmp-doctor-test/.claude"
cleanup() { rm -rf "${tmp}" "${workspace_root}/.tmp-doctor-test"; }
trap cleanup EXIT

failures=0
pass() { printf '  ok   %s\n' "$1"; }
fail() { printf '  FAIL %s\n' "$1" >&2; failures=$((failures + 1)); }

mkdir -p "${tmp}/checkouts" "${tmp}/work" "${tmp}/gone"

run_doctor() { # descriptor-path -> sets DOCTOR_OUT / DOCTOR_CODE
  set +e
  DOCTOR_OUT=$(AGENTIC_WORKSPACE_DESCRIPTOR="$1" "${doctor}" 2>&1)
  DOCTOR_CODE=$?
  set -e
}

printf '== workspace doctor tests ==\n'

# --- no declaration on this machine
run_doctor "${tmp}/absent.yaml"
[[ "${DOCTOR_CODE}" == "3" ]] && pass 'exits 3 when no descriptor exists' \
  || fail "exits 3 when no descriptor exists (got ${DOCTOR_CODE})"
grep -q 'workspace-setup' <<< "${DOCTOR_OUT}" \
  && pass 'names the setup skill as the fix' || fail 'names the setup skill as the fix'

# --- an unrecognized descriptor version is not silently tolerated
cat > "${tmp}/v9.yaml" <<EOF
descriptor_version: 9
AGENTIC_REPO_CHECKOUT_ROOT: ${tmp}/checkouts
AGENTIC_WORKING_MATERIALS_ROOT_1: ${tmp}/work
EOF
run_doctor "${tmp}/v9.yaml"
[[ "${DOCTOR_CODE}" == "3" ]] && pass 'exits 3 on an unrecognized descriptor_version' \
  || fail "exits 3 on an unrecognized descriptor_version (got ${DOCTOR_CODE})"

# --- an incomplete declaration stops rather than guessing the missing half
cat > "${tmp}/partial.yaml" <<EOF
descriptor_version: 1
AGENTIC_REPO_CHECKOUT_ROOT: ${tmp}/checkouts
EOF
run_doctor "${tmp}/partial.yaml"
[[ "${DOCTOR_CODE}" == "3" ]] && pass 'exits 3 when no working-materials root is declared' \
  || fail "exits 3 when no working-materials root is declared (got ${DOCTOR_CODE})"

# --- a declared root that has since moved or been deleted
cat > "${tmp}/stale.yaml" <<EOF
descriptor_version: 1
AGENTIC_REPO_CHECKOUT_ROOT: ${tmp}/checkouts
AGENTIC_WORKING_MATERIALS_ROOT_1: ${tmp}/vanished
EOF
run_doctor "${tmp}/stale.yaml"
[[ "${DOCTOR_CODE}" == "3" ]] && pass 'exits 3 when a declared root is gone from disk' \
  || fail "exits 3 when a declared root is gone from disk (got ${DOCTOR_CODE})"
grep -q 'vanished' <<< "${DOCTOR_OUT}" \
  && pass 'names the missing root' || fail 'names the missing root'

# --- a checkout root inside the shared tree is refused, not warned about
cat > "${tmp}/inshared.yaml" <<EOF
descriptor_version: 1
AGENTIC_REPO_CHECKOUT_ROOT: ${support_root}
AGENTIC_WORKING_MATERIALS_ROOT_1: ${tmp}/work
EOF
run_doctor "${tmp}/inshared.yaml"
[[ "${DOCTOR_CODE}" == "3" ]] && pass 'exits 3 when the checkout root is inside the shared tree' \
  || fail "exits 3 when the checkout root is inside the shared tree (got ${DOCTOR_CODE})"

# --- a valid declaration produces a report, even with nothing else installed
cat > "${tmp}/valid.yaml" <<EOF
descriptor_version: 1
AGENTIC_REPO_CHECKOUT_ROOT: ${tmp}/checkouts
AGENTIC_WORKING_MATERIALS_ROOT_1: ${tmp}/work
AGENTIC_EXTRA_ROOT_1: ${tmp}/gone
EOF
run_doctor "${tmp}/valid.yaml"
[[ "${DOCTOR_CODE}" == "0" ]] && pass 'exits 0 on a valid declaration' \
  || fail "exits 0 on a valid declaration (got ${DOCTOR_CODE})"
grep -q "${tmp}/checkouts" <<< "${DOCTOR_OUT}" \
  && pass 'reports the declared checkout root' || fail 'reports the declared checkout root'
grep -q 'default output destination' <<< "${DOCTOR_OUT}" \
  && pass 'marks the first working root as the default output destination' \
  || fail 'marks the first working root as the default output destination'
grep -q 'What you can do today' <<< "${DOCTOR_OUT}" \
  && pass 'reports capability tiers' || fail 'reports capability tiers'
grep -q 'Skill availability' <<< "${DOCTOR_OUT}" \
  && pass 'reports skill availability from the manifest' \
  || fail 'reports skill availability from the manifest'

# --- member-specific harness state in the shared tree warns without blocking
mkdir -p "${planted}"
printf '{}\n' > "${planted}/settings.local.json"
run_doctor "${tmp}/valid.yaml"
[[ "${DOCTOR_CODE}" == "0" ]] && pass 'harness state in the shared tree warns, not fails' \
  || fail "harness state in the shared tree warns, not fails (got ${DOCTOR_CODE})"
grep -q 'member-specific harness state' <<< "${DOCTOR_OUT}" \
  && pass 'flags harness state inside the shared tree' \
  || fail 'flags harness state inside the shared tree'
grep -q 'PRIMARY folder' <<< "${DOCTOR_OUT}" \
  && pass 'points at the launch shape, not just the file' \
  || fail 'points at the launch shape, not just the file'
rm -rf "${workspace_root}/.tmp-doctor-test"

# --- an unresolvable support tree is a different failure from a bad declaration
mkdir -p "${tmp}/fake-support/tools"
cp "${doctor}" "${tmp}/fake-support/tools/workspace-doctor.sh"
set +e
AGENTIC_WORKSPACE_DESCRIPTOR="${tmp}/valid.yaml" "${tmp}/fake-support/tools/workspace-doctor.sh" >/dev/null 2>&1
orphan_code=$?
set -e
[[ "${orphan_code}" == "2" ]] && pass 'exits 2 when the support tree is unresolvable' \
  || fail "exits 2 when the support tree is unresolvable (got ${orphan_code})"

printf '\n'
if (( failures > 0 )); then
  printf 'workspace doctor tests: %s failure(s)\n' "${failures}" >&2
  exit 1
fi
printf 'workspace doctor tests passed\n'
