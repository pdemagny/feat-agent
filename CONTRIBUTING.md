# Contributing

Thanks for your interest. feat-agent is a personal project: issues are
welcome, and pull requests too once we've agreed on the change in an issue.

## Issues

- **Bug**: use the Bug template. Include the skill or agent, what it did,
  the smallest brief or run that shows it, and your versions (feat-agent,
  Claude Code, Spec Kit).
- **Idea or feature**: use the Feature template. Say what problem it solves
  before how.
- **Security**: never in an issue; see [SECURITY.md](SECURITY.md).

What's planned is on the [roadmap](https://github.com/users/pdemagny/projects/2).

## Working on it

You need Claude Code, [mise](https://mise.jdx.dev) and the
[prerequisites](docs/install.md#prerequisites).

```sh
git clone https://github.com/pdemagny/feat-agent
cd feat-agent
mise install            # the pinned tools
mise run dev:install    # symlink the skills and agents into ~/.claude, add the third-party skills
```

Edits apply in the next Claude Code session. `mise run dev:uninstall`
removes the links. `mise tasks` lists the rest.

Where things are:

```
.apm/skills/feat/             the orchestrator: phases, gates, size table (source of truth)
.apm/skills/feat/scripts/     tracker.sh (board moves), spec-number.sh (numbers the spec dir)
.apm/skills/feat/references/  harness.md: the rules /feat and /fix share (gates, state file, board, resume)
.apm/skills/fix/              the bugfix orchestrator: assess, fix, test, review, ship; its own size table
.apm/skills/brief/            phase 1: interview, size, brief or capability map
.apm/agents/*.agent.md        one subagent per phase role
apm.yml                       APM package: metadata and the third-party skill dependencies
.claude-plugin/               Claude Code plugin and marketplace manifests
install.sh                    developer install (symlinks), deps, check, uninstall
tests/                        offline tests for the two scripts (stub gh, fake GraphQL endpoint)
specs/, .specify/bugs/        records of the /feat and /fix runs that built this repo
mise.toml                     pinned tools and tasks (lint, check, test:*, docs, dev:*)
docs/                         the user documentation, published with README.md as the website
hugo.toml, go.mod             the website's Hugo config and theme (`mise run docs:serve` previews it)
```

The rules for changing the skills and agents are in
[`.claude/CLAUDE.md`](.claude/CLAUDE.md), which Claude Code loads when you
work in this repo. The ones that bite most:

- The size tables in `.apm/skills/feat/SKILL.md` and
  `.apm/skills/fix/SKILL.md` are the source of truth for models and
  efforts; mirror any change in [docs/workflow.md](docs/workflow.md).
- Every agent prompt ends with a fixed report format that `/feat` or `/fix`
  parses: change both sides together.
- `/feat` and `/fix` only coordinate. New work goes into an agent, not the
  coordinator.

## Before you open a pull request

- `mise run lint`, `mise run test:apm`, `mise run test:tracker` and
  `mise run test:spec-number` pass. The `check` workflow runs the same on
  every pull request.
- For a change to a skill or agent prompt, run it on a scratch project and
  say in the PR what you ran and what happened. There is no automated test
  for prompts.
- Commits follow [Conventional Commits](https://www.conventionalcommits.org)
  (`type(scope): short message`), one logical change per commit.
  [CHANGELOG.md](CHANGELOG.md) is generated from them: `feat` and `fix`
  subjects become its entries, so write those for users. A `!` after the
  type (`feat!:`) marks a breaking change.
- The PR says `Closes #N` for its issue.

By contributing, you agree that your contribution is licensed under the
[MIT License](LICENSE).

## Releases

[release-please](https://github.com/googleapis/release-please) keeps a
release pull request open with the next version and its CHANGELOG section,
from the commits merged since the last release. Merging it (maintainer
only) bumps the versions, tags the release and publishes it on GitHub.
