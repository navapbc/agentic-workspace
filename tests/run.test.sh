#!/usr/bin/env bash
# U1 -- tests/run.sh itself. The runner is the gate, and its exit taxonomy is the
# invariant the whole verification story rests on: a skipped stage must never
# report 0. Nothing else exercises it, so this pins it end to end.
#
# Every case runs against a throwaway copy of the tree, with probe test scripts
# planted in it and selected by name, so the real tests never run here.
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=tests/lib.sh
. "$HERE/lib.sh"

ROOT="$(repo_root)"
cd "$ROOT"

COPY="$(tmp_repo_copy)"

plant() {
  # plant <name> <body-line>
  cat > "$COPY/tests/$1.test.sh" <<EOF
#!/usr/bin/env bash
set -euo pipefail
. "\$(cd "\$(dirname "\${BASH_SOURCE[0]}")" && pwd)/lib.sh"
$2
EOF
}

run_copy() {
  local rc=0
  # CE_REPO_ROOT must be cleared: tests/run.sh exports it, so without this the
  # copy's runner would resolve the REAL repository and refuse (exit 2) --
  # correctly, which is what the anchor guard is for.
  ( cd "$COPY" && env -u CE_REPO_ROOT bash tests/run.sh "$@" ) >/dev/null 2>&1 || rc=$?
  printf '%s\n' "$rc"
}

expect() {
  # expect <want> <got> <what>
  [ "$1" = "$2" ] || fail "$3: expected exit $1, got $2"
  pass "$3 -> exit $2"
}

plant zzpass   'pass "probe"'
plant zzskip   'note_skip ZZ_OPTIONAL_TOOL_ABSENT "an optional tool is absent"
finish'
plant zzhard   'skip ZZ_CANNOT_RUN "the whole script cannot run"'
plant zzusage  'usage_error "a required tool is absent"'
plant zzfail   'fail "a check failed"'

expect 0 "$(run_copy zzpass)"                        "a passing test"
expect 3 "$(run_copy zzskip)"                        "a deferred skip (note_skip + finish)"
expect 3 "$(run_copy zzhard)"                        "an immediate skip"
expect 2 "$(run_copy zzusage)"                       "a usage/environment error"
expect 1 "$(run_copy zzfail)"                        "a failed check"

# Precedence: 1 beats 2 beats 3 beats 0. A skip must never be masked by a pass,
# and must never mask a real failure.
expect 3 "$(run_copy zzpass zzskip)"                 "pass + skip"
expect 2 "$(run_copy zzpass zzskip zzusage)"         "pass + skip + usage error"
expect 1 "$(run_copy zzpass zzskip zzusage zzfail)"  "pass + skip + usage error + failure"
expect 1 "$(run_copy zzskip zzfail)"                 "skip + failure"

# Skip codes. Exit 3 alone cannot tell a skip CI could never satisfy (the
# git-ignored real-name list) from a check that silently did not run, so CI
# reads the codes instead. Two properties hold that up: an unclassified skip
# must be impossible to write, and the codes must actually reach the summary.
run_copy_out() {
  ( cd "$COPY" && env -u CE_REPO_ROOT bash tests/run.sh "$@" ) 2>/dev/null || true
}

plant zzuncoded 'note_skip "no code at all"
finish'
expect 2 "$(run_copy zzuncoded)"                     "a skip with no code is a usage error, not a silent pass"

plant zzlower   'note_skip not_screaming "lowercase code"
finish'
expect 2 "$(run_copy zzlower)"                       "a skip whose code is not SCREAMING_SNAKE is a usage error"

codes_line="$(run_copy_out zzskip zzhard | sed -n 's/^SKIPPED_CODES: //p')"
case " $codes_line " in
  *" ZZ_OPTIONAL_TOOL_ABSENT "*) : ;;
  *) fail "SKIPPED_CODES omitted a deferred skip's code; got '$codes_line'" ;;
esac
case " $codes_line " in
  *" ZZ_CANNOT_RUN "*) : ;;
  *) fail "SKIPPED_CODES omitted an immediate skip's code; got '$codes_line'" ;;
esac
pass "SKIPPED_CODES names every stage that skipped -> $codes_line"

if run_copy_out zzpass | grep -q '^SKIPPED_CODES:'; then
  fail "a run with no skips still printed a SKIPPED_CODES line"
fi
pass "a run with no skips prints no SKIPPED_CODES line"

# A test script that crashes without using the library still fails the run.
printf '#!/usr/bin/env bash\nexit 42\n' > "$COPY/tests/zzcrash.test.sh"
expect 1 "$(run_copy zzcrash)"                       "an unrecognized non-zero exit"
printf '#!/usr/bin/env bash\nthis-command-does-not-exist\n' > "$COPY/tests/zzmissing.test.sh"
expect 1 "$(run_copy zzmissing)"                     "a test that dies on a missing command"

# Flags.
expect 0 "$(run_copy --help)"                        "--help"
expect 0 "$(run_copy --list)"                        "--list"
expect 2 "$(run_copy --bogus)"                       "an unknown flag"
expect 2 "$(run_copy no-such-test)"                  "a selection that matches nothing"

# --list must name every planted probe, so a test file cannot land undiscovered.
listed="$( (cd "$COPY" && env -u CE_REPO_ROOT bash tests/run.sh --list) | sed 's#.*/##' | sort)"
for want in zzpass.test.sh zzskip.test.sh repo-baseline.test.sh run.test.sh; do
  printf '%s\n' "$listed" | grep -qx "$want" || fail "--list did not report $want"
done
pass "--list reports every test file in tests/, including this one"

# The runner must notice a test that dirtied the tree it was given.
# shellcheck disable=SC2016  # the probe body is code for the planted script, not this one.
plant zzdirty 'printf "x\n" > "$(repo_root)/tests/__left_behind__.txt"
pass "probe wrote a file"'
expect 1 "$(run_copy zzdirty)"                       "a test that leaves the tree dirty"
rm -f "$COPY/tests/__left_behind__.txt"

# And a test that quietly rewrites a file that was already modified.
printf '\n# already dirty before the run\n' >> "$COPY/tests/lib.sh"
# shellcheck disable=SC2016  # the probe body is code for the planted script, not this one.
plant zzrewrite 'printf "\n# rewritten by the probe\n" >> "$(repo_root)/tests/lib.sh"
pass "probe appended to an already-dirty file"'
expect 1 "$(run_copy zzrewrite)"                     "a test that rewrites an already-dirty file"

# The anchor guard: a runner invoked with CE_REPO_ROOT pointing somewhere else
# must refuse (exit 2) rather than test a checkout it did not draw its tests from.
guard_rc=0
( cd "$COPY" && CE_REPO_ROOT="$ROOT" bash tests/run.sh zzpass ) >/dev/null 2>&1 || guard_rc=$?
expect 2 "$guard_rc" "a runner pointed at a different checkout"

printf '\nrun: checks complete\n'
finish
