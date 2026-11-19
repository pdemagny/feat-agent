# Research: Measure what a /feat or /fix run costs

Each decision below was checked against the structure (record types, keys,
value kinds, counts; never content) of real transcripts written by Claude
Code 2.1.304 to 2.1.328. The shapes relied on are in
[contracts/transcript-records.md](contracts/transcript-records.md).

## R1. Recognising a `/feat` or `/fix` invocation (left to planning by the spec)

- **Decision**: a coordinator `user` record that is not `isMeta`, whose
  `origin.kind` is `"human"`, and whose text (string content, or its `text`
  blocks) contains `<command-name>` followed by `/feat`, `/fix`,
  `/logistics:feat` or `/logistics:fix` (leading slash optional) and
  `</command-name>`. The first such record gives the run's skill and is the
  run's start: only records after it in file order belong to the run, and
  its timestamp gives the run's date and the timeline's start (FR-004,
  FR-006). Its `<command-args>…</command-args>` text, leading whitespace
  stripped, is read for one thing only: a first word `resume` marks the run
  resumed (`/feat resume`, `/fix resume`); the arguments are never printed.
  A record with the tag but no `origin` at all makes the session a left-out
  run ("no message origin recorded"), so an older format shows instead of
  vanishing; `isCompactSummary` and `isMeta` records are ignored by that
  rule (a compact summary may quote the tag).
- **Rationale**: typed skill commands carry `origin: {"kind": "human"}` and
  the tag; local commands (`/clear`, `/model`) carry the tag without an
  origin, and agent reports carry `origin.kind == "peer"`, so neither can be
  taken for an invocation. Matching the exact tag avoids text that merely
  mentions `/feat`.
- **Alternatives considered**: the `Skill` tool call (the model can call it
  without the user invoking anything; the spec ties a run to the user's
  invocation); a substring search for `/feat` (matches prose and arguments).

## R2. Model calls

- **Decision**: one model call per distinct `message.id` among `assistant`
  records; its usage is the last record's of the id (identical on every
  record in the sessions checked, but a streamed call could write growing
  counts), its model and timestamp the first record's; its tool calls are the
  union of their `tool_use` blocks. Records whose `message.model` is `<synthetic>` or that
  carry `isApiErrorMessage` are not model calls. A model call with no `usage`
  leaves the run out.
- **Rationale**: Claude Code writes one record per content block; 6,055 of
  10,290 checked records repeat an id with the same usage. Counting records
  would inflate calls and tokens about 2.5 times.
- **Alternatives considered**: `requestId` (also shared, but `message.id` is
  what the API returns per call); summing usage per record (double counts).

## R3. Agents and their types

- **Decision**: a run's agents are the `subagents/agent-<id>.jsonl` files of
  the session (all spawn depths) whose first timestamp is at or after the
  invocation's. An agent id read from a transcript
  (`toolUseResult.agentId`, `origin.from`) is used only if it matches
  `[A-Za-z0-9_-]+`; any other counts as "agent transcript missing" and is
  never joined into a path. Type: the `.meta.json` `agentType`, else the
  `subagent_type` of the coordinator `Agent`/`Task` call whose result's
  `toolUseResult.agentId` is `<id>`, else `unknown`. A `<plugin>:` prefix is
  stripped (`logistics:feat-planner` → `feat-planner`). A coordinator spawn
  whose result names an agent id with no file leaves the run out. A spawn call
  that failed (error result, no agent id) is a failed tool call of the
  coordinator (tool `Agent`), not an agent.
- **Rationale**: every agent id in a spawn result matched one file in the
  sessions checked; one spawn per hundred had no agent id (refused spawn).
  Files also cover agents spawned by agents.
- **Alternatives considered**: counting spawn calls only (misses nested
  agents, counts refused spawns).

## R4. The coordinator timeline (FR-006)

- **Decision**: events and their class: `assistant` record → coordinator
  thinking; `tool_result` → coordinator tools, except the result of an
  `Agent`/`Task` call that is the agent's report (its `toolUseResult` is not
  `status: "async_launched"` and the block is not `is_error`) → agents
  working; `origin.kind == "peer"` → agents working, although the record is
  `isMeta`; `origin.kind == "task-notification"` → agents working when its
  `<task-id>` names one of the session's agent transcripts, else coordinator
  tools; `origin.kind == "human"` → waiting for the user. Every other record
  (attachments, system, other meta records and compact summaries, local
  command output, queued commands) ends no gap. Start = the
  invocation record's timestamp (R1); duration = last event − start.
- **Rationale**: in the versions checked, agents run in the background: the
  spawn's tool result says `async_launched` at once, and the report arrives
  later as a `user` record with `origin.kind == "peer"` naming the agent. An
  older synchronous spawn returns the report as the tool result itself, hence
  the exception. A background task finishing arrives as a
  `task-notification`. Corrected on 2026-11-19 against 158 real sessions,
  structure only: every report record is `isMeta`, and 591 of 598
  notifications name an agent, 217 of them before any report record; counting
  them as the coordinator's own tool put a median 10 minutes of agent time
  under coordinator tools, and skipping meta records put all of it under
  coordinator thinking.
  Gaps are attributed to what ends them, so the parts sum to the duration by
  construction.
- **Alternatives considered**: summing agent durations (counts parallel agents
  twice; rejected by the spec); `system` `turn_duration` records (cover only
  turns, not idle time, and not every version writes them).

## R5. An agent's time split (FR-007)

- **Decision**: in the agent's own file, every `user` and `assistant` record
  is a boundary; the gap since the previous boundary is model time when ended
  by an `assistant` record, tool time when ended by a `user` record with a
  `tool_result`, and not counted otherwise (spawn prompt, a `SendMessage`
  continuation after the agent reported).
- **Rationale**: same rule as R4 on the agent's transcript, while the idle
  time between a report and a continuation goes to neither.

## R6. What an agent's first request is made of

- **Decision**: parsed only for the first spawn of each agent type in a run
  (by its file's first timestamp): later spawns of a type carry the same
  shape, and their `api-request-shape` records are the largest lines of the
  agent files. From that agent's own file, when present:
  - tool schemas: `api-request-shape` → `shape.tools[]`, each tool's size as
    the length of its compact JSON, listed by `name`;
  - skills listing: the `skill_listing` attachment's `content` length;
  - system prompt: the summed `text` length of `shape.system[]` (Claude Code's
    own prompt and the agent's definition, which the record does not
    separate);
  - instruction files: the summed `content` length of the `instructions`
    attachment's `files[]`, and their count (never their paths).
  Sizes are characters, with each part's share of their total. Without an
  `api-request-shape` record the agent type's line says "not recorded".
- **Rationale**: these are the only records holding the parts; no record gives
  per-part tokens, so characters are the honest unit, and the first call's
  context in tokens is reported beside them.
- **Alternatives considered**: estimating tokens as characters / 4 (a made-up
  number in a tool meant to judge changes).

## R7. Attributing a session to a repo (FR-012)

- **Decision**: from the first recorded `cwd`: go up to the nearest existing
  directory, then up to the first `.git`. A `.git` directory: the repo is its
  parent. A `.git` file (`gitdir: <path>`, a relative `<path>` taken from the
  directory holding the file): read `<path>/commondir` (relative to
  `<path>`), the main repo is the parent of that common dir; with no
  `commondir` (a submodule, a separate git dir), the repo is the directory
  holding the `.git` file. No `.git` found: the repo is the cwd itself. The
  target repo (current directory or `--project`) is resolved the same way,
  so running from a worktree measures its main repo. Compared as whole paths
  after `os.path.realpath`. The result is cached per distinct `cwd`: most
  sessions of a repo share a handful of them.
- **Rationale**: needs no subprocess and no folder name; a worktree of the
  repo, existing or deleted (`<repo>/.claude/worktrees/<name>` resolves
  through its existing parents), lands on the repo; a sibling whose name
  starts the same has its own `.git` and never matches.
- **Alternatives considered**: `git rev-parse` (a subprocess per session, and
  fails on deleted worktrees); path prefix (matches `app-old` for `app`); the
  `worktree-state` record (only in sessions that called `EnterWorktree`).
- **Limit**: a worktree outside the repo's directory that no longer exists
  resolves to itself (its own block in `--all`); documented.

## R8. Where transcripts are read

- **Decision**: `$CLAUDE_CONFIG_DIR/projects` when the variable is set, else
  `~/.claude/projects`. The tests set it to a temp dir.
- **Rationale**: Claude Code's own setting for its config dir; no test-only
  option in the public interface.

## R9. Reading little on a large history

- **Decision**: per session file: skip at once unless `<session>/subagents/`
  holds an `agent-*.jsonl`; read lines until the first `cwd`, and stop there
  when the repo is outside the selection; check raw lines for a command tag
  before JSON-parsing the file in full; the date window applies to the
  invocation's date once the tag is found; read agent files only for runs.
- **Rationale**: a measured history of ~2 GB holds ~400 session files and
  ~1,600 agent files; most sessions are not runs.

## R10. Medians

- **Decision**: per run, one value per figure; per-spawn figures of an agent
  type (calls per spawn, first-call context, model and tool minutes) are the
  mean over that run's spawns of the type, and its first-request sizes are
  its first spawn's (R6). The report shows the median over the finished,
  non-resumed runs of the skill; an agent type's figures are medians over the
  runs where it appears, with that number of runs. `statistics.median` (mean
  of the two middle values for an even count). One exception: failed tool
  calls by tool are the total over those runs, printed with the number of
  runs, since a median of a rare count is nearly always 0.
- **Rationale**: "medians over the selected runs" (FR-008); a type absent from
  most runs (`feat-design-reviewer` on small runs) would otherwise show a
  median of 0.

## R11. Weights file and prices

- **Decision**: JSON with optional `tokens`, `models` and `prices` objects
  ([contracts/weights-file.md](contracts/weights-file.md)), merged over the
  defaults. `prices` maps a model key to USD per million input tokens; the
  token weights scale the other kinds (output costs 5 times the input price
  with the default weights). Unknown keys and any value that is not an
  `int` or `float`, is a `bool`, is not finite or is negative: error, exit 2.
  The file is parsed with `parse_constant` raising, so `NaN`, `Infinity` and
  `-Infinity` (which `json` accepts by default) are refused, and
  `math.isfinite` catches an overflowing literal such as `1e400`.
- **Rationale**: one price per model is all a user needs to look up; a typo
  fails loudly instead of silently changing every number.

## R12. Unknown models and missing prices

- **Decision**: a model with no weight is weighted as the highest model weight
  in effect (5 with the defaults) and named in the report; with `prices`
  given, a model with no price uses the highest price given and is named.

## R13. Unparseable lines

- **Decision**: a line of a run's files that is not valid JSON leaves the run
  out ("unreadable line"). A record that parses but has a type the script does
  not use is ignored.
- **Rationale**: a lost line may be a model call; the spec never mixes good
  and bad data in one number.

## R14. `mise run measure --help`

- **Finding**: mise (2026.9.17) answers `--help` and `-h` after a task name
  itself ("This task does not accept any arguments"); every other argument is
  appended to the task's command. `mise run measure -- --help` reaches the
  script. A `usage` spec makes mise parse and re-quote the arguments, which
  breaks them.
- **Decision**: plain `run` task; docs and acceptance use `mise run measure --
  --help` (assumption A1, accepted at the gate; FR-002 and US7 say so).

## R15. Test design

- **Decision**: bash runner like `tests/tracker/run.sh` (`new_case`, `fail`,
  `expect_rc`, `ok`); JSONL templates with `@ROOT@`, made concrete with `sed`
  into a temp dir; real git repos and a worktree from `git init` and `git
  worktree add` with `GIT_CONFIG_GLOBAL=/dev/null` (as
  `tests/spec-number/run.sh`); `TZ=UTC`; fixtures `chmod -R a-w`; whole-output
  golden files with the temp path replaced by `@ROOT@`; hand arithmetic for
  the acceptance figures in comments beside the fixtures.
- **Rationale**: golden files freeze the public output format (FR-019) and
  check every figure at once; the comments keep the key numbers reviewable
  instead of trusted from the script.

## R16. Python 3.11

- **Decision**: Python 3.11 or later (the user's decision at the design
  review gate, replacing the brief's 3.9). 3.11 syntax and standard library
  are allowed (`match`, `X | Y`); `datetime.fromisoformat` reads the
  transcripts' `…Z` timestamps with any number of fractional digits as they
  are, and a value it refuses counts as "no timestamp". Local dates via
  `datetime.astimezone()`. The floor is checked by `mise run lint` with
  `ast.parse(…, feature_version=(3, 11))` on `measure.py` (syntax only; a
  newer standard-library call is left to review), with no extra interpreter
  in `mise.toml`.

## R17. Constitution principle V

- **Finding**: "Scripts MUST be bash" is broken by a Python script, which the
  brief decided (bash with `jq` rejected).
- **Decision**: amend principle V in this PR (assumption A2, accepted at the
  gate): a Python 3.11 or later standard-library script is allowed where
  bash would have to aggregate JSON, with the same lint and offline-test
  duty; constitution 1.2.0 (MINOR), and the matching line in
  `.claude/CLAUDE.md`. The plan's Constitution Check gives the wording.
