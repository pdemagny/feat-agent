#!/usr/bin/env bash
# Offline tests for docs/diagrams/sizes.py (mise run test:sizes).
#
# Fixtures: a sizes.json whose values differ from today's and stale copies of the four target
# files, under fixtures/; the generator's reviewed outputs under expected/. Every case runs the
# script with --root on a scratch copy of the fixtures laid out at the real paths.
set -euo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
repo="$(cd "$here/../.." && pwd -P)"
script="$repo/docs/diagrams/sizes.py"
fx="$here/fixtures"
ex="$here/expected"

json=".apm/skills/feat/sizes.json"
feat=".apm/skills/feat/SKILL.md"
fix=".apm/skills/fix/SKILL.md"
brief=".apm/skills/brief/SKILL.md"
wf="docs/workflow.md"

current="setup"
fail() {
  printf 'FAIL %s: %s\n' "$current" "$1"
  if [ -n "${err-}" ]; then printf '  stderr: %s\n' "$err"; fi
  exit 1
}

work="$(mktemp -d)"
trap 'command rm -rf -- "$work"' EXIT
n=0

# mk: a fresh root holding the stale fixtures at the real paths; sets $root.
mk() {
  n=$((n + 1))
  root="$work/root$n"
  mkdir -p "$root/.apm/skills/feat" "$root/.apm/skills/fix" "$root/.apm/skills/brief" "$root/docs"
  cp "$fx/sizes.json" "$root/$json"
  cp "$fx/feat-SKILL.md" "$root/$feat"
  cp "$fx/fix-SKILL.md" "$root/$fix"
  cp "$fx/brief-SKILL.md" "$root/$brief"
  cp "$fx/workflow.md" "$root/$wf"
}

new_case() {
  current="$1"
  err=
  out=
  mk
}

# run <args>: run the script on $root; sets $out, $err and $rc.
run() {
  rc=0
  out="$(python3 -I "$script" --root "$root" "$@" 2>"$work/stderr")" || rc=$?
  err="$(cat "$work/stderr")"
}

# snap: save the tree, so untouched() can prove nothing was written.
snap() {
  command rm -rf -- "$work/snap"
  cp -R "$root" "$work/snap"
}
untouched() { diff -r "$work/snap" "$root" >/dev/null || fail "$1: the tree changed"; }

# sub <path> <old> <new>: literal replace in a file of $root; the old text must be there.
sub() {
  local c
  c="$(cat "$root/$1")"
  [[ "$c" == *"$2"* ]] || fail "setup: no '$2' in $1"
  printf '%s\n' "${c/"$2"/$3}" >"$root/$1"
}

expect_rc() { [ "$rc" = "$1" ] || fail "exit $rc, want $1"; }
expect_err() { grep -qF -- "$1" <<<"$err" || fail "stderr lacks: $1"; }
expect_no_err() { [ -z "$err" ] || fail "stderr not empty"; }
expect_out_empty() { [ -z "$out" ] || fail "stdout not empty: $out"; }
same() { cmp -s "$1" "$2" || fail "$1 differs from $2"; }

# generated <root>-relative files equal expected
expect_fresh() {
  same "$root/$feat" "$ex/feat-SKILL.md"
  same "$root/$fix" "$ex/fix-SKILL.md"
  same "$root/$brief" "$ex/brief-SKILL.md"
  same "$root/$wf" "$ex/workflow.md"
}

# both <fragment...>: the error shows in write mode and in check mode, writing nothing.
both() {
  local frag mode
  snap
  for mode in "" --check; do
    run ${mode:+"$mode"}
    expect_rc 2
    expect_out_empty
    for frag in "$@"; do expect_err "$frag"; done
    untouched "${mode:-write}"
  done
}

new_case "fresh: generation equals expected"
run
expect_rc 0
expect_no_err
for p in "$feat" "$fix" "$brief" "$wf"; do grep -qxF "updated $p" <<<"$out" || fail "no 'updated $p'"; done
expect_fresh

new_case "idempotent: a second run writes nothing"
run
snap
run
expect_rc 0
expect_out_empty
expect_no_err
untouched "second run"

new_case "check passes on fresh output"
run
run --check
expect_rc 0
expect_out_empty
expect_no_err

new_case "check on stale copies: exit 1 naming each file"
snap
run --check
expect_rc 1
for p in "$feat" "$fix" "$brief" "$wf"; do expect_err "$p: differs from $json; run mise run diagrams"; done
untouched "check"

new_case "check on a hand-edited cell"
run
sub "$fix" "opus · low" "opus · max"
snap
run --check
expect_rc 1
expect_err "$fix: differs from"
[ "$(wc -l <<<"$err")" = 1 ] || fail "more than one file named"
untouched "check"
run
expect_rc 0
expect_fresh

new_case "check after a data change"
run
sub "$json" '"small": {"model": "opus", "effort": "low"}' '"small": {"model": "opus", "effort": "high"}'
run --check
expect_rc 1
expect_err "$fix: differs from"
expect_err "$wf: differs from"
! grep -qF "$feat" <<<"$err" || fail "$feat named"
! grep -qF "$brief" <<<"$err" || fail "$brief named"
run
run --check
expect_rc 0

new_case "d2 equals models.d2"
run --d2
expect_rc 0
expect_no_err
[ "$out" = "$(cat "$ex/models.d2")" ] || fail "d2 differs from expected/models.d2"
[ "$(grep -c 'c0_6: "opus\\nhigh"' "$ex/models.d2")" = 1 ] || fail "expected small code review cell is not opus / high"

new_case "agents table: one-value and two-value cells"
run
line="$(grep -F "\`feat-implementer\`" "$root/$wf")"
[[ "$line" == *"haiku · high"* && "$line" != *"("* ]] || fail "one value: $line"
line="$(grep -F "\`feat-bug-assessor\`" "$root/$wf")"
[[ "$line" == *"opus · low (assess)"* && "$line" == *"sonnet · high (test)"* ]] || fail "two values: $line"

# markers: errors are the same in write and check mode, name the file and the marker
new_case "marker missing"
sub "$wf" "<!-- sizes-start fix-matrix -->" ""
sub "$wf" "<!-- sizes-end fix-matrix -->" ""
both "sizes.py: $wf: marker fix-matrix: missing"

new_case "marker unpaired: start only"
sub "$wf" "<!-- sizes-end fix-matrix -->" ""
both "sizes.py: $wf: marker fix-matrix: unpaired"

new_case "marker unpaired: end only"
sub "$fix" "<!-- sizes-start fix-table -->" ""
both "sizes.py: $fix: marker fix-table: unpaired"

new_case "marker unpaired: end before start"
sub "$brief" "<!-- sizes-start brief-review -->stale<!-- sizes-end brief-review -->" "<!-- sizes-end brief-review -->stale<!-- sizes-start brief-review -->"
both "sizes.py: $brief: marker brief-review: unpaired"

new_case "marker duplicated"
sub "$feat" "After." "<!-- sizes-start feat-table -->After."
both "sizes.py: $feat: marker feat-table: duplicated"

new_case "marker unknown"
sub "$brief" "Next." "<!-- sizes-start bogus -->Next."
both "sizes.py: $brief: marker bogus: unknown"

new_case "marker for another file's region is unknown here"
sub "$feat" "After." "<!-- sizes-start fix-table --><!-- sizes-end fix-table -->After."
both "sizes.py: $feat: marker fix-table: unknown"

new_case "markers wrong in two files: both reported"
sub "$wf" "<!-- sizes-end feat-matrix -->" ""
sub "$fix" "<!-- sizes-end fix-table -->" ""
both "sizes.py: $wf: marker feat-matrix: unpaired" "sizes.py: $fix: marker fix-table: unpaired"

new_case "agents table: a line with no row"
sub "$wf" "| \`feat-shipper\` | 8 | stale | — |" "| \`feat-shipper\` | 8 | stale | — |
| \`feat-ghost\` | 9 | stale | — |"
both "sizes.py: $wf: agents table: feat-ghost has no row in sizes.json"

new_case "agents table: a row agent with no line"
sub "$wf" "| \`feat-shipper\` | 8 | stale | — |" ""
both "sizes.py: $wf: agents table: no line for feat-shipper"

new_case "schema: newline in a label"
sub "$json" '"label": "Specify"' '"label": "Spec\nify"'
both "$json: feat.rows[1].label"

new_case "schema: pipe in a label"
sub "$json" '"label": "Specify"' '"label": "Spec|ify"'
both "$json: feat.rows[1].label"

new_case "schema: comment marker in a label"
sub "$json" '"label": "Specify"' '"label": "<!-- sizes-end x -->"'
both "$json: feat.rows[1].label"

new_case "schema: space in an agent"
sub "$json" '"agent": "feat-specifier"' '"agent": "feat specifier"'
both "$json: feat.rows[1].agent"

new_case "schema: trailing newline in an agent"
sub "$json" '"agent": "feat-specifier"' '"agent": "x\n"'
both "$json: feat.rows[1].agent"

new_case "schema: trailing newline in a loads entry"
sub "$json" '"loads": ["speckit-specify"]' '"loads": ["x\n"]'
both "$json: feat.rows[1].loads[0]"

new_case "schema: a group list that is not a list"
sub "$json" '"4": {"small": [["4a", "4b"]]' '"4": {"small": 3'
both "$json: feat.groups.4.small"

new_case "schema: unknown top-level key"
sub "$json" '{
  "feat"' '{
  "extra": 1,
  "feat"'
both "$json: extra: unknown key"

new_case "schema: invalid JSON"
sub "$json" '"feat"' 'feat'
both "sizes.py: $json"

printf 'sizes: all cases pass\n'
