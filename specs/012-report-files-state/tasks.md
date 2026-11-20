---

description: "Task list for report files and a state script"
---

# Tasks: Report files and a state script

**Input**: Design documents in `specs/012-report-files-state/` (spec.md, plan.md, research.md, data-model.md, contracts/state-cli.md, contracts/digests.md, contracts/coordinator-calls.md, quickstart.md)

**Prerequisites**: plan.md, spec.md

**Tests**: Requested (FR-020, SC-002, SC-005): offline tests in `tests/state/run.sh`, written with each subcommand. Existing offline tests (`tests/story/`, `tests/spec-number/`) are the pattern.

**Organization**: Setup, Foundational, US1 (P1, state.sh and the swap), US2 (P2, report files and digests), Polish. The run can stop after Phase 3 (US1): `report-path`, `snapshot` and `unchanged` do not exist yet, no agent gets a report path, and every agent reports in full.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: can run in parallel (different files, no dependency on an incomplete task)
- All paths are relative to the repository root. `state.sh` is `.apm/skills/feat/scripts/state.sh`; every task that adds a subcommand also adds its cases to `tests/state/run.sh` (same file, so those tasks are not [P]).
- bash 3.2 constructs only in `state.sh` (plan.md, Technical Context); `shellcheck` clean; no `$(…)` / heredoc / `>` in anything a prompt tells the coordinator to run.

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Wire the new test suite into the repo's tasks and CI.

- [X] T001 Add `[tasks."test:state"]` to `mise.toml` (runs `bash tests/state/run.sh`), add `tests/state/run.sh` and `.apm/skills/feat/scripts/state.sh` to the `lint` shellcheck line, and add to the `test:apm` checks that the installed package contains `scripts/state.sh`
- [X] T002 [P] Add a `mise run test:state` step to `.github/workflows/check.yml`
- [X] T003 [P] Create the `tests/state/` scaffold modelled on `tests/story/` and `tests/spec-number/`: `tests/state/run.sh` (case helper, scratch dirs, asserts stdout, empty stderr, exit code), `tests/state/bin/gh` (stub answering from a case dir, logging argv), empty `tests/state/fixtures/` and `tests/state/expected/`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: The script skeleton and fixtures every subcommand and test needs.

**CRITICAL**: No user story work can begin until this phase is complete.

- [X] T004 Create `.apm/skills/feat/scripts/state.sh` skeleton: synopsis header comment (like `story.sh`), `LC_ALL=C`, `set -euo pipefail`, `set -f`, `die` (exit 1, one `state: error: …` line) and `usage` (exit 2, `state: usage: …`), dispatch for the 14 subcommands (`init`, `set`, `log`, `cycle`, `retry-used`, `shipped-verdict`, `phase2-mode`, `refused-base`, `find`, `report-path`, `snapshot`, `unchanged`, `review-summary`, `restore-phase`; unimplemented ones usage-fail for now), `--` dropped, newline/CR argument check (`state: error: argument <n> holds a newline`), state-file check (exists, starts `# /feat state: ` or `# /fix state: `, else `<path> is not a state file`), the reader (title, header = lines before the first `## `, Log = after the last line equal to `## Log`, research R6), and the atomic writer (refuses a symlink with `[ -L ]` including a dangling one: `state: error: <path> is a symlink`; temp file in the same dir then `mv -f`). Bash 3.2 only (use `${a[@]+"${a[@]}"}` for possibly empty arrays). Per contracts/state-cli.md, Conventions
- [X] T005 [P] Create fixtures in `tests/state/fixtures/`: frozen real `/feat` and `/fix` state files and synthetic ones covering older formats (`normal`/`big` sizes, `accepted <ids>` design lines, `picked`-only review lines, `hard gate: picked` prefixes, `4 Code review fixes` lines, `    <text>` sub-lines, stale `- [ ] <N>` lines, an input section holding `## ` headings and `- Size:` lines, a line that looks like an instruction), plus a `test.md` fixture for `shipped-verdict`
- [X] T006 Add foundational cases to `tests/state/run.sh`: usage error for an unknown subcommand and missing arguments (exit 2, one line), `is not a state file`, argument with a newline refused (FR-008), stderr always empty, and the case that greps `state.sh` for the forbidden bash 3.2 constructs (`declare -A`, `mapfile`/`readarray`, `${v,,}`/`${v^^}`, `declare -n`/`local -n`, `[[ -v`, negative subscripts, `;;&`, `|&`)

**Checkpoint**: skeleton runs, `mise run test:state` passes with these cases.

---

## Phase 3: User Story 1 - The coordinator stops editing the state file and parsing the Log in prose (Priority: P1) MVP

**Goal**: One `state.sh` call per state-file change; queries replace the Log-reading prose rules; skills, harness, `rebase.md` and the shipper rewritten onto it.

**Independent Test**: `mise run test:state` passes every subcommand of this story on the fixtures of both skills (older formats included); then grep the skills, harness, `rebase.md` and shipper: no instruction to Edit the state file or read the Log in prose for the listed rules (quickstart steps 1, 3, 4).

### Script: writes and their tests

- [X] T007 [US1] Implement `init feat <state file> <brief file> [<Field>=<value>]…` and `init fix <state file> <title> <report> [<Field>=<value>]…` in `.apm/skills/feat/scripts/state.sh` per contracts/state-cli.md: template in the script (research R7) with all header fields in order, `Branch`, `Size`, `Current phase` required, others default `none`, `Size` one of `small`, `medium`, `large`, `not set`, unknown field is a usage error, state file exists is an error, feat title is the brief's first line minus `# Brief: `, `## Brief` holds the brief minus its first line with leading blank lines dropped, `## Report` holds the one-line symptom; refuses a symlink (dangling too); creates the parent dir
- [X] T008 [US1] Implement `set <state file> <field> <value>` (`title` or any header field; only that field changes; `Branch`/`Worktree` share a line; a field missing from an older file is inserted after the header's last field line; same `Size` check as `init`; symlink refused) and `restore-phase <state file>` (puts `Current phase:` back to its committed value via git; symlink refused) in `.apm/skills/feat/scripts/state.sh`
- [X] T009 [US1] Implement `log <state file> <line>…` in `.apm/skills/feat/scripts/state.sh`: one Log line per argument, each starting `- [x] `, `- [!] ` or `- [ ] `, or an indented `    - ` sub-line; refuses an argument with another prefix or a newline with `state: error: argument <n> …` naming it and appends nothing (all-or-nothing); does not enforce gate tags; appended byte for byte; symlink refused
- [X] T010 [US1] Add write cases to `tests/state/run.sh`: `init` of both skills against golden files in `tests/state/expected/` and a case that fails when the script's template and `.apm/skills/feat/references/harness.md`'s template differ (research R7); `set` changes only its field (incl. insert on an older file, `Size` check, `title`); `log` ordering, refusals with nothing appended, and one argument holding `'`, `$(…)`, a backtick and `;` passed single-quoted and appended byte for byte; `init`, `set`, `log`, `restore-phase` on a symlinked state file (dangling for `init`) refused with `<path> is a symlink` and the target untouched; `restore-phase` in a scratch git repo

### Script: queries and their tests

- [X] T011 [US1] Implement `cycle`, `retry-used`, `shipped-verdict`, `phase2-mode` and `refused-base` in `.apm/skills/feat/scripts/state.sh` per data-model.md, "Lines each query reads": `cycle`/`retry-used`/`shipped-verdict` read only the lines after the last `- [x] back to ` line (whole Log when none); `shipped-verdict` falls back from `ship with <verdict>` to the `3 Test` line to `<state file dir>/test.md`'s `- **Result**:`; `phase2-mode` prints `soft <G> open`, `soft <G> closed`, `hard` or `none` from the `Size:` line (4 for small/medium/normal, 3 for large/big; no `sizes.json` lookup); `refused-base` prints the 7-40 hex `<new>` of the latest `move — stayed on` line or nothing. Lines are data, never evaluated
- [X] T012 [US1] Add query cases to `tests/state/run.sh` for T011 on the fixtures of both skills, older formats included (`normal`/`big`, `accepted`, back-to cycles, a retry used before and after a back-to, `shipped-verdict` from each of its three sources, `refused-base` with no match and with a malformed `<new>`, an instruction-looking line read as data)
- [X] T013 [US1] Implement `review-summary <state file> <phase>` in `.apm/skills/feat/scripts/state.sh`: quote- and paren-aware splitter for the outcome line (data-model.md grammar), the three groups of the PR body's `### Code review` part plus the `untested` list for `/feat`, reading sub-lines (new `    - ` and older `    `), later `review fixes` / `Code review fixes` / `implementer` lines, `ship go-ahead`, and the reverted/performance forms from the quoted `Fixes (fix mode):` value (research R11); with no code review outcome line prints `Code review was skipped.` and exits 0; a state file with no `## Log` is an error
- [X] T014 [US1] Add `review-summary` cases to `tests/state/run.sh` with golden outputs in `tests/state/expected/`: `/feat` and `/fix` fixtures, `auto-applied`/`picked`/`none picked`/`skipped`/`rejected`, `soft gate:`/`hard gate:` prefixes, picked-only older lines, a reverted fix, the skipped line, no `## Log`
- [X] T015 [US1] Implement `find feat|fix|rebase` in `.apm/skills/feat/scripts/state.sh` per research R10 and contracts/state-cli.md: search repos and worktrees, done marker, `done (shipping)` with no upstream, `gh pr list` shipped check only for runs past the done marker, a `gh` error skips no run; `find feat|fix` print `<state file> <worktree> <current phase>` per run and nothing (exit 0) when none; `find rebase` prints its own form (four fields, or `skip: <reason>`)
- [X] T016 [US1] Add `find` cases to `tests/state/run.sh` using throwaway repos and worktrees and `tests/state/bin/gh` on `PATH`: done, shipping without upstream, shipped per `gh pr list`, open, a failing `gh`, no run found, each `rebase` skip reason

### Swap the text onto the script (parallel across files)

- [X] T017 [P] [US1] Rewrite `.apm/skills/feat/references/harness.md` per contracts/coordinator-calls.md, Harness: thin-orchestrator bullets ("edit anything" plus the *state script* exception), State file section (created by `init`, changed only by `set`/`log`, never Edit or Write; every `state.sh` argument single-quoted with `'` as `'\''`; text from a report or the user never outside quotes or in a `<token>`/`<key>` position; queries ride on a `set`/`log` call in one Bash command; `state: error`/`state: usage` handling), template without the `- [ ] <N> <phase>` line and with `    - ` sub-lines, Base check via `refused-base`, At ship via `set`/`log` at the shipper's numbered path, Resume via `find` then the one state-file Read. No `/feat`-only words, no old wording
- [X] T018 [P] [US1] Update `.apm/skills/feat/references/rebase.md`: `find rebase` replaces the rebase search, `set`/`log` replace hand edits, the shipper gets `restore-phase` for `Current phase:`; no `/feat`-only words
- [X] T019 [P] [US1] Update `.apm/skills/feat/SKILL.md` per contracts/coordinator-calls.md, `/feat`: Harness values (add *State script*, drop *Resume search*, *Done marker*, *Rebase search*, `gh pr list --head …` and `git for-each-ref …` from commands), each boundary's calls as `set`/`log` (without `report-path`, `snapshot`, `unchanged`; `init` stays where the state file is created today), phase 2's four sub-lines as `    - Stories: …` etc., the review-fixes Log line quoting the implementer's `Fixes (fix mode):` value, no open `- [ ] <N> <phase>` lines, resume via `phase2-mode` and `refused-base`, prose Log rules removed. Do not edit between `sizes-start`/`sizes-end` markers
- [X] T020 [P] [US1] Update `.apm/skills/fix/SKILL.md` per contracts/coordinator-calls.md, `/fix`: Harness values (add *State script* as `<this skill's base dir>/../feat/scripts/state.sh`, drop the moved values), setup 7 as `init fix` with the symptom joined by spaces, phases 1/3/5 calls as `set`/`log`, the test cycle and retry via `cycle`/`retry-used`, the shipped verdict via `shipped-verdict`, resume via `find fix`, no open `- [ ] <N> <phase>` lines written, prose Log rules removed. Do not edit between `sizes-start`/`sizes-end` markers
- [X] T021 [P] [US1] Update `.apm/agents/feat-shipper.agent.md`: add the `State script:` input, build `### Code review` with `review-summary`, use `shipped-verdict` in fix mode and `restore-phase` in rebase mode instead of the hand Edit; fixed report format unchanged
- [X] T022 [US1] Add the old-wording lint line from contracts/coordinator-calls.md, Lint, to the `lint` task in `mise.toml` (joins SKILL.md files, harness.md, rebase.md and the shipper into one line, fails on the old phrases); adjust a pattern only if new text needs the phrase for another meaning, and say so
- [X] T023 [US1] Run `mise run test:state`, `mise run lint` and `mise run test:apm`; fix failures. This closes the MVP (quickstart steps 1-5)

**Checkpoint**: User Story 1 is complete and shippable alone; the run may stop here.

---

## Phase 4: User Story 2 - Agents write their reports to files and hand back a digest (Priority: P2)

**Goal**: Every `/feat` and `/fix` spawn gets a report path; the agent writes its full report there and hands back a digest; reviewers get `Write` back, checked by `snapshot`/`unchanged`; `reports/` is never committed.

**Independent Test**: With a report path the file exists before the gate, holds the full report, and the hand-back lacks exactly the dropped lines; with no path the agent reports in full and writes nothing (quickstart steps 4, 6, 8).

**Depends on**: Phase 3 (the script, the harness State file rules and the skill calls).

### Script and tests

- [X] T024 [US2] Implement `report-path <state file> <key>` in `.apm/skills/feat/scripts/state.sh`: key matches `^[A-Za-z0-9][A-Za-z0-9+_-]{0,63}$`; prints the next free `<artifact dir>/reports/<key>.md` (or `<key>-<n>.md`, n >= 2), never an existing one; on first use in a dir writes `reports/.gitignore` holding `*`; fails with `state: error: <path> is a symlink` and prints no path when `<dir>/reports` is a symlink or the path to print or a `-<n>` candidate exists as a symlink; does not require the state file to exist (research R3)
- [X] T025 [US2] Implement `snapshot <state file>` and `unchanged <state file> <token>` in `.apm/skills/feat/scripts/state.sh` per research R1: 12-hex token of the content of tracked and untracked files, ignored files and `reports/` of the state file's dir excluded, hashing only changed and untracked files, manifest kept at `<git dir>/logistics/snapshots/<token>`; `snapshot` never prints the file list; `unchanged` prints a short verdict, and on `changed` only also prints the differing paths (up to 10 as `- <path>`, then `- and <n> more`; with no manifest a "see git status" line), then removes the manifest; a difference is a verdict, exit 0
- [X] T026 [US2] Add cases to `tests/state/run.sh`: `report-path` first-use `.gitignore`, the `-2` rerun, never an existing path, symlinked `reports/`, symlink at the printed path and at a `-<n>` candidate, bad key; `snapshot`/`unchanged` catching an edit to an already-modified file, a new untracked file and a deleted file, ignoring `reports/` and ignored files, bounded path list (10 then count), `unchanged` quiet-form on no change, a missing manifest

### Agents (parallel; each agent file changes with the rule that reads it, same commit as T034-T036, principle IV)

- [X] T027 [P] [US2] Update `.apm/agents/feat-code-reviewer.agent.md` per contracts/digests.md: `Write` back (`Edit` stays denied; use `disallowedTools`, no `model`/`effort`/`tools`/`color` in frontmatter), rule to write its report file and nothing else and nothing with no report path, report path on `Wrote:`, digest drops `Dismissed:`
- [X] T028 [P] [US2] Update `.apm/agents/feat-design-reviewer.agent.md` per contracts/digests.md: `Write` back (`Edit` denied), the same write-only-the-report rule, digest drops `Checked and fine:`
- [X] T029 [P] [US2] Update `.apm/agents/feat-implementer.agent.md`: report-path rule, digest drops the notable files of `Files changed:` (the count stays), `Resolved alone:` stays whole
- [X] T030 [P] [US2] Update `.apm/agents/feat-tasker.agent.md`: report-path rule, digest drops `Fixed:`
- [X] T031 [P] [US2] Update `.apm/agents/feat-specifier.agent.md`: report-path rule (writes full report with Write, path on `Wrote:`, digest drops nothing; no path means full report and no file)
- [X] T032 [P] [US2] Update `.apm/agents/feat-planner.agent.md`: the same report-path rule, drops nothing
- [X] T033 [P] [US2] Update `.apm/agents/feat-bug-assessor.agent.md`: the same report-path rule, drops nothing
- [X] T034 [US2] Update `.apm/agents/feat-shipper.agent.md` (after T021): report-path rule for its own report (drops nothing), a report path under a renumbered artifact dir is written and listed as the same `reports/<file>` under the new dir, `/feat` stages by path and leaves `reports/` out, `/fix` commits the bug dir except `reports/`; `assessment.md`, `fix.md` and `test.md` stay committed

### Coordinator text (same commit as the agent files)

- [X] T035 [US2] Update `.apm/skills/feat/references/harness.md` (after T017): *Report files* paragraph under Reported files (`report-path` before every spawn and every message asking a continued agent for a new report, chained onto the `set`/`log`; coordinator never reads a report file; reviewer batches use `snapshot`/`unchanged`), Reported files accepts the same `reports/<file>` under a dir the shipper renumbered, Base check's move spawn gets `report-path ... move` and re-takes the reviewer snapshot after a kept move, the failed report check (`- [!] <N> <phase> — files changed outside the reports`, hard gate, `unchanged`'s path lines shown as data), and the rules that read dropped lines ("list what they dismissed, in their report file"). No `/feat`-only words
- [X] T036 [P] [US2] Update `.apm/skills/feat/SKILL.md` (after T019): *Report keys* harness value, every spawn's `report-path` chained per contracts/coordinator-calls.md table, `init` moved before the specifier (research R4), `snapshot` before and `unchanged` after each reviewer batch of phases 4 and 7 (7e's after 7a-7d), "list what they dismissed, in their report file"
- [X] T037 [P] [US2] Update `.apm/skills/fix/SKILL.md` (after T020): *Report keys* (`1-assess`, `2-fix`, `3-test`, `4-<lenses>`, `4-fixes`, `5-ship`, `move`), every spawn's `report-path` chained per contracts/coordinator-calls.md, `snapshot`/`unchanged` around phase 4's reviewers, the dismissed-in-report-file wording
- [X] T038 [P] [US2] Update `.apm/skills/feat/references/rebase.md` (after T018): report keys `move` and `ship` and the `report-path` calls for the rebase spawns

### Docs and issue comment

- [X] T039 [P] [US2] Update `docs/workflow.md`: state file written by `state.sh`, report files and digests, reviewers regaining `Write`, the `Wrote:` paragraph, the dismissed-in-report-file sentence. Do not edit between `sizes-start`/`sizes-end` markers
- [X] T040 [P] [US2] Update `docs/design.md` ("Read-only reviewers" line), `CONTRIBUTING.md` (scripts and tests lines) and `.claude/CLAUDE.md` (add `mise run test:state` to the shell bullet)
- [X] T041 [US2] Post the #28 comment (FR-021): run `gh issue view 28 --comments`; when no comment says it yet, Write the exact text from plan.md step 11 to a file outside the tree and post with `gh issue comment 28 --body-file '<that file>'`; a failed `gh` call goes under `Not verified:` as `n/a → #28 comment → <first line of gh's error>` and does not block the PR

**Checkpoint**: Stories 1 and 2 both work; `reports/` ignores itself.

---

## Phase 5: Polish & Cross-Cutting Concerns

**Purpose**: Final verification across both stories.

- [X] T042 Run `mise run test:state`, `mise run lint` (shellcheck on `state.sh`, `tests/state/run.sh`; the old-wording grep; `/feat`-only words absent from `harness.md` and `rebase.md`; no drift in `sizes-start`/`sizes-end` blocks), `mise run test:apm`, `mise run test:story`, `mise run test:spec-number`, `mise run test:tracker`, `mise run test:sizes` and `mise run test:measure`; fix failures
- [ ] T043 Run quickstart.md steps 1-7 (offline tests, lint and packaging, old wording gone, a state file by hand, other tests green, agent files, docs); steps 8 (live run) and 9 (SC-006 after at least three post-merge runs) are for after the merge and are listed under `Not verified:`
- [X] T044 Confirm `.apm/skills/tiny/SKILL.md`, `.apm/skills/brief/SKILL.md`, `.apm/agents/feat-brief-reviewer.agent.md`, `.claude-plugin/plugin.json`, `sizes.json`, `docs/diagrams/*` and `measure.py` are unchanged (`git status`), and that `reports/` appears in no staged path

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: none; start at once
- **Foundational (Phase 2)**: after Setup (T006 needs T003; T004 first)
- **US1 (Phase 3)**: after Foundational. Script tasks T007-T016 are sequential (one file, one test file); the text tasks T017-T021 need the script's behaviour settled (after T016) but are parallel with each other; T022 after T017-T021; T023 last
- **US2 (Phase 4)**: after US1. T024-T026 sequential; agent tasks T027-T033 parallel and independent of T024-T026 except for testing; T034 after T021; T035 after T017; T036/T037/T038 after T019/T020/T018; T041 any time after T035
- **Polish (Phase 5)**: after the stories you ship

### User Story Dependencies

- **US1 (P1)**: no dependency on US2. MVP.
- **US2 (P2)**: depends on US1's script, harness rules and skill calls.

### Within Each Story

- A subcommand and its test cases land together (T007/T010 ... T015/T016).
- Agent files and the coordinator text that reads them land in the same commit (FR-019).

### Parallel Opportunities

- T002, T003; T005 beside T004
- T017, T018, T019, T020, T021 (different files)
- T027-T033, then T036-T040

---

## Parallel Example: User Story 2 agents

```text
Task: "Update .apm/agents/feat-code-reviewer.agent.md (Write back, report-path rule, drop Dismissed:)"
Task: "Update .apm/agents/feat-design-reviewer.agent.md (Write back, report-path rule, drop Checked and fine:)"
Task: "Update .apm/agents/feat-implementer.agent.md (report-path rule, drop notable files)"
Task: "Update .apm/agents/feat-tasker.agent.md (report-path rule, drop Fixed:)"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Phase 1 Setup, Phase 2 Foundational
2. Phase 3 US1 (T007-T023)
3. Stop and validate: `mise run test:state`, `mise run lint`, `mise run test:apm`, quickstart steps 1-5
4. The run may ship here as `feat(state)`

### Incremental Delivery

1. Add US2 (T024-T041), validate with quickstart steps 4, 6, 7
2. Polish (T042-T044)
3. Commits for the shipper (plan.md): `docs(specs)`, `feat(state)` for US1, `feat(agents)` for US2

---

## Notes

- Constitution principle IV: an agent file and the rule that reads its report change in the same commit.
- `state.sh` stays one file: tasks touching it are sequential, never [P].
- Never hand-edit `sizes-start`/`sizes-end` blocks, CHANGELOG.md, versions or `.release-please-manifest.json`.
