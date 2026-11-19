#!/usr/bin/env bash
# Offline tests for .apm/skills/feat/scripts/story.sh (mise run test:story).
#
# Fixtures: two real tasks.md files (006, 009) and synthetic ones under
# fixtures/; expected outputs under expected/. Every case also checks that
# stderr is empty.
set -euo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
root="$(cd "$here/../.." && pwd -P)"
script="$root/.apm/skills/feat/scripts/story.sh"
fx="$here/fixtures"
ex="$here/expected"

current="setup"
fail() {
  printf 'FAIL %s: %s\n' "$current" "$1"
  if [ -n "${out+x}" ]; then printf '  output: %s\n' "$out"; fi
  exit 1
}

work="$(mktemp -d)"
trap 'command rm -rf -- "$work"' EXIT

new_case() {
  current="$1"
  unset out
}

# run <args>: run the script; sets $out and $rc, checks stderr is empty.
run() {
  rc=0
  out="$(bash "$script" "$@" 2>"$work/stderr")" || rc=$?
  [ ! -s "$work/stderr" ] || fail "stderr not empty: $(head -n 1 "$work/stderr")"
}

expect_rc() { [ "$rc" = "$1" ] || fail "exit $rc, want $1"; }
# expect_file <file>: the output equals the file.
expect_file() { [ "$out" = "$(cat "$1")" ] || fail "output differs from $1"; }
expect_line() { [ "$(printf '%s\n' "$out" | sed -n "$1p")" = "$2" ] || fail "line $1 is not: $2"; }
expect_has() { grep -qxF -- "$1" <<<"$out" || fail "no line: $1"; }
expect_lacks() { ! grep -qF -- "$1" <<<"$out" || fail "output holds: $1"; }
# expect_error <fragment>: exit 1, one story: error: line holding fragment.
expect_error() {
  expect_rc 1
  [ "$(printf '%s\n' "$out" | wc -l)" = 1 ] || fail "not one line"
  [[ "$out" == "story: error: "*"$1"* ]] || fail "want error with: $1"
}
# expect_usage: exit 2, one story: usage: line.
expect_usage() {
  expect_rc 2
  [ "$(printf '%s\n' "$out" | wc -l)" = 1 ] || fail "not one line"
  [[ "$out" == "story: usage: "* ]] || fail "want a usage line"
}
ok() { printf 'ok %s\n' "$current"; }

# --- cases -------------------------------------------------------------------

new_case "real fixtures, all stories"
for n in 006 009; do
  run "$fx/$n-tasks.md"
  expect_rc 0
  expect_file "$ex/$n-all.txt"
done
ok

new_case "real fixtures, one-story headers"
for c in "009 US1|US1: 2 tasks; setup/foundational: 2 tasks; 0 unchecked" \
  "009 US5|US5: 7 tasks; polish: 3 tasks; 0 unchecked" \
  "006 US2|US2: 3 tasks; setup/foundational: 5 tasks; 0 unchecked" \
  "006 US1|US1: 10 tasks; 0 unchecked" \
  "006 US4|US4: 5 tasks; polish: 7 tasks; 0 unchecked"; do
  args=${c%%|*}
  run "$fx/${args%% *}-tasks.md" "${args##* }"
  expect_rc 0
  expect_line 1 "${c#*|}"
done
ok

new_case "setup first, polish last (009 US1, compact lines)"
run "$fx/009-tasks.md" US1
expect_rc 0
expect_file "$ex/009-us1.txt"
expect_line 2 "T001 [x] paths: none"
ok

new_case "mixed file, all stories"
run "$fx/mixed-tasks.md"
expect_rc 0
expect_file "$ex/mixed-all.txt"
ok

new_case "mixed file, one story"
for n in 1 2 3; do
  run "$fx/mixed-tasks.md" "US$n"
  expect_rc 0
  expect_file "$ex/mixed-us$n.txt"
done
ok

new_case "paths: none, several, command, bare path, [P]"
run "$fx/mixed-tasks.md" US1
expect_has "T001 [ ] paths: none"
expect_has "T002 [x] paths: docs/a.md docs/b.md"
expect_has "T003 [x] paths: lib/x.sh"
expect_has "T005 [x] paths: none"
expect_lacks "mise run"
expect_lacks "src/bare.md"
expect_lacks "SendMessage"
expect_has "T006 [ ] paths: README.md"
ok

new_case "placeholder, glob and URL spans"
run "$fx/mixed-tasks.md" US1
expect_has "T004 [ ] paths: src/real.py"
expect_lacks "<feature>"
expect_lacks "*.svg"
expect_lacks "example.com"
expect_line 8 "files: docs/a.md docs/b.md lib/x.sh src/real.py README.md"
ok

new_case "checked and unchecked"
run "$fx/mixed-tasks.md" US1
n="$(grep -c ' \[ \] paths:' <<<"$out")"
[[ "$(sed -n 1p <<<"$out")" == *"; $n unchecked" ]] || fail "unchecked count is not $n"
expect_has "T003 [x] paths: lib/x.sh"
ok

new_case "-- before the path"
run "$fx/mixed-tasks.md" US2
a="$out"
run -- "$fx/mixed-tasks.md" US2
[ "$out" = "$a" ] || fail "output differs with --"
run -- "$fx/mixed-tasks.md"
a="$out"
run "$fx/mixed-tasks.md"
[ "$out" = "$a" ] || fail "all-stories output differs with --"
ok

new_case "no backtick in the output"
for f in 006 009 mixed; do
  run "$fx/$f-tasks.md"
  expect_lacks '`'
  for u in US1 US2 US3; do
    run "$fx/$f-tasks.md" "$u"
    if [ "$rc" = 0 ]; then expect_lacks '`'; fi
  done
done
ok

new_case "story with no tasks of its own"
run "$fx/mixed-tasks.md" US3
expect_rc 0
expect_line 1 "US3: 0 tasks; polish: 1 tasks; 1 unchecked"
ok

new_case "task line inside a code fence"
run "$fx/mixed-tasks.md"
expect_lacks "T099"
expect_line 6 "total: 8 tasks"
ok

new_case "path candidate with glob characters stays literal"
mkdir "$work/glob"
printf 'x' > "$work/glob/ab.md"
printf 'x' > "$work/glob/bx.md"
# shellcheck disable=SC2016
printf '%s\n' '## Phase 3: User Story 1' '' '- [ ] T001 [US1] Edit `a?.md` and `b[xy].md`' > "$work/glob/tasks.md"
rc=0
out="$(cd "$work/glob" && bash "$script" tasks.md US1 2>"$work/stderr")" || rc=$?
[ ! -s "$work/stderr" ] || fail "stderr not empty"
expect_rc 0
expect_has "files: a?.md b[xy].md"
ok

new_case "unknown story"
run "$fx/009-tasks.md" US9
expect_error "no User Story 9"
ok

new_case "no [US<n>] tag"
run "$fx/notag-tasks.md"
expect_error "no [US<n>] tag"
ok

new_case "untagged task inside a story phase"
run "$fx/untagged-tasks.md"
expect_error "T002"
run "$fx/untagged-tasks.md" US1
expect_error "T002"
ok

new_case "tag with no story heading"
run "$fx/nostory-tasks.md"
expect_error "T002"
ok

new_case "unreadable file"
run "$work/missing.md"
expect_error "cannot read"
ok

new_case "bad arguments"
run
expect_usage
run --
expect_usage
run "$fx/009-tasks.md" 2
expect_usage
run "$fx/009-tasks.md" US
expect_usage
run "$fx/009-tasks.md" US1 extra
expect_usage
ok
