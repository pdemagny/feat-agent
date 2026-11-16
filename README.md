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

```mermaid
flowchart TD
    idea([Feature idea]) --> P1["1 Brief<br/>brief skill · interview-me"]
    P1 -- huge --> MAP["Capability map<br/>brief skill"]
    MAP --> GM{{"Gate: map"}}
    GM -- "one brief per capability" --> P1
    P1 -- "small · medium · large" --> R1["Brief review<br/>feat-brief-reviewer<br/>fresh reader"]
    R1 --> G1{{"Gate: brief, size and review"}}
    G1 --> CLR["clear context, then run feat on the brief"]
    CLR --> P2["2 Specify<br/>feat-specifier"]
    P2 --> G2{{"Gate: spec.md"}}
    G2 --> P3["3 Plan<br/>feat-planner"]
    P3 --> P4["4 Design review<br/>feat-design-reviewer<br/>security · cost · clarity and fit<br/>1 reviewer on small, 3 otherwise"]
    P4 --> G4{{"Gate: design findings"}}
    G4 --> P5["5 Tasks + analyze<br/>feat-tasker"]
    P5 --> P6["6 Implement<br/>feat-implementer<br/>one per user story, in turn"]
    P6 --> P7["7 Code review<br/>feat-code-reviewer<br/>2 reviewers on small, 5 otherwise"]
    P7 --> G7{{"Gate: pick the fixes"}}
    G7 --> P7f["Apply picks<br/>feat-implementer · fix mode"]
    P7f --> P8["8 Ship<br/>feat-shipper · haiku"]
    P8 --> PR([Pull request])

    classDef you fill:#e8f0fe,stroke:#4a6fd1,color:#1a2b5c
    classDef agent fill:#eef7ee,stroke:#4a9a4a,color:#1d3d1d
    classDef gate fill:#fff4e0,stroke:#d18b2a,color:#5c3a0a
    class P1,MAP,CLR you
    class P2,P3,P4,P5,P6,P7,P7f,P8 agent
    class G1,GM,G2,G4,G7 gate
```

Blue runs in your session, green in a subagent, orange hexagons are gates
where the run waits for you. On a small or medium feature the design gate
(phases 3 and 4 together) only waits when a finding needs your call; a
large feature also stops after phases 3 and 5 and after each story of 6.
Several reviewers on one phase run in parallel.

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

Version 0.9.0. Tested with Claude Code 2.1.308 and Spec Kit (specify-cli) <!-- x-release-please-version -->
1.2.x. See [CHANGELOG.md](https://github.com/pdemagny/feat-agent/blob/main/CHANGELOG.md).

## License

MIT, see [LICENSE](https://github.com/pdemagny/feat-agent/blob/main/LICENSE). Some review checklists and prompts are adapted
from addyosmani/agent-skills, mattpocock/skills, dietrichgebert/ponytail
(MIT) and google/elephant-goldfish-model (Apache-2.0), and the `.specify/`
files come from Spec Kit (MIT). Credits and license texts are in
[THIRD_PARTY_NOTICES.md](https://github.com/pdemagny/feat-agent/blob/main/THIRD_PARTY_NOTICES.md). The third-party skills
that get installed keep their own licenses.
