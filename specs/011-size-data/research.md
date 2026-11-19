# Research: Size tables generated from one data file

No NEEDS CLARIFICATION was left in the Technical Context. These are the
decisions the spec left to the plan, and the ones the code forced.

## R1. JSON shape and field names (contract for #28)

- **Decision**: top level `{"feat": {"rows": [...], "groups": {...}}, "fix":
  {"rows": [...]}}`. A row is `{"id", "label", "agent", "loads", "small",
  "medium", "large"}`, each size `{"model", "effort"}`; `loads` is a list
  of skill names (`[]` for none). `groups` maps a phase number (`"4"`,
  `"7"`) to `{"small"|"medium"|"large": [[row id, ...], ...]}`. Full
  schema in [data-model.md](data-model.md) and
  [contracts/sizes-json.md](contracts/sizes-json.md).
- **Rationale**: one lookup per spawn in every reader: jq
  `.feat.rows[] | select(.id == "3") | .[$size]`, Python
  `row[size]["model"]`, JS `row[size].model`. Sizes as row keys, not
  nested under another key, keep that lookup one step. Objects for model ·
  effort, not two-element arrays, so #28's reader names what it reads.
  Rows are an ordered list (the tables' order), not an object keyed by id.
- **Alternatives considered**: `"small": ["sonnet", "medium"]` (shorter
  lines, positional meaning); rows keyed by id (loses order, which the
  tables need); a `version` field (no reader needs it yet; #28 can add it);
  `/fix`'s groups (out of scope).

## R2. Diagram column titles

- **Decision**: the generator keeps the diagram's eight `(phase, title)`
  pairs (`"Brief review"`, `"Specify"`, …, `"Ship"`) as fixed template
  text, like the docs' `huge` column, and fails when the set of `/feat`
  phases in the JSON differs from it. Each column's groups come from
  `feat.groups[phase][size]` when the phase has groups, else the phase's
  single row.
- **Rationale**: the titles are not row labels ("Design review" names
  phase 4, whose rows are 4a–4c; row 1's label carries "(`/brief`)") and
  must stay byte-identical for SC-004. The phase check makes a new phase
  in the JSON fail loudly instead of vanishing from the picture.
- **Alternatives considered**: deriving titles from labels (needs a
  special case for every grouped phase and for row 1); a `title` per
  phase in the JSON (a presentation field in #28's contract).

## R3. Markers

- **Decision**: `<!-- sizes-start NAME -->` and `<!-- sizes-end NAME -->`,
  in the style of release-please's `x-release-please-start-version` /
  `x-release-please-end`, with the name repeated on the end marker so an
  unpaired half can be named. Names: `feat-table`, `fix-table`,
  `brief-review`, `feat-matrix`, `fix-matrix`, `agents-table`. Block
  regions hold a blank line, the table and a blank line; the inline
  region holds the sentence alone.
- **Rationale**: GFM keeps adding lines to a table until a blank line, so a
  marker line right after a table could become a row on the website; the
  blank lines rule that out. A named end marker lets every error name the
  marker.
- **Alternatives considered**: one bare end marker per file (an unpaired
  half could not be named); markers inside each agents-table cell (nine
  inline pairs in one table, unreadable to edit).

## R4. The agents table region

- **Decision**: one block pair wraps the whole agents table. The generator
  parses the table inside it, keeps every cell but the `small size` column
  as written, replaces that column's cells from the JSON, and re-pads the
  table (FR-009). An agent line with no row in the JSON, a JSON agent with
  no line, or a line whose cell count differs from the header is an
  error.
- **Rationale**: FR-007 changes the cells in place and FR-009 normalises
  padding, which the spec already expects to change the agents table's
  whitespace once. The other columns' text stays byte-for-byte; only
  padding moves.
- **Consequence**: a hand edit of the agents table's other columns that
  leaves the padding uneven fails the check until `mise run diagrams` is
  run. Accepted: the same command fixes it, and the check names the file.

## R5. Agents-table cell values

- **Decision**: collect the agent's rows in `feat` order, then `fix`
  order; keep distinct `small` values in order of first appearance. One
  value: `model · effort`. Several: each `model · effort (label)`, the
  label being the first row with that value, lowercased, joined with
  `, `.
- **Rationale**: reproduces today's cells, including the bug assessor's
  `opus · medium (assess), sonnet · medium (test)`.

## R6. `/brief`'s sentence

- **Decision**: from `feat` row `1`, group consecutive sizes that share a
  value: ``small and medium `sonnet` · `medium`, large `opus` · `medium` ``
  (three equal sizes give `small, medium and large …`). The marked
  sentence sits on one line; the surrounding paragraph is reflowed by hand
  once.
- **Rationale**: reproduces today's sentence; consecutive grouping reads
  in size order.

## R7. Command line and mise task

- **Decision**: `python3 -I docs/diagrams/sizes.py [--root DIR] [--check |
  --d2]`. No mode writes the copies; `--check` compares; `--d2` prints the
  D2 source. `--root` (default: the repo root, two levels above the
  script) exists for the tests. `mise run diagrams` runs the write first,
  then renders all three diagrams: one edit plus `mise run diagrams`
  (FR-012). Exit 0 clean, 1 drift (check), 2 any error. Contract in
  [contracts/sizes-cli.md](contracts/sizes-cli.md).
- **Rationale**: the spec allows `mise run diagrams` as the one command;
  it already has to run to refresh `models.svg`, so a second task would
  make the change two commands. Separate exit codes let the tests tell
  drift from a bad marker.
- **Alternatives considered**: a new `sizes` task (two commands per
  change, or a task chain); subcommands (`generate`, `check`, `d2`) (no
  gain over two flags).

## R8. Generate is all-or-nothing and byte-exact

- **Decision**: the generator reads every target as bytes decoded as
  UTF-8 (no newline translation), computes every new text, and writes
  only when no error was found, only the files that changed. Padding
  counts code points (`·` and `—` are one each), as the tables do today.
- **Rationale**: a bad marker never leaves half the copies rewritten;
  today's tables regenerate unchanged where only padding rules apply.

## R9. Tests

- **Decision**: `tests/sizes/run.sh` (bash, like `tests/story/run.sh`)
  with `fixtures/` (a fixture `sizes.json` whose values differ from
  today's, so a strongest-of-a-group cell takes its model from one row and
  its effort from another, and an agent has two distinct small values;
  stale versions of the four target files) and `expected/` (the four
  generated files and `models.d2`). Run by `mise run test:sizes`, CI and
  shellcheck in `mise run lint`.
- **Rationale**: matches the repo's offline-test pattern; golden files
  also prove the text outside markers is untouched.
- **Alternatives considered**: a Python `unittest` file (no other test in
  the repo is one); a fixture of today's values (rejected in the brief).

## R10. Constitution amendment

- **Decision**: principle III names `.apm/skills/feat/sizes.json` as the
  source and the marked copies as generated; version 1.2.0 → 1.3.0
  (MINOR: the principle's guidance changes materially, its intent stays).
- **Rationale**: the governance section's versioning rule.
