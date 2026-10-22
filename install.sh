#!/usr/bin/env bash
# Install the /feat skill and its feat-* subagents into Claude Code.
#
#   ./install.sh [install] [--copy] [--target DIR]   link (or copy) skill + agents
#   ./install.sh deps                                install the third-party skills
#   ./install.sh check [PROJECT_DIR]                 report what is missing
#   ./install.sh uninstall [--target DIR]            remove what install created
#
# --target defaults to ~/.claude (user level). Pass a project's .claude
# directory to install for that project only.
set -euo pipefail

repo="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
target="$HOME/.claude"
mode="link"
cmd=install
project=""

# Third-party skills, as "<github source> <skill>".
deps=(
  "addyosmani/agent-skills interview-me"
  "addyosmani/agent-skills security-and-hardening"
  "addyosmani/agent-skills performance-optimization"
)
# Installed per project by `specify init --integration claude`.
speckit_skills=(speckit-specify speckit-clarify speckit-plan speckit-tasks speckit-analyze speckit-implement)
tools=(claude git gh specify)

while [ $# -gt 0 ]; do
  case "$1" in
    install|deps|check|uninstall) cmd="$1" ;;
    --copy) mode=copy ;;
    --target) target="$2"; shift ;;
    -h|--help) sed -n '2,10p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) if [ "$cmd" = check ] && [ -z "$project" ]; then project="$1"
       else echo "unknown argument: $1" >&2; exit 2; fi ;;
  esac
  shift
done

# place SRC DEST: link or copy, backing up anything that isn't already ours.
place() {
  local src="$1" dest="$2"
  if [ -L "$dest" ] && [ "$(readlink -f "$dest")" = "$(readlink -f "$src")" ]; then
    echo "ok       $dest"; return
  fi
  if [ -e "$dest" ] || [ -L "$dest" ]; then
    local bak
    # Outside skills/ and agents/: Claude Code would load a backup there as a skill or agent.
    bak="$HOME/.claude/feat-agents-backups/$(basename "$dest").$(date +%Y%m%d%H%M%S)"
    mkdir -p "$(dirname "$bak")"
    mv "$dest" "$bak"
    echo "backup   $dest -> $bak"
  fi
  if [ "$mode" = link ]; then ln -s "$src" "$dest"; else cp -R "$src" "$dest"; fi
  echo "$mode     $dest"
}

has_skill() {
  local name="$1" dir
  for dir in "$target/skills" "$HOME/.claude/skills" ${project:+"$project/.claude/skills"}; do
    [ -f "$dir/$name/SKILL.md" ] && return 0
  done
  return 1
}

has_agent() {
  [ -f "$target/agents/$1" ] || [ -f "$HOME/.claude/agents/$1" ] ||
    { [ -n "$project" ] && [ -f "$project/.claude/agents/$1" ]; }
}

case "$cmd" in
  install)
    mkdir -p "$target/skills" "$target/agents"
    for d in "$repo"/skills/*/; do
      d="${d%/}"
      place "$d" "$target/skills/$(basename "$d")"
    done
    for f in "$repo"/agents/*.md; do
      place "$f" "$target/agents/$(basename "$f")"
    done
    echo
    echo "Next: ./install.sh deps (third-party skills), then ./install.sh check <project>"
    ;;

  deps)
    command -v npx >/dev/null || { echo "npx not found: install Node.js first" >&2; exit 1; }
    for d in "${deps[@]}"; do
      read -r src skill <<<"$d"
      npx -y skills add "$src" --skill "$skill" --agent claude-code --global --yes
    done
    ;;

  check)
    missing=0
    # expect LABEL FIX CMD...: run CMD, report LABEL as ok or missing with FIX.
    expect() {
      local label="$1" fix="$2"; shift 2
      if "$@" >/dev/null 2>&1; then echo "ok       $label"
      else echo "MISSING  $label ($fix)"; missing=1; fi
    }
    for t in "${tools[@]}"; do expect "tool $t" "install it" command -v "$t"; done
    expect "gh authenticated" "gh auth login" gh auth status
    for d in "$repo"/skills/*/; do
      s="$(basename "$d")"
      expect "skill $s" "./install.sh" has_skill "$s"
    done
    for f in "$repo"/agents/*.md; do
      a="$(basename "$f")"
      expect "agent ${a%.md}" "./install.sh" has_agent "$a"
    done
    for d in "${deps[@]}"; do
      read -r _ skill <<<"$d"
      expect "skill $skill" "./install.sh deps" has_skill "$skill"
    done
    if [ -n "$project" ]; then
      fix="specify init --here --integration claude"
      expect "spec kit in $project" "$fix" test -d "$project/.specify"
      for s in "${speckit_skills[@]}"; do expect "skill $s" "$fix" has_skill "$s"; done
    else
      echo "skipped  spec kit checks (pass a project dir)"
    fi
    exit "$missing"
    ;;

  uninstall)
    for dest in "$target"/skills/feat "$target"/skills/feat-* "$target"/agents/feat-*.md; do
      [ -e "$dest" ] || [ -L "$dest" ] || continue
      if [ -L "$dest" ] && [[ "$(readlink -f "$dest")" == "$repo"/* ]]; then
        rm "$dest"; echo "removed  $dest"
      else
        echo "kept     $dest (not a link into $repo; remove it by hand)"
      fi
    done
    ;;
esac
