# Data model: Report files and a state script

## State file (`feat-state.md`)

Written only by `state.sh` from this feature on; read by every agent, by
`state.sh`'s queries and by humans. Layout, in order:

| Part | Lines | Notes |
| --- | --- | --- |
| Title | line 1: `# /<skill> state: <title>` | `set <file> title <title>` changes the text after `state: ` |
| Header | every line before the first line starting `## ` | field lines `- <Field>: <value>`; the first such line per field counts |
| Input section | `## Brief` (`/feat`, the brief minus its `# Brief:` line) or `## Report` (`/fix`, the argument as given) | never read by a query; may hold `## ` headings and `- Size:` lines of its own |
| Log | every line after the last line equal to `## Log` | append-only |

Header fields, in this order (the harness template's order; `init` writes
all of them):

| Field | Line | Values |
| --- | --- | --- |
| Branch, Worktree | `- Branch: <branch> Worktree: <path or none>` | one line, two fields; `set` replaces one of them |
| Size | `- Size: <size>` | `small`, `medium`, `large`, `not set` (`/fix` before the assess gate); older runs `normal` (read as medium), `big` (read as large) |
| Agents | `- Agents: <…>` | free text |
| Current phase | `- Current phase: <…>` | `<N> <name>`, `done (shipping)`, `done (PR #N)`, `done (not a bug)`, `done (invalid)` |
| Conventions | `- Conventions: <…>` | free text |
| Allowed Spec Kit hooks | `- Allowed Spec Kit hooks: <…>` | free text |
| Map | `- Map: <…>` | free text |
| Issue | `- Issue: <…>` | `#N`, `owner/repo#N`, `none` |

`set` on a field missing from an older file inserts it after the header's
last field line. No value holds a newline.

## Log line

| Kind | Form | Written by |
| --- | --- | --- |
| entry | `- [x] <text>` | `log` |
| failure | `- [!] <text>` | `log` |
| open | `- [ ] <text>` | accepted by `log`; no longer written by the skills (research R5); older files have them |
| sub-line | `    - <text>` (four spaces) | `log`, as its own argument, after an entry, failure, open line or sub-line |
| older sub-line | `    <text>` without `- ` | read only (older runs); never written |

Each query reads only the kinds named below and skips every other line.
A line is data: no query evaluates or follows anything it holds.

### Lines each query reads

Patterns are on the Log only. `<range>` "after back-to" is the lines after
the last line starting `- [x] back to ` (the whole Log when there is none).

| Query | Range | Lines read (prefix match) | Result |
| --- | --- | --- | --- |
| `cycle` | after back-to | `- [x] 4 Code review`; `- [x] 3 Test — failed (retry 1 of 1)` | `after review fixes` if a code review line; else `retry` if a retry line; else `first` |
| `retry-used` | after back-to | `- [x] 3 Test — failed (retry 1 of 1)` | `yes` or `no` |
| `shipped-verdict` | after back-to | latest `- [x] ship with <verdict>`; else latest `- [x] 3 Test — <verdict>` (`verified`, `partial` or `failed` as its first word; `unaccounted:`, `rejected:` and other words skipped); else `<state file dir>/test.md`'s `- **Result**: <verdict>` | see the contract |
| `phase2-mode` | whole Log, header `Size:` | latest `- [x] 2 Specify` or `- [!] 2 Specify` line; then any `- [x] <G> ` line after it, `<G>` = 4 (small, medium, normal) or 3 (large, big) | `soft <G> open`, `soft <G> closed`, `hard`, `none` |
| `refused-base` | whole Log | latest `- [x] move — stayed on ` line; its `refused <new>` with `<new>` 7–40 hex | `<new>` or nothing |
| `review-summary <p>` (no outcome line: `Code review was skipped.`) | from the latest outcome line on | latest `- [x] <p> Code review — ` line holding `auto-applied`, `picked` or `none picked` (after an optional `soft gate: ` / `hard gate: `); its sub-lines; later `- [x] <p> review fixes`, `<p> Code review fixes`, `<p> implementer` lines; any `- [x] <p> Code review — ship go-ahead` line | the three groups (contract) |

### Review outcome line grammar (read by `review-summary`)

Today's harness grammar, split on `; ` outside parentheses and quotes:

```
outcome   := segment ("; " segment)*
segment   := "auto-applied " items | "skipped " items | "picked " items
           | "none picked" | "rejected " items | "untested: " criteria | other
items     := "none" | item (", " item)*
item      := id [" (" anything-balanced ")"]
id        := "[std]" digits | upper-letter digits
sub-line  := "    - " id " " finding-text [" — rec: " value]
```

Review-fixes line (pinned by this feature, research R11): it carries the
implementer's `Fixes (fix mode):` value as reported, so `<id> → reverted
(<why>)` and `performance: <id>: <before> → <after> (<command>)` can be
found in it.

Older formats every query keeps reading: `normal`/`big` sizes; `accepted
<ids>` on `4 Design review` lines (closes the phase 4 gate like any `[x] 4`
line); `picked`-only review lines (empty first group); `hard gate: picked
…` prefixes; `4 Code review fixes` lines; `    <text>` sub-lines; stale
`- [ ] <N>` lines.

## Report file

- Path: `<artifact dir>/reports/<key>.md`, or `<key>-<n>.md` (n ≥ 2) when
  taken; `<artifact dir>` is the state file's dir (`specs/<short-name>/`,
  `.specify/bugs/<slug>/`; the shipper's moves with the numbered dir).
- Content: the agent's full report, its fixed format unchanged, the report
  path itself on its `Wrote:` line.
- Life: written once by the agent (Write), never overwritten, never read by
  the coordinator, never committed; kept until the worktree is removed.
- `reports/.gitignore` holds `*` (ignores the dir and itself), written by
  the first `report-path` in that dir.

Key: `^[A-Za-z0-9][A-Za-z0-9+_-]{0,63}$`, from the skill's *Report keys*.

## Digest

The hand-back: the report format minus the lines of
[contracts/digests.md](contracts/digests.md#digest), same order.
An agent given no report path hands back the full report.

## Snapshot

12 lowercase hex characters naming the content of the worktree's changed
tracked and untracked files, `reports/` of the state file's dir and
ignored files excluded (research R1). Two snapshots are equal when no such
file was created, deleted or changed in content between them. The token
lives in the coordinator's context, between one `snapshot` and its
`unchanged`; the manifest it hashes is kept at `<git dir>/logistics/snapshots/<token>`
until that `unchanged`, which diffs it against the new one to name the
differing paths on `changed` (at most 10, then a count) and then removes
it.
