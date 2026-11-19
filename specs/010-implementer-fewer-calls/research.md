# Research: Cut the implementer's model calls per spawn

All unknowns of the plan's Technical Context are resolved here; no
`NEEDS CLARIFICATION` is left. The spec left one choice open (assumption 4:
the layout of `story.sh`'s lines); the rest are decisions the spec did not
call for, taken as the simplest fit with the codebase.

## R1. `story.sh`'s output layout

- **Decision**: two forms, one line per fact, plain text.
  - All stories (`story.sh <tasks.md>`), for phase 5:
    `setup/foundational: <n> tasks: <IDs>`, then one `US<k>: <n> tasks: <IDs>`
    line per story in heading order, then `polish: <n> tasks: <IDs>`, then
    `total: <n> tasks`. IDs are listed one by one, space-separated, never
    as ranges; a group with no task reads `<label>: 0 tasks`. The setup and
    polish lines are always printed.
  - One story (`story.sh <tasks.md> US<k>`), for phase 6, compact: a
    header `US<k>: <n> tasks[; setup/foundational: <s> tasks][; polish: <p> tasks]; <u> unchecked`,
    then one line per task `<ID> [ ]|[x] paths: <paths | none>`, then
    `files: <every path, once | none>`. No task text.
    Exact grammar in [contracts/story-cli.md](contracts/story-cli.md).
- **Rationale**: the all-stories form lines up with the tasker's `Per
  story:` report group by group, with the IDs already expanded, so `/feat`
  only expands the tasker's side (spec assumption 4, US2 scenario 2). The
  one-story form carries what the first turn needs (which tasks, which are
  left, which files) and nothing the implementer reads anyway: the task
  text stays in tasks.md, which `speckit-implement` reads and ticks, so
  repeating it would only add prompt tokens re-read on every call (user
  decision at the design gate, D2). The `files:` line is the list the
  implementer's first turn reads together, so it does not have to collect
  it from the task lines. `<n> tasks` stays plural even for one task: the
  line is read by a model and a test, never by a person first, and the
  spec's literal `0 tasks` stays one pattern.
- **Alternatives considered**: TSV or JSON (needs `jq` or parsing on the
  reader's side, and `/feat` would read it less easily than plain lines);
  ranges in the all-stories form (then `/feat` would have to compare two
  range writings, which is what the spec rules out); per-task paths only,
  without `files:` (the implementer would merge them itself, one more
  thing to get wrong in the turn that matters most); each task line
  verbatim, as the brief worded it (rejected at the design gate, D2: cost,
  and task text in the prompt is more text to fence as data); truncated
  task lines (moot once the text is gone, D3).

## R2. Which section is a story phase

- **Decision**: a story phase starts at a level-2 heading that matches
  `^##[[:space:]]+Phase[^:]*:[[:space:]]*User Story[[:space:]]+<n>` (the
  Spec Kit tasks template's `## Phase 3: User Story 1 - …`). The story
  phases run from the first such heading to the first other level-2 heading
  after the last one. Untagged tasks before that span are
  setup/foundational, after it polish, inside it (a non-story level-2
  section between two story phases included) an error. Level-3 headings
  (`### Tests for User Story 1`) never start a section. Lines inside
  fenced code blocks (a line starting with three backticks toggles) are
  skipped. A task's story is the first `[US<n>]` marker right after its
  ID; a tag that names a story with no phase heading is an error.
- **Rationale**: all nine `specs/*/tasks.md` in this repo and the template
  use that heading; stories are not in number order (006 runs US2 first),
  so "first" and "last" story must come from position, as `/feat` phase 6
  already assigns setup and polish. Known stories must come from headings,
  not tags, to tell "a story with no tasks of its own" (FR-006, `0 tasks`)
  from "an unknown story" (non-zero). The orphan-tag error makes a heading
  written another way surface at phase 5 as a hard gate with one line,
  rather than as a silently wrong grouping (US2's purpose).
- **Alternatives considered**: any level-2 heading containing `User Story`
  (a `## Parallel Example: User Story 1` section after the polish phase
  would stretch the story span over polish and make its tasks errors);
  stories from tags only (no way to know a story with no tasks exists).

## R3. What a path is

- **Decision**: split the task text (after the ID and markers) on
  backticks; a span between a pair is a path when it holds no whitespace
  and either contains `/` or ends with `.` and a letter followed by
  letters or digits (`.md`, `.sh`, `.d2`, `.toml`), and holds none of
  `<`, `*` or `://`. Each task lists its paths once, in order of
  appearance; `files:` merges them across the printed tasks, first seen
  first. The paths are candidates: the implementer reads those that exist
  and skips the missing ones (D1).
- **Rationale**: FR-004 says "a backticked token"; a token has no space,
  which is what tells `mise run lint` or `git status --short` (commands)
  from `.apm/skills/feat/SKILL.md`. Requiring a letter after the dot keeps
  version numbers (`2.103.3`) out. Tasks in this repo write placeholders
  (`.specify/bugs/<slug>/`), globs and URLs in backticks; none can be read
  as one file, so the script drops them rather than have the implementer's
  first turn fail on them (D1, the drop is the planner's choice; one test
  line covers it).
- **Alternatives considered**: matching paths outside backticks (the spec
  rules it out, and prose such as "and/or" would match); checking the
  path exists on disk (tasks name files they will create); leaving
  placeholders and globs in `files:` for the implementer to skip (one more
  judgement in the turn that matters most, for a one-line filter).

## R4. Errors and exit codes

- **Decision**: like `tracker.sh`: everything on stdout, nothing on
  stderr; a failure is one line `story: error: <why>` with exit 1; a usage
  error is `story: usage: story.sh [--] <tasks.md> [US<n>]` with exit 2.
  A leading `--` is dropped first (R13). The
  checks, in order: usage; the file is a readable regular file; at least
  one `[US<n>]` tag; the first task (in file order) that is untagged inside
  the story phases or tagged with a story that has no phase heading,
  named with its ID and line number; the story argument names a story
  phase.
- **Rationale**: `/feat` runs it "like `tracker.sh`" (FR-010) and shows
  the one line at the gate (US2 scenario 4). Checking "no tag at all"
  before the per-task errors gives a file without tags the FR-006 message
  rather than "T001 is untagged".
- **Alternatives considered**: stderr for errors (`secret-scan.sh`'s
  convention; `/feat` would then have to read two streams for one line).

## R5. Language and tools

- **Decision**: bash 4 (as `tracker.sh`, which uses `declare -A`),
  `set -euo pipefail`, `LC_ALL=C`, built-ins only for the parse (`[[ =~ ]]`,
  arrays); no `awk`, `sed`, `jq` or Python.
- **Rationale**: FR-013 allows nothing beyond what `tracker.sh` uses;
  constitution V asks for bash and shellcheck. `LC_ALL=C` makes the
  regex classes byte-wise, so the UTF-8 in task text (em dashes, emoji in
  `🎯 MVP` headings) passes through untouched.
- **Alternatives considered**: Python (allowed by principle V only where
  bash would aggregate JSON; not the case).

## R6. Test fixtures and the ground truth

- **Decision**: `tests/story/` modelled on `tests/secret-scan/` (no stub
  needed: no `gh`, no git). Real fixtures: frozen copies of
  `specs/006-rebase-when-main-moves/tasks.md` and
  `specs/009-soft-design-gate/tasks.md`. Their expected all-stories output
  is written by hand from those runs' phase 5 Log lines (the tasker's own
  grouping, see [quickstart.md](quickstart.md)), so the test compares the
  parser with an independent source, the way phase 5 will. Synthetic
  fixtures cover what the real ones lack (unchecked tasks, a story with no
  tasks, the error cases, a fenced task line).
- **Rationale**: 006 has stories out of number order and both setup and
  foundational phases; 009 is small with every group present. Both are
  fully ticked, hence the synthetic unchecked cases. Copies, not the live
  files, so a later edit of a spec dir cannot change a test.
- **Alternatives considered**: pointing the test at `specs/` in place
  (the shipper renames spec dirs; fixtures would move under the test);
  golden outputs generated by the script itself (circular).

## R7. Who compares the report with `story.sh`

- **Decision**: `/feat` compares, reading two texts it already holds: the
  tasker's `Per story:` line and `story.sh`'s output. `story.sh` does not
  parse the tasker's prose.
- **Rationale**: the spec puts the comparison in `/feat` (FR-007); the
  tasker's report is free prose (`US4 T028–T030, T039`, "with setup"), and a
  bash parser of it would be the fragile part. Expanding ranges and
  comparing two ID lists is mechanical, not code reading (principle I).
- **Alternatives considered**: a `--compare` mode in `story.sh` (moves a
  judgement into a prose parser; out of the spec).

## R8. A tasker report that folds setup into a story

- **Decision**: a difference, as FR-007 says: the tasker's report format
  already asks for setup/foundational and polish IDs apart, and the recent
  runs (004, 006 to 009) list them apart. `/feat` identifies the tasker's
  groups by their labels (setup and foundational together, polish, each
  `US<n>`); IDs with no label, or a grouping that reads two ways, are a
  difference too (D6). A report that folds them into the first or last
  story makes the gate hard; the fix goes back to the tasker, which
  reports again. Example mapping in [quickstart.md §2](quickstart.md).
- **Rationale**: the spec rules out a soft gate on a mismatch and any
  change to the tasker's report format; a lenient rule would be a
  judgement `/feat` must make, which this feature removes.
- **Alternatives considered**: comparing per implementer (first story plus
  setup) instead of per group; contradicts US2 scenario 1.

## R9. No fallback when `story.sh` fails

- **Decision**: phase 6 never starts without a clean `story.sh` run. On a
  non-zero exit at phase 5, the hard gate recommends sending the line to
  the tasker as an accepted fix (it fixes tasks.md and reports again); the
  user may also edit tasks.md and say go on. `/feat` runs `story.sh` again
  before phase 6 either way. A non-zero exit in phase 6 (tasks.md changed
  since phase 5) is a hard gate with the line.
- **Rationale**: FR-009 makes `story.sh`'s IDs the ones each implementer
  owns; a fallback to the tasker's prose IDs is the path this feature
  closes. Any error `story.sh` reports is fixable in tasks.md.
- **Alternatives considered**: "go on" with the tasker's IDs and no
  `story.sh` output (one more branch in `/feat` for a case the tasker can
  fix).

## R10. The bug-mode first turn

- **Decision**: in bug mode, the first turn sends `git status --short`
  with the reads of the bug report and `assessment.md`; the Spec Kit reads
  come after `speckit-bug-fix` is invoked (the skill is not preloaded, so
  its reads can't be in the first turn); the files `assessment.md` lists go
  together in the turn after it is read. FR-011 and US3 say so (D4).
- **Rationale**: `/fix` passes the implementer no file list and never reads
  `assessment.md` (thin coordinator), so the listed files are known only
  once `assessment.md` is read. The batch is the same; it lands one turn
  later.
- **Alternatives considered**: `/fix` passing the assessor's file list
  (the brief rules `/fix` changes out: FR-012).

## R11. Mirrors beyond FR-015

- **Decision**: besides the phase table, section 5, `docs/workflow.md`
  (phase table row 5, the sizes matrix's hard-gates row, section 5) and
  `docs/diagrams/gates.d2`: `docs/diagrams/chain.d2`'s phase 5 gate label
  and the README's `gates.svg` alt text, which name that gate; and
  `docs/workflow.md` section 6, one sentence on the `story.sh` output and
  the one-turn rule. CI (`.github/workflows/check.yml`) and
  `CONTRIBUTING.md`'s checks list gain `test:story`; `test:apm` checks the
  script lands.
- **Rationale**: `.claude/CLAUDE.md` says a change to `/feat`'s gates
  updates `gates.d2` and `chain.d2`; the alt text describes the diagram;
  every other test task runs in CI and in `test:apm`'s file checks.

## R12. "Part of #55" in the PR body

- **Decision**: no repo change. The shipper writes `Closes <issue>` when
  the state file names an issue; the brief's acceptance (in the state
  file `/feat` reads) asks for `Part of #55`, so `/feat` passes that to the
  shipper as a run convention at phase 8.
- **Rationale**: changing the shipper is out of scope ("any other agent").

## R13. Running `story.sh` and passing its output safely

- **Decision**: `/feat` runs `story.sh` only on the tasker's `Tasks:` path
  once that path is on the report's `Wrote:` and passed the `ls -d` check
  (section 5 already gates on both), single-quoted and after `--`:
  `bash <base>/scripts/story.sh -- '<tasks.md>' [US<n>]` (D8). `story.sh`
  drops one leading `--` and takes no option, so any other first argument
  is the path. In phase 6 the one-story output goes into the prompt
  between two lines of four backticks, labelled as data; on exit 0 the
  output holds no backtick (labels, IDs, `[ ]`/`[x]`, and paths, which are
  spans between backticks), so the fence is longer than any backtick run
  in it, and the implementer treats everything up to the closing fence as
  data (D7).
- **Rationale**: the path comes from an agent's prose report; checking it
  against `Wrote:` and the disk first, as `/feat` does for every reported
  path, keeps the script on the file the tasker wrote, and `--` keeps a
  path starting with `-` from reading as an option. A four-backtick fence
  around text with no backtick cannot be closed by the content, so nothing
  in tasks.md can step out of the data block.
- **Alternatives considered**: a labelled heredoc-style delimiter (a
  Markdown fence is what a model reads as a block, and four backticks are
  enough when the content holds none); escaping backticks in the output
  (none can occur).
