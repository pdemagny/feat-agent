#!/usr/bin/env bash
# Offline tests for docs/diagrams/sizes.py (mise run test:sizes).
#
# Fixtures: a sizes.json whose values differ from today's and stale copies of the two marked
# target files (sizes.tsv starts absent), under fixtures/; the generator's reviewed outputs under
# expected/. Every case runs the script with --root on a scratch copy of the fixtures laid out at
# the real paths.
set -euo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
repo="$(cd "$here/../.." && pwd -P)"
script="$repo/docs/diagrams/sizes.py"
fx="$here/fixtures"
ex="$here/expected"

json=".apm/skills/feat/sizes.json"
brief=".apm/skills/brief/SKILL.md"
wf="docs/workflow.md"
tsv=".apm/skills/feat/sizes.tsv"

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
  mkdir -p "$root/.apm/skills/feat" "$root/.apm/skills/brief" "$root/docs"
  cp "$fx/sizes.json" "$root/$json"
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
  same "$root/$brief" "$ex/brief-SKILL.md"
  same "$root/$wf" "$ex/workflow.md"
  same "$root/$tsv" "$ex/sizes.tsv"
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
for p in "$brief" "$wf" "$tsv"; do grep -qxF "updated $p" <<<"$out" || fail "no 'updated $p'"; done
[ "$(wc -l <<<"$out")" = 3 ] || fail "more than the three targets updated: $out"
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
for p in "$brief" "$wf"; do expect_err "$p: differs from $json; run mise run diagrams"; done
expect_err "sizes.tsv is stale: run mise run diagrams"
untouched "check"

new_case "check on a hand-edited cell"
run
sub "$wf" "opus · low" "opus · max"
snap
run --check
expect_rc 1
expect_err "$wf: differs from"
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
expect_err "$wf: differs from"
expect_err "sizes.tsv is stale: run mise run diagrams"
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
sub "$wf" "<!-- sizes-start fix-matrix -->" ""
both "sizes.py: $wf: marker fix-matrix: unpaired"

new_case "marker unpaired: end before start"
sub "$brief" "<!-- sizes-start brief-review -->stale<!-- sizes-end brief-review -->" "<!-- sizes-end brief-review -->stale<!-- sizes-start brief-review -->"
both "sizes.py: $brief: marker brief-review: unpaired"

new_case "marker duplicated"
sub "$wf" "Between." "<!-- sizes-start feat-matrix -->Between."
both "sizes.py: $wf: marker feat-matrix: duplicated"

new_case "marker unknown"
sub "$brief" "Next." "<!-- sizes-start bogus -->Next."
both "sizes.py: $brief: marker bogus: unknown"

new_case "marker for another file's region is unknown here"
sub "$brief" "Next." "<!-- sizes-start feat-matrix --><!-- sizes-end feat-matrix -->Next."
both "sizes.py: $brief: marker feat-matrix: unknown"

new_case "the skills' old size table markers are unknown"
sub "$wf" "Tail." "<!-- sizes-start feat-table --><!-- sizes-end feat-table -->Tail."
both "sizes.py: $wf: marker feat-table: unknown"

new_case "markers wrong in two files: both reported"
sub "$wf" "<!-- sizes-end feat-matrix -->" ""
sub "$brief" "<!-- sizes-end brief-review -->" ""
both "sizes.py: $wf: marker feat-matrix: unpaired" "sizes.py: $brief: marker brief-review: unpaired"

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

# sizes.tsv: the whole-file target step.sh reads
new_case "sizes.tsv: a stale copy fails check with its line"
run
sub "$tsv" "row	fix	4b	feat-code-reviewer	7b	large	sonnet	max" "row	fix	4b	feat-code-reviewer	7b	large	opus	max"
snap
run --check
expect_rc 1
expect_err "sizes.tsv is stale: run mise run diagrams"
[ "$(wc -l <<<"$err")" = 1 ] || fail "more than one file named"
untouched "check"

new_case "sizes.tsv: a hand edit is overwritten"
run
sub "$tsv" "group	fix	4	large	default	4b	7b	sonnet	max" "group	fix	4	large	default	4b	7b	haiku	low"
run
expect_rc 0
grep -qxF "updated $tsv" <<<"$out" || fail "no 'updated $tsv'"
expect_fresh

new_case "sizes.tsv: a data change makes it stale"
run
sub "$json" '"large": {"model": "sonnet", "effort": "max"}' '"large": {"model": "opus", "effort": "max"}'
run --check
expect_rc 1
expect_err "sizes.tsv is stale: run mise run diagrams"

new_case "sizes.tsv: groups on the strongest model and effort, performance variant only where listed"
run
grep -qxF "group	fix	4	small	default	4a+4b+4c	7a+7b+7c	opus	high" "$root/$tsv" || fail "small fix group"
! grep -qF "group	fix	4	small	performance" "$root/$tsv" || fail "performance small written"
grep -qxF "row	feat	2	feat-specifier	-	small	sonnet	low" "$root/$tsv" || fail "feat row lens not -"
grep -qxF "row	feat	7a	feat-code-reviewer	7a	small	sonnet	high" "$root/$tsv" || fail "feat reviewer row lens"
! grep -qE '		|	$' "$root/$tsv" || fail "an empty column or a trailing tab"

new_case "schema: a fix group naming a row of another phase"
sub "$json" '"medium": [["4a", "4b"]], "large": [["4a"], ["4b"]],' '"medium": [["4a", "3"]], "large": [["4a"], ["4b"]],'
both "$json: fix.groups.4.medium: must list rows of 4a, 4b, 4c, each at most once"

new_case "schema: a fix group listing an id twice in one size"
sub "$json" '"medium": [["4a", "4b"]], "large": [["4a"], ["4b"]],' '"medium": [["4a"], ["4a", "4b"]], "large": [["4a"], ["4b"]],'
both "$json: fix.groups.4.medium: must list rows of 4a, 4b, 4c, each at most once"

new_case "schema: a fix group missing a size"
sub "$json" '"medium": [["4a", "4b"]], "large": [["4a"], ["4b"]],' '"medium": [["4a", "4b"]],'
both "$json: fix.groups.4.large: missing"

new_case "schema: a bad lens"
sub "$json" '"lens": "7c"' '"lens": "4c"'
both "$json: fix.rows[5].lens: must be one of 7a, 7b, 7c, 7d, 7e"

new_case "schema: a fix reviewer row without a lens"
sub "$json" '"lens": "7c", ' ''
both "$json: fix.rows[5].lens: missing"

new_case "schema: a lens on a feat row"
sub "$json" '"agent": "feat-code-reviewer", "loads": []' '"agent": "feat-code-reviewer", "lens": "7a", "loads": []'
both "$json: feat.rows[7].lens: unknown key"

new_case "schema: a performance object missing a size is allowed"
grep -qF '"performance": {"medium"' "$root/$json" || fail "setup: fixture performance lists small"
run
expect_rc 0
expect_no_err
expect_fresh

new_case "schema: a feat group missing a row is still refused"
sub "$json" '"medium": [["4a"], ["4b"]], "large": [["4a", "4b"]]' '"medium": [["4a"]], "large": [["4a", "4b"]]'
both "$json: feat.groups.4.medium: must list each of 4a, 4b exactly once"

printf 'sizes: all cases pass\n'
