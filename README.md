# feat-agent

[![Release](https://img.shields.io/github/v/release/pdemagny/feat-agent)](https://github.com/pdemagny/feat-agent/releases/latest)
[![check](https://github.com/pdemagny/feat-agent/actions/workflows/check.yml/badge.svg)](https://github.com/pdemagny/feat-agent/actions/workflows/check.yml)
[![docs](https://github.com/pdemagny/feat-agent/actions/workflows/docs.yml/badge.svg)](https://pdemagny.github.io/feat-agent/)
[![License: MIT](https://img.shields.io/github/license/pdemagny/feat-agent)](https://github.com/pdemagny/feat-agent/blob/main/LICENSE)
[![Claude Code plugin](https://img.shields.io/badge/Claude_Code-plugin-D97757)](https://pdemagny.github.io/feat-agent/docs/install/)
[![Built on Spec Kit](https://img.shields.io/badge/built_on-Spec_Kit-6e40c9)](https://github.com/github/spec-kit)

### From idea to merge-ready PR on autopilot: an AI engineering team in your terminal, with spec-driven planning, right-sized models and smart gates that only stop you when it matters.

feat-agent is a set of Claude Code skills and subagents that take a feature
idea, or a bug report, to a reviewed pull request, using
[Spec Kit](https://github.com/github/spec-kit) for the spec, plan and tasks.

- **`/brief "<idea>"`** interviews you about a feature and writes a short
  brief.
- **`/feat <brief>`** specifies, plans, reviews the design, breaks it into
  tasks, implements, reviews the code, then commits, pushes and opens a PR
  on its own branch.
- **`/fix #N`** (or `/fix "<symptom>"`) assesses a bug, fixes it, has a
  different agent verify the fix, reviews it and opens a PR with
  `Fixes #N`.

You decide at a few gates (the brief, the spec when it leaves a question
open, which review findings to fix); everything else runs on its own, and nothing is ever merged for you.
Each phase runs in its own subagent on a model and effort sized to the job:
Sonnet at medium effort for most of a small feature, Opus at higher effort
where a large one needs it. The session you type in only coordinates, which
keeps token use down on a plan with a usage limit.

## Quick start

You need [Claude Code](https://code.claude.com/docs/en/setup), git, the
[GitHub CLI](https://cli.github.com) logged in (`gh auth login`) and
[uv](https://docs.astral.sh/uv/).

```sh
uv tool install apm-cli                         # the package manager that installs feat-agent
uv tool install specify-cli                     # Spec Kit
apm install -g pdemagny/feat-agent -t claude    # skills, agents and the skills they use

cd ~/your-project
specify init --here --integration claude        # once per project
specify extension add bug                       # once per project, for /fix
claude
```

Then, in Claude Code:

```
/brief "let users export a report as CSV"
/clear
/feat specs/briefs/<name>.md
```

`/clear` starts the build with a fresh context, so the interview isn't
carried into every later step. For a bug: `/fix #42` or `/fix "export
drops the last row"`.

Prefer a Claude Code plugin, or working from a clone? Both, and a command
that checks your setup, are in [docs/install.md](docs/install.md). Claude
Code only: the workflow needs its subagents with a model and effort per
call, and `EnterWorktree`.

## How it works

<p align="center"><img src="docs/img/gates.svg" alt="Sequence diagram of a small or medium feature: you, Claude Code and the agents. You always confirm the brief and pick the code review fixes. The run also stops when the spec has open questions, when the plan and design review need your call (you then check the spec too), and when the consistency check finds serious gaps." width="560"></p>

Agents do the work, each phase in a fresh one. Solid orange arrows are gates
where the run always waits for you; dashed ones wait only when something
needs your call. The spec stops only on an open question; otherwise you see
its summary at the plan and design review gate. A large feature also stops
after the plan, the design review, the tasks and each story.

<p align="center"><img src="docs/img/chain.svg" alt="From your idea to a pull request: brief, fresh reader, you confirm; spec, you answer its questions; plan; security, cost, and clarity and fit reviewed in parallel; you check the spec and decide on findings, then spec and plan are amended; tasks and a consistency check; code written one story at a time; correctness, security, performance and over-engineering reviewed in parallel, readability after over-engineering; you pick fixes; pull request. A huge idea first becomes a capability map, one brief per capability." width="480"></p>

Each artifact is checked before the next one is built from it. Shown for
medium and large features, with one reviewer per lens; a small feature runs
one design reviewer and two code reviewers covering the same lenses.

- **Design review** (phase 4) looks at security, cost, and clarity and fit:
  that last lens reads spec and plan as someone new to the project would,
  paraphrases them for you to check, and flags what is unclear, what the
  code contradicts and what already exists.
- **Code review** (phase 7) looks at correctness against the spec,
  security, performance, over-engineering and readability. You pick which
  findings get fixed.
- **A huge idea** is split into a capability map first: one brief, one run
  and one PR per capability.
- **`/fix`** runs the same way on Spec Kit's bug extension: assess, fix,
  test by a different agent, code review, ship.

Every phase, gate and model: [docs/workflow.md](docs/workflow.md).

## Documentation

Also on the website: [pdemagny.github.io/feat-agent](https://pdemagny.github.io/feat-agent/).

| Doc | What's in it |
|---|---|
| [docs/install.md](docs/install.md) | Prerequisites, the three ways to install, the setup check, board tracking, update, uninstall |
| [docs/usage.md](docs/usage.md) | Brief, build, fix a bug, answer gates, resume, change the size, tune models and effort |
| [docs/workflow.md](docs/workflow.md) | Every phase, gate and agent: the size × phase matrix, what runs when and how |
| [docs/design.md](docs/design.md) | Why it is built this way: Claude Code mechanics, rejected alternatives |
| [Roadmap](https://github.com/users/pdemagny/projects/2) | Known bugs and what is planned |
| [CONTRIBUTING.md](https://github.com/pdemagny/feat-agent/blob/main/CONTRIBUTING.md) | Reporting bugs, proposing changes, working on feat-agent |
| [SECURITY.md](https://github.com/pdemagny/feat-agent/blob/main/SECURITY.md) | Reporting a vulnerability privately |

## Status

Version 0.11.0. Tested with Claude Code 2.1.308 and Spec Kit (specify-cli) <!-- x-release-please-version -->
1.2.x. See [CHANGELOG.md](https://github.com/pdemagny/feat-agent/blob/main/CHANGELOG.md).

## License

MIT, see [LICENSE](https://github.com/pdemagny/feat-agent/blob/main/LICENSE). Some review checklists and prompts are adapted
from addyosmani/agent-skills, mattpocock/skills, dietrichgebert/ponytail
(MIT) and google/elephant-goldfish-model (Apache-2.0), and the `.specify/`
files come from Spec Kit (MIT). Credits and license texts are in
[THIRD_PARTY_NOTICES.md](https://github.com/pdemagny/feat-agent/blob/main/THIRD_PARTY_NOTICES.md). The third-party skills
that get installed keep their own licenses.
