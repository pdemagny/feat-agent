# Installing feat-agent

Claude Code only. Three ways to install; the design behind them:
[design.md](design.md#distribution-one-source-three-installers).

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

### With APM (recommended: dependencies included)

[APM](https://microsoft.github.io/apm/) (Microsoft's Agent Package Manager)
installs the 2 skills, the 8 agents and the 3 third-party skills they use,
in one command:

```sh
uv tool install apm-cli          # or: pipx install apm-cli
apm install -g pdemagny/feat-agent -t claude
```

`-g` installs for your user (all projects) into `~/.claude/`; drop it
inside a project to install there only.

### As a Claude Code plugin

```
/plugin install feat-agent --marketplace pdemagny/feat-agent
```

On Claude Code before 2.1.275, use two commands:

```sh
claude plugin marketplace add pdemagny/feat-agent
claude plugin install feat-agent@feat-agent
```

Plugins name everything after the plugin: the commands become
`/feat-agent:feat` and `/feat-agent:brief`, the agents
`feat-agent:feat-planner` and so on. The skills handle both names. A plugin
can't install the third-party skills, so add them with the [skills
CLI](https://github.com/vercel-labs/skills):

```sh
npx skills add addyosmani/agent-skills -s interview-me security-and-hardening performance-optimization -a claude-code -g -y
```

Update with `/plugin update feat-agent`.

### From a clone (to work on the workflow)

```sh
git clone https://github.com/pdemagny/feat-agent ~/Projects/feat-agent
cd ~/Projects/feat-agent
./install.sh             # symlinks into ~/.claude, so edits apply at once
./install.sh deps        # the three third-party skills (skills CLI)
```

`--copy` copies instead of linking; `--target ~/proj/.claude` installs for
one project. Anything already at a destination that isn't a link into this
repo (for example an older hand-written `feat` skill) is moved to
`~/.claude/feat-agent-backups/<name>.<timestamp>` first, never deleted.
Backups stay out of `skills/` and `agents/`, where Claude Code would load
them as a second skill or agent.

Restart Claude Code (or start a new session) after any of the three.

## 2. The third-party skills

| Skill                      | Source                                                                | Used by                                                     |
| -------------------------- | --------------------------------------------------------------------- | ----------------------------------------------------------- |
| `interview-me`             | [addyosmani/agent-skills](https://github.com/addyosmani/agent-skills) | `/brief` (phase 1)                                          |
| `security-and-hardening`   | addyosmani/agent-skills                                               | `feat-design-reviewer` lens 4a, `feat-code-reviewer` lens 7b |
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

Once per project that will use `/feat`, with the Claude integration:

```sh
cd ~/your-project
specify init --here --integration claude
```

This adds `.specify/` and the `speckit-*` skills in `.claude/skills/`
(`/brief` doesn't need them). The workflow uses `speckit-specify`, `speckit-clarify`, `speckit-plan`,
`speckit-tasks`, `speckit-analyze` and `speckit-implement`. Writing a
constitution (`/speckit-constitution`) is optional but makes phase 3's
constitution check meaningful.

## 4. Check

```sh
~/Projects/feat-agent/install.sh check ~/your-project
```

It needs a clone of this repo, and works whichever way you installed. Every
line should say `ok`; each `MISSING` line names the command that fixes it.
Exit code 0 means ready.

## Updating

- APM: `apm update -g`. Plugin: `/plugin update feat-agent`. Clone:
  `git pull` (with `--copy`, rerun `./install.sh --copy`).
- Third-party skills installed with the skills CLI: `npx skills update -g`.
- Spec Kit: upgrade the CLI, then rerun `specify init --here --integration
  claude --force` in each project to refresh its templates and skills.

## Uninstalling

APM: `apm uninstall -g pdemagny/feat-agent`. Plugin: `/plugin uninstall
feat-agent`. Clone:

```sh
./install.sh uninstall               # or --target <dir>
```

Removes only the links that point into this repo. Copies and backups are
listed and left for you to remove. Third-party skills stay: `npx skills
remove <name> --global` if you no longer want them.
