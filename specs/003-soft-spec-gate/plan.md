# Implementation Plan: Soft spec gate, with the spec summary at the design gate

**Branch**: `soft-spec-gate` | **Date**: 2026-11-16 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `specs/003-soft-spec-gate/spec.md` (brief in [feat-state.md](feat-state.md))

## Summary

Phase 2 of `/feat` stops only when the spec has an open
`[NEEDS CLARIFICATION]` marker or the specifier reports a blocker (and, by
the harness's soft-gate rule, on anything surprising in its report);
otherwise it reports in one line, writes the spec summary
(stories, requirements, the specifier's assumptions, unchecked checklist
items) under a `soft` phase 2 Log line, and goes on. Phase 2 has no size
rule: size increases are caught at phase 3 and phase 5, as today. The next
gate (plan and design review on small and medium, phase 3 on large) opens
with that summary, read from the latest phase 2 Log line so resume keeps
it; an unchecked item makes the small/medium gate hard; spec changes asked
there go to `feat-planner`'s amend pass with the accepted findings. All of it is text in
`.apm/skills/feat/SKILL.md`, one clause in the planner prompt, and the
mirrored docs. No report format, harness rule, size table or agent changes
otherwise.

## Technical Context

**Language/Version**: Markdown prompts (skill, agent) and Markdown docs.

**Primary Dependencies**: none new.

**Storage**: the state file's `## Log` (`specs/<short-name>/feat-state.md`): a `soft`/`hard` word on the phase 2 line and, when soft, four indented summary lines ([data-model.md](data-model.md)).

**Testing**: `mise run lint` (includes the harness grep and `claude plugin validate .`), `mise run test:apm`, and the read/grep checks of [quickstart.md](quickstart.md); live runs optional.

**Target Platform**: Claude Code sessions, installed by APM, the plugin or `install.sh`.

**Project Type**: Claude Code skills/agents package.

**Performance Goals**: fewer stops and spawns, not speed: one user stop fewer per run with a clean spec (SC-001), no extra spawn for spec changes at the design gate (SC-004). The coordinator's context grows by the four summary lines in the Log.

**Constraints**: coordinator stays thin (FR-015); `references/harness.md` unchanged (FR-016); specifier and planner report formats unchanged (FR-014); planner prompt gets at most one phrase; diagrams out of scope.

**Scale/Scope**: 6 files, ~12 tasks (small).

## Constitution Check

*Constitution: `.specify/memory/constitution.md` v1.1.0.*

| Principle | Status |
| --- | --- |
| I. Thin coordinators | pass: the summary is copied from the specifier's report into the state file, the only file the coordinator edits; it never opens spec.md for it. Spec changes go to an agent (the planner). |
| II. The user decides at gates | pass: phase 2 stops whenever a decision is open (marker, blocker, anything surprising); size increases still stop the run at phases 3 and 5; the specifier's assumptions and the checklist question move to a gate that stops, or, when nothing else needs the user, are reported in the soft report and logged, as the brief decided (its third "Alternatives rejected"). Unchecked checklist items still force a hard gate before tasks. |
| III. One source of truth per fact | pass: size tables untouched; the gate change is mirrored in `docs/workflow.md` (table, "Hard gates" row, phase details) in the same commit as the skill. Shared harness untouched. |
| IV. Fixed report formats | pass: no report format changes; the planner's amend input gains spec changes, its report block is unchanged. |
| V. Small and plain | pass: rules added to existing paragraphs; no new file, script or agent. |

Post-design re-check: pass, no violations.

## Project Structure

### Documentation (this feature)

```text
specs/003-soft-spec-gate/
├── plan.md               # this file
├── research.md           # decisions R1–R8
├── data-model.md         # gate mode, Log lines, summary-carrying gate, transitions
├── quickstart.md         # offline checks Q1–Q7, live scenarios L1–L6
├── contracts/gates.md    # soft report, spec block, amend message, the shared wording
└── tasks.md              # phase 5
```

### Source Code (repository root)

```text
.apm/skills/feat/SKILL.md          # Harness values (artifact owners); phases-and-gates rows 2–4; sections 2, 3, 4, 5
.apm/agents/feat-planner.agent.md  # amend mode: one clause
docs/workflow.md                   # phases at a glance rows 2–4; "Hard gates" row; phase details 2–5
docs/usage.md                      # "Answering a gate"
docs/design.md                     # `speckit-implement` row
README.md                          # "You decide at a few gates" sentence
```

Not touched: `references/harness.md`, `feat-specifier.agent.md`, size
tables, `/fix`, `/brief`, CHANGELOG.md, versions, diagrams.

**Structure Decision**: edits in place; nothing to install or ship
differently.

## Design

The shared wording every file must agree with is in
[contracts/gates.md](contracts/gates.md) ("Wording to carry"). Suggested
text below; the implementer may tighten it but not change its meaning.

### `.apm/skills/feat/SKILL.md`

**Harness values, *Artifact owners*** (so the harness's "changes go back to
the owner" still holds, research R6): `planner: plan.md, accepted design
findings, and spec changes asked at the plan or the design review gate`.

**Phases and gates table**:

- Row 2 gate: `**hard** only on open [NEEDS CLARIFICATION] markers or a specifier blocker; else soft, and the spec summary opens the next gate`.
- Row 3 gate: `none for small and medium (merged with 4); **hard** for large, opening with the spec summary after a soft phase 2`.
- Row 4 gate: add `an unchecked checklist item after a soft phase 2` to the small/medium hard list.
- Row 5: unchanged.

**Section 2**, replacing the "**Hard gate**" paragraph (FR-001–FR-004,
FR-013, FR-019, FR-020):

- Gate rule: hard only when the report has open markers or a blocker; at
  every size. Otherwise soft, and the harness's "anything surprising" makes
  it hard (no need to restate it; at most "anything else surprising makes it
  hard, as at any soft gate"). No size increase in this rule: phase 2 has
  no size trigger (research R3).
- Blocker test, as written: "the report has no `Spec:` path, or its
  Assumptions or Open markers say the brief can't be specified as written".
- Hard: today's text (summary, markers with recommended answers,
  assumptions, checklist question; answers and edits to the specifier in
  amend mode; a spec with open markers isn't approvable). Log
  `2 Specify — hard (<why>)`.
- Soft: one line (contracts/gates.md), then phase 3. Log `2 Specify — soft`
  with the four summary lines (data-model.md), from the report.
- Every phase 2 run, "back to 2" and reruns included, writes its own soft
  or hard line; the latest phase 2 line decides. The summary-carrying gate
  is open while no `[x]` line for it (phase 4 on small and medium, phase 3
  on large) follows that line. A phase 2 line with neither word counts as
  hard.
- After a soft phase 2 the next gate (3+4 on small and medium, 3 on large)
  opens with the summary from the Log, so `/feat resume` shows it too; the
  spec assumptions (recommended: keep as written) and the checklist question
  are answered there; "ok" accepts the recommendations.
- "This is the only place questions are asked" becomes: questions are asked
  at phase 2 or at the gate that shows its summary, so later phases don't
  stop to ask.

**Section 3, large** (FR-005, FR-011, FR-021): the hard gate opens with the
spec summary after a soft phase 2, and carries the data-model sentence
verbatim: "The gate's Log line records what became of the spec assumptions
and the checklist answer." A spec change asked there goes to
`feat-planner` in amend mode right away; phase 4's reviewers are spawned
after it reports, on the updated spec and plan. No second stop for the
amend.

**Section 4** (FR-005, FR-007–FR-010, FR-012, FR-021, FR-022):

- Large: when the planner amended the plan after the phase 3 gate, the
  phase 4 gate says so under "What you should know" (what the amend
  changed, one line).
- The same data-model sentence, verbatim, for the small/medium gate
  carrying the summary, hard or soft.

- Small/medium gate contents: the spec summary first (after a soft phase
  2), then the paraphrase, approach, what it touches, assumptions, any size
  increase (first of the rest), findings.
- Hard list gains: an unchecked checklist item carried from a soft phase 2.
- When phase 2 was soft and this gate is soft: the soft report carries the
  spec summary, the spec assumptions are logged as kept at their
  recommendations.
- "Accepted findings go to `feat-planner` in amend mode" becomes: accepted
  findings and the spec changes asked at this gate (an overturned
  assumption, a reworded requirement) go to `feat-planner` in one amend
  pass, written into spec.md and plan.md; a change that rewrites stories is
  "back to 2".

**Section 5**: "unchecked checklist items the phase 2 answer doesn't cover"
→ "… the checklist answer already given (phase 2 or the spec summary)
doesn't cover".

### `.apm/agents/feat-planner.agent.md`

One clause after "apply edits as given;", ending that sentence, copied
exactly from contracts/gates.md (FR-014, research R7). The amend-mode
header, frontmatter, steps 1–4 and the report block unchanged.

### `docs/workflow.md`

- Phases at a glance: row 2 gate `hard only on an open question or a
  blocker; else soft, and its summary opens the next gate`; row 3 `none
  (hard for large, opening with the spec summary after a soft phase 2)`;
  row 4 adds "an unchecked checklist item after a soft phase 2" to its
  hard list.
- Under the phases table (next to the hard/soft gate legend), one line:
  "After a soft phase 2, the first stop is the 3/4 gate (phase 3 on
  large), which opens with the spec summary."
- "Hard gates" row: small `brief, 7 (+2 on an open question, +3/4 on a real
  finding or an unchecked checklist item, +5 on CRITICAL/HIGH)`; medium
  `brief, 7 (+2, +3/4 and +5 as for small)`; large `brief, 3, 4, 5, each
  story in 6, 7 (+2 on an open question)`.
- Phase details 2: the gate rule (markers or a blocker; no size rule),
  soft one-liner, summary in the state file, the latest phase 2 line
  decides, "the only place questions are asked" replaced as in the skill
  (the phrase wraps at lines 158–159 today: replace the whole sentence). 3:
  large's gate opens with the summary; spec changes there go to the planner
  before phase 4. 4: summary first, the checklist rule, the soft case, spec
  changes in the planner's amend pass; on large, the phase 4 gate notes a
  plan amended after phase 3. 5: "your phase 2 answer" → "the
  checklist answer you already gave".

### `docs/usage.md`

In "Answering a gate", after "On small and medium features, plan and design
review share one gate…": when the spec leaves no question open, phase 2
doesn't stop; the next gate (phase 3 on large) opens with the spec, the
specifier's assumptions and the checklist question, "ok" accepts those
too, and a spec change you ask there is written by the planner with the
findings; "back to 2" for a rewrite.

### `docs/design.md`

`speckit-implement` row: "the orchestrator asks with the spec summary (at
the phase 2 gate, or at the next gate when phase 2 didn't stop), again at
phase 5 for items that answer doesn't cover, and passes the answer".

### `README.md`

"You decide at a few gates (the brief, the spec, which review findings to
fix)" → "(the brief, the spec when it leaves a question open, which review
findings to fix)". Research R8.

## Order

1. SKILL.md (source of truth) and the planner clause.
2. docs/workflow.md, then usage.md, design.md, README.md, against
   contracts/gates.md.
3. Quickstart Q1–Q7 (with Q4b, Q6b).

## Complexity Tracking

None.
