# Feature Specification: Size tables generated from one data file

**Feature Branch**: `size-data`

**Created**: 2026-11-19

**Status**: Draft

**Input**: User description: "Generate the size tables and every copy of them from one JSON data file, and fail lint on drift" (brief: `specs/briefs/size-data.md`, issue #30)

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Change a model or effort in one place (Priority: P1)

A maintainer of logistics wants to change the model or effort of one workflow step. Today they edit up to six hand-written copies and nothing fails when one is missed. They edit one data file, run one command, and every copy shows the new value.

**Why this priority**: This is the point of the feature: one source of truth, and copies that cannot disagree with it.

**Independent Test**: Change one model or effort in the data file, run the generate command, and check that both skills' size tables, the `/brief` sentence, both matrices in the workflow doc, the agents table's "small size" cell and the models diagram show the new value and nothing else changed.

**Acceptance Scenarios**:

1. **Given** the data file with today's values, **When** the maintainer runs the generate command, **Then** no model or effort changes anywhere; only the labels listed in FR-005 and whitespace padding differ from `main`.
2. **Given** one model changed in the data file, **When** the maintainer runs the generate command, **Then** every marked copy and the diagram source show the new value for that row and size.
3. **Given** an agent that appears in rows of both skills with different small-size values, **When** the agents table is generated, **Then** its "small size" cell lists each distinct value with its row's label in lowercase (for example "opus · medium (assess), sonnet · medium (test)").
4. **Given** an agent whose rows all share one small-size value, **When** the agents table is generated, **Then** its cell shows that value alone.

---

### User Story 2 - Lint fails on drift (Priority: P1)

A maintainer (or CI) wants a hand edit of a generated copy, or a data change that was not regenerated, to fail the build and name the file, so drift can no longer go unnoticed.

**Why this priority**: Without the check, a single source is only a convention; the check is what makes the copies trustworthy.

**Independent Test**: Edit a marked copy by hand, run lint, and see a failure naming that file; regenerate, and lint passes.

**Acceptance Scenarios**:

1. **Given** freshly generated copies, **When** lint runs, **Then** it passes.
2. **Given** a marked region edited by hand, or a data change not regenerated, **When** lint runs, **Then** it exits non-zero and names each differing file.
3. **Given** a marker that is missing, unpaired or duplicated in any target file, **When** the generator runs in generate or check mode, **Then** it fails naming the file and the marker; a lost marker never makes the check pass.

---

### User Story 3 - Data file a later command can read (Priority: P2)

The author of the future boundary command (#28) needs the sizes in a form readable from bash with jq, Python or JS, and shipped in an install, so that command can print the next spawn's model and effort.

**Why this priority**: It does not change today's behaviour, but its path and format are a contract for #28.

**Independent Test**: Install the package and find the data file at its documented path inside the installed skill; parse it with a standard JSON reader.

**Acceptance Scenarios**:

1. **Given** an install, **When** the installed skill directory is listed, **Then** the data file is present at the same relative path as in the source.
2. **Given** the data file, **When** read, **Then** it holds per skill (`feat`, `fix`) each row's id, label, agent, loads and model · effort per size, plus `/feat`'s reviewer groups per size.

---

### User Story 4 - Rules and diagram follow the new source (Priority: P2)

A maintainer reading `.claude/CLAUDE.md` and constitution principle III, or running the diagrams task, finds them describing and using the data file, not hand mirroring.

**Why this priority**: Stale rules would tell maintainers to hand-edit generated text.

**Independent Test**: Read the mirroring paragraph and principle III; run the diagrams task and compare the produced `models.svg` with the committed one.

**Acceptance Scenarios**:

1. **Given** the updated rules, **When** read, **Then** they say to edit the data file and run the generator, keep the rule for the hand-written reviewer-group prose, and name the data file in principle III.
2. **Given** the diagrams task, **When** run, **Then** `models.svg` is identical to today's.

### Edge Cases

- A marker pair appears twice, once, or with only an opening or closing half: error naming file and marker, in both modes.
- The agents table has an agent with no row in the data file, or a row's agent has no table line: the generator fails rather than skipping silently.
- A table cell is wider than the rest of its column after a label change: padding is recomputed per column, so the result is stable on a second run.
- Text outside markers (reviewer-group prose, other agents-table columns) must be left byte-for-byte unchanged.
- The `/fix` docs matrix and the agents table change in whitespace only on first generation.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The repo MUST hold a JSON data file shipped with the `/feat` skill at `.apm/skills/feat/sizes.json` (installed as `.claude/skills/feat/sizes.json`), holding per skill (`feat`, `fix`) each row's `id`, `label` (without the id), agent, `Loads` and model · effort per size (small, medium, large), and `/feat`'s reviewer groups per size. It MUST start with today's values.
- **FR-002**: Each row MUST have one label, used by every copy; the generator MUST join id and label for the skills (for example "1 Brief review (`/brief`)") and put the id in the docs' `#` column.
- **FR-003**: A generator written in Python 3.11+ using only the standard library, run as `python3 -I`, living in `docs/diagrams/` and replacing `docs/diagrams/models.py` (renamed, for example `sizes.py`), MUST rewrite the text between HTML comment markers in `.apm/skills/feat/SKILL.md`, `.apm/skills/fix/SKILL.md`, `.apm/skills/brief/SKILL.md` and `docs/workflow.md`.
- **FR-004**: Table markers MUST wrap the whole table, header included. In `.apm/skills/brief/SKILL.md` an inline pair MUST wrap row 1's sentence ("small and medium `sonnet` · `medium`, large `opus` · `medium`"). In `docs/workflow.md` markers MUST wrap the size × phase matrix, `/fix`'s size matrix and the agents table's "small size" cells.
- **FR-005**: The docs' wording MUST change only in these labels: `/feat` 1 "Brief review" becomes "Brief review (`/brief`)"; `/feat` 4a–4c lose "∥"; `/feat` 5 "Tasks + analyze" becomes "Tasks"; `/feat` 6 "Implement (×1 per story)" becomes "Implement"; `/fix` 2 "Fix (review fixes and moves)" becomes "Fix". What the dropped words said (one implementer per story; review fixes and moves use the phase 6 / phase 2 row) MUST stay in the prose under each table.
- **FR-006**: The generator MUST add the docs-only parts as fixed template text: the "1 Brief / your session" row, the `huge` column ("first capability's size" on row 1, "—" elsewhere), and no `Loads` column in the docs.
- **FR-007**: In the agents table the generator MUST replace only the "small size" cells, in place; the other columns stay hand-written. A cell is the agent's distinct small values across both skills' rows: one value is printed as is; several are each printed with their row's label in lowercase.
- **FR-008**: A missing, unpaired or duplicated marker MUST be an error in both generate and check modes, naming the file and marker.
- **FR-009**: Table padding MUST be normalised to the widest cell of each column.
- **FR-010**: The generated tables MUST keep the same markdown table shape the coordinator reads today; nothing changes at run time.
- **FR-011**: A check mode (for example `--check`) MUST exit non-zero and name each file whose marked text differs from a fresh generation. `mise run lint` MUST run it.
- **FR-012**: A mise task (or `mise run diagrams`) MUST regenerate every copy; changing a model or effort is one edit to the JSON plus one command.
- **FR-013**: The generator MUST print the D2 source of `models.svg`, as `models.py` does today, with `/feat`'s groups read from the JSON. `mise run diagrams` MUST produce a `models.svg` identical to today's, and the CI step that renders and diffs `docs/img` stays.
- **FR-014**: The reviewer-group prose under each table MUST stay hand-written, and the check MUST NOT cover drift between the JSON's group lists and that prose.
- **FR-015**: `.claude/CLAUDE.md`'s mirroring rules and constitution principle III MUST be rewritten: the JSON is the source of truth for models, efforts and loads; marked copies are generated, never edited by hand. The mirroring paragraph shrinks to "edit the JSON, run the generator" plus the group-prose rule.
- **FR-016**: Every place naming `models.py` or "read from the size table" MUST follow the rename and new source: `mise.toml`'s `py_compile` list, its `diagrams` task and description, and `docs/workflow.md`'s "drawn from the size table by `mise run diagrams`".
- **FR-017**: `mise run lint` MUST compile and syntax-check the generator against Python 3.11, like `measure.py`; `mise run test:apm` MUST check that `.claude/skills/feat/sizes.json` lands in an install.
- **FR-018**: Offline tests under `tests/`, using a fixture JSON, MUST cover generate and check: a drifted copy fails, a fresh one passes, a missing marker fails, a duplicated marker fails, the strongest-of-a-group cell, and an agents-table cell with one value and with several.
- **FR-019**: `measure.py` MUST stay the only script in the shipped `scripts/`; the JSON ships, the generator does not.
- **FR-020**: Because generated text lands in SKILL.md files the coordinator reads as instructions, the generator MUST validate the JSON before writing or checking anything, and fail naming the field: a `label` matches `[A-Za-z0-9 ,()`/-]+` (letters, digits, space and `, ( ) ` / -`); an `agent` and each `loads` entry match `^[a-z0-9-]+$`; an unknown key at the top level, in a skill or in a row is rejected.

### Key Entities

- **Size data file**: The single source of truth. Holds a section per skill with ordered rows, plus `/feat`'s reviewer groups per size.
- **Row**: One workflow step: id (for example `1`, `4a`), label, agent, loads, and model · effort for each of small, medium and large.
- **Reviewer group**: For `/feat`, a named list of rows per size, used to draw the diagram (the strongest-of-a-group rule picks the group's displayed model).
- **Marked region**: Text between a pair of HTML comment markers in a target file, owned by the generator.
- **Agents table "small size" cell**: Derived from the distinct small values of the agent's rows across both skills.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Changing one model or effort takes exactly one data edit and one command, after which all seven kinds of copy (both skills, `/brief`, both docs matrices, the agents table cell, the diagram) show the new value.
- **SC-002**: Lint fails, naming the file, in 100% of these cases: a marked copy edited by hand, a data change not regenerated, a marker missing, unpaired or duplicated; it passes on a fresh generation.
- **SC-003**: The pull request's diff of generated copies against `main` changes zero model · effort values; only the FR-005 labels and padding change.
- **SC-004**: The regenerated `models.svg` is byte-identical to today's.
- **SC-005**: The offline tests listed in FR-018 pass, and lint and the apm install test stay clean.
- **SC-006**: A reader can parse the installed data file with jq, Python or JS without extra dependencies.

## Assumptions

- The generator's name is `sizes.py` in `docs/diagrams/`; the exact check flag name and mise task name are plan decisions within FR-011 and FR-012.
- Marker text follows the style of release-please's markers in `docs/install.md` and is invisible on the website because it renders raw HTML.
- The data file's field names are chosen in the plan; they become a contract for #28 once merged.
- The `huge` column exists only in the docs matrix and is fixed template text, so the JSON holds no `huge` values.
- Existing hand-written content outside the markers is already consistent with today's JSON values, so the first generation changes nothing but labels and padding.

## Out of Scope

- A runtime lookup command printing a spawn's model and effort (#28).
- Removing the tables from the SKILL.md files (decided in #28's brief).
- `/fix`'s reviewer groups in the JSON.
- Generating the reviewer-group prose or the agents table's other columns.
- Changing any model, effort or group.
