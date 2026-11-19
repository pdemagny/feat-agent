# Data model: Size tables generated from one data file

## Size data file: `.apm/skills/feat/sizes.json`

Installed as `.claude/skills/feat/sizes.json`. Field-level contract for
readers in [contracts/sizes-json.md](contracts/sizes-json.md).

```json
{
  "feat": {
    "rows": [
      {"id": "1", "label": "Brief review (`/brief`)", "agent": "feat-brief-reviewer", "loads": [],
       "small": {"model": "sonnet", "effort": "medium"}, "medium": {"model": "sonnet", "effort": "medium"}, "large": {"model": "opus", "effort": "medium"}},
      "... rows 2 to 8, in table order ..."
    ],
    "groups": {
      "4": {"small": [["4a", "4b", "4c"]], "medium": [["4a"], ["4b"], ["4c"]], "large": [["4a"], ["4b"], ["4c"]]},
      "7": {"small": [["7a", "7b"], ["7c", "7d", "7e"]],
            "medium": [["7a"], ["7b"], ["7c"], ["7d"], ["7e"]], "large": [["7a"], ["7b"], ["7c"], ["7d"], ["7e"]]}
    }
  },
  "fix": {
    "rows": ["... rows 1 to 5, in table order ..."]
  }
}
```

Formatting is free (the generator never writes the JSON); one row object
per line keeps diffs readable.

### Skill (`feat`, `fix`)

| Field    | Type                 | Rule                                                        |
| -------- | -------------------- | ----------------------------------------------------------- |
| `rows`   | array of Row, ≥ 1    | table order; `id` unique within the skill                    |
| `groups` | object (`feat` only) | required for `feat`, absent for `fix`                        |

### Row

| Field    | Type                        | Rule                                                                          |
| -------- | --------------------------- | ----------------------------------------------------------------------------- |
| `id`     | string                      | `^[0-9]+[a-z]?$`: phase number plus an optional lens letter (`1`, `4a`)       |
| `label`  | string, non-empty           | without the id; used by every copy (FR-002); only letters, digits, space and `, ( ) ` / -` (FR-020) |
| `agent`  | string                      | agent name without backticks (`feat-planner`); matches `^[a-z0-9-]+$` (FR-020) |
| `loads`  | array of strings            | skill names the agent loads for this row, each matching `^[a-z0-9-]+$` (FR-020); `[]` renders as `—` |
| `small`, `medium`, `large` | Spawn     | all three required                                                            |

No other key is allowed in a row (a typo such as `smal` fails), in a
skill (only `rows`, plus `groups` for `feat`) or at the top level (only
`feat` and `fix`) (FR-020). The generated text lands in SKILL.md files the
coordinator reads as instructions, so validation runs before any write
or check.

### Spawn

| Field    | Type   | Rule                                                 |
| -------- | ------ | ---------------------------------------------------- |
| `model`  | string | one of `haiku`, `sonnet`, `opus` (ordered weakest first) |
| `effort` | string | one of `low`, `medium`, `high`, `xhigh`, `max` (ordered) |

### Reviewer groups (`feat.groups`)

`{ phase: { size: [ [row id, ...], ... ] } }`

- `phase` is the numeric part of row ids that share it (`"4"` for
  4a–4c); only phases with two or more rows have groups, and every such
  phase must have them.
- Each size lists the reviewers spawned at that size; each inner list is
  one reviewer's rows. Every row of the phase appears exactly once per
  size.
- A group runs on the strongest model and the strongest effort among its
  rows, taken separately (`opus · medium` and `sonnet · high` give
  `opus · high`). Ordering, such as "7e after 7d", stays in the prose.

## Marked region

`<!-- sizes-start NAME -->` … `<!-- sizes-end NAME -->`; exactly one start
and one end per name per file, start before end. Any other
`sizes-start`/`sizes-end` name in a target file is an error.

| File                          | Name           | Kind   | Content                                                                 |
| ----------------------------- | -------------- | ------ | ----------------------------------------------------------------------- |
| `.apm/skills/feat/SKILL.md`   | `feat-table`   | block  | `/feat` skill table                                                     |
| `.apm/skills/fix/SKILL.md`    | `fix-table`    | block  | `/fix` skill table                                                      |
| `.apm/skills/brief/SKILL.md`  | `brief-review` | inline | `feat` row 1 as a sentence                                              |
| `docs/workflow.md`            | `feat-matrix`  | block  | size × phase matrix                                                     |
| `docs/workflow.md`            | `fix-matrix`   | block  | `/fix` size matrix                                                      |
| `docs/workflow.md`            | `agents-table` | block  | agents table, `small size` column generated, other columns kept         |

- **Block**: the start marker ends its line; between the markers sit
  `\n\n`, the table (lines joined by `\n`) and `\n\n`, so the end marker
  starts its own line after a blank one.
- **Inline**: the generated text sits directly between the markers.

## Generated tables

Every table: `| a | b |` cells padded with spaces to the column's widest
cell (code points), a separator `| --- | --- |` of dashes as wide as the
column.

| Region        | Columns                                                     | Rows                                                                                                       |
| ------------- | ----------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------- |
| `feat-table`, `fix-table` | `Phase`, `Agent`, `Loads`, `small`, `medium`, `large` | `<id> <label>`, `` `<agent>` ``, loads joined with `, ` or `—`, `<model> · <effort>` ×3                    |
| `feat-matrix` | `#`, `Phase`, `Agent`, `small`, `medium`, `large`, `huge`   | first the fixed row `1`, `Brief`, `your session`, `session` ×3, `session, plus capability map`; then each row: id, label, `` `<agent>` ``, values, `huge` = `first capability's size` for id `1`, `—` otherwise |
| `fix-matrix`  | `#`, `Phase`, `Agent`, `small`, `medium`, `large`           | id, label, `` `<agent>` ``, values                                                                         |
| `agents-table`| as written in the file                                      | as written; the `small size` cell replaced (below); the agent read from the first cell, backticks stripped |

### Agents-table `small size` cell

The agent's rows, `feat` then `fix`, in table order; distinct `small`
values in order of first appearance. One value: `model · effort`.
Several: `model · effort (label)` per value, the label of its first row
lowercased, joined with `, `. Errors: a table line whose agent has no row;
a row agent with no table line; a line whose cell count differs from the
header; no `small size` or `Agent` header.

### `brief-review` sentence

`feat` row `1`; sizes in order, consecutive equal values grouped. Each
group is its sizes (`small`, `small and medium`, `small, medium and
large`), a space, then the model and the effort, each in backticks,
joined by ` · `; groups joined with `, `.
Today: ``small and medium `sonnet` · `medium`, large `opus` · `medium` ``.
