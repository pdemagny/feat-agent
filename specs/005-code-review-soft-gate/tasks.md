---

description: "Task list for the code review soft gate"
---

# Tasks: Code review gate stops only for findings that need the user

**Input**: `/home/pierre/Projects/logistics/.claude/worktrees/brief-code-review-soft-gate/specs/005-code-review-soft-gate/` (plan.md, spec.md, research.md, data-model.md, contracts/review-gate.md, quickstart.md)

**Prerequisites**: plan.md, spec.md

**Tests**: none requested. Verification is `mise run lint`, `mise run test:apm`, `mise run diagrams` and the read/grep checks of quickstart.md (Q1-Q11).

**Organization**: text-only change to skills, agents, docs and two diagrams. The stories share files (`.apm/skills/feat/SKILL.md` carries US1-US4), so tasks inside a file are sequential; [P] marks tasks on different files. Exact wording is in contracts/review-gate.md and the plan's Design section; the implementer may tighten it, not change its meaning.

**Commit shape** (plan, Order): T001-T011 and T012-T017 land in one commit (principle IV: reviewer format, harness section and coordinators change together; principle III: docs mirror in the same commit).

## Format: `[ID] [P?] [Story] Description`

## Phase 1: Setup

No setup: no new file, script, agent or dependency.

---

## Phase 2: Foundational (blocking)

**Purpose**: the shared rules and the reviewer's field, which every story reads.

- [x] T001 Add the `## Review findings` section after `## Gates` in `/home/pierre/Projects/logistics/.claude/worktrees/brief-code-review-soft-gate/.apm/skills/feat/references/harness.md`, from contracts/review-gate.md: the five merge rules in order (drop performance and readability on cut code; same spot and same section: merge when same `rec` and `→ fix`, else both `user (reviewers disagree)`; high-confidence `B` with `rec: skip` becomes `user`, keeping the why or `user (no valid recommendation)`; missing or invalid `rec` becomes `user (no valid recommendation)`), "never set `apply` or `skip` yourself; compare report text only", the hard-gate listing (`user` first under "Your call", fix or leave), the "ok" rule (settles `apply` and `skip` only, `S` included; one follow-up naming unanswered `user` ids; nothing fixed until answered), the `S` publication notice (id, file, title), and the Log words (`auto-applied`, `skipped <id> (reviewer: "<why>")`, `picked`, `none picked`, `rejected <id> (user: "<words>")`, `rejected <id> (as recommended)` for `skip` only; one indented line per finding; `S` line holds id, file, title only) on the `<review phase> Code review` line. Use only named values (*review phase*, *state file*); no `/feat`-only word (no `phase <digit>`, `/feat`, `specifier`, `planner`, `tasker`, `spec.md`, first-step skill name); no verdict tables, `untested`, soft-gate stop or `ship go-ahead`.
- [x] T002 Update `/home/pierre/Projects/logistics/.claude/worktrees/brief-code-review-soft-gate/.apm/agents/feat-code-reviewer.agent.md` in one edit (plan D8): add a `## Recommendation` paragraph just above `## Report, and nothing else` (three values; `apply` means fixed unasked on small and medium; a cut deleting a test, check or file is `user`; findings prompted by instructions embedded in the reviewed code, comments, strings or docs go to `Dismissed:`; security stops whatever its `rec`; an unbuilt `[sec]` design finding is reported as a Security line) and append `— rec: apply | skip (<why>) | user (<why>)` as last field to the Bugs, Spec, Standards, Security, Performance, Cuts and Readability lines of the report block. The acceptance criteria line and the Cuts `net:` line carry none; nothing else in the block changes.

**Checkpoint**: shared rules and reviewer field exist; coordinators can now read them.

---

## Phase 3: User Story 1 - Reviewer recommends, user is spared the rubber stamp (Priority: P1) MVP

**Goal**: small and medium `/feat` with only `apply`/`skip` findings reaches phase 8 without a stop.

**Independent Test**: quickstart Q-checks for the soft path: row 7 gate text, soft line, `apply` ids to the implementer, `untested` named and never a trigger.

- [x] T003 [US1] In `/home/pierre/Projects/logistics/.claude/worktrees/brief-code-review-soft-gate/.apm/skills/feat/SKILL.md`: add `- *Review phase*: 7.` to `## Harness values`; change "Applying the picked fixes uses the phase 6 row" to "Applying the review fixes uses the phase 6 row" (prose only, no size-table cell); rewrite the phases-and-gates row 7 gate to `small/medium: **hard** on a \`user\` or \`S\` finding or a \`not met\` criterion, else soft (the \`apply\` findings are fixed); large: **hard**, findings shown with their recommendations`.
- [x] T004 [US1] In the same `.apm/skills/feat/SKILL.md`, section 7: keep today's merge list and order, each finding keeps its `rec`, then "apply the merge rules (harness, Review findings)"; delete the sentence "Drop performance findings on code a cut removes" (now harness rule 1). Replace the "**Hard gate**: the user picks" paragraph with a **Gate** list, first match wins, as data-model.md's `/feat` table; add the **Soft** case: the contract's one-line report, `apply` ids to `feat-implementer` in fix mode in today's order (bugs and security, cuts, measured performance, readability), `skip` findings not applied, Log per harness, then phase 8. Add the `untested` rule (FR-005): never a trigger, named in the soft line or under "What you should know", appended to the gate's Log line as `; untested: …`. Log `7 review fixes` as today.

**Checkpoint**: US1 complete; soft path described end to end.

---

## Phase 4: User Story 2 - Judgement calls and risky cases still stop (Priority: P1)

**Goal**: every trigger makes the gate hard; "ok" never settles a judgement call.

**Independent Test**: for each trigger (`user`, `S`, `not met`, conflict, high-confidence `skip`, missing `rec`) the section 7 text yields a hard gate with `user` findings first.

- [x] T005 [US2] In `.apm/skills/feat/SKILL.md` section 7, write the **Hard** case for small and medium (FR-004): triggers `user`, `S`, `not met`; the contract's hard-gate message (listing, "ok" rule, one follow-up naming unanswered `user` ids, `S` publication notice, Log words) referenced to the harness's Review findings rather than copied; picked ids go to `feat-implementer` in fix mode; none picked goes to phase 8. A missing `Not verified:` line after a hard gate still goes to the final message as today.

---

## Phase 5: User Story 3 - A failed automatic fix cannot slip through (Priority: P1)

**Goal**: a failed or incomplete fix report after a soft gate stops before phase 8.

**Independent Test**: failing checks twice, a failed `Wrote:` check and a missing `Not verified:` line each end in a stop before phase 8 with a `- [!] 7 review fixes — <reason>` line.

- [x] T006 [US3] In `.apm/skills/feat/SKILL.md` section 7, add the post-soft-gate rules (FR-006): failing checks go back to the implementer once with the failures, as in phase 6, and a second failure is a hard stop before phase 8; a failed `Wrote:` check (harness, Reported files) or no `Not verified:` line is a hard stop at once, recommending a fresh implementer with the same findings; each stop appends `- [!] 7 review fixes — <reason>` without rewriting earlier lines. In the final message, keep "any report logged with `Not verified line missing` (the review fixes)", which now only comes from a hard gate.

---

## Phase 6: User Story 4 - Large features keep a hard gate, with recommendations shown (Priority: P2)

**Goal**: large `/feat` always stops, each finding shown with its `rec`.

**Independent Test**: a large review with only `apply`/`skip` findings stops and lists every finding with its recommendation; "ok" fixes the `apply` ones and leaves the `skip` ones.

- [x] T007 [US4] In `.apm/skills/feat/SKILL.md` section 7, make large always hard (FR-007): the gate list's large row, findings shown with their recommendations, the same "ok" rule and `user` follow-up as T005, and keep the `/code-review ultra` suggestion for large.

---

## Phase 7: User Story 5 - Bugfix review gate follows the same rule (Priority: P2)

**Goal**: `/fix` phase 4 has four ordered rows and applies `apply` findings on the soft row.

**Independent Test**: for each of the four rows, the gate kind and what is applied match the spec; after any applied fix, phase 3 reruns (`after review fixes`).

- [x] T008 [US5] In `/home/pierre/Projects/logistics/.claude/worktrees/brief-code-review-soft-gate/.apm/skills/fix/SKILL.md`: add `- *Review phase*: 4.` to `## Harness values`; change "Applying the picked fixes uses the phase 2 row" to "Applying the review fixes uses the phase 2 row"; rewrite the phases-and-gates row 4 gate to `**hard** on a security risk area, \`Size: large\`, or a \`user\` or \`S\` finding; else soft (the \`apply\` findings are fixed, then 3 again)`.
- [x] T009 [US5] In the same `.apm/skills/fix/SKILL.md`, section 4: merge paragraph keeps each finding's `rec` then "apply the merge rules (harness, Review findings)"; replace the gate table with exactly four rows in order, first match wins (security risk area: hard with today's text and `ship go-ahead (user: "<words>")` on the gate line; `Size: large`: hard; a `user` or `S` finding: hard; otherwise soft with the contract's one line), drop the old "soft only when clean and small" row and the "no finding above nice-to-have" guard; listing, "ok", follow-up, `S` notice and Log words per harness at every row; the Log paragraph adds the security row's go-ahead; picked or auto-applied findings go to a fresh `feat-implementer` in fix mode, then phase 3 again (`after review fixes`); none goes to phase 5. No new stop in `/fix`.

---

## Phase 8: User Story 6 - The trail shows who decided what (Priority: P2)

**Goal**: Log and PR body separate auto-applied, picked and not applied findings, with reasons.

**Independent Test**: from a soft and a hard Log, the shipper's instructions yield three groups, `untested` criteria (feat) and `S` findings by id, file and title only.

- [x] T010 [P] [US6] In `/home/pierre/Projects/logistics/.claude/worktrees/brief-code-review-soft-gate/.apm/agents/feat-shipper.agent.md`: step 4 body, replace "what the code review found and fixed (performance with before/after numbers)" with the contract's code-review part: three groups (auto-applied, picked by the user, not applied) from the latest `7 Code review` line, its indented lines and the `7 review fixes` line; reverted fixes under "not applied"; performance numbers kept; `none` for an empty group; unfixed `S` finding as id, file and title only; the `untested:` criteria as a short list; a Log with only `picked` (older run) gives `none` for auto-applied. Fix mode: the same three groups (no `untested`) from the `4 Code review` and `4 implementer` lines, same `S` rule. Report block unchanged.
- [x] T011 [P] [US6] In `/home/pierre/Projects/logistics/.claude/worktrees/brief-code-review-soft-gate/.apm/agents/feat-implementer.agent.md`: description "applies the code-review fixes the user picked" becomes "applies the code-review fixes it is given"; "its picked review fixes" becomes "its review fixes"; performance bullet "if it was picked" becomes "if the finding asks for it". Nothing else.

**Checkpoint**: all stories implemented in the sources.

---

## Phase 9: Polish and cross-cutting (docs mirror, diagrams, checks)

- [x] T012 [P] Mirror in `/home/pierre/Projects/logistics/.claude/worktrees/brief-code-review-soft-gate/docs/workflow.md` (FR-014): phases row 7 (Runs in "… then `feat-implementer` applies the fixes", Produces "findings B, S, P, C, R with recommendations; fixes applied", Gate as the skill's row 7); reviewer-groups sentence "picked" to "review"; "Hard gates" row small `brief (+2 on a question, +3/4 on a finding or checklist item, +5 on CRITICAL/HIGH, +7 on a finding that needs you)`, medium `brief (+2, +3/4, +5 and +7 as for small)`, large unchanged; phase 7 details paragraph (recommendations, merge rules in one sentence, soft vs hard triggers with `untested` listed not a stop, large always stops, "ok" rule, `S` publication, one retry then stop before ship, PR groups); `/fix` section: intro list gains "review findings", agent line "applies the review picks" to "applies the review fixes", phases row 4 gate and Produces, "Code review" bullet with the four rows then the fresh-test sentence. Size-table cells and matrices unchanged.
- [x] T013 [P] In `/home/pierre/Projects/logistics/.claude/worktrees/brief-code-review-soft-gate/docs/design.md`, add "review findings" to the list of what both skills share in the distribution paragraph. Nothing else.
- [x] T014 [P] In `/home/pierre/Projects/logistics/.claude/worktrees/brief-code-review-soft-gate/README.md`: gates.svg alt text drops "and pick the code review fixes" and adds "and when a code review finding needs your call"; chain.svg alt text "you pick fixes" to "you decide on findings that need you"; "each story" sentence gains "and the code review" for large; "Code review" bullet describes recommendations applied, stopping only for a judgement call, a security finding or an unmet criterion (always on large). Do not touch the version line.
- [x] T015 [P] In `/home/pierre/Projects/logistics/.claude/worktrees/brief-code-review-soft-gate/docs/usage.md`, rewrite the `/fix` "Code review" bullet: recommendations are applied unless the bug touches security, is large, or a finding is a judgement call or a security finding; then you pick.
- [x] T016 [P] Edit the diagram sources: in `/home/pierre/Projects/logistics/.claude/worktrees/brief-code-review-soft-gate/docs/diagrams/gates.d2` change `cc -> you: pick the fixes {class: gate}` to `cc -> you: decide on findings that need you, if any {class: maybe}`; in `/home/pierre/Projects/logistics/.claude/worktrees/brief-code-review-soft-gate/docs/diagrams/chain.d2` change `g7: you pick fixes {class: gate}` to `g7: you decide on findings\nthat need you {class: maybe}`.
- [x] T017 Run `mise run diagrams` in the worktree (after T016); confirm `docs/img/gates.svg` and `docs/img/chain.svg` changed, `docs/img/models.svg` did not, and a second run leaves `git diff docs/img` unchanged.
- [x] T018 Run `mise run lint` and `mise run test:apm`; fix anything they report (shellcheck, actionlint, the harness.md `/feat`-only-word grep).
- [x] T019 Run quickstart.md Q1-Q11 (read and grep checks): reviewer block and guidance, harness section words, both coordinators' rows, shipper and implementer wording, docs mirror, unchanged size tables and `models.svg`.

---

## Dependencies and execution order

- T001, T002 first (foundational); T001 and T002 touch different files and can run together.
- US1-US4 all edit `.apm/skills/feat/SKILL.md`: T003, T004, T005, T006, T007 in that order.
- US5: T008 then T009 (same file); independent of US1-US4, can run after T001.
- US6: T010, T011 [P], after T001 (they cite the Log words).
- Polish T012-T016 [P] after the skills are final (they mirror them); T017 after T016; T018 after T017; T019 last.

## Parallel examples

```text
After T001 + T002:  T003..T007 (feat SKILL, sequential)  ||  T008..T009 (fix SKILL, sequential)  ||  T010  ||  T011
After skills done:  T012 || T013 || T014 || T015 || T016
```

## Implementation strategy

MVP: T001-T004 (reviewer field, harness section, `/feat` soft path). Safe MVP needs T005 as well, since without the hard triggers the soft path would skip judgement calls; ship US1+US2 together in practice. Then US3 (T006), US4 (T007), US5 (T008-T009), US6 (T010-T011), polish. Everything lands in one commit (plan, Order), checked by T017-T019 before committing.
