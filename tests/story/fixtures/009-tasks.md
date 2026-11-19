---

description: "Tasks for soft-design-gate"
---

# Tasks: Design review stops only on findings that need the user

**Input**: Design documents from `specs/009-soft-design-gate/` (plan.md, spec.md, research.md, data-model.md, contracts/phase4-gate.md, quickstart.md)

**Tests**: None requested. This is a text-only change (prompts, docs, D2 sources); it is checked by `mise run lint`, `mise run test:apm`, the SC-004 greps and the quickstart §3 walk-through.

**Organization**: Grouped by user story. Stories 1 to 4 all land in section 4 of `.apm/skills/feat/SKILL.md`, so those tasks run in order. Wording to aim for is in `contracts/phase4-gate.md` (values, triggers and formats must not change). No commits during implementation: the shipper makes one `feat(feat)` commit.

**Paths** are relative to the worktree root. `harness.md`, `/fix`, phase 7, the size table, `docs/diagrams/models.py` and `docs/img/models.svg` MUST NOT change (FR-012).

## Phase 1: Setup

- [x] T001 Run `mise run lint` and `mise run test:apm` once from the worktree root to confirm a clean baseline before any edit

---

## Phase 2: Foundational (blocks all stories)

**Purpose**: The reviewer's report format is what every gate rule reads, so it changes first (constitution IV).

- [x] T002 In `.apm/agents/feat-design-reviewer.agent.md`, add a `## Recommendation` section after the severity paragraph and before `## Report, and nothing else` (contract §1): every finding line, nice-to-have included, ends with `— rec: apply | skip (<why>) | user (<why>)`; `user` for any finding that removes or changes a story, a requirement or an acceptance criterion the brief asked for, overturns a spec assumption, or weakens a control the spec or plan sets (relaxes validation, widens access); a finding that only adds a tightening requirement (input validation, error handling, a secure default) may be `apply`; the 4c paraphrase carries no rec (FR-001, FR-002). In the report format, append the rec after `severity: …` on the `[sec]`, `[cost]` and `[design]` lines, give `[sec]` and `[cost]` the `: <section or line>` spot, and add one line saying the spot is the section heading as written in the artifact, or a line number. Leave the lenses, `Checked and fine:` and `Wrote: none` unchanged.

**Checkpoint**: `grep -n 'rec: apply | skip' .apm/agents/feat-design-reviewer.agent.md` shows three finding lines; `grep -n 'widens access'` matches.

---

## Phase 3: User Story 1 - Plain design findings are applied without a stop (P1) MVP

**Goal**: A small or medium run whose design findings are all `apply` or `skip`, with no other trigger, reaches phase 5 with one status line and no stop.

**Independent Test**: Quickstart §3 cases A, A2, B, B2: soft gate, line with counts and `[sec]` ids, no `SendMessage` when nothing is `apply`.

- [x] T003 [US1] In `.apm/skills/feat/SKILL.md` section 4 (about lines 279 to 310), write the **Soft** paragraph (contract §4, FR-006, FR-007): print the 4c paraphrase (after the spec block when phase 2 was soft), then the one line `Phase 4 Design review — soft: <n> findings, <a> applied, <s> skipped[; security: <[sec] ids with rec apply>][; security skipped: <[sec] ids with rec skip>]; none needs your call. Next: phase 5 Tasks`; leave out `; security: …` and `; security skipped: …` when empty; never name severity; zero findings prints `0 findings, 0 applied, 0 skipped`; the `apply` findings go to `feat-planner` continued with `SendMessage`, the `skip` ones are left; with no `apply` finding send nothing to the planner and go straight to phase 5; spec assumptions after a soft phase 2 logged as kept at their recommendations, as today.
- [x] T004 [US1] In the same section 4 amend-pass paragraph of `.apm/skills/feat/SKILL.md`, change one clause: accepted findings are the `apply` findings on a soft gate and the picked ones on a hard gate; continued planner after soft, fresh planner after hard (FR-008).

**Checkpoint**: Section 4 describes the soft path completely.

---

## Phase 4: User Story 2 - Judgement calls and risky cases still stop (P1)

**Goal**: Every user-owned decision keeps a hard gate that lists `user` findings first.

**Independent Test**: Quickstart §3 cases C, D, E: each trigger gives a hard gate; bare "ok" with an unanswered `user` finding gets one follow-up naming the ids.

- [x] T005 [US2] In `.apm/skills/feat/SKILL.md` section 4, add the gate table, first match wins, in the shape of section 7's (contract §3, FR-005): small/medium is **hard** on a `D` finding with `rec: user`, an assumption with `needs user: yes`, a constitution violation, a blocker, a size increase, a 4c paraphrase contradicting the brief, an unchecked checklist item carried from a soft phase 2, or a failed report check (harness, Reported files), **soft** otherwise. No row may mention severity or "a finding above nice-to-have". Keep today's "what the gate shows" list in order.
- [x] T006 [US2] In `.apm/skills/feat/SKILL.md` section 4, write the **Hard** paragraph (contract §5, FR-008): title `Phase 3–4: Plan and design review — needs your call` on small/medium; What you should know says why it stops; Your call lists each `user` finding first as "apply or leave?" with the reviewer's why, then the others with their `rec`; "ok" applies every `apply` and leaves every `skip`; each `user` finding needs its own answer; a bare "ok" with one unanswered gets one follow-up naming the ids (refer to the harness's Review findings rule, "fix" read as "apply", its `S` notice does not apply); picked findings and any spec change go to a fresh `feat-planner`.
- [x] T007 [US2] In `.apm/skills/feat/SKILL.md`, edit the phase table row 4 Gate cell (about line 131) as in plan.md section 2: small/medium one gate for 3+4, **hard** on a `user` finding, a user-call assumption, a constitution violation, a blocker, a size increase, a paraphrase that contradicts the brief or a carried checklist item, else soft (the `apply` findings are applied); large **hard**, findings shown with their recommendations. Edit the cell only, no re-alignment.

**Checkpoint**: `grep -n 'above nice-to-have' .apm/skills/feat/SKILL.md` finds nothing.

---

## Phase 5: User Story 3 - /feat merges design findings without recommending itself (P2)

**Goal**: `/feat` never sets `apply` or `skip`; conflicts and gaps become `user`.

**Independent Test**: Quickstart §3 cases F and G.

- [x] T008 [US3] In `.apm/skills/feat/SKILL.md` section 4, replace the last sentence of the spawn paragraph ("Merge the findings into `D1…`, drop duplicates, give each a recommendation") with the merge rule of contract §2 (FR-003, FR-004): each finding keeps the `rec` that ends its line; never set `apply` or `skip`; apply harness merge rules 2, 3 and 5 by reference (do not restate them), where the same spot is the same artifact and an identical section heading or line, and the same section is the same tag (`[sec]`, `[cost]`, `[design]`); rules 1 and 4 do not apply; findings with different tags on the same spot stay separate, each with its own `rec`. A missing or invalid rec becomes `user (no valid recommendation)`.

---

## Phase 6: User Story 4 - Large features keep a hard gate with phase 7's rule (P2)

**Goal**: Large is always hard, every finding shown with its rec, `user` first.

**Independent Test**: Quickstart §3 case H.

- [x] T009 [US4] In `.apm/skills/feat/SKILL.md` section 4, make the gate table's large row always **hard** and extend the Hard paragraph for large (contract §5, FR-009): title `Phase 4: Design review — needs your call`, every finding shown with its `rec` even when none is `user`, `user` first, same "ok" rule and follow-up.

---

## Phase 7: User Story 5 - The Log and the docs say what happened (P2)

**Goal**: The Log records each outcome and every doc, diagram and render says the same as `/feat`.

**Independent Test**: Read the Log paragraph, then run the SC-004 greps and `mise run diagrams`.

- [x] T010 [US5] In `.apm/skills/feat/SKILL.md` section 4, write the Log paragraph (contract §6, FR-010): soft `- [x] 4 Design review — auto-applied <ids | none>; skipped <id> (reviewer: "<why>"), …`; hard `- [x] 4 Design review — picked <ids> | none picked; rejected <id> (user: "<words>"), <id> (as recommended), …`; one indented line per finding `    - <id> <artifact>: <section> — <a few words> — rec: <value>` (a `[sec]` finding gives its title only); accepted design findings are the `auto-applied` and `picked` ids (phase 7 gives accepted `[sec]` ones to lens 7b); `skipped` and rejected `D` findings reach later reviewers as rejected findings.
- [x] T011 [P] [US5] In `.apm/agents/feat-shipper.agent.md` (about line 74), where "accepted design findings" are read, add their source: "(the `auto-applied` and `picked` ids of the `4 Design review` Log line; `accepted` in older runs)". Report format unchanged.
- [x] T012 [P] [US5] In `docs/workflow.md`, edit the phase table row 4 (Gate cell: hard only on a finding that needs you (`user`), a user-call assumption, a constitution violation, a blocker, a size increase, a paraphrase that contradicts the brief or an unchecked checklist item after a soft phase 2, else soft and the `apply` findings are applied, always hard for large; Produces cell: a paraphrase, findings D1… with recommendations) and, in `### 4 Design review`, replace the paragraph from "Each `D…` gets a recommendation" through "…the accepted ones" with the reviewer-recommends rules (plan.md section 4). Keep the planner amend pass text. No re-alignment of the table.
- [x] T013 [P] [US5] In `docs/usage.md`, replace the "Answering a gate" example's "I recommend accepting" with the reviewer's recs, `user` first (contract §7), rewrite the paragraph below it (on small and medium the gate stops only when something needs your call; "ok" applies every `apply` and leaves every `skip`; a `user` finding needs its own answer) and change the plain-words example to "apply D1, leave D2: behind the VPN".
- [x] T014 [P] [US5] In `docs/diagrams/gates.d2` line 26, set the label to `cc -> you: check the spec, decide on findings that need you, if any {class: maybe}`; in `docs/diagrams/chain.d2`, set the `g4` label to `you check the spec,\ndecide on findings\nthat need you` (class `maybe` unchanged).
- [x] T015 [P] [US5] In `README.md`, change the chain alt text "you check the spec and decide on findings, then spec and plan are amended" to "you check the spec and decide on findings that need you, then spec and plan are amended". Leave the gates alt text.
- [x] T016 [US5] Run `mise run diagrams` to re-render `docs/img/gates.svg` and `docs/img/chain.svg` (after T014); `docs/img/models.svg` must come out unchanged.

**Checkpoint**: `git status --short docs/img` lists only `gates.svg` and `chain.svg`.

---

## Phase 8: Polish and checks

- [x] T017 Run `mise run lint` and `mise run test:apm` from the worktree root; both must pass (FR-015, SC-005). Fix any `/feat`-only-word or shellcheck complaint in the touched files.
- [x] T018 Run the quickstart §2 text checks and confirm each SC-004 grep finds no match (`grep -n 'above nice-to-have' .apm/skills/feat/SKILL.md`; `grep -n 'real finding\|finding above' docs/workflow.md README.md docs/usage.md`; `grep -n 'decide on the findings\|decide on findings,' docs/workflow.md README.md docs/usage.md docs/diagrams/gates.d2`; `grep -n 'decide on findings {' docs/diagrams/chain.d2`), `grep -n 'I recommend' docs/usage.md` shows nothing on a `D` finding, and `git diff --quiet origin/main -- .apm/skills/feat/references/harness.md .apm/skills/fix/SKILL.md .apm/agents/feat-code-reviewer.agent.md docs/diagrams/models.py` exits 0.
- [x] T019 Walk quickstart §3 cases A to H against section 4 of `.apm/skills/feat/SKILL.md` (reading only) and fix any case that gives the wrong gate. Also confirm section 4 tells `/feat` to work from the reviewer's report and never to read the spec or plan for this (FR-013).

---

## Dependencies and Execution Order

- T001 first. T002 (Foundational) blocks everything.
- T003 to T010 all edit section 4 of `.apm/skills/feat/SKILL.md`: run in order T003, T004, T005, T006, T007, T008, T009, T010 (no [P]).
- T011 to T015 touch different files and can run in parallel once T002 is done; T012 and T013 read best after T006 is written.
- T016 after T014. T017 to T019 after everything else.
- Story order is P1 (US1, US2) then P2 (US3, US4, US5); the stories share one file, so they are not independent in parallel, but each checkpoint is checkable on its own.

## Parallel Example

```text
After T010:
Task: T011 feat-shipper.agent.md
Task: T012 docs/workflow.md
Task: T013 docs/usage.md
Task: T014 docs/diagrams/*.d2
Task: T015 README.md
```

## Implementation Strategy

MVP is T001 to T007 (reviewer rec, soft gate, hard triggers, row 4): the gate stops only for what needs the user. T008 to T010 complete merge, large and Log; T011 to T016 bring docs and renders in line; because the report format and `/feat` change together (constitution IV), ship all of them in one commit.
