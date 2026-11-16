#!/usr/bin/env bash
# Offline tests for .apm/skills/feat/scripts/spec-number.sh (mise run
# test:spec-number).
#
# Each case gets a local "origin" repo, a clone of it ($repo) where the
# script runs, and a case dir read by the stub tests/spec-number/bin/gh,
# first on PATH. Nothing reaches GitHub.
set -euo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
root="$(cd "$here/../.." && pwd -P)"
script="$root/.apm/skills/feat/scripts/spec-number.sh"

current="setup"
fail() {
  printf 'FAIL %s: %s\n' "$current" "$1"
  if [ -n "${out+x}" ]; then printf '  output: %s\n' "$out"; fi
  if [ -n "${case_dir:-}" ] && [ -s "$case_dir/stderr" ]; then
    printf '  stderr: %s\n' "$(head -n 3 "$case_dir/stderr")"
  fi
  exit 1
}

work="$(mktemp -d)"
trap 'command rm -rf -- "$work"' EXIT

# Commits here must not depend on the user's git config (signing, hooks).
export GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1
export GIT_AUTHOR_NAME=test GIT_AUTHOR_EMAIL=test@example.com
export GIT_COMMITTER_NAME=test GIT_COMMITTER_EMAIL=test@example.com

# new_case <name>: a fresh origin ($origin) with one commit on main, its
# clone ($repo) and a case dir ($case_dir).
new_case() {
  current="$1"
  local d="$work/$1"
  mkdir -p "$d/origin" "$d/case"
  origin="$d/origin" repo="$d/repo" case_dir="$d/case"
  git -C "$origin" init -q -b main
  printf 'x\n' >"$origin/README"
  git -C "$origin" add README
  git -C "$origin" commit -q -m init
  git clone -q "$origin" "$repo"
  unset out subdir
}

# on_main <dir>...: commit specs/<dir>/spec.md on origin's main.
on_main() {
  local name
  for name in "$@"; do
    mkdir -p "$origin/specs/$name"
    printf 'spec\n' >"$origin/specs/$name/spec.md"
    git -C "$origin" add "specs/$name"
  done
  git -C "$origin" commit -q -m specs
}

# open_pr <number> <branch> [<file>...]: an open same-repo PR with these
# files; open_fork_pr: the same from a fork (isCrossRepository true).
open_pr() { pr_line false "$@"; }
open_fork_pr() { pr_line true "$@"; }
pr_line() {
  local fork="$1" n="$2" branch="$3"
  shift 3
  printf '%s %s %s\n' "$n" "$fork" "$branch" >>"$case_dir/prs"
  : >"$case_dir/files-$n"
  if [ "$#" -gt 0 ]; then printf '%s\n' "$@" >"$case_dir/files-$n"; fi
}

# run <args>: runs the script in $repo (or $repo/$subdir); sets $out and $rc.
run() {
  rc=0
  out="$(cd "$repo/${subdir:-}" && PATH="$here/bin:$PATH" SPECNUM_CASE="$case_dir" \
    bash "$script" "$@" 2>"$case_dir/stderr")" || rc=$?
}

expect_rc() { [ "$rc" = "$1" ] || fail "exit $rc, want $1"; }
expect_out() { [ "$out" = "$1" ] || fail "want output: $1"; }
expect_ok() {
  expect_rc 0
  expect_out "$1"
  [ ! -s "$case_dir/stderr" ] || fail "stderr not empty"
}
expect_error() {
  expect_rc "$1"
  expect_out ""
  grep -q "^spec-number: error: $2" "$case_dir/stderr" || fail "stderr lacks: $2"
}

ok() { printf 'ok %s\n' "$current"; }

# --- cases -------------------------------------------------------------------

new_case "no specs anywhere"
run next main
expect_ok 001
ok

new_case "highest on main plus one"
on_main 001-a 087-describe-protocol-window 012-b
run next main
expect_ok 088
ok

new_case "three digits roll over"
on_main 099-last
run next main
expect_ok 100
ok

# The issue's "done when": #363 kept branch typed-config-value, but its files
# hold specs/088-*; the next shipper must not take 088 again.
new_case "unnumbered PR branch, numbered spec in its files"
on_main 087-describe-protocol-window
open_pr 363 typed-config-value src/a.ts specs/088-typed-config-value/spec.md
run next main
expect_ok 089
ok

# #363 had 141 files and gh's files JSON stops at 100: the spec paths came
# after them. The stub serves 100 lines unless --paginate is passed.
new_case "PR with more than 100 files"
on_main 087-describe-protocol-window
files=()
for i in $(seq 120); do files+=("src/f$i.ts"); done
files+=(specs/088-typed-config-value/spec.md specs/088-typed-config-value/plan.md)
open_pr 363 typed-config-value "${files[@]}"
run next main
expect_ok 089
ok

new_case "numbered PR branch without spec files"
on_main 087-a
open_pr 5 090-older-run docs/x.md
run next main
expect_ok 091
ok

# GitHub issue branches (`370-foo`) carry an issue number: a PR's branch
# name counts only when its files hold no spec dir.
new_case "numbered PR branch with spec files: branch ignored"
on_main 087-a
open_pr 9 370-fix-thing specs/088-fix-thing/spec.md
run next main
expect_ok 089
ok

new_case "run from a subdirectory"
on_main 005-a
mkdir -p "$repo/docs/deep"
subdir=docs/deep
run next main
expect_ok 006
ok

# Anyone can open a PR from a fork: its branch and files never count.
new_case "fork PR ignored"
on_main 087-a
open_fork_pr 10 500-evil specs/600-evil/spec.md
open_fork_pr 11 700-evil-branch
run next main
expect_ok 088
! grep -q "pulls/1[01]/files" "$case_dir/calls" || fail "fork PR files fetched"
ok

# 19-20 digits overflow bash arithmetic; only 3-4 digits are spec numbers.
new_case "long-digit names ignored"
on_main 087-a 12345-five-digits
open_pr 12 99999999999999999999-big
open_pr 13 b specs/9223372036854775808-huge/spec.md
run next main
expect_ok 088
ok

new_case "four digits count"
on_main 087-a 1000-a
run next main
expect_ok 1001
ok

new_case "files outside specs/ dirs are ignored"
on_main 003-a
open_pr 7 b specs/README.md src/specs/900-x/y.md
run next main
expect_ok 004
ok

# Step 1 used to read origin/<default> before anything fetched it.
new_case "main moved after the clone"
on_main 010-a
on_main 011-b
run next main
expect_ok 012
ok

new_case "check: own number free"
on_main 087-a
open_pr 1 other specs/086-other/spec.md
run check main 088-mine
expect_ok "keep 088"
ok

new_case "check: own dir is not a clash with itself"
on_main 087-a
open_pr 1 mine specs/088-mine/spec.md
run check main 088-mine
expect_ok "keep 088"
ok

new_case "check: taken by an open PR meanwhile"
on_main 087-a
open_pr 364 split-entry-lock specs/088-split-entry-lock/spec.md
run check main 088-typed-config-value
expect_ok "renumber 089"
ok

new_case "check: taken on main meanwhile, PR holds a higher one"
on_main 087-a
open_pr 2 b specs/089-b/spec.md
on_main 088-merged
run check main 088-mine
expect_ok "renumber 090"
ok

new_case "gh pr list fails"
touch "$case_dir/fail-pr"
run next main
expect_error 1 "gh pr list failed"
ok

new_case "gh api fails"
open_pr 3 b specs/001-b/spec.md
touch "$case_dir/fail-api"
run next main
expect_error 1 "gh api files of PR #3 failed"
ok

new_case "fetch fails"
git -C "$repo" remote set-url origin "$work/nowhere"
run next main
expect_rc 1
expect_out ""
grep -q "^spec-number: error: git fetch origin main failed" "$case_dir/stderr" \
  || fail "stderr lacks the fetch error"
ok

new_case "usage errors"
run
expect_error 2 "usage"
run next
expect_error 2 "usage"
run next -main
expect_error 2 "bad branch name"
run check main mine
expect_error 2 "not a numbered spec dir name"
[ ! -e "$case_dir/calls" ] || fail "gh was called"
ok

echo "all spec-number tests passed"
