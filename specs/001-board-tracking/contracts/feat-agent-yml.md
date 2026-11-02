# Contract: `.feat-agent.yml`

Opt-in file at the repo root (`git rev-parse --show-toplevel`). Committed, so
worktrees branched from `origin/<default>` see it. Absent: tracking is off and
nothing calls `gh` for the board.

## Accepted form

```yaml
tracker:
  provider: github            # only value accepted
  project: https://github.com/users/pdemagny/projects/2
  statuses:
    brief: Brief
    building: In progress
    review: In review
```

Not YAML in general: the script reads exactly this shape, line by line, in
pure bash (no yq, no Python, no `eval`).

## Grammar

Each line, after removing a trailing `\r`, is one of:

| Line | Rule |
|---|---|
| empty or only spaces | ignored |
| `#…` after optional spaces | comment, ignored |
| `tracker:` | column 0; must be the first key line; once |
| `  provider: <value>` | 2 spaces; under `tracker`; once |
| `  project: <value>` | 2 spaces; under `tracker`; once |
| `  statuses:` | 2 spaces; under `tracker`; once; no value |
| `    brief: <value>` | 4 spaces; only after `statuses:` and before the next 2-space key; once |
| `    building: <value>` | same |
| `    review: <value>` | same |

- Indentation is spaces only, exactly 0, 2 or 4 as above. A tab anywhere in a
  key line, another indent, an unknown key, a key at the wrong level or a
  repeated key is an error.
- Keys within a level may come in any order.
- `<value>`: after `key:` and at least one space, either
  - unquoted: everything up to a ` #` (space then hash) or the end of line,
    trailing spaces trimmed; must not start with `"` or `'`;
  - `"…"` or `'…'`: everything up to the matching closing quote (no escape
    sequences; the quote character can't appear inside), then optional
    spaces and an optional `# comment`, nothing else.
- Empty values (`brief:`, `brief: ""`) are errors.
- After the last line, every one of the six keys must have been seen.

## Value rules

| Key | Rule |
|---|---|
| `provider` | exactly `github` |
| `project` | matches `^https://github\.com/(users\|orgs)/[A-Za-z0-9][A-Za-z0-9-]{0,38}/projects/[1-9][0-9]{0,9}$` (no trailing slash, query, fragment or `/views/N`) |
| `statuses.*` | any text; at `check` it must equal (exact, case-sensitive) one option name of the board's Status field. A name holding a tab, a newline or a backslash is unsupported (the filters' `@tsv` escapes them, so it never matches) |

No field or option IDs, no `done` key (FR-002, FR-004).

## Errors

All are `check` failures (exit 1), reported before any `gh` call except the
status match, which needs the board:

| Case | Line printed |
|---|---|
| bad line (indent, tab, unknown or misplaced key, junk after a quoted value) | `tracker: error: .feat-agent.yml line <n>: <reason>` |
| repeated key | `tracker: error: .feat-agent.yml line <n>: duplicate <key>` |
| missing key | `tracker: error: .feat-agent.yml: missing <key>` (e.g. `tracker.statuses.review`) |
| empty value | `tracker: error: .feat-agent.yml line <n>: empty <key>` |
| provider not `github` | `tracker: error: .feat-agent.yml line <n>: provider must be github` |
| URL shape | `tracker: error: .feat-agent.yml line <n>: project must be https://github.com/users\|orgs/<login>/projects/<number>` |
| unknown status | `tracker: error: unknown status "<name>" (statuses.<key>); board options: <opt>, <opt>, ...` (several unknown names in one line, `;`-separated; at most 10 options listed, then `, ...`, three ASCII dots) |

`<reason>` is fixed text chosen by the script; the offending value is never
echoed for a bad line, so a hostile line can't put its text into the
orchestrator's context. Status names and board options are echoed through
`clean()` (control and Unicode bidi/format characters → `?`, at most 60
characters, quoted; see [tracker-cli.md](tracker-cli.md#common-behaviour)).
