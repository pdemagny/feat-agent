# Implementation Plan: Report files and a state script

**Branch**: `report-files-state` | **Date**: 2026-11-20 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `specs/012-report-files-state/spec.md` (issue #27)

## Summary

A new bash script, `.apm/skills/feat/scripts/state.sh`, becomes the only
writer of the state file (`init`, `set`, `log`) and answers, as fixed
one-line queries, the six rules the coordinator and the shipper apply
today by reading the Log in prose (`cycle`, `retry-used`,
`shipped-verdict`, `phase2-mode`, `refused-base`, `find`, `review-summary`,
`restore-phase`). Both skills, the harness, `rebase.md` and the shipper are
rewritten onto it: each hand Edit becomes one `set` or `log` call, and
each query rides on a call already made at that boundary (story 1, P1).
Then every `/feat` and `/fix` spawn gets a report path from `state.sh
report-path`; the agent writes its full report there and hands back a
digest that drops only the lines no reader uses; the code and design
reviewers get `Write` back, checked by `snapshot`/`unchanged` around each
batch of reviewers; `reports/` ignores itself and is never committed
(story 2, P2). Offline tests under `tests/state/`, a lint grep for the old
wording, docs and CI complete it.

## Technical Context

**Language/Version**: bash 3.2 or later (macOS's `/bin/bash` included): `state.sh` is on every run's path and needs nothing bash 4 adds, so it uses only bash 3.2 constructs: no `declare -A`, `mapfile`/`readarray`, `${v,,}`/`${v^^}`, `declare -n`/`local -n`, `[[ -v ]]`, negative subscripts, `;;&`, `|&`, and no `"${a[@]}"` of a possibly empty array under `set -u` (use `${a[@]+"${a[@]}"}`). `tests/state/run.sh` has a case that greps `state.sh` for those constructs (CI has no bash 3.2). `tracker.sh` and `secret-scan.sh` stay bash 4 (not this feature). Markdown prompts

**Primary Dependencies**: none new; `git` and `gh` (already required by the skills); `shellcheck` 0.11.0 pinned in `mise.toml`

**Storage**: files: the state file, `<artifact dir>/reports/*.md`, `reports/.gitignore`

**Testing**: `tests/state/run.sh` (fixtures, golden outputs, scratch repos and worktrees, stub `gh`), new `mise run test:state` and CI step; `mise run lint` (shellcheck, old-wording grep); `mise run test:apm`; [quickstart.md](quickstart.md)

**Target Platform**: the machines running `/feat` and `/fix` in Claude Code (Linux, macOS); the `check` workflow (ubuntu-latest)

**Project Type**: prompt package (skills + subagents) with helper scripts

**Performance Goals**: no growth in coordinator calls (SC-006: median ≤ 62 `/feat`, ≤ 45 `/fix`); `snapshot` hashes only changed and untracked files (research R1); `find` calls `gh` only for runs past the done marker

**Constraints**: commands the coordinator runs stay plain (no `$(…)`, heredoc or `>`; every `state.sh` argument single-quoted, `'` as `'\''`, report or user text never outside quotes nor in a `<token>`/`<key>` position); no Log line format changes beyond FR-009's three (phase 2 `    - ` sub-lines, no open `- [ ]` lines, the review-fixes line quoting `Fixes (fix mode):`), old forms still read; `state.sh` never writes through a symlink; the harness and `rebase.md` hold no `/feat`-only words (lint); report formats keep their shape and order; `/tiny` and `/brief` unchanged; old state files keep working

**Scale/Scope**: 1 new script (~500 lines) and its test dir; 8 agent files; 2 skills, `harness.md`, `rebase.md`; `mise.toml`, CI, 4 docs; ~55 tasks

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Check | Result |
| --------- | ----- | ------ |
| I. Thin coordinators | the coordinator stops editing the state file and stops parsing the Log; it runs a script, like `tracker.sh` and `story.sh`, and reads one-line answers; it never reads a report file | pass |
| II. The user decides at gates | gates and their conditions are unchanged; a reviewer that changes the worktree is a failed report check, already a hard gate | pass |
| III. One source of truth | rules written twice today (the shipped verdict in `/fix` and the shipper) or in both skills (resume search, done marker) live once, in `state.sh`; the header shape lives in `state.sh` and the harness template, and `tests/state` fails when they differ (research R7) | pass |
| IV. Fixed report formats | formats keep their lines and order; the digest and the reviewers' `Wrote:` change in the same commit as the skill rules that read them | pass |
| V. Small and plain | one bash script with offline tests, shellcheck clean; the skills lose more prose (the Log rules) than they gain (the call lines); agent files gain a three-line rule | pass |

Distribution: `state.sh` sits in `.apm/skills/feat/scripts/`, shipped
whole by APM, the plugin (`./.apm/skills/`) and `install.sh`;
`test:apm` gains a check. No agent added or removed, so
`.claude-plugin/plugin.json` doesn't change.

Post-design re-check: pass. Permissions change: `feat-code-reviewer` and
`feat-design-reviewer` regain `Write` (in the brief), bounded by the rule
and the `snapshot`/`unchanged` check. No service, exposure or dependency.

## Project Structure

### Documentation (this feature)

```text
specs/012-report-files-state/
├── plan.md                        # this file
├── research.md                    # decisions R1–R14
├── data-model.md                  # state file, Log lines each query reads, report file, snapshot
├── quickstart.md                  # validation steps
├── contracts/
│   ├── state-cli.md               # every subcommand: arguments, output, exit, errors
│   ├── digests.md                 # the agents' report-path rule, digest table, reviewers, keys
│   └── coordinator-calls.md       # where each call goes in the skills, harness, rebase.md, shipper; the lint grep
└── tasks.md                       # phase 5
```

### Source code (repository root)

New:

```text
.apm/skills/feat/scripts/state.sh
tests/state/run.sh
tests/state/bin/gh                 # stub: answers from a case dir, logs argv
tests/state/fixtures/              # frozen real state files + synthetic ones, test.md
tests/state/expected/              # golden outputs (review-summary, init)
```

Changed:

```text
.apm/skills/feat/references/harness.md   # State file, Report files, Reported files, Base check, At ship, Resume
.apm/skills/feat/references/rebase.md    # find rebase, set/log, report paths, State script to the shipper
.apm/skills/feat/SKILL.md                # harness values, phase 2/7/8 calls, resume, prose rules out
.apm/skills/fix/SKILL.md                 # harness values, setup 7, phases 1/3/5 calls, resume, prose rules out
.apm/agents/feat-shipper.agent.md        # State script input, review-summary, shipped-verdict, restore-phase, reports/ never staged, report path
.apm/agents/feat-code-reviewer.agent.md  # Write back, report-path rule, digest drops Dismissed:
.apm/agents/feat-design-reviewer.agent.md# Write back, report-path rule, digest drops Checked and fine:
.apm/agents/feat-implementer.agent.md    # report-path rule, digest drops notable files
.apm/agents/feat-tasker.agent.md         # report-path rule, digest drops Fixed:
.apm/agents/feat-specifier.agent.md      # report-path rule
.apm/agents/feat-planner.agent.md        # report-path rule
.apm/agents/feat-bug-assessor.agent.md   # report-path rule
mise.toml                                # lint: shellcheck tests/state, old-wording grep; test:state; test:apm checks state.sh
.github/workflows/check.yml              # mise run test:state
docs/workflow.md                         # state file, report files, reviewers, Wrote:
docs/design.md                           # "Read-only reviewers" line
CONTRIBUTING.md                          # scripts and tests lines
.claude/CLAUDE.md                        # test:state in the shell bullet
```

Unchanged on purpose: `.apm/skills/tiny/SKILL.md`, `.apm/skills/brief/SKILL.md`,
`.apm/agents/feat-brief-reviewer.agent.md`, `.claude-plugin/plugin.json`,
`sizes.json` and every generated table, `docs/diagrams/*` (no phase or
gate changes), `measure.py`.

**Structure Decision**: one script next to `tracker.sh` and `story.sh`,
tested like `tests/story/` (fixtures, golden files, stderr empty) and
`tests/spec-number/` (scratch origin and clone, stub `gh` on `PATH`).

## How

### Story 1 (P1): `state.sh` and the swap

1. **Script skeleton**: header comment with the synopsis (like
   `story.sh`), `die`/`usage`, argument and newline checks, the state-file
   reader (title, header, Log split per research R6), the atomic writer
   (refuses a state file that is a symlink, `[ -L ]` checked before the
   temp file + `mv -f`, as `tracker.sh`'s `create-issue` refuses a leaf
   symlink), bash 3.2 constructs only (Technical Context).
2. **Writes**: `init` (both forms, research R8), `set`, `log`,
   `restore-phase`, per [contracts/state-cli.md](contracts/state-cli.md).
3. **Queries**: `cycle`, `retry-used`, `shipped-verdict`, `phase2-mode`,
   `refused-base`, `review-summary` (a small quote- and paren-aware splitter
   for the outcome line, data-model.md grammar), `find feat|fix`, `find
   rebase`.
4. **Tests** for each, as they land (quickstart step 1), including: a
   `log` case whose argument holds `'`, `$(…)`, a backtick and `;`,
   passed single-quoted (`'\''`), appended byte for byte; `init`, `set`,
   `log` and `restore-phase` on a state file that is a symlink (dangling
   for `init`), each refused with `<path> is a symlink` and the target
   untouched; `review-summary` with no outcome line printing `Code review
   was skipped.`; the bash 3.2 constructs grep. `mise.toml`
   `test:state`, shellcheck line, `test:apm` check; CI step.
5. **Swap the text** per [contracts/coordinator-calls.md](contracts/coordinator-calls.md):
   harness (State file section, Base check, At ship, Resume, the thin
   orchestrator bullets), `/feat`, `/fix`, `rebase.md`, the shipper
   (`review-summary`, `shipped-verdict`, `restore-phase`, `State script:`
   input). Remove *Resume search*, *Done marker*, *Rebase search* and the
   two moved commands from both skills' Harness values; add *State
   script*. Pin the review-fixes Log line to the implementer's `Fixes`
   value (research R11). Phase 2's sub-lines get `    - `. The harness
   State file section says every `state.sh` argument is single-quoted
   (contracts/coordinator-calls.md, Harness); `/fix`'s input section is
   the argument with its lines joined by spaces (research R8). The
   resume text says when the coordinator reads the state file (once,
   after the resume call).
6. **Lint**: the old-wording line (coordinator-calls.md, Lint).

Story 1 is complete on its own: no report path yet, every agent reports in
full as today, and `report-path`/`snapshot`/`unchanged` exist but are not
called. The run can stop here.

### Story 2 (P2): report files and digests

7. **Script**: `report-path`, `snapshot`, `unchanged` (research R1, R3)
   and their tests: `report-path` refusing a symlinked `reports/`, a
   symlink at the path it would print and at a `-<n>` candidate;
   `unchanged` printing the bounded path list on `changed` only.
8. **Agents** per [contracts/digests.md](contracts/digests.md): the rule in
   eight agent files, the four digests, `Write` back for the two
   reviewers, the shipper's numbered report path and `reports/` staging.
9. **Coordinator text** (same commit as step 8, principle IV): harness
   Report files and Reported files additions, *Report keys* in both
   skills, every spawn's `report-path` chained per coordinator-calls.md,
   `/feat` phase 2's `init` moved before the specifier (research R4), the
   snapshot/unchanged calls around phases 4 and 7 (`/feat`) and 4
   (`/fix`), "list what they dismissed, in their report file". The
   Reported files check accepts a report path under a dir the shipper
   renumbered (contracts/digests.md, The coordinator side), worded once
   in the harness and once in the shipper.
10. **Docs**: `docs/workflow.md`, `docs/design.md`, `CONTRIBUTING.md`,
    `.claude/CLAUDE.md`.
11. **#28 comment** (FR-021): check `gh issue view 28 --comments`; when no
    comment says it yet, write the text below with Write to a file
    outside the tree and post it with `gh issue comment 28 --body-file
    '<that file>'`. A failed `gh` call (either one) goes under `Not
    verified:` as `n/a → #28 comment → <first line of gh's error>` and
    doesn't block the PR. The exact text:

    ```markdown
    From #27 (report files and a state script), which lands first:

    - Every `/feat` and `/fix` agent now writes its full report to `<artifact dir>/reports/<key>.md` and hands back a digest that drops only the lines no gate reads. Shrinking the hand-back to a few lines is left to this issue: once `step.sh` reads the report file, the hand-back becomes `step.sh`'s output.
    - #21's gate tags on Log lines also land here: `state.sh log` checks only the line prefixes, and `step.sh` writes most gate lines.
    ```

### Commits (for the shipper, default conventions)

`docs(specs)` for this dir; `feat(state)` for story 1 (script, tests,
skills, harness, rebase.md, shipper, lint, CI); `feat(agents)` for story 2
(script additions, agents and the skill text that reads them, docs).

## Risks

- **False `changed`** when a reviewer's build or test run leaves an
  untracked, non-ignored file, or rewrites a tracked file (a golden or
  snapshot file, a lockfile) (research R1): a hard gate; `unchanged`
  names the differing paths (up to 10, then a count), the gate shows
  them, and the user clears it from that list; build outputs are
  normally ignored.
- **Snapshot manifests** left under the git dir
  (`<git dir>/logistics/snapshots/`) when a run stops between
  `snapshot` and `unchanged`: a few small files, removed with the
  worktree (a linked worktree's git dir goes with it).
- **`review-summary` on free-form review-fixes lines** of older runs finds
  no reverted fix (research R11); only a run shipped or rebased across the
  upgrade is affected.
- **Prompt drift**: the coordinator might still Edit out of habit; the
  harness says "never with Edit or Write" and SC-006 measures it.

## Complexity Tracking

No constitution violation to justify.
