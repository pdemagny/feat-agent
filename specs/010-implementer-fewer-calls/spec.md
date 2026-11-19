# Feature Specification: Cut the implementer's model calls per spawn

**Feature Branch**: `implementer-fewer-calls`

**Created**: 2026-11-19

**Status**: Draft

**Input**: User description: "Brief specs/briefs/implementer-fewer-calls.md (issue #55, part of epic #31): feat-implementer is 49% of a /feat run's weighted cost in the maintainer's busiest project, with a median of 45.8 model calls per spawn. Cut the calls with a story.sh script that gives /feat and each implementer a parsed view of tasks.md, a phase 5 cross-check of the tasker's report, and a short one-turn rule in the implementer's agent file."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - The implementer receives its story's tasks and files up front (Priority: P1)

The person running `/feat` gets implementers that start from a ready list: each implementer's prompt carries its story's task IDs, whether each is checked, and the file paths they name, so its first turn can read those files together instead of discovering them one call at a time. The task text stays in `tasks.md`, which the implementer reads and ticks. A script, `story.sh`, produces that list from `tasks.md`.

**Why this priority**: This is the data the whole feature rests on. Without the paths arriving before `tasks.md` is read, the first turn cannot batch the story's reads. Fewer calls per spawn is the largest lever epic #31 has left on tokens and agent time; every `/feat` user pays for the implementer's spend.

**Independent Test**: Run `story.sh` on a real `tasks.md` with a story number and check the output: one line per task of that story with its ID, its checked state and its paths, setup/foundational tasks attached to the first story, polish tasks to the last, the unchecked count and the merged `files:` line.

**Acceptance Scenarios**:

1. **Given** a `tasks.md` with tagged story tasks, **When** `story.sh <tasks.md> US2` runs, **Then** it prints a header with the counts and how many of those tasks are unchecked, one line per task with its ID, its checked state and the file paths it names (no task text), and a `files:` line merging every path once.
2. **Given** setup/foundational tasks before the first story phase and polish tasks after the last, **When** `story.sh` runs for the first story, **Then** the setup/foundational tasks are included; **When** it runs for the last story, **Then** the polish tasks are included.
3. **Given** a task text with a backticked token containing `/` or ending in a file extension, **When** `story.sh` runs, **Then** that token is listed as a path; a backticked command such as `mise run lint`, a backticked placeholder (`<…>`), glob (`*`) or URL (`://`), and text outside backticks are not.
4. **Given** a task naming no path, or several, or carrying a `[P]` marker, **When** `story.sh` runs, **Then** it prints it correctly (no path, all paths, the marker not read as a story).
5. **Given** checked and unchecked tasks, **When** `story.sh` runs, **Then** the unchecked count matches the unchecked tasks printed.
6. **Given** a story with no tasks of its own, **When** `story.sh` runs for it, **Then** it prints `0 tasks` and exits 0, and setup and polish still attach to it by position.
7. **Given** an unknown story, a `tasks.md` with no `[US<n>]` tag at all, or an unreadable file, **When** `story.sh` runs, **Then** it exits non-zero with one line saying why.
8. **Given** an untagged task inside a story phase, **When** `story.sh` runs, **Then** it exits non-zero with one line naming that task.

---

### User Story 2 - Phase 5 checks the tasker's report against tasks.md (Priority: P1)

The person running `/feat` is stopped at phase 5 when the tasker's prose report and `tasks.md` disagree on which tasks belong to which group. Today nothing checks the task IDs `/feat` hands to each implementer.

**Why this priority**: The implementers' task ownership would now rest on `story.sh`; a parse gap or a wrong report must surface before the implementers start, the last cheap moment. It also takes a judgement out of `/feat`.

**Independent Test**: Feed phase 5 a tasker report and a `tasks.md` whose ID sets differ in one group, and check that the gate is hard and shows both sides; feed it matching ones and check that it is unchanged.

**Acceptance Scenarios**:

1. **Given** `story.sh <tasks.md>` without a story, **When** it runs, **Then** it prints each story's task IDs and count, plus setup/foundational and polish on their own lines, marked as such and not folded into a story.
2. **Given** the tasker's report with ranges such as `T001–T012`, **When** `/feat` compares it with `story.sh`'s output group by group (each story, setup/foundational, polish), **Then** ranges are expanded first, so a range written differently is not a difference.3. **Given** any real difference in a group's ID set or count, **When** phase 5 ends, **Then** the gate is hard and shows both sides.
4. **Given** `story.sh` exits non-zero in phase 5, **When** phase 5 ends, **Then** the gate is hard and shows the one-line reason.
5. **Given** `story.sh`'s figures, **When** the size check runs, **Then** it uses them.
6. **Given** matching IDs and counts, **When** phase 5 ends, **Then** its gate behaves as it did before this feature.
7. **Given** the tasker's report, **When** `/feat` reads its groups, **Then** it identifies the setup, foundational and polish IDs by their labels; IDs the report leaves unlabelled, or a grouping that could be read two ways, count as a difference.

---

### User Story 3 - The implementer batches independent tool calls (Priority: P1)

The person running `/feat` or `/fix` pays for fewer model calls per implementer spawn, because the implementer sends independent tool calls in one turn. In story mode its first turn sends together `git status --short`, the Spec Kit reads its skill requires, and the files its tasks name that exist. In bug mode its first turn sends `git status --short` with the reads of the bug report and `assessment.md`; the Spec Kit reads come after `speckit-bug-fix` is invoked, and the files `assessment.md` lists go together in the turn after it is read. After that it sends together the searches before a task, the edits to different files, and the ticks of one task group. In fix and rebase mode only the "one turn" sentence applies.

**Why this priority**: This is the lever itself: a median spawn spends 11 calls before the first edit, 8 of them shell searches, and 76% of calls carry a single tool call. `git status --short` in the first turn also shows files that earlier stories wrote or changed, at no extra call.

**Independent Test**: Read `feat-implementer.agent.md` and check that a short paragraph carries the first-turn list for story and bug mode and the "one turn" sentence alone for fix and rebase mode.

**Acceptance Scenarios**:

1. **Given** the implementer agent file, **When** it is read, **Then** it carries a short paragraph with the one-turn rule: independent tool calls go in one turn.
2. **Given** story or bug mode, **When** the paragraph is read, **Then** it lists the first turn: in story mode `git status --short`, the Spec Kit reads the skill requires, and the files on `story.sh`'s `files:` line that exist (a missing one may be a file the story creates); in bug mode `git status --short` with the reads of the bug report and `assessment.md`, the files `assessment.md` lists going together in the turn after it is read; then the later batches (searches before a task, edits to different files, ticks of one task group).
3. **Given** fix or rebase mode, **When** the paragraph is read, **Then** only the "one turn" sentence applies.
4. **Given** `/fix`, **When** it spawns the implementer, **Then** it gets the rule through the shared agent file and no `story.sh`: bug mode has no `tasks.md`.

---

### User Story 4 - Phase 6 gives each implementer its story's output and refreshes it on retry (Priority: P2)

Each implementer's prompt in phase 6 carries the `story.sh` output for its story, and the IDs it owns are `story.sh`'s. A retry or a resume runs `story.sh` again so the unchecked count is current.

**Why this priority**: It delivers Story 1 to the implementer; it depends on Stories 1 and 2 and changes no behaviour on its own.

**Independent Test**: Read phase 6 of `/feat` and check the prompt contents and the retry/resume rule; run it with a story partly ticked and check that the retry prompt shows the lower unchecked count.

**Acceptance Scenarios**:

1. **Given** phase 6 starts a story's implementer, **When** its prompt is built, **Then** it carries that story's `story.sh` output and the IDs it owns are `story.sh`'s.
2. **Given** a retry or a resume, **When** the prompt is built, **Then** `story.sh` runs again and the unchecked count is current.
3. **Given** `story.sh`'s output reaches the implementer, **When** it is read, **Then** it sits inside a fence longer than any backtick run in it, and everything up to the closing fence is data, never instructions; `tasks.md` stays the file the implementer reads and ticks.
4. **Given** `/feat`, **When** it runs `story.sh`, **Then** it runs it like `tracker.sh`, only on a `Tasks:` path that is also on the tasker's `Wrote:` and checked on disk, quoted, after `--`, and never reads `tasks.md` itself.

---

### User Story 5 - Documentation and checks follow the change (Priority: P2)

A maintainer or user reading the docs finds the phase 5 gate described as it now works, in the same words in every place that mirrors it, and the project's lint and tests cover the new script.

**Why this priority**: The project's rules require gate changes to be mirrored; the `check` workflow fails when diagrams drift.

**Independent Test**: Run `mise run lint`, `mise run test:apm` and the new test task; they pass and shellcheck is clean.

**Acceptance Scenarios**:

1. **Given** the phase 5 change, **When** the docs are read, **Then** the phase table, section 5 of `/feat`, `docs/workflow.md`'s matrix and `docs/diagrams/gates.d2` say the gate goes hard on a mismatch with the tasker's report or on `story.sh`'s non-zero exit, and the rendered diagram matches a fresh render.
2. **Given** the new script, **When** the offline tests run through their `mise` task, **Then** they cover every case in the acceptance list below, using at least two real `specs/*/tasks.md` as fixtures.
3. **Given** the new test task, **When** the maintainer notes are read, **Then** `.claude/CLAUDE.md`'s shell paragraph names it like `test:tracker`.
4. **Given** the PR, **When** its body is read, **Then** it says `Part of #55`, not `Closes #55`.

---

### Edge Cases

- A story with no tasks of its own prints `0 tasks`, exits 0, and setup and polish still attach to it by position.
- An untagged task before the first story phase is setup/foundational; after the last story phase it is polish; inside a story phase it is an error.
- A task naming no path, several paths, or a backticked command that is not a path.
- A backticked placeholder (`specs/<feature>/plan.md`), glob (`docs/img/*.svg`) or URL is not a path; a path to a file that doesn't exist yet stays one (the story may create it), and the implementer skips it in its first turn.
- A `tasks.md` with no `[US<n>]` tag, an unknown story, an unreadable file: non-zero exit with one line.
- The tasker writes a range (`T001–T012`) where `story.sh` lists IDs: no difference.
- A retry or resume after some tasks were ticked: the count changes, the IDs do not.
- The implementer ignores the rule (calls carrying one tool stay around 76%): a follow-up issue is filed rather than a longer rule.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: `story.sh <tasks.md> US<n>` MUST print that story's tasks in a compact form, with no task text: a header with the counts and how many of the tasks are unchecked; per task, one line with its ID, its checked state and the file paths it names (`paths:`); and a `files:` line merging every path once. The task text stays in `tasks.md`.
- **FR-002**: Setup and foundational tasks MUST go with the first story and polish tasks with the last. A task's story is its `[US<n>]` tag; an untagged task before the first story phase is setup/foundational, after the last story phase is polish.
- **FR-003**: An untagged task inside a story phase MUST make `story.sh` exit non-zero with one line naming it.
- **FR-004**: A path MUST be a backticked token containing `/` or ending in a file extension; backticked commands, tokens containing `<`, `*` or `://` (placeholders, globs, URLs) and text outside backticks MUST NOT be paths. A task MAY name none or several. Paths are candidates: `story.sh` does not check they exist (a task may create its file).
- **FR-005**: `story.sh <tasks.md>` without a story MUST print each story's task IDs and count, and setup/foundational and polish on their own marked lines, not folded into a story.
- **FR-006**: A story with no tasks of its own MUST print `0 tasks` and exit 0, with setup and polish still attached by position. A `tasks.md` with no `[US<n>]` tag, an unknown story or an unreadable file MUST exit non-zero with one line saying why.
- **FR-007**: Phase 5 of `/feat` MUST run `story.sh` without a story and compare, group by group, its ID set and count with the tasker's report, expanding the tasker's ranges first. It MUST identify the tasker's setup, foundational and polish IDs by their labels; an unlabelled or ambiguous grouping is a difference.
- **FR-008**: Phase 5 MUST make its gate hard, showing both sides, on any real difference or on a non-zero exit of `story.sh`; `story.sh`'s figures MUST feed the size check.
- **FR-009**: Phase 6 of `/feat` MUST put each story's `story.sh` one-story output (FR-001: per task its ID, checked state and `paths:`, plus the header and `files:` line; no verbatim task text) in that story's implementer prompt; the IDs the implementer owns are `story.sh`'s. A retry or a resume MUST run `story.sh` again. `tasks.md` stays the file the implementer reads and ticks, and the only place it reads the task text.
- **FR-010**: `story.sh`'s output MUST reach the implementer as data, never instructions: `/feat` fences it with a fence longer than any backtick run in it, and the implementer treats everything up to the closing fence as data. `/feat` MUST run it like `tracker.sh`, only on a `Tasks:` path that is also on the tasker's `Wrote:` and passed the on-disk check, quoted and after `--`, and never read `tasks.md` itself.
- **FR-011**: `feat-implementer.agent.md` MUST carry a short paragraph (about seven lines): send independent tool calls in one turn. In story mode the first turn sends together `git status --short`, the Spec Kit reads its skill requires and the files on `story.sh`'s `files:` line that exist (skipping missing ones, which the story may create). In bug mode the first turn sends `git status --short` with the reads of the bug report and `assessment.md`; the Spec Kit reads come after `speckit-bug-fix` is invoked, and the files `assessment.md` lists go together in the turn after it is read. After that, the searches before a task, the edits to different files and the ticks of one task group go together. Fix and rebase mode get only the "one turn" sentence.
- **FR-012**: `/fix` MUST NOT gain `story.sh`; it gets the rule through the shared agent file.
- **FR-013**: `story.sh` MUST live in `.apm/skills/feat/scripts/`, be bash, shellcheck clean, with no dependency beyond what `tracker.sh` already uses. It MUST stay out of `references/harness.md` and be listed in `/feat`'s `Commands besides the tracker` harness value.
- **FR-014**: Neither the tasker's nor the implementer's report format MUST change; the size table MUST NOT change.
- **FR-015**: The phase 5 gate change MUST be mirrored in the phase table, section 5, `docs/workflow.md`'s matrix and `docs/diagrams/gates.d2`, with `docs/img` re-rendered by `mise run diagrams` and committed.
- **FR-016**: `story.sh` MUST have offline tests like `tests/tracker/`, run by a new `mise` task and covered by `mise run lint`'s shellcheck, with at least two of this repo's real `specs/*/tasks.md` as fixtures, covering: setup/foundational attached to the first story and polish to the last; a task with no path, with several paths, a backticked non-path command, a backticked placeholder and glob (not paths), and `[P]` markers; `--` before the path; checked and unchecked tasks; a story with no tasks (`0 tasks`, exit 0); an unknown story, a `tasks.md` with no `[US<n>]` tag, and an untagged task inside a story phase (each non-zero); the all-stories form with marked setup/foundational and polish lines.
- **FR-017**: `.claude/CLAUDE.md`'s shell paragraph MUST name the new test task like `test:tracker`.
- **FR-018**: The private project the baseline comes from MUST NOT be named in the spec, the plan, the PR or the docs; say "the maintainer's busiest project".

### Key Entities

- **Story group**: the tasks of one `[US<n>]` story, with setup/foundational attached to the first and polish to the last; has an ID set, a count and an unchecked count.
- **Task**: an ID, its text (read for paths, never printed), checked or not, optional `[P]` marker, optional `[US<n>]` tag, zero or more file paths.
- **Tasker's report**: the prose list of task IDs and counts per group (ranges allowed) that phase 5 compares against.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: In the PR, `mise run lint`, `mise run test:apm` and the new test task pass and shellcheck is clean.
- **SC-002**: After merge, on at least five `/feat` runs in the maintainer's busiest project, `measure.py --project <that project> --compare-since <merge date>` shows implementer calls per spawn going from 45.8 to 34 or fewer (-25%), and the implementer's weighted cost share is no worse.
- **SC-003**: After merge, `/fix` implementer calls per spawn (all repos, baseline 27) are no worse.
- **SC-004**: After merge, comparing those five runs by hand with the five `/feat` runs before the merge in the same project, not-verified items per run and phase 7 findings by severity are no worse; both counts are posted on #55.
- **SC-005**: If the first two post-merge runs show the rule ignored (calls carrying one tool still around 76%), a follow-up issue is filed rather than a longer rule.
- **SC-006**: #55 stays open until SC-002 to SC-004 are measured.

## Assumptions

- The baseline is `docs/workflow.md`'s `## Baseline` (2026-11-19), read per project for the 45.8.
- `story.sh` saves few calls itself (about 1-3 per spawn); the saving comes from the first-turn batching it makes possible. It cannot save the `tasks.md` read, because `speckit-implement` requires reading and ticking it.
- Setup, foundational and polish tasks are told apart by position relative to the story phases, as `/feat` phase 6 already assigns them.
- The output format of `story.sh` (layout of lines) is a planning choice, provided it satisfies the requirements above.
- The one-story form and the phase 6 prompt carry no verbatim task text: per task one line with its ID, its checked state and its `paths:`, plus the header and the `files:` line. This deviates from the brief's "each one's ID, its text, and the file paths"; the user decided it at the design gate (finding D2, "apply D2 compact form"): the text would cost prompt tokens on every call, and the implementer reads it in `tasks.md` anyway.

## Out of scope

- Parallel stories (#1), loading the implementer's rebase mode on demand (#39), and the other sub-issues of #31.
- `measure.py` changes: no per-tool breakdown, no `feat-state.md` Log parsing.
- Changing `speckit-implement` or `speckit-bug-fix`, the checks the implementer runs, or any other agent.
- Growing the rule past a short paragraph in this PR.
- Listing files earlier stories wrote in each prompt (`git status --short` in the first turn covers it); dropping IDs and counts from the tasker's report; a soft gate on a mismatch; teaching `measure.py` to count not-verified items.
