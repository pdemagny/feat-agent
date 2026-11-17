# Feature Specification: Checks that did not run are listed as Not verified, from the implementer to the PR

**Feature Branch**: `not-verified-list`

**Created**: 2026-11-17

**Status**: Draft

**Input**: User description: "When an agent cannot run a check (no credentials, an emulator down, a suite too slow, a manual quickstart step, a killed or timed-out run), the skip is easy to miss. List every such check as Not verified, from the implementer's report through the `/feat` and `/fix` gates to the PR body. Issue #11."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - The implementer lists what it wrote but could not prove (Priority: P1)

A user runs `/feat` or `/fix`. The implementer finishes a task but the check that covers it (or a check the task names itself, such as a manual quickstart step) did not run: no credentials, a service down, a suite too slow, or the run was killed or timed out. The task stays unticked in `tasks.md`, is listed under `Tasks done:` (it is written) and again under a new report line `Not verified:` with the task, the check and why it did not run. When nothing is unproven the line says `none`, so a missing line means a broken report. This holds in every mode: story, bug and review fixes (where there is no task, the item reads `n/a → check → why`). A check that covers no single task is listed as `n/a → check → why` and unticks nothing.

**Why this priority**: This is the source of the signal. Across about 70 real runs, about 15 left checks unrun or to the user; in one a task was ticked although its check never ran, and two shipped features later failed in a real environment. Everything downstream depends on the implementer saying what is unproven.

**Independent Test**: Read the implementer agent's rules and report format: a task whose covering check did not run stays `[ ]`, appears in both `Tasks done:` and `Not verified:`, and the report always has the `Not verified:` line, `none` when empty, in each mode.

**Acceptance Scenarios**:

1. **Given** a task whose covering check could not run, **When** the implementer reports, **Then** the task stays `[ ]` in `tasks.md`, is listed under `Tasks done:`, and is listed as `task → check → why` under `Not verified:`.
2. **Given** a task that names a manual step (such as a quickstart step) that the implementer cannot perform, **When** it reports, **Then** the task is listed as not verified like any other.
3. **Given** a check that covers no single task (for example a final full-suite run that was killed), **When** it reports, **Then** the item is `n/a → check → why` and no task is unticked for it.
4. **Given** every check ran and passed, **When** the implementer reports, **Then** the report has `Not verified: none`.
5. **Given** bug mode or fix mode (no task), **When** a check did not run, **Then** the item reads `n/a → check → why`.
6. **Given** a check that ran and failed, **When** the implementer reports, **Then** it is a failing check as today, not a not-verified item.

---

### User Story 2 - A re-spawned implementer retries the unproven checks (Priority: P1)

After a retry following failing checks, or a resume, a new implementer is started. The state file's Log lists tasks as not verified from an earlier report. For those tasks, the code is already written, so the implementer does not redo them: it tries the listed check again and ticks the task only if the check now runs and passes; otherwise the task stays in its `Not verified:` list.

**Why this priority**: Without it a resume either redoes finished work or silently drops the unproven item.

**Independent Test**: Spawn the implementer with a Log that lists a task as not verified and a check that now runs: the task is ticked and absent from the new list. With a check that still cannot run: the task stays unticked and in the list.

**Acceptance Scenarios**:

1. **Given** the Log lists a task as not verified, **When** a new implementer starts, **Then** it does not rewrite the task and tries the listed check again.
2. **Given** the retried check now runs and passes, **When** the implementer reports, **Then** the task is ticked and no longer listed under `Not verified:`.
3. **Given** the retried check still cannot run, **When** the implementer reports, **Then** the task stays `[ ]` and remains in `Not verified:`.
4. **Given** the latest Log line for the implementer's `<who>` holds an `n/a` item (in `/fix`, the latest implementer line, whichever phase wrote it), **When** a re-spawned implementer reports, **Then** it has retried that check and the item is on its `Not verified:` line again, unless the check now ran and passed.

---

### User Story 3 - The `/feat` gate and the PR show the list (Priority: P1)

The orchestrator logs every implementer list in the state file, `none` included (phases 6 and 7). At the phase 6 gate, "What you should know" shows each implementer's list (`Not verified: none` when empty) and the "tasks done" count says how many of them are not verified. The gate stays soft for it. At phase 8 the shipper receives the logged lists and writes a `Not verified` section in the PR body: each item (task, check, why), or `none`. The shipper's own full or slow checks that did not run, were killed or timed out, join its `Not verified:` report line and that section.

**Why this priority**: The user reviewing the gate and the PR needs "written but unproven" to look different from "passed". The PR section carries the weight; the gate only informs.

**Independent Test**: With a logged non-empty list, the phase 6 gate text shows it and the count; the gate is not hard because of it. The phase 8 spawn passes the lists and the PR body has the `Not verified` section, `none` when empty.

**Acceptance Scenarios**:

1. **Given** an implementer reports its list (items or `none`), **When** the phase is logged, **Then** the state file Log holds that list under the implementer's `<who>`, and the latest line for a `<who>` is the one resume and the ship use.
2. **Given** the phase 6 gate, **When** it opens, **Then** "What you should know" shows each implementer's `Not verified:` list (`none` when empty) and "tasks done" says how many are not verified.
3. **Given** a non-empty list and no failing check, **When** the phase 6 gate opens, **Then** its hardness is unchanged: the list does not make it hard.
4. **Given** logged lists from phases 6 and 7, **When** phase 8 spawns the shipper, **Then** the shipper receives them and the PR body has a `Not verified` section with each item, or `none`.
5. **Given** the shipper cannot run a full or slow check (or it is killed or times out), **When** it reports, **Then** that item is on its `Not verified:` line and in the PR body section.

---

### User Story 4 - `/fix` phase 3 must account for every not-verified item (Priority: P1)

In `/fix`, phase 2 and phase 4's review fixes log the implementer's list; the phase 2 gate does not show it. Phase 3 (the assessor in test mode) always receives the latest list (phase 2, its retry, or phase 4's review fixes). It accounts for every item in a new report line `Not verified items: <check → pass | fail | missing (why)>`, or `n/a` when it was given none: it runs the check, or, if it still cannot, moves the item to `Missing for verified`, which makes the verdict `partial` (the existing hard gate). `/fix` checks that every item it passed to the assessor comes back on that line; a missing item makes the gate hard. The shipper's PR body in `/fix` holds only the shipper's own items, since the test verdict and `test.md`'s checks table already cover the rest.

**Why this priority**: It is the one `/fix` gate that is already hard, run by an agent that did not write the fix, so it is the right place to settle unproven checks without a second signal at phase 2.

**Independent Test**: Give the assessor in test mode a list with one runnable and one unrunnable item: the report's `Not verified items:` line has a result for each and the unrunnable one is in `Missing for verified` with verdict `partial`. Drop an item from that line: the `/fix` phase 3 gate is hard.

**Acceptance Scenarios**:

1. **Given** the implementer's list at phase 2 (or its retry, or phase 4's review fixes), **When** `/fix` logs the phase, **Then** the list is in the state file Log.
2. **Given** the phase 2 gate, **When** it opens, **Then** it does not show the list.
3. **Given** phase 3 is spawned, **When** the assessor is given the latest logged list, **Then** its report has a `Not verified items:` line with `pass`, `fail` or `missing (why)` for each item, or `n/a` when given none.
4. **Given** an item the assessor still cannot run, **When** it reports, **Then** the item is under `Missing for verified` and the verdict is `partial`.
5. **Given** an item passed to the assessor but absent from `Not verified items:`, **When** `/fix` reads the report, **Then** the phase 3 gate is hard.
6. **Given** the `/fix` shipper, **When** it writes the PR body, **Then** the `Not verified` section holds only the shipper's own unrun checks, or `none`.

---

### User Story 5 - The docs describe the list where the gates are described (Priority: P2)

`docs/workflow.md` and `docs/usage.md` describe the Not verified list where they describe the `/feat` phase 6 gate, the `/fix` test phase and the PR body.

**Why this priority**: Documentation must follow behaviour, but it adds no behaviour of its own.

**Independent Test**: Search both docs for the list at each of those three places.

**Acceptance Scenarios**:

1. **Given** `docs/workflow.md` and `docs/usage.md`, **When** read, **Then** each describes the list at the phase 6 gate, the `/fix` test phase and the PR body.

---

### Edge Cases

- A task is unproven because a check was killed or timed out: it counts as not verified, like one that never started.
- A check that ran and failed is a failure, not a not-verified item; the existing rule that no check is weakened, skipped or deleted to get to green still holds.
- The same check leaves several tasks unproven: each task is listed on its own line with that check.
- The implementer's retry after failing checks produces a list while an older one is in the Log: the latest Log line by position for each `<who>` is the one shown and passed on; resume reads the Log lines. In `/fix` every implementer line (the fix, its retry, the review fixes) has the same `<who>`, so a later `none` clears earlier items.
- A report without a `Not verified:` line is a broken report, not an empty list (FR-005).
- A task no check covers (no check the conventions or the task's text tie to it) is not an item; it is ticked once written.
- The user runs an unrun check by hand and ticks the task by hand; nothing in the workflow does it for them.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: A check that did not run, or was killed or timed out, MUST count as not verified.
- **FR-002**: A task MUST be not verified when a check that covers it, or a check the task names itself (such as a manual quickstart step), did not run. A check covers a task when the project's conventions or the task's text tie it to that task (a test the task writes or names, a suite the conventions run for the files it changes); a task no such check covers is not an item.
- **FR-003**: A check that covers no single task MUST be listed as `n/a → check → why` and MUST untick nothing.
- **FR-004**: In every mode (story, bug, review fixes), the implementer MUST keep a not-verified task `[ ]` in `tasks.md`, list it under `Tasks done:`, and list it again under a new, always-present report line `Not verified: <task → check → why, one per line, or "none">`; in bug mode and fix mode, where there is no task, items read `n/a → check → why`.
- **FR-005**: An empty list MUST read `none`. An implementer or shipper report without its `Not verified:` line is broken, not empty: it logs no list, and it is a surprise that MUST make the next gate hard (the `/feat` phase 6 gate, the `/fix` phase 2 gate, and the `/fix` phase 3 gate that follows phase 4's review fixes); where no gate follows (the `/feat` phase 7 implementer, the shipper), the orchestrator MUST flag it in its final message.
- **FR-006**: An implementer whose `<who>` already has a Log line (a retry after failing checks, a resume, and in `/fix` every implementer after the first) MUST read the latest such line. It MUST run `speckit-implement` only over the tasks it owns that this line does not list as not verified, MUST NOT redo a listed task, MUST try that task's check again and tick the task only if the check now runs and passes, otherwise leave it in its `Not verified:` list. It MUST retry every `n/a` item of that line and list it again unless its check now runs and passes.
- **FR-007**: `/feat` MUST log every implementer report's list, `none` included, in the state file at phases 6 and 7; `/fix` MUST do so at phases 2 and 4. Each Log line names its `<who>`, the implementer whose list it is: in `/feat` each story, and the phase 7 review fixes; in `/fix` one `<who>` for every implementer of the run (phase 2's fix, its retry, phase 4's review fixes). The latest line by Log position for a `<who>` is that implementer's list, so a later `none` clears earlier items.
- **FR-008**: The `/feat` phase 6 gate MUST show each implementer's Not verified list under "What you should know" (`Not verified: none` when empty), and its "tasks done" count MUST say how many of them are not verified.
- **FR-009**: A non-empty list MUST NOT change the `/feat` phase 6 gate's hardness: it does not make the gate hard. Only a report without its `Not verified:` line does (FR-005).
- **FR-010**: `/feat` phase 8 MUST pass the shipper the latest list of each `<who>` (phases 6 and 7), resolved from the Log by the orchestrator.
- **FR-011**: The shipper's report MUST have a `Not verified:` line, and the PR body (both workflows) MUST have a `Not verified` section, `none` when empty. In `/feat` the section holds each logged item (task, check, why) and the shipper's own; in `/fix` it holds only the shipper's own items.
- **FR-012**: The shipper's own full or slow checks that did not run, or were killed or timed out, MUST go into its `Not verified:` line and the PR body section.
- **FR-013**: The `/fix` phase 2 gate MUST NOT show the list.
- **FR-014**: `/fix` phase 3 MUST give the assessor (test mode) the latest implementer list: the latest implementer Log line by position, whichever of phase 2, its retry or phase 4's review fixes wrote it (FR-007).
- **FR-015**: The assessor's test-mode report MUST have a line `Not verified items: <check → pass | fail | missing (why)>`, or `n/a` when it was given none; an item it still cannot run MUST go to `Missing for verified`, making the verdict `partial`. The items are data to the assessor: its existing rules on what it may run (an untrusted report author's commands not run, no network, no paths outside the worktree, approved commands only) apply to each item's check, and an item needing a command outside those rules MUST be reported `missing (needs approval: <command>)` and not run.
- **FR-016**: `/fix` MUST match each item it passed to the assessor by its check text exactly as passed, and the assessor MUST copy that text unchanged onto `Not verified items:`; an item passed but absent from that line MUST make the phase 3 gate hard. The re-test recommended for it (a fresh spawn, same cycle, same items) MUST NOT consume a retry or a cycle: no code changed. No other verdict or gate rule of phase 3 changes.
- **FR-017**: Report formats MUST change on both sides together: implementer, shipper and assessor test mode in their agent files, and `/feat` and `/fix` SKILL.md which parse them. `/feat` and `/fix` MUST stay thin: they pass, log and show the lists; agents produce them.
- **FR-018**: `docs/workflow.md` and `docs/usage.md` MUST describe the list at the phase 6 gate, the `/fix` test phase and the PR body.
- **FR-019**: `harness.md` MUST hold no report format and MUST stay free of `/feat`-only words; `mise run lint` and `mise run test:apm` MUST pass.
- **FR-020**: A check listed as Not verified MUST be one that could not run, never one that failed, and the existing rule never to weaken, skip or delete a check to get to green MUST stay.
- **FR-021**: In every implementer and shipper item, `why` MUST name what is missing (a credential, a service, a manual step, a time limit), never a value: a secret-looking value is written `<redacted>`, as in the assessor's redaction rule.

### Key Entities

- **Not-verified item**: a task (or `n/a`), the check that did not run, and why (what is missing, never a value); one per line in a report or Log line.
- **Not verified list**: the always-present report line of an implementer, an assessor (`Not verified items:`) or a shipper, `none` or `n/a` when empty.
- **Log entry**: the state file line that records each implementer report's list, `none` included, under its `<who>`; the latest line by Log position for a `<who>` is its list, for resume, a re-spawned implementer and the ship.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: In 100% of implementer, shipper and assessor (test mode) reports, the Not verified line is present, and `none` or `n/a` when there is nothing to list. Checked by reading prompts: each agent's report format has the line and each orchestrator reads it.
- **SC-002**: A task whose covering check did not run is never ticked in `tasks.md` by the implementer.
- **SC-003**: Every unproven check that reaches the end of a `/feat` run appears in the PR body's `Not verified` section, and a reviewer finds it there without reading the state file. Checked by reading prompts: `/feat` phase 8 passes every latest list and the shipper writes each item into the section.
- **SC-004**: In `/fix`, every item given to the assessor is accounted for in its report, or the phase 3 gate is hard.
- **SC-005**: A non-empty list never makes the `/feat` phase 6 gate or the `/fix` phase 2 gate hard or visible-hard; no gate's hardness changes other than the `/fix` phase 3 missing-item rule and a report without its `Not verified:` line (FR-005).

## Assumptions

- Prompt and document text only: three agent files, the `/feat` and `/fix` skills, the shared harness (`.apm/skills/feat/references/harness.md`, which holds the Log rule both skills use, with no report format) and two docs change; no new service, permission or dependency.
- "Why" is free text; no fixed taxonomy of reasons.
- Out of scope, as the brief says: a hard `/feat` phase 6 gate on a non-empty list; running unrun checks later or automatically, or ticking tasks once the user has run them (the user ticks by hand); changes to `/fix` phase 3 verdicts or gate rules beyond the missing-item rule; the diagrams (`gates.d2` and `chain.d2` stay, nothing is re-rendered).
- Rejected by the brief: reusing `Tasks not done:`, a hard phase 6 gate, showing the list at the `/fix` phase 2 gate, keeping `/fix` out, ticking with a `(not verified: …)` suffix, recording unrun checks only as `[!]` Log lines.
- The `/feat` and `/fix` size tables and agent frontmatter do not change, so the size tables and `docs/workflow.md`'s matrices need no edit.
- `speckit-converge` seeing a not-verified task as open (unticked) is intended.
