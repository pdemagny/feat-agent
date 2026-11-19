# Data model: Measure what a /feat or /fix run costs

In-memory only; nothing is stored. Field names are descriptive, not a
required spelling. Record shapes read from transcripts:
[contracts/transcript-records.md](contracts/transcript-records.md).

## Session (discovered)

| Field | From |
| --- | --- |
| `session_id` | file name `<session>.jsonl` |
| `path` | `<projects dir>/<folder>/<session>.jsonl` |
| `cwd` | first record carrying `cwd` |
| `repo` | resolved from `cwd` (research R7), cached per distinct `cwd` |
| `version` | first record carrying `version` |
| `first_time` | first record carrying `timestamp`; used only for a LeftOut's date when no invocation was read |

A session becomes a **Run**, a **LeftOut**, or nothing (not a run). Any
exception while parsing a session that passed the pre-filter (research R9)
makes it a LeftOut with reason `unexpected record shape`; the exception's
text is never printed.

## Invocation

| Field | Rule |
| --- | --- |
| `record` | first human-origin coordinator `user` record carrying a `/feat`, `/fix`, `/logistics:feat` or `/logistics:fix` command tag (research R1) |
| `time` | its `timestamp`: the run's start |
| `date` | `time` in the local time zone, `YYYY-MM-DD`: the run's date |
| `skill` | `feat` or `fix` |
| `resumed` | the first word of its `<command-args>` (leading whitespace stripped) is `resume` |

Only main-file records after the invocation, in file order, belong to the
run. A tagged record with no `origin` leaves the run out (`no message origin
recorded`), unless it is `isCompactSummary` or `isMeta`.

## ModelCall

| Field | Rule |
| --- | --- |
| `id` | `message.id`; records sharing it are one call |
| `model` | `message.model` |
| `time` | timestamp of its first record |
| `tokens` | `input`, `cache_write_5m`, `cache_write_1h`, `cache_read`, `output` from the `message.usage` of its last record; a `cache_creation_input_tokens` without breakdown counts as `cache_write_5m` |
| `tool_names` | names of its `tool_use` blocks, in order |
| `kind` (coordinator only) | `spawn` if any tool is `Agent` or `Task`; else `chore` if any tool; else `text` |
| `context` | `input + cache_write_5m + cache_write_1h + cache_read` |
| `units` | Σ tokens[k] × weight[k], × model weight (see Weights) |

Validation: a call without `usage`, or whose records lack a parseable
`timestamp`, makes the run a LeftOut.

## Agent

| Field | Rule |
| --- | --- |
| `agent_id` | `agent-<id>.jsonl`; an id read from a transcript must match `[A-Za-z0-9_-]+`, else `agent transcript missing` |
| `first_time` | first timestamp of its file; the agent belongs to the run only if it is at or after the invocation's `time` |
| `type` | `.meta.json` `agentType`, else the spawn naming `<id>`, else `unknown`; `<plugin>:` prefix stripped |
| `calls` | its ModelCalls |
| `first_context` | `context` of its first call (absent if no call) |
| `model_seconds`, `tool_seconds` | research R5 |
| `first_request` | parsed only for the first Agent of each type in the run (by `first_time`): `tools: {name: chars}`, `skills_listing: chars`, `system_prompt: chars` (includes Claude Code's own), `instructions: {count, chars}`, or `None` (not recorded) |

## Run

| Field | Rule |
| --- | --- |
| `session` | the Session |
| `invocation` | the Invocation: skill, date, start, resumed |
| `status` | `resumed` if the invocation is; else `finished` if some Agent has type `feat-shipper`; else `unfinished` |
| `coordinator_calls` | ModelCalls of the main file after the invocation |
| `failed_tools` | `{tool name: count}` of coordinator `tool_result` blocks with `is_error`, after the invocation |
| `agents` | Agents at or after the invocation |
| `timeline` | seconds per part: `agents`, `user`, `thinking`, `tools`, from the invocation's `time`; `duration` = their sum |
| `user_answers` | human-origin user records after the invocation |

Requires an invocation and at least one Agent of a `feat-*` type.

## LeftOut

| Field | Rule |
| --- | --- |
| `session_id`, `date`, `repo`, `version` | from the Session and the Invocation (`date` is the invocation's, else the Session's `first_time`'s; `version` may be unknown) |
| `reason` | one of: `model call without token usage`, `event without timestamp`, `unreadable line`, `agent transcript missing`, `no message origin recorded`, `unexpected record shape` |

## RunFigures (per Run)

| Figure | Definition |
| --- | --- |
| coordinator calls: total, spawn, chore, text | counts of `coordinator_calls` by kind |
| coordinator context: first, median, max | `context` of the first call; median and max over all its calls |
| coordinator share | coordinator units / run units |
| coordinator failed tool calls | `failed_tools` |
| per agent type: spawns | number of Agents of the type |
| per agent type: calls per spawn, first context, model min, tool min | mean over the run's Agents of the type (first context over those that have one) |
| per agent type: first request | the first Agent of the type's `first_request` |
| per agent type: share | units of the type's Agents / run units |
| wall clock | `timeline` parts in minutes, and `duration` |
| user answers | `user_answers` |
| tokens by kind, units, USD | sums over every call of the run; USD only with prices |

Run units = coordinator units + all Agents' units, so the coordinator's and
the types' shares add to 100% for one run.

## Aggregate (per skill, per selection side)

Median of each RunFigure over the finished Runs (`statistics.median`;
resumed and unfinished Runs excluded), so the coordinator context's first,
median and max are each a median over runs; an agent type's figures over the
finished Runs where it appears, with that count; failed tool calls as the
total per tool over the finished Runs, with their number (not a median).
Counts: finished, unfinished, resumed, left out.

## Weights

| Field | Default |
| --- | --- |
| `tokens.input` | 1 |
| `tokens.cache_read` | 0.1 |
| `tokens.output` | 5 |
| `tokens.cache_write_1h` | 2 |
| `tokens.cache_write_5m` | 1.25 |
| `models.haiku` / `sonnet` / `opus` | 1 / 3 / 5 |
| `prices` | none |

Model lookup: exact model id key, else a key equal to one `-`-separated part
of the id, else the highest model weight in effect (model listed as
unweighted). Prices: same lookup over `prices`, else the highest price (model
listed as unpriced). USD = Σ tokens[k] × weight[k] × price / 1,000,000.
Validation: every value is an `int` or `float`, not a `bool`, finite and
≥ 0 (contracts/weights-file.md).

## Selection

| Field | From |
| --- | --- |
| `repos` | the resolved current directory, or `--project`, or every repo with a run (`--all`) |
| `since`, `until` | inclusive local dates, tested on the invocation's `date` |
| `compare_since` | runs with `date < D` before, `date ≥ D` since |
| `session` | one session id, searched in every folder |

## Printed strings

Every string from a transcript or the filesystem (repo paths, the projects
dir, session ids, model ids, tool names, agent types, versions) is printed
with each control character (Unicode category `Cc`: C0, DEL and C1, tab and
newline included) replaced by `?`.
