#!/usr/bin/env bash
# story.sh - what a tasks.md says about its user stories, for /feat.
#
#   story.sh [--] <tasks.md>          every group's task IDs and count (phase 5)
#   story.sh [--] <tasks.md> US<n>    one story's tasks: IDs, checked state,
#                                     paths, the unchecked count (phase 6)
#
# A first argument `--` is dropped; the script takes no option. Everything goes
# to stdout, nothing to stderr. Exit 0 ok, 1 a tasks.md problem (one
# `story: error: ...` line), 2 usage (one `story: usage: ...` line). On exit 0
# the output holds no backtick, so a fence of four backticks around it holds.
#
# Reading tasks.md, per line, in file order:
#   - a line starting with three backticks toggles a fence; fenced lines are skipped;
#   - `## Phase ...: User Story <n>` starts story <n>; any other `## ` heading
#     starts another section (`###` and deeper do not);
#   - `- [ ] T001 ...` (`x` or `X` for checked) is a task. Its markers are the
#     [P] and [US<n>] tokens right after the ID; the first [US<n>] is its story.
# Groups: a tagged task belongs to its story; an untagged one before the story
# phases is setup/foundational, one after them is polish, one inside them is an
# error. The story phases run from the first story heading to the first
# non-story heading after the last story heading.
# Paths of a task: the backticked spans of its text without whitespace that
# hold a `/` or end in `.` plus a letter and letters or digits, and none of
# `<`, `*`, `://`. They are candidates: the script never checks the disk.
#
# All-stories form:
#   setup/foundational: <s> tasks[: IDs]
#   US<n>: <k> tasks[: IDs]            one line per story, in heading order
#   polish: <p> tasks[: IDs]
#   total: <t> tasks
# One-story form:
#   US<n>: <k> tasks[; setup/foundational: <s> tasks][; polish: <p> tasks]; <u> unchecked
#   <ID> [ ]|[x] paths: <path> ... | none      setup/foundational first, polish last
#   files: <path> ... | none
# Setup/foundational is printed with the first story, polish with the last.

set -euo pipefail
set -f
export LC_ALL=C

die() { printf 'story: error: %s\n' "$1"; exit 1; }
usage() { printf 'story: usage: story.sh [--] <tasks.md> [US<n>]\n'; exit 2; }

if [[ ${1-} == -- ]]; then shift; fi
if (( $# < 1 || $# > 2 )); then usage; fi
file=$1
want=
if (( $# == 2 )); then
  [[ $2 =~ ^US([0-9]+)$ ]] || usage
  want=$((10#${BASH_REMATCH[1]}))
fi
[[ -f $file && -r $file ]] || die "cannot read $file"

re_story='^##[[:space:]]+Phase[^:]*:[[:space:]]*User[[:space:]]+Story[[:space:]]+([0-9]+)'
re_sect='^##[[:space:]]'
re_task='^- \[([ xX])\] (T[0-9]+)([[:space:]].*)?$'
re_marker='^[[:space:]]+\[(P|US[0-9]+)\](.*)$'
re_ext='\.[A-Za-z][A-Za-z0-9]*$'
fence='```'

stories=()
# has_story <n>: is story n in stories
has_story() {
  local s
  for s in ${stories[@]+"${stories[@]}"}; do
    if (( s == $1 )); then return 0; fi
  done
  return 1
}
sect=0
first_sect=999999
last_sect=-1
fenced=0
lineno=0
t_id=() t_chk=() t_tag=() t_sect=() t_line=() t_paths=()

while IFS= read -r line || [[ -n $line ]]; do
  lineno=$((lineno + 1))
  if [[ $line == "$fence"* ]]; then
    fenced=$((1 - fenced))
    continue
  fi
  if (( fenced )); then continue; fi
  if [[ $line =~ $re_story ]]; then
    sect=$((sect + 1))
    n=$((10#${BASH_REMATCH[1]}))
    if (( sect < first_sect )); then first_sect=$sect; fi
    last_sect=$sect
    has_story "$n" || stories+=("$n")
  elif [[ $line =~ $re_sect ]]; then
    sect=$((sect + 1))
  elif [[ $line =~ $re_task ]]; then
    chk=${BASH_REMATCH[1]}
    id=${BASH_REMATCH[2]}
    rest=${BASH_REMATCH[3]}
    tag=
    while [[ $rest =~ $re_marker ]]; do
      m=${BASH_REMATCH[1]}
      rest=${BASH_REMATCH[2]}
      if [[ -z $tag && $m == US* ]]; then tag=$((10#${m#US})); fi
    done
    # paths: odd fields between backticks, when closed
    ticks=${rest//[^\`]/}
    nticks=${#ticks}
    IFS='`' read -r -a parts <<< "$rest" || true
    paths=
    i=1
    while (( i < nticks && i < ${#parts[@]} )); do
      p=${parts[i]}
      i=$((i + 2))
      [[ -n $p && $p != *[[:space:]]* ]] || continue
      [[ $p != *'<'* && $p != *'*'* && $p != *'://'* ]] || continue
      [[ $p == */* || $p =~ $re_ext ]] || continue
      case " $paths " in *" $p "*) continue ;; esac
      paths+="${paths:+ }$p"
    done
    [[ $chk == ' ' ]] || chk=x
    t_id+=("$id") t_chk+=("$chk") t_tag+=("$tag") t_sect+=("$sect")
    t_line+=("$lineno") t_paths+=("$paths")
  fi
done < "$file"

ntasks=${#t_id[@]}

tagged=0
for (( i = 0; i < ntasks; i++ )); do
  if [[ -n ${t_tag[i]} ]]; then tagged=1; fi
done
(( tagged )) || die "no [US<n>] tag in $file"

# group of each task: a story number, "sf" (setup/foundational) or "pol" (polish)
t_grp=()
for (( i = 0; i < ntasks; i++ )); do
  if [[ -n ${t_tag[i]} ]]; then
    has_story "${t_tag[i]}" || die "${t_id[i]} (line ${t_line[i]}) is tagged US${t_tag[i]} but no phase heading is User Story ${t_tag[i]}"
    t_grp+=("${t_tag[i]}")
  elif (( t_sect[i] < first_sect )); then
    t_grp+=(sf)
  elif (( t_sect[i] > last_sect )); then
    t_grp+=(pol)
  else
    die "${t_id[i]} (line ${t_line[i]}) has no [US<n>] tag inside the story phases"
  fi
done

if [[ -n $want ]]; then
  if ! has_story "$want"; then
    list=
    for s in ${stories[@]+"${stories[@]}"}; do list+="${list:+ }US$s"; done
    die "no User Story $want in $file (stories: $list)"
  fi
fi

# group_line <label> <group>: "<label>: <k> tasks[: IDs]"
group_line() {
  local ids='' k=0 i
  for (( i = 0; i < ntasks; i++ )); do
    if [[ ${t_grp[i]} == "$2" ]]; then
      k=$((k + 1))
      ids+=" ${t_id[i]}"
    fi
  done
  if (( k )); then printf '%s: %d tasks:%s\n' "$1" "$k" "$ids"; else printf '%s: 0 tasks\n' "$1"; fi
}

# group_count <group>
group_count() {
  local k=0 i
  for (( i = 0; i < ntasks; i++ )); do
    if [[ ${t_grp[i]} == "$1" ]]; then k=$((k + 1)); fi
  done
  printf '%d' "$k"
}

if [[ -z $want ]]; then
  group_line setup/foundational sf
  for s in ${stories[@]+"${stories[@]}"}; do group_line "US$s" "$s"; done
  group_line polish pol
  printf 'total: %d tasks\n' "$ntasks"
  exit 0
fi

first=${stories[0]}
last=${stories[${#stories[@]} - 1]}
header="US$want: $(group_count "$want") tasks"
is_first=0 is_last=0
if (( want == first )); then is_first=1; header+="; setup/foundational: $(group_count sf) tasks"; fi
if (( want == last )); then is_last=1; header+="; polish: $(group_count pol) tasks"; fi

out=
files=
unchecked=0
for (( i = 0; i < ntasks; i++ )); do
  g=${t_grp[i]}
  if [[ $g == "$want" ]] || { (( is_first )) && [[ $g == sf ]]; } || { (( is_last )) && [[ $g == pol ]]; }; then
    if [[ ${t_chk[i]} == ' ' ]]; then unchecked=$((unchecked + 1)); fi
    out+="${t_id[i]} [${t_chk[i]}] paths: ${t_paths[i]:-none}"$'\n'
    for p in ${t_paths[i]}; do
      case " $files " in *" $p "*) ;; *) files+="${files:+ }$p" ;; esac
    done
  fi
done

printf '%s; %d unchecked\n' "$header" "$unchecked"
printf '%s' "$out"
printf 'files: %s\n' "${files:-none}"
