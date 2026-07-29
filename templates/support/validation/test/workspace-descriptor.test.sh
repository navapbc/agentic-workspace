#!/usr/bin/env bash
set -euo pipefail
# shellcheck disable=SC2015  # `check && pass || fail` is the intended report shape here

# workspace-descriptor.test.sh — behavioral tests for the descriptor generator.
#
# The generator is the one place that decides what a member's workspace IS, so its
# refusals matter more than its happy path: every guard here corresponds to a way a
# silently-wrong descriptor would make downstream tools act on the wrong directory.
#
# All runs use AGENTIC_WORKSPACE_DESCRIPTOR pointed at a temp file, so the live
# machine-local declaration is never read or written.

support_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)
workspace_root=$(cd "${support_root}/.." && pwd)
generator="${support_root}/tools/generate-workspace-descriptor.sh"

tmp=$(mktemp -d)
inside_shared="${support_root}/.tmp-descriptor-test"
cleanup() { rm -rf "${tmp}" "${inside_shared}"; }
trap cleanup EXIT

failures=0
pass() { printf '  ok   %s\n' "$1"; }
fail() { printf '  FAIL %s\n' "$1" >&2; failures=$((failures + 1)); }

out="${tmp}/descriptor.yaml"
export AGENTIC_WORKSPACE_DESCRIPTOR="${out}"

mkdir -p "${tmp}/checkouts" "${tmp}/work-a" "${tmp}/work-b" "${tmp}/extra" \
         "${tmp}/checkouts/nested" "${inside_shared}"

printf '== workspace descriptor tests ==\n'

# --- happy path: a full declaration is written in the flat, grep-parsable form
if "${generator}" --checkout-root "${tmp}/checkouts" \
    --working-materials-root "${tmp}/work-a" \
    --working-materials-root "${tmp}/work-b" \
    --extra-root "${tmp}/extra" >/dev/null; then
  pass 'writes a full declaration'
else
  fail 'writes a full declaration'
fi

grep -q '^descriptor_version: 1$' "${out}" && pass 'stamps descriptor_version' || fail 'stamps descriptor_version'
grep -q "^AGENTIC_REPO_CHECKOUT_ROOT: ${tmp}/checkouts$" "${out}" \
  && pass 'declares the checkout root' || fail 'declares the checkout root'
grep -q "^AGENTIC_WORKING_MATERIALS_ROOT_1: ${tmp}/work-a$" "${out}" \
  && pass 'first working root keeps ordinal 1 (default output destination)' \
  || fail 'first working root keeps ordinal 1'
grep -q "^AGENTIC_WORKING_MATERIALS_ROOT_2: ${tmp}/work-b$" "${out}" \
  && pass 'second working root keeps ordinal 2' || fail 'second working root keeps ordinal 2'
grep -q "^AGENTIC_EXTRA_ROOT_1: ${tmp}/extra$" "${out}" \
  && pass 'declares extra roots' || fail 'declares extra roots'
grep -q "^AGENTIC_SUPPORT_ROOT: ${support_root}$" "${out}" \
  && pass 'derives the support root from its own location' || fail 'derives the support root'

# --- a re-run must never silently narrow an existing declaration
if "${generator}" --checkout-root "${tmp}/checkouts" \
    --working-materials-root "${tmp}/work-a" >/dev/null 2>&1; then
  fail 'refuses a re-run that would drop a declared root'
else
  pass 'refuses a re-run that would drop a declared root'
fi
grep -q "^AGENTIC_WORKING_MATERIALS_ROOT_2: ${tmp}/work-b$" "${out}" \
  && pass 'refused re-run left the existing declaration intact' \
  || fail 'refused re-run left the existing declaration intact'

# --- a re-run carrying the full set is allowed
if "${generator}" --checkout-root "${tmp}/checkouts" \
    --working-materials-root "${tmp}/work-b" \
    --working-materials-root "${tmp}/work-a" \
    --extra-root "${tmp}/extra" >/dev/null 2>&1; then
  pass 'allows a re-run that carries the full set (reordering is fine)'
else
  fail 'allows a re-run that carries the full set'
fi

# --- guards, each on a fresh output path
fresh() { export AGENTIC_WORKSPACE_DESCRIPTOR="${tmp}/fresh-$1.yaml"; }

fresh nonexistent
if "${generator}" --checkout-root "${tmp}/does-not-exist" \
    --working-materials-root "${tmp}/work-a" \
    --out "${AGENTIC_WORKSPACE_DESCRIPTOR}" >/dev/null 2>&1; then
  fail 'refuses a declared root that does not exist'
else
  pass 'refuses a declared root that does not exist'
fi

fresh nested
if "${generator}" --checkout-root "${tmp}/checkouts" \
    --working-materials-root "${tmp}/checkouts/nested" \
    --out "${AGENTIC_WORKSPACE_DESCRIPTOR}" >/dev/null 2>&1; then
  fail 'refuses nested declared roots'
else
  pass 'refuses nested declared roots'
fi

fresh duplicate
if "${generator}" --checkout-root "${tmp}/checkouts" \
    --working-materials-root "${tmp}/work-a" \
    --extra-root "${tmp}/work-a" \
    --out "${AGENTIC_WORKSPACE_DESCRIPTOR}" >/dev/null 2>&1; then
  fail 'refuses a root declared twice'
else
  pass 'refuses a root declared twice'
fi

fresh shared
if "${generator}" --checkout-root "${inside_shared}" \
    --working-materials-root "${tmp}/work-a" \
    --out "${AGENTIC_WORKSPACE_DESCRIPTOR}" >/dev/null 2>&1; then
  fail 'refuses a checkout root inside the shared workspace tree'
else
  pass 'refuses a checkout root inside the shared workspace tree'
fi

fresh missing-args
if "${generator}" --out "${AGENTIC_WORKSPACE_DESCRIPTOR}" >/dev/null 2>&1; then
  fail 'refuses a declaration with no roots'
else
  pass 'refuses a declaration with no roots'
fi

# --- the default descriptor location must never fall inside the shared tree,
#     or one member's declaration would sync to the whole team
case "${HOME}/.agentic-workspace/workspace-descriptor.yaml" in
  "${workspace_root}"/*) fail 'default descriptor path is inside the shared tree' ;;
  *) pass 'default descriptor path sits outside the shared tree' ;;
esac

printf '\n'
if (( failures > 0 )); then
  printf 'workspace descriptor tests: %s failure(s)\n' "${failures}" >&2
  exit 1
fi
printf 'workspace descriptor tests passed\n'
