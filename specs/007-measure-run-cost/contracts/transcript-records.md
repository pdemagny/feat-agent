# Contract: the Claude Code records `measure.py` reads

Claude Code's transcript format is not documented; this is what the script
depends on, checked (record types, keys and value kinds only) on transcripts
written by Claude Code 2.1.304 to 2.1.328. Anything else is ignored. A
change here shows as left-out runs (FR-016), and `docs/measure.md` names the
versions tested. The examples are synthetic.

## Layout

```text
<projects dir>/<folder>/<session>.jsonl                       # the coordinator
<projects dir>/<folder>/<session>/subagents/agent-<id>.jsonl   # one per agent
<projects dir>/<folder>/<session>/subagents/agent-<id>.meta.json
```

`<projects dir>` is `$CLAUDE_CONFIG_DIR/projects`, else `~/.claude/projects`.
`<folder>` is never read for meaning (FR-012). One JSON object per line.

## Fields common to the records used

`type`, `timestamp` (ISO 8601 UTC, `…Z`), `cwd`, `version`, `sessionId`,
`isSidechain` (main-file records with `true` are skipped), `isMeta`,
`isCompactSummary`.

A field of an unexpected type (a string where an object is expected, a
number where a list is) leaves the run out as `unexpected record shape`;
the field's value is never printed.

Records without `timestamp` exist (`mode`, `permission-mode`, `ai-title`,
`worktree-state`, …): they are not used, so they never cause a left-out run.

## `assistant`: a model call, one record per content block

```json
{"type":"assistant","timestamp":"2026-03-02T10:00:05.000Z","cwd":"/home/u/Projects/my-app","version":"2.1.320",
 "message":{"id":"msg_01","model":"claude-opus-5-5","content":[{"type":"tool_use","id":"toolu_01","name":"Agent","input":{"subagent_type":"feat-planner"}}],
 "usage":{"input_tokens":6,"cache_creation_input_tokens":1200,"cache_read_input_tokens":18000,"output_tokens":350,
          "cache_creation":{"ephemeral_5m_input_tokens":0,"ephemeral_1h_input_tokens":1200}}}}
```

- Records sharing `message.id` are one call; their `usage` was identical in
  the versions checked, and the last record's is the one used (the first
  record's `timestamp`).
- `message.model == "<synthetic>"` or `isApiErrorMessage: true`: not a call.
- `content[]` blocks used: `tool_use` (`id`, `name`, `input.subagent_type`
  for `Agent`/`Task`). `text` and `thinking` only mark a text-only call; their
  text is never read into output.

## `user`

Three shapes are used:

1. A typed message: `message.content` a string (or `text` blocks), `origin:
   {"kind":"human"}`. An invocation carries
   `<command-name>/feat</command-name>` (or `/fix`, `/logistics:feat`,
   `/logistics:fix`) and `<command-args>…</command-args>`; of the arguments,
   only whether the first word is `resume` is used. The first invocation is
   the run's start: earlier main-file records are not part of the run.
2. An agent's report: `origin: {"kind":"peer","name":"feat-planner","from":"<agent id>"}`.
3. A tool result: `message.content[]` with `{"type":"tool_result","tool_use_id":"toolu_01","is_error":true?}`
   and, beside it, `toolUseResult`; for an `Agent` call,
   `toolUseResult.agentId` names the agent file and `toolUseResult.status` is
   `"async_launched"` when the report comes later as shape 2.

An agent id from `toolUseResult.agentId` or `origin.from` is used only if it
matches `[A-Za-z0-9_-]+`; any other is treated as a missing agent transcript.

Also read: `origin: {"kind":"task-notification"}` (a background task ended).
User records with no `origin` (local commands, their output, compact
summaries) end no gap and invoke nothing; a tagged record with no `origin`
leaves the run out unless it is `isCompactSummary` or `isMeta`.

## Agent files

- `agent-<id>.jsonl`: the same `assistant` and `user` records for the agent.
- `agent-<id>.meta.json`: `{"agentType":"feat-planner","model":"opus","effort":"high","toolUseId":"toolu_01",…}`;
  only `agentType` is used (model comes from the calls).
- An agent file belongs to the run when its first timestamp is at or after
  the invocation's.
- First request, when recorded (absent on some versions → "not recorded"),
  read only from the first agent file of each type in a run:
  - `{"type":"api-request-shape","shape":{"system":[{"type":"text","text":"…"}],"tools":[{"name":"Bash","description":"…","input_schema":{…}}]}}`:
    the first one in the file;
  - `{"type":"attachment","attachment":{"type":"skill_listing","content":"…","skillCount":81}}`;
  - `{"type":"attachment","attachment":{"type":"instructions","files":[{"path":"…","type":"…","content":"…"}]}}`.
  Only lengths and tool names are used.

## Not used

`api-request`, `api-request-blob`, `cost-state`, `system` (`turn_duration`,
`away_summary`, …), `queue-operation`, other `attachment` types,
`file-history-*`, `worktree-state`, `relocated`, `pr-link`, and any type
added later.
