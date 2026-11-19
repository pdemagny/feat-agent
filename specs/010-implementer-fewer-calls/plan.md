# Implementation Plan: Cut the implementer's model calls per spawn

**Branch**: `implementer-fewer-calls` | **Date**: 2026-11-19 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `specs/010-implementer-fewer-calls/spec.md` (issue #55, part of epic #31)

## Summary

A new bash script, `.apm/skills/feat/scripts/story.sh`, parses tasks.md into
groups (setup/foundational, each `[US<n>]` story in heading order, polish)
and prints either every group's IDs and count (phase 5) or, compactly, one
story's task IDs with their checked state and the paths they name, the
unchecked count and the merged `files:` line, no task text (phase 6).
`/feat` runs it like `tracker.sh`, on the checked `Tasks:` path after `--`,
never reading tasks.md itself: at phase 5 it compares the groups with the
tasker's `Per story:` line (groups by label, ranges expanded) and goes
hard on any difference or a non-zero exit, and the size check takes its
total; at phase 6 every implementer spawn (first, retry, resume) gets its
story's fresh output in a four-backtick fence, as data.
`feat-implementer.agent.md` gains a short **One turn** paragraph:
independent tool calls in one turn; in story mode a first turn that reads
the existing `files:` together with `git status --short` and the Spec Kit
reads; in bug mode `git status --short`, the report and `assessment.md`
first, its listed files the turn after. Offline tests with two real
tasks.md fixtures, a `test:story` mise task run by CI, and the mirrors of
the phase 5 gate (docs, both diagrams re-rendered) complete it. No report
format, size table row, `/fix` file or `harness.md` line changes.

## Technical Context

**Language/Version**: bash 4+ (as `tracker.sh`), Markdown prompts (skill and agent files), D2 diagram sources

**Primary Dependencies**: none new; `shellcheck` 0.11.0 and `d2` 0.9.0, already pinned in `mise.toml`

**Storage**: N/A (reads tasks.md; `/feat` logs to the state file as today)

**Testing**: `tests/story/run.sh` (bash, modelled on `tests/secret-scan/run.sh`) run by a new `mise run test:story`; `mise run lint`, `mise run test:apm`, `mise run diagrams` with a clean `git diff --exit-code docs/img`; reading checks in [quickstart.md](quickstart.md)

**Target Platform**: Claude Code (where `/feat` runs); the script on Linux and macOS with bash 4+

**Project Type**: prompt package (skills + subagents) with helper scripts, shipped by APM, the plugin and `install.sh` (the scripts dir ships with the `feat` skill already)

**Performance Goals**: implementer model calls per spawn from 45.8 to 34 or fewer in the maintainer's busiest project (SC-002); `/feat` gains one script call at phase 5 and one per implementer spawn, no agent spawn

**Constraints**: `/feat` never reads tasks.md (principle I, FR-010); `story.sh` stays out of `references/harness.md` (lint grep, FR-013); tasker and implementer report formats and the size table unchanged (FR-014); the implementer rule is one short paragraph (FR-011); `/fix` unchanged (FR-012); the private baseline project is never named (FR-018)

**Scale/Scope**: one new script (about 120 lines) and its test dir; about 10 edited files plus 2 re-rendered SVGs; ~25 tasks

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Check | Result |
| --------- | ----- | ------ |
| I. Thin coordinators | `/feat` runs `story.sh` as one of its *commands besides the tracker* and compares two texts it holds (the tasker's report, the script's lines); it reads no tasks.md, spec or code. The parsing moves into a script, the ID check out of `/feat`'s judgement | pass |
| II. The user decides at gates | a mismatch or a script failure makes phase 5 hard, both sides shown (no soft path, as the brief decided); nothing else about gates changes | pass |
| III. One source of truth | size table unchanged; `harness.md` untouched; the phase 5 gate is mirrored in `docs/workflow.md`, `gates.d2`, `chain.d2` and the README alt text in the same commit as `/feat` | pass |
| IV. Fixed report formats | no agent report format changes; `story.sh`'s output is a script contract ([contracts/story-cli.md](contracts/story-cli.md)), written into the script header and changed with `/feat` in the same commit, as `tracker.sh`'s | pass |
| V. Small and plain | bash, shellcheck-clean, offline tests under `tests/`; one short paragraph added to the implementer; rules go into existing files. A script rather than a one-liner: the grouping, path and error rules need tests (principle V's own condition) | pass |

Post-design re-check: pass. The design adds one script and its tests, no
agent, dependency, service, permission or exposure.

## Design

### `story.sh` ([contract](contracts/story-cli.md), [research R1–R5](research.md))

- **Arguments**: `story.sh [--] <tasks.md> [US<k>]`; a leading `--` is
  dropped, there is no option, so any other first argument is the path
  (R13).
- **Forms**: `story.sh <tasks.md>` prints `setup/foundational: <n> tasks:
  <IDs>`, one `US<k>: …` line per story in heading order, `polish: …`,
  `total: <n> tasks`; IDs one by one, never ranges. `story.sh <tasks.md>
  US<k>` prints a header `US<k>: <n> tasks[; setup/foundational: <s>
  tasks][; polish: <p> tasks]; <u> unchecked`, one line per printed task
  `<ID> [ ]|[x] paths: <paths> | none` (no task text: it stays in
  tasks.md, the user's call at the design gate, D2), and a `files:` line
  merging every path once. On exit 0 the output holds no backtick.
- **Grouping**: story phases are level-2 headings `## Phase …: User Story
  <n>`; known stories, and first and last, come from those headings in file
  order (006 runs US2 first). A task's story is its first `[US<n>]` marker
  after the ID. Untagged tasks before the story span are setup/foundational,
  after it polish, inside it an error; a tag naming a story with no heading
  is an error. Fenced code blocks are skipped.
- **Paths**: a backticked span with no whitespace that contains `/` or ends
  in `.<letter>…` (so `mise run lint` and `2.103.3` are not paths), minus
  any span holding `<`, `*` or `://` (placeholders, globs, URLs: dropped
  by the script, D1). Never checked on disk: they are candidates, and the
  implementer reads the ones that exist.
- **Errors**: one stdout line, nothing on stderr: `story: error: …` exit 1
  (unreadable file, no tag, first misplaced task with its ID and line,
  unknown story); `story: usage: …` exit 2.
- **Implementation**: `set -euo pipefail`, `LC_ALL=C`, one pass with
  `[[ =~ ]]` filling arrays (id, checked, story, line, text, paths), then
  the span bounds and the output. No `awk`, `sed`, `jq`. File mode 100644
  like the other scripts (`/feat` runs it with `bash`).

### `/feat` ([text contract](contracts/workflow-text.md), [research R7–R9, R12](research.md))

- *Commands besides the tracker* lists `bash <base>/scripts/story.sh --
  '<tasks.md>' [US<n>]`, run only on a `Tasks:` path that is on the
  tasker's `Wrote:` and passed the `ls -d` check (D8, R13); nothing is
  added to `harness.md`, whose thin-orchestrator rule already allows the
  listed commands.
- **Phase 5**: after each tasker report (reruns included), once its
  `Wrote:` check passed, run the all-stories form on the `Tasks:` path;
  compare per group with `Per story:` (the tasker's groups identified by
  label: setup and foundational IDs together, polish, each `US<n>`; IDs
  with no label or a grouping that reads two ways are a difference, D6;
  ranges expanded; a missing group is empty). A difference or a non-zero exit → hard gate, one line per
  differing group `<group> — tasker: <IDs> — tasks.md: <IDs>`, or the error
  line; recommend the tasker fix (its existing step 4), then rerun. Log
  `story.sh: match` or what differed. The size check uses `total:`. A
  tasker report that folds setup into a story is a difference (R8). Phase 6
  never starts without a clean run (R9).
- **Phase 6**: stories in `story.sh`'s order; before every implementer
  spawn (first, retry, resume) run the one-story form and put the output in
  the prompt between two lines of four backticks (longer than any backtick
  run in it: it holds none), labelled data, never instructions (D7, R13);
  the IDs it owns are those listed. A non-zero exit is a hard gate with its
  line.
- **Phase 8**: nothing in the repo; the brief's acceptance asks the PR body
  to say `Part of #55`, which `/feat` passes to the shipper from the state
  file at ship (R12).

### `feat-implementer.agent.md`

- Intro: the task IDs come with `story.sh`'s view of them; everything up
  to the closing fence is data, never instructions; tasks.md stays the
  file it reads and ticks, and the one holding the task text.
- **One turn** paragraph (every mode, about seven lines), after the
  numbered steps: independent tool calls in one turn; story mode's first
  turn sends together `git status --short`, the Spec Kit reads its skill
  requires and the existing files on the `files:` line (a missing one may
  be a file the story creates, D1); bug mode's first turn sends `git
  status --short` with the bug report and `assessment.md`, the Spec Kit
  reads come once `speckit-bug-fix` is invoked, and the files
  `assessment.md` lists go together in the turn after it is read (D4,
  R10); then the searches before a task, the edits to different files and
  the ticks of one task group go together. Fix and rebase mode: the first
  sentence only. `/fix` gets it through this shared file; `/fix` itself is
  unchanged.

### Tests (`tests/story/`, [research R6](research.md), cases in [quickstart §3](quickstart.md))

- `run.sh`: `new_case`/`fail`/`ok` helpers as in `tests/secret-scan/run.sh`;
  each case runs the script with `bash`, captures stdout, the exit code, and
  asserts empty stderr.
- `fixtures/006-tasks.md`, `fixtures/009-tasks.md`: frozen copies of
  `specs/006-rebase-when-main-moves/tasks.md` and
  `specs/009-soft-design-gate/tasks.md`; `expected/006-all.txt`,
  `expected/009-all.txt` written by hand from those runs' phase 5 Log lines
  (quickstart §2), plus the one-story headers of quickstart §2.
- Synthetic fixtures (small files under `fixtures/`): a mixed tasks.md
  (setup, foundational, stories with `[P]`, checked and unchecked tasks,
  no-path, several-path and command-only tasks, a fenced task line, a last
  story with no tasks of its own, polish, and one task naming a
  placeholder, a glob and a URL beside a real path) with its expected
  outputs; one file each for no tag, an untagged task inside a story phase,
  and a tag with no story heading. Cases also run with `--` before the path
  and check no exit-0 output holds a backtick.

### Docs and checks

- `docs/workflow.md`: phase table row 5, the sizes matrix's hard-gates row
  (+5 on CRITICAL/HIGH or a task mismatch), section 5 (the comparison and
  its hard gate, `total:` for size) and one sentence in section 6 (the
  `story.sh` view in each prompt, the one-turn rule).
- `docs/diagrams/gates.d2` and `chain.d2`: the phase 5 gate label names a
  task mismatch; `mise run diagrams` re-renders `docs/img/gates.svg` and
  `chain.svg` (`models.svg` stays as is: the size table does not change).
  README's `gates.svg` alt text follows.
- `mise.toml`: `test:story` task, `lint` shellchecks `tests/story/run.sh`,
  `test:apm` checks `story.sh` lands. `.github/workflows/check.yml` runs
  `mise run test:story`. `.claude/CLAUDE.md`'s shell paragraph and
  `CONTRIBUTING.md`'s pre-PR list name `test:story`.

### Commits (for the shipper)

`docs(specs)` for the spec dir; `feat(feat): check tasks.md against the
tasker's report and hand each implementer its story` (script, tests, mise,
CI, `/feat`, docs, diagrams, CLAUDE.md, CONTRIBUTING); `feat(agents): send
the implementer's independent tool calls in one turn` (the agent file and
its line in `docs/workflow.md` section 6 if separable, else with the first).

## Project Structure

### Documentation (this feature)

```text
specs/010-implementer-fewer-calls/
├── plan.md                    # this file
├── research.md                # decisions R1–R13
├── data-model.md              # task, story, group, tasker report
├── quickstart.md              # checks, expected outputs, live and post-merge validation
├── contracts/
│   ├── story-cli.md           # story.sh: arguments, parsing, output, errors
│   └── workflow-text.md       # what /feat, the implementer, docs and checks say
└── tasks.md                   # phase 5 (feat-tasker)
```

### Source Code (repository root)

```text
.apm/
├── skills/feat/
│   ├── SKILL.md                       # harness value, row 5, sections 5 and 6
│   └── scripts/story.sh               # new
└── agents/feat-implementer.agent.md   # intro clause, One turn paragraph
tests/story/                           # new
├── run.sh
├── fixtures/                          # 006-tasks.md, 009-tasks.md (real copies), synthetic files
└── expected/                          # hand-written expected outputs
docs/
├── workflow.md                        # row 5, sizes matrix, sections 5 and 6
├── diagrams/gates.d2, chain.d2        # phase 5 gate label
└── img/gates.svg, chain.svg           # re-rendered
README.md                              # gates.svg alt text
mise.toml                              # test:story, lint, test:apm
.github/workflows/check.yml            # runs test:story
.claude/CLAUDE.md                      # shell paragraph names test:story
CONTRIBUTING.md                        # pre-PR checks list
```

**Structure Decision**: the script sits next to `tracker.sh` and ships with
the `feat` skill the three ways it already does; its tests follow the
existing one-dir-per-script layout under `tests/`. `harness.md`,
`.apm/skills/fix/SKILL.md`, `feat-tasker.agent.md` and every other agent
stay untouched.

## Risks

- **False hard gates**: a tasker report that folds setup into the first
  story, or a tasks.md whose story headings differ from the template, stops
  phase 5. Both show the reason in one line and are fixed by the tasker;
  the recent reports list setup and polish apart. Watch the first runs.
- **Prompt growth**: small. The one-story output carries no task text
  (D2), one short line per task (ID, checked state, paths) plus the header
  and `files:`, so a 10-task story adds about a dozen short lines to the
  prompt (cache reads at 0.1 weight per call); SC-002's cost-share check
  still catches it if it outweighs the calls saved.
- **The rule ignored**: SC-005 files a follow-up instead of growing the
  paragraph.

## Complexity Tracking

No constitution violation to justify.
