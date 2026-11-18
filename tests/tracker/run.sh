#!/usr/bin/env bash
# Offline tests for .apm/skills/feat/scripts/tracker.sh (mise run test:tracker).
#
# Each case gets a temp git repo (with or without .logistics.yml) and a case
# dir. The stub tests/tracker/bin/gh, first on PATH, answers `gh repo` and
# `gh issue` from case files and hands `gh api` to the real gh, whose config
# (GH_CONFIG_DIR) sends every request to fake_github.py on a unix socket: the
# real -f/-F handling and --jq filters run, and nothing reaches GitHub.
set -euo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
root="$(cd "$here/../.." && pwd -P)"
script="$root/.apm/skills/feat/scripts/tracker.sh"
fixtures="$here/fixtures"

current="setup"
fail() {
  printf 'FAIL %s: %s\n' "$current" "$1"
  if [ -n "${out+x}" ]; then printf '  output: %s\n' "$out"; fi
  exit 1
}

real_gh="$(command -v gh)" || fail "install gh (mise install)"
command -v python3 >/dev/null || fail "python3 not found"

work="$(mktemp -d)"
endpoint_pid=""
finish() {
  if [ -n "$endpoint_pid" ]; then kill "$endpoint_pid" 2>/dev/null || true; fi
  command rm -rf -- "$work"
}
trap finish EXIT

CONFIG='tracker:
  provider: github
  project: https://github.com/users/alice/projects/2
  statuses:
    brief: Brief
    building: In progress
    review: In review
'

# new_case <name>: a fresh repo ($repo) and case dir ($case_dir).
new_case() {
  current="$1"
  local d="$work/$1"
  mkdir -p "$d/repo" "$d/case" "$d/ghcfg"
  git -C "$d/repo" init -q
  repo="$d/repo" case_dir="$d/case" ghcfg="$d/ghcfg"
  printf 'http_unix_socket: %s\n' "$case_dir/s" >"$ghcfg/config.yml"
  unset out
}

write_config() { printf '%s' "$1" >"$repo/.logistics.yml"; }

# fixture <file> <Op>: the endpoint's answer to operation <Op>.
fixture() { command cp -f "$fixtures/$1" "$case_dir/$2.json"; }

# tracker <args>: runs the script in $repo with the endpoint up; sets $out, $rc.
tracker() {
  python3 -I "$here/fake_github.py" "$case_dir/s" "$case_dir" &
  endpoint_pid=$!
  local i
  for i in $(seq 100); do
    [ -S "$case_dir/s" ] && break
    [ "$i" -lt 100 ] || fail "fake endpoint did not start"
    sleep 0.05
  done
  rc=0
  out="$(cd "$repo" && env -u GH_HOST -u GH_REPO -u GITHUB_TOKEN -u GH_ENTERPRISE_TOKEN \
    PATH="$here/bin:$PATH" TRACKER_REAL_GH="$real_gh" TRACKER_CASE="$case_dir" \
    GH_CONFIG_DIR="$ghcfg" GH_TOKEN=test GH_NO_UPDATE_NOTIFIER=1 GH_PROMPT_DISABLED=1 \
    TRACKER_RETRY_DELAY=0 bash "$script" "$@" 2>"$case_dir/stderr")" || rc=$?
  kill "$endpoint_pid" 2>/dev/null || true
  wait "$endpoint_pid" 2>/dev/null || true
  endpoint_pid=""
  command rm -f -- "$case_dir/s"
  [ ! -s "$case_dir/stderr" ] || fail "stderr not empty: $(head -n 3 "$case_dir/stderr")"
}

expect_rc() { [ "$rc" = "$1" ] || fail "exit $rc, want $1"; }
expect_out() { [ "$out" = "$1" ] || fail "want output: $1"; }
expect_no_calls() { [ ! -e "$case_dir/calls" ] || fail "gh was called: $(head -n 1 "$case_dir/calls")"; }

# ops: the operation names the endpoint received, space-separated.
ops() {
  [ -e "$case_dir/requests" ] || return 0
  sed -n 's/^{"op": "\([A-Za-z]*\)".*/\1/p' "$case_dir/requests" | paste -sd ' ' -
}
expect_ops() { [ "$(ops)" = "$1" ] || fail "requests: '$(ops)', want '$1'"; }

ok() { printf 'ok %s\n' "$current"; }

# --- cases -------------------------------------------------------------------

# 1. No config: off, and gh is never called.
new_case "no config"
tracker check
expect_rc 0
expect_out "tracker: off (no .logistics.yml)"
tracker set-status building '#1'
expect_rc 0
expect_out "tracker: off (no .logistics.yml)"
expect_no_calls
ok

# 1b. Old config name: check fails and says to rename it.
new_case "old config name"
printf 'x' >"$repo/.feat-agent.yml"
tracker check
expect_rc 1
expect_out "tracker: error: .feat-agent.yml is now .logistics.yml; rename it"
expect_no_calls
ok

# bad_config <config> <want output>: check fails on it before any gh call.
bad_config() {
  write_config "$1"
  tracker check
  expect_rc 1
  expect_out "$2"
  expect_no_calls
}
err_line='tracker: error: .logistics.yml line'

# 2. Malformed line: each error names the line or the key; gh never runs.
new_case "malformed line"
bad_config "${CONFIG/  provider/   provider}" "$err_line 2: bad indentation (0, 2 or 4 spaces)"
bad_config "${CONFIG/    review: /$'\t'review: }" "$err_line 7: tab in a key line"
bad_config "$CONFIG  owner: alice"$'\n' "$err_line 8: unknown key"
bad_config "$CONFIG    review: Done"$'\n' "$err_line 8: duplicate tracker.statuses.review"
bad_config "${CONFIG/    review: In review$'\n'/}" \
  "tracker: error: .logistics.yml: missing tracker.statuses.review"
bad_config "${CONFIG/provider: github/provider: linear}" "$err_line 2: provider must be github"
ok

# 3. Bad project URL: only https://github.com/users|orgs/<login>/projects/<n>.
new_case "bad project URL"
want="$err_line 3: project must be https://github.com/users|orgs/<login>/projects/<number>"
good='https://github.com/users/alice/projects/2'
for url in 'https://github.com/alice/app' 'http://github.com/users/alice/projects/2' \
  'https://gitlab.com/users/alice/projects/2' 'https://github.com/users/alice/projects/2/views/1' \
  'https://github.com/users/alice/projects/2/'; do
  bad_config "${CONFIG/"$good"/"$url"}" "$want"
done
ok

# 4. Unknown status: named, and at most 10 board options listed.
new_case "unknown status"
write_config "${CONFIG/review: In review/review: In Review}"
fixture board-12.json TrackerBoard
tracker check
expect_rc 1
expect_out 'tracker: error: unknown status "In Review" (statuses.review); board options: "Backlog", "Todo", "Brief", "Ready", "In progress", "Blocked", "In review", "QA", "Staging", "Released", ...'
expect_ops "TrackerBoard"
ok

# 5. Repeat: the item is already at the target, so no mutation.
new_case "repeat"
write_config "$CONFIG"
printf 'alice/app\n' >"$case_dir/repo"
printf 'repo, project\n' >"$case_dir/scopes"
fixture board.json TrackerBoard
tracker check
expect_rc 0
expect_out "tracker: ok users/alice/projects/2 (Brief, In progress, In review)"
command rm -f -- "$case_dir/requests"
fixture item-at-brief.json TrackerItem
tracker set-status brief '#11'
expect_rc 0
expect_out 'tracker: #11 already "Brief"'
expect_ops "TrackerItem"
for frag in '"owner": "alice"' '"repo": "app"' '"issue": 11' '"login": "alice"' '"number": 2'; do
  grep -qF "$frag" "$case_dir/requests" || fail "TrackerItem variables lack $frag"
done
ok

# 6. Item missing: added to the board, then set.
new_case "item missing"
write_config "$CONFIG"
printf 'alice/app\n' >"$case_dir/repo"
fixture item-missing.json TrackerItem
fixture add.json TrackerAdd
fixture set.json TrackerSet
tracker set-status brief '#11'
expect_rc 0
expect_out 'tracker: #11 set to "Brief" (added to board)'
expect_ops "TrackerItem TrackerAdd TrackerSet"
grep '"op": "TrackerSet"' "$case_dir/requests" | grep -q '"option": "opt_brief"' ||
  fail "TrackerSet's option is not the Brief option ID"
grep '"op": "TrackerSet"' "$case_dir/requests" | grep -q '"item": "PVTI_new1"' ||
  fail "TrackerSet's item is not the added item"
ok

# 7. Hostile value: nothing from the config is evaluated or sent to gh, and
# echoed values are cleaned.
new_case "hostile value"
write_config "${CONFIG/brief: Brief/brief: \$(touch pwned)}"
fixture board.json TrackerBoard
tracker check
expect_rc 1
expect_out "tracker: error: unknown status \"\$(touch pwned)\" (statuses.brief); board options: \"Brief\", \"In progress\", \"In review\", \"Done\""
[ -z "$(find "$work" "${TMPDIR:-/tmp}" -maxdepth 4 -name pwned 2>/dev/null)" ] || fail "pwned was created"
! grep -q pwned "$case_dir/requests" || fail "pwned reached gh"
write_config "${CONFIG/building: In progress/building: In$'\e'[31mprogress}"
tracker check
expect_rc 1
expect_out 'tracker: error: unknown status "In?[31mprogress" (statuses.building); board options: "Brief", "In progress", "In review", "Done"'
write_config "${CONFIG/building: In progress/building: In$'\xe2\x80\xae'pro$'\xe2\x81\xa6'g$'\xe2\x80\x8b'ress}"
tracker check
expect_rc 1
expect_out 'tracker: error: unknown status "In?pro?g?ress" (statuses.building); board options: "Brief", "In progress", "In review", "Done"'
ok

# 8. Retry then success: the first read fails once (502), the retry goes on.
new_case "retry then success"
write_config "$CONFIG"
printf 'alice/app\n' >"$case_dir/repo"
fixture item-other.json TrackerItem
fixture set.json TrackerSet
: >"$case_dir/TrackerItem.fail"
tracker set-status review '#11'
expect_rc 0
expect_out 'tracker: #11 set to "In review"'
expect_ops "TrackerItem TrackerItem TrackerSet"
[ ! -e "$case_dir/TrackerItem.fail" ] || fail "the fault was not hit"
ok

# 9. Upstream repo: the issue goes where gh resolves the repo (a fork's
# upstream) only when that is the repo the user confirmed, and the body keeps
# a fenced "## " line inside Behaviour.
new_case "upstream repo"
write_config "$CONFIG"
printf 'up/r\n' >"$case_dir/repo"
printf 'https://github.com/up/r/issues/7\n' >"$case_dir/issue-url"
mkdir -p "$repo/specs/briefs"
printf '%s\n' '# Brief: Add a widget' '- Size: small' '' \
  '## Why' 'Users need widgets.' '' \
  '## Today' 'No widgets.' '' \
  '## Behaviour' '- A widget shows.' '```markdown' '## not a heading' '```' '- It stays.' '' \
  '## Out of scope' '- Gadgets.' >"$repo/specs/briefs/add-widget.md"
tracker create-issue specs/briefs/add-widget.md alice/app
expect_rc 1
expect_out "tracker: error: could not create the issue (current repo is up/r, not alice/app named at the gate)"
! grep -q '^issue create' "$case_dir/calls" || fail "an issue was created in an unconfirmed repo"
tracker create-issue specs/briefs/add-widget.md up/r
expect_rc 0
expect_out "tracker: created up/r#7"
grep -q '^issue create -R up/r --title Add a widget --body-file ' "$case_dir/calls" ||
  fail "issue create call: $(grep '^issue create' "$case_dir/calls" || true)"
! grep -q -- '--label' "$case_dir/calls" || fail "issue create got a label"
for frag in '## Why' 'Users need widgets.' '## Behaviour' '- A widget shows.' '## not a heading' \
  '- It stays.' 'Brief: specs/briefs/add-widget.md'; do
  grep -qxF -- "$frag" "$case_dir/body" || fail "body lacks: $frag"
done
[ "$(tail -n 1 "$case_dir/body")" = 'Brief: specs/briefs/add-widget.md' ] || fail "body's last line is not the Brief: line"
for frag in 'No widgets.' 'Gadgets.' '# Brief: Add a widget'; do
  ! grep -qF -- "$frag" "$case_dir/body" || fail "body holds: $frag"
done
ok

# 10. Symlinked path: specs/briefs points outside the repo, so the brief is
# refused before any gh call.
new_case "symlinked path"
write_config "$CONFIG"
mkdir -p "$repo/specs" "$work/outside"
printf '%s\n' '# Brief: X' '## Why' 'w' '## Behaviour' 'b' >"$work/outside/x.md"
ln -s "$work/outside" "$repo/specs/briefs"
tracker create-issue specs/briefs/x.md up/r
expect_rc 2
expect_out "tracker: error: specs/briefs resolves outside the repo"
expect_no_calls
ok

# 11. Read issue: #N resolves to the current repo and gh's JSON is printed
# as is.
new_case "read issue"
write_config "$CONFIG"
printf 'o/r\n' >"$case_dir/repo"
fixture issue.json issue
tracker read-issue '#5'
expect_rc 0
expect_out "$(cat "$fixtures/issue.json")"
grep -qx 'issue view 5 -R o/r --json number,title,body,labels,url' "$case_dir/calls" ||
  fail "issue view call: $(grep '^issue view' "$case_dir/calls" || true)"
ok

# 12. Missing project scope: check refuses a token without it (read:project
# is not enough) and names the fix.
new_case "missing project scope"
write_config "$CONFIG"
printf 'repo, read:project\n' >"$case_dir/scopes"
fixture board.json TrackerBoard
tracker check
expect_rc 1
expect_out "tracker: error: token lacks the project scope; run gh auth refresh -s project"
expect_ops "TrackerBoard"
ok

# write_assessment <slug> <lines...>: .specify/bugs/<slug>/assessment.md.
write_assessment() {
  local slug="$1"
  shift
  mkdir -p "$repo/.specify/bugs/$slug"
  printf '%s\n' "$@" >"$repo/.specify/bugs/$slug/assessment.md"
}

# 13. Bug issue: an assessment gives a `bug`-labelled issue whose body holds
# the Symptom (a fenced "## " line included) and the Root Cause Hypothesis,
# and nothing else; an unconfirmed repo still creates nothing.
new_case "bug issue"
write_config "$CONFIG"
printf 'up/r\n' >"$case_dir/repo"
printf 'https://github.com/up/r/issues/8\n' >"$case_dir/issue-url"
write_assessment login-timeout '# Bug Assessment: Login times out' '' \
  '## Report (verbatim or summarized)' 'It hangs at login.' '' \
  '## Symptom' 'Login spins for 30s.' '```text' '## not a heading' '```' '' \
  '## Reproduction' '1. Open /login.' '' \
  '## Suspected Code Paths' '- auth/session.py' '' \
  '## Root Cause Hypothesis' 'The session lock is never released (confidence: medium).' '' \
  '## Proposed Remediation' 'Release the lock.'
tracker create-issue .specify/bugs/login-timeout/assessment.md up/r
expect_rc 0
expect_out "tracker: created up/r#8"
grep -q '^issue create -R up/r --title Login times out --body-file .* --label bug$' "$case_dir/calls" ||
  fail "issue create call: $(grep '^issue create' "$case_dir/calls" || true)"
for frag in '## Symptom' 'Login spins for 30s.' '## not a heading' '## Root cause' \
  'The session lock is never released (confidence: medium).' 'Trail: .specify/bugs/login-timeout/'; do
  grep -qxF -- "$frag" "$case_dir/body" || fail "body lacks: $frag"
done
[ "$(tail -n 1 "$case_dir/body")" = 'Trail: .specify/bugs/login-timeout/' ] || fail "body's last line is not the Trail: line"
for frag in 'It hangs at login.' 'Open /login.' 'auth/session.py' 'Release the lock.' '# Bug Assessment'; do
  ! grep -qF -- "$frag" "$case_dir/body" || fail "body holds: $frag"
done
command rm -f -- "$case_dir/calls"
tracker create-issue .specify/bugs/login-timeout/assessment.md other/r
expect_rc 1
expect_out "tracker: error: could not create the issue (current repo is up/r, not other/r named at the gate)"
! grep -q '^issue create' "$case_dir/calls" || fail "an issue was created in an unconfirmed repo"
ok

# 14. Bad assessment path: a .specify/bugs symlinked outside the repo, or a
# path that is not <slug>/assessment.md, is refused before any gh call.
new_case "bad assessment path"
write_config "$CONFIG"
mkdir -p "$repo/.specify" "$work/outside-bugs/x"
printf '%s\n' '# Bug Assessment: X' '## Symptom' 's' '## Root Cause Hypothesis' 'h' \
  >"$work/outside-bugs/x/assessment.md"
ln -s "$work/outside-bugs" "$repo/.specify/bugs"
tracker create-issue .specify/bugs/x/assessment.md up/r
expect_rc 2
expect_out "tracker: error: .specify/bugs/x resolves outside the repo"
expect_no_calls
tracker create-issue .specify/bugs/x/fix.md up/r
expect_rc 2
expect_out "tracker: error: brief path must be specs/briefs/<name>.md or .specify/bugs/<slug>/assessment.md"
expect_no_calls
ok

# 15. Missing section: an assessment without a Root Cause Hypothesis is
# refused, naming the section, before any gh call.
new_case "missing section"
write_config "$CONFIG"
write_assessment login-timeout '# Bug Assessment: Login times out' '' \
  '## Symptom' 'Login spins for 30s.' '' \
  '## Proposed Remediation' 'Release the lock.'
tracker create-issue .specify/bugs/login-timeout/assessment.md up/r
expect_rc 2
expect_out "tracker: error: assessment has no Root Cause Hypothesis section"
expect_no_calls
ok

# 16. Missing bug label: gh refuses --label before creating anything, so the
# script retries once without it and says so; any other failure is not retried.
new_case "missing bug label"
write_config "$CONFIG"
printf 'up/r\n' >"$case_dir/repo"
printf 'https://github.com/up/r/issues/9\n' >"$case_dir/issue-url"
: >"$case_dir/no-label"
write_assessment login-timeout '# Bug Assessment: Login times out' '' \
  '## Symptom' 'Login spins for 30s.' '' \
  '## Root Cause Hypothesis' 'The session lock is never released.'
tracker create-issue .specify/bugs/login-timeout/assessment.md up/r
expect_rc 0
expect_out "tracker: created up/r#9 (without the bug label: up/r has none)"
[ "$(grep -c '^issue create' "$case_dir/calls")" = 2 ] || fail "want two issue create calls"
grep '^issue create' "$case_dir/calls" | tail -n 1 | grep -qv -- '--label' || fail "the retry kept --label"
command rm -f -- "$case_dir/calls" "$case_dir/issue-url"
tracker create-issue .specify/bugs/login-timeout/assessment.md up/r
expect_rc 1
[ "$(grep -c '^issue create' "$case_dir/calls")" = 2 ] || fail "want the label retry only"
command rm -f -- "$case_dir/calls" "$case_dir/no-label"
tracker create-issue .specify/bugs/login-timeout/assessment.md up/r
expect_rc 1
[ "$(grep -c '^issue create' "$case_dir/calls")" = 1 ] || fail "a failure other than the label was retried"
ok

# 17. Secret in the body: an assessment whose Symptom or Root Cause holds a
# secret-looking value (secret-scan.sh's rules) is refused before any gh
# call; a key with no literal value is not a secret. The samples are built
# by concatenation, so this file passes the secret scan itself.
new_case "secret in body"
write_config "$CONFIG"
want="tracker: error: assessment's Symptom or Root Cause Hypothesis holds a secret-looking value; redact it first"
for value in "pass""word=\"hunter2024\"" "\"tok""en\": 'abcd1234efgh'" \
  "API_""KEY=0123456789abcdefghij0123" 'key gh''s_abc' 's''k-proj123' '-----BEG''IN RSA PRIVATE KEY-----'; do
  write_assessment login-timeout '# Bug Assessment: Login times out' '' \
    '## Symptom' 'Login spins.' "$value" '' \
    '## Root Cause Hypothesis' 'The lock is held.'
  tracker create-issue .specify/bugs/login-timeout/assessment.md up/r
  expect_rc 2
  expect_out "$want"
  expect_no_calls
done
printf 'up/r\n' >"$case_dir/repo"
printf 'https://github.com/up/r/issues/9\n' >"$case_dir/issue-url"
for value in 'pass''word=hunter2' '"tok''en": "abc"' "tok""en: \${{ secrets.GH_TOKEN }}" \
  'sec''ret := cfg.GetString("sec''ret")'; do
  write_assessment login-timeout '# Bug Assessment: Login times out' '' \
    '## Symptom' 'Login spins.' "$value" '' \
    '## Root Cause Hypothesis' 'The lock is held.'
  tracker create-issue .specify/bugs/login-timeout/assessment.md up/r
  expect_rc 0
  expect_out "tracker: created up/r#9"
done
ok
