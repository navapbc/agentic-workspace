#!/usr/bin/env bash
set -euo pipefail

# check-workspace.sh — the invariant gate for this workspace.
#
# Run after any structural or routing change, and in CI if the workspace is
# git-backed. Read-only. Requires bash and jq; uses rg/fd/shellcheck when present
# and degrades to find/grep when not, so it runs on a teammate's machine with no
# toolchain installed.
#
# Usage: check-workspace.sh [extra-lane-dir]...
#        (the support tree and the shared workspace root are always checked)
#
# Exit 0 = pass (warnings allowed), 1 = at least one invariant failed.

support_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
workspace_root=$(cd "${support_root}/.." && pwd)
skills_root="${support_root}/skills"
manifest="${skills_root}/skill-manifest.yaml"
fabric_root="${support_root}/context-fabric"
agents_line_budget="${AGENTIC_AGENTS_LINE_BUDGET:-40}"

lanes=("${workspace_root}")
for extra in "$@"; do
  [[ -d "${extra}" ]] || { printf 'ERROR: not a directory: %s\n' "${extra}" >&2; exit 1; }
  lanes+=("$(cd "${extra}" && pwd)")
done

failures=0
warnings=0
fail() { printf 'FAIL: %s\n' "$*" >&2; failures=$((failures + 1)); }
warn() { printf 'WARN: %s\n' "$*" >&2; warnings=$((warnings + 1)); }
require_file() { [[ -f "$1" ]] || fail "missing $1"; }

have() { command -v "$1" >/dev/null 2>&1; }
command -v jq >/dev/null 2>&1 || { printf 'ERROR: jq is required\n' >&2; exit 1; }

# Portable helpers: prefer the fast tools, fall back to POSIX ones.
find_files() { # dir name-pattern
  if have fd; then fd -H -t f "$2" "$1" 2>/dev/null || true
  else find "$1" -type f -name "$2" -not -path '*/.git/*' 2>/dev/null || true; fi
}
grep_tree() { # extended-regex dir...
  local pat="$1"; shift
  if have rg; then rg -n --hidden -g '!.git' -e "${pat}" "$@" 2>/dev/null || true
  else grep -rEnI --exclude-dir=.git -e "${pat}" "$@" 2>/dev/null || true; fi
}

# --- 1. Required support-tree files ----------------------------------------
for required in README.md AGENTS.md CONCEPTS.md \
  docs/architecture.md docs/contributing.md docs/placement-doctrine.md \
  docs/skill-binding-contract.md docs/skill-bundle-pattern.md \
  docs/workspace-routing.md docs/context-source-ladder.md \
  context-fabric/README.md context-fabric/docs/authoring.md \
  skills/skill-manifest.yaml \
  templates/checkouts-root/AGENTS.md \
  tools/workspace-doctor.sh tools/generate-workspace-descriptor.sh; do
  require_file "${support_root}/${required}"
done
require_file "${workspace_root}/AGENTS.md"

# --- 2. Manifest <-> skill consistency -------------------------------------
# The manifest is the availability authority; the SKILL.md is the behavior
# authority. Either one existing without the other is a lie to every session.
manifest_ids=''
current_id=''; current_path=''; current_status=''; current_review=''

check_entry() {
  [[ -n "${current_id}" ]] || return 0
  manifest_ids+="${current_id}"$'\n'

  if [[ -z "${current_path}" || -z "${current_status}" ]]; then
    fail "manifest entry '${current_id}' is missing path or status"
    return 0
  fi
  if [[ "${current_path}" != "${current_id}/SKILL.md" ]]; then
    fail "manifest id/path mismatch: ${current_id} -> ${current_path}"
  fi
  case "${current_status}" in
    enabled) ;;
    partially-paused|paused)
      [[ -n "${current_review}" ]] || fail "manifest entry '${current_id}' is ${current_status} without a review_by date" ;;
    *) fail "invalid manifest status for ${current_id}: ${current_status}" ;;
  esac

  local skill_file="${skills_root}/${current_path}"
  if [[ ! -f "${skill_file}" ]]; then
    fail "manifest entry '${current_id}' has no canonical skill at ${current_path}"
    return 0
  fi

  local field
  for field in workflow_id version status owner source_of_truth portable_across_harnesses; do
    grep -Eq "^${field}:" "${skill_file}" || fail "skill frontmatter missing ${field}: ${current_path}"
  done
  local declared_workflow
  declared_workflow=$(sed -n 's/^workflow_id: *//p' "${skill_file}" | head -1 | tr -d "'\"")
  [[ "${declared_workflow}" == "${current_id}" ]] || \
    fail "skill workflow_id '${declared_workflow}' != manifest id '${current_id}': ${current_path}"

  local section
  for section in Procedure Guardrails 'Output Shape' 'Failure Handling' 'Harness Interpretation'; do
    grep -Fxq "## ${section}" "${skill_file}" || fail "skill section missing '${section}': ${current_path}"
  done
}

while IFS= read -r raw; do
  case "${raw}" in
    *'- id:'*)
      check_entry
      current_id="${raw#*- id: }"; current_id="${current_id%\"}"; current_id="${current_id#\"}"
      current_path=''; current_status=''; current_review='' ;;
    *'path:'*)      current_path="${raw#*path: }" ;;
    *'status:'*)    current_status="${raw#*status: }" ;;
    *'review_by:'*) current_review="${raw#*review_by: }" ;;
  esac
done < <(sed -n '/^skills:/,/^[a-z_]*:/p' "${manifest}")
check_entry

# Every canonical skill on disk must be registered (adapters are not skills).
while IFS= read -r skill_file; do
  [[ -n "${skill_file}" ]] || continue
  case "${skill_file}" in */adapters/*) continue ;; esac
  rel="${skill_file#"${skills_root}/"}"
  depth=$(printf '%s' "${rel}" | tr -cd '/' | wc -c | tr -d ' ')
  [[ "${depth}" == "1" ]] || continue
  printf '%s' "${manifest_ids}" | grep -Fxq "${rel%/SKILL.md}" || \
    fail "canonical skill missing from manifest: ${rel}"
done < <(find_files "${skills_root}" 'SKILL.md')

# --- 3. Binding contract: no user-home absolute defaults -------------------
if grep_tree '(/Users/[A-Za-z0-9._-]+|/home/[A-Za-z0-9._-]+|[A-Za-z]:\\Users\\)' \
  "${skills_root}" "${support_root}/tools" "${support_root}/docs" | grep -q .; then
  fail 'user-home absolute path in a skill, tool, or doc; use a binding token (docs/skill-binding-contract.md)'
  grep_tree '(/Users/[A-Za-z0-9._-]+|/home/[A-Za-z0-9._-]+|[A-Za-z]:\\Users\\)' \
    "${skills_root}" "${support_root}/tools" "${support_root}/docs" >&2
fi

# --- 4. No sibling-relative cross-root references --------------------------
# Roots share no common parent, so `../<other-root>/` cannot resolve anywhere.
# Shared materials use descriptor binding tokens instead.
checkout_dir_names='(repo-checkouts|checkouts|code-checkouts)'
if grep_tree "(\\.\\./)+${checkout_dir_names}" "${support_root}" "${lanes[@]}" | grep -q .; then
  # shellcheck disable=SC2016  # the binding token is a literal, not an expansion
  fail 'sibling-relative checkout reference found; use the ${AGENTIC_REPO_CHECKOUT_ROOT}/ binding token (docs/workspace-routing.md)'
  grep_tree "(\\.\\./)+${checkout_dir_names}" "${support_root}" "${lanes[@]}" >&2
fi

# --- 5. Thin AGENTS.md doctrine --------------------------------------------
# Procedure content in an always-loaded file is paid for in every session and
# drifts from the skill it was copied out of. Fail on the markers; warn on length,
# because exception-heavy areas can legitimately run long.
while IFS= read -r agents_file; do
  [[ -n "${agents_file}" ]] || continue
  if grep -Eq '^#{1,3} (Procedure|Steps|Output Shape|Failure Handling|Harness Interpretation)$|^workflow_id:' "${agents_file}"; then
    fail "AGENTS.md carries skill-procedure content (see docs/placement-doctrine.md): ${agents_file}"
  fi
  lines=$(wc -l < "${agents_file}" | tr -d ' ')
  (( lines > agents_line_budget )) && \
    warn "AGENTS.md exceeds the ${agents_line_budget}-line thinness budget (${lines} lines): ${agents_file}"
  d=$(dirname "${agents_file}")
  [[ -f "${d}/CLAUDE.md" ]] || warn "no CLAUDE.md import beside ${agents_file}"
done < <(for lane in "${support_root}" "${lanes[@]}"; do find_files "${lane}" 'AGENTS.md'; done | sort -u)

# --- 6. Nothing that must never be shared ----------------------------------
secret_pat='ghp_[A-Za-z0-9]{36}|github_pat_[A-Za-z0-9_]{40,}|xox[baprs]-[A-Za-z0-9-]{12,}|-----BEGIN [A-Z ]*PRIVATE KEY-----'
if grep_tree "${secret_pat}" "${support_root}" "${lanes[@]}" | grep -q .; then
  fail 'token-shaped value found in the shared tree; rotate it and remove it'
fi
if grep_tree 'op://[A-Za-z0-9._-]+/[A-Za-z0-9._-]+' "${support_root}" "${lanes[@]}" | grep -q .; then
  fail 'secret-manager reference found; inject secrets at runtime, never store references'
fi
for lane in "${support_root}" "${lanes[@]}"; do
  if find "${lane}" -name node_modules -type d -not -path '*/.git/*' 2>/dev/null | grep -q .; then
    fail "dependency folder present in the shared tree: ${lane}"
  fi
  if find "${lane}" \( -name '.DS_Store' -o -name 'Icon?' -o -name '.env' -o -name '.env.*' \) \
    -not -path '*/.git/*' 2>/dev/null | grep -q .; then
    warn "OS metadata or .env file present: ${lane}"
  fi
done
# A nested .git inside the support tree means a checkout leaked in.
if find "${support_root}" -mindepth 2 -maxdepth 5 -name .git 2>/dev/null | grep -q .; then
  fail 'nested git checkout inside the support tree; checkouts belong in the machine-local checkout root'
fi

# --- 7. Member-specific harness state in the shared tree (warn) ------------
# Warn, not fail: a harness recreates these whenever a session opens with a
# shared folder as its primary folder. The launch shape is the fix, not the gate.
while IFS= read -r hit; do
  [[ -n "${hit}" ]] && warn "member-specific harness state inside the shared tree: ${hit}"
done < <(find "${workspace_root}" -maxdepth 4 \
  \( -name 'settings.local.json' -o -name '*.code-workspace' \) 2>/dev/null)
if [[ ! -d "${workspace_root}/.git" ]]; then
  while IFS= read -r hit; do
    [[ -n "${hit}" ]] && warn "harness config directory inside a non-git shared tree: ${hit}"
  done < <(find "${workspace_root}" -maxdepth 3 \
    \( -name '.claude' -o -name '.codex' -o -name '.gemini' \) 2>/dev/null)
fi

# --- 8. Context Fabric structure ------------------------------------------
while IFS= read -r json_file; do
  [[ -n "${json_file}" ]] || continue
  jq empty "${json_file}" 2>/dev/null || fail "invalid JSON: ${json_file}"
done < <(find "${fabric_root}" -type f -name '*.json' 2>/dev/null)

if ! "${support_root}/tools/lint-context-fabric-records.sh" --all; then
  fail 'Context Fabric record lint failed'
fi

# --- 9. Tools are shell-clean (when shellcheck is available) ---------------
if have shellcheck; then
  # shellcheck disable=SC2046  # deliberate word splitting over the file list
  if ! shellcheck -S warning $(find "${support_root}/tools" "${support_root}/validation" -name '*.sh' 2>/dev/null); then
    fail 'shellcheck reported problems in tools/ or validation/'
  fi
else
  warn 'shellcheck not installed; skipped shell linting of tools/'
fi

# --- 10. Component test suites --------------------------------------------
for suite in workspace-descriptor workspace-doctor; do
  test_file="${support_root}/validation/test/${suite}.test.sh"
  [[ -x "${test_file}" ]] || continue
  "${test_file}" || fail "${suite} test suite failed"
done

printf '\n'
if (( failures > 0 )); then
  printf 'RESULT: FAIL — %s invariant failure(s), %s warning(s)\n' "${failures}" "${warnings}" >&2
  exit 1
fi
if (( warnings > 0 )); then
  printf 'RESULT: PASS with %s warning(s)\n' "${warnings}"
else
  printf 'RESULT: PASS\n'
fi
