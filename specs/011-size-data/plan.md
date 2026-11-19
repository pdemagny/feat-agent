# Implementation Plan: Size tables generated from one data file

**Branch**: `size-data` | **Date**: 2026-11-19 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `specs/011-size-data/spec.md` (issue #30)

## Summary

`.apm/skills/feat/sizes.json` becomes the one source of every row's model,
effort and loads for `/feat` and `/fix`, plus `/feat`'s reviewer groups.
`docs/diagrams/models.py` is renamed `docs/diagrams/sizes.py` and grows into
a generator: from the JSON it rewrites six marked regions (both skills'
size tables, `/brief`'s row 1 sentence, `docs/workflow.md`'s two matrices
and its agents table's `small size` column), and with `--d2` prints the
same D2 source `models.py` prints today. `--check` makes `mise run lint`
fail on drift or a bad marker; `mise run diagrams` regenerates everything,
so a change is one JSON edit plus one command. Offline tests under
`tests/sizes/`, the rule and constitution updates, and the FR-005 label
changes complete it. Nothing read at run time changes shape.

## Technical Context

**Language/Version**: Python 3.11+ standard library only, run as `python3 -I` (generator); bash (tests); JSON; Markdown

**Primary Dependencies**: none new; `d2` 0.9.0 and `shellcheck` 0.11.0 already pinned in `mise.toml`

**Storage**: one JSON file in the repo, shipped with the `feat` skill

**Testing**: `tests/sizes/run.sh` with fixtures and golden files, run by a new `mise run test:sizes` and CI; `mise run lint` (`--check`, compile, 3.11 syntax, shellcheck); `mise run test:apm`; `mise run diagrams` + `git diff --exit-code docs/img`; [quickstart.md](quickstart.md)

**Target Platform**: maintainers' machines and the `check` workflow (ubuntu-latest); the JSON is read in any install by #28 later

**Project Type**: prompt package (skills + subagents) with helper scripts and a Hugo docs site

**Performance Goals**: N/A (a few small files, run on demand)

**Constraints**: models.svg byte-identical (SC-004); no model · effort change in any copy (SC-003); text outside markers byte-for-byte unchanged; the generator does not ship (FR-019); the markers stay invisible on the website (`hugo.toml`: `unsafe = true`)

**Scale/Scope**: 1 new JSON, 1 renamed and rewritten script (~250 lines), 1 test dir; ~10 edited files; ~22 tasks

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Check | Result |
| --------- | ----- | ------ |
| I. Thin coordinators | `/feat` and `/fix` keep reading the same tables; no new step, read or tool call | pass |
| II. The user decides at gates | no gate changes | pass |
| III. One source of truth | the principle is amended in this PR to name `sizes.json` (FR-015) and the copies become generated and lint-checked; the reviewer-group prose stays a hand mirror under its rule in `.claude/CLAUDE.md` (FR-014) | pass (amended, 1.2.0 → 1.3.0) |
| IV. Fixed report formats | no agent report changes; the JSON and the generator's CLI are contracts written down in [contracts/](contracts/) | pass |
| V. Small and plain | Python is allowed for JSON aggregation (the brief rejected bash + jq for this); standard library only, compiled and 3.11-checked by lint, offline tests under `tests/`; markers add four lines to each SKILL.md | pass |

Distribution: the JSON sits in the `feat` skill dir, which APM
(`includes: auto`), the plugin (`./.apm/skills/`) and `install.sh` already
ship whole; `test:apm` gains a check. Development workflow: the
constitution change goes through this PR with `.claude/CLAUDE.md` updated
alongside.

Post-design re-check: pass. No agent, service, permission, exposure or
dependency added.

## Design

### Data file ([data-model](data-model.md), [contract for #28](contracts/sizes-json.md), R1)

`{"feat": {"rows": [...], "groups": {"4": {...}, "7": {...}}}, "fix":
{"rows": [...]}}`; row `{"id", "label", "agent", "loads", "small",
"medium", "large"}`, each size `{"model", "effort"}`. Starts with today's
values; labels are the skill tables' labels without the id (the skills'
wording wins, FR-005).

### Generator `docs/diagrams/sizes.py` ([CLI contract](contracts/sizes-cli.md), R2–R8)

- `git mv docs/diagrams/models.py docs/diagrams/sizes.py`, then rewrite.
  Keep `models.py`'s D2 code (`FILL`, `FONT`, `WIDTH`, `GAP`, the layout
  loop, `strongest`) unchanged so the output stays byte-identical; replace
  `size_table()` with the JSON and `COLUMNS`' groups with
  `feat.groups`, the eight column titles staying as fixed text (R2).
- `--root DIR`, no mode = write, `--check`, `--d2`; exit 0 / 1 drift / 2
  error. Load and validate the JSON (schema in data-model.md; FR-020:
  `label` without `|`, newline or control character, `agent` and `loads`
  entries matching `^[a-z0-9-]+$`, unknown keys rejected at the top
  level, in a skill and in a row, since the output lands in prompts the
  coordinator reads), then for
  each target file find the markers, check them (missing, unpaired,
  duplicated, unknown), render each region, and only then write the
  changed files or report drift (R8).
- Renderers: one table function (pad to widest cell, code points) used by
  the skill tables, both matrices and the agents table; the docs-only
  parts (`your session` row, `huge` column) are constants (FR-006); the
  agents table keeps every column but `small size` (R4, R5); the `/brief`
  sentence groups consecutive equal sizes (R6).

### Markers (R3)

`<!-- sizes-start NAME -->` / `<!-- sizes-end NAME -->`: `feat-table` in
`.apm/skills/feat/SKILL.md`, `fix-table` in `.apm/skills/fix/SKILL.md`,
`brief-review` (inline) in `.apm/skills/brief/SKILL.md`, and
`feat-matrix`, `fix-matrix`, `agents-table` in `docs/workflow.md`. Block
regions are marker, blank line, table, blank line, marker. In
`/brief`, the paragraph is reflowed once so the marked sentence sits on
one line.

### Wiring

- `mise.toml`:
  - `lint`: `docs/diagrams/sizes.py` replaces `models.py` in `py_compile`;
    the `ast` 3.11 check covers `measure.py` and `sizes.py`; add
    `python3 -I docs/diagrams/sizes.py --check` and
    `shellcheck tests/sizes/run.sh`; description names the size check.
  - `diagrams`: first `python3 -I docs/diagrams/sizes.py`, then the two
    `d2` lines, then `python3 -I docs/diagrams/sizes.py --d2 | d2 … -
    docs/img/models.svg`; description "Regenerate the size tables' copies
    from .apm/skills/feat/sizes.json and render docs/diagrams to docs/img;
    lint and CI fail if they differ".
  - `test:apm`: `test -f .claude/skills/feat/sizes.json`.
  - new `test:sizes`: `bash tests/sizes/run.sh`.
- `.github/workflows/check.yml`: `mise run test:sizes`; the docs/img
  comment says "their sources and sizes.json".

### Tests `tests/sizes/` (FR-018, R9)

`run.sh` copies `fixtures/` into a temp root at the real paths
(`fixtures/sizes.json` → `.apm/skills/feat/sizes.json`, `feat-SKILL.md`,
`fix-SKILL.md`, `brief-SKILL.md`, `workflow.md` → their target paths),
runs the generator with `--root`, and compares with `expected/` (the four
files and `models.d2`). The fixture JSON differs from today's values: the
small code-review group `7a+7b` has `sonnet · high` and `opus · medium`
(cell `opus` / `high`), and one fix-only agent has two distinct small
values while another has one. Cases: fresh generation equals expected;
second run writes nothing; check passes on fresh; check fails on the
stale fixtures, on a hand-edited cell and on a data change, naming each
file (exit 1); missing, unpaired (start only, end only), duplicated and
unknown markers fail in both modes with file and marker named and no file
written (exit 2); an agents-table line with no row and a row agent with
no line fail; `--d2` equals `expected/models.d2`; the one-value and
two-value agents cells; a fixture JSON with a newline in a `label`, an
`agent` with a space, and an unknown top-level key each fail with exit 2,
naming the field, and write nothing (FR-020).

### Text changes

- `.apm/skills/feat/SKILL.md`, `.apm/skills/fix/SKILL.md`: markers around
  the table (table bytes unchanged); the line "The single source of truth
  for (`/fix`'s) models and efforts" becomes "The models and efforts
  passed on every spawn. Generated from `sizes.json` in a checkout; edit
  that, not this table." in both skills (`/fix` keeps its "`/fix`'s"),
  with no path: the coordinator reads this at run time, where the table
  is what counts and the JSON isn't read until #28. Agent files still
  carry none. The full path to `sizes.json` appears only in the docs and
  `.claude/CLAUDE.md`.
- `.apm/skills/brief/SKILL.md`: inline markers; "mirrors row 1" stays.
- `docs/workflow.md`: three block pairs; the labels change by generation
  (FR-005); under the `/feat` matrix add "Phase 6 runs one implementer per
  user story, in turn." (the review-fixes sentences under both matrices
  are already there); line 9–10 says the tables here and in both skills
  are generated from `.apm/skills/feat/sizes.json` (linked); line 63–64
  "drawn from `.apm/skills/feat/sizes.json` by `mise run diagrams`"
  (FR-016).
- `.claude/CLAUDE.md` (FR-015): the size-table bullet becomes: `sizes.json`
  is the source of models, efforts, loads and `/feat`'s groups; edit it
  and run `mise run diagrams`; never edit between `sizes-start`/`sizes-end`
  markers; lint fails on drift; the reviewer-group prose (under each
  table and in `docs/workflow.md`) stays hand-written and changes with the
  groups; the frontmatter sentence stays. The diagrams bullet: `models.svg`
  is drawn from `sizes.json` by `sizes.py --d2`. The third-party-skill
  bullet: "`loads` in `sizes.json`" for "the size table's `Loads` column".
  The shell bullet: `measure.py` is the one shipped Python script,
  `docs/diagrams/sizes.py` the repo-only one, both 3.11+ standard library,
  compiled and 3.11-checked by lint; `mise run test:sizes` joins the test
  list.
- `.specify/memory/constitution.md` (FR-015): principle III names
  `sizes.json` as the source for models, efforts, loads and `/feat`'s
  groups, the marked copies as generated by `mise run diagrams` and never
  edited by hand, lint as the drift check, and the group prose as the one
  hand mirror; version 1.3.0, Last Amended 2026-11-19 (R10).
- `CONTRIBUTING.md`: "Where things are" names `sizes.json` as the source;
  the two "bite most" bullets say edit the JSON and run `mise run
  diagrams`; `mise run test:sizes` joins the pre-PR list.
- `docs/usage.md` Tuning: in a checkout, edit `sizes.json` and run `mise
  run diagrams`; in an install, the coordinator reads the SKILL.md tables,
  so tune those. Lines 308–309 ("are the single source of truth") are
  reworded accordingly.
- Sweep (one task): `grep -rn "size table"` across `docs/`, `README.md`
  and `CONTRIBUTING.md`. Keep statements still true for installs (the
  coordinator passes model and effort from the table); reword those that
  call the tables the source or authority. Known hits:
  `docs/design.md:32` and `:181`, `docs/install.md:31`,
  `docs/workflow.md:522`, `docs/usage.md:308–309`.

## Project Structure

### Documentation (this feature)

```text
specs/011-size-data/
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
├── contracts/
│   ├── sizes-json.md
│   └── sizes-cli.md
└── tasks.md             # phase 5
```

### Source Code (repository root)

```text
.apm/skills/feat/sizes.json          new: the data
.apm/skills/feat/SKILL.md            markers, one sentence
.apm/skills/fix/SKILL.md             markers, one sentence
.apm/skills/brief/SKILL.md           inline markers
docs/diagrams/sizes.py               renamed from models.py, generator
docs/workflow.md                     markers, labels, prose
docs/usage.md                        Tuning paragraph
docs/design.md, docs/install.md      size-table sweep (reword only if they call the table the source)
README.md                            size-table sweep (grep only; no hit today)
docs/img/models.svg                  re-rendered, unchanged
tests/sizes/run.sh                   new
tests/sizes/fixtures/                new: sizes.json + 4 stale targets
tests/sizes/expected/                new: 4 generated targets + models.d2
mise.toml                            lint, diagrams, test:apm, test:sizes
.github/workflows/check.yml          test:sizes step, comment
.claude/CLAUDE.md                    rules
.specify/memory/constitution.md      principle III, 1.3.0
CONTRIBUTING.md                      source, tests
```

**Structure Decision**: no new directory outside `tests/sizes/`; the
generator stays in `docs/diagrams/` (not shipped), the JSON in the `feat`
skill dir (shipped).

## Order

1. JSON with today's values; `sizes.py --d2` and `cmp` against
   `models.py`'s output (quickstart 1) before `models.py` goes.
2. Generator write/check, markers in the four files, first generation;
   review the diff against `main` (quickstart 2).
3. Tests and fixtures; mise and CI wiring.
4. Prose, rules, constitution; `mise run lint`, `mise run test:sizes`,
   `mise run test:apm`, `mise run diagrams` + `git diff --exit-code
   docs/img`.

## Complexity Tracking

None: no constitution violation.
