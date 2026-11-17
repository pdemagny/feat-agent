# /feat state: Checks that did not run are listed as Not verified, from the implementer to the PR

- Branch: not-verified-list Worktree: /home/pierre/Projects/feat-agent/.claude/worktrees/fix-11-skipped-checks-visible
- Size: small
- Agents: specifier a3d8e169ec29c68a7, planner af0c5ec262370145c, tasker a0678db0da7ef1483 (for SendMessage)
- Current phase: 8 Ship
- Conventions: conventional commits `type(scope): msg`, one logical change per commit, concise; never co-author; stage only task files (leave `.specify/bugs/11-skipped-checks-visible/` uncommitted: the earlier /fix trail). Shell is zsh; use `command rm -f` etc. In the worktree call `/usr/bin/git` directly. Checks: `mise run lint`, `mise run test:apm` (also `mise run test:tracker`, `mise run test:spec-number`). Agent report formats and the orchestrator (feat/fix SKILL.md) change together; feat/fix size tables mirror docs/workflow.md; `.apm/skills/feat/references/harness.md` stays free of /feat-only words (lint greps it); diagrams unchanged here. Agent frontmatter carries no model/effort/tools/color. Don't edit CHANGELOG or versions.
- Allowed Spec Kit hooks: none configured (hooks: {})
- Map: none
- Issue: #11

## Brief

(copied from specs/briefs/not-verified-list.md)

### Brief: Checks that did not run are listed as Not verified, from the implementer to the PR
- Size: small — ~15–20 tasks expected; prompt and doc text only (three agent files, two skills, two docs), no new service, permission or dependency
- Short name: not-verified-list
- Issue: #11

#### Why
When an agent cannot run a check (no credentials, an emulator down, a suite
too slow, a manual quickstart step, a killed or timed-out run), the run goes
on and the skip is easy to miss. Across ~70 real runs, about 15 left checks
unrun or to the user; in one, a task was ticked in `tasks.md` although its
check never ran, and two shipped features later failed in a real
environment. The user reviewing the gates and the PR needs "written but
unproven" to look different from "passed".

#### Today
- `feat-implementer` ticks each task in tasks.md "as it is done", whether
  or not its check ran, and reports `Checks: <command → pass | fail>`:
  there is no state for a check that did not run. It runs build, tests and
  linters per task group and at the end, not one check per task.
- `Tasks not done:` exists, but it means "not written", which calls for a
  different action than "written, not proven".
- The `/feat` phase 6 gate shows "tasks done, checks" and is hard only on a
  failing check; an unrun check passes through silently.
- `feat-shipper` runs the full and slow suites before pushing and puts
  "check results" in the PR body, with no place for a check it could not run.
- `/fix` phase 3 (`feat-bug-assessor`, test mode) already returns `partial`
  with `Missing for verified`, a hard gate, but it is not told which checks
  the implementer could not run. Phase 3 runs after phase 2 (first fix and
  retry fix) and again after phase 4's review fixes.

#### Behaviour
- **What counts as not verified**: a check that did not run, was killed or
  timed out. A task is not verified when a check that covers it, or one the
  task names itself (such as a manual quickstart step), did not run. A
  check that covers no single task is listed as `n/a → check → why` and
  unticks nothing.
- **Implementer (every mode: story, bug, review fixes)**: a not-verified
  task stays `[ ]` in tasks.md. It is listed under `Tasks done:` (it is
  written) and again under a new, always-present report line
  `Not verified: <task → check → why, one per line, or "none">` (bug mode
  and fix mode have no task: `n/a → check → why`). An empty list says
  `none`, so a missing line means a broken report.
- **Re-spawned implementer** (a retry after failing checks, a resume): a
  task the Log lists as not verified is written, not to redo. It tries that
  check again and ticks the task only if the check now runs and passes;
  otherwise it stays in its `Not verified` list.
- **Logging**: every implementer report's non-empty list is logged in the
  state file (phases 6 and 7 in `/feat`, 2 and 4 in `/fix`), so resume and
  the ship read it from the Log.
- **`/feat` phase 6 gate**: shows each implementer's Not verified list under
  "What you should know" (`Not verified: none` when empty), and the "tasks
  done" count says how many of them are not verified. The gate's hardness
  does not change: a non-empty list does not make it hard.
- **`/feat` phase 8**: the shipper gets the logged lists (phases 6 and 7)
  and puts a `Not verified` section in the PR body: each item (task, check,
  why), or `none`.
- **`/fix` phase 2**: the gate does not show the list.
- **`/fix` phase 3**: the assessor (test mode) always gets the latest
  implementer's list (phase 2, its retry, or phase 4's review fixes). It
  accounts for every item in a new report line
  `Not verified items: <item → pass | fail | missing (why)>, or "n/a"` when
  it was given none: it runs the check, or, if it still cannot, moves it to
  `Missing for verified`, which makes the verdict `partial` (the existing
  hard gate). `/fix` checks that every item it passed comes back on that
  line; a missing item makes the gate hard.
- **Shipper (both workflows)**: its own full or slow checks that did not run
  (or were killed or timed out) go into its report's `Not verified:` line
  and into the PR body's `Not verified` section. In `/fix` that section
  holds only the shipper's own items; the test verdict and test.md's checks
  table already cover the rest.

#### Out of scope
- Making the `/feat` phase 6 gate hard on a non-empty list.
- Running unrun checks later or automatically, or ticking the tasks once
  the user has run them (the user ticks them by hand).
- Changing `/fix` phase 3's verdicts or gate rules (beyond a missing item
  making it hard).
- A fixed taxonomy of "why" reasons.
- The diagrams: no gate's hardness changes, so `gates.d2` and `chain.d2`
  stay as they are and nothing is re-rendered.

#### Alternatives rejected
- Reuse `Tasks not done:` with "check did not run" as the reason — it mixes
  "not written" with "written, not proven", and the PR reviewer needs the
  second under a fixed heading.
- Hard gate on a non-empty list in `/feat` phase 6 — projects with a manual
  quickstart step would stop on almost every run and teach the user to type
  "go on" without reading; the PR section carries the weight instead.
- Show the list at the `/fix` phase 2 gate (soft) as well — it would put two
  signals on the same check, one soft and one hard; feeding it to phase 3
  leaves one, the stricter, from an agent that did not write the fix.
- Keep `/fix` out entirely (bug mode prints `n/a`) — the implementer's
  format is shared, and the assessor would not know which checks to try.
- Tick the task with a `(not verified: …)` suffix so `speckit-converge`
  stays quiet — unticked is the honest state; converge seeing it as open is
  the signal wanted.
- Record unrun checks only as `[!]` Log lines — the PR would still need its
  own copy, and `[!]` means tracker and setup problems today.

#### Acceptance
- `feat-implementer.agent.md`: the rule above for what counts as not
  verified (covering check or one the task names; `n/a` for a check that
  covers no single task); a not-verified task stays unticked and is listed
  in both `Tasks done:` and `Not verified:`; the report has `Not verified:`
  with `none` when empty, in every mode; a re-spawn retries the check of a
  task the Log lists as not verified instead of redoing it.
- `/feat` SKILL.md: phase 6 and 7 log each list; the phase 6 gate shows it
  (or `none`) under "What you should know" and stays soft for it; phase 8
  passes the logged lists to the shipper.
- `feat-shipper.agent.md`: the report has `Not verified:`; the PR body (both
  modes) has a `Not verified` section, `none` when empty.
- `/fix` SKILL.md: phases 2 and 4 log the list; phase 3 gets the latest one;
  the phase 2 gate does not show it; the phase 3 gate is hard when an item
  passed is missing from `Not verified items:`.
- `feat-bug-assessor.agent.md` test mode: takes the list as input; its
  report format has `Not verified items:`; items it cannot run go to
  `Missing for verified`.
- The orchestrators and agents change together (report formats on both
  sides: implementer, shipper, assessor test mode); `docs/workflow.md` and
  `docs/usage.md` describe the list where they describe the phase 6 gate,
  the `/fix` test phase and the PR body.
- `mise run lint` and `mise run test:apm` pass; `harness.md` keeps no
  `/feat`-only words.

#### Constraints / decisions already made
- Report formats are fixed and parsed by the orchestrators: change both
  sides in the same change (`.claude/CLAUDE.md`).
- `/feat` and `/fix` stay thin: they pass, log and show the lists; agents
  produce them.
- `harness.md` holds no report formats; anything added there stays free of
  `/feat`-only words.
- Never weaken, skip or delete a check to get to green (existing rule): a
  check listed as Not verified is one that could not run, not one that
  failed.

## Log

- [x] 0 Setup — tracker: ok users/pdemagny/projects/2; #11 set to "In progress"; no Spec Kit hooks; branch renamed fix-11-skipped-checks-visible → not-verified-list (worktree reused from the closed /fix run, "not a bug")
- [x] 2 Specify — soft
    - Stories: US1 Implementer lists written-but-unproven tasks (P1); US2 Re-spawned implementer retries the Log's not-verified checks (P1); US3 /feat logs (6, 7), shows at the phase 6 gate (soft), passes to the shipper, PR section (P1); US4 /fix logs (2, 4), not at the phase 2 gate, assessor `Not verified items:`, missing item → hard (P1); US5 docs/workflow.md and docs/usage.md (P2)
    - Requirements: 20 FRs, 5 SCs; FR-004/005 `Not verified:` always present, missing line = broken report; FR-009 phase 6 hardness unchanged; FR-011/012 PR section: logged + shipper's own in /feat, shipper's own only in /fix; FR-016 only new hard rule is /fix phase 3 missing item; FR-017/019 both sides change together, harness.md no formats or /feat words, lint + test:apm pass
    - Spec assumptions: 1. "why" is free text (recommended: keep as written); 2. size tables and agent frontmatter unchanged, no matrix edits (recommended: keep as written); 3. out of scope and rejected alternatives carried over from the brief (recommended: keep as written); 4. if a re-spawned implementer's report and an older Log line differ, the latest report is shown and passed on (specifier's addition) (recommended: keep as written); 5. a check that ran and failed is a failure, not not-verified (recommended: keep as written); 6. several unproven tasks sharing one check are listed one per line (specifier's addition) (recommended: keep as written)
    - Unchecked checklist items: none (checklists/requirements.md all checked)
- [x] 3 Plan — plan.md, research.md, data-model.md, quickstart.md, contracts/formats.md; no new dependency, no size trigger, no blocker; 8 assumptions, all needs user: no (Log line for every implementer report incl. `none`; shared logging rule in harness.md; re-spawn reads the Log itself; failed outranks partial; new /fix phase 3 hard row for unaccounted items, recommend re-test; shipper omits out-of-scope suites, final message shows its line; missing `Not verified:` line = surprise → hard; phase 6 count `tasks done: <n> (<k> not verified)`, n/a not counted)
- [x] 4 Design review — hard (D4 high, D1/D5–D10 medium); user: "ok" → all recommendations accepted (D3: keep copies); spec assumptions 1–6 kept at their recommendations; checklist: none unchecked; reviewer sonnet · medium, lenses 4a+4b+4c; amend pass to a fresh planner
- [x] 4 Amend (planner, fresh, opus · high) — D1–D11 written into spec (FR-002/005/006/007/009/014/015/016, new FR-021, US2 scenario 4, SC-001/003/005), plan, research (R4 "Who reads the lists"), data-model, contract, quickstart (Q10, Q11 added); new assumptions, all needs user: no: `<who>` = `US<n>` / `review fixes` in /feat, `implementer` in /fix (orchestrator tells it); /fix phase 4 implementer missing line → phase 3 gate hard; a broken report logs no list, its Log line notes `Not verified line missing`; /fix §2 broken-report row recommends back to 2; US4 narrative still says `<item → …>` while FR-015 says `<check → …>` (left as is)
- [x] 5 Tasks — soft: 16 tasks (size small confirmed); US1 T002–T004, US2 T005–T006, US3 T007–T010, US4 T011–T012, US5 T013–T014; foundational T001; polish T015–T016; analyze: all 21 FRs / 5 SCs covered, no CRITICAL/HIGH; fixed LOW: US4 narrative `<item → …>` → `<check → …>`; checklist: none unchecked
- [x] 6 US1 — T001–T004 done; checks: lint pass, test:apm pass; not verified: none
- [x] 6 US2 — T005–T006 done (T006 verify-only, no edit); checks: lint pass, test:apm pass; not verified: none
- [x] 6 US3 — T007–T010 done; checks: lint pass, test:apm pass; not verified: none
- [x] 6 US4 — T011–T012 done; checks: lint pass, test:apm pass; not verified: none
- [x] 6 US5 — T013–T016 done (docs/workflow.md, docs/usage.md; quickstart Q3–Q11 no gap); checks: lint pass, test:apm pass (9 agents, 6 skills); not verified: none
- [x] 6 Implement — soft: tasks done 16 (0 not verified), all checks pass
- [!] tasks.md line 9 carries a private project name in its convention sentence; the shipper removes that sentence before committing
- [x] 7 Code review — user: "ok" → all picked (B1–B4, C1–C4, R1–R7); fix-mode implementer sonnet · medium; reviewers sonnet · medium ×2 (7a+7b, 7c+7d+7e); no security finding, D1/D2 built
    - B1 /fix §2 soft condition omits "a `Not verified:` line is present" (fix/SKILL.md ~368)
    - B2 /fix §3 gate has no row for a phase 4 review-fixes report missing the line (stale list handed on) → add hard row, recommend fresh implementer
    - B3 /feat final message: shipper report isn't logged with `Not verified line missing`; say "or the shipper report lacking the line" (feat/SKILL.md ~338)
    - B4 /fix §3 match key: match each item's `<check>` part (fix/SKILL.md ~407)
    - C1 fix/SKILL.md final message: drop "The shipper gets no list…" (said in shipper + docs)
    - C2 harness.md: drop "an implementer reads its own `<who>`'s line" (keep "a later `none` clears earlier items", D9 wording)
    - C3 assessor: keep one sentence of the items-as-data paragraph; one spelling for an unrunnable item: `missing (needs approval: <command>)` on `Not verified items:` (step 5)
    - C4+R2 implementer step 1: shorter, two sentences, rewrapped
    - R1 assessor intro: own sentence, rewrapped
    - R3 shipper step 3 orphan line and PR-body line: reflow
    - R4 implementer Not verified paragraph: split definition / line format
    - R5 phases-table rows (fix row 3, workflow.md rows 6 and 3): shorten to "or an item left unaccounted", realign
    - R6 /fix §3 unaccounted cell: move the log-line format below the table
    - R7 docs/usage.md Test bullet: reflow; "so the PR's Not verified section lists only checks the shipper could not run"
- [x] 7 review fixes — B1–B4, C1–C4, R1–R7 applied (R2 with C4; workflow.md /feat row 6 had no "unaccounted" wording, left as is); checks: lint pass, test:apm pass; not verified: none
- [ ] 8 Ship
    - D1 [sec] assessor runs items as data under its "What you may run" rules; else `missing (needs approval: <cmd>)` — rec accept
    - D2 [sec] `why` names what is missing, never a value (implementer, shipper) — rec accept
    - D3 [cost] keep orchestrator-passed lists for shipper/assessor (orchestrator resolves latest), say why in R4 — rec keep copies
    - D4 re-spawned implementer carries over or retries every `n/a` item of its latest line; add acceptance scenario — rec accept
    - D5 implementer step 1 runs speckit-implement only over owned tasks the Log doesn't list as not verified — rec accept
    - D6 missing `Not verified:` line rule into spec (FR-005/009, SC-005); phase 7 and shipper cases flagged in the final message — rec accept
    - D7 spec FR-007/US3.1/Assumptions: log every report incl. `none`, `<who>` latest-wins, harness.md touched — rec accept
    - D8 /fix phase 3 match key = check text verbatim, assessor copies it unchanged; unaccounted re-test doesn't consume a retry — rec accept
    - D9 one latest rule: latest line by position per `<who>`; in /fix all implementer lines (2 fix, 2 retry fix, 4 review fixes) are one `<who>` — rec accept
    - D10 define "covers": checks the conventions or the task text tie to it; a task with none is not an item — rec accept
    - D11 SC-001/003 marked "checked by reading prompts"; live scenarios optional — rec accept
