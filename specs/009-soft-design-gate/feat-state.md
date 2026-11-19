# /feat state: Design review stops only on findings that need the user

- Branch: soft-design-gate Worktree: /home/pierre/Projects/logistics/.claude/worktrees/brief-soft-design-gate
- Size: small
- Agents: specifier aafa034664a4b07f7, planner a2e09f4d1dd318417, tasker a7f785400c2db020f (for SendMessage)
- Current phase: done (shipping)
- Conventions: conventional commits `type(scope): msg`, one logical change per commit, user is the only author (no co-author); git as `/usr/bin/git`, one plain command per call; harness.md is shared with /fix and stays unchanged; agent report formats and /feat change together; a /feat gate change updates docs/workflow.md, docs/diagrams/gates.d2 and chain.d2 and their docs/img renders (`mise run diagrams`); checks `mise run lint` and `mise run test:apm`; `rm`/`cp`/`mv` are interactive aliases (use `command rm -f` etc.); the rtk hook may rewrite `gh`/`mise` calls: run them alone in a response.
- Allowed Spec Kit hooks: none
- Map: none
- Issue: #20

## Brief

# Brief: Design review stops only on findings that need the user
- Size: small — ~15 tasks expected: text changes to one agent's report contract, `/feat`'s phase 4 rules, the docs and one diagram; no new dependency, service or permission
- Short name: soft-design-gate
- Kind: feat
- Issue: #20

## Why
On small and medium features, `/feat`'s "Plan and design review" gate
(phases 3+4) stops on any finding above nice-to-have. In real runs 95% of
design findings were accepted as recommended, and 12 of the 17 recent stops
on medium features were plain approvals. Each stop costs the user a read
and a reply, and the run waits for them: the run-cost baseline
(`docs/workflow.md`, `## Baseline`) shows that waiting for the user is a
large share of a `/feat` run's wall clock. This is part of epic #31 (cut
the cost and time of `/feat` and `/fix` runs). A user asked to approve
often starts approving without reading, which defeats the gate.

## Today
- `feat-design-reviewer` reports each finding with a `severity: high |
  medium | nice-to-have` and no recommendation. `/feat` merges the findings
  into `D1…` and writes a recommendation for each itself.
- Small/medium: the gate is hard on a finding above nice-to-have, a planner
  assumption with `needs user: yes`, a constitution violation, a blocker, a
  size increase, a 4c paraphrase that contradicts the brief, or an
  unchecked checklist item carried from a soft phase 2. Otherwise it is
  soft and `/feat`'s recommendations are applied.
- Large: always hard, and the user accepts or rejects each finding against
  `/feat`'s recommendation.
- The phase 7 code review gate already works the way this brief wants:
  each reviewer ends every finding with `rec: apply | skip (<why>) | user
  (<why>)`, `/feat` never sets `apply` or `skip` itself, merges by fixed
  rules (harness, Review findings), and is soft on small/medium unless a
  finding needs the user. The two gates behave differently for no reason
  the user can see.

## Behaviour
- `feat-design-reviewer` ends every finding with `rec: apply | skip (<why>)
  | user (<why>)`, the same three values as `feat-code-reviewer`. Severity
  stays on the line. Every finding carries a rec, nice-to-have included,
  and follows it like any other (today's soft gate already applies them,
  so the planner's amend pass doesn't grow). The 4c paraphrase is
  unchanged and carries no rec.
- The reviewer must mark `rec: user` any finding that removes or changes a
  story, a requirement or an acceptance criterion the brief asked for, or
  overturns a spec assumption. A finding that only adds a tightening
  requirement (input validation, error handling, a secure default) may be
  `apply`.
- `/feat` never sets `apply` or `skip` on a design finding; it merges the
  design findings into `D1…` with the harness's merge rules 2, 3 and 5
  (Review findings), where "same spot" means the same artifact and the
  same section or line, and "same section" means the same tag (`[sec]`,
  `[cost]`, `[design]`): the same spot with the same rec and fix is kept
  once; the same spot from different reviewers or lenses with a different
  rec or fix becomes `user (reviewers disagree)`; a missing or invalid rec
  becomes `user (no valid recommendation)`. Rules 1 (cut code) and 4
  (high-confidence bug) don't apply to design findings.
- **Small/medium**: the "Plan and design review" gate is hard when any of
  these holds, and soft otherwise:
  - a `D` finding with `rec: user`;
  - a planner assumption with `needs user: yes`;
  - a constitution violation;
  - a blocker;
  - a size increase;
  - a 4c paraphrase that contradicts the brief;
  - an unchecked checklist item carried from a soft phase 2;
  - a failed report check (harness, Reported files), as today.
- A soft gate applies the `apply` findings unasked (the planner writes
  them, continued with `SendMessage` as today), leaves the `skip` ones,
  and prints one line naming the counts and every `[sec]` finding applied,
  e.g. `Phase 4 Design review — soft: 5 findings, 4 applied, 1 skipped;
  security: D2; none needs your call. Next: phase 5 Tasks`. After a soft
  phase 2 the soft report still carries the spec summary, as today. A
  high-severity finding the reviewer marks `apply` or `skip` is applied or
  left like any other and is not named in the soft line: the reviewer's
  rec is trusted, and the Log lists every finding with its rec.
- A hard small/medium gate lists the `user` findings first ("apply or
  leave?" with the reviewer's why), then the others with their rec. "ok"
  applies every `apply` and leaves every `skip`; each `user` finding needs
  its own answer, and a bare "ok" while one is unanswered gets one
  follow-up naming the ids (phase 7's rule).
- **Large**: always hard, with phase 7's large rule: every finding shown
  with its rec, `user` first, the same "ok" rule.
- The Log's phase 4 line records what happened: soft `auto-applied <ids |
  none>; skipped <id> (reviewer: "<why>")`; hard `picked <ids>` / `rejected
  <id> (user: "<words>" | as recommended)`; one indented line per finding
  with its id, spot, a few words and its rec. Skipped and rejected design
  findings reach later reviewers as rejected findings (the reviewer
  context), as today.

## Out of scope
- Phase 7 (code review) rules, and `/fix` (it has no design review): their
  behaviour does not change.
- Any other gate (phases 2, 3 large, 5, 6).
- The size table, models and efforts, and the reviewer lenses' content.
- Making `[sec]` findings always stop (rejected below).

## Alternatives rejected
- Do nothing — 12 of 17 recent medium stops were plain approvals; the gate
  costs the user's time and teaches them to approve without reading.
- `/feat` decides from severity ("high means user"), no report change — keeps
  the judgment in the coordinator, which `/feat` avoids at phase 7; a high
  `fit` finding (a cited file that doesn't exist) has one obvious fix and
  needs no user, which severity can't tell apart.
- Every `[sec]` finding makes the gate hard, like `S` at phase 7 — `S` stops
  because an unfixed finding is published with code already written; at
  phase 4 an `apply` security finding is a design correction written before
  any code, and 7b checks it was built. Naming them in the soft line shows
  them without a stop.
- Leave large as it is, with `/feat` writing its own recommendations there
  — two sources of recommendations in one phase; large takes phase 7's
  large rule instead.
- Name high-severity ids in the soft line as well as `[sec]` ones — the
  reviewer's rec is trusted (the point of this change) and the Log lists
  every finding; a longer soft line works against the goal.
- Every finding that touches the spec is `rec: user` — most design
  findings are written into spec.md as requirements, so this would bring
  most stops back; only removing or changing what the brief asked for, or
  overturning a spec assumption, needs the user.
- Drop the `needs user: yes`, constitution and paraphrase triggers to match
  the issue's four — each is a decision only the user can make, and they
  are not what produced the plain approvals.

## Acceptance
- `feat-design-reviewer`'s report format ends every finding with `rec:
  apply | skip (<why>) | user (<why>)`, and `/feat`'s phase 4 reads it.
- `.apm/skills/feat/SKILL.md`'s phase table row 4 and its section 4 state the small/medium
  triggers above, the soft line with `[sec]` ids, and the large rule; no
  trigger on "a finding above nice-to-have" remains.
- `/feat` never writes its own recommendation on a design finding.
- `docs/workflow.md` (the phase table row, the section on 4 Design review)
  says the same; `docs/diagrams/gates.d2` and the README's chain alt text
  no longer say the gate stops to "decide on the findings" unconditionally;
  `docs/img/` is re-rendered with `mise run diagrams` and the `check`
  workflow passes.
- A soft gate's Log line lists the auto-applied and skipped `D` ids.
- `mise run lint` and `mise run test:apm` pass.

## Constraints / decisions already made
- The orchestrator reads the reviewer's report and depends on its fixed
  format: change `feat-design-reviewer.agent.md` and `/feat`'s phase 4
  together (`.claude/CLAUDE.md`).
- The design rules are written in `/feat`'s section 4, referring to the
  harness's merge rules 2, 3 and 5 and its "ok" follow-up; `harness.md`
  (shared with `/fix`) is not changed, so `/fix`'s behaviour can't change.
- `/feat` stays thin: no new reading of spec or plan by the coordinator.
- A soft gate keeps continuing the planner with `SendMessage` for the amend
  pass; a hard gate keeps a fresh spawn.
- A change to `/feat`'s gates updates `gates.d2` and `chain.d2` and their
  renders (`.claude/CLAUDE.md`); `models.svg` is unaffected (the size table
  doesn't change).
- The `feat` commit subject becomes a CHANGELOG entry: write it for users.

## Log

- [x] 0 Setup — no Spec Kit hooks enabled; tracker: ok users/pdemagny/projects/2; #20 set to "In progress"
- [x] 2 Specify — soft
    - Stories: US1 Plain design findings are applied without a stop (P1); US2 Judgement calls and risky cases still stop (P1); US3 /feat merges design findings without recommending itself (P2); US4 Large features keep a hard gate with phase 7's rule (P2); US5 The Log and the docs say what happened (P2)
    - Requirements: 15 FRs, 5 SCs; FR-001 every design finding ends with a rec, 4c paraphrase none; FR-002 removing/changing what the brief asked or overturning a spec assumption must be `rec: user`; FR-003/004 /feat never sets apply/skip, merges with harness rules 2, 3, 5 only; FR-005 the eight small/medium hard triggers; FR-006 soft line with counts and `[sec]` ids; FR-009 large always hard; FR-012 harness.md, phase 7, /fix, other gates and size table unchanged; FR-014 docs, gates.d2, README alt text, docs/img re-render
    - Spec assumptions: 1. "Blocker" and "size increase" keep their present meaning in phase 4 (recommended: keep as written); 2. a phase 4 resumed from before the change, with findings lacking a rec, makes each `user (no valid recommendation)` and the gate hard (recommended: keep as written); 3. the spec names files and rules because the brief makes them binding (recommended: keep as written); 4. chain.d2 is listed "as needed" in FR-014 (recommended: keep as written)
    - Unchecked checklist items: none
- [x] 3 Plan — no gate (small); plan.md + research, data-model, quickstart, contracts/phase4-gate.md; no blocker, no size trigger; 1 assumption needs user (soft gate still prints the 4c paraphrase)
- [x] 4 Design review — hard (D1, D2, D3, D5, D6 above nice-to-have; planner assumption needs user); approved "ok" (user): all recommendations accepted; reviewer sonnet · medium, lenses 4a+4b+4c; /feat wrote the recs (old phase 4 rule)
    - assumption "soft gate still prints the 4c paraphrase": kept (user: "ok")
    - spec assumptions 1–4: kept as written; checklist: none
    - D1 contract §2 — merge rules rarely fire with same tag = same section — accepted partly: keep rules 2, 3, 5; add "different tags on the same spot stay separate, each with its rec"; rejected dropping the rule reference (as recommended: changes what the brief asked for)
    - D2 contract §2 — "spot" means two things — accepted partly: define spot as same artifact and identical section heading or line; rejected restating the harness rules (as recommended: constitution III)
    - D3 contract §4 — zero apply: no SendMessage, go to phase 5 — accepted
    - D4 plan §2 — phase table isn't fixed-width, no re-alignment — accepted
    - D5 spec SC-004 — name greps for "real finding" and "decide on" in docs/workflow.md, README.md, docs/usage.md — accepted
    - D6 contract §4 / FR-006 — [sec] skipped silent in soft line: add "; security skipped: <ids>" when non-empty — accepted
    - D7 contract §1 / FR-002 — user rule also covers a finding that weakens a control the spec or plan sets — accepted
- [x] 4 amend — planner fresh (opus · high): D1–D7 and the paraphrase decision written into spec.md, plan.md, contracts, quickstart, data-model, research; SC-004 greps exact old phrases incl. "finding above"; reviewer section = heading as written or a line number
- [x] 5 Tasks — soft: 19 tasks (US1 T003–T004, US2 T005–T007, US3 T008, US4 T009, US5 T010–T016; setup T001, foundational T002, polish T017–T019); analyze ran, 1 LOW fixed (FR-013 check added to T019), none open; checklist: none
- [x] 6 US1 — T001–T004 done; lint, test:apm pass; feat-design-reviewer.agent.md Recommendation section + rec on report lines; SKILL.md section 4 Soft paragraph — not verified: none
- [x] 6 US2 — T005–T007 done; lint, test:apm pass; SKILL.md section 4 gate table + Hard paragraph, row 4 cell rewritten; large row already in the gate table (T009 adds title and wording) — not verified: none
- [x] 6 US3 — T008 done; lint, test:apm pass; SKILL.md section 4 merge rule (harness rules 2, 3, 5 by reference) — not verified: none
- [x] 6 US4 — T009 done; lint (icon-missing plugin warning only), test:apm pass; SKILL.md section 4 Hard paragraph large title and every finding with its rec — not verified: none
- [x] 6 US5 — T010–T019 done; lint, test:apm, diagrams pass (gates.svg, chain.svg re-rendered; models.svg unchanged); SC-004 greps no match; shipper, workflow.md, usage.md, d2 sources, README alt text — not verified:
    - T018 → `git diff --quiet origin/main -- <protected files>` → worktree guard refused it; orchestrator ran it afterwards: exit 0 (harness.md, fix/SKILL.md, feat-code-reviewer.agent.md, models.py, models.svg unchanged)
    - T019 → quickstart §3 walk-through → done as a read-only reread of section 4, not a run
- [x] 6 Implement — soft: tasks done: 19 (2 not verified); checks pass
- [x] 7 Code review — hard (C2 needs user); picked C1; rejected C2 (user: "leave C2"); rejected C3, R1, R2 (as recommended); reviewers sonnet · medium: 7a+7b, 7c+7d+7e; untested: US5 4 (docs/img vs fresh render; implementer ran `mise run diagrams`, check workflow confirms)
    - C1 SKILL.md section 4 — "spec assumptions logged as kept" said three times; keep the one after the Gate table — rec: apply
    - C2 SKILL.md phase table row 4 Gate cell — shorten to "hard on a user finding or another stop condition (section 4)" — rec: user (row is gate wording, your call)
    - C3 SKILL.md section 4 Hard paragraph reasons list — shorten to refer to the Gate table — rec: skip (fixed wording keeps the gate text stable; small saving)
    - R1 SKILL.md Soft one-line template — keep as is — rec: skip (rewrite risks the wording the orchestrator depends on)
    - R2 SKILL.md merge paragraph — depends on harness numbering — rec: skip (decided at the design gate)
- [x] 7 review fixes — C1 applied (SKILL.md section 4: duplicate "spec assumptions logged as kept" dropped from the Soft paragraph and the Log paragraph; the surviving sentence also logs the checklist answer); lint, test:apm pass; performance: none — not verified: none
- [x] 8 Ship
