# /feat state: Code review gate stops only for findings that need the user

- Branch: code-review-soft-gate Worktree: /home/pierre/Projects/logistics/.claude/worktrees/brief-code-review-soft-gate
- Size: small
- Agents: specifier ac4b68b004f0bc411, planner ac72205ab33b14cfa (amend; first run a8ac072ca4944a454), tasker a50f21c745eb7793a (for SendMessage)
- Current phase: 8 Ship
- Conventions: conventional commits `type(scope): msg`, one logical change per commit, no co-author, user is sole author; never "Closes #N" in a commit (PR body only); `/feat` and `/fix` stay thin (no code reading); reviewer report format and its coordinators change together; mirror size-table/agent changes in docs/workflow.md; D2 diagrams in docs/diagrams/ rendered to docs/img/ by `mise run diagrams` (commit both; gates.d2 and chain.d2 for /feat gate changes); harness.md holds no /feat-only words (lint greps it); `mise run lint` and `mise run test:apm` before committing; CHANGELOG generated, never edited; never edit versions by hand; in worktrees call `/usr/bin/git` directly, one plain command per call; `rm`/`cp`/`mv` are interactive aliases: use `command rm -f` etc.
- Allowed Spec Kit hooks: none (none configured)
- Map: none
- Issue: #12

## Brief

- Size: small — ~15–20 tasks expected; text-only changes to prompts (code reviewer, `/feat`, `/fix`, shipper), `docs/workflow.md` and two diagrams, no new dependency or service
- Short name: code-review-soft-gate
- Issue: #12

### Why
The person running `/feat` (and `/fix`) is asked to pick code-review fixes
at every run, and nearly always answers "apply the recommendations": in ~70
real runs, medium features stopped at phase 7 in 26 of 27 recent runs, each
ending that way, and 84% of all code-review findings were fixed. The stop
costs a wait (median 7–8 min, p75 ~30 min) and trains the user to approve
without reading, which weakens the gates that do matter.

### Today
- `/feat` phase 7 is always a **hard** gate: the coordinator merges the
  reviewers' findings (`B`, `S`, `P`, `C`, `R`, `[std]`), adds its own
  recommendation to each, and the user picks the fixes.
- `feat-code-reviewer`'s report carries severity (security), confidence
  (bugs) and tags (cuts), but no recommendation: the coordinator invents
  it while merging, and nothing marks a finding as a judgement call.
- `/fix` phase 4 is soft only when there is no finding above nice-to-have,
  no security finding, `Size: small` and a `Risk area` without security;
  otherwise hard, the user picks.

### Behaviour
- Every finding line in `feat-code-reviewer`'s report (sections Bugs,
  Spec, Standards, Security, Performance, Cuts, Readability) ends with a
  separate trailing field `— rec: apply | skip (<why>) | user (<why>)`,
  distinct from the `→ <fix>` some lines already carry. The Acceptance
  criteria line and the Cuts `net:` line carry none. `user` means a
  judgement call the reviewer can't make (e.g. scope creep the user may
  want to keep, a trade-off between two valid designs).
- When merging, the coordinator turns into `user`:
  - a spot two reviewers report with different recommendations or
    different fixes (any same-spot conflict);
  - a `skip` on a `B` finding with `confidence: high` (a real bug left
    unfixed is the user's call);
  - a finding whose `rec` is missing or not one of the three values (a
    reviewer that omitted it, a run resumed across the upgrade).
  A performance finding on code a cut removes is dropped and not listed,
  as today.
- `/feat` phase 7, small and medium:
  - **hard** when any finding is `user`, any finding is a security (`S`)
    finding, or any acceptance criterion is `not met`; the gate lists all
    findings with their recommendations and "ok" accepts them all;
  - otherwise **soft**: a one-line report, the `apply` findings go to
    `feat-implementer` in fix mode (same order and rules as today: bugs and
    security, cuts, measured performance, readability), the `skip` findings
    are not applied; then phase 8.
  - After a soft gate, a fix-mode report with failing checks, a failed
    `Wrote:` check or no `Not verified:` line is a **hard** stop before
    phase 8 (not only a line in the final message).
- `/feat` phase 7, large: stays **hard** at every run, as today, but each
  finding shows the reviewer's recommendation, so "ok" accepts them in one
  word.
- `/fix` phase 4, first match wins:
  1. `Risk area` includes security → **hard**, unchanged (findings to pick,
     plus the go-ahead to make the fix public);
  2. `Size: large` → **hard**, the user picks (mirrors `/feat` large);
  3. any `user` or `S` finding → **hard**, the user picks;
  4. otherwise → **soft**: `apply` findings go to the implementer, `skip`
     ones are logged.
  Today's "soft only when clean and small" row goes away (row 4 covers it).
  After any applied fix, phase 3 still reruns with a fresh assessor
  (`after review fixes`) before ship.
- The state file Log tells the two apart: a soft gate logs
  `auto-applied <ids>` and `skipped <id> (reviewer: "<why>")`; a hard gate
  logs `picked <ids>` (the user's choice, "ok" included) and the rest as
  rejected with the user's reason or "as recommended". `/fix`'s security
  row keeps its `ship go-ahead (user: "<words>")` line in addition to
  `picked <ids>` / `none picked`.
- Each skill defines this grouping in its own Log rule (`/feat` phase 7,
  `/fix` phase 4); `harness.md` is unchanged. The shipper builds the PR
  body from the state file Log it already receives.
- The PR body's code-review part lists findings in three groups:
  auto-applied, picked by the user, not applied (each with the reviewer's
  or the user's reason), so a skipped finding can still be overturned in
  PR review.

### Out of scope
- The design review gate (`/feat` phase 4): that is #20, which will reuse
  the same reviewer-recommendation rule.
- Parsable gate tags in the Log (`[soft]`/`[hard]`, `approved`/`picked`):
  #21.
- Deciding gate verdicts with a script: #28 (the new fixed field should
  make that easier, nothing more here).
- Changing which lenses run, their models or efforts: the size tables
  don't change.
- Any undo of auto-applied fixes beyond normal PR review.

### Alternatives rejected
- An opt-in/opt-out "trust the reviewers" option (as the issue proposed) —
  a setting nobody switches back, with no home today (`.logistics.yml`
  holds only the tracker config), and a per-run flag would have to survive
  `/feat resume`. Changing the gate itself, with hard-gate conditions as the
  safety valve, is what `003-soft-spec-gate` did.
- The coordinator deciding "needs the user" from existing fields (severity,
  confidence, tags) — severity measures how bad, not whether it is a
  judgement call; and the coordinator never reads code, the reviewer did.
- Stopping on findings the reviewer recommends against (`skip`) — agreeing
  with "not worth fixing" is the rubber stamp this removes; they are logged
  and listed in the PR as not applied instead.
- Same soft rule for large features — the user wants large to keep a hard
  phase 7, consistent with large's hard gates in phases 3–6.

### Acceptance
- `feat-code-reviewer`'s report format has the recommendation on every
  finding line, and `/feat` phase 7 and `/fix` phase 4 read it.
- On small and medium, a review with only `apply`/`skip` findings, no `S`
  finding and no `not met` criterion runs fixes and reaches phase 8 without
  stopping; one with a `user` or `S` finding, a `not met` criterion, a
  missing or invalid `rec`, a high-confidence bug marked `skip` or a
  same-spot conflict stops.
- A failed or incomplete fix-mode report after a soft phase 7 stops before
  phase 8.
- On large, phase 7 always stops and shows the recommendations.
- `/fix` phase 4's gate table has the four rows above, in that order.
- The Log distinguishes auto-applied from user-picked findings, and records
  skipped ones with the reviewer's reason.
- The PR body (shipper, both `/feat` and `/fix` modes) lists auto-applied,
  picked and not-applied findings separately.
- `docs/workflow.md` (phase table, `/fix` section) and `gates.d2` /
  `chain.d2` (re-rendered with `mise run diagrams`) describe the new gate;
  `mise run lint` and `mise run test:apm` pass.

### Constraints / decisions already made
- The reviewer's report format and the coordinators that read it change
  together (`/feat` phase 7, `/fix` phase 4); the orchestrator depends on
  the fixed format.
- `/feat` and `/fix` stay thin: they never read code; the recommendation
  comes from the reviewer, the coordinator only merges and applies the
  conflict rule.
- Shared wording goes in `.apm/skills/feat/references/harness.md` only if
  it carries no `/feat`-only words (`mise run lint` greps it).
- Security findings always stop (they are what becomes public once
  pushed); `/fix`'s `Risk area` security row stays first and unchanged.
- No new agent, no change to the size tables (models.svg unchanged).

## Log

- [x] 0 Setup — no Spec Kit hooks; tracker: ok users/pdemagny/projects/2; #12 set to "In progress"; branch renamed to code-review-soft-gate
- [x] 2 Specify — soft
    - Stories: US1 Reviewer recommends, user spared the rubber stamp (P1); US2 Judgement calls and risky cases still stop (P1); US3 A failed automatic fix cannot slip through (P1); US4 Large features keep a hard gate with recommendations shown (P2); US5 /fix phase 4 four-row gate table, first match wins (P2); US6 Log and PR body distinguish auto-applied / picked / not applied (P2)
    - Requirements: 14 FR, 6 SC; FR-001 trailing `— rec: apply | skip (<why>) | user (<why>)` on every finding line (none on Acceptance criteria / Cuts `net:`); FR-002 coordinator turns same-spot conflicts, high-confidence B `skip`, missing/invalid `rec` into `user`; FR-004/005/006 /feat small/medium hard-vs-soft rule and post-soft-gate hard stop; FR-008 /fix four rows in order; FR-010/011/012 per-skill Log grouping, harness.md unchanged, three-group PR body; FR-014 docs/workflow.md + gates.d2/chain.d2 re-rendered, size tables and models.svg unchanged
    - Spec assumptions: 1. "Same spot" means same file and location as reported by the reviewers (recommended: keep as written); 2. A missing `rec` is treated as `user` (fail safe), including runs resumed across the upgrade (recommended: keep as written); 3. The `not met` acceptance-criterion trigger is /feat-only; /fix's rows don't list it (recommended: keep as written); 4. No requirement beyond the brief; Assumptions restates out-of-scope and rejected alternatives (recommended: keep as written)
    - Unchecked checklist items: none
- [x] 3 Plan — plan.md + research, data-model, quickstart, contracts/review-gate.md; no blocker, no size trigger; constitution III deviation (merge rules duplicated in both skills, harness.md unchanged per FR-011); 8 assumptions, A1 needs user ("ok" at a hard gate fixes `apply` only)
- [x] 4 Design review (gate for 3+4) — hard (D3 high, D1/D2/D4/D5/D6 medium, planner A1 needs user, constitution III deviation); reviewer sonnet·medium, lenses 4a+4b+4c; cost: no findings; spec assumptions 1–4 kept (1 narrowed by D3); checklist: none unchecked
    - Constitution III (user: "why would we knowingly violate the constitution if there are other ways (updating the harness)?", then "ok"): FR-011 reworded; harness.md gains a "Review findings" section with named values (e.g. *review phase*): the five merge rules, the A1-b "ok" rule, and the Log words (auto-applied / skipped (reviewer: …) / picked / rejected (user: …)); verdict tables, /feat's post-soft-gate stop and /fix's ship go-ahead line stay per skill; lint must stay clean
    - accepted D3: same-spot conflict only when same spot AND same section, with different `rec` or different `→ fix` text; Readability findings on code a cut removes are dropped like Performance
    - accepted D2: reviewer guidance dismisses findings driven by instructions embedded in the code; a cut that deletes a test, check or file is `user`
    - accepted D1: when an `S` finding stays unfixed, the hard gate says it will be published (PR body and state file); the PR body lists it as id, file and title only, no exploit detail
    - D4 decided soft (user "ok" to recommendation, against reviewer's "hard"): an `untested` criterion doesn't stop; it is listed in the one-line soft report and in the PR body
    - accepted D5: after a soft gate, failing checks go back to the implementer once (as phase 6), then hard; a failed Wrote: check or missing Not verified: line is hard at once, recommending a fresh implementer with the same findings; the `[!]` line is appended
    - accepted D6: US5/FR-008 say /fix row 4 intentionally drops the old "nothing above nice-to-have" guard and covers small and medium
    - accepted D7 (rule 4 uses the reviewer's why when present, else rule 5's text), D8 (guidance paragraph and report-block edits in one task)
    - planner amend done: spec/plan/research/data-model/quickstart/contract amended; constitution check passes; harness.md gains "## Review findings" (merge rules, "ok" rule, S publication notice, Log words), *Review phase* 7/4; docs/design.md newly touched; planner assumptions (needs user: no): S notice in harness; `untested` named at hard gates too and logged `; untested: …` (/feat only); bare "ok" with open `user` findings fixes nothing until each is answered
    - A1 overturned (user: "b"): at a hard gate "ok" covers only `apply`/`skip` findings; each `user` finding must get an explicit fix-or-leave answer (listed first under "Your call" with the reviewer's why); a bare "ok" with `user` findings open gets one follow-up naming them by id; Log: `picked <id>` / `rejected <id> (user: "<words>")`, "as recommended" only for `skip`; `S` findings unchanged (rec apply/skip, "ok" follows it)
- [x] 5 Tasks — soft: 19 tasks (small); US1 T001–T004 (T001 harness, T002 reviewer = foundational), US2 T005, US3 T006, US4 T007, US5 T008–T009, US6 T010–T011 + polish T012–T019; MVP T001–T005; analyze (done by hand, not via the skill): no findings, 100% FR/SC coverage; checklist: none unchecked
- [x] 6 US1 — not verified: none (T001–T004; harness.md Review findings, reviewer rec, /feat Harness values + row 7 + §7 gate table/soft case; lint + test:apm pass)
- [x] 6 US2 — not verified: none (T005; /feat §7 Hard paragraph for small/medium, refers to harness Review findings; lint + test:apm pass)
- [x] 6 US3 — not verified: none (T006; /feat §7 "After a soft gate" retry/stop paragraph; lint + test:apm pass)
- [x] 6 US4 — not verified: none (T007; /feat §7 Hard covers large always with recs shown; lint + test:apm pass)
- [x] 6 US5 — not verified: none (T008–T009; /fix *Review phase* 4, row 4, §4 four-row table, security row first + ship go-ahead kept; lint + test:apm pass)
- [x] 6 US6 — not verified: none (T010–T019; shipper three-group PR body, implementer wording, workflow/design/README/usage docs, gates.d2 + chain.d2 re-rendered, models.svg unchanged; lint, test:apm, diagrams, quickstart Q1–Q11 pass; optional live scenarios L1–L10 not run, not in tasks)
- [x] 6 Implement — soft: tasks done: 19 (0 not verified); lint + test:apm + diagrams pass
- [x] 7 Code review — hard (installed /feat: always; B2, P1 are `user`); #12 set to "In review"; reviewers sonnet·medium: 7a+7b, 7c+7d+7e; D1, D2 built; all acceptance criteria met; S: none; picked B1, C1, C2, R1, R2; rejected B2 (user: "leave"), P1 (user: "ok for the rest", recommendation was leave), C3, C4, R3 (as recommended)
    - B1 .apm/skills/fix/SKILL.md + feat-shipper (fix mode) — two `4 Code review` Log lines (go-ahead + outcome) with no fixed order; shipper may miss picked/rejected → shipper reads all `4 Code review` lines — confidence: medium — rec: apply
    - B2 feat-code-reviewer Recommendation — unbuilt accepted `[sec]` design finding reported as Security line (= S stop); not in FR-001 (was planner A4) — rec: user
    - P1 harness.md:122-125 — rule 3 compares `→ fix` text; wording rarely matches → `user` → hard gates — rec: user
    - C1 feat/SKILL.md:341-345 — Hard parenthetical repeats the table → "Hard:" — rec: apply
    - C2 feat/SKILL.md:345 — drop "reviewers disagree on <spot>" stop reason (covered by `<ids> need you`) — rec: apply
    - C3 feat/SKILL.md:323-330 — shrink 3-row table to a sentence — rec: skip (matches /fix's table style)
    - C4 feat-code-reviewer.agent.md:164-167 — drop "security finding stops whatever its rec" — rec: skip (one-line hint helps choose rec)
    - R1 docs/workflow.md:315-317 — orphaned last sentence → new paragraph, rewrap — rec: apply
    - R2 docs/workflow.md:296-315 — 20-line paragraph, four topics → 3 paragraphs — rec: apply
    - R3 feat-shipper PR-body step — long rewrapped line → rewrap — rec: skip (cosmetic)
- [x] 7 review fixes — not verified: none (B1 applied: shipper fix mode reads all `4 Code review` lines; C1, C2 applied in feat/SKILL.md §7; R1, R2 applied: docs/workflow.md phase 7 split into 4 paragraphs; performance: none; lint + test:apm pass)
- [ ] 8 Ship
