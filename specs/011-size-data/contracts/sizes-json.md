# Contract: `sizes.json` (for #28 and any other reader)

**Path**: `.apm/skills/feat/sizes.json` in the source;
`<skills dir>/feat/sizes.json` in an install (APM and `install.sh`:
`.claude/skills/feat/sizes.json`; the plugin ships `.apm/skills/` as is).

**Format**: JSON (RFC 8259), UTF-8. Readable with `jq`, Python's `json`,
or `JSON.parse`; no comments, no trailing commas.

**Schema**: [data-model.md](../data-model.md#size-data-file-apmskillsfeatsizesjson).
The keys a reader may rely on:

| Path                                   | Meaning                                                    |
| -------------------------------------- | ---------------------------------------------------------- |
| `.feat.rows[]`, `.fix.rows[]`          | the skill's rows, in table order                           |
| `.<skill>.rows[].id`                   | `"1"`, `"4a"`: phase number plus optional lens letter      |
| `.<skill>.rows[].label`                | the row's name, without the id; only letters, digits, space and `, ( ) ` / -` (`[A-Za-z0-9 ,()`/-]+`) |
| `.<skill>.rows[].agent`                | the agent spawned, without the plugin prefix              |
| `.<skill>.rows[].loads`                | skills the agent loads for this row (`[]` for none)        |
| `.<skill>.rows[].small` / `.medium` / `.large` | `{"model": ..., "effort": ...}` passed on the spawn |
| `.feat.groups.<phase>.<size>`          | the reviewers of a multi-row phase at that size: a list of lists of row ids, one inner list per reviewer |

**Rules a reader can count on**

- Sizes are exactly `small`, `medium`, `large`; `huge` is never in the
  file (a huge idea never reaches `/feat`).
- A reviewer group runs on the strongest model and the strongest effort
  among its rows, taken separately; model order `haiku` < `sonnet` <
  `opus`, effort order `low` < `medium` < `high` < `xhigh` < `max`.
- Conditions and ordering that are not membership ("7e with 7d's cuts",
  "for a performance bug") are not in the file; `/fix` has no `groups`.
- The size tables in `/feat`'s and `/fix`'s SKILL.md are generated from
  this file and agree with it in the source. In an install, a user may
  have edited the tables by hand (`docs/usage.md#tuning`); until #28, the
  coordinator reads the tables, not this file.

**Examples**

```bash
jq -r --arg s medium '.feat.rows[] | select(.id == "3") | "\(.[$s].model) \(.[$s].effort)"' sizes.json
# opus high
jq -c '.feat.groups["7"].small' sizes.json
# [["7a","7b"],["7c","7d","7e"]]
```

**Change policy**: adding a key is compatible; renaming or removing one,
or changing a value's type, is a breaking change for #28's command and
needs `!` in the commit subject.
