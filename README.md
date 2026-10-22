# feat-agents

A Claude Code workflow that takes a feature idea to a reviewed pull request,
in two commands: `/feat-brief "let users edit a stack's config"` interviews
you and writes a brief; `/clear`, then `/feat specs/briefs/<name>.md`
specifies, plans, reviews, breaks down, implements and code-reviews it with
[Spec Kit](https://github.com/github/spec-kit), then commits, pushes and
opens a PR on its own branch. You approve the decisions that shape the
feature at a few gates; everything else runs on its own.

`/feat` only coordinates: every phase runs in a dedicated `feat-*` subagent
whose model and effort follow the feature's size (Sonnet at medium effort
for most of a small feature, Opus at higher effort where a large one needs
it). Keeping the coordinator's context small is what keeps the token count
down on a plan with a usage limit. A huge idea is split into a capability
map, one brief and PR per capability.

```mermaid
flowchart TD
    idea([Feature idea]) --> P1["1 Brief<br/>feat-brief skill · interview-me"]
    P1 --> G1{{"Gate: brief and size"}}
    G1 -- huge --> MAP["Capability map<br/>feat-brief skill"]
    MAP --> GM{{"Gate: map"}}
    GM -- "one brief per capability" --> P1
    G1 -- "small · medium · large" --> CLR["clear context, then run feat on the brief"]
    CLR --> P2["2 Specify<br/>feat-specifier"]
    P2 --> G2{{"Gate: spec.md"}}
    G2 --> P3["3 Plan<br/>feat-planner"]
    P3 --> P4a["4a Security design<br/>feat-sec-reviewer"]
    P3 --> P4b["4b Cost design<br/>feat-cost-reviewer"]
    P4a --> G4{{"Gate: design findings"}}
    P4b --> G4
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
    class P2,P3,P4a,P4b,P5,P6,P7,P7f,P8 agent
    class G1,GM,G2,G4,G7 gate
```

Blue runs in your session, green in a subagent, orange hexagons are hard
gates. Branches out of one box run in parallel. The phase 4 gate is soft for
a small feature without real findings. Phases 3, 5 and each story of 6 also
stop for a large feature. Phase 7's lenses: correctness/spec/standards,
security, performance, over-engineering, readability. Full matrix in
[docs/workflow.md](docs/workflow.md).

## Quick start

```sh
uv tool install apm-cli
apm install -g pdemagny/feat-agents -t claude   # skills, agents and their dependencies
cd ~/your-project
specify init --here --integration claude       # once per project, if not already
claude
> /feat-brief "describe the feature in one line"
> /clear
> /feat specs/briefs/<name>.md
```

Or, in Claude Code only, as a plugin (commands become `/feat-agents:feat`
and `/feat-agents:feat-brief`):

```
/plugin install feat-agents --marketplace pdemagny/feat-agents
```

then add the third-party skills with `npx skills add`.

**Claude Code only, for the build.** `/feat` relies on Claude Code's
subagents with a model and effort per call, so it runs nowhere else. APM
can also install for Codex, OpenCode and the harnesses that read
`~/.agents/skills`; there you get `/feat-brief` and the agents on their
own, not the build. What works where:
[docs/install.md](docs/install.md#what-works-where). All three install ways, and checking an
install: [docs/install.md](docs/install.md).

## Documentation

| Doc | What's in it |
|---|---|
| [docs/install.md](docs/install.md) | Prerequisites, every dependency and where it comes from, install options, uninstall |
| [docs/usage.md](docs/usage.md) | Brief, build, answering gates, resuming, changing size, tuning models and effort |
| [docs/workflow.md](docs/workflow.md) | Every phase, gate and agent: the size × phase matrix, what runs when and how |
| [docs/design.md](docs/design.md) | Why it is built this way: Claude Code mechanics, rejected alternatives |
| the cost notes (since moved out) | Measuring a run's tokens and cost with a cost script (since moved out); the baseline to compare against |

## Layout

```
.apm/skills/feat/        the orchestrator: phases, gates, size table (source of truth)
.apm/skills/feat-brief/  phase 1: interview, size, brief or capability map
.apm/agents/*.agent.md   one subagent per phase role, harness-neutral frontmatter
apm.yml                  APM package: metadata and the third-party skill dependencies
.claude-plugin/          Claude Code plugin and marketplace manifests
install.sh               developer install (symlinks), deps, check, uninstall
a cost script (since moved out)            tokens and $ of a run, per phase and model, from transcripts
mise.toml                pinned tools and tasks (lint, check, test:apm, cost, release, pin)
docs/                    the documentation above
```

## Status

Version 0.2.0. Tested with Claude Code 2.1.308 and Spec Kit (specify-cli)
1.2.x. See [CHANGELOG.md](CHANGELOG.md).

## License

MIT, see [LICENSE](LICENSE). The capability-map rules in `.apm/skills/feat-brief`
are adapted from addyosmani/agent-skills (MIT), and three checklists in
`.apm/agents/feat-code-reviewer.agent.md` from MIT skills: standards and spec review
from mattpocock/skills' `code-review` (Matt Pocock), over-engineering from
dietrichgebert/ponytail's pre-v5 `ponytail-review` (Dietrich Gebert),
readability from addyosmani/agent-skills' `code-simplification` (Addy
Osmani, itself inspired by Anthropic's code-simplifier plugin). Third-party skills installed
by `install.sh deps` keep their own licenses.
