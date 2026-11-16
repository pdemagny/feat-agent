#!/usr/bin/env bash
# Spec numbers for the /feat shipper: which NNN a new `specs/NNN-<name>/` dir
# may take without clashing with main or with another feature in flight.
#
#   spec-number.sh next <default-branch>
#   spec-number.sh check <default-branch> <NNN-short-name>
#
# A number is taken when it leads a `specs/NNN-*` entry on the freshly
# fetched origin/<default-branch>, a `specs/NNN-*/` path among an open PR's
# files (paginated, so PRs with more than 100 files count), or, for an open
# PR whose files hold no `specs/` dir, its branch name `NNN-*`. Only
# same-repo PRs count (the shipper pushes to origin; fork PRs are ignored),
# and only 3- or 4-digit numbers (longer leading digits are not a spec
# number). `next` prints the highest taken number plus one, three digits at
# least. `check` ignores entries named exactly <NNN-short-name> (the
# caller's own dir) and prints `keep NNN` when NNN is free, else
# `renumber MMM` with the next free number.
#
# Works from any directory of the repo. One line on stdout. Exit 0 ok,
# 1 failure (git or gh failed: never a guess), 2 usage error; errors go to
# stderr.
set -euo pipefail
export LC_ALL=C

die() { printf 'spec-number: error: %s\n' "$1" >&2; exit "${2:-1}"; }
usage() {
  die "usage: spec-number.sh next <default-branch> | check <default-branch> <NNN-short-name>" 2
}

RE_BRANCH='^[A-Za-z0-9._][A-Za-z0-9._/-]{0,199}$'
RE_OWN='^([0-9]{3,4})-[A-Za-z0-9._-]+$'
RE_NUMBERED='^([0-9]{3,4})-'

cmd="${1:-}"
default="${2:-}"
own="" own_num=""
case "$cmd" in
  next) [ "$#" -eq 2 ] || usage ;;
  check) [ "$#" -eq 3 ] || usage; own="$3"
         [[ "$own" =~ $RE_OWN ]] || die "not a numbered spec dir name: $own" 2
         own_num="${BASH_REMATCH[1]}" ;;
  *) usage ;;
esac
[[ "$default" =~ $RE_BRANCH ]] || die "bad branch name: $default" 2

# names: one spec dir or branch name per line, from every source.
names=""
add() { [ -z "$1" ] || names+="$1"$'\n'; }

git fetch --quiet origin "+refs/heads/$default:refs/remotes/origin/$default" \
  || die "git fetch origin $default failed"
# --full-tree: the specs/ pathspec is relative to the repo root, not the cwd.
listing="$(git ls-tree --full-tree --name-only "refs/remotes/origin/$default" specs/)" \
  || die "git ls-tree origin/$default failed"
while IFS= read -r path; do add "${path#specs/}"; done <<<"$listing"

prs="$(gh pr list --state open --limit 1000 \
  --json number,isCrossRepository,headRefName \
  --jq '.[] | "\(.number) \(.isCrossRepository) \(.headRefName)"')" \
  || die "gh pr list failed"
while read -r pr fork branch; do
  [ -n "${pr:-}" ] || continue
  [[ "$pr" =~ ^[0-9]+$ && "$fork" =~ ^(true|false)$ ]] \
    || die "unexpected gh pr list line: $pr $fork $branch"
  [ "$fork" = false ] || continue
  files="$(gh api --paginate "repos/{owner}/{repo}/pulls/$pr/files" \
    --jq '.[].filename')" || die "gh api files of PR #$pr failed"
  has_spec=no
  while IFS= read -r f; do
    [[ "$f" == specs/*/* ]] || continue
    f="${f#specs/}"
    add "${f%%/*}"
    has_spec=yes
  done <<<"$files"
  # A branch name counts only for a PR without spec files: issue branches
  # (`370-foo`) carry an issue number, not a spec number.
  [ "$has_spec" = yes ] || add "$branch"
done <<<"$prs"

# numbers [skip]: the leading number of every name but <skip>, one per line.
numbers() {
  local name
  while IFS= read -r name; do
    [ -n "$name" ] && [ "$name" != "${1:-}" ] || continue
    [[ "$name" =~ $RE_NUMBERED ]] || continue
    echo "$((10#${BASH_REMATCH[1]}))"
  done <<<"$names"
}

# next_free [skip]: the highest number among the others, plus one.
next_free() { printf '%03d' "$(( $( { echo 0; numbers "${1:-}"; } | sort -n | tail -n 1) + 1 ))"; }

if [ "$cmd" = next ]; then
  printf '%s\n' "$(next_free)"
else
  others="$(numbers "$own")"
  if grep -qx "$((10#$own_num))" <<<"$others"; then
    printf 'renumber %s\n' "$(next_free "$own")"
  else
    printf 'keep %s\n' "$own_num"
  fi
fi
