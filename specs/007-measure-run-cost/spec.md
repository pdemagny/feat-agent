# Feature Specification: Measure what a /feat or /fix run costs

**Feature Branch**: `measure-run-cost`

**Created**: 2026-11-19

**Status**: Draft

**Input**: User description: brief `specs/briefs/measure-run-cost.md` (issue #53)

## User Scenarios & Testing *(mandatory)*

### User Story 1 - See what my runs cost and where the time goes (Priority: P1)

A user of logistics, on their own repo, runs one command from that repo and gets a terminal report, per skill (`/feat`, `/fix`), of the median numbers over their finished runs: how many model calls the coordinator makes and of what kind, how big its context is (at the first call, and the median and maximum over all its model calls), what share of a run's cost each agent type takes, where the wall-clock time goes, what each agent type's first request is made of, and tokens by kind with one weighted figure. It reads the transcripts Claude Code already keeps on the machine.

**Why this priority**: This is the need behind the whole feature: numbers on a run's cost and time, available to anyone who installed logistics, with no checkout of this repo.

**Independent Test**: Run the script on fixture transcripts holding a few finished runs of both skills; check each reported number against hand-computed values.

**Acceptance Scenarios**:

1. **Given** fixture runs of `/feat` with a coordinator making known numbers of spawning, chore and text-only calls, **When** the report runs, **Then** the three kinds of coordinator calls, each agent type's spawns per run and model calls per spawn, and each agent's cost share (default weights) are the exact expected medians, with the number of runs.
2. **Given** a fixture run with parallel agents and user answers, **When** the report runs, **Then** wall clock is split into agents working, waiting for the user, coordinator thinking and coordinator tools, the four parts add up to the run's duration, and the number of user answers is shown.
3. **Given** a fixture whose agents' first requests are recorded, **When** the report runs, **Then** each agent type's first request is broken down (tool schemas by name, skills listing, the system prompt (includes Claude Code's own), instruction files); for an agent type whose transcripts do not record it, the report says "not recorded".
4. **Given** a fixture session in which `/feat` (plain or `logistics:`-prefixed) was invoked and a `feat-shipper` agent was spawned, **When** the report runs, **Then** it counts as a finished run; a session with `feat-*` agents but no shipper is listed apart as unfinished and is not in the medians.
5. **Given** the output for the fixtures, **When** it is inspected, **Then** it contains none of the prompt, file or command text the fixtures hold; only counts, tool names, agent types, models, session ids, dates and repo paths.

---

### User Story 2 - Judge whether a change helped (Priority: P1)

The maintainer (or a user who changed their setup) gives a date and gets the medians of the runs before it next to those since it, with the difference and the number of runs on each side, so a change to the workflow is judged on numbers, not on a mechanism.

**Why this priority**: Comparison is what judges a change, and epic #31's items each state a target that nothing in the repo can check today.

**Independent Test**: Fixtures with two runs before a date and two since; run with `--compare-since <date>`.

**Acceptance Scenarios**:

1. **Given** two runs before and two since a date, **When** `--compare-since <date>` runs, **Then** both medians, their difference and both counts are printed, with no statistical claim.
2. **Given** no run on one side of the date, **When** the command runs, **Then** that side prints "no runs" and the exit status is 0.

---

### User Story 3 - Choose which runs are counted (Priority: P2)

The user selects the runs: by default the repo the command is run in, including runs made in its worktrees; another repo with `--project <path>`; every project on the machine with `--all`, one block per repo and one for the total; and a date window with `--since` and `--until`.

**Why this priority**: Repos differ more than changes do, so mixing them by default would hide or fake an effect; selecting precisely is needed for the comparison to mean anything. The default (current repo) already works for most users, hence P2.

**Independent Test**: Fixtures with sessions in a repo A, a worktree of A, a repo whose folder name merely starts with A's name, and another repo B.

**Acceptance Scenarios**:

1. **Given** a session whose recorded working directory is a worktree of repo A, stored in a different folder than A's, **When** the command runs in A, **Then** the session is counted for A.
2. **Given** a session of a repo whose folder name merely starts with A's name, **When** the command runs in A, **Then** it is not counted.
3. **Given** runs in repos A and B, **When** `--project <path of B>` runs, **Then** only B's runs are counted; with `--all`, the output has one block per repo and one total block.
4. **Given** `--since 2026-03-01` or `--until`, **When** the command runs, **Then** only runs whose invocation falls in that window (local time zone) are counted.
5. **Given** a selection matching no run, **When** the command runs, **Then** it prints "no runs found" with where it looked, and exits 0.

---

### User Story 4 - Look at one run in detail (Priority: P2)

To understand a number that looks odd, the user passes `--session <id>` and gets the same figures for that single run, not medians.

**Why this priority**: The report explains a surprising median; without a per-run view the user cannot trace it.

**Independent Test**: Run on a fixture with `--session <id>` and compare with the hand-computed values for that run.

**Acceptance Scenarios**:

1. **Given** a fixture session id, **When** `--session <id>` runs, **Then** the report shows that run's own values for every figure in the default report.
2. **Given** the id of a left-out run, **When** `--session <id>` runs, **Then** it prints that run's left-out line (session id, date, reason, Claude Code version) and exits 0, or 1 with `--strict`.

---

### User Story 5 - Weights and optional money (Priority: P2)

Cost is shown in cost units (default weights per token kind and per model). A user can supply a JSON file with `--weights` to override any weight and, if they want, give prices, in which case the report adds a dollar column. Without prices, no money is ever printed.

**Why this priority**: Users differ in model mix and plan (a subscription user gets nothing from dollars); units keep shares and differences valid.

**Independent Test**: Run the same fixtures with and without an override file, and with and without prices in it.

**Acceptance Scenarios**:

1. **Given** the default weights (input 1, cache read 0.1, output 5, cache write 2 on the 1-hour cache and 1.25 on the 5-minute cache, 1.25 when the record has no breakdown; haiku 1, sonnet 3, opus 5), **When** the report runs, **Then** cost units are computed accordingly.
2. **Given** a weights file overriding some weights, **When** the report runs, **Then** the cost units change accordingly.
3. **Given** a weights file that also gives prices, **When** the report runs, **Then** a dollar column is added; **Given** one without prices, **Then** no money appears.
4. **Given** a model with no weight, **When** the report runs, **Then** the model is named in the report and weighted as the highest model weight in effect.

---

### User Story 6 - Trust the numbers when transcripts are odd (Priority: P2)

Transcripts are Claude Code's undocumented format and vary by version. The tool ignores record types it does not use; a run missing what the numbers need (a model call without token usage, an event without a timestamp, an unreadable line, an agent transcript missing, an invocation with no recorded message origin, a record of an unexpected shape) is left out whole, listed at the end with the reason and its Claude Code version, and the other runs are still reported. Every report states how many runs were counted and left out. `--strict` makes the command exit non-zero when any run was left out.

**Why this priority**: A single odd session in a user's history must not make the tool useless, nor mix good and bad data in one number.

**Independent Test**: Fixtures with a run containing a model call lacking token usage, and a record of an unknown type.

**Acceptance Scenarios**:

1. **Given** a run with a model call lacking token usage, **When** the report runs, **Then** that run is left out and listed with its reason and Claude Code version, the other runs are reported, and the counts of counted and left-out runs are shown.
2. **Given** the same fixtures, **When** run with `--strict`, **Then** the exit status is non-zero; without it, 0.
3. **Given** a record of an unknown type, **When** the report runs, **Then** nothing changes in the output.
4. **Given** an event without a timestamp, **When** the report runs, **Then** its run is left out like any other run missing required data.
5. **Given** a run with a record field of an unexpected type, **When** the report runs, **Then** that run is left out with the reason `unexpected record shape`, and no text of the record and no error text appears in the output.

---

### User Story 7 - Learn to install, run and read it (Priority: P3)

A user finds a docs page describing the command for each way of installing logistics, each option, how to read each number, the weights and prices file, what "left out" means, the Claude Code versions tested and the limits. The workflow doc carries a dated baseline section; the install doc lists Python 3.11 or later as needed for this script only; `install.sh check` notes whether it is present without counting it as missing.

**Why this priority**: Needed for a public interface, but useless without the tool itself.

**Independent Test**: Check the pages exist with their required front matter and content; run `install.sh check` with and without Python 3.11+.

**Acceptance Scenarios**:

1. **Given** the docs, **When** inspected, **Then** `docs/measure.md` exists with `title` and `weight` front matter and covers the items above; `docs/workflow.md` has a baseline section with its date and weights; `docs/install.md` lists Python 3.11 or later for this script only.
2. **Given** a machine without Python 3.11 or later, **When** `install.sh check` runs, **Then** it reports a note and does not fail or count it as missing.
3. **Given** a checkout of this repo, **When** `mise run measure -- --help` runs, **Then** the options are printed, and `mise run measure -- <args>` passes its arguments through to the script.

---

### Edge Cases

- A run resumed in a second session: each session is its own run (not joined). A session whose invocation's arguments start with `resume` (`/feat resume`, `/fix resume`) is classified "resumed (not in the medians)": counted, listed apart next to the unfinished runs, and kept out of the medians even when it spawned a shipper.
- Work done in a session before the `/feat` or `/fix` invocation (other commands, agents spawned earlier) is not part of the run: the run starts at the invocation record.
- Dates are read in the user's local time zone; a run's date is the date of its invocation.
- A run whose coordinator spawned agents in parallel: wall clock must not count them twice.
- An agent's transcript with no recorded first request (older Claude Code): "not recorded", not left out.
- An unknown model: named in the report and weighted as the highest model weight in effect.
- A cache-creation record without a breakdown: weighted as the 5-minute cache.
- Folder names that share a prefix with a repo's folder must not be attributed to it; attribution comes from the recorded working directory, never the folder name.
- A working directory whose `.git` file names a git dir that is not a worktree's (no common dir, as in a submodule or a separate git dir): the directory holding the `.git` file is the repo.
- A repo path, model id or other recorded string holding a control character (a tab, a newline): printed with `?` in its place.
- A side of a comparison, or a whole selection, with no runs: "no runs" line, exit 0.
- A run of `/brief` or `/tiny`, or a session where `/feat` was invoked but no `feat-*` agent was spawned: not a run.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The tool MUST ship with the feat skill as `scripts/measure.py`, next to `tracker.sh`, using only the Python 3 standard library (3.11 or later), so every install route (APM package, plugin, `install.sh`) has it.
- **FR-002**: In this repo, `mise run measure` MUST run the same file and pass its arguments through; `mise run measure -- --help` MUST print the options.
- **FR-003**: The tool MUST only read transcripts (read-only file access), write nothing but its terminal output, and make no network call.
- **FR-004**: A run MUST be one session in which `/feat` or `/fix` was invoked (plain or `logistics:`-prefixed) and at least one `feat-*` agent was spawned. A run starts at its invocation record: its coordinator model calls and tool calls, its timeline, the user's answers and its agents (those whose transcript's first timestamp is at or after the invocation) are counted from there, and work earlier in the session is not part of the run. A run's date is the date of its invocation. A run is finished when a `feat-shipper` agent was spawned in it, for both skills. A run whose invocation's arguments start with `resume` is resumed: it is counted and listed apart as "resumed (not in the medians)", next to the unfinished runs, whether or not it spawned a shipper. Medians MUST use finished runs that are not resumed; unfinished runs MUST be counted and listed apart. Runs of `/brief` and `/tiny` are not runs.
- **FR-005**: Cost share MUST be a share of that run's total cost units (coordinator plus all its agents = 100% for one run); medians of shares need not add to 100%.
- **FR-006**: Wall clock MUST be split along the coordinator's own timeline, from the invocation record to its last event, each gap between two of its events going to what ends it: a model reply (coordinator thinking), a tool result (coordinator tools), an agent's report arriving (agents working), a message the user typed (waiting for the user). The four parts MUST add up to the run's duration.
- **FR-007**: An agent's time split MUST use the same rule on the agent's own transcript: a gap ended by a model reply is model time, by a tool result is tool time.
- **FR-008**: The default report MUST be given per skill, as medians over the selected finished runs (resumed runs excluded), with the number of runs, except where a figure below says otherwise, and contain:
  - coordinator: model calls split into calls that spawn an agent, calls that only do chores (tool calls, no agent) and calls with text only; its context at the first call, and the median and maximum over all its model calls (each a figure of the run, then a median over runs); its share of the run's cost; its failed tool calls by tool, as the total over the finished runs with the number of runs (not a median);
  - each agent type: spawns per run, model calls per spawn, context at its first call, share of the run's cost, time split between model and tools;
  - wall clock: agents working, waiting for the user, coordinator thinking, coordinator tools; and the number of times the user answered during the run;
  - for each agent type, what the first request of its first spawn in a run is made of (tool schemas by name, skills listing, the system prompt (includes Claude Code's own), instruction files) when the transcript records it, else "not recorded";
  - tokens by kind (input, cache write, cache read, output) and one weighted figure in cost units.
- **FR-009**: `--session <id>` MUST print the same numbers for that one run, not medians. For a left-out run it MUST print that run's left-out line (session id, date, reason, Claude Code version), and exit non-zero only with `--strict`.
- **FR-010**: `--compare-since <date>` MUST print the medians of the runs before the date next to those since it, with the difference and the number of runs on each side, making no statistical claim. A side with no run MUST print "no runs" and the command MUST exit 0. With `--all`, each repo block and the total block MUST use the same comparison layout.
- **FR-011**: With no selection option, the tool MUST take the repo the command is run in, including runs made in its worktrees. `--project <path>` MUST pick another repo. `--all` MUST take every project on the machine, with one block per repo and one for the total. `--since` and `--until` MUST bound the dates. Every date option MUST take `YYYY-MM-DD`, read in the user's local time zone.
- **FR-012**: Sessions MUST be attributed to a repo from the working directory each transcript records, never from the folder name; a worktree session is attributed to its repo, and a repo whose folder name merely starts with another's is not. A directory whose `.git` file names a git dir with no common dir (not a worktree) is its own repo.
- **FR-013**: A selection with no run MUST print "no runs found" with where it looked, and exit 0.
- **FR-014**: Cost units MUST weight each token kind and each model. Defaults: input 1, cache read 0.1, output 5; cache write 2 on the 1-hour cache and 1.25 on the 5-minute cache, told apart by the usage record's cache-creation breakdown (1.25 when the record has none); haiku 1, sonnet 3, opus 5. A model with no weight MUST be named in the report and weighted as the highest model weight in effect (the defaults, or the weights file's).
- **FR-015**: `--weights <file>` MUST name a JSON file that overrides any weight. When it also gives prices, the report MUST add a dollar column; without prices the tool MUST never print money. No built-in price table. A weight or price that is not a finite number ≥ 0 (a boolean, `NaN` and `Infinity` included) MUST be rejected with an error and a usage exit status.
- **FR-016**: Record types the tool does not use MUST be ignored. A run missing what the numbers need MUST be left out whole and listed at the end with the reason and its Claude Code version; other runs MUST be reported. The reasons are: a model call without token usage; an event without a timestamp; an unreadable line; an agent transcript missing (a spawn names an agent with no transcript, or an agent id other than letters, digits, `_` and `-`); an invocation with no recorded message origin; an unexpected record shape (any other error while reading the session).
- **FR-017**: Every report MUST state how many runs it counted (finished, unfinished, resumed) and how many it left out. `--strict` MUST make the exit status non-zero when any run was left out.
- **FR-018**: The output MUST contain only counts, tool names, agent types, models, session ids, dates and repo paths, never the text of a prompt, a file or a command. An error while reading a session MUST never print its text (it gives FR-016's `unexpected record shape`). Every string taken from a transcript or the filesystem MUST be printed with its control characters (tab and newline included) replaced by `?`.
- **FR-019**: The options and output are a public interface from the first release; `--help` MUST list every option.
- **FR-020**: Docs: a new page `docs/measure.md` (with `title` and `weight` front matter) MUST give the command for each way of installing logistics, each option, how to read each number, the weights and prices file, what "left out" means, the Claude Code versions tested, and the limits, and a "Before sharing the output" paragraph: the output holds repo paths, the home directory and session ids, so what is posted publicly is only the all-repos block's figures, without the per-repo blocks or the unfinished, resumed and left-out lists. `docs/workflow.md` MUST get a baseline section with its date and weights and the same note (its numbers are filled by the maintainer from real transcripts, outside this feature's tasks). `docs/install.md` MUST list Python 3.11 or later as needed for this script only.
- **FR-021**: `install.sh check` MUST report whether Python 3.11 or later is present, as a note that is not counted as missing and does not fail.
- **FR-022**: Tests MUST run offline on synthetic fixture transcripts written for the tests (never copied from a real transcript) via `mise run test:measure`, with a bash runner following `tests/tracker/` and staying shellcheck-clean, checking exact numbers for the behaviours above. Each output case MUST map to an acceptance criterion; behaviours without one of their own are folded into those fixtures. Every free-text field the fixtures carry MUST hold a sentinel that no output may contain.
- **FR-023**: `mise run lint` MUST compile the script (add `measure.py` to the `py_compile` line), check its syntax against Python 3.11, and stay clean, with the shellcheck glob over `.apm/skills/feat/scripts/` narrowed to `*.sh`; `mise run test:apm` MUST check the script is installed.

### Key Entities

- **Run**: one session in which `/feat` or `/fix` was invoked and a `feat-*` agent was spawned, from its invocation on; has a skill, a date (its invocation's), a repo, a Claude Code version, finished, unfinished or resumed status, and counted or left-out status.
- **Coordinator**: the session's own model calls and tool calls; its timeline defines the wall-clock split.
- **Agent**: a spawned `feat-*` agent with a type, model, effort and its own transcript; spawned by the coordinator, reports back.
- **Agent first request**: what an agent's first model request was made of, when recorded.
- **Cost units**: weighted tokens (by kind and model); optionally converted to dollars from user-supplied prices.
- **Weights file**: user JSON overriding weights and optionally giving prices.
- **Left-out run**: a run missing required data, with a reason and Claude Code version.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: On the fixture transcripts, every reported figure (the three kinds of coordinator calls, spawns and calls per spawn per agent type, cost shares, wall-clock split) equals the hand-computed expected value exactly.
- **SC-002**: With two fixture runs before a date and two since, the comparison shows both medians, the difference and both counts (2 and 2).
- **SC-003**: A user can obtain a report for their own repo with one command and no setup beyond Python 3.11 or later.
- **SC-004**: In every fixture scenario the output contains zero characters of the prompt, file or command text the fixtures hold.
- **SC-005**: Of the fixture runs, one with a model call lacking token usage is left out and listed with its reason while the others are reported; with `--strict` the exit status is non-zero, otherwise 0; an unknown record type changes no number.
- **SC-006**: Empty selections and empty comparison sides print their "no runs" line and exit 0 in 100% of tested cases.
- **SC-007**: `mise run lint` and `mise run test:apm` pass with the script included, and `install.sh check` does not fail when Python 3.11 or later is absent.
- **SC-008**: The four wall-clock parts sum to the run's duration for every fixture run, including runs with parallel agents.

## Assumptions

- Users run the command from a repo (or pass `--project`) and have transcripts under `~/.claude/projects/` on the same machine.
- The transcript format is not a documented contract; the docs name the Claude Code versions tested, and the left-out rule is how a format change shows.
- Skill invocation is identified from the transcript's user-message origin (plain `/feat`, `/fix` or `logistics:`-prefixed); how exactly is a planning decision.
- Medians are taken per metric over finished runs; the unfinished are listed with counts but excluded.
- A cache write with no cache-creation breakdown is treated as 5-minute-cache.
- Local time zone is the system's.
- The Python floor is 3.11 or later: the user's decision at the design review gate, replacing the brief's 3.9.
- Baseline numbers in `docs/workflow.md` and the report posted next to #31's table are the maintainer's steps in the PR, outside the task list.
- Out of scope (decided in the brief): reading a run's state file; a `/measure` skill; a built-in price table; joining a resumed run's sessions; `/brief` and `/tiny` runs; charts, HTML or non-terminal-text output; statistical significance tests.
