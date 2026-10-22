# Installing feat-agents

## Prerequisites

| Tool | Why | Install |
|---|---|---|
| Claude Code (tested on 2.1.308) | runs the skill and agents; older versions may ignore subagent `effort` or `skills` | <https://code.claude.com/docs/en/setup> |
| git | branches, worktrees, diffs | your package manager |
| GitHub CLI `gh`, logged in | phase 8 pushes and opens the PR | <https://cli.github.com>, then `gh auth login` |
| Spec Kit CLI `specify` | phases 2–6 are Spec Kit skills | `uv tool install specify-cli` (or `mise use -g pypi:specify-cli`) |
| Node.js / `npx` | only to install the third-party skills | <https://nodejs.org> |

The workflow uses Opus and Sonnet. Your plan must give access to both; if one
isn't available, change the size table (see [usage.md](usage.md#tuning)).

## 1. Install the skill and agents

```sh
./install.sh                       # symlinks into ~/.claude (all projects)
./install.sh --copy                # copies instead of symlinks
./install.sh --target ~/proj/.claude   # one project only
```

| Installed | Where (default target) |
|---|---|
| `skills/feat/`, `skills/feat-brief/` | `~/.claude/skills/` |
| `agents/feat-*.md` (8 files) | `~/.claude/agents/` |

Symlinks are the default so that editing this repo changes the installed
workflow immediately; use `--copy` to pin a version. Anything already at a
destination that isn't a link into this repo (for example an older
hand-written `feat` skill) is moved to
`~/.claude/feat-agents-backups/<name>.<timestamp>` first, never deleted.
Backups stay out of `skills/` and `agents/`, where Claude Code would load
them as a second skill or agent.

Restart Claude Code (or start a new session) to pick up new agents.

## 2. Install the third-party skills

```sh
./install.sh deps
```

This runs `npx skills add <source> --skill <name> --agent claude-code --global`
for each skill below. They land in `~/.agents/skills/` and are linked into
`~/.claude/skills/`.

| Skill | Source | Used by |
|---|---|---|
| `interview-me` | [addyosmani/agent-skills](https://github.com/addyosmani/agent-skills) | `/feat-brief` (phase 1) |
| `security-and-hardening` | addyosmani/agent-skills | `feat-sec-reviewer` (phase 4), `feat-code-reviewer` lens 7b |
| `performance-optimization` | addyosmani/agent-skills | `feat-code-reviewer` lens 7c |

Three more checklists are built into `feat-code-reviewer` instead of being
installed: the standards and spec review of lens 7a (from Matt Pocock's
`code-review`), the over-engineering review of lens 7d (from the pre-v5
`ponytail-review`) and the readability review of lens 7e (from Addy
Osmani's `code-simplification`). All MIT, credited in the agent and the
README.

## 3. Set up Spec Kit in each project

Once per project that will use `/feat`:

```sh
cd ~/your-project
specify init --here --integration claude
```

This adds `.specify/` and the `speckit-*` skills in `.claude/skills/`. The
workflow uses `speckit-specify`, `speckit-clarify`, `speckit-plan`,
`speckit-tasks`, `speckit-analyze` and `speckit-implement`. Writing a
constitution (`/speckit-constitution`) is optional but makes phase 3's
constitution check meaningful.

## 4. Check

```sh
~/Projects/feat-agents/install.sh check ~/your-project
```

Every line should say `ok`; each `MISSING` line names the command that fixes
it. Exit code 0 means ready.

## Updating

- This repo: `git pull`. With symlinks, that's all; with `--copy`, rerun
  `./install.sh --copy`.
- Third-party skills: `npx skills update --global`.
- Spec Kit: upgrade the CLI, then rerun `specify init --here --integration
  claude --force` in each project to refresh its templates and skills.

## Uninstalling

```sh
./install.sh uninstall               # or --target <dir>
```

Removes only the links that point into this repo. Copies and backups are
listed and left for you to remove. Third-party skills stay: `npx skills
remove <name> --global` if you no longer want them.
