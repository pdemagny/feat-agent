# Implementation Plan: Run each phase boundary of /feat and /fix with one command

**Branch**: `step-command` | **Date**: 2026-11-20 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `specs/013-step-command/spec.md` (issue #28; closes #21; epic #31; replaces #41)

## Summary

A new bash script, `.apm/skills/feat/scripts/step.sh`, becomes the one call
the `/feat` and `/fix` coordinators make at every phase boundary. It reads
the agents' report files and the state file, checks `Wrote:`, runs
`unchanged`, decides the verdict from today's gate tables (`soft`, `hard:`
with reasons, `stop:`), merges review findings (rules 2–6; 2, 3, 5 for the
design review), writes the tagged gate line and `Current phase` through
`state.sh`, records the user's answer as a sub-line, runs the base, repair
and diff checks with git, and prints the next spawn: agent, lenses, mode,
model and effort from a generated `sizes.tsv`, report path, snapshot, and a
tab-separated `boundary:` line the coordinator copies into its next call
(story 1). Every agent's report gets fixed-value fields and list fields
that `step.sh` parses fail-closed, one reformat turn when a report doesn't
parse, and a digest cut to the gate message inputs (story 2). The merged
list (story 3), the git checks and a new `references/move.md` (story 4)
and the `[soft]`/`[hard]` tags with `answer:` sub-lines, read by
`state.sh`'s queries (story 5), complete it. Last, the skills and
`harness.md` drop the size tables, gate tables, merge rules and git prose,
and `mise run lint` keeps them out (story 6).

The design review added safety rules that run through all of it: the run's
top level comes from the state file's location, never from `Worktree:`; a
report read again must hash as when it was checked; a missing Log fact is
never its permissive value; the review diff marks only the run's own
files; the Log never holds an unparsable line's or a shipper's `!` line's
text; `dropped:` and `/fix` 1's security choice are checked.

## Technical Context

**Language/Version**: bash 3.2 or later for `step.sh` and the `state.sh`
changes (same construct limits as `state.sh`: no `declare -A`, `mapfile`,
`${v,,}`, `declare -n`, `[[ -v ]]`, `;;&`, `|&`; empty arrays as
`${a[@]+"${a[@]}"}`); Python 3.11 standard library for `docs/diagrams/sizes.py`
(repo-only); Markdown prompts

**Primary Dependencies**: none new; `git` (already required:
`hash-object`, `check-ref-format`, `ls-files`, `add -N`, `fetch`,
`merge-base`, `rev-parse`), `state.sh` and `story.sh` (shipped beside it);
`shellcheck` 0.11.0 as pinned

**Storage**: the state file, `<artifact dir>/reports/*.md`, the generated
`.apm/skills/feat/sizes.tsv`

**Testing**: new `tests/step/run.sh` (scratch skill layout with a fixture
`sizes.tsv`, fixture state files and reports per gate row, golden stdout
and Log tails, `UPDATE=1` to regenerate them (exits non-zero), throwaway
repos with a bare origin, one under a path with a space),
`log-readers-agree` comparing `state.sh`'s and `step.sh`'s Log readers on
shared tagged and untagged fixtures, `mise run test:step` and a
`check.yml` step; tagged fixtures added to `tests/state`; `tests/sizes`
for `sizes.tsv`; `mise run lint` (shellcheck, new greps, `sizes.py
--check`); `mise run test:apm`; [quickstart.md](quickstart.md)

**Target Platform**: Claude Code sessions running `/feat` and `/fix`
(Linux, macOS, bash 3.2 included); the `check` workflow (ubuntu-latest)

**Project Type**: prompt package (skills and subagents) with helper scripts

**Performance Goals**: SC-008 after merge: median coordinator calls per run
`/feat` 62 → ≤ 45, `/fix` 45 → ≤ 30; one `step.sh` call per boundary,
under a second without a fetch

**Constraints**: the coordinator's command line holds no `$(…)`, pipe or
heredoc; every argument single-quoted, one per tab-separated word of the
call line; `step.sh` prints data only and passes report and user text to
`state.sh` as single arguments; state file writes only through `state.sh`;
the Log never holds report text beyond today's titles (no unparsable
line, no `!` line); git targets and the `Wrote:` root come from the state
file's own top level; no `jq`, no Python at run time; same gate for the
same reports and state as today's tables (FR-005); a missing fact never
loosens a gate (FR-031); old untagged state files keep working;
`harness.md`, `rebase.md`, `move.md` hold no `/feat`-only words;
`/tiny` and `feat-brief-reviewer` unchanged

**Scale/Scope**: 1 new script (~1,700 lines) and its tests (~180 cases);
`state.sh` (~60 lines); `sizes.json`, `sizes.py`, new `sizes.tsv`; 8 agent
files; both skills, `harness.md`, `rebase.md`, new `move.md`; `mise.toml`,
CI; 8 docs and the gates diagram; ~105 tasks

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Check | Result |
| --------- | ----- | ------ |
| I. Thin coordinators | the coordinator stops applying gate tables, merging, running git checks and reading size tables; it runs one script per boundary and reads its data lines, like `state.sh`; it still never reads a report file (`rebase`'s `Wrote:` check reads the digest and runs `ls -d`, as the harness does today) | pass |
| II. The user decides at gates | the same gates stop (FR-005, a fixture per row); `step.sh` can make a gate hard, the coordinator can still make a soft gate hard (override), nothing makes a hard gate soft; a missing fact, a changed report and a refused `dropped:` all stop rather than pass; the reformat turn decides nothing, it only re-asks for the format; answers are recorded with the user's words | pass |
| III. One source of truth | the gate rules move from two skills and the harness into one script; `sizes.json` gains `/fix`'s groups and stays the source of the generated `sizes.tsv`; the Log grammar keeps two readers (`state.sh`, `step.sh`, R1) by the user's choice, held together by the `log-readers-agree` test on one fixture set (R6); the shared rules then live in `harness.md`, the references it points to and `step.sh` by design, so principle III's text is amended in this PR (version 1.4.0) as its governance asks (FR-029, R18): `sizes.tsv`, both skills' groups, and its last sentence becomes "Rules both skills share MUST live once: the coordinators' part in harness.md and the references it points to (rebase.md, move.md), the rules step.sh applies in step.sh" | pass |
| IV. Fixed report formats | each agent's format (list fields, required lens sections, the reformat-mode paragraph), its digest and `step.sh`'s parser change in one commit; the rebase-mode digest carries what `rebase` reads; the principle's wording gains `step.sh` | pass |
| V. Small and plain | bash, shellcheck-clean, offline tests; the prompts lose far more lines than they gain; `move.md` is a new file on purpose (read only on a move, ~55 lines off every call, brief); no shared library file added (R1) | pass |

Distribution: `step.sh`, `sizes.tsv` and `references/move.md` live under
`.apm/skills/feat/`, shipped whole by APM, the plugin and `install.sh`;
`test:apm` checks each. No agent added or removed: `plugin.json`
unchanged.

Post-design re-check (after the design review): pass. No service,
permission, exposure or dependency added: `git fetch`, `git merge-base`
and `git add -N` already run at these boundaries, now inside the script;
`git hash-object` and `git check-ref-format` are git. Exposure narrows:
`git add -N` now marks only the run's own files (no user file enters the
reviewers' context or the index), the `Wrote:` root can no longer be
widened through `Worktree:`, and no unparsable line or `!` line reaches
the committed Log. Size trigger: none.

## Project Structure

### Documentation (this feature)

```text
specs/013-step-command/
├── plan.md                      # this file
├── research.md                  # decisions R1–R21
├── data-model.md                # entities, top level, Log grammar and lines, facts, open gate, report hashes, reformat turn, step function, checks, merge
├── quickstart.md                # validation steps
├── contracts/
│   ├── step-cli.md              # call forms, arguments, answers, output (call lines, answer call output), exit codes
│   ├── gates.md                 # each boundary: conditions → reasons, Log lines, next, answers
│   ├── agent-formats.md         # parsing rules (fail-closed), the eight agents' formats, reformat mode, digests
│   ├── sizes.md                 # sizes.json changes, sizes.tsv, sizes.py, tests
│   └── coordinator.md           # skills, harness, move.md, rebase.md, state.sh, checks, docs
└── tasks.md                     # phase 5
```

### Source code (repository root)

New:

```text
.apm/skills/feat/scripts/step.sh
.apm/skills/feat/sizes.tsv                 # generated
.apm/skills/feat/references/move.md
tests/step/run.sh
tests/step/fixtures/sizes.tsv              # stable models for goldens
tests/step/fixtures/states/                # state files per case (tagged, untagged, pre-feature)
tests/step/fixtures/logs/                  # shared Logs for log-readers-agree (tests/state's, tagged and untagged)
tests/step/fixtures/agents/<agent>/        # agent files per gate row, per parsing rule, today's layout
tests/step/expected/                       # golden stdout and Log tails (UPDATE=1 rewrites them)
```

Changed:

```text
.apm/skills/feat/scripts/state.sh          # tag normalisation; phase2-mode, review-summary, shipped-verdict
.apm/skills/feat/sizes.json                # fix lens, fix groups (+ performance variant)
docs/diagrams/sizes.py                     # sizes.tsv target (header with the install tuning note), loose fix groups, lens; SKILL.md table targets removed
.apm/skills/feat/SKILL.md                  # one step.sh call per boundary; tables and rule prose out
.apm/skills/fix/SKILL.md                   # the same
.apm/skills/feat/references/harness.md     # Step script section; rules out; dropped value names out; move rules to move.md
.apm/skills/feat/references/rebase.md      # repair check and Wrote: check written out, move.md, sizes file
.apm/agents/feat-specifier.agent.md        # formats, list fields, reformat mode, digests (contracts/agent-formats.md)
.apm/agents/feat-planner.agent.md
.apm/agents/feat-tasker.agent.md
.apm/agents/feat-implementer.agent.md
.apm/agents/feat-code-reviewer.agent.md
.apm/agents/feat-design-reviewer.agent.md
.apm/agents/feat-bug-assessor.agent.md
.apm/agents/feat-shipper.agent.md
tests/state/                               # tagged fixtures and expectations
tests/sizes/                               # sizes.tsv expected, SKILL.md fixtures out
mise.toml                                  # lint greps, shellcheck tests/step, test:step, test:apm
.github/workflows/check.yml                # mise run test:step
docs/workflow.md, docs/diagrams/gates.d2, docs/img/gates.svg
docs/design.md, docs/usage.md, docs/install.md, CONTRIBUTING.md
.claude/CLAUDE.md, .specify/memory/constitution.md
```

Unchanged on purpose: `.apm/skills/tiny/SKILL.md`, `.apm/skills/brief/SKILL.md`
(its marked sentence stays generated), `feat-brief-reviewer.agent.md`,
`plugin.json`, `apm.yml`, `install.sh`, `story.sh`, `tracker.sh`,
`measure.py`, `docs/diagrams/chain.d2` (no phase or gate change).

**Structure Decision**: one script beside `state.sh` and `story.sh`, tested
like `tests/state` (fixtures, goldens, scratch repos), reading generated
data beside `sizes.json`.

## How

### Foundational (blocks every story)

1. **Sizes data**: `sizes.json` (`fix` lens, `fix.groups` with the
   `performance` variant), `sizes.py` (validation, the `sizes.tsv` whole-file
   target with its header, the install tuning note included, `--check`),
   generate `sizes.tsv`, `tests/sizes` cases (contracts/sizes.md). The
   SKILL.md table targets stay until step 16.
2. **`state.sh` tags**: `log_lines` normalisation and tag array;
   `phase2-mode` (tag, override, answered gate G), `review-summary`
   (`outcome:` sub-line, skipped sub-lines, `dropped:`, `wrote:`),
   `shipped-verdict` (`answer: ship with`); tagged copies of the existing
   fixtures in `tests/state` give the same answers (data-model.md, Tags).
3. **`step.sh` skeleton**: header synopsis; main guard; `die`/`usage`; the
   four forms; argument classes, `sum=` and `snapshot=` required where
   step-cli.md says; the top level from the state file's dir and the
   `Worktree:` check (data-model.md, State file fields); state file
   reader; `sizes.tsv` reader (rows, groups, variants); report reader
   (fields, list fields, required lens sections, fixed values, fail-closed
   rules, unparsable line and key); `Wrote:` check (renumbered dir and
   `state:` line included); report hashes (take, print, compare); output
   writer (keys, one line each, control characters out, tab-separated call
   lines, no tab in a path); `state.sh` wrappers (computing every line
   first, one `log` call, a retry that finds the same lines at the Log's
   end writes nothing); expected boundary and report keys; open gate;
   facts reader with the missing-fact rule; answer parsing and refusal;
   the reformat turn; the step function frame; `step: error` logging.
4. **Test harness**: `tests/step/run.sh` (scratch layout, case runner,
   golden compare, stderr empty, bash 3.2 grep, `UPDATE=1` writes the
   actual output over `tests/step/expected/` and exits non-zero),
   `log-readers-agree` on `tests/step/fixtures/logs/` (R6), `mise.toml`
   `test:step` and shellcheck line, `check.yml` step, `test:apm` line for
   `step.sh`.

### Story 1 (P1): one call per boundary

5. `setup` for both skills; the `size` form (sets, logs, prints `size:`,
   no spawn); `resume` without repair (phase restart, owed amends and
   fixes, phase 6 progress with the done rule, `phase2-mode`, `assess
   gate:`); `step: error` cases (`Worktree:` naming another path, a tab in
   a path).
6. Non-review boundaries, each with its rows, Log lines, answers and next
   spawn (contracts/gates.md): `/feat` 2, 3 (and amends; the untagged
   merged line on small and medium; assumption numbers), 5 (`story.sh`
   comparison, size check), 6 (story order, the who-line on every report
   with `wrote:` sub-lines, `story.sh` output, retry, large per-story gate),
   8 (ship outcomes, the `! cd <top> && ` check, renumbered dir and
   `state:`, `done (PR #N)`); `/fix` 1 (stop, soft conditions, hard rows,
   pass, extra arguments, the `security:` refusal, a missing report
   author), 2, 3 (routing from `cycle` and `retry-used`, unaccounted
   items, `ship with`), 5 (`security bug` from the facts, a missing risk
   area). Missing facts on a pre-feature state file at each gate that reads
   one. Answer call output (`answered`, `stop`, `back to`, `skip`). The
   soft gate's `answer call:` and the override's answer. Continuation
   from the `Agents` line and `agent=<id>`. The reformat turn for every
   agent (first unparsable report → reformat spawn; second → hard).
7. Fixtures and goldens: one case per row, per boundary inside a phase,
   per answer kind, per refusal, per missing fact, per reformat outcome;
   a report changed between calls (7e and an answer call); each next-spawn
   row and group per size against the fixture `sizes.tsv`; the real
   `sizes.tsv` parse check.

### Story 2 (P1): formats and digests

8. The formats and digests of contracts/agent-formats.md for
   `feat-specifier`, `feat-planner`, `feat-tasker`, `feat-implementer`,
   `feat-bug-assessor`, `feat-shipper` (list fields, `Wrote:` included;
   `Risk area` and `Performance bug` fixed; the reformat-mode paragraph;
   the rebase-mode digest with `Move`, `Checks`, `Decided`, `Wrote`),
   landing with their parser and gate rows (steps 6–7) in the same commit;
   fixture files of each agent per gate condition, one per fail-closed
   rule, and one in today's layout (bare paths under `Wrote:`) that is
   unparsable at its first bare path. SC-004: each digest list compared
   against what the new skill text quotes.

### Story 3 (P2): merged review findings

9. Formats of `feat-code-reviewer` and `feat-design-reviewer` (`at:`,
   `fix:`, lists, every section of the spawned lenses, `none` when empty;
   the `[sec]`/`[cost]`/`[design]` tag required; `Paraphrase vs brief`),
   the lens 4c comparison.
10. Merge in `step.sh`: code rules 2–6 and design rules 2, 3, 5, ids,
    order, counts (data-model.md, Merged list); review gates `/feat` 4,
    7/7e (7e after 7a–7d with `cuts:` and the earlier reports' `sum=`),
    7-fixes (retry, stop), `/fix` 4 (variants, the performance variant on
    a missing fact, security go-ahead, `skip 4`), 4-fixes; outcome
    sub-line; `dropped:` accepted only for a `P`/`R` id cut by a `C` id
    of the list; `rejected:` and `accepted sec:` spawn inputs; a reviewer's
    reformat with its new snapshot.
11. Fixtures per merge rule, per review gate row, zero findings, each
    refused `dropped:`.

### Story 4 (P2): base, repair and diff in the command; `move.md`

12. Base check (`same`, `refused`, `moved`, `fetch-failed`) in the top
    level, default branch (with the `-` and `check-ref-format` checks),
    diff preparation (`git add -N` only on the untracked paths of the
    `wrote:` facts, `added:`, `untracked, not in the diff:`, base, empty
    diff), repair check in `resume` and at a reportless `move`; `move` and
    `repair` boundaries (kept, undone gate, `stay`, nothing to do, at
    ship).
13. Throwaway-repo cases for each, `Worktree: none` and a worktree path
    with a space included; a user file left untracked and out of the
    diff; a remote default branch named `-x`.
14. `references/move.md` from the harness; `rebase.md` updated
    (contracts/coordinator.md: the repair check, the `Wrote:` check with
    `ls -d` for its own spawns, the move's outcome from the digest);
    `test:apm` line for `move.md`.

### Story 5 (P2): tags and answers

15. Tagged lines everywhere `step.sh` decides a gate; `answer:` sub-lines
    for every kind; `override:` read as an open gate; cases that run each
    `state.sh` query on the resulting files; a case counting soft, hard,
    overridden and answered gates by `grep` on a full fixture run (SC-003);
    `log-readers-agree` extended to these files.

### Story 6 (P3): the skills keep the coordinator's part

16. Rewrite both SKILL.md files and `harness.md` per
    contracts/coordinator.md (the soft summary in the same turn as the
    spawn; the tab-separated call lines; `state:`, `reformat`, `answered`
    and the override's `answer call:`; every sentence naming a dropped
    Harness value reworded); drop the SKILL.md table targets from
    `sizes.py` and their `tests/sizes` fixtures; lint greps (the dropped
    value names included); `test:apm` lines for `sizes.tsv`.
17. Docs: `docs/workflow.md`, `gates.d2` and its render, `.claude/CLAUDE.md`,
    constitution 1.4.0, `CONTRIBUTING.md`, `docs/design.md`,
    `docs/usage.md` (Tuning: the `row` line and every `group` line naming
    it, in an install), `docs/install.md`.
18. A scratch `/feat` small run and a `/fix` run (quickstart.md, steps 6–7).

### Commits (for the shipper)

`docs(specs)` for this dir; `feat(sizes)` for step 1; `feat(state)` for
step 2; `feat(step)` for steps 3–16 (script, tests, agents, skills,
harness, `move.md`, `rebase.md`, checks: one commit, principle IV);
`docs` for step 17 (constitution and `.claude/CLAUDE.md` included). The PR
body says `Closes #28` and `Closes #21`.

## Risks

- **Size of the change**: one PR across both skills, eight agents and a
  new script. Mitigation: a fixture per gate row and per answer, goldens
  regenerated with `UPDATE=1` and reviewed as a diff, and the scratch runs
  before ship; story order lets the script be complete and tested before
  the prompts swap.
- **Agents drifting from the format**: the parser fails closed, so a drift
  never misroutes a run; the first slip of a spawn costs one reformat turn
  of that agent alone, a second one a hard gate naming the file, line and
  key. Each agent file keeps its format block as the last thing it reads.
- **More stops on resumed pre-feature runs**: their Logs lack the facts,
  so gates that read one stop with `fact missing: <name>` once; `approved`
  or `back to N` moves on.
- **More size gates at the edges**: exact thresholds (R14) stop a 31-task
  small run where today's "~30" might not; the user keeps the size with
  `approved`.
- **A partial write**: a `step.sh` failure between its `log` and `set`
  calls; the retry finds the same lines and writes only what is missing.
- **Runs started before the upgrade**: their untagged lines read as today;
  the resumed phase restarts with a fresh spawn in the new format (edge
  case of the spec).
- **Two Log readers**: `state.sh` and `step.sh` parse the same grammar;
  `log-readers-agree` fails when they disagree on a shared fixture.
- **`/tiny` users** see the code reviewer's new finding layout (`at:`,
  `fix:`, sections written `none`); `/tiny`'s text reads only the `rec`
  values, which keep their place.

## Complexity Tracking

No constitution violation to justify.
