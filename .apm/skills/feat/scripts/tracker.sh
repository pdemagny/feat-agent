#!/usr/bin/env bash
# Board tracking for /brief, /feat and /fix: moves the feature's issue across the
# GitHub Projects board named in <repo root>/.logistics.yml.
#
#   tracker.sh check
#   tracker.sh read-issue <ref>
#   tracker.sh create-issue <brief-file | assessment-file> <owner/repo confirmed by the user>
#   tracker.sh set-status <brief|building|review> <ref>
#
# One line on stdout ("tracker: ..." or read-issue's JSON), nothing on
# stderr. Exit 0 ok/off/no change, 1 failure, 2 usage error. Only gh is
# called; the config is untrusted: nothing from it is evaluated, and values
# reach gh only as -f/-F variables of the fixed documents below.
set -euo pipefail

user_lc_all="${LC_ALL-}"
export LC_ALL=C
# user_locale: back to the caller's LC_ALL (call it in a subshell).
user_locale() { if [ -n "$user_lc_all" ]; then LC_ALL="$user_lc_all"; else unset LC_ALL; fi; }

RE_URL='^https://github\.com/(users|orgs)/([A-Za-z0-9][A-Za-z0-9-]{0,38})/projects/([1-9][0-9]{0,9})$'
RE_REF_SHORT='^#([1-9][0-9]{0,9})$'
RE_REF_FULL='^([A-Za-z0-9][A-Za-z0-9-]{0,38})/([A-Za-z0-9._-]{1,100})#([1-9][0-9]{0,9})$'
RE_REPO='^([A-Za-z0-9][A-Za-z0-9-]{0,38})/([A-Za-z0-9._-]{1,100})$'
RE_ID='^[A-Za-z0-9_=-]{1,200}$'
RE_KEY='^( *)([a-z]+):(.*)$'
RE_SKIP_LINE='^ *(#.*)?$'
RE_ISSUE_URL='^https://github\.com/([A-Za-z0-9][A-Za-z0-9-]{0,38}/[A-Za-z0-9._-]{1,100})/issues/([1-9][0-9]{0,9})$'
RE_AFTER_QUOTE='^ *(#.*)?$'
RE_SCOPE_PROJECT='(^|,) *project *(,|$)'
# Secret-looking values (FR-038's patterns): an assessment-derived issue body
# that matches one is refused.
RE_SECRET='-----BEGIN|gh[opsur]_|github_pat_|AKIA|xox[bp]-|(^|[^A-Za-z0-9_])sk-|(password|token|secret)["'"'"']?[[:space:]]*[:=]'

# GraphQL documents and --jq filters, verbatim from the contract
# (specs/001-board-tracking/contracts/tracker-cli.md). Never spliced into: each
# is a quoted heredoc, so nothing in it expands.
IFS= read -r -d '' Q_BOARD <<'EOF' || true
query TrackerBoard($login: String!, $number: Int!) {
  repositoryOwner(login: $login) {
    ... on ProjectV2Owner {
      projectV2(number: $number) {
        id
        viewerCanUpdate
        field(name: "Status") {
          ... on ProjectV2SingleSelectField { id options { id name } }
        }
      }
    }
  }
}
EOF
IFS= read -r -d '' J_BOARD <<'EOF' || true
.data.repositoryOwner.projectV2 // empty
| (["B", .id, (.viewerCanUpdate | tostring), (.field.id // "")] | @tsv),
  (.field.options // [] | .[] | ["O", .id, .name] | @tsv)
EOF

IFS= read -r -d '' Q_ITEM <<'EOF' || true
query TrackerItem($login: String!, $number: Int!, $owner: String!, $repo: String!, $issue: Int!) {
  repositoryOwner(login: $login) {
    ... on ProjectV2Owner {
      projectV2(number: $number) {
        id
        viewerCanUpdate
        field(name: "Status") {
          ... on ProjectV2SingleSelectField { id options { id name } }
        }
      }
    }
  }
  repository(owner: $owner, name: $repo) {
    issue(number: $issue) {
      id
      projectItems(first: 100) {
        nodes {
          id
          project { id }
          fieldValueByName(name: "Status") {
            ... on ProjectV2ItemFieldSingleSelectValue { optionId }
          }
        }
      }
    }
  }
}
EOF
IFS= read -r -d '' J_ITEM <<'EOF' || true
.data as $d
| ($d.repositoryOwner.projectV2 // empty) as $p
| ($p | (["B", .id, (.viewerCanUpdate | tostring), (.field.id // "")] | @tsv),
        (.field.options // [] | .[] | ["O", .id, .name] | @tsv)),
  ($d.repository.issue // empty
   | ([.projectItems.nodes[] | select(.project.id == $p.id)] | first) as $it
   | ["I", .id, ($it.id // ""), ($it.fieldValueByName.optionId // "")] | @tsv)
EOF

IFS= read -r -d '' M_ADD <<'EOF' || true
mutation TrackerAdd($project: ID!, $content: ID!) {
  addProjectV2ItemById(input: {projectId: $project, contentId: $content}) { item { id } }
}
EOF
J_ADD='.data.addProjectV2ItemById.item.id'

IFS= read -r -d '' M_SET <<'EOF' || true
mutation TrackerSet($project: ID!, $item: ID!, $field: ID!, $option: String!) {
  updateProjectV2ItemFieldValue(input: {projectId: $project, itemId: $item, fieldId: $field, value: {singleSelectOptionId: $option}}) { projectV2Item { id } }
}
EOF
J_SET='.data.updateProjectV2ItemFieldValue.projectV2Item.id'

# --- output -----------------------------------------------------------------

say() { printf 'tracker: %s\n' "$1"; }
die() { say "error: $1"; exit "${2:-1}"; }
usage() {
  die "usage: tracker.sh check | read-issue <ref> | create-issue <brief-file | assessment-file> <owner/repo> | set-status <brief|building|review> <ref>" 2
}

# Invisible format characters, as UTF-8 bytes (so any locale matches them):
# U+200B-200F, U+202A-202E (bidi embeddings), U+2066-2069 (bidi isolates).
INVISIBLE=(
  $'\xe2\x80\x8b' $'\xe2\x80\x8c' $'\xe2\x80\x8d' $'\xe2\x80\x8e' $'\xe2\x80\x8f'
  $'\xe2\x80\xaa' $'\xe2\x80\xab' $'\xe2\x80\xac' $'\xe2\x80\xad' $'\xe2\x80\xae'
  $'\xe2\x81\xa6' $'\xe2\x81\xa7' $'\xe2\x81\xa8' $'\xe2\x81\xa9'
)

# Control and invisible format characters -> "?", at most 60 characters (in
# the caller's locale).
clean() (
  local c
  s="$1"
  for c in "${INVISIBLE[@]}"; do s="${s//"$c"/?}"; done
  user_locale
  s="${s//[[:cntrl:]]/?}"
  printf '%s' "${s:0:60}"
)

# --- config -----------------------------------------------------------------

declare -A st=() # statuses.<key> -> board option name
kind="" login="" number="" board_ref=""

cfg_err() { die ".logistics.yml line $1: $2"; }

# parse_value <text after "key:"> <line no> <key path>: sets $val.
parse_value() {
  local r="$1" q inner after
  val=""
  [ -z "$r" ] || [[ "$r" == " "* ]] || cfg_err "$2" "no space after the colon"
  r="${r#"${r%%[! ]*}"}"
  case "$r" in
    \"* | \'*)
      q="${r:0:1}" inner="${r:1}"
      [[ "$inner" == *"$q"* ]] || cfg_err "$2" "unclosed quote"
      val="${inner%%"$q"*}"
      after="${inner#*"$q"}"
      [[ "$after" =~ $RE_AFTER_QUOTE ]] || cfg_err "$2" "junk after a quoted value"
      ;;
    \#* | "") ;;
    *)
      val="${r%% #*}"
      val="${val%"${val##*[! ]}"}"
      ;;
  esac
  [ -n "$val" ] || cfg_err "$2" "empty $3"
}

# no_value <text after "key:"> <line no> <key path>: a section key takes none.
no_value() {
  local r="${1#"${1%%[! ]*}"}"
  case "$r" in "" | \#*) ;; *) cfg_err "$2" "$3 takes no value" ;; esac
}

parse_config() {
  local line n=0 indent key rest path section="" seen=" " k
  while IFS= read -r line || [ -n "$line" ]; do
    n=$((n + 1))
    line="${line%$'\r'}"
    [[ "$line" =~ $RE_SKIP_LINE ]] && continue
    [[ "$line" != *$'\t'* ]] || cfg_err "$n" "tab in a key line"
    [[ "$line" =~ $RE_KEY ]] || cfg_err "$n" "not a key: value line"
    indent="${#BASH_REMATCH[1]}" key="${BASH_REMATCH[2]}" rest="${BASH_REMATCH[3]}"
    case "$indent:$key" in
      0:tracker)
        path=tracker
        # first key line must be tracker
        [ "$seen" = " " ] || [[ "$seen" == *" tracker "* ]] || cfg_err "$n" "tracker must be the first key"
        ;;
      2:provider | 2:project | 2:statuses)
        path="tracker.$key"
        [[ "$seen" == *" tracker "* ]] || cfg_err "$n" "$key outside tracker"
        section=""
        ;;
      4:brief | 4:building | 4:review)
        path="tracker.statuses.$key"
        [ "$section" = statuses ] || cfg_err "$n" "$key outside statuses"
        ;;
      0:* | 2:* | 4:*) cfg_err "$n" "unknown key" ;;
      *) cfg_err "$n" "bad indentation (0, 2 or 4 spaces)" ;;
    esac
    [[ "$seen" != *" $path "* ]] || cfg_err "$n" "duplicate $path"
    seen="$seen$path "
    case "$key" in
      tracker) no_value "$rest" "$n" "$path" ;;
      statuses) no_value "$rest" "$n" "$path"; section=statuses ;;
      provider)
        parse_value "$rest" "$n" "$path"
        [ "$val" = github ] || cfg_err "$n" "provider must be github"
        ;;
      project)
        parse_value "$rest" "$n" "$path"
        [[ "$val" =~ $RE_URL ]] || cfg_err "$n" "project must be https://github.com/users|orgs/<login>/projects/<number>"
        kind="${BASH_REMATCH[1]}" login="${BASH_REMATCH[2]}" number="${BASH_REMATCH[3]}"
        ;;
      brief | building | review) parse_value "$rest" "$n" "$path"; st[$key]="$val" ;;
    esac
  done <"$config"
  for k in tracker tracker.provider tracker.project tracker.statuses \
    tracker.statuses.brief tracker.statuses.building tracker.statuses.review; do
    [[ "$seen" == *" $k "* ]] || die ".logistics.yml: missing $k"
  done
  [[ "$number" =~ ^[0-9]+$ ]] || die ".logistics.yml: bad project number"
  board_ref="$kind/$login/projects/$number"
}

# --- gh plumbing --------------------------------------------------------------

gh_out="" gh_reason="" errfile="" tmpfiles=()
cleanup() { [ "${#tmpfiles[@]}" -eq 0 ] || command rm -f -- "${tmpfiles[@]}"; }

# run_gh <args>: stdout into $gh_out; on failure stdout is dropped and the
# reason, taken from stderr's first line, goes into $gh_reason.
run_gh() {
  local first=""
  if gh_out="$(gh "$@" 2>"$errfile")"; then return 0; fi
  gh_out=""
  IFS= read -r first <"$errfile" || true
  case "$first" in
    *"gh auth login"*) gh_reason="gh not authenticated; run gh auth login" ;;
    *INSUFFICIENT_SCOPES* | *"required scopes"*)
      gh_reason="token lacks the project scope; run gh auth refresh -s project" ;;
    *"Could not resolve to a ProjectV2"*)
      gh_reason="board $board_ref not found or not visible to this account; check tracker.project" ;;
    *)
      first="${first#gh: }"
      first="${first#GraphQL: }"
      gh_reason="$(clean "$first")"
      ;;
  esac
  [ -n "$gh_reason" ] || gh_reason="gh failed"
  return 1
}

# current_repo: sets $cur_repo the way gh issue resolves it (FR-029).
cur_repo=""
current_repo() {
  run_gh repo view --json nameWithOwner --jq .nameWithOwner || return 1
  if [[ ! "$gh_out" =~ $RE_REPO ]]; then
    gh_reason="gh repo view gave no owner/repo"
    return 1
  fi
  cur_repo="$gh_out"
}

# parse_ref <ref>: sets $ref_owner, $ref_repo (empty for #N), $ref_num.
ref_owner="" ref_repo="" ref_num=""
parse_ref() {
  if [[ "$1" =~ $RE_REF_SHORT ]]; then
    ref_owner="" ref_repo="" ref_num="${BASH_REMATCH[1]}"
  elif [[ "$1" =~ $RE_REF_FULL ]]; then
    ref_owner="${BASH_REMATCH[1]}" ref_repo="${BASH_REMATCH[2]}" ref_num="${BASH_REMATCH[3]}"
  else
    die "malformed issue ref \"$(clean "$1")\" (want #N or owner/repo#N)" 2
  fi
}

# resolve_ref: fills $ref_owner/$ref_repo for #N from the current repo.
resolve_ref() {
  [ -z "$ref_owner" ] || return 0
  current_repo || return 1
  ref_owner="${cur_repo%%/*}" ref_repo="${cur_repo#*/}"
}

valid_id() { [[ "$1" =~ $RE_ID ]]; }

# read_rows <filter output>: the tab-separated lines of J_BOARD / J_ITEM.
#   B <board_id> <can_update> <field_id>   the board (sets $have_b)
#   O <option id> <option name>            one per Status option: opt_ids/opt_names
#   I <issue_id> <item_id> <cur_opt>       the issue (sets $have_i); item_id and
#                                          cur_opt are empty when it isn't on the board
have_b=0 have_i=0 board_id="" can_update="" field_id="" issue_id="" item_id="" cur_opt=""
opt_ids=() opt_names=()
read_rows() {
  local tag f1 f2 f3
  have_b=0 have_i=0 opt_ids=() opt_names=()
  while IFS=$'\t' read -r tag f1 f2 f3; do
    case "$tag" in
      B) have_b=1 board_id="$f1" can_update="$f2" field_id="$f3" ;;
      O) opt_ids+=("$f1") opt_names+=("$f2") ;;
      I) have_i=1 issue_id="$f1" item_id="$f2" cur_opt="$f3" ;;
    esac
  done <<<"$1"
}

# board_problem: true (and $reason set) when the board can't take moves.
reason=""
board_problem() {
  if [ "$have_b" = 0 ]; then
    reason="board $board_ref not found or not visible to this account; check tracker.project"
  elif [ "$can_update" != true ]; then
    reason="this account can't edit board $board_ref; ask for write access"
  elif [ -z "$field_id" ]; then
    reason="board $board_ref has no single-select Status field"
  elif ! valid_id "$board_id" || ! valid_id "$field_id"; then
    reason="unexpected ID in the board's response"
  else
    return 1
  fi
}

# option_id <name>: sets $opt to the ID of the option named exactly <name>.
opt=""
option_id() {
  local i
  for i in "${!opt_names[@]}"; do
    if [ "${opt_names[$i]}" = "$1" ]; then
      opt="${opt_ids[$i]}"
      return 0
    fi
  done
  return 1
}

# --- subcommands --------------------------------------------------------------

cmd_check() {
  local line body="" in_body=0 name scopes="" have_scopes=0 k unknown="" list="" i
  run_gh api graphql --include -f query="$Q_BOARD" -f login="$login" -F number="$number" --jq "$J_BOARD" ||
    die "$gh_reason"
  while IFS= read -r line; do
    line="${line%$'\r'}"
    if [ "$in_body" = 1 ]; then
      body+="$line"$'\n'
    elif [ -z "$line" ]; then
      in_body=1
    else
      name="${line%%:*}"
      if [ "${name,,}" = x-oauth-scopes ]; then
        have_scopes=1
        scopes="${line#*:}"
      fi
    fi
  done <<<"$gh_out"
  if [ "$have_scopes" = 1 ] && [[ ! "$scopes" =~ $RE_SCOPE_PROJECT ]]; then
    die "token lacks the project scope; run gh auth refresh -s project"
  fi
  read_rows "$body"
  if board_problem; then die "$reason"; fi
  for k in brief building review; do
    option_id "${st[$k]}" || unknown+="unknown status \"$(clean "${st[$k]}")\" (statuses.$k); "
  done
  if [ -n "$unknown" ]; then
    for i in "${!opt_names[@]}"; do
      if [ "$i" -ge 10 ]; then
        list+=", ..."
        break
      fi
      [ -z "$list" ] || list+=", "
      list+="\"$(clean "${opt_names[$i]}")\""
    done
    die "${unknown}board options: ${list:-none}"
  fi
  say "ok $board_ref ($(clean "${st[brief]}"), $(clean "${st[building]}"), $(clean "${st[review]}"))"
}

cmd_read_issue() {
  parse_ref "$1"
  resolve_ref || die "$gh_reason"
  run_gh issue view "$ref_num" -R "$ref_owner/$ref_repo" --json number,title,body,labels,url ||
    die "$gh_reason"
  printf '%s\n' "$gh_out"
}

# trim_blank <text>: drops leading and trailing blank lines; sets $val.
trim_blank() {
  val="$1"
  while [[ "$val" == $'\n'* ]]; do val="${val#$'\n'}"; done
  while [[ "$val" == *$'\n' ]]; do val="${val%$'\n'}"; done
}

# doc_parts <file> <kind> <title prefix> <section 1> <section 2>: sets
# $title, $part1, $part2 (each section's text, outside-fence "## " lines
# start sections), or refuses (exit 2) naming <kind> and the section.
title="" part1="" part2=""
doc_parts() {
  local file="$1" kind="$2" prefix="$3" s1="$4" s2="$5"
  local line first=1 fence=0 section="" lines1="" lines2=""
  while IFS= read -r line || [ -n "$line" ]; do
    line="${line%$'\r'}"
    if [ "$first" = 1 ]; then
      first=0
      [[ "$line" == "$prefix"* ]] || die "$kind has no \"$prefix\" first line" 2
      title="${line#"$prefix"}"
      continue
    fi
    if [ "$fence" = 0 ] && [[ "$line" == "## "* ]]; then
      case "${line%"${line##*[! ]}"}" in
        "$s1") section=1 ;;
        "$s2") section=2 ;;
        *) section="" ;;
      esac
      continue
    fi
    [[ "$line" != '```'* ]] || fence=$((1 - fence))
    case "$section" in
      1) lines1+="$line"$'\n' ;;
      2) lines2+="$line"$'\n' ;;
    esac
  done <"$file"
  [ -n "${title//[[:space:]]/}" ] || die "$kind title is empty" 2
  trim_blank "$lines1"; part1="$val"
  trim_blank "$lines2"; part2="$val"
  [ -n "${part1//[[:space:]]/}" ] || die "$kind has no ${s1#"## "} section" 2
  [ -n "${part2//[[:space:]]/}" ] || die "$kind has no ${s2#"## "} section" 2
}

RE_BRIEF_PATH='^specs/briefs/[a-z0-9][a-z0-9-]*\.md$'
RE_ASSESSMENT_PATH='^\.specify/bugs/([a-z0-9][a-z0-9-]*)/assessment\.md$'

cmd_create_issue() {
  local path="$1" confirmed="$2" kind sub dir want body url slug="" label=() note=""
  # The path decides the source: a brief, or a bug's assessment.
  if [[ "$path" =~ $RE_BRIEF_PATH ]]; then
    kind=brief sub=specs/briefs
  elif [[ "$path" =~ $RE_ASSESSMENT_PATH ]]; then
    slug="${BASH_REMATCH[1]}"
    kind=assessment sub=".specify/bugs/$slug"
  else
    die "brief path must be specs/briefs/<name>.md or .specify/bugs/<slug>/assessment.md" 2
  fi
  [[ "$confirmed" =~ $RE_REPO ]] || die "malformed repo \"$(clean "$confirmed")\" (want owner/repo)" 2
  # The directory must physically be <root>/<sub>: a symlinked parent
  # resolves elsewhere. A leaf symlink is refused outright.
  dir="$(cd -P -- "$root/$sub" 2>/dev/null && pwd -P)" || die "no $sub directory" 2
  want="$(cd -P -- "$root" && pwd -P)/$sub"
  [ "$dir" = "$want" ] || die "$sub resolves outside the repo" 2
  [ -f "$root/$path" ] && [ ! -L "$root/$path" ] || die "$kind is not a regular file" 2

  body="$(mktemp)"
  tmpfiles+=("$body")
  if [ "$kind" = brief ]; then
    doc_parts "$root/$path" brief "# Brief: " "## Why" "## Behaviour"
    printf '## Why\n%s\n\n## Behaviour\n%s\n\nBrief: %s\n' "$part1" "$part2" "$path" >"$body"
  else
    doc_parts "$root/$path" assessment "# Bug Assessment: " "## Symptom" "## Root Cause Hypothesis"
    [[ ! "$part1"$'\n'"$part2" =~ $RE_SECRET ]] ||
      die "assessment's Symptom or Root Cause Hypothesis holds a secret-looking value; redact it first" 2
    printf '## Symptom\n%s\n\n## Root cause\n%s\n\nTrail: .specify/bugs/%s/\n' "$part1" "$part2" "$slug" >"$body"
    label=(--label bug)
  fi

  current_repo || die "could not create the issue ($gh_reason)"
  # The user confirmed a repo at the gate: never create it anywhere else.
  [ "$cur_repo" = "$confirmed" ] ||
    die "could not create the issue (current repo is $cur_repo, not $confirmed named at the gate)"
  # Never retried, but for a missing label: gh checks labels before it
  # creates anything, so that retry cannot duplicate the issue.
  if ! run_gh issue create -R "$cur_repo" --title "$title" --body-file "$body" ${label[@]+"${label[@]}"}; then
    [[ "${#label[@]}" != 0 && "$gh_reason" == *"could not add label"*"not found"* ]] ||
      die "could not create the issue ($gh_reason)"
    run_gh issue create -R "$cur_repo" --title "$title" --body-file "$body" ||
      die "could not create the issue ($gh_reason)"
    note=" (without the bug label: $cur_repo has none)"
  fi
  url="$gh_out"
  [[ "$url" =~ $RE_ISSUE_URL ]] || die "could not create the issue (unexpected URL from gh: $(clean "$url"))"
  say "created ${BASH_REMATCH[1]}#${BASH_REMATCH[2]}$note"
}

# set_attempt <status name>: one try. Returns 0 done, 1 gh failure (worth a
# retry), 2 a result that a retry won't change. Sets $reason and $changed;
# sets $added once an add succeeds (the caller clears it, a retry keeps it).
added=0 changed=0
set_attempt() {
  changed=0
  if ! resolve_ref; then
    reason="$gh_reason"
    return 1
  fi
  if ! run_gh api graphql -f query="$Q_ITEM" -f login="$login" -F number="$number" \
    -f owner="$ref_owner" -f repo="$ref_repo" -F issue="$ref_num" --jq "$J_ITEM"; then
    reason="$gh_reason"
    return 1
  fi
  read_rows "$gh_out"
  if board_problem; then return 2; fi
  if ! option_id "$1"; then
    reason="unknown status \"$(clean "$1")\" on the board"
    return 2
  fi
  if [ "$have_i" = 0 ]; then
    reason="issue $ref not found"
    return 2
  fi
  if ! valid_id "$issue_id" || ! valid_id "$opt" || { [ -n "$item_id" ] && ! valid_id "$item_id"; }; then
    reason="unexpected ID in the issue's response"
    return 2
  fi
  if [ -z "$item_id" ]; then
    if ! run_gh api graphql -f query="$M_ADD" -f project="$board_id" -f content="$issue_id" --jq "$J_ADD"; then
      reason="$gh_reason"
      return 1
    fi
    if ! valid_id "$gh_out"; then
      reason="unexpected ID in the add response"
      return 2
    fi
    item_id="$gh_out" cur_opt="" added=1
  fi
  if [ "$cur_opt" != "$opt" ]; then
    if ! run_gh api graphql -f query="$M_SET" -f project="$board_id" -f item="$item_id" \
      -f field="$field_id" -f option="$opt" --jq "$J_SET"; then
      reason="$gh_reason"
      return 1
    fi
    changed=1
  fi
}

ref=""
cmd_set_status() {
  local name rc=0 delay="${TRACKER_RETRY_DELAY:-2}"
  name="${st[$1]}"
  ref="$2"
  parse_ref "$ref"
  added=0
  set_attempt "$name" || rc=$?
  # One retry, and only for a gh failure (FR-017); results are final (FR-028).
  if [ "$rc" = 1 ]; then
    [[ "$delay" =~ ^[0-9]+$ ]] || delay=2
    sleep "$delay"
    rc=0
    set_attempt "$name" || rc=$?
  fi
  [ "$rc" = 0 ] || die "could not set $ref to \"$(clean "$name")\" ($reason); set it by hand"
  if [ "$changed" = 0 ]; then
    say "$ref already \"$(clean "$name")\""
    return 0
  fi
  local suffix=""
  [ "$added" = 0 ] || suffix=" (added to board)"
  say "$ref set to \"$(clean "$name")\"$suffix"
}

# --- main ---------------------------------------------------------------------

sub="${1:-}"
[ "$#" -eq 0 ] || shift
case "$sub" in
  check) [ "$#" -eq 0 ] || usage ;;
  read-issue) [ "$#" -eq 1 ] || usage ;;
  create-issue) [ "$#" -eq 2 ] || usage ;;
  set-status)
    [ "$#" -eq 2 ] || usage
    case "$1" in brief | building | review) ;; *) usage ;; esac
    ;;
  *) usage ;;
esac

root="$(git rev-parse --show-toplevel 2>/dev/null)" || root="$PWD"
config="$root/.logistics.yml"
if [ ! -e "$config" ]; then
  [ -e "$root/.feat-agent.yml" ] && die ".feat-agent.yml is now .logistics.yml; rename it"
  say "off (no .logistics.yml)"
  exit 0
fi
[ -f "$config" ] && [ -r "$config" ] || die ".logistics.yml is not a readable file"
parse_config

command -v gh >/dev/null 2>&1 || die "gh not found; install it (https://cli.github.com)"
trap cleanup EXIT
errfile="$(mktemp)"
tmpfiles+=("$errfile")

case "$sub" in
  check) cmd_check ;;
  read-issue) cmd_read_issue "$1" ;;
  create-issue) cmd_create_issue "$1" "$2" ;;
  set-status) cmd_set_status "$1" "$2" ;;
esac
