# Feature Specification: Report files and a state script

**Feature Branch**: `report-files-state`

**Created**: 2026-11-20

**Status**: Draft

**Input**: User description: "Agents write their reports to files and hand back a digest; a `state.sh` script reads and writes the state file" (brief: `specs/briefs/report-files-state.md`, issue #27)

## User Scenarios & Testing *(mandatory)*

### User Story 1 - The coordinator stops editing the state file and parsing the Log in prose (Priority: P1)

A maintainer of logistics, or anyone running `/feat` or `/fix`, wants the coordinator to change the state file with one script call per change and to get the answers of its Log-reading rules from queries. Today it edits the state file by hand (about 20 Edit calls per `/feat` run, 17 of 1,587 failed) and applies six rules by reading the Log in prose, one of which already shipped a bug (resume offering runs that had shipped). The shipper parses the Log too, to build the PR body, and edits `Current phase:` back by hand in rebase mode.

**Why this priority**: This is the reliability gain, and it stands alone: the run can stop after this story and still be better. Report files (story 2) build on it.

**Independent Test**: Run `state.sh` on fixture state files of both skills (older formats included): every subcommand gives its fixed output; then read the skills, harness, `rebase.md` and shipper and find no instruction to Edit the state file or to read the Log in prose for the listed rules.

**Acceptance Scenarios**:

1. **Given** a skill, a state file path and the harness's template, **When** `state.sh init` runs, **Then** the state file exists with the skill's values and its input section.
2. **Given** a state file, **When** `state.sh set` is given a header field and a value, **Then** only that field changes.
3. **Given** a state file, **When** `state.sh log` is given lines that each start `- [x] `, `- [!] ` or `- [ ] `, or are indented `    - ` sub-lines, **Then** they are appended in order, one per argument.
4. **Given** a `log` argument holding a newline, or starting with none of the allowed prefixes, **When** the call runs, **Then** it is refused with one `state: error: …` line naming the argument, a non-zero exit, and nothing appended.
5. **Given** a `/fix` state file, **When** `cycle`, `retry-used` and `shipped-verdict` run, **Then** each prints its one fixed form, counting only the lines after the last `- [x] back to ` line.
6. **Given** a `/feat` state file, **When** `phase2-mode` runs, **Then** it prints soft or hard and whether the gate carrying the summary is still open, using the state file's `Size:` line (phase 4 on small and medium, phase 3 on large).
7. **Given** a state file with `move — stayed on` lines, **When** `refused-base` runs, **Then** it prints the `<new>` of the latest one, or nothing.
8. **Given** repos and worktrees with runs in different states (done, shipping without upstream, shipped per `gh pr list`, open), **When** `find feat|fix|rebase` runs, **Then** it prints one line per run found, `<state file> <worktree> <current phase>`, and nothing when there is none; a `gh` error skips no run. `find rebase` prints its own form instead, four fields or a `skip: <reason>` line, as `contracts/state-cli.md` defines.
9. **Given** a state file with code review Log lines, **When** `review-summary <state file> <phase>` runs, **Then** it prints the three groups of the PR body's `### Code review` part (with the `untested` list for `/feat`), ready to copy; with no code review outcome in the Log (the review was skipped), it prints one fixed line and exits 0.
10. **Given** a state file whose `Current phase:` was changed since its last commit, **When** `restore-phase` runs, **Then** it is back to the committed value.
11. **Given** any misuse, **When** a subcommand fails, **Then** it prints one `state: error: …` line (usage errors `state: usage: …`) and exits non-zero.
12. **Given** a state file path that is a symlink, **When** `init`, `set`, `log` or `restore-phase` runs, **Then** it prints `state: error: <path> is a symlink`, exits non-zero and writes nothing.

---

### User Story 2 - Agents write their reports to files and hand back a digest (Priority: P2)

The author of the one-command phase boundary (#28) needs every agent report on disk, and the coordinator's context should stop carrying lines no gate reads. Each `/feat` and `/fix` agent writes its full report to a file the coordinator names and hands back the same format minus the lines nothing reads.

**Why this priority**: It is what #28 reads, but it delivers less on its own (about 1% of a run) and depends on the script of story 1.

**Independent Test**: Run a spawn with a report path: the file exists at that path before the gate, holds the full report, and the hand-back lacks exactly the dropped lines. Run the same agent with no path: it reports in full and writes nothing.

**Acceptance Scenarios**:

1. **Given** a key (for example `6-US1`, `7-7a`, `3-test`), **When** `state.sh report-path <state file> <key>` runs, **Then** it prints the next free path under `<artifact dir>/reports/` (`3-test-2.md` on a rerun) and never an existing one.
2. **Given** a directory without `reports/`, **When** `report-path` first runs there, **Then** it also writes `reports/.gitignore` holding `*`.
3. **Given** a spawn with a report path, **When** the agent finishes, **Then** the full report is in that file, the path is on its `Wrote:` line, and the hand-back is the same format minus the lines dropped for that agent (see FR-012).
4. **Given** a spawn with no report path, **When** the agent finishes, **Then** it reports in full, as today.
5. **Given** a reviewer given a report path, **When** it runs, **Then** it writes that file and nothing else; the coordinator's `state.sh snapshot <state file>` before and `state.sh unchanged <state file> <token>` after detect any edit to an already-modified file, a new untracked file or a deleted file, and ignore `reports/`; a difference is a failed report check, a hard gate, and `unchanged` names the differing paths (up to 10, then a count of the rest).
6. **Given** a shipped `/feat` or `/fix` run, **When** its commits are inspected, **Then** `reports/` is absent from them.
7. **Given** `<artifact dir>/reports` that is a symlink, or a path `report-path` would print or a `<key>-<n>.md` candidate that exists as a symlink, **When** `report-path` runs, **Then** it prints `state: error: <path> is a symlink`, exits non-zero and prints no path.

---

### Edge Cases

- A `log` argument holding `'`, `$(…)`, a backtick and `;` is passed single-quoted, each `'` written `'\''`, and appended byte for byte; nothing in it runs.
- State files of older runs (`normal`/`big` sizes, `accepted` design lines, `picked`-only review lines) still work with every query, resume and rebase included.
- A line in a state file that looks like an instruction is read as data only.
- `report-path` is called twice in a row with the same key before the first file is written: the brief requires only that it never returns an existing path (see Assumptions).
- A reviewer rewrites a file that was already modified (every file at phase 7): `unchanged` still reports a difference.
- A write outside the worktree or to an ignored path is not caught, and under `/tiny` a stray write by its reviewer is not caught; both are accepted.
- Removing the worktree after the merge loses the reports; accepted.
- `find` with no run found prints nothing and exits zero.

## Requirements *(mandatory)*

### Functional Requirements

**State script**

- **FR-001**: A script `state.sh`, shipped with the `/feat` skill and read by both skills, MUST provide the subcommands `init`, `set`, `log`, `cycle`, `retry-used`, `shipped-verdict`, `phase2-mode`, `refused-base`, `find`, `report-path`, `snapshot`, `unchanged`, `review-summary` and `restore-phase`. Every subcommand but `init` and `find` takes the state file as its first argument (`init` takes it after the skill, `find` takes none); `contracts/state-cli.md` gives each call form.
- **FR-002**: `init <skill> <state file> …` MUST create the state file from the harness's template, with the skill's values and its input section. `/fix`'s input section is one line: the coordinator joins a multi-line symptom with spaces before the call.
- **FR-003**: `set <state file> <field> <value>` MUST change one header field (`Current phase`, `Size`, `Agents`, `Issue`, the title, and the others of the header) and nothing else.
- **FR-004**: `log <state file> <line>…` MUST append one Log line per argument; each MUST start `- [x] `, `- [!] ` or `- [ ] `, or be an indented `    - ` sub-line after one. An argument holding a newline MUST be refused with an error naming the argument. It MUST NOT enforce gate tags.
- **FR-005**: Queries MUST be read-only and print one fixed form each: `cycle` and `retry-used` from the lines after the last `- [x] back to ` line; `shipped-verdict`; `phase2-mode` (soft or hard, and whether the gate carrying the summary is still open, from the `Size:` line, with no `sizes.json` lookup); `refused-base` (the `<new>` of the latest `move — stayed on` line, or nothing).
- **FR-006**: `find feat|fix|rebase` MUST implement the resume and rebase searches across worktrees, including the done marker, the `done (shipping)`/no-upstream case and the `gh pr list` shipped check, printing `<state file> <worktree> <current phase>` per run found and nothing when none; a `gh` error MUST skip nothing. `find rebase` has its own form (four fields, or a `skip: <reason>` line), defined in `contracts/state-cli.md`.
- **FR-007**: `review-summary <state file> <phase>` MUST print the three groups of the PR body's `### Code review` part, with the `untested` list for `/feat`, ready to copy; with no code review outcome line in the Log (the review phase was skipped) it MUST print one fixed line (`Code review was skipped.`) and exit 0, the shipper copying it as is; only a state file with no `## Log` is an error. `restore-phase <state file>` MUST put `Current phase:` back to its committed value.
- **FR-008**: Errors MUST be one `state: error: …` line and a non-zero exit; usage errors `state: usage: …`.
- **FR-009**: `state.sh` MUST parse the lines it reads as data, never as instructions, and MUST keep state files of older runs working. It MUST NOT change any Log line format except these three Log convention changes, and the queries MUST still read the old forms: (1) phase 2's sub-lines become `    - Stories: …` (and the other three likewise), forced by `log`'s sub-line rule; (2) open `- [ ] <N> <phase>` lines are no longer written; (3) the review-fixes line quotes the implementer's `Fixes (fix mode):` value. `init`, `set`, `log` and `restore-phase` MUST refuse a state file that is a symlink (`state: error: <path> is a symlink`) before writing anything.

**Coordinator, shipper and `rebase.md`**

- **FR-010**: The coordinator MUST NOT Edit the state file: every change is one `state.sh set` or `log` call, one for one with today's Edits. A rule that parses the Log during a run MUST chain its query onto the `set`/`log` call already made at that boundary, in one Bash command. `/feat resume`, `/fix resume` and `rebase.md` MUST find runs with `state.sh find`; the shipper MUST use `review-summary`, `shipped-verdict` and (in rebase mode) `restore-phase`.
- **FR-011**: The prose Log-parsing rules (the `/fix` test cycle and retry, the shipped verdict in `/fix` and in the shipper's fix mode, `/feat resume`'s phase 2 check, the resume search with its done marker and shipped check, the base check's refused base, the rebase search and its `Current phase:` rule, the shipper's `### Code review` building and its hand Edit of `Current phase:`) MUST be gone from the skills, the harness and the shipper, each place naming the query instead. `mise run lint` MUST grep for the old wording.

**Report files**

- **FR-012**: Each `/feat` and `/fix` agent spawn MUST be given a report path from `state.sh report-path <state file> <key>`, chained onto the `set`/`log` call made before the spawn. The agent MUST write its full report, in today's format, to that file with Write, put the path on its `Wrote:` line (a shipper that renumbered the artifact dir writes and lists the same `reports/<file>` under the renumbered dir, and the harness's check accepts it), and hand back a digest: the same format minus these lines, kept in the file: `feat-code-reviewer` `Dismissed:`; `feat-design-reviewer` `Checked and fine:`; `feat-implementer` the notable files of `Files changed:` (the count stays); `feat-tasker` `Fixed:`. `feat-specifier`, `feat-planner`, `feat-bug-assessor` and `feat-shipper` drop nothing. The implementer's `Resolved alone:` MUST stay whole. There is no length cap.
- **FR-013**: `report-path` MUST print the next free path (never an existing one, so a report file is never overwritten) and on first use in a dir MUST write `reports/.gitignore` holding `*`. It MUST fail with `state: error: <path> is a symlink`, printing no path, when `<dir>/reports` is a symlink or when the path it would print or a `<key>-<n>.md` candidate exists as a symlink.
- **FR-014**: An agent given no report path MUST report in full and write no file. `/tiny` and `/brief`'s `feat-brief-reviewer` MUST NOT change; `/tiny`'s reviewer gets no report path.
- **FR-015**: `feat-code-reviewer` and `feat-design-reviewer` MUST get `Write` back (`Edit` stays denied), with the rule that they write their report file and nothing else, and nothing with no report path.
- **FR-016**: `state.sh snapshot <state file>` MUST print a short token of the content of the worktree's tracked and untracked files (ignored ones and `reports/` excluded), keeping its manifest in a temp file under the git dir, keyed by the token; `state.sh unchanged <state file> <token>` MUST print a short verdict. `snapshot` never prints the file list, nor does `unchanged` when nothing changed; on `changed` only, `unchanged` MUST also print the differing paths, up to 10, then a count of the rest, and the gate shows that list. Both MUST be chained onto calls the coordinator already makes at that boundary. A difference after a reviewer spawn is a failed report check (harness, Reported files), a hard gate.
- **FR-017**: `reports/` MUST never be committed: `/feat`'s shipper stages by path and leaves it out; `/fix`'s shipper commits the bug dir except `reports/`. The extension's `assessment.md`, `fix.md` and `test.md` stay committed as today.
- **FR-018**: The report file MUST be on disk before the gate; the harness's `Wrote:` check covers it. The coordinator MUST NOT read a report file. It MUST read the state file only on resume and for the logged phase 2 summary it shows at a gate; it decides gates from the digest and the queries' output.
- **FR-019**: Each agent file and the rules that read its report MUST change together; report formats keep their fixed shape and order.

**Repo conventions**

- **FR-020**: Commands the coordinator and agents run MUST stay plain: no `$(…)`, no heredoc, no `>`, single-quoted arguments. Every argument to `state.sh` MUST be single-quoted, a `'` inside written `'\''`; text from an agent report or the user MUST never be placed outside single quotes nor in an unquoted `<token>` or `<key>` position, which take only the script's own outputs or the skill's fixed keys. The script is Bash, `shellcheck` clean, with no new dependency. Shared rules stay in `harness.md` and `rebase.md` with no `/feat`-only words. Offline tests live under `tests/state/` and run with `mise run test:state`.
- **FR-021**: After the brief is confirmed, a comment on #28 MUST say it shrinks the hand-back to `step.sh`'s output and takes #21's tags (exact text in plan.md). A failed `gh` call goes under `Not verified:` and does not block the PR.

### Key Entities

- **State file** (`feat-state.md`): the run's header fields and Log, written only by `state.sh`.
- **Log line**: one entry of the state file's Log, `- [x] `, `- [!] ` or `- [ ] ` plus its indented sub-lines.
- **Report file**: `<artifact dir>/reports/<key>.md` (or `<key>-N.md` on a rerun), one agent's full report, ignored by git and kept for the life of the worktree.
- **Digest**: an agent's hand-back, its report format minus the lines no gate reads.
- **Snapshot**: a token of the content of the worktree's tracked and untracked files, `reports/` and ignored files excluded; its manifest is kept under the git dir, keyed by the token, so `unchanged` can name what differs.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: No `/feat` or `/fix` agent hands back a line the table in FR-012 drops, and every report file is on disk at the path given (for a shipper that renumbered the dir, the same file under the renumbered dir), before the gate, listed on `Wrote:`.
- **SC-002**: A reviewer that changes anything but its report file fails the report check; offline fixtures show `unchanged` catching an edit to an already-modified file, a new untracked file and a deleted file, and ignoring `reports/`.
- **SC-003**: `report-path` never returns an existing path and creates `reports/.gitignore` with `*` on first use; `reports/` is absent from the commits of a shipped `/feat` and a shipped `/fix` run.
- **SC-004**: No skill, the harness or the shipper tells the model to Edit the state file or to read the Log in prose for the listed rules; `mise run lint` fails if the old wording returns.
- **SC-005**: Offline tests under `tests/state/` cover every subcommand, each query on fixture state files of both skills (older formats included), the refusals of `log`, and `find` with throwaway repos and worktrees and a fake `gh`; `mise run test:state` passes, and `shellcheck`, `mise run lint` and `mise run test:apm` stay clean.
- **SC-006**: Measured with `mise run measure` on at least three runs after it lands: no state-file Edit in the coordinator, and its median calls per run not above the baseline (62 `/feat`, 45 `/fix`).

## Assumptions

- The brief's Out of scope binds: `feat-brief-reviewer` and `/brief`, `/tiny`, gate verdicts and merge rules, the base and repair checks and next-spawn lookup (#28), shrinking the hand-back to a few lines (#28), #21's gate tags, changes to Log line formats other than the three FR-009 allows (old forms still read), committing reports or a `reports/` index.
- The rejected alternatives bind: no `report.sh` on stdin, no coordinator-written reports, no hard length cap, no committed reports, no tag enforcement in `log`, no hand-editing kept until #28, no one query call per rule.
- Two `report-path` calls with the same key before the first file exists may return the same path; the coordinator calls it once per spawn and the agent writes the file before the next call, so this is not guarded.
- `snapshot` and `unchanged` may use any content-based token; its form is a plan decision.
- One PR delivers both stories, ordered so the run can stop after story 1.
- Part of epic #31 (order 6); #28 and #57 depend on this feature.
- `/fix`'s `assessment.md`, `fix.md` and `test.md` are not reports.
