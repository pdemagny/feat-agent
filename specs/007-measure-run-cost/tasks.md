---

description: "Task list for measure-run-cost"
---

# Tasks: Measure what a /feat or /fix run costs

**Input**: Design documents from `specs/007-measure-run-cost/`

**Prerequisites**: plan.md, spec.md, research.md (R1-R17), data-model.md, contracts/ (cli.md, weights-file.md, transcript-records.md), quickstart.md

**Tests**: Requested (FR-022): offline, on synthetic fixtures written for the tests, never copied from a real transcript. Each golden file is computed by hand (the arithmetic goes in a comment beside the fixture run), then the script is made to agree with it.

**Organization**: grouped by user story. Nearly all code goes into one file, `.apm/skills/feat/scripts/measure.py`, so script tasks run one after another; fixtures and golden files are separate files and are marked [P].

## Format: `[ID] [P?] [Story] Description`

- **[P]**: different files, no dependency on an unfinished task
- **[Story]**: US1 to US7, from spec.md

## Path Conventions

- Script: `.apm/skills/feat/scripts/measure.py` (Python 3.11 or later, standard library only)
- Tests: `tests/measure/run.sh`, `tests/measure/bin/`, `tests/measure/fixtures/`, `tests/measure/expected/`
- Fixtures hold the placeholder `@ROOT@` for the temp dir; every free-text field in them holds a `SECRET-` sentinel that no output may contain

## Out of the task list (maintainer's own steps in the PR)

Filling the baseline section's numbers from a real `--all` run, and posting that report next to issue #31. No task needs a real transcript.

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: repo wiring so lint and the test task exist from the start

- [x] T001 Add to `mise.toml` the task `[tasks.measure]` (run `python3 -I .apm/skills/feat/scripts/measure.py`, `quiet = true`, arguments appended by mise) and `[tasks."test:measure"]` (run `bash tests/measure/run.sh`)
- [x] T002 In `mise.toml` change `[tasks.lint]`: narrow `shellcheck .apm/skills/feat/scripts/*` to `*.sh`; add `shellcheck tests/measure/run.sh tests/measure/bin/*`; add `measure.py` to the `py_compile` line; add `python3 -c 'import ast, sys; ast.parse(open(sys.argv[1]).read(), feature_version=(3, 11))' .apm/skills/feat/scripts/measure.py`; update its `description` to name `measure.py` (compiled and checked against Python 3.11). In `[tasks."test:apm"]` add `test -f .claude/skills/feat/scripts/measure.py` (FR-023)
- [x] T003 [P] Add a `mise run test:measure` step beside the other test steps in `.github/workflows/check.yml`
- [x] T004 Create `.apm/skills/feat/scripts/measure.py` with its module docstring (what it reads, read-only, Python 3.11 or later, standard library only) and a `main()` entry guarded by `if __name__ == "__main__"`, so T002's lint lines pass from now on

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: the pieces every story's report needs

**CRITICAL**: no user story work starts before this phase is complete

- [x] T005 In `.apm/skills/feat/scripts/measure.py` add the default weights (one dict: tokens input 1, cache_read 0.1, output 5, cache_write_1h 2, cache_write_5m 1.25; models haiku 1, sonnet 3, opus 5) and the `argparse` options of contracts/cli.md (`--project`, `--all`, `--since`, `--until`, `--session`, `--compare-since`, `--weights`, `--strict`, `-h/--help`). `--all`/`--project` and `--session`/`--compare-since` are mutually exclusive; a bad date is a message on stderr and exit 2. `--help` lists every option and ends with the default weights line `weights: input 1, cache read 0.1, output 5, cache write 1h 2, cache write 5m 1.25; haiku 1, sonnet 3, opus 5`, printed from the same dict (FR-019, plan constitution III)
- [x] T006 In `.apm/skills/feat/scripts/measure.py` add the one print-safe function that replaces every Unicode category `Cc` character (C0, DEL, C1, tab and newline included) with `?`, used for every string from a transcript or the filesystem (FR-018), and the number formats of contracts/cli.md (integers or one decimal for a median between two integers; tokens `18.2k`/`1.4M` from 10,000; shares whole percent; signed share differences `+3pp`; minutes one decimal; cost units with `,`; USD `$` and two decimals)
- [x] T007 In `.apm/skills/feat/scripts/measure.py` add discovery and repo resolution (research R7, R8, R9): projects dir `$CLAUDE_CONFIG_DIR/projects` else `~/.claude/projects`; skip a `<folder>/<session>.jsonl` unless `<session>/subagents/` holds an `agent-*.jsonl`; peek to the first record with `cwd`; from that cwd go up to the nearest existing directory, then to the first `.git`: a directory gives its parent, a `.git` file `gitdir: <path>` (relative paths from the directory holding the file) gives the main repo through `<path>/commondir`, a gitdir with no `commondir` gives the directory holding the `.git` file, no `.git` makes the cwd the repo; component-wise path equality, never a string prefix; one resolution per distinct cwd; the selected repo resolved the same way from the current directory (FR-011, FR-012)
- [x] T008 In `.apm/skills/feat/scripts/measure.py` add the session parse (contracts/transcript-records.md, research R1-R3, R13): invocation = first human-origin user message with a `/feat`, `/fix`, `/logistics:feat` or `/logistics:fix` command tag (the run's start; only later main-file records belong to the run); `resumed` when the first word of `<command-args>` (leading whitespace stripped) is `resume`; a tagged record with no `origin` leaves the run out unless it is `isCompactSummary` or `isMeta`; model calls grouped by `message.id` (usage from the last record, timestamp from the first, `<synthetic>` skipped); agents from `subagents/agent-<id>.jsonl` whose first timestamp is at or after the invocation, typed by `.meta.json` `agentType`, else the spawn naming the id, else `unknown`, `<plugin>:` prefix stripped; an agent id read from a transcript is used only if it matches `[A-Za-z0-9_-]+`, else `agent transcript missing`, and is never joined into a path. Wrap the whole parse of one session so any exception leaves it out with the fixed reason `unexpected record shape` and its text is never printed. Left-out reasons exactly: `model call without token usage`, `event without timestamp`, `unreadable line`, `agent transcript missing`, `no message origin recorded`, `unexpected record shape` (FR-004, FR-016, FR-018)
- [x] T009 Create `tests/measure/run.sh` (bash, shellcheck-clean, pattern of `tests/tracker/run.sh`): a temp dir with `config/projects/`, real repos made with `git init` and `git worktree add` (`app`, worktree `app/.claude/worktrees/wt`, `app-old`, `other`, a repo whose directory name holds a tab, `lib` whose `.git` file names a separate git dir with no `commondir`, and a deleted worktree under `app`); `CLAUDE_CONFIG_DIR`, `TZ=UTC` and git config pinned; fixture templates copied with `@ROOT@` replaced, then `chmod -R a-w`; a `run_case <name> <args>` helper that runs `python3 -I .apm/skills/feat/scripts/measure.py` from a repo, replaces the temp path with `@ROOT@`, compares stdout and the exit code to `tests/measure/expected/<name>.txt`, prints `ok <case>` or `FAIL <case>: <why>` with the output, and checks that neither stdout nor stderr of any case contains `SECRET-` (FR-022, SC-004)

**Checkpoint**: the script parses and the harness runs; story phases can start

---

## Phase 3: User Story 1 - See what my runs cost and where the time goes (Priority: P1) MVP

**Goal**: one command in a repo prints, per skill, the medians over finished runs: coordinator call kinds and contexts, cost shares, agent figures, wall-clock split, first-request breakdown, tokens and cost units.

**Independent Test**: `report` case: run the script from `app` on the fixture transcripts and compare with the hand-computed golden file.

### Tests for User Story 1

- [x] T010 [P] [US1] Write the `report` fixtures under `tests/measure/fixtures/projects/` (JSONL templates plus `.meta.json`; hand-computed values in a comment beside each run): finished `/feat` runs and a finished `/fix` run with known numbers of spawning, chore and text-only coordinator calls; a plain and a `logistics:`-prefixed invocation; a parallel-agent run with user answers; work before the invocation (an earlier command and agent) that must not count; a message id with growing usage records (the last counts); one agent type with no recorded first request (`not recorded`); a `worktree` session of `app` stored in another folder and a deleted-worktree session; an `app-old` session (not counted); an unfinished run (no shipper) and a `resume` run (listed apart); not-a-run sessions (`/brief` with a `feat-brief-reviewer`, `/feat` with no agent); an agent whose model id has no weight (listed on `unweighted models:`); a compact-summary record carrying the tag and no origin; an `api-request-shape` record for the first-request parts
- [x] T011 [US1] Write `tests/measure/expected/report.txt` by hand from T010's fixtures (header, per-skill blocks, lists of unfinished and resumed runs), the wall-clock parts summing to the run duration (SC-008)
- [x] T012 [US1] Add the `report` case (from `app`, no options) to `tests/measure/run.sh`

### Implementation for User Story 1

- [x] T013 [US1] In `.apm/skills/feat/scripts/measure.py` compute the per-run figures of data-model.md: coordinator calls by kind (`spawn` if any tool is `Agent` or `Task`, else `chore` if any tool, else `text`), context = `input + cache_write_5m + cache_write_1h + cache_read` (first call, median and max over its calls), failed tool calls by tool, tokens by kind (a `cache_creation_input_tokens` without breakdown counts as `cache_write_5m`), cost units with the default weights, run units = coordinator units + all agents' units, shares of the run's total (FR-005, FR-008, FR-014), user answers = human-origin user records after the invocation
- [x] T014 [US1] In `.apm/skills/feat/scripts/measure.py` add the coordinator timeline (research R4, FR-006): start = invocation timestamp; each gap between two events goes to what ends it (assistant record: coordinator thinking; `tool_result`: coordinator tools, except an `Agent`/`Task` result that is the agent's report, neither `status: "async_launched"` nor an error, and `origin.kind == "peer"`: agents working; `task-notification`: coordinator tools; `human`: waiting for the user); duration = last event - start so the four parts add up to it and parallel agents count once; and the agent timeline (R5, FR-007): a gap ended by an assistant record is model time, by a `tool_result` tool time, anything else not counted
- [x] T015 [US1] In `.apm/skills/feat/scripts/measure.py` parse the first-request breakdown (research R6) only for the first spawn of each agent type in the run: tool schemas by name, skills listing, system prompt (includes Claude Code's own), instruction files (count and characters); an agent type whose transcripts do not record it is `not recorded`, not left out
- [x] T016 [US1] In `.apm/skills/feat/scripts/measure.py` classify each run `resumed` (invocation args start with `resume`, whatever else), else `finished` (a `feat-shipper` agent was spawned), else `unfinished`, and aggregate per skill (research R10): `statistics.median` over finished non-resumed runs for every figure; per-agent-type figures over the runs where the type appears, with that count; failed tool calls as the total per tool over those runs with their number, not a median
- [x] T017 [US1] In `.apm/skills/feat/scripts/measure.py` render the header (`measure: /feat and /fix runs in <repo path> and its worktrees`, `from <projects dir>`, `runs: <n> counted (<f> finished, <u> unfinished, <r> resumed), <l> left out`, the weights line), the per-skill blocks `== /feat: <f> finished runs (medians) ==` with sections Coordinator, Agents, Wall clock, First request, Tokens exactly as contracts/cli.md orders and words them (skill with no run omitted; agents sorted by cost share descending then name), and the `unfinished runs (not in the medians):` and `resumed runs (not in the medians):` lists with session id, date, skill, repo path
- [x] T018 [US1] In `.apm/skills/feat/scripts/measure.py` wire `main()` for the default selection (the repo of the current directory including its worktrees, all dates) end to end, so `report` passes; exit 0

**Checkpoint**: US1 works alone; this is the MVP

---

## Phase 4: User Story 2 - Judge whether a change helped (Priority: P1)

**Goal**: `--compare-since <date>` prints medians before and since a date with the difference and both counts.

**Independent Test**: fixtures with two runs before a date and two since give counts 2 and 2.

### Tests for User Story 2

- [x] T019 [P] [US2] Write the `compare` fixtures under `tests/measure/fixtures/projects/` (two finished runs before a date and two since, in `app`, hand-computed medians and differences in a comment), plus the date used by `compare-empty` (no run before it)
- [x] T020 [P] [US2] Write `tests/measure/expected/compare.txt` and `tests/measure/expected/compare-empty.txt` by hand (SC-002, SC-006)

### Implementation for User Story 2

- [x] T021 [US2] In `.apm/skills/feat/scripts/measure.py` add `--compare-since D` (runs with `date < D` before, `date >= D` since; `--since`/`--until` apply first): same aggregation per side, difference = since - before, heading `== /feat: before <D>: <n> runs | since <D>: <m> runs ==`, columns `before`, `since`, `diff`; an empty side prints `no runs` with its diff column empty; a type, tool schema or failed tool on one side only prints `-` on the other side with an empty diff; failed tool calls show each side's total and runs with an empty diff; share differences signed whole percentage points; no statistical wording (FR-010)
- [x] T022 [US2] Add the `compare` and `compare-empty` cases to `tests/measure/run.sh`, each also checking the output contains none of `significant`, `confidence` (no statistical claim)

**Checkpoint**: US1 and US2 both work

---

## Phase 5: User Story 3 - Choose which runs are counted (Priority: P2)

**Goal**: `--project`, `--all`, `--since`, `--until`, correct repo attribution, empty selections.

**Independent Test**: fixtures with sessions in `app`, its worktree, `app-old`, `other`, the tab repo and `lib`.

### Tests for User Story 3

- [x] T023 [P] [US3] Write the fixtures `other` (three finished runs, the ones before and after the window not counted by `--project other --since ... --until ...`), the tab repo (name with a tab) and `lib` (separate git dir, its own repo) under `tests/measure/fixtures/projects/`
- [x] T024 [P] [US3] Write `tests/measure/expected/project.txt`, `all.txt` and `no-runs.txt` by hand (the tab repo printed with `?`)

### Implementation for User Story 3

- [x] T025 [US3] In `.apm/skills/feat/scripts/measure.py` add selection: `--project PATH` resolved like the current directory; `--since`/`--until` inclusive on the invocation's local date; `--all` with one block per repo sorted by path (`## <repo path>`) then `## all repos`, the unfinished, resumed and left-out lists printed once at the end; the header wording `on every repo (--all)`; and with `--compare-since` the same layout in each repo block and the total (FR-010, FR-011)
- [x] T026 [US3] In `.apm/skills/feat/scripts/measure.py` print `no runs found in <projects dir> for <repo path>` (or `for any repo`, `for session <id>`), plus `, <since> to <until>` when bounded, and exit 0 when the selection holds no run (FR-013, SC-006)
- [x] T027 [US3] Add the cases `project` (`--project other --since ... --until ...`), `all` (`--all`) and `no-runs` (an empty selection) to `tests/measure/run.sh`

---

## Phase 6: User Story 4 - Look at one run in detail (Priority: P2)

**Goal**: `--session <id>` prints one run's own values, or its left-out line.

**Independent Test**: `--session <id>` on a `report` fixture matches the hand-computed values.

- [x] T028 [US4] In `.apm/skills/feat/scripts/measure.py` add `--session ID`: search every project folder, ignore `--project`/`--all`; for a counted run print the header `session <id>` and its one skill block headed `== /feat run <id>, <date>, finished|unfinished|resumed ==` with the same figures as the default report, single values (the Agents table has no `runs` column and `spawns` instead of `spawns/run`; `failed tool calls` without a total; as in contracts/cli.md); an unknown id or a non-run prints the `no runs found ... for session <id>` line; a left-out run prints the header and its `left out:` row (session id, date, reason, Claude Code version), exit 0, or 1 with `--strict` (FR-009)
- [x] T029 [P] [US4] Write `tests/measure/expected/session.txt` by hand for one `report` fixture run
- [x] T030 [US4] Add the `session` case (`--session <id of a finished report run>`) to `tests/measure/run.sh`

---

## Phase 7: User Story 5 - Weights and optional money (Priority: P2)

**Goal**: cost units from default or overridden weights; dollars only with user-supplied prices.

**Independent Test**: same fixtures with and without an override file, with and without prices.

### Tests for User Story 5

- [x] T031 [P] [US5] Write `tests/measure/fixtures/weights/*.json`: an override without prices, one with `prices`, and the invalid files (`true` as a weight, `NaN`, `Infinity`, `1e400`, `-1`, a string, an unknown section, an unknown `tokens` key, not JSON; shapes per contracts/weights-file.md) (the unknown-model run is already in T010's `report` fixtures)
- [x] T032 [P] [US5] Write `tests/measure/expected/weights.txt` and `tests/measure/expected/weights-prices.txt` by hand

### Implementation for User Story 5

- [x] T033 [US5] In `.apm/skills/feat/scripts/measure.py` add `--weights FILE` per contracts/weights-file.md: merge over the defaults; read with `json.load(..., parse_constant=...)` raising on `NaN`, `Infinity` and `-Infinity`; a value is valid only if it is an `int` or `float`, not a `bool`, finite (`math.isfinite`, which catches `1e400`) and `>= 0`; anything else (also an unknown section or `tokens` key, not JSON, unreadable file) is a message on stderr, exit 2, nothing on stdout. Model lookup: key equal to the id, else a key equal to one `-`-separated part (`claude-opus-5-5` matches `opus`), else the highest model weight in effect with the model named on `unweighted models: <model id> (weighted as <w>), ...`. With `prices` (USD per million input tokens per model key): the weights line is followed by `prices: <model> <usd>/Mtok, ...`, a `USD` row appears in Tokens (USD = sum of tokens[k] x weight[k] x price / 1,000,000), a model without a price uses the highest price given and is named on `unpriced models: ...`; without prices no money is ever printed (FR-014, FR-015)
- [x] T034 [US5] Add to `tests/measure/run.sh` the cases `weights` and `weights-prices`, and the error cases (one per invalid file of T031: exit 2, stderr message, empty stdout), and a check that the default `report` output contains no `$` and no `USD`

---

## Phase 8: User Story 6 - Trust the numbers when transcripts are odd (Priority: P2)

**Goal**: odd runs are left out whole with reason and version, others reported; `--strict`; unknown record types ignored.

**Independent Test**: fixtures with a model call lacking usage, a timestamp-less event, a wrong-typed field and an invalid agent id.

### Tests for User Story 6

- [x] T035 [P] [US6] Write the `left-out` fixtures: runs without token usage, without a timestamp, with an unparseable JSON line, with a wrong-typed field holding a `SECRET-` value (`unexpected record shape`), with a spawn result naming agent id `../x` (`agent transcript missing`), with an invocation lacking `origin`; and a copy of a `report` session with an unknown record type appended
- [x] T036 [P] [US6] Write `tests/measure/expected/left-out.txt` by hand (each row: session id, date, reason, `(Claude Code <version>|unknown)`, repo path; counted and left-out counts in the header)

### Implementation for User Story 6

- [x] T037 [US6] In `.apm/skills/feat/scripts/measure.py` finish the left-out handling: unused record types ignored; every reason of T008 produced by its own condition (a model call without `usage` or a parseable `timestamp`, an event without a parseable timestamp, an unparseable line, a missing or invalid agent, no message origin, any other exception); the `left out:` list printed once per command; `--strict` makes the exit status 1 when any run in the selection was left out and 0 otherwise; the header always states counted and left-out counts (FR-016, FR-017); nothing of a record or an error text is printed (FR-018)
- [x] T038 [US6] Add to `tests/measure/run.sh` the cases `left-out` (exit 0), `left-out` with `--strict` (exit 1, same stdout), and `unknown-record` (output byte-identical to `report`'s)
- [x] T039 [US4] Add to `tests/measure/run.sh` the `--session <id of a left-out run>` check: its `left out:` row, exit 0, then exit 1 with `--strict` (no golden file); needs T035 and T028
- [x] T040 [US6] Add to `tests/measure/run.sh` the static checks (a test, not a lint grep): `measure.py` imports only the allowlist (`argparse`, `json`, `math`, `os`, `re`, `statistics`, `datetime`, `collections`, `sys`, plus `unicodedata` if used), no `socket`, `urllib` or `http` import, no `open(` with a write or append mode (FR-003); fixtures read-only so runs succeed on read-only files

---

## Phase 9: User Story 7 - Learn to install, run and read it (Priority: P3)

**Goal**: docs, install prerequisite and `install.sh check` note.

**Independent Test**: pages exist with front matter; `install.sh check` with Python 3.11 or later failing and passing.

- [x] T041 [P] [US7] Create `docs/measure.md` (`title: Measure`, `weight: 35`): the command per install route (APM user-level `~/.claude/skills/feat/scripts/measure.py`, also where the dev `install.sh` puts it; APM project-level `.claude/skills/feat/scripts/measure.py`; plugin `~/.claude/plugins/cache/logistics/logistics/<version>/.apm/skills/feat/scripts/measure.py`; clone `mise run measure -- ...`), Python 3.11 or later, each option, how to read each number (a run starts at its invocation; failed tool calls are totals), the weights and prices file, what "left out", "unfinished" and "resumed" mean, the Claude Code versions tested (2.1.304 to 2.1.328), the limits (listed in plan.md Docs), the default weights line exactly as `--help` prints it, and a "Before sharing the output" paragraph (the output holds repo paths, the home directory and session ids; post only the all-repos block's figures, without the per-repo blocks or the unfinished, resumed and left-out lists). Link repo files outside `docs/` with absolute GitHub URLs (FR-020)
- [x] T042 [P] [US7] Add a `## Baseline` section to `docs/workflow.md` with its date, the default weights line and the same "before sharing" note, and a marked line where the maintainer fills the figures from the all-repos block of a real `--all` run (not a task)
- [x] T043 [P] [US7] In `docs/install.md` add a Prerequisites row "Python 3.11 or later, for `measure.py` only" and list the new `note` line in section 4 (`install.sh check`)
- [x] T044 [US7] In `install.sh` `check`, after the tools, run `python3 -c 'import sys; sys.exit(sys.version_info < (3, 11))'` and print `ok       python3 3.11 or later (measure.py)` or `note     python3 3.11 or later not found (needed by measure.py only: docs/measure.md)`; it never sets `missing` and never changes the exit status (FR-021)
- [x] T045 [US7] Create the stubs `tests/measure/bin/claude`, `tests/measure/bin/gh` (so `gh auth status` stays offline) and `tests/measure/bin/python3` (failing or passing by an env var), executable and shellcheck-clean, and add the `install-check` case to `tests/measure/run.sh`: with the `python3` stub failing a `note` line names Python 3.11 and the exit code equals the one with the stub succeeding
- [x] T046 [US7] Add to `tests/measure/run.sh` the `help` case (`--help`, golden `tests/measure/expected/help.txt` listing every option and ending with the default weights line) and a check that `docs/measure.md` contains that default weights line and begins with `title` and `weight` front matter

---

## Phase 10: Polish & Cross-Cutting Concerns

- [x] T047 [P] Add a `docs/measure.md` row to the docs table in `README.md`
- [x] T048 [P] Name `mise run test:measure` in the checks list of `CONTRIBUTING.md`
- [x] T049 [P] Amend principle V in `.specify/memory/constitution.md`: its third sentence becomes "Scripts MUST be bash, `shellcheck`-clean and covered by offline tests under `tests/`; where bash would have to aggregate JSON, a script MAY instead be Python 3.11 or later using the standard library only, compiled by `mise run lint` and covered by offline tests under `tests/` the same way."; version 1.1.0 to 1.2.0 (MINOR: guidance materially expanded), `Last Amended` set to the day of the change, and the sync impact report updated as the file's convention asks
- [x] T050 [P] In `.claude/CLAUDE.md` update the Shell line to match T049: `measure.py` is the one Python script, Python 3.11 or later and standard library only; `mise run lint` compiles and syntax-checks it and `mise run test:measure` tests it
- [x] T051 Run `mise run lint`, `mise run test:apm`, `mise run test:tracker`, `mise run test:spec-number` and `mise run test:measure`; fix any failure at its cause
- [x] T052 Run `mise run measure -- --help` in the checkout, and the quickstart.md offline scenarios against the table in quickstart.md (spec to case); confirm no case needed a real transcript

---

## Dependencies & Execution Order

### Phase Dependencies

- Setup (T001-T004): T002 after T001 (same file); T004 before the lint in T002 can pass
- Foundational (T005-T009): after Setup; T005-T008 in order (one file); T009 independent of them
- User stories: after Foundational. US1 first (MVP). US2 needs US1's aggregation and rendering (T016, T017). US3 needs US1. US4 needs US1 (T013-T017). US5 touches the cost computation of T013 and the header of T017. US6 finishes what T008 started. US7 needs the final option list and weights line (T005) and the case runner (T009)
- Polish after the stories; T051 last but one, T052 last

### Cross-story notes

- T049 amends constitution principle V (scripts MUST be bash) so that `measure.py` (T004) conforms; both land in the same PR, and nothing is committed before phase 8
- T039 is a US4 check placed in the US6 phase because it needs the left-out fixtures of T035
- Script tasks in `measure.py` (T004-T008, T013-T018, T021, T025, T026, T028, T033, T037) never run in parallel; fixtures, golden files and docs marked [P] do

### Parallel Opportunities

- Fixtures and golden files of different stories (T010, T019, T023, T031, T035) can be written while the script is built
- T041, T042, T043 (docs) in parallel; T047-T050 in parallel

### Parallel Example: User Story 1

```text
Task: "Write the report fixtures under tests/measure/fixtures/projects/"   (T010)
Task: "Add the default weights and argparse options in measure.py"         (T005)
```

---

## Implementation Strategy

### MVP First (User Story 1 only)

1. Phase 1 and 2 (T001-T009)
2. Phase 3 (T010-T018): `mise run measure` prints the medians for the current repo; `report` passes
3. Stop and validate: `mise run test:measure`, `mise run lint`

### Incremental Delivery

US2 (comparison), then US3 (selection), US4 (one session), US5 (weights), US6 (robustness), US7 (docs and install note), then Polish; each adds cases to `tests/measure/run.sh` without breaking earlier ones.

---

## Notes

- Hand-compute expected values before writing the code that produces them (SC-001)
- Never commit from a task: the workflow commits in phase 8
- No task reads a real transcript; every fixture is synthetic
