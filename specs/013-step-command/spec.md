# Feature Specification: Run each phase boundary of /feat and /fix with one command

**Feature Branch**: `step-command`

**Created**: 2026-11-20

**Status**: Draft

**Input**: User description: "Run each phase boundary of /feat and /fix with one command" (brief: `specs/briefs/step-command.md`, issue #28)

## Clarifications

### Session 2026-11-20

- Q: Does `step.sh` also prepare the code review diff at the boundary into `/feat` phase 7 and `/fix` phase 4 (intent-to-add the run's new files, print the base for `git diff <base>`, hard when the diff is empty), which the coordinator does today with two or three git calls, one of them `BASE=$(git merge-base …)`? → A: Yes: `step.sh` runs `git add -N` on the run's new files, prints the base for `git diff <base>`, and the verdict is hard on an empty diff; that boundary is one call and no `$(…)` stays in the coordinator's command line.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - One call decides each boundary and names the next spawn (Priority: P1)

A maintainer of logistics, or anyone running `/feat` or `/fix`, wants the coordinator to cross each phase boundary with one fixed Bash command, `step.sh`, instead of applying by hand, one tool call and one model call at a time, the `Wrote:` check, the gate table, the routing inside a phase, the size triggers and the size-table lookup for the next spawn. Against the 2026-11-19 baseline (`docs/workflow.md`, `## Baseline`) a `/feat` run makes 62 coordinator calls (21 chores only) and a `/fix` run 45 (21 chores only), each re-reading about 110k tokens, and 167 `/feat` and 33 `/fix` coordinator Bash calls failed, most of them command lines the worktree guard, a hook or the classifier refused. A fixed command has neither cost.

**Why this priority**: It is epic #31's main lever on the coordinator; every other story adds to the same command or follows from it.

**Independent Test**: Run `step.sh` offline on fixture state files and fixture reports: one per gate table row of both skills, each boundary inside a phase, `/fix`'s routing, `setup`, `size <s>` and `resume`. Each call prints the expected verdict, writes the expected Log line and `Current phase:`, and prints the expected next spawn (agent, lenses, model, effort, report path) for each size.

**Acceptance Scenarios**:

1. **Given** `state.sh init` just created the state file, **When** `step.sh <skill> <state file> setup` runs, **Then** it prints the first spawn: `/feat` phase 2 (`feat-specifier`) or `/fix` phase 1 (`feat-bug-assessor`), with its model, effort and report path for the run's size.
2. **Given** an agent's report (or a batch of reviewers' reports) that matches no hard condition of its phase's gate, **When** the boundary call `step.sh <skill> <state file> <phase> <report file>…` runs, **Then** it prints `soft`, logs `- [x] <N> <phase> [soft] — …`, sets `Current phase:` to the next phase and prints the next spawn.
3. **Given** a report that matches one or more hard conditions, **When** the boundary call runs, **Then** it prints `hard:` followed by one reason per line, logs `- [x] <N> <phase> [hard] — …`, and prints no spawn until the call that carries the user's answer.
4. **Given** a `/fix` phase 1 report with `Assessment: none`, `Verdict: invalid` or `Is a bug: no — …`, **When** the boundary call runs, **Then** it prints `stop:` with its reason, sets `Current phase:` to `done (invalid)` or `done (not a bug)` and logs the stopped line.
5. **Given** a report with no `Wrote:` line, a refused path, an artifact or report path missing from `Wrote:`, or a path not on disk, **When** the boundary call runs, **Then** the verdict is hard whatever the gate table says, each failure is a reason, and each is logged `- [!] <N> <phase> — <reason>`; after a reviewer batch, `unchanged` printing `changed` is a hard reason too, with its paths.
6. **Given** a report `step.sh` cannot parse, **When** the boundary call runs, **Then** it prints one reformat spawn of the same agent (continued when the skill allows it, else fresh) naming the file and the line it stopped on, and only the agents whose reports failed to parse are asked again; **When** the reformatted report still cannot be parsed, **Then** the verdict is hard and names the file, the line number and its key. The Log holds the line number and key, never the line's text. (The user's decision at the design review, "ok, as recommended", overriding the brief's "always hard".)
7. **Given** a `/fix` phase 3 report `Verdict: failed` with `cycle` printing `first` and `retry-used` printing `no`, **When** the boundary call runs, **Then** there is no stop: the retry line is logged and the next spawn is a fresh phase 2 implementer with the test report's path; `failed` after the retry or after review fixes is hard; `verified` after review fixes goes to phase 5.
8. **Given** a `/feat` phase 6 story report, **When** the boundary call runs, **Then** on large the gate is hard after each story, and on small and medium the next spawn is the next story's implementer (soft after the last story).
9. **Given** `/feat` phase 7 on medium or large, **When** the boundary call runs on the 7a–7d reports, **Then** the next spawn is 7e with 7d's cuts and a new snapshot; the gate comes after 7e.
10. **Given** the user's `size <s>` while no hard gate is open (at a hard gate it is the answer `size <s>`), **When** `step.sh <skill> <state file> size <s>` runs, **Then** it sets `Size`, logs the change and prints `size: <old> → <new>` with no spawn; the spawns printed from the next boundary on use the new size's model and effort.
11. **Given** a run to resume, **When** `step.sh resume <state file>` runs, **Then** it runs the repair check, then prints the same output as the boundary call for the current phase.
12. **Given** `step.sh` itself fails, **When** any call runs, **Then** it prints a `step: error: …` line and exits non-zero; the line is logged `- [!] step: <line>`, the gate is hard with `retry` (the same call) and `stop` as its only answers, and nothing is spawned from memory.
13. **Given** a fact a gate reads from an earlier Log line is missing (a run started before this feature: no `risk area` on the `1 Assess` line, no facts on the `3 Plan` line, no `report author` on the setup line), **When** that gate is decided, **Then** the missing fact never counts as its permissive value: the gate is hard with `fact missing: <name>`, a missing report author counts as untrusted, and a `/fix` shipper gets `security bug: yes` until the user answers.
14. **Given** a report `step.sh` already checked is changed before a later call passes it again (7a–7d's at the 7e call, any report on an answer call), **When** that call runs, **Then** it is a failed report check, `report changed since checked: <file name>`, and an answer call applies none of its answers.

---

### User Story 2 - Every report step.sh reads parses safely, and the hand-back carries only the gate message inputs (Priority: P1)

The coordinator no longer applies the gate rules, so it no longer needs the fields they read; `step.sh` reads the report files instead, and needs each gate condition as a fixed value it can parse without judgment.

**Why this priority**: Story 1 cannot decide a gate from prose. Each agent's report format and its digest change together, once (brief, Alternatives rejected: no tightening now and shrinking later).

**Independent Test**: For each agent `step.sh` reads, parse fixture reports of every gate condition with `step.sh`; compare each agent's digest with its new format and find no dropped line in it.

**Acceptance Scenarios**:

1. **Given** a report of `feat-specifier`, `feat-planner`, `feat-tasker`, `feat-implementer`, `feat-code-reviewer`, `feat-design-reviewer`, `feat-bug-assessor` or `feat-shipper`, or the rebase mode's `Move:` line, **When** `step.sh` reads it, **Then** each field it needs is on its own line with a fixed value (for example `Paraphrase: matches | contradicts`, `Risk area: security | none`).
2. **Given** a spawn with a report path, **When** the agent finishes, **Then** the full report is in the file and the hand-back holds only what the coordinator needs beside `step.sh`'s output: the gate message inputs.
3. **Given** a gate condition no agent can report as a fixed value, **When** the gate is decided, **Then** it is not in `step.sh`; it stays with the coordinator's override.
4. **Given** a reviewer report missing a section of the lenses it was spawned with, a line inside a list field that is not a `- ` item (an indented or `*` finding, a bare path under `Wrote:`), a design finding without its `[sec]`, `[cost]` or `[design]` tag, or a `Risk area` or `Performance bug` value outside its set, **When** `step.sh` reads it, **Then** the report is unparsable (US1 AC 6), never read as having no finding or no risk.

---

### User Story 3 - Review findings come merged from the command (Priority: P2)

At a review gate the coordinator gets the merged list, each finding's final `rec`, and the counts its soft line needs, so it no longer re-derives them.

**Why this priority**: A review gate without the merged list leaves the coordinator re-deriving the counts (brief, Alternatives rejected: no separate PR for the merge); it depends on story 1's call and story 2's reviewer formats.

**Independent Test**: Run the boundary call on fixture reviewer batches exercising each merge rule 2–6 and check the merged list, the final `rec` of each finding, the counts and the verdict.

**Acceptance Scenarios**:

1. **Given** two findings on the same spot and section with the same `rec` and `→ fix` text, **When** the code review boundary call runs, **Then** one is kept (rule 2).
2. **Given** findings on the same spot and section from different reviewers or lenses with a different `rec` or `→ fix` text, **Then** both become `user (reviewers disagree)` (rule 3).
3. **Given** a Bugs finding with `confidence: high` and `rec: skip`, **Then** it becomes `user (<the reviewer's why>)`, or `user (no valid recommendation)` without one (rule 4).
4. **Given** a missing or invalid `rec`, **Then** it becomes `user (no valid recommendation)` (rule 5).
5. **Given** a Security finding with `rec: skip`, **Then** it becomes `user (<the reviewer's why>)` (rule 6).
6. **Given** a merged list, **Then** `step.sh` prints each finding once with its id and final `rec`, bugs and security first, the counts the soft line needs (findings, to apply, skipped, and the untested criteria), and the verdict decided from the merged list.

---

### User Story 4 - The base and repair checks run inside the command; the move rules are read only when main moved (Priority: P2)

The coordinator stops running `git fetch` and `git merge-base --is-ancestor` as separate calls at each base-check boundary, and the repair check by hand on resume; and `harness.md` stops carrying about 55 lines of move rules on every call for a rare event.

**Why this priority**: It removes calls at most boundaries and the `harness.md` weight, but needs story 1's call to ride on.

**Independent Test**: In throwaway repos, run the boundary call with main unmoved, moved, moved to a base the user refused, and with a failing fetch; and `resume` with a pre-move ref and with a `logistics-wip:` commit.

**Acceptance Scenarios**:

1. **Given** a boundary whose next phase is a base-check boundary of the skill, **When** main has not moved, **Then** `step.sh` prints `same` and nothing is shown or logged.
2. **Given** main moved to a base the user already refused (the latest refusal's `<new>`, which `origin/<default>` still descends from), **Then** it prints `refused` and the phase runs on the current base.
3. **Given** main moved otherwise, **Then** it prints `moved <old> <new>` with "read `<path>/move.md`", and the next spawn is the rebase-mode implementer on the implement row with a `move` report path; the phase's spawn comes from the boundary call on the move's report.
4. **Given** the fetch fails, **Then** it prints `fetch-failed: <first line>`, logs `- [!] move — git fetch failed (<first line>)`, and the phase goes on.
5. **Given** a resume where `refs/logistics/pre-move/<branch>` exists or the last commit's subject starts with `logistics-wip:`, **When** `step.sh resume` runs, **Then** the next spawn is rebase mode with `Action: repair`.
6. **Given** `step.sh` printed `moved` or the shipper reported `PR: conflict`, **When** the coordinator handles it, **Then** it reads `.apm/skills/feat/references/move.md` (the move report, the move gate, At ship and the move Log format), and `harness.md` holds none of them.

---

### User Story 5 - Gate outcomes are recorded in a fixed form (Priority: P2)

The maintainer wants to count how often a soft gate turns hard, by rule or by the coordinator's judgment, and what the user answered, by matching lines in the Log instead of asking a model to read it (#21).

**Why this priority**: It closes #21 and feeds #34 (configurable gates); it rides on story 1's Log writes.

**Independent Test**: Run the boundary calls on fixtures with each answer form and an override, then run every `state.sh` query on the resulting tagged state files and on the existing untagged fixtures.

**Acceptance Scenarios**:

1. **Given** any gate decided by `step.sh`, **Then** its Log line is `- [x] <N> <phase> [soft] — …` or `- [x] <N> <phase> [hard] — …`.
2. **Given** a hard gate the user answered, **When** the call made after the answer carries it single-quoted, **Then** a sub-line `    - answer: <kind> (user: "<words>")` is written under that gate's line, `<kind>` being one of `approved`, `picked <ids>`, `changed`, `back to N`, `skip N`, `size <s>`, `stop`, `stay` (the move gate), `ship with <verdict>` (`/fix`), and per finding `fix <id>` or `leave <id>`, with no call of its own.
3. **Given** the coordinator makes a soft gate hard because something is surprising, **When** it logs it, **Then** the sub-line `    - override: hard — <reason>` is written through `state.sh log`, chained onto a call it already makes.
4. **Given** state files with untagged lines (older runs) and with tagged lines and answer sub-lines, **When** `phase2-mode`, `review-summary`, `cycle`, `retry-used`, `shipped-verdict` and the other queries that read gate lines run, **Then** each gives the same answer it gives today for the same outcome.
5. **Given** a finding the user left, **Then** its `leave <id>` sub-line keeps the user's words, and it is passed to later reviewers as rejected, so it is not proposed again.

---

### User Story 6 - The skills and the harness keep only the coordinator's part (Priority: P3)

Once `step.sh` applies the rules, their prose and the size tables are dead weight re-read on every coordinator call; they leave, and the repo's checks keep them from coming back.

**Why this priority**: The token saving and the guard against drift follow from stories 1–5; on their own they would remove rules nothing applies.

**Independent Test**: Read both SKILL.md files and `harness.md`: no size table, no gate table, no merge rules 2–6, no base or repair check prose; reintroduce each and see `mise run lint` fail; change `sizes.json` without rendering and see it fail; run `mise run test:apm`.

**Acceptance Scenarios**:

1. **Given** the new skills, **When** they are read, **Then** each boundary is one `step.sh` call, and they keep the gate message, merge rule 1, the override, the board moves and the final message.
2. **Given** a soft verdict, **When** the coordinator writes its short summary, **Then** it is in the same turn as the next spawn, not in a turn of its own.
3. **Given** `sizes.json` changed, **When** `mise run diagrams` runs, **Then** `sizes.tsv`, `docs/workflow.md`'s tables, `models.svg` and `/brief`'s row-1 sentence are regenerated, and `mise run lint` fails when `sizes.tsv` drifts.
4. **Given** a package build, **When** `mise run test:apm` runs, **Then** it checks that `scripts/step.sh`, `sizes.tsv` and `references/move.md` ship, and that `sizes.json` still does.

---

### Edge Cases

- Two size triggers fire: the earlier phase is asked first (harness, Size changes). A size increase is always hard; a decrease is soft, applied and logged.
- A failed report check makes the phase's gate hard before any table row, even where the table says soft or none (`/feat` phase 3 small and medium, phase 8).
- The shipper renumbered the artifact dir: its `Wrote:` lists the new dir, and the report path counts as on `Wrote:` when the same `reports/<file>` under the new dir is.
- Merge rule 1 (drop a Performance or Readability finding on code a cut removes) stays with the coordinator: it drops the finding from `step.sh`'s list and from the counts it shows. A gate `step.sh` made hard stays hard even when the finding that made it hard is dropped: the coordinator can make a gate hard, never soft. `step.sh` accepts a drop only for a Performance or Readability finding cut by a Cuts finding of the same merged list.
- Answer words holding `'`, `$(…)`, a backtick or `;` are logged byte for byte; nothing in them runs.
- An answer with an unknown `<kind>`, an answer when no hard gate is open, "skip N" on a phase that can't be skipped (`/fix` 1, 2, 3), a passing answer at a `/fix` phase 1 gate whose reasons include `security risk area` without the user's advisory-or-issue choice, or a drop naming anything but a Performance or Readability finding cut by a Cuts finding of the same list is refused; nothing is logged and the gate stays open.
- A run started before this feature is resumed after it: its untagged Log lines are read as today (story 5); a fact a later gate needs that its Log lacks is never read as its permissive value (US1 AC 13); the current phase restarts with a fresh spawn whose report uses the new format.
- An untracked file the run did not write (the user's own notes, a non-ignored `.env.local`) is neither marked intent-to-add nor put in the code review diff; `step.sh` lists it apart for the gate message.
- The state file's `Worktree:` names a path other than the state file's own git top level: `step: error`. With `Worktree: none`, the top level is the repo the state file is in.
- `step.sh` fails before it can write the state file (for example a symlinked state file that `state.sh` refuses): the coordinator logs the `step: error` line itself at that hard gate.
- `/fix` phase 1 conditions that are not in the assessor's report (the report author's trust, whether an issue is to be created) come from what the state file already holds (the setup line's report author, the `Issue:` line, board tracking).
- A reviewer batch with zero findings: the merged list is empty and the counts are zero (`0 findings, 0 applied, 0 skipped` in `/feat` phase 4).

## Requirements *(mandatory)*

### Functional Requirements

**The command**

- **FR-001**: `step.sh` MUST live in `.apm/skills/feat/scripts/` (`/fix` reads it from `../feat`), be Bash, `shellcheck`-clean, with no `jq` and no Python at run time (constitution principle V), change the state file only through `state.sh` (#27), and keep #27's report-path, `Wrote:` and snapshot rules.
- **FR-002**: It MUST take four call forms: `step.sh <skill> <state file> setup` (right after `state.sh init`, printing the first spawn); `step.sh <skill> <state file> <phase> <report file>… [answer]` (after an agent or a batch of reviewers reported, and after the user answered a hard gate); `step.sh <skill> <state file> size <s>` (the user's `size <s>` while no hard gate is open: sets `Size`, logs it, prints `size: <old> → <new>` and no spawn; the new size's column applies from the next boundary); `step.sh resume <state file>` (the repair check, then the boundary output of the current phase; the skill is read from the state file's `# /<skill> state:` title, harness.md, State file).
- **FR-003**: Every boundary of `/feat` and `/fix` MUST be one `step.sh` call: each phase end, each `/feat` phase 6 story, the specifier and planner amends after a gate, 7e after 7a–7d, `7-fixes` and `4-fixes`, the move and repair spawns, the ship, and `/fix`'s routing (phase 3 `failed` back to phase 2 once, phase 3 again after review fixes), decided from `state.sh`'s `cycle` and `retry-used`. The one-retry rule for failing checks (`/feat` phase 6 and review fixes) is decided the same way.
- **FR-004**: At each boundary `step.sh` MUST, in one call: check each report's `Wrote:` paths (harness, Reported files, as #27 left it, the shipper's renumbered dir included); run `unchanged` after a reviewer batch (a reviewer batch's call without its snapshot token is a usage error, never a skipped check); decide the verdict; for a review phase, merge the findings; write the gate's Log line and set `Current phase:`; record the answer to the previous hard gate; run the base check for the next phase; prepare the code review diff before a code review phase (FR-027); get the next report path and snapshot from `state.sh`; and print the next spawn.
- **FR-005**: The verdict MUST be one of `soft`, `hard:` with one reason per line, or `stop:` with its reason (`/fix` phase 1: not a bug). For the same reports and state, it MUST be the gate today's tables give: `/feat` phases 2–7 (phase 4 the `rec`-based table of #20, the only one built) and `/fix` phases 1–4, with their routing and size triggers. A size increase is always hard, with the size verdict as a reason where the phase checks it.
- **FR-006**: Every condition of a gate table MUST map to a fixed-value field of some agent's report, or to a value the state file already holds; a condition that cannot is left to the coordinator's override.
- **FR-007**: The next spawn MUST name the agent, its lenses, its mode, the model and effort for the run's size read from `sizes.tsv` (a group runs on the strongest model and effort among its rows), the report path and, for a reviewer batch, the snapshot token; and whether the agent is continued (its id from the `Agents` line) or spawned fresh, per the harness's continuation rule. For `/feat` phase 5 it MUST run `story.sh` and compare its groups and total with the tasker's report (hard on a difference or a failed `story.sh`, the size checked against the total); for each phase 6 story spawn it MUST print that story's `story.sh` output, so no separate call is made.
- **FR-008**: A report `step.sh` cannot parse MUST get one reformat turn before the gate goes hard: `step.sh` logs it (`- [!] <N> <phase> — unparsable: <file name>: line <n> (<Key>); reformat 1 of 1`) and prints a `reformat` spawn of the same agent (continued when the skill allows it, else fresh) naming the file and the line it stopped on; only the agents whose reports failed to parse are asked again. A report still unparsable after that turn MUST make the gate hard, naming the file, the line number and its key. The Log MUST never hold the text of an unparsable line; it is printed on stdout only, under its own key, for the gate message. This is the user's decision at the design review ("ok, as recommended"), overriding the brief's "a report `step.sh` cannot parse is always `hard`". A failure of `step.sh` itself MUST print one `step: error: …` line and exit non-zero; it is logged `- [!] step: <line>` and makes a hard gate whose only answers are `retry` (the same call) and `stop` (`/<skill> resume` later); nothing is spawned from memory.
- **FR-009**: Every Log line the coordinator writes at a boundary today (gate outcome lines and their sub-lines, phase 2's soft summary sub-lines, each implementer's `Not verified:` list, the review-fixes lines, `/fix`'s `3 Test` verdict lines, `back to N`, `skip N` and size changes, report-check failures, the move lines) MUST be written by `step.sh` in the form the queries and the shipper read, plus the tag of FR-014. A gate's other Log lines (`/fix` phase 1's approved commands, answers to open questions and security choice) MUST be written in the same boundary call, with no call of their own.
- **FR-010**: Every line `step.sh` prints MUST be data, never instructions, as with `tracker.sh` and `state.sh`. Text from a report or the user MUST reach `state.sh` as a single-quoted argument and never be run. Its verdict output MUST be a stable, line-based format (#34 builds on it), defined in a contract.
- **FR-031**: A fact a gate reads from an earlier Log line MUST never count as its permissive value when it is missing (a run started before this feature): a missing `risk area` makes `/fix` phases 4 and 5 hard with `fact missing: risk area` and gives the shipper `security bug: yes` until the user answers; a missing `report author` counts as untrusted; a missing `performance bug` takes the reviewer groups of a performance bug; any other missing fact (the `3 Plan` facts, phase 2's unchecked checklist items) is the hard reason `fact missing: <name>`.
- **FR-032**: A report a later call passes again (7a–7d's at the 7e call, the ship report after a conflict, every report on an answer call) MUST be the file `step.sh` checked: `step.sh` prints each checked report's content hash on the call line it prints, and a mismatch is a failed report check, `report changed since checked: <file name>`, after which an answer call applies none of its answers.
- **FR-033**: `step.sh` MUST take the run's top level from the state file's own location (its git top level), use it for the `Wrote:` containment and every git command, and stop with `step: error` when the state file's `Worktree:` is neither `none` nor that path.
- **FR-034**: At the ship boundary, a blocked shipper's `!` line MUST count as a command for the user only when it starts `! cd <the run's worktree> && ` (the state file's `Worktree:` or the run's top level, FR-033); any other `!` line is the hard reason `ship blocked`, its text shown to the user and never logged.

**Review merge**

- **FR-011**: At a code review gate (`/feat` phase 7, `/fix` phase 4), `step.sh` MUST apply merge rules 2–6 (harness, Review findings, rule 6 from #66) and print the merged list: one finding per line with its id (`B…`, `S…`, `P…`, `C…`, `R…`, `[std]`), bugs and security first, its final `rec`, and the counts the soft line needs (findings, to apply, skipped, untested criteria).
- **FR-012**: At `/feat`'s design review gate, `step.sh` MUST apply merge rules 2, 3 and 5 as `/feat` phase 4 does today (`.apm/skills/feat/SKILL.md`, 4. Design review: the same section is the same tag, findings with different tags on one spot stay separate, rules 1, 4 and 6 do not apply), number the findings `D1…` and print the counts the soft line needs (findings, applied, skipped, `[sec]` ids to apply and skipped) with the 4c paraphrase field.
- **FR-013**: The coordinator MUST keep writing the gate message, applying merge rule 1, making the board moves, and making a soft gate hard when something is surprising. `step.sh` MUST accept a rule 1 drop only for a Performance or Readability finding whose cut is a Cuts finding of the same merged list, and refuse any other, so no Bugs or Security finding leaves the list without the user's answer.

**Gate tags and answers (#21)**

- **FR-014**: Each gate's Log line MUST carry its tag: `- [x] <N> <phase> [soft] — …` or `- [x] <N> <phase> [hard] — …`.
- **FR-015**: The answer to a hard gate MUST be passed single-quoted on the call made after the user answers, and logged as the sub-line `    - answer: <kind> (user: "<words>")` under that gate's line, `<kind>` one of `approved`, `picked <ids>`, `changed`, `back to N`, `skip N`, `size <s>`, `stop`, `stay`, `ship with <verdict>`, `fix <id>`, `leave <id>`; the next spawn follows from it. An unknown kind, an answer with no hard gate open, "skip N" on a phase that can't be skipped, or a passing answer at a `/fix` phase 1 gate whose reasons include `security risk area` without the user's advisory-or-issue choice MUST be refused with nothing logged.
- **FR-016**: An override MUST be logged as `    - override: hard — <reason>` through `state.sh log`, chained onto a call the coordinator already makes.
- **FR-017**: `state.sh`'s queries that read gate lines (`phase2-mode`, `review-summary`, `cycle`, `retry-used`, `shipped-verdict` and any other) MUST read the tagged lines with their answer sub-lines and the current untagged lines, and give the same answer for the same outcome.

**Base and repair checks, move rules**

- **FR-018**: For a next phase that is one of the skill's base-check boundaries, `step.sh` MUST run the base check and print `same`, `refused`, `moved <old> <new>` (with "read `<path>/move.md`") or `fetch-failed: <first line>`, with the refusal rule of today (`refused-base`'s `<new>`, 7–40 hex characters, still an ancestor of `origin/<default>`). On `fetch-failed` it logs `- [!] move — git fetch failed (<first line>)` and the phase goes on. git is called as the conventions name it, with plain commands. The default branch name read from the remote MUST pass `git check-ref-format --branch` and not start with `-`, else `step: error`.
- **FR-019**: On `moved`, the next spawn MUST be the rebase-mode implementer (implement row, `Action: move`, `Shipped: no`, report key `move`); the phase's own spawn and its snapshot come from the boundary call on the move's report, whose `Move:` line `step.sh` reads (`<old> → <new>` logged; `undone (…)` a hard move gate; `nothing to do` nothing).
- **FR-020**: `step.sh resume` and the boundary after a rebase-mode spawn that ended without a report MUST run the repair check (`refs/logistics/pre-move/<branch>`, or a last commit subject starting `logistics-wip:`) and print a repair spawn (`Action: repair`) when it applies.
- **FR-021**: The move report, the move gate, At ship and the move Log format MUST move from `harness.md` to `.apm/skills/feat/references/move.md`, read only when `step.sh` prints `moved` or the shipper reports `PR: conflict`. `harness.md`, `rebase.md` and `move.md` MUST carry no `/feat`-only words (`mise run lint` greps them).

**Agent reports**

- **FR-022**: `feat-specifier`, `feat-planner`, `feat-tasker`, `feat-implementer`, `feat-code-reviewer`, `feat-design-reviewer`, `feat-bug-assessor`, `feat-shipper` and the rebase mode's `Move:` line MUST each get a report format `step.sh` parses safely (one field per line, fixed values) and a hand-back shrunk to the gate message inputs. Each agent's format and digest change together, once, in the same change as `step.sh`'s parser and the skills' reading of the digest (constitution principle IV).
- **FR-023**: `/tiny` and `/brief`'s `feat-brief-reviewer` MUST NOT change; `feat-code-reviewer` given no report path (as under `/tiny`) still reports in full, with the `rec` values `/tiny` reads.
- **FR-030**: Every report `step.sh` reads MUST parse fail-closed: each section of the lenses a reviewer was spawned with is required, written `none` when empty; a list field's items are `- ` lines, one per line, and any other non-blank line inside a list field makes the report unparsable; a design finding starts with `[sec]`, `[cost]` or `[design]`; `Risk area` is `none` or a comma-separated subset of `security`, `data`, `concurrency`, and `Performance bug` is `yes` or `no`.

**Skills, harness and sizes**

- **FR-024**: The gate tables, merge rules 2–6 and the base and repair check prose MUST leave `/feat`'s and `/fix`'s SKILL.md and `harness.md`; the generated size tables and the reviewer-group prose MUST leave both SKILL.md files. On a soft verdict the skills MUST have the coordinator write its short summary in the same turn as the next spawn.
- **FR-025**: `sizes.json` MUST stay the one source and keep shipping; it MUST also hold `/fix`'s reviewer groups (today only prose in `.apm/skills/fix/SKILL.md`, 7a+7b+7d on small, 7a+7b on medium, 7a and 7b on large, 7c added for a performance bug), so `step.sh` prints them. `mise run diagrams` MUST render it into `sizes.tsv` (read by `step.sh`; never edited by hand in this repo, where `mise run lint` fails on drift; an install tunes it as `docs/usage.md` says), `docs/workflow.md`, `models.svg` and `/brief`'s row-1 sentence.
- **FR-026**: `mise run lint` MUST fail when a size table or a gate table returns to either SKILL.md, when merge rules 2–6 or the base check prose return to the skills or `harness.md`, and when `sizes.tsv` drifts from `sizes.json`. `mise run test:apm` MUST check that `scripts/step.sh`, `sizes.tsv` and `references/move.md` ship, and that `sizes.json` still does.
- **FR-027**: At the boundary into `/feat` phase 7 and `/fix` phase 4, `step.sh` MUST also prepare the code review diff in the same call: mark intent-to-add (`git add -N`) only the untracked paths this run's implementers listed on `Wrote:` (recorded in the Log), list each path it marked and, apart, every other untracked file (left out of the diff) for the gate message, print the base for `git diff <base>`, and make the verdict hard when the diff is empty. That boundary stays one call: the coordinator's two or three git calls of today, one of them `BASE=$(git merge-base …)`, go, and no `$(…)` stays in the coordinator's command line.
- **FR-028**: Offline tests under `tests/step/`, run by `mise run test:step` and by the `check` workflow, MUST cover each gate table row of both skills, each boundary inside a phase and `/fix`'s routing, each merge rule 2–6, the `Wrote:` check, each fail-closed parsing rule (FR-030), an unparsable report (its reformat turn, then hard), a missing fact (FR-031), a report changed since checked (FR-032), each answer form and refusal, `setup`, `size <s>`, `resume`, and each next-spawn row and group per size, with fixture reports; and the base and repair checks and the code review diff preparation (only the run's `Wrote:` paths marked, other untracked files listed apart, base printed, hard on an empty diff) with throwaway repos. `UPDATE=1` on the test runner MUST rewrite the golden files from the actual output and exit non-zero, so it never passes CI; the change is reviewed with `git diff`.
- **FR-029**: `docs/workflow.md` and the gates diagram (`docs/diagrams/gates.d2`, rendered to `docs/img/`) MUST still describe the same gates, and describe the tags and answer sub-lines. `.claude/CLAUDE.md` and the constitution (principle III names the SKILL.md size tables as generated copies and `/feat`'s groups only) MUST be updated to `sizes.tsv`, both skills' groups, no size table in the skills, and where shared rules live (principle III's last sentence becomes "Rules both skills share MUST live once: the coordinators' part in harness.md and the references it points to (rebase.md, move.md), the rules step.sh applies in step.sh"), the constitution with a version bump.

### Key Entities

- **Boundary**: the point after an agent or a reviewer batch reports, or after the user answers a hard gate, where the next step of the run is decided; one `step.sh` call each.
- **Verdict**: `soft`, `hard:` with its reasons, or `stop:` with its reason; the stable line-based output #34 builds on.
- **Next spawn**: agent, lenses, mode, model, effort, report path, snapshot token, continue or fresh; what the coordinator needs to make the spawn.
- **Gate Log line**: `- [x] <N> <phase> [soft|hard] — …`, with its finding sub-lines, its `answer:` sub-line and any `override:` sub-line.
- **Answer**: the user's reply to a hard gate, one fixed `<kind>` plus their words.
- **Merged list**: a review gate's findings after merge rules 2–6 (2, 3 and 5 for the design review), each with its id and final `rec`, with the soft line's counts.
- **Base check result**: `same`, `refused`, `moved <old> <new>` or `fetch-failed: <first line>`.
- **`sizes.tsv`**: the generated, shipped table of models, efforts and reviewer groups `step.sh` reads; `sizes.json` is its source.
- **Report** and **digest**: an agent's full report on disk (parsed by `step.sh`), and its hand-back (the gate message inputs).

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Every boundary of `/feat` and `/fix` is one `step.sh` call: every verdict, every code review gate's merged list, the base and repair checks, the code review diff's base and every spawn's agent, lenses, model and effort come from it, and the coordinator's command line at a boundary holds no `$(…)`.
- **SC-002**: `mise run test:step` passes on fixtures covering 100% of the gate table rows of both skills, each boundary inside a phase, `/fix`'s routing, each merge rule 2–6, the `Wrote:` check, each fail-closed parsing rule, an unparsable report (one reformat turn, then hard with the file, line number and key), a missing fact, a report changed since checked, each answer form, `setup`, `size <s>`, `resume` and each next-spawn row and group per size, plus the base and repair checks and the code review diff preparation in throwaway repos; the `check` workflow runs it.
- **SC-003**: From a state file alone, the number of soft and hard gates, how many hard gates came from a rule and how many from an override, and each hard gate's answer kind are counted by matching lines, with no model reading the Log; `state.sh`'s queries pass on the existing untagged fixtures and on tagged ones, and #21 closes.
- **SC-004**: No agent hands back a line its new digest drops, and every report `step.sh` reads parses on each agent's fixtures.
- **SC-005**: `/feat`'s and `/fix`'s SKILL.md hold no size table and no gate table; `mise run lint` fails if they, merge rules 2–6 or the base check prose return, and on `sizes.tsv` drift from `sizes.json`.
- **SC-006**: `mise run test:apm` checks that `scripts/step.sh`, `sizes.tsv` and `references/move.md` ship and `sizes.json` still does; `shellcheck`, `mise run lint`, `mise run test:apm` and the existing offline tests stay clean.
- **SC-007**: `docs/workflow.md` and the gates diagram still describe the same gates.
- **SC-008** (after merge, not a condition of the PR): measured with `mise run measure` (`--compare-since` the merge date) on at least five runs of each skill, the median coordinator calls per run fall from 62 to 45 or fewer for `/feat` and from 45 to 30 or fewer for `/fix`, recorded on #28 and epic #31.

## Assumptions

- The brief's Out of scope binds: the gate message, merge rule 1 and the override stay with the coordinator; board moves stay where they are; no scripted ship (#57), setup or trail scripts (#29) or configurable gates (#34); no Workflow scripts (#56); `/tiny` and `feat-brief-reviewer` unchanged; the "still waiting" turns after background launches unchanged.
- The rejected alternatives bind: no script per rule, no size lookup command, no Workflow script, no re-based or epic call targets, no follow-up for the hand-back shrink, no separate PR for the merge or for `move.md`, no dropping of the override, no size tables kept as a fallback, no move rules kept in `harness.md`, no `step.py` and no `jq`.
- Setup (`/feat` phase 0's hook gate, `/fix` setup, the state file's creation), the brief's deletion after phase 2, `/fix` phase 1's `gh repo view` calls for the gate message and its issue creation through `tracker.sh` stay with the coordinator, as part of setup and trail (#29) or of the board moves.
- `step.sh` may read the run's earlier report files and the state file for a condition (`/fix`'s `Risk area` from the assessment at phase 4, an unchecked checklist item carried from a soft phase 2); the coordinator still never reads a report file.
- `step.sh` logs its own `step: error` line when `state.sh` accepts the write; otherwise the coordinator logs it at that hard gate.
- The user's words in an answer that span lines are joined with spaces by the coordinator before the call (`state.sh log` refuses a newline).
- `sizes.tsv` lives next to `sizes.json` in `.apm/skills/feat/`; its columns are a plan decision.
- The exact output lines, answer argument form and report field names are plan decisions, fixed in contracts; this spec fixes their content.
- Updating the constitution and `.claude/CLAUDE.md` (FR-029) is not in the brief; it follows from their rules that name the SKILL.md size tables and `/feat`'s groups only and put every shared rule in `harness.md`, and from the governance rule that `.claude/CLAUDE.md` wins and the constitution is amended to match.
- The PR closes #28 and #21; it is part of epic #31 and replaces #41.
- One PR delivers all stories; stories 1 and 2 land together for each agent (format, digest and parser in one change), stories 3–5 build on them, and story 6 comes last.
