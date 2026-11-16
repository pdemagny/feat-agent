# feat-agent Constitution

## Core Principles

### I. Thin coordinators
`/feat` and `/fix` only coordinate: they spawn the phase agents, hold the
gates and keep the state file. They never read code or edit artifacts. New
work goes into an agent (`.apm/agents/*.agent.md`), not into a coordinator.

### II. The user decides at gates
Nothing is merged, and nothing is called done, without the user. A phase
that needs a decision stops at a hard gate; a soft gate only reports. A
fix is called fixed only after an agent that did not write it has
verified it.

### III. One source of truth per fact
The size tables in `.apm/skills/feat/SKILL.md` and `.apm/skills/fix/SKILL.md`
set every agent's model, effort and loaded skills; agent frontmatter
carries no `model`, `effort`, `tools` or `color`. Rules both skills share
live once, in `.apm/skills/feat/references/harness.md`. Anything that
mirrors them (`docs/workflow.md`, `.apm/skills/brief/SKILL.md`) changes in
the same commit.

### IV. Fixed report formats
Every agent prompt ends with a fixed report format that the coordinators
parse. A change to a format changes both sides together.

### V. Small and plain
Prompts are prose, read by a model on every run: each added line has to
earn its tokens. Prefer a rule in an existing file to a new file, and a
shell one-liner to a script. Scripts are bash, `shellcheck`-clean, and
tested offline (`tests/`).

## Distribution

One source (`.apm/`), shipped three ways: an APM package (`apm.yml`), a
Claude Code plugin (`.claude-plugin/`, whose `agents` list names every
agent) and `install.sh` for development. A third-party skill is added or
removed in all of them at once (see `.claude/CLAUDE.md`).

## Development Workflow

- Conventional commits, one logical change per commit; `feat` and `fix`
  subjects become the CHANGELOG, so they are written for users.
- Every change reaches `main` through a PR. `mise run lint`,
  `mise run test:apm` and `mise run test:tracker` pass before committing.
- Releases are cut by release-please when its release PR is merged;
  versions and the CHANGELOG are never edited by hand.

## Governance

This constitution sums up `.claude/CLAUDE.md`, which holds the detailed
rules; when they disagree, `.claude/CLAUDE.md` wins and this file is
updated. A plan that breaks a principle says so in its constitution check,
with the reason, and stops at the design gate.

**Version**: 1.0.0 | **Ratified**: 2026-11-16 | **Last Amended**: 2026-11-16
