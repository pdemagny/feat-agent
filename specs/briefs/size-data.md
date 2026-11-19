# Brief: generate the size tables and every copy of them from one JSON data file, and fail lint on drift
- Size: small — ~20–28 tasks expected: one data file, one Python generator with a check mode (absorbing `models.py`), markers in four files, offline tests, lint and rule updates; no new dependency
- Short name: size-data
- Kind: feat
- Issue: #30

## Why
Maintainers of logistics change a model or an effort by hand in up to six
places, and nothing fails when one is missed. The data also needs a form
that #28's boundary command can read later to print the next spawn's
model and effort, whatever language #28 ends up in (bash with jq, Python
or a Workflow script in JS, pending spike #56).

## Today
Models and efforts are written by hand in:
- `.apm/skills/feat/SKILL.md`, `## Size table` (with a `Loads` column;
  the phase number inside the label cell, e.g. "1 Brief review
  (`/brief`)");
- `.apm/skills/fix/SKILL.md`, `## Size table` (same shape);
- `docs/workflow.md`, `## Size × phase matrix`: the same rows with a
  separate `#` column, other labels ("Brief review", "Tasks + analyze",
  "Implement (×1 per story)", "∥" on parallel lenses), no `Loads`, plus a
  "1 Brief / your session" row and a `huge` column;
- `docs/workflow.md`, `/fix`'s `### Size matrix` (no `Loads`; row 2 is
  "Fix (review fixes and moves)"; one row overflows its column);
- `docs/workflow.md`, `## Agents`: its "small size" column, not
  column-padded (the bug assessor's cell holds both modes: "opus · medium
  (assess), sonnet · medium (test)");
- `.apm/skills/brief/SKILL.md`: row 1 written out as prose ("small and
  medium `sonnet` · `medium`, large `opus` · `medium`").

The reviewer groups are prose under each size table and, for `/feat`,
again as Python lists in `docs/diagrams/models.py`, which parses `/feat`'s
markdown table to draw `docs/img/models.svg`. `.claude/CLAUDE.md` and
constitution principle III ask for every copy to change in the same
commit; only the SVG is checked (CI renders and diffs `docs/img`).

## Behaviour
- `.apm/skills/feat/sizes.json` (shipped with the skill, so #28's command
  can read it in an install; the path is a contract for #28) holds, per
  skill (`feat`, `fix`): each row's `id` (e.g. `1`, `4a`), `label`
  (without the id), agent, `Loads` and model · effort per size (small,
  medium, large); and `/feat`'s reviewer groups per size (the lists
  `models.py` holds today).
- One label per row, used by every copy. The generator joins id and label
  for the skills ("1 Brief review (`/brief`)") and puts the id in the
  docs' `#` column. The docs' wording changes, and only these labels:
  - `/feat` 1 "Brief review" → "Brief review (`/brief`)";
  - `/feat` 4a–4c lose "∥";
  - `/feat` 5 "Tasks + analyze" → "Tasks";
  - `/feat` 6 "Implement (×1 per story)" → "Implement";
  - `/fix` 2 "Fix (review fixes and moves)" → "Fix".
  What the dropped words said stays in the prose under each table (one
  implementer per story; review fixes and moves use the phase 6 / phase
  2 row).
- A Python generator replaces `docs/diagrams/models.py` (kept in
  `docs/diagrams/`, renamed, e.g. `sizes.py`) and, from the JSON:
  - rewrites the text between HTML comment markers in
    `.apm/skills/feat/SKILL.md`, `.apm/skills/fix/SKILL.md`,
    `.apm/skills/brief/SKILL.md` (an inline pair around row 1's sentence)
    and `docs/workflow.md` (both matrices and the agents table). Table
    markers wrap the whole table, header included;
  - adds the docs-only parts as fixed template text: the "your session"
    row, the `huge` column ("first capability's size" on row 1, "—"
    elsewhere), no `Loads` column in the docs;
  - in the agents table, replaces only the "small size" cells, in place;
    its other columns (phases, denied tools, loads, writes) stay
    hand-written. A cell is the agent's distinct small values across both
    skills' rows: one value is printed as is; several are each printed
    with their row's label in lowercase, which gives the bug assessor's
    "opus · medium (assess), sonnet · medium (test)";
  - prints the D2 source of `models.svg`, as `models.py` does today, with
    `/feat`'s groups read from the JSON.
- A missing, unpaired or duplicated marker is an error in both modes,
  naming the file and marker: a lost marker never makes the check pass.
- Padding is normalised to the widest cell of each column, so the `/fix`
  docs matrix and the agents table get a whitespace-only change once.
- The coordinator reads the same values in the same markdown table it
  reads today: nothing changes at run time.
- A check mode (e.g. `--check`) exits non-zero and names each file whose
  marked text differs from a fresh generation; `mise run lint` runs it.
- A mise task (or `mise run diagrams`) regenerates everything: changing a
  model or effort is one edit to the JSON plus one command.
- The reviewer-group prose under each table stays hand-written: it holds
  conditions ("7e with 7d's cuts", "for a performance bug") that a
  generated sentence can't carry. The check does not cover drift between
  `/feat`'s group lists in the JSON and that prose; the mirroring rule
  for it stays in `.claude/CLAUDE.md`.
- `.claude/CLAUDE.md`'s mirroring rules and constitution principle III
  are rewritten: the JSON is the source of truth for models, efforts and
  loads; the marked copies are generated, never edited by hand.

## Out of scope
- A runtime lookup command printing a spawn's model and effort: #28's
  boundary command does that, from this JSON.
- Removing the tables from the SKILL.md files: decided in #28's brief,
  once its command prints the next spawn (a question added to #28).
- `/fix`'s reviewer groups in the JSON: no consumer reads them yet, and
  they depend on conditions ("for a performance bug"); #28 adds them with
  those conditions when it needs them.
- Generating the reviewer-group prose, or the agents table's other
  columns (e.g. denied tools from the agents' `disallowedTools`).
- Changing any model, effort or group: the JSON starts with today's
  values.

## Alternatives rejected
- The SKILL.md markdown tables as the generator's input (no new file, no
  constitution change) — splitting cells on ` · ` is a fragile input for
  #28's command in bash or JS, and the reviewer groups can't live in a
  markdown table.
- TOML or YAML — YAML needs a dependency in Python; TOML is read-only in
  Python's standard library and unreadable by jq or JS without one. JSON
  is read by all three.
- A bash and jq generator (constitution V prefers bash) — building padded
  markdown tables, the strongest-of-a-group rule and in-place marker
  rewrites in four files is the JSON aggregation where principle V allows
  Python.
- A second label per copy (`doc_label`) to keep the docs' wording — a
  second label is one more field that drifts unnoticed.
- An agent-to-rows mapping in the JSON for the agents table — the rows'
  `agent` field already gives it.
- Dropping the agents table's "small size" column and pointing to the
  matrices — the user wants it kept and generated.
- Removing the tables from the SKILL.md files now — until #28 prints the
  spawn, the coordinator would need a tool call to read the JSON (the
  issue's reason against a lookup command), and the saving is well under
  1% of a run per the measured baseline.
- Shipping the generator in `.apm/skills/feat/scripts/` — it only serves
  this repo's sources, never an install.
- A permanent fixture of today's values — the PR's one-time diff against
  `main` proves the first generation; the tests pin the generator's logic.

## Acceptance
- Changing one model or effort is one edit to the JSON plus one
  generate command; after it, every copy (both skills, `/brief`, both
  docs matrices, the agents table's cell, `models.svg`) shows the new
  value.
- `mise run lint` fails, naming the file, when any marked copy is edited
  by hand, a JSON change is not regenerated, or a marker is missing,
  unpaired or duplicated; it passes on a fresh generation.
- The PR's diff of the generated copies against `main` changes no
  model · effort anywhere: only the labels listed under Behaviour and
  whitespace padding change.
- `mise run diagrams` produces a `models.svg` identical to today's.
- Offline tests under `tests/` cover generate and check with a fixture
  JSON: a drifted copy fails, a fresh one passes, a missing or duplicated
  marker fails, the strongest-of-a-group cell, and an agents-table cell
  with one value and with several.
- `mise run lint` stays clean (the generator compiled and syntax-checked
  against Python 3.11, like `measure.py`); `mise run test:apm` checks
  `.claude/skills/feat/sizes.json` lands in an install.
- `.claude/CLAUDE.md`'s mirroring paragraph shrinks to "edit the JSON,
  run the generator" (plus the group-prose rule); constitution principle
  III names the JSON.

## Constraints / decisions already made
- Python 3.11 or later, standard library only (constitution V), run with
  `python3 -I`.
- Markers are HTML comments (as release-please's in `docs/install.md`);
  the website renders raw HTML (`hugo.toml`: `unsafe = true`), so they
  stay invisible there.
- `measure.py` stays the only script in the shipped `scripts/`; the JSON
  ships, the generator does not.
- Every place naming `models.py` or "read from the size table" follows
  the rename and the new source: `mise.toml`'s `py_compile` list (lint),
  its `diagrams` task and description, and `docs/workflow.md`'s "drawn
  from the size table by `mise run diagrams`".
- The CI step that renders and diffs `docs/img` stays.
- #28 reads this JSON; its path and format are a contract for #28's
  brief.
