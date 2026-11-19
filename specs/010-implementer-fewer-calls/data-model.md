# Data model: Cut the implementer's model calls per spawn

No storage. These are the things `story.sh` reads from tasks.md and the
things `/feat` compares at phase 5. Parsing rules: [contracts/story-cli.md](contracts/story-cli.md).

## Task

One `- [ ] T<digits> …` line of tasks.md, outside a code fence.

| Field | From | Notes |
| ----- | ---- | ----- |
| ID | `T<digits>` after the checkbox | as written (`T001`) |
| checked | the checkbox | `[ ]` unchecked; `[x]` or `[X]` checked |
| markers | `[P]` / `[US<n>]` tokens right after the ID | `[P]` is never a story |
| story | the first `[US<n>]` marker | none when untagged |
| line | its line number | named in errors |
| text | the line as written | read for paths, never printed: it stays in tasks.md |
| paths | backticked whitespace-free spans with `/` or a file extension, none holding `<`, `*` or `://` | zero or more, deduplicated, in order; candidates, never checked on disk |

In the one-story form a task prints as one line: `<ID> [ ]|[x] paths:
<paths> | none`.

## Story

A level-2 heading `## Phase …: User Story <n> …`.

| Field | Notes |
| ----- | ----- |
| number | `<n>`, compared as a number |
| position | order of its first heading; gives first and last story |

## Group

| Group | Members |
| ----- | ------- |
| setup/foundational | untagged tasks before the story span |
| `US<n>` | tasks tagged `[US<n>]` |
| polish | untagged tasks after the story span |

Each group has an ID set, a count and an unchecked count. Every task is in
exactly one group, or `story.sh` exits 1 (untagged inside the story span, or
tagged with a story that has no heading).

**Story group** (spec's key entity, what an implementer owns): `US<n>`'s
tasks, plus setup/foundational when `US<n>` is the first story and polish
when it is the last.

## Tasker's report (phase 5 input to the comparison)

The `Per story:` line of `feat-tasker`'s report, unchanged: per story `US<n>:
<n> tasks (<IDs or ranges>)`, then setup/foundational and polish IDs.
`/feat` reads it as groups, by label: the IDs labelled setup or
foundational together are the setup/foundational group, those labelled
polish the polish group, those after `US<n>` that story's; a group it
leaves out is empty; a range `T001–T012` (en dash or hyphen) stands for
every ID from T001 to T012. IDs with no label, or a grouping that reads two
ways (a range across two labels, IDs listed "with" a story), are a
difference. Example in [quickstart.md §2](quickstart.md).

**Match**: for every group, the expanded ID set and the count equal
`story.sh`'s. Anything else is a difference (hard gate).
