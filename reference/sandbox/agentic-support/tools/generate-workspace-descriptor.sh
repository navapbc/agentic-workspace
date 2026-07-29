#!/usr/bin/env bash
set -euo pipefail

# generate-workspace-descriptor.sh — write this machine's declared workspace descriptor.
#
# The descriptor is the per-machine source of workspace-owned bindings
# (docs/skill-binding-contract.md). Roots are DECLARED by the member — normally
# through the workspace-setup skill — never derived from sibling directories or
# directory shape. It is machine-local and never synced or committed; writing it
# under ~/.agentic-workspace/ keeps it out of every synced tree by construction.
# After moving or reorganizing a root, re-run the generator with the FULL set of
# declared roots; it refuses to silently narrow an existing declaration.
#
# Usage:
#   generate-workspace-descriptor.sh \
#     --checkout-root <path> \
#     --working-materials-root <path> [--working-materials-root <path>]... \
#     [--extra-root <path>]... \
#     [--out <path>]
#
# Default output: ${AGENTIC_WORKSPACE_DESCRIPTOR:-~/.agentic-workspace/workspace-descriptor.yaml}
# Schema: context-fabric/schemas/workspace-descriptor/1.0.0/schema.json

support_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
workspace_root=$(cd "${support_root}/.." && pwd)
product_work_dir="${AGENTIC_PRODUCT_WORK_DIR:-product-work}"
product_work_lane="${workspace_root}/${product_work_dir}"

out="${AGENTIC_WORKSPACE_DESCRIPTOR:-${HOME}/.agentic-workspace/workspace-descriptor.yaml}"
checkout_root=""
working_roots=()
extra_roots=()

fail() { printf 'ERROR: %s\n' "$1" >&2; exit 1; }

usage() {
  printf 'Usage: %s --checkout-root <path> --working-materials-root <path> [--working-materials-root <path>]... [--extra-root <path>]... [--out <path>]\n' \
    "$(basename "${BASH_SOURCE[0]}")" >&2
}

require_value() { # flag value...
  [[ $# -ge 2 && -n "$2" ]] || { usage; fail "missing value for $1"; }
}

while (($#)); do
  case "$1" in
    --checkout-root) require_value "$@"; checkout_root="$2"; shift 2 ;;
    --working-materials-root) require_value "$@"; working_roots+=("$2"); shift 2 ;;
    --extra-root) require_value "$@"; extra_roots+=("$2"); shift 2 ;;
    --out) require_value "$@"; out="$2"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) usage; fail "unknown argument: $1" ;;
  esac
done

# Read any existing declaration first: a re-run must never silently drop roots.
existing_roots=()
if [[ -f "${out}" ]]; then
  while IFS= read -r line; do
    existing_roots+=("${line#*: }")
  done < <(grep -E '^(AGENTIC_REPO_CHECKOUT_ROOT|AGENTIC_WORKING_MATERIALS_ROOT_[0-9]+|AGENTIC_EXTRA_ROOT_[0-9]+): ' "${out}" || true)
fi

if [[ -z "${checkout_root}" || ${#working_roots[@]} -eq 0 ]]; then
  if [[ ${#existing_roots[@]} -gt 0 ]]; then
    printf 'ERROR: missing required declarations. The existing descriptor at %s declares:\n' "${out}" >&2
    printf '  %s\n' "${existing_roots[@]}" >&2
    printf 'Re-run with the full set of roots (--checkout-root, --working-materials-root ..., --extra-root ...).\n' >&2
    exit 1
  fi
  usage
  fail 'required: --checkout-root <path> and at least one --working-materials-root <path>'
fi

norm() { # resolve to a normalized logical path; fails when the directory is absent
  (cd -- "$1" 2>/dev/null && pwd) || return 1
}
pnorm() { # physical resolution for comparisons; falls back to the literal value
  (cd -- "$1" 2>/dev/null && pwd -P) || printf '%s' "$1"
}

checkout_root_norm="$(norm "${checkout_root}")" || fail "declared root does not exist: ${checkout_root}"
normalized_working=()
for r in "${working_roots[@]}"; do
  normalized_working+=("$(norm "${r}")") || fail "declared root does not exist: ${r}"
done
normalized_extra=()
for r in ${extra_roots[@]+"${extra_roots[@]}"}; do
  normalized_extra+=("$(norm "${r}")") || fail "declared root does not exist: ${r}"
done

# The checkout root must sit outside the shared workspace tree: git internals
# inside a synced folder would replicate to the whole team. Compare physical
# forms so no indirection (symlink, alias) evades the rule.
checkout_root_phys="$(pnorm "${checkout_root_norm}")"
workspace_root_phys="$(pnorm "${workspace_root}")"
case "${checkout_root_phys}" in
  "${workspace_root_phys}"|"${workspace_root_phys}"/*)
    fail "checkout root must sit outside the shared workspace tree: ${checkout_root_norm}"
    ;;
esac

all_roots=("${checkout_root_norm}" "${normalized_working[@]}" ${normalized_extra[@]+"${normalized_extra[@]}"})

# Declared roots must not nest or repeat: nesting duplicates trees in harness
# pickers, makes role resolution ambiguous, and reopens the
# checkout-inside-a-synced-root data-safety hole. Comparisons use physical
# paths so symlink indirection cannot evade the rule.
all_roots_phys=()
for r in "${all_roots[@]}"; do
  all_roots_phys+=("$(pnorm "${r}")")
done
count=${#all_roots_phys[@]}
for ((i = 0; i < count; i++)); do
  for ((j = 0; j < count; j++)); do
    [[ ${i} -eq ${j} ]] && continue
    a="${all_roots_phys[i]}"
    b="${all_roots_phys[j]}"
    if [[ "${a}" == "${b}" && ${i} -lt ${j} ]]; then
      fail "declared roots must be distinct: ${all_roots[i]} is declared twice"
    fi
    if [[ "${b}" == "${a}"/* ]]; then
      fail "declared roots must not nest: ${all_roots[j]} is inside ${all_roots[i]}"
    fi
  done
done

if [[ ${#existing_roots[@]} -gt 0 ]]; then
  missing=()
  for prev in "${existing_roots[@]}"; do
    prev_phys="$(pnorm "${prev}")"
    found=0
    for cur in "${all_roots_phys[@]}"; do
      [[ "${cur}" == "${prev_phys}" ]] && { found=1; break; }
    done
    ((found)) || missing+=("${prev}")
  done
  if [[ ${#missing[@]} -gt 0 ]]; then
    printf 'ERROR: re-run would drop previously declared root(s):\n' >&2
    printf '  %s\n' "${missing[@]}" >&2
    printf 'Include them in the new declaration; to retire a root intentionally, delete %s and re-declare the full set.\n' "${out}" >&2
    exit 1
  fi
fi

# Role-based product-work binding: the product-work lane is bound only when the
# member declared it as a working-materials root — never machine-wide.
product_work_root=""
if [[ -d "${product_work_lane}" ]]; then
  product_work_lane_norm="$(norm "${product_work_lane}")"
  for r in "${normalized_working[@]}"; do
    [[ "${r}" == "${product_work_lane_norm}" ]] && product_work_root="${r}"
  done
fi

lane() { # name path — emit binding only when the path exists
  if [[ -d "$2" ]]; then
    printf '%s: %s\n' "$1" "$2"
  else
    printf '# %s: unavailable (no directory at %s)\n' "$1" "$2"
  fi
}

mkdir -p "$(dirname "${out}")"
{
  printf '# Machine-local workspace descriptor. Generated by\n'
  printf '# agentic-support/tools/generate-workspace-descriptor.sh — do not sync, share,\n'
  printf '# or hand-edit. Roots are declared, not derived: re-run the generator with the\n'
  printf '# full set of declared roots after moving or reorganizing one.\n'
  printf '# Schema: context-fabric/schemas/workspace-descriptor/1.0.0/schema.json\n'
  printf 'descriptor_version: 1\n'
  printf 'generated_at: %s\n' "$(date +%Y-%m-%d)"
  lane 'AGENTIC_WORKSPACE_ROOT' "${workspace_root}"
  lane 'AGENTIC_SUPPORT_ROOT' "${support_root}"
  lane 'AGENTIC_CONTEXT_FABRIC_ROOT' "${support_root}/context-fabric"
  if [[ -n "${product_work_root}" ]]; then
    printf 'AGENTIC_PRODUCT_WORK_ROOT: %s\n' "${product_work_root}"
  fi
  printf 'AGENTIC_REPO_CHECKOUT_ROOT: %s\n' "${checkout_root_norm}"
  index=1
  for r in "${normalized_working[@]}"; do
    printf 'AGENTIC_WORKING_MATERIALS_ROOT_%d: %s\n' "${index}" "${r}"
    index=$((index + 1))
  done
  index=1
  for r in ${normalized_extra[@]+"${normalized_extra[@]}"}; do
    printf 'AGENTIC_EXTRA_ROOT_%d: %s\n' "${index}" "${r}"
    index=$((index + 1))
  done
} > "${out}"

printf 'Wrote %s\n' "${out}"
