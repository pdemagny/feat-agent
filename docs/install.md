---
title: Install
weight: 10
---

# Installing logistics

Claude Code only. Three ways to install; the design behind them:
[design.md](design.md#distribution-one-source-three-installers).

## Prerequisites

| Tool                            | Why                                                                                   | Install                                         |
| ------------------------------- | ------------------------------------------------------------------------------------- | ----------------------------------------------- |
| Claude Code (tested on 2.1.308) | runs `/feat` and its agents; older versions may ignore subagent `effort` or `skills`  | <https://code.claude.com/docs/en/setup>         |
| git ≥ 2.44                      | branches, worktrees, diffs; moves runs with `rebase`, phase 8 renumbers with `rebase --autosquash` | your package manager                            |
| GitHub CLI `gh`, logged in      | phase 8 pushes and opens the PR; `rebase` lists your conflicting PRs and pushes with `--force-with-lease`; board tracking needs the `project` scope ([section 5](#5-board-tracking-optional)) | <https://cli.github.com>, then `gh auth login`  |
| Spec Kit CLI `specify`          | phases 2–6 are Spec Kit skills                                                        | `uv tool install specify-cli`                   |
| Spec Kit bug extension, `/fix` only (tested with bug 1.0.1 and 1.0.2) | `/fix`'s assess, fix and test phases are its skills       | `specify extension add bug` in each project     |
| APM (`apm`) or Node.js (`npx`)  | APM installs everything; `npx` installs the third-party skills for the other two ways | `uv tool install apm-cli`; <https://nodejs.org> |

`uv tool install` puts commands in `~/.local/bin`; if `apm` or `specify`
isn't found afterwards, run `uv tool update-shell` and open a new shell.

In a clone of this repo, `mise install` installs all of these except git
and the bug extension (plus the linters) at the versions the release was
tested with; see [`mise.toml`](https://github.com/pdemagny/logistics/blob/main/mise.toml).

The workflow uses Opus and Sonnet, and Haiku to ship. Your plan must give
access to them; if one isn't available, change the size table (see [usage.md](usage.md#tuning)).

## 1. Install the skills and agents

Pick one of three ways. Use only one: two would load the workflow twice.

### With APM (recommended: dependencies included)

[APM](https://microsoft.github.io/apm/) (Microsoft's Agent Package Manager)
installs the 3 skills, the 9 agents and the 3 third-party skills they use,
in one command:

```sh
uv tool install apm-cli          # or: pipx install apm-cli
apm install -g pdemagny/logistics -t claude
```

`-g` installs for your user (all projects) into `~/.claude/`. Without it,
inside a project, it installs there only and adds `apm.yml`,
`apm.lock.yaml` and `apm_modules/` to the project.

This installs the latest `main`. To stay on a release instead, name its tag
([releases](https://github.com/pdemagny/logistics/releases)); running it
again with another tag, or none, moves you:

<!-- x-release-please-start-version -->
```sh
apm install -g pdemagny/logistics#v0.12.0 -t claude
```
<!-- x-release-please-end -->

### As a Claude Code plugin

In Claude Code:

```
/plugin install logistics --marketplace pdemagny/logistics
```

or from a shell, `claude plugin install logistics --marketplace
pdemagny/logistics`. On Claude Code before 2.1.275, use two commands:

```sh
claude plugin marketplace add pdemagny/logistics
claude plugin install logistics@logistics
```

Plugins name everything after the plugin: the commands become
`/logistics:feat`, `/logistics:brief` and `/logistics:fix`, the agents
`logistics:feat-planner` and so on. The skills handle both names. A plugin
can't install the third-party skills, so add them with the [skills
CLI](https://github.com/vercel-labs/skills):

```sh
npx -y skills@1.7.6 add https://github.com/addyosmani/agent-skills/tree/0.6.13/skills -s interview-me security-and-hardening performance-optimization -a claude-code -g -y
```

Update with `/plugin update logistics`.

### From a clone (to work on the workflow)

```sh
git clone https://github.com/pdemagny/logistics
cd logistics
./install.sh             # symlinks into ~/.claude, so edits apply at once
./install.sh deps        # the three third-party skills (skills CLI)
```

`--copy` copies instead of linking; `--target ~/proj/.claude` installs for
one project (pass it again to `check`, `uninstall` and any rerun). Anything already at a destination that isn't a link into this
repo (for example an older hand-written `feat` skill) is moved to
`~/.claude/logistics-backups/<name>.<timestamp>` first, never deleted.
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

In a directory that already has files it asks to confirm (`y`). This adds
`.specify/` and the `speckit-*` skills in `.claude/skills/`
(`/brief` doesn't need them). The workflow uses `speckit-specify`, `speckit-clarify`, `speckit-plan`,
`speckit-tasks`, `speckit-analyze` and `speckit-implement`. Writing a
constitution (`/speckit-constitution`) is optional but makes phase 3's
constitution check meaningful.

For `/fix`, also add Spec Kit's bundled bug extension (no network needed):

```sh
specify extension add bug
```

It adds `speckit-bug-assess`, `speckit-bug-fix` and `speckit-bug-test`;
`/fix` stops at setup and names this command when they are missing.
`/brief` and `/feat` don't need it.

## 4. Check

```sh
git clone https://github.com/pdemagny/logistics
./logistics/install.sh check ~/your-project
```

It only reads, and works whichever way you installed. Each `MISSING` line
says how to fix it; without a project dir, the Spec Kit lines say
`skipped`. Exit code 0 means ready.

With a project dir it also lists the bug extension's skills. They are
needed by `/fix` only, so neither of these lines changes the exit code:
- `note skill <name> (needed by /fix only: specify extension add bug)`:
  the skill is not installed;
- `warn <name> differs from the names /fix was tested with (bug 1.0.1 and 1.0.2)`:
  an installed skill lacks a section heading or verdict word `/fix`
  relies on, usually a newer extension. `/fix` may still work; its assessor
  reports a missing section as an error.

## 5. Board tracking (optional)

`/brief` and `/feat` can move a brief's issue across a GitHub Projects
board: Brief when the brief is written, In progress while it is built, In
review from the code review on (`/fix` moves a bug's issue the same way:
[workflow.md](workflow.md#board-moments)). Which moment sets which status:
[workflow.md](workflow.md#board-tracking). It is off unless the repo has a
`.logistics.yml` at its root:

```yaml
tracker:
  provider: github            # only value accepted
  project: https://github.com/users/<login>/projects/<number>   # or /orgs/<org>/...
  statuses:                   # option names of the board's Status field, exact case
    brief: Brief
    building: In progress
    review: In review
```

Exactly this shape: comments and quoted values are fine, other keys or
indents are refused. Commit and push it: `/feat` builds in a worktree
branched from `origin/<default>`, which only sees what is pushed (without it
the run says so and skips its moves).

Then give `gh` (tested on 2.103.3) the `project` scope:

```sh
gh auth refresh -s project
```

That scope is broad: it grants read and write on every Projects board your
account can reach, not just this one. Without the file, nothing calls `gh`
for a board and the scope isn't needed.

On the board, in its workflows:
- **Enable "Item closed"** (sets Done). Merging the PR closes the issue and
  this moves the card. Without it, cards stop at In review and you move
  them to Done by hand.
- **Check what "Pull request linked to issue" sets.** It fires when phase 8
  opens the PR (`Closes #N`) and could move the card back from In review;
  turn it off or point it at In review. It also fires when a release PR
  built from commits (release-please) copies a `Closes #N` footer, and
  moves the closed card from Done back to In review: the shipper keeps
  closing keywords in the PR body for that reason, so keep them out of
  the commits you write by hand too.

**A `bug` label in the repo.** The issues `/fix` creates are labelled
`bug` (one of GitHub's default labels). If the repo has no such label, the
issue is created without it and the run says so; create the label (`gh
label create bug`) to keep bug issues labelled.

**Repos you didn't write.** A repo's `.logistics.yml` and a brief's
`Issue:` line decide where the writes go: they can point at any board your
account can edit and add any issue you can read to it. Each run starts by
printing the board it will write to (`tracker: ok users/<login>/projects/<n>
...`); on a repo you didn't write, check that line before going on.

## Updating

- APM: `apm update -g`. Plugin: `/plugin update logistics`. Clone:
  `git pull` (with `--copy`, rerun `./install.sh --copy`; each rerun moves
  the previous copies to the backups dir).
- Third-party skills installed with the skills CLI: `npx skills update -g`.
- Spec Kit: upgrade the CLI, then rerun `specify init --here --integration
  claude --force` in each project to refresh its templates and skills.

## Uninstalling

APM: `apm uninstall -g pdemagny/logistics`. Plugin: `/plugin uninstall
logistics`. Clone:

```sh
./install.sh uninstall               # or --target <dir>
```

Removes only the links that point into this repo. Copies are listed as
`kept` for you to remove; backups in `~/.claude/logistics-backups/` are
left as they are. Third-party skills stay: `npx skills
remove <name> --global` if you no longer want them.
