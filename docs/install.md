# Installing feat-agents

## What works where

|                                     | Claude Code | Codex, OpenCode                       | Gemini CLI, Antigravity, other harnesses that read `~/.agents/skills` |
| ----------------------------------- | ----------- | ------------------------------------- | --------------------------------------------------------------------- |
| `/feat` (the build, phases 2–8)     | **yes**     | no                                    | no                                                                    |
| `/feat-brief` (interview and brief) | yes         | should work, untested                 | should work, untested                                                 |
| `feat-*` agents used on their own   | yes         | yes (Codex ignores their tool limits) | no: no custom agents                                                  |
| a cost script (since moved out)                     | yes         | no: reads Claude Code transcripts     | no                                                                    |

`/feat` needs Claude Code's agent tool with a model and effort per call,
and `EnterWorktree`; it stops with a message elsewhere. Installing for
another harness gives you the brief step and the agents there, not the
build. A brief written in another harness can be built with `/feat` in
Claude Code. Why it isn't portable: [design.md](design.md#distribution-one-source-three-installers).

## Prerequisites

| Tool                            | Why                                                                                   | Install                                         |
| ------------------------------- | ------------------------------------------------------------------------------------- | ----------------------------------------------- |
| Claude Code (tested on 2.1.308) | runs `/feat` and its agents; older versions may ignore subagent `effort` or `skills`  | <https://code.claude.com/docs/en/setup>         |
| git                             | branches, worktrees, diffs                                                            | your package manager                            |
| GitHub CLI `gh`, logged in      | phase 8 pushes and opens the PR                                                       | <https://cli.github.com>, then `gh auth login`  |
| Spec Kit CLI `specify`          | phases 2–6 are Spec Kit skills                                                        | `uv tool install specify-cli`                   |
| APM (`apm`) or Node.js (`npx`)  | APM installs everything; `npx` installs the third-party skills for the other two ways | `uv tool install apm-cli`; <https://nodejs.org> |

In a clone of this repo, `mise install` installs all of these (and
`shellcheck`) at the versions the release was tested with; see
[`mise.toml`](../mise.toml).

The workflow uses Opus and Sonnet. Your plan must give access to both; if one
isn't available, change the size table (see [usage.md](usage.md#tuning)).

## 1. Install the skills and agents

Pick one of three ways. Use only one: two would load the workflow twice.

### With APM (recommended: every harness, dependencies included)

[APM](https://microsoft.github.io/apm/) (Microsoft's Agent Package Manager)
installs the 2 skills, the 8 agents and the 3 third-party skills they use,
in one command:

```sh
uv tool install apm-cli          # or: pipx install apm-cli
apm install -g pdemagny/feat-agents -t claude,codex,opencode
```

`-g` installs for your user (all projects); drop it inside a project to
install there only. `-t` lists the harnesses to install for:

| Harness (`-t`)                  | Skills go to                           | Agents go to                      | Notes                                                                      |
| ------------------------------- | -------------------------------------- | --------------------------------- | -------------------------------------------------------------------------- |
| `claude`                        | `~/.claude/skills/`                    | `~/.claude/agents/`               | the only harness that runs `/feat` end to end                              |
| `codex`                         | `~/.agents/skills/`                    | `~/.codex/agents/*.toml`          | APM converts the agents; tool restrictions (`disallowedTools`) are dropped |
| `opencode`                      | `~/.config/opencode/skills/`           | `~/.config/opencode/agents/`      |                                                                            |
| `gemini`, `antigravity`, others | `~/.agents/skills/` and their own dirs | none: these have no custom agents |                                                                            |

APM pins what it installed in `~/.apm/apm.lock.yaml`. Update with `apm
update -g`, remove with `apm uninstall -g pdemagny/feat-agents`.

### As a Claude Code plugin (Claude Code only)

```
/plugin install feat-agents --marketplace pdemagny/feat-agents
```

On Claude Code before 2.1.275, use two commands:

```sh
claude plugin marketplace add pdemagny/feat-agents
claude plugin install feat-agents@feat-agents
```

Plugins name everything after the plugin: the commands become
`/feat-agents:feat` and `/feat-agents:feat-brief`, the agents
`feat-agents:feat-planner` and so on. The skills handle both names. A plugin
can't install the third-party skills, so add them with the [skills
CLI](https://github.com/vercel-labs/skills):

```sh
npx skills add addyosmani/agent-skills -s interview-me security-and-hardening performance-optimization -a claude-code -g -y
```

Update with `/plugin update feat-agents`.

### From a clone (to work on the workflow)

```sh
git clone https://github.com/pdemagny/feat-agents ~/Projects/feat-agents
cd ~/Projects/feat-agents
./install.sh             # symlinks into ~/.claude, so edits apply at once
./install.sh deps        # the three third-party skills (skills CLI)
```

`--copy` copies instead of linking; `--target ~/proj/.claude` installs for
one project. Anything already at a destination that isn't a link into this
repo (for example an older hand-written `feat` skill) is moved to
`~/.claude/feat-agents-backups/<name>.<timestamp>` first, never deleted.
Backups stay out of `skills/` and `agents/`, where Claude Code would load
them as a second skill or agent.

Restart Claude Code (or start a new session) after any of the three.

## 2. The third-party skills

| Skill                      | Source                                                                | Used by                                                     |
| -------------------------- | --------------------------------------------------------------------- | ----------------------------------------------------------- |
| `interview-me`             | [addyosmani/agent-skills](https://github.com/addyosmani/agent-skills) | `/feat-brief` (phase 1)                                     |
| `security-and-hardening`   | addyosmani/agent-skills                                               | `feat-sec-reviewer` (phase 4), `feat-code-reviewer` lens 7b |
| `performance-optimization` | addyosmani/agent-skills                                               | `feat-code-reviewer` lens 7c                                |

They are declared in `apm.yml` (APM installs them) and in `install.sh`
(`./install.sh deps`).

Three more checklists are built into `feat-code-reviewer` instead of being
installed: the standards and spec review of lens 7a (from Matt Pocock's
`code-review`), the over-engineering review of lens 7d (from the pre-v5
`ponytail-review`) and the readability review of lens 7e (from Addy
Osmani's `code-simplification`). All MIT, credited in the agent and the
README.

## 3. Set up Spec Kit in each project

Once per project that will use `/feat`, with the Claude integration
(`/feat` runs only in Claude Code):

```sh
cd ~/your-project
specify init --here --integration claude
```

This adds `.specify/` and the `speckit-*` skills in `.claude/skills/`.
Spec Kit also has integrations for other harnesses (`--integration codex`,
`gemini`, and more); they let you run the `speckit-*` commands there by
hand, but `/feat` won't drive them. `/feat-brief` doesn't need Spec Kit.
The workflow uses `speckit-specify`, `speckit-clarify`, `speckit-plan`,
`speckit-tasks`, `speckit-analyze` and `speckit-implement`. Writing a
constitution (`/speckit-constitution`) is optional but makes phase 3's
constitution check meaningful.

## 4. Check

```sh
~/Projects/feat-agents/install.sh check ~/your-project
```

It needs a clone of this repo, and works whichever way you installed. Every
line should say `ok`; each `MISSING` line names the command that fixes it.
Exit code 0 means ready.

## Updating

- APM: `apm update -g`. Plugin: `/plugin update feat-agents`. Clone:
  `git pull` (with `--copy`, rerun `./install.sh --copy`).
- Third-party skills installed with the skills CLI: `npx skills update -g`.
- Spec Kit: upgrade the CLI, then rerun `specify init --here --integration
  claude --force` in each project to refresh its templates and skills.

## Uninstalling

APM: `apm uninstall -g pdemagny/feat-agents`. Plugin: `/plugin uninstall
feat-agents`. Clone:

```sh
./install.sh uninstall               # or --target <dir>
```

Removes only the links that point into this repo. Copies and backups are
listed and left for you to remove. Third-party skills stay: `npx skills
remove <name> --global` if you no longer want them.
