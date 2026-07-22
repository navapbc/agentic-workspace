#!/bin/sh
# Check a shared agentic workspace for the invariants that keep it safe and consistent.
# Generalized from an internal validation script.
#
# Usage:
#   ./validate-workspace.sh [workspace-dir]   (default: current directory)
#
# Checks:
#   - required files exist (root AGENTS.md; CLAUDE.md mirror if any AGENTS.md exists)
#   - no secrets (token-shaped strings, op:// URIs)
#   - no code checkouts, dependency folders, or OS metadata committed
#   - no absolute machine paths in shared files
#   - every JSON file parses
#   - AGENTS.md files are thin (warns past a line threshold)
# Exits non-zero if any hard check fails.

set -eu

ws="${1:-$(pwd)}"
[ -d "$ws" ] || { printf 'error: not a directory: %s\n' "$ws" >&2; exit 2; }

fail=0
warn=0
err()  { printf 'FAIL  %s\n' "$1" >&2; fail=1; }
note() { printf 'WARN  %s\n' "$1" >&2; warn=1; }
ok()   { printf 'ok    %s\n' "$1"; }

have() { command -v "$1" >/dev/null 2>&1; }

# Prefer ripgrep; fall back to grep -E. Both take an extended-regex pattern.
search() {
  pat=$1
  if have rg; then rg -n --hidden -g '!.git' "$pat" "$ws" 2>/dev/null
  else grep -rEnI "$pat" "$ws" 2>/dev/null; fi
}

# 1. Required files.
if [ -f "$ws/AGENTS.md" ]; then ok "root AGENTS.md present"
else err "root AGENTS.md missing"; fi

# CLAUDE.md mirror wherever an AGENTS.md exists.
if have fd; then agents=$(fd -H -t f '^AGENTS\.md$' "$ws" 2>/dev/null || true)
else agents=$(find "$ws" -name AGENTS.md -not -path '*/.git/*' 2>/dev/null || true); fi
printf '%s\n' "$agents" | while IFS= read -r a; do
  [ -n "$a" ] || continue
  d=$(dirname "$a")
  [ -f "$d/CLAUDE.md" ] || printf 'WARN  no CLAUDE.md mirror beside %s\n' "$a" >&2
done

# 2. No secrets. Patterns require realistic length/shape so guardrail *documentation*
#    (text that mentions "op://" or "ghp_" as things to avoid) does not trip the check.
secret_pat='ghp_[A-Za-z0-9]{36}|github_pat_[A-Za-z0-9_]{40,}|xox[baprs]-[A-Za-z0-9-]{12,}|-----BEGIN [A-Z ]*PRIVATE KEY-----|Bearer [A-Za-z0-9._-]{20,}'
if search "$secret_pat" >/dev/null 2>&1; then
  err "possible secret/token found:"; search "$secret_pat" >&2 || true
else ok "no token-shaped secrets"; fi

# A real 1Password reference looks like op://<vault>/<item>...; a bare "op://" in prose does not.
if search 'op://[A-Za-z0-9._-]+/[A-Za-z0-9._-]+' >/dev/null 2>&1; then
  err "1Password op:// reference found; inject secrets at runtime, do not store references:"
  search 'op://[A-Za-z0-9._-]+/[A-Za-z0-9._-]+' >&2 || true
else ok "no op:// references"; fi

# 3. No checkouts / deps / OS metadata.
if find "$ws" -name node_modules -type d -not -path '*/.git/*' 2>/dev/null | grep -q .; then
  err "node_modules present; dependency folders must not be committed"
else ok "no node_modules"; fi

if find "$ws" \( -name '.DS_Store' -o -name 'Icon?' -o -name '.env' -o -name '.env.*' \) -not -path '*/.git/*' 2>/dev/null | grep -q .; then
  note "OS metadata or .env files present (.DS_Store / Icon / .env*)"
else ok "no OS metadata or .env files"; fi

# Nested .git inside the workspace suggests a code checkout living inside it.
if find "$ws" -mindepth 2 -name .git -maxdepth 4 2>/dev/null | grep -q .; then
  note "nested .git found; code checkouts should live outside the workspace"
else ok "no nested code checkouts"; fi

# 4. Absolute machine paths in shared markdown (bindings should be used instead).
if search '/Users/[A-Za-z]|/home/[A-Za-z]' >/dev/null 2>&1; then
  note "absolute machine path(s) in files; prefer bindings (\${SUPPORT_ROOT}, ...)"
else ok "no absolute machine paths"; fi

# 5. JSON parseability. Collect failures in a temp file so the count survives the loop.
if have jq; then
  if have fd; then jsons=$(fd -H -e json . "$ws" 2>/dev/null || true)
  else jsons=$(find "$ws" -name '*.json' -not -path '*/.git/*' 2>/dev/null || true); fi
  bad=$(mktemp)
  printf '%s\n' "$jsons" | while IFS= read -r j; do
    [ -n "$j" ] || continue
    jq empty "$j" >/dev/null 2>&1 || printf '%s\n' "$j" >> "$bad"
  done
  if [ -s "$bad" ]; then
    while IFS= read -r j; do err "invalid JSON: $j"; done < "$bad"
  else
    ok "all JSON parses"
  fi
  rm -f "$bad"
else
  note "jq not installed; skipped JSON parse check"
fi

# 6. Thin AGENTS.md (advisory).
printf '%s\n' "$agents" | while IFS= read -r a; do
  [ -n "$a" ] || continue
  lines=$(wc -l < "$a" | tr -d ' ')
  [ "$lines" -le 60 ] || printf 'WARN  %s is %s lines; keep AGENTS.md thin (<=60)\n' "$a" "$lines" >&2
done

printf '\n'
if [ "$fail" -ne 0 ]; then
  printf 'RESULT: FAIL (fix the FAIL items above)\n' >&2
  exit 1
elif [ "$warn" -ne 0 ]; then
  printf 'RESULT: PASS with warnings\n'
else
  printf 'RESULT: PASS\n'
fi
