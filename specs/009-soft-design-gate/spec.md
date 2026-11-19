# Feature Specification: Design review stops only on findings that need the user

**Feature Branch**: `soft-design-gate`

**Created**: 2026-11-19

**Status**: Draft

**Input**: User description: "Brief specs/briefs/soft-design-gate.md (issue #20): on small and medium features the 'Plan and design review' gate of /feat (phases 3+4) stops on any finding above nice-to-have, and the user nearly always approves the recommendations. Make the gate stop only for findings that need the user, the way the phase 7 code review gate already does."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Plain design findings are applied without a stop (Priority: P1)

The person running a small or medium `/feat` no longer waits at the "Plan and design review" gate when every design finding is a plain "apply" or "skip" call. Each design finding carries the reviewer's own recommendation; the run applies the `apply` ones, leaves the `skip` ones, and goes on.

**Why this priority**: This is the point of the feature. 95% of recent design findings were accepted as recommended and 12 of the 17 recent stops on medium features were plain approvals. Each stop costs a read and a reply, the run waits, and a user asked to approve often approves without reading. It is part of epic #31 (cut the cost and time of runs).

**Independent Test**: Run phase 4 of a small feature whose design review yields only `apply` and `skip` findings and none of the hard triggers: the `apply` findings are written into the plan and spec, the `skip` ones are left, and phase 5 starts without a stop.

**Acceptance Scenarios**:

1. **Given** a small or medium feature whose design findings are all `apply` or `skip` and no hard trigger holds, **When** phase 4 ends, **Then** the gate is soft, the `apply` findings are written by the planner (continued with `SendMessage`), the `skip` findings are left, and the 4c paraphrase is printed followed by one line, e.g. `Phase 4 Design review — soft: 5 findings, 4 applied, 1 skipped; security: D2; none needs your call. Next: phase 5 Tasks`.
2. **Given** that soft gate, **When** the line is printed, **Then** it names the counts, every `[sec]` finding applied and, only when there are any, every `[sec]` finding skipped, e.g. `Phase 4 Design review — soft: 5 findings, 4 applied, 1 skipped; security: D2; security skipped: D5; none needs your call. Next: phase 5 Tasks`; a high-severity finding marked `apply` or `skip` is applied or left like any other and is not named.
3. **Given** a soft phase 2 followed by this soft gate, **When** the line is printed, **Then** the report still carries the spec summary, as today.
4. **Given** a nice-to-have finding, **When** the reviewer reports it, **Then** it carries a rec like any other finding and follows it.
5. **Given** a soft gate with no `apply` finding, **When** phase 4 ends, **Then** the planner is not continued (no `SendMessage`) and the run goes straight to phase 5.

---

### User Story 2 - Judgement calls and risky cases still stop (Priority: P1)

The person is still asked whenever a decision is theirs: a finding the reviewer marks `rec: user`, a planner assumption with `needs user: yes`, a constitution violation, a blocker, a size increase, a 4c paraphrase that contradicts the brief, an unchecked checklist item carried from a soft phase 2, or a failed report check.

**Why this priority**: Removing the stop is only safe if the stops that matter remain.

**Independent Test**: For each trigger, give phase 4 a report containing it and check that the gate is hard, lists the `user` findings first, then the others with their rec, and that "ok" settles only the `apply` and `skip` findings.

**Acceptance Scenarios**:

1. **Given** a small or medium feature with a `D` finding with `rec: user`, **When** phase 4 ends, **Then** the gate is hard; it lists each `user` finding first ("apply or leave?" with the reviewer's why), then the others with their rec.
2. **Given** that hard gate, **When** the user answers "ok" and answers each `user` finding, **Then** every `apply` finding is applied, every `skip` finding is left, and each `user` finding follows its answer.
3. **Given** that hard gate, **When** the user answers a bare "ok" while a `user` finding is unanswered, **Then** one follow-up names the unanswered ids, as phase 7's rule does.
4. **Given** each of the other triggers (assumption with `needs user: yes`, constitution violation, blocker, size increase, contradicting 4c paraphrase, unchecked carried checklist item, failed report check), **When** phase 4 ends, **Then** the gate is hard.
5. **Given** a finding that removes or changes a story, a requirement or an acceptance criterion the brief asked for, overturns a spec assumption, or weakens a control the spec or plan sets (relaxes validation, widens access), **When** the reviewer reports it, **Then** its rec is `user`; a finding that only adds a tightening requirement (input validation, error handling, a secure default) may be `apply`.
6. **Given** a hard gate, **When** it is shown, **Then** it no longer has any trigger on "a finding above nice-to-have".

---

### User Story 3 - /feat merges design findings without recommending itself (Priority: P2)

`/feat` never sets `apply` or `skip` on a design finding. It merges the reviewers' findings into `D1…` by fixed rules, as it does at phase 7.

**Why this priority**: Two sources of recommendations in one phase is what the brief rejects; the merge rules keep conflicts and gaps visible as `user`.

**Independent Test**: Feed phase 4 findings with the same spot and the same rec and fix, the same spot with different recs, and a missing rec; check the merged results.

**Acceptance Scenarios**:

1. **Given** the same spot (same artifact and identical section heading or line) and the same tag, reported with the same rec and fix, **When** merged, **Then** it is kept once.
2. **Given** the same spot and the same tag from different reviewers or lenses with a different rec or fix, **When** merged, **Then** it becomes `user (reviewers disagree)`; "same section" means the same tag (`[sec]`, `[cost]`, `[design]`).
3. **Given** a finding with a missing or invalid rec, **When** merged, **Then** it becomes `user (no valid recommendation)`.
4. **Given** design findings, **When** merged, **Then** the cut-code and high-confidence-bug rules (harness rules 1 and 4) are not applied.
5. **Given** findings with different tags on the same spot, **When** merged, **Then** they are kept separate, each with its own rec.

---

### User Story 4 - Large features keep a hard gate with phase 7's rule (Priority: P2)

On a large feature the gate is always hard: every finding is shown with its rec, `user` ones first, and the same "ok" rule applies.

**Why this priority**: Large keeps its stop, but the recommendations come from the reviewer, not from `/feat`.

**Independent Test**: Run phase 4 of a large feature with only `apply` findings: the gate stops and lists them all with their rec.

**Acceptance Scenarios**:

1. **Given** a large feature, **When** phase 4 ends, **Then** the gate is hard whatever the findings, listing `user` findings first and the rest with their rec.
2. **Given** that gate, **When** the user answers a bare "ok" with a `user` finding unanswered, **Then** one follow-up names the ids.

---

### User Story 5 - The Log and the docs say what happened (Priority: P2)

The Log's phase 4 line records the outcome, and the docs and diagrams describe the same gate.

**Why this priority**: The reviewer's rec is trusted, so the Log is where every finding stays visible; stale docs would contradict the behaviour.

**Independent Test**: Read the Log line after a soft and a hard gate, and the docs, diagram sources and renders.

**Acceptance Scenarios**:

1. **Given** a soft gate, **When** the Log line is written, **Then** it reads `auto-applied <ids | none>; skipped <id> (reviewer: "<why>")`, with one indented line per finding giving its id, spot, a few words and its rec.
2. **Given** a hard gate, **When** the Log line is written, **Then** it reads `picked <ids>` / `rejected <id> (user: "<words>" | as recommended)`, with the same indented lines.
3. **Given** skipped or rejected design findings, **When** later reviewers are spawned, **Then** those findings reach them as rejected findings, as today.
4. **Given** the docs, **When** read, **Then** the phase table row and the Design review section of `docs/workflow.md`, `docs/diagrams/gates.d2` and the README chain alt text no longer say the gate stops to "decide on the findings" unconditionally, and `docs/img/` is re-rendered.

### Edge Cases

- A high-severity finding with `rec: apply` or `skip`: applied or left, not named in the soft line.
- An `apply` `[sec]` finding on a soft gate: applied and named in the soft line, no stop.
- A `skip` `[sec]` finding on a soft gate: left and named in the soft line after `security skipped:`, no stop.
- A soft gate with no `apply` finding: no `SendMessage` to the planner; straight to phase 5.
- A phase 4 run resumed from before the change, where findings have no rec: each becomes `user (no valid recommendation)` and the gate is hard.
- The 4c paraphrase carries no rec and is unchanged.
- All findings `skip` or none at all: the soft line says so with zero applied.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The design reviewer MUST end every finding, nice-to-have included, with `rec: apply | skip (<why>) | user (<why>)`, keeping the severity on the line; the 4c paraphrase carries no rec and is unchanged.
- **FR-002**: The design reviewer MUST mark `rec: user` any finding that removes or changes a story, a requirement or an acceptance criterion the brief asked for, overturns a spec assumption, or weakens a control the spec or plan sets (relaxes validation, widens access); a finding that only adds a tightening requirement MAY be `apply`.
- **FR-003**: `/feat` MUST NOT set `apply` or `skip` on a design finding or write its own recommendation on one.
- **FR-004**: `/feat` MUST merge design findings into `D1…` with the harness's merge rules 2, 3 and 5, referred to and not restated, with "same spot" defined in `/feat`'s section 4 as the same artifact and an identical section heading or line, and "same section" meaning the same tag; findings with different tags on the same spot MUST be kept separate, each with its own rec; rules 1 and 4 MUST NOT apply.
- **FR-005**: On small and medium features the gate MUST be hard when any of these holds, and soft otherwise: a `D` finding with `rec: user`; a planner assumption with `needs user: yes`; a constitution violation; a blocker; a size increase; a 4c paraphrase contradicting the brief; an unchecked checklist item carried from a soft phase 2; a failed report check.
- **FR-006**: A soft gate MUST apply the `apply` findings unasked through the planner continued with `SendMessage`, leave the `skip` findings, and print the 4c paraphrase followed by one line with the counts, every `[sec]` finding applied (`; security: <ids>`) and, only when there are any, every `[sec]` finding skipped (`; security skipped: <ids>`). With no `apply` finding, it MUST NOT continue the planner and goes straight to phase 5.
- **FR-007**: A soft gate after a soft phase 2 MUST still carry the spec summary.
- **FR-008**: A hard small or medium gate MUST list `user` findings first with the reviewer's why, then the others with their rec; "ok" applies every `apply` and leaves every `skip`; each `user` finding needs its own answer, and a bare "ok" with one unanswered gets one follow-up naming the ids. A hard gate keeps a fresh planner spawn.
- **FR-009**: On large features the gate MUST always be hard, with every finding shown with its rec, `user` first, and the same "ok" rule.
- **FR-010**: The Log's phase 4 line MUST record the soft or hard outcome as in User Story 5, one indented line per finding with id, spot, a few words and rec; skipped and rejected findings reach later reviewers as rejected findings.
- **FR-011**: No trigger on "a finding above nice-to-have" MUST remain in `/feat`'s phase table row 4 or section 4, and none of the old design-gate wording ("real finding", an unconditional "decide on the findings") MUST remain in `docs/workflow.md`, `README.md` or `docs/usage.md`, as checked by SC-004.
- **FR-012**: The design rules MUST be written in `/feat`'s section 4, referring to the harness; `harness.md`, phase 7, `/fix`, the other gates, the size table, models, efforts and reviewer lens content MUST NOT change.
- **FR-013**: `/feat` MUST NOT read the spec or plan itself for this change; it works from the reviewer's report.
- **FR-014**: `docs/workflow.md` (phase table row, Design review section), `docs/diagrams/gates.d2`, `docs/diagrams/chain.d2` as needed and the README chain alt text MUST say the same as `/feat`; `docs/img/` MUST be re-rendered so the `check` workflow passes.
- **FR-015**: `mise run lint` and `mise run test:apm` MUST pass.

### Key Entities

- **Design finding (`D`)**: an item from the design reviewer with a tag (`[sec]`, `[cost]`, `[design]`), a severity, a spot, a suggested fix and a rec.
- **Rec**: `apply`, `skip (<why>)` or `user (<why>)`, set only by the reviewer, or `user (...)` by the merge rules.
- **Gate**: soft (applied unasked, one line) or hard (the user answers).

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A small or medium run whose design findings are all `apply` or `skip` and with no other trigger reaches phase 5 with zero user stops at the design gate.
- **SC-002**: Every hard-trigger case listed in FR-005 produces a hard gate in 100% of checked cases.
- **SC-003**: Every design finding in a report ends with a valid rec, and no phase 4 text states a recommendation written by `/feat`.
- **SC-004**: Each of these searches, run from the repository root, finds no match: `grep -n 'above nice-to-have' .apm/skills/feat/SKILL.md`; `grep -n 'real finding\|finding above' docs/workflow.md README.md docs/usage.md`; `grep -n 'decide on the findings\|decide on findings,' docs/workflow.md README.md docs/usage.md docs/diagrams/gates.d2`; `grep -n 'decide on findings {' docs/diagrams/chain.d2`. (A bare `decide on` still matches phase 7's "decide on findings that need you" and `/fix`'s roles, which stay.)
- **SC-005**: Lint, the apm test and the `check` workflow pass.

## Assumptions

- The report format change is made in `feat-design-reviewer` and read by phase 4 together, as the repo requires.
- "Blocker" and "size increase" keep their present meaning in phase 4.
- A high-severity finding is trusted to the reviewer's rec; the Log is the record.
- `models.svg` is unaffected since the size table does not change.
- Decided at the phase 4 gate: the soft gate still prints the 4c paraphrase before its one line (FR-006), so the user can check it against what they meant.
- The `feat` commit subject is written for users, since it becomes a CHANGELOG entry.
