# Feature Specification: Soft spec gate, with the spec summary at the design gate

**Feature Branch**: `soft-spec-gate`

**Created**: 2026-11-16

**Status**: Draft

**Input**: User description: "Make the spec gate (phase 2 of `/feat`) soft unless the spec has open questions, and show the spec summary, the specifier's assumptions and the unchecked checklist items at the next gate. Issue #6."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - A clean spec does not stop the run (Priority: P1)

A user runs `/feat` on a brief. The specifier writes a spec with no open `[NEEDS CLARIFICATION]` markers and reports no blocker. The run reports in one line that the spec is written and goes straight on to the plan, without waiting for the user. The state file's Log records that phase 2 was soft and holds the spec summary, the specifier's assumptions with their recommendations, and the unchecked checklist items.

**Why this priority**: This is the point of the feature. Across 75 runs on a private project, the spec was approved as written in about 54, so the stop at phase 2 teaches the user to approve without reading, and costs a round trip right before another stop.

**Independent Test**: Run `/feat` on a brief whose spec comes back with no open markers and no blocker. The run reaches phase 3 without asking the user anything, prints one report line for phase 2, and the state file Log contains a line saying the gate was soft plus the summary, assumptions and checklist items.

**Acceptance Scenarios**:

1. **Given** a spec with no open markers and no specifier blocker, **When** phase 2 finishes, **Then** the run continues to the plan without stopping, with a one-line report.
2. **Given** that same spec, **When** phase 2 finishes, **Then** the state file Log says phase 2 was soft and records the spec summary, the assumptions with their recommendations, and the unchecked checklist items.
3. **Given** a feature of any size, large included, **When** the spec has no open markers and no blocker, **Then** phase 2 is soft in the same way.

---

### User Story 2 - Open questions still stop at the spec (Priority: P1)

When the specifier leaves open `[NEEDS CLARIFICATION]` markers or reports a blocker, phase 2 stops as it does today; so does anything surprising in its report (a remark about size included), by the existing soft-gate rule. The user answers the questions, answers and edits go to the specifier in amend mode, and the next gate is as it is today (no spec summary is carried forward, since the user has just read the spec).

**Why this priority**: The planner and the design reviewers would otherwise build on an answer the user may reject, which means planning and reviewing again.

**Independent Test**: Produce a spec with one open marker. The run stops at phase 2 with the questions and recommended answers; after the user answers, the specifier amends the spec and the next gate shows no spec summary.

**Acceptance Scenarios**:

1. **Given** a spec with open markers, **When** phase 2 finishes, **Then** the run stops and asks the user, with a recommended answer for each marker.
2. **Given** a specifier blocker (the report has no `Spec:` path, or its Assumptions or Open markers say the brief can't be specified as written), **When** phase 2 finishes, **Then** the run stops.
3. **Given** a specifier report with no open marker and no blocker but a remark about size (or anything else surprising), **When** phase 2 finishes, **Then** the run stops (the existing rule that anything surprising makes a soft gate hard); a size increase itself is still detected at phase 3 (the planner's size trigger) and phase 5 (the task count).
4. **Given** phase 2 was hard, **When** the next gate opens, **Then** it is as it is today, without the spec summary.
5. **Given** the Log has several phase 2 lines (after "back to 2" or a rerun), **When** the next gate opens, **Then** the latest phase 2 line decides whether the summary is shown.

---

### User Story 3 - The next gate shows the spec summary (Priority: P1)

After a soft phase 2, the next gate opens with the spec summary before anything else: the stories and requirements in a few lines, the specifier's assumptions with their recommendations, and the unchecked checklist items with the question whether to proceed. That gate is the plan and design review gate on small and medium features, and the phase 3 plan gate on large ones. The user answers the assumptions and the checklist question there, and "ok" accepts the recommendations.

**Why this priority**: The user must still be able to see and overturn the spec and the assumptions before tasks are generated; moving the summary here puts it in front of a gate that stops anyway.

**Independent Test**: After a soft phase 2 on a small feature, reach the plan and design review gate and check that its report starts with the summary, assumptions and checklist question, then the plan paraphrase and the findings. Repeat on a large feature at the phase 3 gate.

**Acceptance Scenarios**:

1. **Given** a soft phase 2 on a small or medium feature, **When** the plan and design review gate opens, **Then** it shows the spec summary, the assumptions with recommendations and the checklist question before the paraphrase and the findings.
2. **Given** a soft phase 2 on a large feature, **When** the phase 3 gate opens, **Then** it shows the same summary block first.
3. **Given** the user replies "ok" at that gate, **When** the run continues, **Then** the assumptions are accepted at their recommendations and logged as accepted.
4. **Given** a soft phase 2 with unchecked checklist items, **When** the plan and design review gate would otherwise be soft, **Then** it is hard and asks whether to proceed, answered before tasks are generated.
5. **Given** the user answers the summary-carrying gate, **When** its Log line is written, **Then** it records what became of the spec assumptions and the checklist answer.
6. **Given** a large feature whose planner amended the plan after the phase 3 gate, **When** the phase 4 gate opens, **Then** it says so under "What you should know".

---

### User Story 4 - A clean spec and a clean design review pass through together (Priority: P2)

When phase 2 was soft and the plan and design review gate would be soft too (no finding needs the user, no unchecked checklist item), the soft gate's report carries the spec summary, the assumptions are accepted at their recommendations and logged, and the run continues.

**Why this priority**: It completes the saving for the best case, but the feature delivers value without it.

**Independent Test**: Run a small feature whose spec has no markers or unchecked items and whose reviewers raise nothing needing the user. The soft report contains the summary, the Log shows the assumptions as accepted, and the run moves on to tasks.

**Acceptance Scenarios**:

1. **Given** a soft phase 2 and a soft design gate, **When** the design gate reports, **Then** the report contains the spec summary and the run continues without stopping.
2. **Given** the same case, **When** the run continues, **Then** the Log records the assumptions as accepted at their recommendations.

---

### User Story 5 - Spec changes asked at the design gate reach the planner (Priority: P2)

When the user, at the plan and design review gate, overturns an assumption or rewords a requirement, the change goes to the planner in amend mode together with the accepted findings, in the same pass. The planner writes it into the spec and the plan. On large features, a spec change asked at the phase 3 gate goes to the planner in amend mode right away, and the design reviewers then read the updated spec and plan. A change big enough to rewrite stories is handled by the existing "back to 2".

**Why this priority**: Without it, moving the summary to the design gate would leave the user unable to act on what they see there.

**Independent Test**: At the design gate of a small feature, reject one assumption. The planner is spawned in amend mode with that change and the accepted findings, and the spec file and plan both reflect the change afterwards. Repeat at the phase 3 gate on a large feature and check the change lands before the design reviewers run.

**Acceptance Scenarios**:

1. **Given** a spec change asked at the plan and design review gate, **When** the user accepts findings too, **Then** one planner amend pass receives both, and spec and plan carry the change.
2. **Given** a large feature and a spec change asked at the phase 3 gate, **When** the user answers, **Then** the planner amends right away, before the design reviewers read the spec and plan.
3. **Given** a change that rewrites stories, **When** the user asks for it at any gate, **Then** the existing "back to 2" applies.

---

### User Story 6 - Resuming keeps the summary (Priority: P2)

After a soft phase 2, if the session is interrupted and the user runs `/feat resume`, the next gate still shows the spec summary, because it is read from the state file.

**Why this priority**: Without it, a resume would silently lose the spec summary the user has not yet seen.

**Independent Test**: Do a soft phase 2, stop the session, resume, and reach the next gate: the summary, assumptions and checklist question appear, taken from the state file.

**Acceptance Scenarios**:

1. **Given** a state file recording a soft phase 2, **When** `/feat resume` reaches the next gate, **Then** the gate shows the spec summary, assumptions and checklist question from the state file.

---

### User Story 7 - The documentation tells the same story (Priority: P2)

A reader of the skill, the workflow doc, the usage doc, the design doc and the README finds the same description of when phase 2 stops and what the next gate shows.

**Why this priority**: These documents mirror each other by project convention, and a drifted description misleads users about when they will be asked.

**Independent Test**: Read each listed document and check it states: phase 2 is hard only with open markers or a blocker (or anything surprising, as at any soft gate); otherwise soft; the next gate opens with the summary; unchecked checklist items make the design gate hard.

**Acceptance Scenarios**:

1. **Given** the change is done, **When** the phases-and-gates table and sections 2 to 4 of the `/feat` skill, `docs/workflow.md` (phases at a glance, the "Hard gates" row, phase details), `docs/usage.md`, the `speckit-implement` row of `docs/design.md` and the README's sentence on gates are read, **Then** they say the same thing.
2. **Given** the change is done, **When** `mise run lint` and `mise run test:apm` run, **Then** both pass.

---

### Edge Cases

- A soft phase 2 with unchecked checklist items: the design gate becomes hard, which includes small and medium features whose design gate would otherwise be soft.
- The user answers "ok" at the summary-carrying gate: all assumptions are accepted at their recommendations.
- A spec change and findings at the same gate: one planner amend pass, not two.
- A spec change at the phase 3 gate of a large feature after the planner has already run: the planner amends, and the design reviewers (spawned afterwards) read the updated files.
- A specifier remark about size on a spec that otherwise has no markers: it is surprising, so the gate is hard; phase 2 has no size trigger of its own, and a size increase is detected at phase 3 or 5.
- Resume after a hard phase 2: no summary is shown, as the user already saw the spec.
- The Log has no record of whether phase 2 was soft or hard (state file from an older run): the next gate behaves as today, without the summary.
- Several phase 2 lines in the Log ("back to 2", reruns): the latest decides; each rerun writes its own soft or hard line, so a hard rerun after a soft one shows no summary, and a soft rerun shows its own.
## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Phase 2 MUST be a hard gate only when the spec has open `[NEEDS CLARIFICATION]` markers or the specifier reports a blocker; otherwise it MUST be soft, except that anything surprising in the report (a remark about size included) makes it hard, as at any soft gate. The rule MUST be the same at every size, large included. Phase 2 has no size trigger: size increases are caught at phase 3 (the planner's size trigger) and phase 5 (the task count), and the specifier's report format stays unchanged.
- **FR-002**: A soft phase 2 MUST print a one-line report and continue to the plan without waiting for the user.
- **FR-003**: A soft phase 2 MUST write into the state file Log that the gate was soft, the spec summary (stories and requirements in a few lines), the specifier's assumptions with their recommendations, and the unchecked checklist items.
- **FR-004**: A hard phase 2 MUST behave as today: questions with recommended answers, answers and edits sent to the specifier in amend mode, and the Log records that phase 2 was hard.
- **FR-005**: After a soft phase 2, the next gate MUST open with the spec summary: stories and requirements in a few lines, the assumptions with their recommendations, and the unchecked checklist items with the question whether to proceed. That gate is the plan and design review gate on small and medium, and the phase 3 plan gate on large.
- **FR-006**: After a hard phase 2, the next gate MUST be as it is today.
- **FR-007**: The specifier's assumptions and the checklist question MUST be answered at the gate that shows the summary, and "ok" MUST accept the recommendations.
- **FR-008**: After a soft phase 2, unchecked checklist items MUST make the plan and design review gate hard, as a question answered before tasks are generated.
- **FR-009**: When phase 2 was soft and the plan and design review gate would be soft (no finding needs the user, no unchecked checklist item), the soft report MUST contain the spec summary, the assumptions MUST be logged as accepted at their recommendations, and the run MUST continue.
- **FR-010**: A spec change asked at the plan and design review gate (an assumption overturned, a requirement reworded) MUST go to the planner in amend mode in the same pass as the accepted findings, and the planner MUST write it into the spec and the plan.
- **FR-011**: On large features, a spec change asked at the phase 3 gate MUST go to the planner in amend mode right away, before the design reviewers run, so they read the updated spec and plan.
- **FR-012**: A change big enough to rewrite stories MUST continue to be handled by "back to 2" at any gate.
- **FR-013**: The state file MUST record whether phase 2 was soft or hard, and the next gate, including after `/feat resume`, MUST read that record and the summary from the state file.
- **FR-014**: The planner's amend-mode prompt MUST name spec changes alongside findings, and its report format MUST stay unchanged.
- **FR-015**: The coordinator MUST stay thin: the spec summary comes from the specifier's report, as today, and the coordinator MUST NOT read code or edit artifacts.
- **FR-016**: The shared rules in `.apm/skills/feat/references/harness.md` MUST stay free of `/feat`-only words and unchanged; its existing rule that anything surprising makes a soft gate hard covers the phase 2 cases beyond markers and blockers.
- **FR-017**: The phases-and-gates table and sections 2 to 4 of `.apm/skills/feat/SKILL.md`, `docs/workflow.md` (phases at a glance, the "Hard gates" row, phase details), `docs/usage.md`, the `speckit-implement` row of `docs/design.md`, and the README's sentence on gates MUST describe the same behavior.
- **FR-018**: `mise run lint` and `mise run test:apm` MUST pass.
- **FR-019**: The coordinator MUST treat the specifier's report as a blocker when it has no `Spec:` path, or its Assumptions or Open markers say the brief can't be specified as written. Anything else surprising MUST make the gate hard by the existing soft-gate rule.
- **FR-020**: When the Log has several phase 2 lines ("back to 2", reruns), the latest MUST decide; every phase 2 run, reruns included, MUST write its own soft or hard phase 2 line. The summary-carrying gate MUST count as open while no `[x]` line for that gate (the phase 4 line, covering 3–4, on small and medium; the phase 3 line on large) follows the latest phase 2 line.
- **FR-021**: The summary-carrying gate's Log line MUST record what became of the spec assumptions and the checklist answer, whether the gate was hard or soft.
- **FR-022**: On large features, when the planner amended the plan after the phase 3 gate, the phase 4 gate MUST say so under "What you should know".

### Out of Scope

- `/fix`, which has no spec gate.
- Changing when the plan and design review gate is hard (apart from the unchecked-checklist rule above, which the brief requires).
- The workflow diagrams in the README and docs, updated separately after this ships.

### Key Entities

- **Phase 2 gate mode**: soft or hard, decided by open markers, a blocker or anything surprising in the specifier's report, and recorded in the state file Log; the latest phase 2 line decides.
- **Spec summary block**: stories and requirements in a few lines, assumptions with recommendations, unchecked checklist items with the proceed question; stored in the state file and shown at the next gate.
- **Amend pass**: one planner run in amend mode that applies the user's spec changes and the accepted findings together.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: For a spec with no open markers and no blocker, the number of user stops between the end of the specification and the end of the design review drops from two to at most one (the design gate), and to zero when the design gate is soft too.
- **SC-002**: For a spec with open markers or a blocker, the user is stopped at phase 2 in 100% of cases.
- **SC-003**: In 100% of soft-phase-2 runs, the user sees the spec summary, the assumptions and the checklist question at the next gate (or in the soft report), including after a resume.
- **SC-004**: Every spec change the user asks for at the design gate is present in spec.md and plan.md after a single amend pass, with no extra specifier spawn.
- **SC-005**: The six listed documents state identical gate behavior, and the lint and offline test checks pass.

## Assumptions

- The specifier's report already carries the stories, requirements, assumptions and checklist items the summary is built from, so no change to its report format is needed.
- Phase 2 has no source for a size increase: the skill's *size triggers* are the planner's trigger and the phase 5 task count, and the specifier's report has no size field (and gets none). A specifier remark about size counts as "anything surprising", which the shared harness rule already makes hard; that rule needs no change.
- "Unchecked checklist items" means items left unchecked in the spec-quality checklist the specifier reports.
- State files written before this change carry no soft/hard record; those runs fall back to today's behavior at the next gate.
- Alternatives rejected by the brief stay rejected: never stopping at phase 2 even with open markers, keeping the gate hard on large, making the design gate always hard after a soft phase 2, and routing design-gate spec changes through the specifier.
