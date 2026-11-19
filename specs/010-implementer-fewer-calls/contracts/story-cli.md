# Contract: `story.sh`

`.apm/skills/feat/scripts/story.sh`, bash, run by `/feat` as
`bash <skill base dir>/scripts/story.sh -- '<tasks.md>' [US<n>]` (phases 5
and 6). The script's header comment carries this contract in short, as
`tracker.sh`'s does.

```text
story.sh [--] <tasks.md>          every group's task IDs and count (phase 5)
story.sh [--] <tasks.md> US<n>    one story's tasks: IDs, checked state, paths, the unchecked count (phase 6)
```

A first argument `--` is dropped before anything else, so a path starting
with `-` is never read as an option; the script takes no option, so any
other first argument is the path. `/feat` always passes `--`.

Everything goes to stdout; nothing to stderr. Exit 0 ok, 1 a tasks.md
problem (one `story: error: …` line), 2 usage (one `story: usage: …` line).
`LC_ALL=C`; bash built-ins for the parse. On exit 0 the output holds no
backtick (labels, IDs, `[ ]`/`[x]` and paths, which are spans between
backticks), so a fence of four backticks around it can't be closed early.

## Reading tasks.md

Per line, in file order:

| Line | Meaning |
| ---- | ------- |
| starts with three backticks | toggles a fence; lines inside a fence are skipped |
| `^##[[:space:]]+Phase[^:]*:[[:space:]]*User Story[[:space:]]+([0-9]+)` | story heading: a section of story `<n>` starts |
| any other `^##[[:space:]]` | another level-2 section starts (`###` and deeper never do) |
| `^- \[([ xX])\] (T[0-9]+)` followed by end of line or whitespace | a task: checkbox (`[ ]` unchecked, `x`/`X` checked), ID |

A task's markers are the bracketed `[P]` or `[US<n>]` tokens right after its
ID, separated by whitespace; the first `[US<n>]` among them is its story tag.
`[P]` is never a story. A `[US<n>]` later in the text is text.

**Stories**: the numbers of the story headings, unique, in order of their
first heading. The *first story* and the *last story* are the first and last
in that order (one story: both).

**Story span**: from the first story heading to the first non-story level-2
heading after the last story heading (or the end of file).

**Group of a task**:

- tagged `[US<n>]` → story `<n>` (wherever it sits);
- untagged, before the story span → setup/foundational;
- untagged, after the story span → polish;
- untagged, inside the story span → error.

**Paths of a task**: split its text after the markers on backticks; each
span between a pair that holds no whitespace and either contains `/` or
ends with `.` followed by a letter and then letters or digits is a path,
unless it contains `<`, `*` or `://`: a placeholder
(`` `specs/<feature>/plan.md` ``), a glob (`` `docs/img/*.svg` ``) or a URL
is dropped. Duplicates within a task are dropped; order of appearance is
kept. The script never checks the disk: a path is a candidate, and may name
a file the story creates. The implementer reads the candidates that exist
and skips the missing ones.

## Checks, in order (the first that fails prints its line)

| Check | Exit | Line |
| ----- | ---- | ---- |
| after dropping a leading `--`, one or two arguments; the second matches `^US[0-9]+$` | 2 | `story: usage: story.sh [--] <tasks.md> [US<n>]` |
| `<tasks.md>` is a regular, readable file | 1 | `story: error: cannot read <tasks.md>` |
| at least one task carries a `[US<n>]` tag | 1 | `story: error: no [US<n>] tag in <tasks.md>` |
| no task is untagged inside the story span, or tagged with a story that has no heading (the first in file order is named) | 1 | `story: error: T014 (line 63) has no [US<n>] tag inside the story phases` / `story: error: T014 (line 63) is tagged US4 but no phase heading is User Story 4` |
| `US<n>` (one-story form) is one of the stories | 1 | `story: error: no User Story <n> in <tasks.md> (stories: US2 US1 …)` |

Story numbers compare as numbers (`US01` is `US1`); output writes them
without leading zeros.

## All-stories form

```text
setup/foundational: <s> tasks[: <ID> <ID> …]
US<a>: <k> tasks[: <ID> …]          one line per story, in story order
…
polish: <p> tasks[: <ID> …]
total: <t> tasks
```

IDs in file order, one by one (never ranges). A group with no task prints
`<label>: 0 tasks` with nothing after. The setup/foundational and polish
lines are always printed, never folded into a story.

## One-story form

```text
US<n>: <k> tasks[; setup/foundational: <s> tasks][; polish: <p> tasks]; <u> unchecked
<ID> [ ]|[x] paths: <path> <path> … | none
…
files: <path> <path> … | none
```

- `<k>` counts the story's own (tagged) tasks; the setup/foundational
  segment appears when `US<n>` is the first story, the polish segment when
  it is the last, each even when its count is 0.
- One line per printed task (setup/foundational if first, the story's own,
  polish if last), in file order: its ID, `[ ]` when unchecked or `[x]`
  when checked (`[X]` written `[x]`), and its paths. No task text, markers
  or description: the implementer reads those in tasks.md. `<u>` counts
  the `[ ]` lines.
- `files:` is every path of the printed tasks, once, first seen first.

A story with no tasks of its own prints `US<n>: 0 tasks…` and exits 0;
setup and polish still attach to it by position.

## Example

For a tasks.md with setup T001 (checked), US1 T002 (unchecked, names
`` `a/b.md` `` and `` `c.sh` ``, runs `` `mise run lint` ``, and mentions
`` `specs/<feature>/plan.md` `` and `` `docs/img/*.svg` ``), US2 with no
task, polish T003 (unchecked, no path):

```text
$ story.sh -- tasks.md
setup/foundational: 1 tasks: T001
US1: 1 tasks: T002
US2: 0 tasks
polish: 1 tasks: T003
total: 3 tasks

$ story.sh -- tasks.md US1
US1: 1 tasks; setup/foundational: 1 tasks; 1 unchecked
T001 [x] paths: none
T002 [ ] paths: a/b.md c.sh
files: a/b.md c.sh

$ story.sh -- tasks.md US2
US2: 0 tasks; polish: 1 tasks; 1 unchecked
T003 [ ] paths: none
files: none
```
