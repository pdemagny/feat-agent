# Contract: `measure.py` command line and output

Public interface from the first release (FR-019). Column spacing is fixed by
the golden files in `tests/measure/expected/`; labels, order, units and the
fixed lines below are the contract.

## Invocation

```text
python3 <skill dir>/scripts/measure.py [options]
mise run measure -- [options]          # in a checkout of logistics; `mise run measure -- --help` for the help
```

Needs Python 3.11 or later.

## Options

| Option | Meaning |
| --- | --- |
| *(none)* | runs of the repo the command runs in (a worktree resolves to its repo), including its worktrees |
| `--project PATH` | runs of the repo at PATH instead; PATH must be an existing directory (else exit 2) |
| `--all` | every repo on the machine: one block per repo with runs, then a total block |
| `--since YYYY-MM-DD` | runs whose date (the invocation's, local time) is on or after |
| `--until YYYY-MM-DD` | runs whose date is on or before |
| `--session ID` | that one run's figures, not medians; searched in every project folder; ignores `--project`/`--all` |
| `--compare-since YYYY-MM-DD` | medians before the date next to those since it, with the difference |
| `--weights FILE` | JSON overriding weights, optionally giving prices ([weights-file.md](weights-file.md)) |
| `--strict` | exit 1 when any run in the selection was left out |
| `-h`, `--help` | the options, and the default weights line |

`--project` and `--all` exclude each other; so do `--session` and
`--compare-since`. `--since`/`--until` apply before `--compare-since` splits.

## Exit codes

| Code | When |
| --- | --- |
| 0 | report printed, including "no runs found", comparison sides with "no runs", and a `--session` left-out line without `--strict` |
| 1 | `--strict` and at least one run left out (with `--session`: that run is left out) |
| 2 | usage error: unknown option, conflicting options, bad date, a `--project` path that is not an existing directory, unreadable or invalid weights file (message on stderr) |

## Output

Terminal text only. Only counts, tool names, agent types, model ids, session
ids, dates and repo paths appear; never a message, prompt, command, command
argument, tool output, file content, instruction-file path or error text
(FR-018). Every string taken from a transcript or the filesystem is printed
with each control character (C0, DEL and C1, tab and newline included)
and each lone surrogate replaced by `?`.

### Header (every report)

```text
measure: /feat and /fix runs in <repo path> and its worktrees     # or: on every repo (--all); or, for --session: runs, session <id>
from <projects dir>[, <since> to <until>]
runs: <n> counted (<f> finished, <u> unfinished, <r> resumed), <l> left out
weights: input 1, cache read 0.1, output 5, cache write 1h 2, cache write 5m 1.25; haiku 1, sonnet 3, opus 5
```

The weights line shows the weights in effect (after `--weights`), and
`prices: <model> <usd>/Mtok, …` on the next line when prices are given. The
same weights line, with the defaults, ends `--help` and is quoted in
`docs/measure.md`.

### Per skill block (`/feat`, then `/fix`; a skill with no run is omitted)

Heading: `== /feat: <f> finished runs (medians) ==`, or for `--session`
`== /feat run <id>, <date>, finished|unfinished|resumed ==`. Wherever a
count precedes "runs" (headings, `total over <f> runs`), a count of 1 reads
`run`: `1 finished run`, `total over 1 run`.

Sections, in order:

1. **Coordinator**: `model calls` (total), `spawn an agent`, `chores`,
   `text only`; `context, first call`, `context, median of calls`,
   `context, max of calls` (tokens: each the run's value, then the median
   over runs); `cost share` (%); `failed tool calls (total over <f> runs)`
   (`failed tool calls` for `--session`) as `<tool> <n>, …` sorted by count
   then name, or `none`.
2. **Agents**: one row per agent type, sorted by cost share descending then
   name; columns `runs` (omitted for `--session`), `spawns/run` (`spawns`
   for `--session`), `calls/spawn`, `ctx first`, `cost share`, `model min`,
   `tool min`.
3. **Wall clock**: rows `agents working`, `waiting for the user`,
   `coordinator thinking`, `coordinator tools` with minutes and share of the
   duration, then `run duration` (minutes, from the invocation to the last
   event) and `user answers`.
4. **First request** (characters, from each type's first spawn in a run):
   per agent type, `tools`, `skills listing`, `system prompt (includes Claude
   Code's own)`, `instructions (<n> files)`, `total`, each with its share;
   then `tool schemas:` `<name> <chars>` pairs, largest first. A type whose
   transcripts never record it: `<type>  not recorded`.
5. **Tokens**: `input`, `cache write`, `cache read`, `output` per run, then
   `cost units`, then `USD` only when the weights file gives prices.

Lines after the blocks, when they apply, each printed once per command
(never per side or per repo block), each run row with its date:

```text
unweighted models: <model id> (weighted as <w>), …
unpriced models: <model id> (priced as <usd>/Mtok), …
unfinished runs (not in the medians):
  <session id>  <date>  /feat  <repo path>
resumed runs (not in the medians):
  <session id>  <date>  /feat  finished|unfinished  <repo path>
left out:
  <session id>  <date>  <reason>  (Claude Code <version>|unknown)  <repo path>
```

`<reason>` is one of `model call without token usage`, `event without
timestamp`, `unreadable line`, `agent transcript missing`, `no message origin
recorded`, `unexpected record shape`.

### `--session ID`

A run that is counted prints the header and its one skill block. A left-out
run prints the header and the `left out:` list with its one row (session id,
date, reason, Claude Code version), exit 0, or 1 with `--strict`.

### `--all`

One header, then per repo (sorted by path) `## <repo path>` followed by its
skill blocks; then `## all repos` with the skill blocks over every run; the
unfinished, resumed and left-out lists once, at the end.

### `--compare-since D`

Each figure row shows `before`, `since`, `diff` (since − before, signed);
the block heading gives both counts:
`== /feat: before <D>: <n> runs | since <D>: <m> runs ==` (`1 run` for a
count of 1). A side with no
finished run prints `no runs` in place of its values and its diff column is
empty. An agent type, tool schema or failed tool present on one side only
prints `-` in the other side's column and an empty diff. `failed tool calls`
shows each side's total and its number of runs, with an empty diff (totals
over different numbers of runs do not subtract). No statistical wording (no
"significant", no confidence).

With `--all`, every repo block and the `all repos` block use this same
layout; the unfinished, resumed and left-out lists are printed once, at the
end, with each run's date, so its side is visible.

### Fixed lines

| Situation | Line | Exit |
| --- | --- | --- |
| selection holds no run | `no runs found in <projects dir> for <repo path>` (or `for any repo`, or `for session <id>`), plus `, <since> to <until>` when bounded | 0 |
| comparison side empty | `no runs` in that side's column | 0 |
| `--session` id not found or not a run | same as "no runs found" | 0 |
| `--session` id of a left-out run | its `left out:` row | 0, or 1 with `--strict` |

### Number formats

- counts and medians: integer, or one decimal when the median falls between
  two integers (`2.5`);
- tokens: integer below 10,000, else thousands with one decimal (`18.2k`) and
  millions (`1.4M`);
- shares: whole percent (`31%`); a difference of shares: signed whole
  percentage points (`+3pp`, `-12pp`, `0pp`);
- other differences: signed, in the figure's own format (`+1.5`, `-2.3k`);
- minutes: one decimal;
- cost units: integer, thousands separator `,`;
- USD: `$` and two decimals.
