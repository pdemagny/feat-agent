# Data model: soft-design-gate

No stored data: these are the shapes `/feat` reads from reports and writes
to the state file. Formats are in [contracts/phase4-gate.md](contracts/phase4-gate.md).

## Design finding (`D<n>`)

| Field | Values | Set by |
| ----- | ------ | ------ |
| tag | `[sec]`, `[cost]`, `[design]` (one per lens: 4a, 4b, 4c) | reviewer |
| kind | `clarity`, `fit`, `simplicity`, `readiness` (`[design]` only) | reviewer |
| text | problem → proposed change | reviewer |
| spot | `<artifact>: <section or line>`, the section heading as written or a line number; two spots are the same when artifact and heading or line are identical | reviewer |
| severity | `high`, `medium`, `nice-to-have`; shown, never a trigger | reviewer |
| rec | see Rec | reviewer; `/feat` only rewrites it to `user (…)` by merge rules |
| id | `D1…`, in merged order | `/feat` |

Validation: a line without a valid rec gets `user (no valid recommendation)`.

## Rec

`apply` | `skip (<why>)` | `user (<why>)`. A `skip` or `user` without its
why is invalid. Merge outcomes: `user (reviewers disagree)`, `user (no valid
recommendation)`.

## Gate (phase 4)

States: `soft` | `hard`, decided once per phase 4 run by the table in the
contract (§3). Transitions after the gate:

- soft → `apply` findings to the continued planner (none: no `SendMessage`, straight to phase 5); `skip` left; Log `auto-applied … ; skipped …`.
- hard → user answers; picked findings and spec changes to a fresh planner;
  Log `picked … ; rejected …`.
- either → phase 5, or "back to 2" when a change rewrites stories (unchanged).

## Log line (`4 Design review`)

One `- [x] 4 Design review — …` line plus one indented line per finding
(contract §6). Accepted = `auto-applied` ∪ `picked`; rejected (reviewer
context) = `skipped` ∪ `rejected`.
