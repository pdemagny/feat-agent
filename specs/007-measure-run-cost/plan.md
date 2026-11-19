# Implementation Plan: Measure what a /feat or /fix run costs

**Branch**: `measure-run-cost` | **Date**: 2026-11-19 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `specs/007-measure-run-cost/spec.md` (brief: issue #53)

## Summary

One read-only Python 3.11+ standard-library script, `.apm/skills/feat/scripts/measure.py`,
shipped with the feat skill so every install route has it. It finds the
`/feat` and `/fix` runs in Claude Code's session transcripts
(`$CLAUDE_CONFIG_DIR/projects`, default `~/.claude/projects`), attributes
each session to a repo by walking up from its recorded working directory to
the `.git` it belongs to (a worktree's `.git` file leads to its main repo),
computes per-run figures from the invocation record on (coordinator calls by
kind, contexts, cost units and shares, agents per type, the wall-clock split
along the coordinator's timeline, the first-request breakdown), and prints
medians per skill, one run (`--session`) or a before/since comparison
(`--compare-since`). A run missing what a figure needs is left out whole and
listed; a resumed session is listed apart. Offline tests run the script on
synthetic fixture transcripts from a bash runner modelled on
`tests/tracker/run.sh` and compare its output to hand-checked golden files.
Docs: a new `docs/measure.md`, a baseline section in `docs/workflow.md`, the
Python prerequisite in `docs/install.md`, and an `install.sh check` note.
Constitution principle V is amended in this PR to allow the script (1.2.0).

The record shapes the script relies on were checked (structure only, no
content) against transcripts written by Claude Code 2.1.304 to 2.1.328:
[contracts/transcript-records.md](contracts/transcript-records.md).

## Technical Context

**Language/Version**: Python 3.11 or later for `measure.py` (3.11 syntax and standard library allowed: `match`, `X | Y` unions, `datetime.fromisoformat` on the transcripts' `…Z` timestamps as they are); bash for the test runner and `install.sh`.

**Primary Dependencies**: Python standard library only (`argparse`, `json`, `math`, `os`, `re`, `statistics`, `datetime`, `collections`, `sys`). No new tool in `mise.toml`.

**Storage**: N/A. Reads transcript files (`*.jsonl`, `*.meta.json`) and an optional weights JSON file, all opened read-only; writes only to stdout and stderr.

**Testing**: `tests/measure/run.sh` (bash, shellcheck-clean, pattern of `tests/tracker/run.sh`), run by `mise run test:measure` and the `check` workflow. Fixtures are hand-written JSONL templates under `tests/measure/fixtures/`, made concrete in a temp dir; expected outputs are golden files under `tests/measure/expected/`. The Python floor is held by one `mise run lint` line, `ast.parse(…, feature_version=(3, 11))` on `measure.py`, with no extra interpreter in `mise.toml`.

**Target Platform**: Linux and macOS, wherever Claude Code keeps transcripts on the local disk.

**Project Type**: CLI script shipped inside a skill package.

**Performance Goals**: the default report on one repo over a ~2 GB transcript history in about 10 s; only sessions that pass a cheap pre-filter are parsed in full (research R9). Not a test gate.

**Constraints**: read-only, offline, no network import; prints only counts, tool names, agent types, models, session ids, dates and repo paths, with control characters replaced (FR-018); Python 3.11 or later; options and output are a public interface from the first release (FR-019).

**Scale/Scope**: hundreds of sessions and a few thousand agent transcripts per machine; ~100 runs per repo.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Result | Note |
| --- | --- | --- |
| I. Thin coordinators | pass | `/feat` and `/fix` are not changed and never call the script. |
| II. The user decides at gates | pass | No gate or verdict changes. |
| III. One source of truth per fact | pass | No size table, agent or harness change. The default weights live once, in the script; `--help` and every report print them from it, and the test checks `docs/measure.md` quotes the same line (see Docs below). |
| IV. Fixed report formats | pass | No agent prompt or report format changes. |
| V. Small and plain | pass, by amendment | "Scripts MUST be bash" is amended in this PR (accepted at the plan and design review gate): see below. `measure.py` is compiled and syntax-checked against 3.11 by `mise run lint` and covered by offline tests under `tests/`. No prompt grows: no skill or agent mentions the script. |
| Distribution | pass | Ships in `.apm/skills/feat/scripts/`, which all three routes install; `mise run test:apm` checks it lands. |

**Amendment (task of this feature)**: `.specify/memory/constitution.md`
principle V becomes, in its third sentence: "Scripts MUST be bash,
`shellcheck`-clean and covered by offline tests under `tests/`; where bash
would have to aggregate JSON, a script MAY instead be Python 3.11 or later
using the standard library only, compiled by `mise run lint` and covered by
offline tests under `tests/` the same way." Version 1.1.0 → 1.2.0 (MINOR:
guidance materially expanded), `Last Amended` set to the day of the change.
`.claude/CLAUDE.md`'s Shell line says the same in the same PR (Governance:
amendments update it when a rule changes): `measure.py` is the one Python
script, Python 3.11 or later and standard library only; `mise run lint`
compiles and syntax-checks it and `mise run test:measure` tests it.

Post-design re-check (after Phase 1): unchanged; the design adds no file a
coordinator or agent reads.

## Project Structure

### Documentation (this feature)

```text
specs/007-measure-run-cost/
├── plan.md              # this file
├── research.md          # Phase 0: decisions R1–R17
├── data-model.md        # Phase 1: run, agent, model call, figures, weights
├── quickstart.md        # Phase 1: how to run and validate
├── contracts/
│   ├── cli.md                  # options, exit codes, output sections and fixed lines
│   ├── weights-file.md         # the --weights JSON file
│   └── transcript-records.md   # the Claude Code records the script reads
└── tasks.md             # Phase 2 (speckit-tasks), not created here
```

### Source Code (repository root)

```text
.apm/skills/feat/scripts/
└── measure.py                 # new: the whole tool, one file

tests/measure/
├── run.sh                     # new: offline runner (mise run test:measure)
├── bin/                       # new: stub claude, gh, python3 for the install.sh check case only
├── fixtures/                  # new: synthetic JSONL templates, @ROOT@ for the temp dir
│   ├── projects/<folder>/<session>.jsonl
│   ├── projects/<folder>/<session>/subagents/agent-<id>.jsonl, .meta.json
│   └── weights/*.json         # override files, with and without prices, and invalid ones
└── expected/*.txt             # golden outputs, paths written as @ROOT@

mise.toml                      # tasks measure, test:measure; lint (and its description) and test:apm lines
.github/workflows/check.yml    # run test:measure
install.sh                     # check: Python 3.11+ note
docs/measure.md                # new page (title, weight 35)
docs/workflow.md               # baseline section
docs/install.md                # prerequisite row, check note
README.md                      # docs table row for measure.md
CONTRIBUTING.md                # test:measure in the checks before a PR
.claude/CLAUDE.md              # Shell line: measure.py, Python 3.11+, test:measure (matches the amendment)
.specify/memory/constitution.md  # principle V amended, 1.2.0
```

**Structure Decision**: one script file, no package, no module of its own to
import: it runs as `python3 <path>/measure.py` from any install, as
`tracker.sh` runs with `bash`; like it, no executable bit is needed.

## Design

### Script layout (`measure.py`)

Plain functions over dicts, in this order; no classes beyond what keeps a
run's figures together.

1. **Defaults and options**: the default weights (one dict); `argparse` with
   the options in [contracts/cli.md](contracts/cli.md); `--help` prints them
   and the default weights line. Mutually exclusive: `--all`/`--project`;
   `--session`/`--compare-since`. Bad date, bad weights file: message on
   stderr, exit 2.
2. **Discovery**: the projects dir is `$CLAUDE_CONFIG_DIR/projects` when the
   variable is set, else `~/.claude/projects` (R8). For each
   `<folder>/<session>.jsonl`: skip unless `<session>/subagents/` holds an
   `agent-*.jsonl`; peek lines until the first record with `cwd`; resolve the
   repo (R7), cached per distinct `cwd` so each is resolved once per command;
   drop it if the repo is outside the selection; then scan raw lines for an
   invocation tag (R1) before parsing anything else in full (R9). The run's
   date is its invocation's (local time); `--since`, `--until` and
   `--compare-since` test that date once the invocation is found.
3. **Repo resolution** (R7): from the recorded `cwd`, go up to the nearest
   directory that exists, then up to the first `.git`: a directory gives its
   parent; a file (`gitdir: <path>`, relative paths taken from the directory
   holding the file) gives the main repo via `<path>/commondir`; a gitdir
   with no `commondir` (a submodule, a separate git dir) gives the directory
   holding the `.git` file. No `.git` found: the cwd itself is the repo. The
   selected repo is resolved the same way from the current directory or
   `--project`. Component-wise path equality, never a string prefix.
4. **Session parse** → a run, a left-out run, or "not a run". The whole
   parse of one session is wrapped so that any exception it raises
   (`KeyError`, `TypeError`, `AttributeError`, `ValueError`, …) leaves the
   session out as a run with the fixed reason `unexpected record shape`; the
   exception's text and traceback are never printed.
   - invocation: the first human-origin user message carrying a `/feat`,
     `/fix`, `/logistics:feat` or `/logistics:fix` command tag gives the skill
     (R1). It is the run's start: in the main file, only records after it in
     file order are read for the run (coordinator calls, tool results,
     failed tool calls, user answers, the timeline); earlier records are not
     part of the run and cannot leave it out. A record with the tag and no
     `origin` leaves the run out, unless it is `isCompactSummary` or `isMeta`
     (those are ignored by that rule);
   - resumed: the invocation's `<command-args>` text, leading whitespace
     stripped, whose first word is `resume` marks the run resumed (R1);
   - coordinator records: top-level, non-sidechain records of `<session>.jsonl`;
     model calls grouped by `message.id`, usage from the last record of the
     id, timestamp from the first; `<synthetic>` model skipped (R2);
   - agents: every `subagents/agent-<id>.jsonl` whose first timestamp is at
     or after the invocation's, typed by its `.meta.json` `agentType`, else by
     the coordinator spawn whose result named `<id>`, else `unknown`; a
     `<plugin>:` prefix is stripped (R3). An agent id read from a transcript
     (`toolUseResult.agentId`, `origin.from`) is used only if it matches
     `[A-Za-z0-9_-]+`; any other id counts as `agent transcript missing` and
     is never joined into a path;
   - a run needs an invocation and one `feat-*` agent; finished when a
     `feat-shipper` agent is among them; resumed as above, whatever else;
   - left-out reasons (each whole-run, listed with session id, date and the
     first recorded `version`): model call without usage; used event without
     a timestamp (or an unparseable one); unparseable JSON line (R13); a spawn
     whose result names an agent with no transcript file or an invalid id;
     invocation without a recorded message origin; unexpected record shape.
5. **Per-run figures** ([data-model.md](data-model.md)): coordinator calls by
   kind, contexts (first call, median and max over its calls), failed tool
   calls by tool; cost units per part and shares; the coordinator timeline
   split (R4); per agent type spawns, calls per spawn, first-call context,
   share, model and tool minutes (R5); the first-request breakdown, parsed
   only for the first spawn of each agent type in the run (R6); tokens by
   kind; user answers.
6. **Aggregation**: medians per figure over the finished, non-resumed runs of
   one skill (`statistics.median`); per-agent-type figures over the runs
   where the type appears, with that count (R10). Failed tool calls by tool
   are the total over those runs, printed with their number, not a median.
   Comparison: the same aggregation on each side, difference = since −
   before.
7. **Rendering**: the sections and fixed lines of [contracts/cli.md](contracts/cli.md).
   Never prints a message text, tool input, tool output, file content or
   instruction file path. Every string that comes from a transcript or the
   filesystem (repo paths, session ids, model ids, tool names, agent types,
   versions, the projects dir) goes through one function that replaces each
   control character (Unicode category `Cc`: C0, DEL and C1, tab and newline
   included) with `?`.

### Weights and money

Defaults: tokens input 1, cache read 0.1, output 5, cache write 1h 2,
5m 1.25 (1.25 when the usage has no `cache_creation` breakdown); models
haiku 1, sonnet 3, opus 5. A model id matches a key equal to it, else a key
equal to one of its `-`-separated parts (`claude-opus-5-5` → `opus`). No
match: the highest model weight in effect, and the model is named in the
report. `--weights` merges over the defaults
([contracts/weights-file.md](contracts/weights-file.md)); `prices` (USD per
million input tokens, per model key) adds a dollar column, the token weights
scaling the other kinds. A model without a price uses the highest price given
and is named. The file is read with `json.load(…, parse_constant=…)` that
raises on `NaN`, `Infinity` and `-Infinity`; a value is valid only if it is
an `int` or `float`, not a `bool`, finite (`math.isfinite`, which also
catches `1e400`) and ≥ 0; anything else is a usage error (exit 2).

### Wall clock (FR-006, FR-007)

Coordinator timeline: start = the invocation record's timestamp. Events after
it, each ending the gap since the previous event (or the start):
- assistant record (one per content block) → coordinator thinking;
- user record with a `tool_result` → coordinator tools, except the result of
  an `Agent`/`Task` call that is the agent's report (not
  `status: "async_launched"`, not an error) → agents working;
- user record with `origin.kind == "peer"` (an agent's hand-back) → agents
  working;
- user record with `origin.kind == "task-notification"` → coordinator tools;
- user record with `origin.kind == "human"` → waiting for the user.

Other records do not end a gap. Duration = last event − start, so the four
parts add up to it exactly; parallel agents are counted once. Agent timeline
(only agents whose first timestamp is at or after the invocation): every user
and assistant record of the agent's file is a boundary; a gap ended by an
assistant record is model time, by a `tool_result` tool time, anything else
(the spawn prompt, a continuation) is not counted.

### Tests (`tests/measure/run.sh`)

- A temp dir holds `config/projects/` (fixtures with `@ROOT@` replaced by the
  temp path), and real repos made with `git init` and `git worktree add`:
  `app`, a worktree `app/.claude/worktrees/wt`, `app-old` (prefix trap),
  `other`, a repo whose directory name holds a tab, and `lib`, whose `.git`
  file names a separate git dir with no `commondir`; one fixture's cwd is a
  deleted worktree under `app`. `CLAUDE_CONFIG_DIR`, `TZ=UTC` and git's
  config are pinned; fixtures are made read-only (`chmod -R a-w`) before any
  run.
- Each case runs `python3 -I measure.py …` from a repo, replaces the temp path
  in the output with `@ROOT@`, and compares it to `expected/<case>.txt`, plus
  the exit code. The exact figures the acceptance names (three call kinds,
  spawns and calls per spawn, shares with default weights, the wall-clock
  split and its sum) are computed by hand in a comment beside each fixture
  run, and the golden files agree with them.
- Golden cases, one per acceptance line of the brief; the other behaviours
  live in their fixtures:
  - `report` (default, from `app`): finished runs of both skills; the worktree
    and deleted-worktree sessions counted, `app-old` not; an unfinished run
    and a `resume` run listed apart; a run with work before its invocation
    (an earlier command and agent) not counted in its figures; a parallel-agent
    run; one agent type with no first request (`not recorded`); a message id
    whose records carry growing usage (the last counts); an unknown model
    (`unweighted models:`); not-a-run sessions (`/brief` with a
    `feat-brief-reviewer`, `/feat` with no agent); a compact-summary record
    with the tag and no origin (ignored);
  - `compare` (`--compare-since` on 2 and 2 runs) and `compare-empty` (a date
    with no run before);
  - `project` (`--project other --since … --until …`: of `other`'s three
    runs, the ones before and after the window are not counted) and `all`
    (`--all`: one block per repo, the tab repo printed with `?`, `lib` as its
    own repo, and the total);
  - `no-runs` (empty selection);
  - `weights` and `weights-prices`;
  - `left-out`: runs without usage, without a timestamp, with a wrong-typed
    field holding a `SECRET-` value (`unexpected record shape`), and with a
    spawn result naming agent id `../x` (`agent transcript missing`); run
    again with `--strict` (exit 1);
  - `session` (`--session <id>`, FR-009, which no acceptance line covers on
    its own); `--session` on a left-out id checks its left-out line and exit
    0, then 1 with `--strict` (no golden file);
  - `help` (`--help`).
- Unknown record type: appended to a `report` session, the output is
  byte-identical to `report`'s.
- Weights errors (exit 2, message on stderr, no stdout): `true`, `NaN`,
  `Infinity`, `1e400`, `-1`, a string, an unknown section, an unknown
  `tokens` key, not JSON.
- Privacy: every free-text field the fixtures carry holds a `SECRET-`
  sentinel: typed messages and the command args, `text` and `thinking`
  blocks, `tool_use` inputs other than `subagent_type`, tool results and
  `toolUseResult` texts, agent reports, `api-request-shape` system texts and
  tool descriptions, the skill listing, and instruction-file paths and
  bodies. No output of any case, stdout or stderr, contains `SECRET-`.
- Static (a test, not a lint grep): the script's imports are within the
  standard-library allowlist above, no `socket`/`urllib`/`http` import, no
  `open(` with a write or append mode.
- `install.sh check` with stubs on `PATH` (`claude` so the real CLI is never
  run, `gh` so `gh auth status` stays offline, `python3` failing or passing):
  with the `python3` stub failing, a `note` line names Python 3.11 and the
  exit code equals the one with the stub succeeding.
- `docs/measure.md` contains the default-weights line `--help` prints.

### Repo wiring

- `mise.toml`: `[tasks.measure]` runs `python3 -I .apm/skills/feat/scripts/measure.py`
  with `quiet = true`; arguments are appended by mise. `mise run measure
  --help` is answered by mise itself (checked on mise 2026.9.17), so the
  script's help is `mise run measure -- --help`, as FR-002 and US7 say.
  `[tasks."test:measure"]` runs `bash tests/measure/run.sh`. `lint`:
  `shellcheck .apm/skills/feat/scripts/*.sh`, add `shellcheck
  tests/measure/run.sh tests/measure/bin/*`, add the script to the
  `py_compile` line, add `python3 -c 'import ast, sys; ast.parse(open(sys.argv[1]).read(),
  feature_version=(3, 11))' .apm/skills/feat/scripts/measure.py`; its
  `description` names `measure.py` (compiled and checked against Python
  3.11). `test:apm`: `test -f .claude/skills/feat/scripts/measure.py`.
- `.github/workflows/check.yml`: a `mise run test:measure` step beside the
  other test steps.
- `install.sh check`: after the tools, `python3 -c 'import sys;
  sys.exit(sys.version_info < (3, 11))'`: `ok       python3 3.11 or later
  (measure.py)` or `note     python3 3.11 or later not found (needed by
  measure.py only: docs/measure.md)`; never sets `missing`.

### Docs

- `docs/measure.md` (`title: Measure`, `weight: 35`): the command per install
  route (APM user-level `~/.claude/skills/feat/scripts/measure.py`, which is
  also where the dev install `install.sh` puts it; APM project-level
  `.claude/skills/feat/scripts/measure.py`; plugin
  `~/.claude/plugins/cache/logistics/logistics/<version>/.apm/skills/feat/scripts/measure.py`;
  clone `mise run measure -- …`); Python 3.11 or later; each option; how to
  read each number (the definitions of FR-004 to FR-008 and R10: a run starts
  at its invocation; failed tool calls are totals); the weights file; what
  "left out", "unfinished" and "resumed" mean; the versions tested (2.1.304
  to 2.1.328); limits (undocumented format; worktrees outside the repo dir
  that no longer exist count as their own repo; a resumed run is its own
  session and is kept out of the medians; duration is wall clock from the
  invocation to the last event, idle time included; character sizes in the
  first-request breakdown, from each type's first spawn; queued messages); a
  "Before sharing the output" paragraph: the output holds repo paths, the
  home directory and session ids, so post only the all-repos block's
  figures, without the per-repo blocks or the unfinished, resumed and
  left-out lists.
- `docs/workflow.md`: a `## Baseline` section with its date, the weights
  line and the same "before sharing" note; the figures are filled by the
  maintainer from an `--all` run before merge (spec assumption, outside the
  tasks), from the all-repos block only.
- `docs/install.md`: a Prerequisites row "Python 3.11 or later, for
  `measure.py` only"; section 4 lists the new `note` line.
- `README.md` docs table, `CONTRIBUTING.md` checks list, `.claude/CLAUDE.md`
  Shell line: name `measure.py` and `mise run test:measure` (the CLAUDE.md
  line also carries the principle V amendment above).

## Assumptions (decisions beyond the spec)

- **A1** (accepted at the gate): `mise run measure --help` shows mise's own
  task help, not the script's (research R14). The plan, docs and tests use
  `mise run measure -- --help`; FR-002 and US7 scenario 3 say so.
- **A2** (accepted at the gate): constitution principle V is amended in this
  PR (1.2.0), with the Python 3.11 floor in its wording; see Constitution
  Check.
- **A3**: invocation recognised by the command tag in a human-origin message
  (R1); the first of `/feat` or `/fix` in a session gives the skill.
- **A4**: first-request parts in characters; "the agent's own prompt" is the
  whole system prompt, which also holds Claude Code's (R6).
- **A5**: per-agent-type medians over the runs where the type appears, with
  that count; per-spawn figures are the mean within a run (R10).
- **A6**: unknown model → highest model weight in effect; model without a
  price → highest price given; both named (R12). Prices are USD per million
  input tokens per model (R11).
- **A7**: an unparseable JSON line leaves its run out (R13).
- **A8**: `--session` searches every project folder and ignores the repo
  selection; an unknown id or a non-run prints "no runs found".
- **A9**: `SendMessage` continuations are chores, not spawns; queued user
  messages and other records end no gap (R4).
- **A10**: transcripts under `$CLAUDE_CONFIG_DIR/projects` when set (R8).
- **A11**: `--since`/`--until` inclusive; `--compare-since D` puts D in
  "since".
- **A12**: a deleted worktree outside its repo's directory counts as its own
  repo (R7 limit, documented).
- **A13**: `check.yml`, `README.md`, `CONTRIBUTING.md` and `.claude/CLAUDE.md`
  get the one-line mentions their lists need.
- **A14**: "resumed" means the first word of the invocation's arguments is
  `resume`, so a brief named `resume-parser` is not taken for a resume. A
  resumed run counts only as resumed (not also as finished or unfinished);
  `--session` on it prints its figures under a `resumed` heading.
- **A15**: records before the invocation are not read for the run, so a
  defect there (a call without usage) does not leave the run out.
- **A16**: a session that passed the pre-filter (agent files and a `/feat` or
  `/fix` tag) and raises while parsed is listed as left out (`unexpected
  record shape`) even if a full parse might have found it was not a run:
  visible rather than silently dropped.
- **A17**: in a comparison, failed tool calls show each side's total and its
  number of runs, with the difference column empty (totals over different
  numbers of runs do not subtract); share differences are signed whole
  percentage points (`+3pp`).
- **A18**: the `install.sh check` test stubs only `claude`, `gh` and
  `python3`; `git` and `specify` are looked up with `command -v` only, and
  the case compares the two exit codes on one machine.

## Complexity Tracking

None: the one departure from the constitution (principle V) is resolved by
the amendment in this PR (see Constitution Check).
