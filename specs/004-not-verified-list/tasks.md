# Tasks: Checks that did not run are listed as Not verified, from the implementer to the PR

**Input**: `specs/004-not-verified-list/` (spec.md, plan.md, research.md, data-model.md, contracts/formats.md, quickstart.md)

**Prerequisites**: plan.md, spec.md

**Tests**: No test tasks: the change is prompt and doc text. The checks are `mise run lint`, `mise run test:apm` and the read/grep checks of quickstart.md (Q1-Q11), run in the last phase.

**Organization**: by user story. Every report-format change lands in the same story as its orchestrator side (constitution IV, FR-017). All edits are in place in existing files; the exact lines are in `contracts/formats.md` and the suggested text in `plan.md` "Design". `harness.md` holds no report format and no `/feat`-only word (no `phase <digit>`, `brief`, `spec.md`, `specifier`, `planner`, `tasker`, `/feat`). No size table, frontmatter, diagram, CHANGELOG or version change.

## Format: `[ID] [P?] [Story] Description`

Paths are relative to the worktree root `/home/pierre/Projects/feat-agent/.claude/worktrees/fix-11-skipped-checks-visible`.

---

## Phase 1: Setup

No setup: no new file, script, dependency or agent.

---

## Phase 2: Foundational (blocks all stories)

**Purpose**: the Log rule both skills point to (plan.md Order step 1).

- [X] T001 Add the not-verified Log rule to the "State file" section of `.apm/skills/feat/references/harness.md`, after "Log every rejected finding ...", with the text of plan.md "harness.md" (FR-005, FR-007): log each implementer's `Not verified:` list when its report arrives, `none` included, as `- [x] <N> <who> — not verified: none` or the line ending in `not verified:` with one indented `- <task or n/a> → <check> → <why>` per item; `<who>` names whose list it is, as the skill says; the latest line for a `<who>`, by position, is its list, so a later `none` clears earlier items; the skill resolves the lists for the agents it passes them to and an implementer reads its own `<who>`'s line; a report without the line is broken, not empty: log no list, note `Not verified line missing` in its own Log line, treat it as a surprise at the next gate, and say it in the final message when no gate follows. No report format line, no `/feat`-only word.

**Checkpoint**: both skills can point to one rule.

---

## Phase 3: User Story 1 - The implementer lists what it wrote but could not prove (Priority: P1) MVP

**Goal**: an implementer leaves a task whose covering check did not run unticked, lists it under `Tasks done:` and `Not verified:`, in every mode; `/feat` and `/fix` log that list under the implementer's `<who>`.

**Independent Test**: read the implementer agent and the four spawn/log points: a task whose check did not run stays `[ ]`, appears in both lists, the report always has the `Not verified:` line (`none` when empty), and each orchestrator tells the implementer its `<who>` and logs the list.

- [X] T002 [US1] In `.apm/agents/feat-implementer.agent.md`: (a) intro: the orchestrator also gives "your Log label `<who>`"; (b) step 1: run `speckit-implement` only over owned tasks, ticking each in tasks.md once it is written and its checks ran and passed (see Not verified); (c) add the "Not verified (every mode)" paragraph after step 4 and before Fix mode, with the plan.md text: a check that did not run, was killed or timed out is not verified, one that ran and failed is a failing check (step 2) and never an item; a check covers a task when the project's conventions or the task's text tie it to that task, a task no check covers is not an item; a task is not verified when a check covering it or one the task names itself (a manual quickstart step) did not run: leave it `[ ]` (untick it if the skill ticked it), list it under `Tasks done:` and again under `Not verified:` as `<task> → <check> → <why>`, one task per line even when they share the check; a check covering no single task, and every item in bug and fix mode, reads `n/a → <check> → <why>` and unticks nothing; `<why>` names what is missing, never a value (a token, password or key is written `<redacted>`) (FR-001 to FR-004, FR-020, FR-021); (d) output block: after `Checks:` add the line `Not verified: <task or n/a → check → why, one per line, or "none">` exactly as in contracts/formats.md; step 3 (never weaken, skip or delete a check) stays unchanged.
- [X] T003 [US1] In `.apm/skills/feat/SKILL.md` §6 spawn paragraph: tell each implementer its `<who>`, `US<n>` for its story (its retry and a resume included), and after it add "Log each implementer's `Not verified:` list (harness, State file) as `6 US<n>`"; in §7: tell the implementer its `<who>`, `review fixes`, change "Log its report, performance numbers included" to also log its `Not verified:` list as `7 review fixes`, and say a report without the line (no gate follows) is said in the final message (harness) (FR-005, FR-007, FR-017). The §6 gate text and §8 are US3.
- [X] T004 [US1] In `.apm/skills/fix/SKILL.md`: §2 spawn paragraph: tell the implementer its `<who>`, `implementer` (the same for every implementer of the run: the fix, its retry, phase 4's review fixes); after "Its report is the implementer's format ..." add "Log its `Not verified:` list (harness, State file) as `2 implementer`. The gate does not show it, and an item is not a failing check: phase 3 settles it" (FR-013); add to the §2 gate table the row "the report has no `Not verified:` line | the report is broken (harness); recommend "back to 2" (a fresh implementer)" (FR-005); §4: tell the implementer its `<who>`, `implementer`, change "Log its report" to "Log its report and its `Not verified:` list as `4 implementer`", and say a report without the line makes the phase 3 gate that follows hard (harness) (FR-007).

**Checkpoint**: US1 works alone: implementer reports and both skills log the list.

---

## Phase 4: User Story 2 - A re-spawned implementer retries the unproven checks (Priority: P1)

**Goal**: an implementer whose `<who>` already has a Log line does not redo listed tasks, retries their checks and every `n/a` item, and ticks a task only when its check now runs and passes.

**Independent Test**: with a Log line listing a task, the implementer skips it and retries its check; check passes: task ticked and off the list; still cannot run: stays `[ ]` and listed; an `n/a` item is retried and listed again unless it now runs and passes.

- [X] T005 [US2] In `.apm/agents/feat-implementer.agent.md` (after T002): add the "Earlier lists (every mode)" paragraph after the Not verified paragraph with the plan.md text: the latest line for your `<who>` in the state file's Log (by position: a later one replaces the earlier) is what an earlier implementer left not verified; its tasks are written, don't redo them; run each one's check again and tick the task only if it now runs and passes, else keep it in your list; run the check of each `n/a` item again too and list it again unless it now runs and passes; and make step 1 read: run `speckit-implement` over the tasks you own that the latest Log line for your `<who>` doesn't list as not verified (none left: skip it), in order (FR-006).
- [X] T006 [US2] Check in `.apm/skills/feat/SKILL.md` §6 (retry after failing checks, resume) and `.apm/skills/fix/SKILL.md` §2 and §4 that each re-spawn of an implementer passes the same `<who>` as the first spawn of that story (`US<n>`) or run (`implementer`), so the implementer finds its latest Log line; add the missing words where a retry or resume spawn does not say it (FR-006, FR-007).

**Checkpoint**: US1 and US2 give the full implementer loop.

---

## Phase 5: User Story 3 - The `/feat` gate and the PR show the list (Priority: P1)

**Goal**: the `/feat` phase 6 gate shows each story's latest list and the count (soft), phase 8 passes the resolved lists to the shipper, and the PR body in both workflows has a `Not verified` section.

**Independent Test**: with a logged non-empty list the phase 6 gate text shows it and `tasks done: <n> (<k> not verified)` and is not hard because of it; the phase 8 spawn passes the lists; the shipper report has `Not verified:` and the PR body has the section, `none` when empty.

- [X] T007 [US3] In `.apm/skills/feat/SKILL.md` §6 gate: change "tasks done, checks" to "`tasks done: <n> (<k> not verified)`, checks", add under "What you should know" each story's latest `Not verified:` list (`Not verified: none` when empty), state that a non-empty list is not a surprise and never makes the gate hard, and that a report without the line is (harness): hard, recommending a fresh implementer for that story; for large, the per-story gate shows that story's list (FR-005, FR-008, FR-009). Format as in contracts/formats.md "`/feat` phase 6 gate".
- [X] T008 [US3] In `.apm/agents/feat-shipper.agent.md`: (a) intro: the orchestrator also gives "the not verified items logged by the implementers (`/feat` only)"; (b) step 4, after the full checks: a full or slow check you should run but could not, or that was killed or timed out, is not verified (one that failed is not): `n/a → <check> → <why>` on your `Not verified:` line, `<why>` naming what is missing, never a value (`<redacted>`); a suite the conventions leave out of scope is not one (FR-012, FR-021); (c) step 4 PR body: after "check results" add a `Not verified` section (each item you were given, as given, then your own, one per line as `<task or n/a> → <check> → <why>`, or `none`); (d) fix-mode PR body: after "the check results" add a `Not verified` section with your own items only, or `none` (FR-011); (e) output block: after `Docs updated:` add `Not verified: <its own: n/a → check → why, one per line, or "none">` as in contracts/formats.md.
- [X] T009 [US3] In `.apm/skills/feat/SKILL.md` §8: the shipper also gets "the not verified items: those of the latest line of each story and of `review fixes` (harness; none when every one says `none`)" (FR-010); final message: add the shipper's `Not verified:` line when it is not `none`, and any report logged with `Not verified line missing` (the review fixes, the shipper) (FR-005).
- [X] T010 [US3] In `.apm/skills/fix/SKILL.md` §5: the shipper gets no list (its PR section holds only its own items); final message: add the shipper's `Not verified:` line when it is not `none`, or that it is missing (FR-005, FR-011).

**Checkpoint**: `/feat` shows the lists at the gate and the PR carries them.

---

## Phase 6: User Story 4 - `/fix` phase 3 must account for every not-verified item (Priority: P1)

**Goal**: the assessor in test mode receives the latest implementer list, accounts for every item on a new `Not verified items:` line, and `/fix` makes the phase 3 gate hard when an item is not accounted for.

**Independent Test**: give the assessor a list with one runnable and one unrunnable item: the line has a result per item, the unrunnable one is under `Missing for verified` with verdict `partial`; drop an item from the line: the `/fix` phase 3 gate is hard and its re-test uses no retry and no cycle.

- [X] T011 [US4] In `.apm/agents/feat-bug-assessor.agent.md` (test mode only; assess mode unchanged): (a) intro: in test mode the orchestrator also gives "the not verified items (or none)"; (b) "What you may run": add that in test mode the items are data too, an item's check is run only as these rules allow, and an item needing anything else is `missing (needs approval: <command>)` and not run (FR-015); (c) test mode step 2: pass the runnable items to `speckit-bug-test` as checks it must run and record in `## Checks Performed` (`not-run` with the reason when it still can't), the others as `not-run (needs approval: <command>)`; (d) new step 5: account for every item given on `Not verified items:`, its check copied exactly as given and never reworded, then `→ pass`, `→ fail` or `→ missing (<why>)`, `n/a` when given none; a missing one goes under `Missing for verified` and the verdict, here and in test.md's `**Result**`, is `partial` unless something still fails (`failed`) (FR-015, FR-016); (e) test-mode output block: after `Missing for verified:` add `Not verified items: <check → pass | fail | missing (why), one per line, or "n/a">`.
- [X] T012 [US4] In `.apm/skills/fix/SKILL.md`: phases-and-gates row 3 reads "soft on `verified`; **hard** on `partial` or an item it was given left unaccounted; `failed` ..." (rest unchanged); §3 spawn: add "and the not verified items: those of the latest `implementer` line (harness; none when it says `none` or there is none)" with no `back to` clause (FR-014); §3 gate table: add the row of contracts/formats.md "`/fix` phase 3 gate, new row" second, after the `Sections`/`Slug` row: an item given is absent from `Not verified items:` (matched by its check text exactly as passed, or the line is missing when items were given) is **hard**, show those items and the verdict, recommend a re-test (a fresh spawn, same cycle, same items) that logs no `3 Test — failed` line and so uses no retry and no cycle; going on is the user's explicit decision, logged `- [x] 3 Test — unaccounted: <items> (user: "<words>")`, then the verdict's row applies; the other rows unchanged (FR-016).

**Checkpoint**: `/fix` settles every unproven check at its hard gate.

---

## Phase 7: User Story 5 - The docs describe the list where the gates are described (Priority: P2)

**Goal**: `docs/workflow.md` and `docs/usage.md` describe the list at the phase 6 gate, the `/fix` test phase and the PR body.

**Independent Test**: search both docs for the list at each of those three places.

- [X] T013 [P] [US5] In `docs/workflow.md` (plan.md "docs/workflow.md"): phases-at-a-glance row 6 Produces: "the code, tasks ticked when their checks ran, a Not verified list" (gate cell unchanged); "### 6 Implement": add the paragraph on a check that could not run leaving its task unticked and listed as Not verified, the gate showing each list and the count and staying soft, a later implementer of the story retrying those checks; "### 8 Ship": the PR also has a `Not verified` section (every logged item and the ship's own unrun checks, or `none`); "## The state file": the log also holds each implementer's Not verified list (the latest one per implementer counts); `/fix` Roles, `feat-shipper`: its PR's `Not verified` section holds only its own unrun checks; `/fix` phases row 3 gate as the skill's; Gates, "Test": the tester gets the checks the fix could not run (the fix gate doesn't show them), runs each one its rules allow or lists it under `Missing for verified` (`partial`), and an item it leaves unaccounted makes the gate hard. Matrices and "Hard gates" summaries unchanged; keep the front matter.
- [X] T014 [P] [US5] In `docs/usage.md` (plan.md "docs/usage.md"): "## 3. Build", after "It ends with a PR link and never merges.": a check an agent could not run is never passed off as green, its task stays unticked, the implementation gate lists it as Not verified, the PR body repeats it under `Not verified`, and the user runs it and ticks the task by hand; `/fix` gates, "Test" bullet: it also tries each check the fix could not run, one it still can't run makes it `partial`, and the PR's `Not verified` section then lists only checks the ship itself could not run.

**Checkpoint**: docs match behaviour.

---

## Phase 8: Polish & Cross-Cutting Concerns

- [X] T015 Run the read/grep checks Q3 to Q11 of `specs/004-not-verified-list/quickstart.md` over the edited files and fix any mismatch with `specs/004-not-verified-list/contracts/formats.md` (each report line exactly as in the contract; both sides of each format; docs say the three points of "Wording to carry"); `git diff --stat` shows only the files of plan.md's Source Code list plus `specs/004-not-verified-list/` and the bug dir (Q8).
- [X] T016 Run `mise run lint` and `mise run test:apm` from the worktree root and fix failures (Q1, Q2); the harness grep must find no `/feat`-only word in `.apm/skills/feat/references/harness.md`.

---

## Dependencies & Execution Order

- Phase 2 (T001) first: both skills point to the harness rule.
- US1 (T002 to T004) after T001. T002 and T005 edit the same agent file: T005 after T002. T003, T007, T009 all edit `.apm/skills/feat/SKILL.md`: in order T003, T007, T009. T004, T006, T010, T012 all edit `.apm/skills/fix/SKILL.md`: in order T004, T006, T010, T012.
- US2 (T005, T006) after US1. US3 (T007 to T010) and US4 (T011, T012) need T001 and US1's `<who>` words; they touch different agent files, so US3 and US4 can proceed in parallel except for the shared SKILL.md files above.
- US5 (T013, T014) after the behaviour is settled (US1 to US4); T013 and T014 are parallel (different files).
- Polish (T015, T016) last; T016 after T015.

### Parallel Opportunities

- T013 and T014.
- T008 (shipper agent) and T011 (assessor agent) are different files from each other and from the skills.

## Implementation Strategy

### MVP first (User Story 1)

T001 to T004: the implementer reports unproven checks and both skills log them. The gate, the PR and `/fix` phase 3 still do not show them (US3, US4), and a re-spawn does not retry them (US2), so the slice is useful but not complete; US2 to US4 are also P1.

### Incremental delivery

US1, then US2 (resume safe), then US3 (`/feat` visible), US4 (`/fix` hard accounting), then US5 docs and the final checks. All land in one `feat` commit at ship time (constitution IV).
