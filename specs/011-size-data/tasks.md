# Tasks: Size tables generated from one data file

**Input**: `specs/011-size-data/` (spec.md, plan.md, research.md, data-model.md, contracts/, quickstart.md)

**Prerequisites**: plan.md, spec.md

**Tests**: requested by FR-018 (offline tests under `tests/sizes/`); they sit in US2, where the check lives, and cover generate too.

**Organization**: by user story. Paths are relative to the worktree root.

## Format: `[ID] [P?] [Story] Description`

## Phase 1: Setup

- [x] T001 Save today's diagram source: `python3 docs/diagrams/models.py > /tmp/models-old.d2` (reference for T005; `models.py` stays until T003 renames it)

---

## Phase 2: Foundational (blocks all stories)

**Purpose**: the data file and the generator's load, validate and D2 paths.

- [x] T002 Create `.apm/skills/feat/sizes.json` with today's values: `{"feat": {"rows": [...], "groups": {"4": {...}, "7": {...}}}, "fix": {"rows": [...]}}`; row `{"id", "label", "agent", "loads", "small", "medium", "large"}`, each size `{"model", "effort"}`; `loads` a list of skill names (`[]` for none); labels are the skill tables' labels without the id (the skills' wording wins, FR-005); take every value from the two SKILL.md tables and from `docs/diagrams/models.py`'s groups. Schema in `specs/011-size-data/data-model.md` and `contracts/sizes-json.md`
- [x] T003 `git mv docs/diagrams/models.py docs/diagrams/sizes.py`, then in `docs/diagrams/sizes.py`: add JSON loading and validation (FR-020, exit 2 naming the field): `label` without `|`, newline or other control character; `agent` and each `loads` entry matching `^[a-z0-9-]+$`; unknown keys rejected at top level, in a skill and in a row; the set of `/feat` phases must equal the diagram's eight fixed `(phase, title)` pairs (R2). Python 3.11 standard library only
- [x] T004 In `docs/diagrams/sizes.py`: replace `size_table()` and `COLUMNS`' groups with the JSON (`feat.groups[phase][size]`, else the phase's single row), keep `FILL`, `FONT`, `WIDTH`, `GAP`, the layout loop and `strongest` unchanged; add `--root DIR` and `--d2` (prints the D2 source; exit 0/1/2 per `contracts/sizes-cli.md`)
- [x] T005 Run `python3 -I docs/diagrams/sizes.py --d2 > /tmp/models-new.d2` and `cmp /tmp/models-old.d2 /tmp/models-new.d2` (quickstart 1, SC-004); fix until identical

**Checkpoint**: data file exists and the diagram source is byte-identical.

---

## Phase 3: User Story 1 - Change a model or effort in one place (P1) MVP

**Goal**: one JSON edit plus `mise run diagrams` updates every copy.

**Independent Test**: quickstart 2 and 3: first generation changes only FR-005 labels and padding; a changed value shows in every copy.

- [x] T006 [US1] In `docs/diagrams/sizes.py`: add the table renderer (pad every column to its widest cell, counting code points, FR-009) and the renderers for the skill tables (id and label joined, `Loads` kept, FR-002/FR-010), the two docs matrices (`#` column, fixed `1 Brief / your session` row and `huge` column, no `Loads`, FR-006), the agents table's `small size` cell (R4, R5, FR-007; errors for an agent line without a row, a row agent without a line, or a cell count differing from the header) and the `/brief` sentence (R6, consecutive equal sizes grouped)
- [x] T007 [US1] In `docs/diagrams/sizes.py`: add marker handling and write mode (R3, R8, FR-008): `<!-- sizes-start NAME -->` / `<!-- sizes-end NAME -->`; names `feat-table`, `fix-table`, `brief-review` (inline), `feat-matrix`, `fix-matrix`, `agents-table`; missing, unpaired, duplicated or unknown marker is exit 2 naming file and marker; read targets as UTF-8 without newline translation, compute every region, write only when no error and only the changed files; text outside markers untouched
- [x] T008 [P] [US1] Add the markers around the table (bytes unchanged) in `.apm/skills/feat/SKILL.md` (`feat-table`) and `.apm/skills/fix/SKILL.md` (`fix-table`), block form: marker, blank line, table, blank line, marker; reword the "single source of truth" sentence in both as the plan's Text changes says (no path; `/fix` keeps "`/fix`'s")
- [x] T009 [P] [US1] In `.apm/skills/brief/SKILL.md` reflow the paragraph once so row 1's sentence sits on one line and wrap it in the inline `brief-review` markers; "mirrors row 1" stays
- [x] T010 [P] [US1] In `docs/workflow.md` add the `feat-matrix`, `fix-matrix` and `agents-table` block markers (agents table: whole table), add under the `/feat` matrix "Phase 6 runs one implementer per user story, in turn." (check the review-fixes sentences under both matrices are present, FR-005), and reword lines 9-10 and 63-64 (generated from, and drawn from, `.apm/skills/feat/sizes.json` by `mise run diagrams`, FR-016)
- [x] T011 [US1] Update `mise.toml`: `diagrams` runs `python3 -I docs/diagrams/sizes.py` first, then the two `d2` lines, then `python3 -I docs/diagrams/sizes.py --d2 | d2 … - docs/img/models.svg`, with the description from the plan; `lint`'s `py_compile` lists `docs/diagrams/sizes.py` in place of `models.py` and its `ast` 3.11 check covers `measure.py` and `sizes.py` (FR-016, FR-017)
- [x] T012 [US1] Run `mise run diagrams`, then `git diff --word-diff main -- .apm/skills docs/workflow.md` and `git diff --exit-code docs/img` (quickstart 2): no `model · effort` change, only FR-005 labels, markers, the reflow, padding and the T010 prose; a second run changes nothing

**Checkpoint**: US1 works alone.

---

## Phase 4: User Story 2 - Lint fails on drift (P1)

**Goal**: hand edits, unregenerated data changes and bad markers fail, naming the file.

**Independent Test**: quickstart 4 and `mise run test:sizes`.

- [x] T013 [US2] In `docs/diagrams/sizes.py`: add `--check` (compare fresh text with each file's marked text, exit 1 naming each differing file; bad marker or invalid JSON exit 2, same errors as write mode, nothing written)
- [x] T014 [P] [US2] Create `tests/sizes/fixtures/`: `sizes.json` (values differ from today's: small code-review group `7a+7b` with `sonnet · high` and `opus · medium` so the cell is `opus` / `high`; one fix-only agent with two distinct small values and another with one) and stale `feat-SKILL.md`, `fix-SKILL.md`, `brief-SKILL.md`, `workflow.md` with markers, including an agents table
- [x] T015 [US2] Create `tests/sizes/expected/` (`feat-SKILL.md`, `fix-SKILL.md`, `brief-SKILL.md`, `workflow.md`, `models.d2`) by running the generator on the fixtures and reviewing each by hand against the rules, not just accepting the output (depends on T007, T013, T014)
- [x] T016 [US2] Create `tests/sizes/run.sh` (bash, shellcheck clean): copy fixtures into a temp root at the real paths, run `python3 -I docs/diagrams/sizes.py --root`, compare with `expected/`; cases per plan: fresh equals expected; second run writes nothing; check passes on fresh; check exit 1 naming each file on stale, a hand-edited cell and a data change; missing, unpaired (start only, end only), duplicated and unknown markers exit 2 in both modes, file and marker named, nothing written; agents-table line without a row and row agent without a line fail; `--d2` equals `models.d2`; one-value and two-value agents cells; newline in a `label`, a space in an `agent`, an unknown top-level key each exit 2 naming the field and writing nothing
- [x] T017 [US2] Update `mise.toml`: `lint` adds `python3 -I docs/diagrams/sizes.py --check` and `shellcheck tests/sizes/run.sh` and names the size check in its description; new task `test:sizes` = `bash tests/sizes/run.sh`; in `.github/workflows/check.yml` add a `mise run test:sizes` step and change the docs/img comment to "their sources and sizes.json"
- [x] T018 [US2] Run `mise run test:sizes` and `mise run lint`; then quickstart 4 (hand-edit fails naming `.apm/skills/feat/SKILL.md`, lost `fix-matrix` marker exits 2 in both modes) and revert

**Checkpoint**: US1 and US2 work.

---

## Phase 5: User Story 3 - Data file a later command can read (P2)

**Goal**: the JSON ships in an install and parses with standard readers.

**Independent Test**: quickstart 6.

- [x] T019 [US3] Add `test -f .claude/skills/feat/sizes.json` to `mise.toml`'s `test:apm` (FR-017); run `mise run test:apm`, and the jq, Python and node one-liners from quickstart 6 (SC-006)

---

## Phase 6: User Story 4 - Rules and diagram follow the new source (P2)

**Goal**: rules and docs describe the JSON, not hand mirroring.

**Independent Test**: quickstart 7.

- [x] T020 [P] [US4] Update `.claude/CLAUDE.md` as the plan's Text changes says (FR-015): size-table bullet (edit `sizes.json`, run `mise run diagrams`, never edit between markers, lint fails on drift, group prose stays hand-written, frontmatter sentence stays), diagrams bullet (`sizes.py --d2`), third-party-skill bullet (`loads` in `sizes.json`), shell bullet (`sizes.py` repo-only Python, `test:sizes` in the test list)
- [x] T021 [P] [US4] Amend `.specify/memory/constitution.md` principle III (source `sizes.json`; marked copies generated by `mise run diagrams`, never edited by hand; lint as the drift check; group prose the one hand mirror); version 1.3.0, Last Amended 2026-11-19 (R10); update its sync-impact note if it has one
- [x] T022 [P] [US4] Update `CONTRIBUTING.md`: "Where things are" (lines ~35-38) names `sizes.json` as the source; the two "bite most" bullets (~56-60) say edit the JSON and run `mise run diagrams`; `mise run test:sizes` joins the pre-PR list
- [x] T023 [P] [US4] Reword `docs/usage.md` Tuning (~308-309 and ~349): in a checkout edit `sizes.json` and run `mise run diagrams`; in an install the coordinator reads the SKILL.md tables, so tune those
- [x] T024 [US4] Sweep `grep -rn "size table" docs README.md CONTRIBUTING.md`: reword only statements calling the tables the source or authority (`docs/design.md:32`, `:181`, `docs/install.md:31`, `docs/workflow.md:522`; README has no hit); keep those still true for installs
- [x] T025 [US4] Run quickstart 7: `grep -rn models.py --exclude-dir=specs .` finds nothing (also check `docs/diagrams/`, `mise.toml`, workflow files)

---

## Phase 7: Polish

- [ ] T026 Run quickstart 3 (one edit, one command; revert with `git checkout --`), then `mise run lint`, `mise run test:sizes`, `mise run test:apm`, `mise run diagrams` and `git diff --exit-code docs/img`; confirm `docs/img` is committed-clean and `scripts/` still holds only `measure.py` (FR-019)

---

## Dependencies and order

- Setup T001, then Foundational T002 to T005 in order (T003, T004 touch one file: not parallel).
- US1 (T006 to T012) needs Foundational; T008 to T010 are parallel with each other and need T007 only for T012. T011 before T012.
- US2 needs US1's generator (T013 after T007); T014 can start once T002 is done; T015 needs T007, T013, T014; T016 after T015; T017, T018 after T016.
- US3 (T019) needs T002 and T011/T017's `mise.toml` edits done first (same file: sequential).
- US4 (T020 to T025) is independent of the code once T011 and T017 are in; T020 to T023 are parallel; T024 after T023 (same docs); T025 last.
- Polish T026 last.
- `mise.toml` is touched by T011, T017, T019: keep them sequential.

## Parallel example

After T007: T008, T009, T010 together. After T018: T020, T021, T022, T023 together.

## Implementation strategy

MVP = Setup + Foundational + US1 (T001 to T012): the JSON, the generator and all copies generated. Then US2 (the drift check and tests that make the copies trustworthy), US3 and US4, then Polish. Follow the plan's Order: JSON and `--d2` cmp before `models.py` goes (T001 saves the old output first), generator and markers, tests and wiring, then prose and rules.
