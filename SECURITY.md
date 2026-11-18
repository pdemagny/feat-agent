# Security policy

logistics runs Claude Code agents that read your code, run commands, edit
files, commit, push and open pull requests. A flaw in its prompts or
scripts can make an agent do one of those things when it shouldn't, so
please report it privately.

## Reporting a vulnerability

Use GitHub's private vulnerability reporting: the repository's **Security**
tab, then **Report a vulnerability**. Please don't open a public issue,
pull request or discussion for it.

Include the version (`version` in `apm.yml`, or the release you
installed), how you installed it (APM, plugin or `install.sh`), the Claude
Code version, and the smallest brief, issue or bug report that shows the
problem.

This is a personal project maintained on a best-effort basis. You'll get
an answer as soon as I can, usually within a week, and credit in the
advisory and the CHANGELOG unless you'd rather not.

## Supported versions

Only the latest release gets fixes. Update before reporting
([docs/install.md](docs/install.md#updating)).

## In scope

- A brief, issue, bug report or repository content that gets an agent to
  run commands, write outside its worktree, commit or push without the gate
  the workflow promises (see [docs/workflow.md](docs/workflow.md)).
- Secrets or other sensitive data ending up in commits, pull request
  bodies, issues or `.specify/` trails, past the checks `/fix` and `/tiny`
  run.
- `install.sh` or the board tracker script (`.apm/skills/feat/scripts/`)
  touching files or calling services they shouldn't, or mishandling
  untrusted issue data.

## Out of scope

Report these upstream instead:

- Claude Code itself, its permission system and its sandbox:
  [anthropics/claude-code](https://github.com/anthropics/claude-code/security/policy).
- Spec Kit and its bug extension:
  [github/spec-kit](https://github.com/github/spec-kit/security/policy).
- The third-party skills logistics installs (see
  [docs/install.md](docs/install.md#2-the-third-party-skills)): their own
  repositories.
