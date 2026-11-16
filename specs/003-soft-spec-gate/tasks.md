# Tasks: Soft spec gate, with the spec summary at the design gate

**Input**: Design documents from `specs/003-soft-spec-gate/` (spec.md, plan.md, research.md, data-model.md, contracts/gates.md, quickstart.md)

**Prerequisites**: plan.md, spec.md

**Tests**: No test tasks: the feature is prompt and doc text. Verification is `mise run lint`, `mise run test:apm` and the quickstart's Q checks (final phase).

**Organization**: Grouped by user story. Paths are relative to the worktree root. The wording every file must agree with is "Wording to carry" in `specs/003-soft-spec-gate/contracts/gates.md`; `.apm/skills/feat/SKILL.md` is edited first and is the source of truth. Hard rules: `.apm/skills/feat/references/harness.md`, `.apm/agents/feat-specifier.agent.md`, the size tables, `/fix`, `/brief`, CHANGELOG.md, version lines and the README/docs diagrams stay untouched; never name the user's private project anywhere.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: can run in parallel (different files, no dependency on an incomplete task)
- Edits to `.apm/skills/feat/SKILL.md` are sequential (same file), so none of them carries [P].

---

## Phase 1: Setup

- [X] T001 Run `mise run lint` and `mise run test:apm` from the worktree root to record a green baseline before any edit; read `.apm/skills/feat/SKILL.md` (phases-and-gates table, sections 2 to 5, Harness values) and `contracts/gates.md` once so later tasks quote them exactly.

## Phase 2: Foundational

None. Every story edits existing paragraphs; no shared prerequisite blocks them beyond T001.

---

## Phase 3: User Story 1 - A clean spec does not stop the run (Priority: P1) MVP

**Goal**: Phase 2 is soft when the spec has no open marker and no blocker: one report line, Log records the summary, run goes to phase 3.

**Independent Test**: Read `.apm/skills/feat/SKILL.md` row 2 and section 2: a report with no marker and no blocker yields the one-line report of contracts/gates.md, a `2 Specify — soft` Log line with the four summary lines of data-model.md, and continues to phase 3 at every size (FR-001 to FR-003, spec US1).

- [X] T002 [US1] In `.apm/skills/feat/SKILL.md` phases-and-gates table, rewrite the row 2 gate cell to: `**hard** only on open [NEEDS CLARIFICATION] markers or a specifier blocker; else soft, and the spec summary opens the next gate`. Name no size increase (FR-001).
- [X] T003 [US1] In `.apm/skills/feat/SKILL.md` section 2, replace the "**Hard gate**" paragraph with the gate rule and the soft path: hard only on open markers or a blocker, the same at every size, large included, "anything else surprising makes it hard, as at any soft gate"; soft prints the one-line report of contracts/gates.md ("Phase 2 Specify — soft: spec.md written (<n> stories, <m> requirements, no open question); summary at the next gate. Next: phase 3 Plan") and writes the Log line `2 Specify — soft` followed by the four indented summary lines of data-model.md (Stories, Requirements, Spec assumptions with "(recommended: keep as written)", Unchecked checklist items), all copied from the specifier's report, never from spec.md (FR-001 to FR-003, FR-015). Replace "This is the only place questions are asked" (whole sentence; it wraps over two lines) with: questions are asked at phase 2 or at the gate that shows its summary, so later phases don't stop to ask.

**Checkpoint**: A clean spec no longer stops the run.

---

## Phase 4: User Story 2 - Open questions still stop at the spec (Priority: P1)

**Goal**: Open markers, a blocker or anything surprising keep phase 2 hard, as today.

**Independent Test**: Read section 2: the blocker test, the hard path text, the Log line `2 Specify — hard (<why>)`, and that a hard phase 2 leaves the next gate without a summary (FR-004, FR-006, FR-019, FR-020).

- [X] T004 [US2] In `.apm/skills/feat/SKILL.md` section 2, keep today's hard-gate text as the hard path (summary, each marker with a recommended answer, assumptions, checklist question; answers and edits to `feat-specifier` in amend mode; a spec with open markers isn't approvable) and add: the Log line `2 Specify — hard (<why>)`; the blocker test verbatim ("the report has no `Spec:` path, or its Assumptions or Open markers say the brief can't be specified as written"); a size remark in the report is "anything surprising" and makes the gate hard, phase 2 having no size trigger (size increases are caught at phase 3 and phase 5); every phase 2 run, "back to 2" and reruns included, writes its own soft or hard line and the latest phase 2 line decides; a phase 2 line with neither word counts as hard; after a hard phase 2 the next gate is as today, no summary (FR-004, FR-006, FR-019, FR-020).

**Checkpoint**: Open questions still stop at phase 2.

---

## Phase 5: User Story 3 - The next gate shows the spec summary (Priority: P1)

**Goal**: After a soft phase 2 the first following gate opens with the spec summary, assumptions and checklist question; unchecked items make the small/medium gate hard; "ok" accepts the recommendations; the gate's Log line records the outcome.

**Independent Test**: Read table rows 3 and 4 and sections 3, 4 and 5: small/medium gate content order, large phase 3 gate opening block, hard-list addition, verbatim Log sentence, phase 4 amended-plan note (FR-005, FR-007, FR-008, FR-021, FR-022).

- [X] T005 [US3] In `.apm/skills/feat/SKILL.md` phases-and-gates table, rewrite the row 3 gate cell to `none for small and medium (merged with 4); **hard** for large, opening with the spec summary after a soft phase 2`, and add `an unchecked checklist item after a soft phase 2` to the small/medium hard list in the row 4 gate cell. Leave row 5 unchanged.
- [X] T006 [US3] In `.apm/skills/feat/SKILL.md` section 3 (large): the hard phase 3 gate opens with the spec block (`**The spec (phase 2 didn't stop):** …`, assumptions numbered first with recommendations, checklist question) after a soft phase 2, before approach, what it touches, dependencies, constitution check and the planner's assumptions; "ok" accepts the recommendations; add verbatim "The gate's Log line records what became of the spec assumptions and the checklist answer." (FR-005, FR-007, FR-021).
- [X] T007 [US3] In `.apm/skills/feat/SKILL.md` section 4: small/medium gate contents become the spec summary first (after a soft phase 2), then paraphrase, approach, what it touches, assumptions, any size increase, findings; add an unchecked checklist item carried from a soft phase 2 to the hard list (a question answered before tasks are generated); add the same verbatim Log sentence as T006 for the gate carrying the summary, hard or soft; for large, add that when the planner amended the plan after the phase 3 gate, the phase 4 gate says so under "What you should know" (one line: what the amend changed) (FR-005, FR-007, FR-008, FR-021, FR-022).
- [X] T008 [US3] In `.apm/skills/feat/SKILL.md` section 5, change "unchecked checklist items the phase 2 answer doesn't cover" to "unchecked checklist items the checklist answer already given (phase 2 or the spec summary) doesn't cover"; do the same for any other "phase 2 answer" occurrence in the file (quickstart Q4).

**Checkpoint**: The summary reaches the user at a gate that stops.

---

## Phase 6: User Story 4 - A clean spec and a clean design review pass through together (Priority: P2)

**Goal**: Soft phase 2 plus soft design gate: the soft report carries the spec summary, assumptions logged as accepted, run continues.

**Independent Test**: Read the soft-gate paragraph of section 4 (FR-009).

- [X] T009 [US4] In `.apm/skills/feat/SKILL.md` section 4, in the soft-gate case add: when phase 2 was soft and this gate is soft (no finding above nice-to-have, no user-call assumption, no violation, no blocker, no size increase, no contradicting paraphrase, no unchecked checklist item), the soft report carries the `**The spec …**` line and the spec assumptions, and the Log line records them as kept at their recommendations (FR-009, FR-021).

**Checkpoint**: Best case needs no stop.

---

## Phase 7: User Story 5 - Spec changes asked at the design gate reach the planner (Priority: P2)

**Goal**: A spec change asked at the summary-carrying gate goes to `feat-planner` in amend mode, with the accepted findings in one pass; on large, right away before the design reviewers; story rewrites stay "back to 2".

**Independent Test**: Read Harness values, sections 3 and 4 and the planner prompt: artifact owner entry, one amend pass, large ordering, one clause in the planner prompt (FR-010 to FR-012, FR-014).

- [X] T010 [P] [US5] In `.apm/agents/feat-planner.agent.md` amend mode, append exactly this clause after "apply edits as given;", ending that sentence: "a spec change (an assumption overturned, a requirement reworded) goes into spec.md, and into plan.md where it changes the how." Leave the amend-mode header, frontmatter, steps 1 to 4 and the report block unchanged (FR-014).
- [X] T011 [US5] In `.apm/skills/feat/SKILL.md` Harness values, *Artifact owners*, set the planner entry to `plan.md, accepted design findings, and spec changes asked at the plan or the design review gate` so the harness rule "changes go back to the owner" still holds.
- [X] T012 [US5] In `.apm/skills/feat/SKILL.md` section 4, replace "Accepted findings go to `feat-planner` in amend mode" with: accepted findings and the spec changes asked at this gate (an overturned assumption, a reworded requirement) go to `feat-planner` in one amend pass, written into spec.md and plan.md, quoting each change (the user's answer, or the new wording); a change that rewrites stories is "back to 2" (FR-010, FR-012).
- [X] T013 [US5] In `.apm/skills/feat/SKILL.md` section 3 (large): a spec change asked at the phase 3 gate goes to `feat-planner` in amend mode right away; phase 4's reviewers are spawned after it reports, on the updated spec and plan; no second stop for the amend; a story rewrite is "back to 2" (FR-011, FR-012).

**Checkpoint**: The user can act on what the summary shows.

---

## Phase 8: User Story 6 - Resuming keeps the summary (Priority: P2)

**Goal**: `/feat resume` after a soft phase 2 shows the summary from the state file.

**Independent Test**: Read the resume rule in SKILL.md (FR-013, FR-020).

- [X] T014 [US6] In `.apm/skills/feat/SKILL.md` (section 2, and next to the *Resume search* / *Building move* resume lines near the top; SKILL.md has no separate resume section): state that the next gate reads the latest phase 2 line; when it says `soft` and no `[x]` line for the summary-carrying gate follows it (the phase 4 line covering 3-4 on small and medium, whose `[x] 3 Plan` progress line doesn't close it; the phase 3 line on large), that gate opens with the summary read from the Log, so `/feat resume` shows it; a state file with no soft or hard word behaves as today (FR-013, FR-020).

**Checkpoint**: The summary survives an interruption.

---

## Phase 9: User Story 7 - The documentation tells the same story (Priority: P2)

**Goal**: Workflow doc, usage doc, design doc and README carry the same four points as the skill.

**Independent Test**: Quickstart Q5: each document states the four points of contracts/gates.md "Wording to carry" and none contradicts them (FR-017, SC-005).

- [X] T015 [US7] In `docs/workflow.md` (after SKILL.md is done): phases-at-a-glance row 2 gate `hard only on an open question or a blocker; else soft, and its summary opens the next gate`, row 3 `none (hard for large, opening with the spec summary after a soft phase 2)`, row 4 adds "an unchecked checklist item after a soft phase 2" to its hard list; one line under the phases table next to the hard/soft legend: "After a soft phase 2, the first stop is the 3/4 gate (phase 3 on large), which opens with the spec summary."; the "Hard gates" row: small `brief, 7 (+2 on an open question, +3/4 on a real finding or an unchecked checklist item, +5 on CRITICAL/HIGH)`, medium `brief, 7 (+2, +3/4 and +5 as for small)`, large `brief, 3, 4, 5, each story in 6, 7 (+2 on an open question)`; phase details 2 to 5 as in plan.md section `docs/workflow.md` (gate rule with no size rule, soft one-liner, summary in the state file, latest phase 2 line decides, replace the whole "only place questions are asked" sentence that wraps over lines 158-159, large gate summary and pre-phase-4 planner amend, small/medium summary first, checklist rule, soft case, spec changes in the planner's amend pass, phase 4 note on a plan amended after phase 3, phase 5 "your phase 2 answer" becomes "the checklist answer you already gave"). Diagrams untouched.
- [X] T016 [P] [US7] In `docs/usage.md` "Answering a gate", after "On small and medium features, plan and design review share one gate…", add: when the spec leaves no question open, phase 2 doesn't stop; the next gate (phase 3 on large) opens with the spec, the specifier's assumptions and the checklist question; "ok" accepts those too; a spec change you ask there is written by the planner together with the findings; "back to 2" for a rewrite.
- [X] T017 [P] [US7] In `docs/design.md`, replace the `speckit-implement` row text with: the orchestrator asks with the spec summary (at the phase 2 gate, or at the next gate when phase 2 didn't stop), again at phase 5 for items that answer doesn't cover, and passes the answer; keep the row's other content and wording style.
- [X] T018 [P] [US7] In `README.md`, change "You decide at a few gates (the brief, the spec, which review findings to fix)" to "(the brief, the spec when it leaves a question open, which review findings to fix)"; touch nothing else, no version line.

**Checkpoint**: Six documents state identical behavior.

---

## Phase 10: Polish and verification

- [X] T019 Run the quickstart greps from the worktree root: Q3 `grep -Pzo 'only\s+place' .apm/skills/feat/SKILL.md docs/workflow.md` (expect no output, exit 1), Q4 `grep -Pzo 'phase\s+2\s+answer' .apm/skills/feat/SKILL.md docs/workflow.md` (expect no output, exit 1), Q4b `grep -n '^. 2 . Specify' .apm/skills/feat/SKILL.md docs/workflow.md` then read both rows; fix the files if any check fails.
- [X] T020 Read the SKILL.md table and sections 2 to 5, then docs/workflow.md, docs/usage.md, docs/design.md and README.md against the four points of contracts/gates.md (Q5, Q6b: no size increase as a phase 2 condition, blocker test, "the latest phase 2 line decides", the verbatim Log sentence in sections 3 and 4, large phase 4 amended-plan note); fix any drift.
- [X] T021 Run `mise run lint` and `mise run test:apm` (Q1, Q2); both must pass.
- [X] T022 Run `git diff --quiet -- .apm/skills/feat/references/harness.md`, `git diff --quiet -- .apm/agents/feat-specifier.agent.md` (Q1, Q6), `git diff .apm/agents/feat-planner.agent.md` (only the one clause) and `git diff --stat` (Q7: only the files in plan.md's Source Code list plus `specs/003-soft-spec-gate/`); confirm CHANGELOG.md, version lines and `.release-please-manifest.json` are unchanged and the user's private project is named nowhere.

---

## Dependencies and execution order

- T001 first. Then SKILL.md edits in order: T002, T003, T004, T005, T006, T007, T008, T009, T011, T012, T013, T014 (same file, sequential; T006, T007, T012 and T013 touch sections 3 and 4, so apply T012 and T013 after T006 and T007 to avoid conflicting paragraphs).
- T010 [P]: independent of SKILL.md (planner file); run any time after T001.
- Docs T015 to T018 after the SKILL.md tasks (the skill is the source of truth); T016, T017, T018 [P] with each other and with T015 (different files).
- Polish T019 to T022 after everything; T021 after T019/T020 fixes.
- Stories are mostly independent in content but share SKILL.md, so run them in priority order US1, US2, US3, US4, US5, US6, US7.

### Parallel example

```text
After T001:   T010 (planner file) alongside the SKILL.md sequence
After T014:   T015, T016, T017, T018 together
```

## Implementation strategy

- **MVP**: T001 to T003 (US1), with T004 to T008 to make the feature coherent: US1 alone would drop the spec stop without the next gate showing the summary, so the shippable MVP slice is T001 to T008 (US1 to US3, all P1) plus T021.
- Then US4 (T009), US5 (T010 to T013), US6 (T014), US7 docs (T015 to T018), polish (T019 to T022).
- Commit per logical change only when asked; this workflow does not commit here.
