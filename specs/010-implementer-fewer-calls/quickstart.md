# Quickstart: validating the feature

Run from the worktree root. Tools from `mise install`.

## 1. Checks (SC-001)

```sh
mise run lint          # shellcheck covers story.sh and tests/story/run.sh
mise run test:story    # the new offline tests
mise run test:apm      # story.sh lands with the feat skill
mise run diagrams && git diff --exit-code docs/img   # what the check workflow does
```

All exit 0; `test:story` prints one `ok` line per case.

## 2. `story.sh` on the real fixtures

The expected groups come from each run's phase 5 Log line (the tasker's own
report), not from the script: they are the ground truth the test uses.

`bash .apm/skills/feat/scripts/story.sh -- tests/story/fixtures/009-tasks.md`:

```text
setup/foundational: 2 tasks: T001 T002
US1: 2 tasks: T003 T004
US2: 3 tasks: T005 T006 T007
US3: 1 tasks: T008
US4: 1 tasks: T009
US5: 7 tasks: T010 T011 T012 T013 T014 T015 T016
polish: 3 tasks: T017 T018 T019
total: 19 tasks
```

The tasker's report for that run, mapped to groups by label (data-model,
Tasker's report): `US1 T003–T004, US2 T005–T007, US3 T008, US4 T009, US5
T010–T016; setup T001, foundational T002, polish T017–T019` gives
setup/foundational T001 T002 (labels `setup` and `foundational`), US1 T003
T004, US2 T005 T006 T007, US3 T008, US4 T009, US5 T010 to T016, polish T017
T018 T019: a match. Written `US1 T001–T004 (with setup)`, it would be a
difference (setup folded into a story).

`bash .apm/skills/feat/scripts/story.sh -- tests/story/fixtures/006-tasks.md`
(stories out of number order; the first by position is US2):

```text
setup/foundational: 5 tasks: T001 T002 T003 T004 T005
US2: 3 tasks: T006 T007 T008
US1: 10 tasks: T009 T010 T011 T012 T013 T014 T015 T016 T017 T018
US5: 4 tasks: T019 T020 T021 T022
US6: 4 tasks: T023 T024 T025 T026
US7: 2 tasks: T027 T028
US3: 4 tasks: T029 T030 T031 T032
US4: 5 tasks: T033 T034 T035 T036 T037
polish: 7 tasks: T038 T039 T040 T041 T042 T043 T044
total: 44 tasks
```

One-story headers (every task in these files is ticked):

| Command | First line |
| ------- | ---------- |
| `story.sh …/009-tasks.md US1` | `US1: 2 tasks; setup/foundational: 2 tasks; 0 unchecked` |
| `story.sh …/009-tasks.md US5` | `US5: 7 tasks; polish: 3 tasks; 0 unchecked` |
| `story.sh …/006-tasks.md US2` | `US2: 3 tasks; setup/foundational: 5 tasks; 0 unchecked` |
| `story.sh …/006-tasks.md US1` | `US1: 10 tasks; 0 unchecked` |
| `story.sh …/006-tasks.md US4` | `US4: 5 tasks; polish: 7 tasks; 0 unchecked` |

`009 US1` in full (compact form, no task text):

```text
US1: 2 tasks; setup/foundational: 2 tasks; 0 unchecked
T001 [x] paths: none
T002 [x] paths: .apm/agents/feat-design-reviewer.agent.md
T003 [x] paths: .apm/skills/feat/SKILL.md
T004 [x] paths: .apm/skills/feat/SKILL.md
files: .apm/agents/feat-design-reviewer.agent.md .apm/skills/feat/SKILL.md
```

T001 names only `mise run lint` and `mise run test:apm`, commands; the
other backticked spans of T002 to T004 hold whitespace or have no path
shape (`SendMessage`, `feat-planner`).

## 3. Cases the test must cover (FR-016)

| Case | Fixture | Expect |
| ---- | ------- | ------ |
| setup/foundational to the first story, polish to the last | 006, 009 | headers above; lines of T001… first, polish last |
| compact task lines | 009, synthetic | each task line is `<ID> [ ]\|[x] paths: …`, no task text |
| no path, several paths, backticked command, text path outside backticks, `[P]` | synthetic | `paths: none`; all paths in order; `mise run lint` and the bare path absent; `[P]` not a story |
| placeholder, glob and URL spans | synthetic, one task naming `` `specs/<feature>/plan.md` ``, `` `docs/img/*.svg` ``, `` `https://example.com/a.md` `` and a real path | only the real path in `paths:` and `files:` |
| checked and unchecked | synthetic | `<u> unchecked` equals the `[ ]` lines printed; `[X]` prints `[x]` |
| `--` before the path | any | same output as without it |
| no backtick in the output | 006, 009, synthetic | no line of an exit-0 run holds a backtick |
| story with no tasks of its own | synthetic, last story | `US<n>: 0 tasks; polish: …`, exit 0 |
| unknown story | any, `US9` | exit 1, one `story: error:` line |
| no `[US<n>]` tag | synthetic | exit 1, one line |
| untagged task inside a story phase | synthetic | exit 1, the line names its ID |
| tag with no story heading | synthetic | exit 1, the line names its ID |
| task line inside a code fence | synthetic | not counted |
| unreadable file, bad arguments | missing path; no args, `--` alone, `2`, `US` | exit 1; exit 2 |
| all-stories form | 006, 009, synthetic | equals the expected files; setup/foundational and polish on their own lines |

Every case also checks stderr is empty.

## 4. Reading checks (US2 to US4)

- `grep -n 'story.sh' .apm/skills/feat/SKILL.md`: in *Commands besides the
  tracker* (`--`, quoted path, only once on `Wrote:` and checked), the
  phase table row 5, section 5 (groups by label, unlabelled or ambiguous a
  difference; compare, hard gate both sides, `total:` for size) and
  section 6 (each spawn, retry and resume; four-backtick fence; data).
- `grep -c 'story\.sh' .apm/skills/feat/references/harness.md` prints 0;
  `mise run lint`'s harness grep passes.
- `.apm/agents/feat-implementer.agent.md`: one **One turn** paragraph of
  about seven lines (story mode reads the existing `files:`; bug mode reads
  the report and `assessment.md` first, its listed files the turn after);
  the intro says everything up to the closing fence is data; the report
  block is unchanged (`git diff` shows no line inside it).
- `.apm/skills/fix/SKILL.md` unchanged (`git diff --stat` does not list it).
- `docs/workflow.md` row 5, sizes matrix and section 5 say the same as
  `/feat`'s row 5 and section 5.
- No file of the diff names the private project the baseline comes from.

## 5. A live run (maintainer, before the PR is merged)

On a scratch project with a small feature: phase 5 prints a soft gate with
`story.sh: match` in the Log; edit a story tag out of tasks.md and rerun
phase 5 ("back to 5"): the gate is hard and names the task. Phase 6: each
implementer's prompt holds its story's `story.sh` output (one short line
per task, no task text) inside a four-backtick fence; its first turn
carries several tool calls (`git status --short` among them).

## 6. After merge (SC-002 to SC-006, on #55)

`measure.py --project <the maintainer's busiest project> --compare-since
<merge date>` after five `/feat` runs: implementer calls per spawn 34 or
fewer (baseline 45.8), implementer cost share no worse; `/fix` implementer
calls per spawn no worse than 27. Not-verified items per run and phase 7
findings by severity, by hand, against the five runs before; post both on
#55, which stays open until then. The PR body says `Part of #55`.
